const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const { body, validationResult } = require('express-validator');

const User = require('../models/User');
const Patient = require('../models/Patient');
const HealthcareProvider = require('../models/HealthcareProvider');
const AuditLog = require('../models/AuditLog');
const { protect, authorise } = require('../middleware/auth');
const bucket = require('../config/firebase');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const getPatientId = async (userId) => {
  const patient = await Patient.findOne({ user_id: userId });
  return patient ? patient._id : null;
};

const hasEmailService = () => {
  const key = process.env.BREVO_API_KEY || '';
  return key && !key.includes('your_');
};

const generateOtp = () => Math.floor(100000 + Math.random() * 900000).toString();

const sendOtpEmail = async (user, otp) => {
  const expiry = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
  user.otpCode = crypto.createHash('sha256').update(otp).digest('hex');
  user.otpExpires = expiry;
  await user.save({ validateBeforeSave: false });

  if (!hasEmailService()) {
    console.warn(`[OTP] Email service not configured. OTP for ${user.email}: ${otp}`);
    return false;
  }

  const { BrevoClient } = require('@getbrevo/brevo');
  const client = new BrevoClient({ apiKey: process.env.BREVO_API_KEY });

  await client.transactionalEmails.sendTransacEmail({
    sender: { email: 'medivault41@gmail.com', name: 'MediVault' },
    to: [{ email: user.email, name: `${user.first_name} ${user.last_name}` }],
    subject: 'MediVault — Your Verification Code',
    htmlContent: `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;background:#050C18;color:#fff;border-radius:16px;padding:32px;">
        <h2 style="color:#00C8FF;margin-bottom:8px;">MediVault</h2>
        <p style="color:#8FA8C8;">Your health records, secured.</p>
        <hr style="border-color:#1E2D40;margin:24px 0;">
        <p>Hi <strong>${user.first_name}</strong>,</p>
        <p>Use the code below to verify your account. It expires in <strong>15 minutes</strong>.</p>
        <div style="background:#0F1A2E;border:1px solid #1E2D40;border-radius:12px;padding:24px;text-align:center;margin:24px 0;">
          <span style="font-size:40px;font-weight:bold;letter-spacing:12px;color:#00C8FF;">${otp}</span>
        </div>
        <p style="color:#8FA8C8;font-size:13px;">If you did not create an account, ignore this email.</p>
      </div>
    `,
  });
  return true;
};

const sendPasswordResetEmail = async (user, resetUrl) => {
  if (!hasEmailService()) {
    console.warn(`[RESET] Email service not configured. Reset URL: ${resetUrl}`);
    return false;
  }

  const { BrevoClient } = require('@getbrevo/brevo');
  const client = new BrevoClient({ apiKey: process.env.BREVO_API_KEY });

  await client.transactionalEmails.sendTransacEmail({
    sender: { email: 'medivault41@gmail.com', name: 'MediVault' },
    to: [{ email: user.email }],
    subject: 'MediVault — Password Reset',
    htmlContent: `
      <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;background:#050C18;color:#fff;border-radius:16px;padding:32px;">
        <h2 style="color:#00C8FF;">MediVault</h2>
        <p>Hi <strong>${user.first_name}</strong>,</p>
        <p>Click the button below to reset your password. This link is valid for <strong>10 minutes</strong>.</p>
        <a href="${resetUrl}" style="display:inline-block;padding:14px 28px;background:#3D72E8;color:#fff;text-decoration:none;border-radius:10px;margin:16px 0;font-weight:bold;">Reset Password</a>
        <p style="color:#8FA8C8;font-size:13px;">If you did not request this, please ignore this email.</p>
      </div>
    `,
  });
  return true;
};

const sendToken = (user, statusCode, res) => {
  const token = jwt.sign(
    { id: user._id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
  res.status(statusCode).json({
    success: true,
    token,
    user: {
      id: user._id,
      name: `${user.first_name} ${user.last_name}`,
      email: user.email,
      role: user.role,
    },
  });
};

const validatePassword = (password) => {
  if (!password || password.length < 8) return false;
  if (!/[a-z]/.test(password)) return false;
  if (!/[A-Z]/.test(password)) return false;
  if (!/[0-9]/.test(password)) return false;
  if (!/[^A-Za-z0-9]/.test(password)) return false;
  return true;
};

const escapeRegex = (value = '') => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const SL_DEFAULT_HOSPITALS = [
  'Apollo Hospital Colombo','Asiri Central Hospital','Asiri Surgical Hospital',
  'Base Hospital Kurunegala','District General Hospital Batticaloa',
  'District General Hospital Galle','District General Hospital Matara',
  'District General Hospital Ratnapura','Durdans Hospital',
  'Hemas Hospital Colombo','Hemas Hospital Wattala','Lady Ridgeway Hospital',
  'Lanka Hospital','Nawaloka Hospital','National Hospital of Sri Lanka',
  'Ninewells Hospital',"Sirimavo Bandaranaike Children's Hospital",
  'Sri Jayewardenepura General Hospital','Teaching Hospital Jaffna',
  'Teaching Hospital Kandy','Teaching Hospital Karapitiya',
  'Teaching Hospital Kurunegala','Teaching Hospital Ratnapura',
];

const SL_DEFAULT_SPECIALIZATIONS = [
  'Anesthesiology','Cardiology','Dermatology','Emergency Medicine',
  'Endocrinology','ENT (Ear, Nose & Throat)','Family Medicine',
  'Gastroenterology','General Medicine','General Surgery',
  'Gynecology & Obstetrics','Hematology','Infectious Diseases',
  'Nephrology','Neurology','Oncology','Ophthalmology',
  'Orthopedic Surgery','Pediatrics','Plastic Surgery','Psychiatry',
  'Pulmonology','Radiology','Rheumatology','Urology',
];

const mergeWithDefaults = (dbValues, defaults) => {
  const seen = new Set(dbValues.map(v => v.toLowerCase()));
  const merged = [...dbValues];
  for (const d of defaults) {
    if (!seen.has(d.toLowerCase())) merged.push(d);
  }
  return merged.sort((a, b) => a.localeCompare(b));
};

// ─── GOOGLE SIGN-IN ──────────────────────────────────────────────────────────
router.post('/google', async (req, res) => {
  try {
    const { id_token, role } = req.body;
    if (!id_token) return res.status(400).json({ success: false, message: 'Google ID token is required' });

    // Verify the token with Google
    const ticket = await googleClient.verifyIdToken({
      idToken: id_token,
      audience: process.env.GOOGLE_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { sub: googleId, email, given_name, family_name, email_verified } = payload;

    if (!email_verified) {
      return res.status(400).json({ success: false, message: 'Google account email is not verified' });
    }

    // Find existing user
    let user = await User.findOne({ $or: [{ google_id: googleId }, { email }] });

    if (user) {
      // Link Google ID if not already linked
      if (!user.google_id) {
        user.google_id = googleId;
        user.auth_provider = 'google';
        user.isVerified = true;
        await user.save({ validateBeforeSave: false });
      }

      const patientId = await getPatientId(user._id);
      await AuditLog.create({
        patient_id: patientId,
        actor_user_id: user._id,
        action_type: 'login',
        action_status: 'success',
        details: 'User logged in via Google',
        ip_address: req.ip,
      });

      return sendToken(user, 200, res);
    }

    // New Google user — role required
    const userRole = role === 'doctor' ? 'doctor' : 'patient';
    user = await User.create({
      first_name: given_name || 'User',
      last_name: family_name || '',
      email,
      google_id: googleId,
      auth_provider: 'google',
      role: userRole,
      isVerified: true,
      password_hash: undefined,
    });

    if (userRole === 'patient') {
      await Patient.create({ user_id: user._id });
    } else {
      await HealthcareProvider.create({
        user_id: user._id,
        specialization: '',
        organisation_name: '',
      });
    }

    await AuditLog.create({
      patient_id: userRole === 'patient' ? (await getPatientId(user._id)) : null,
      actor_user_id: user._id,
      action_type: 'login',
      action_status: 'success',
      details: 'New user registered via Google',
      ip_address: req.ip,
    });

    sendToken(user, 201, res);
  } catch (error) {
    console.error('Google auth error:', error);
    res.status(500).json({ success: false, message: 'Google sign-in failed. Please try again.' });
  }
});

// ─── REGISTER PATIENT ────────────────────────────────────────────────────────
router.post('/register/patient', async (req, res) => {
  try {
    await body('first_name').trim().notEmpty().withMessage('First name is required').run(req);
    await body('last_name').trim().notEmpty().withMessage('Last name is required').run(req);
    await body('email').isEmail().withMessage('Please provide a valid email').run(req);
    await body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters').run(req);

    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ success: false, message: errors.array()[0].msg });

    const { first_name, last_name, email, password, date_of_birth, gender, address, phone_number } = req.body;

    if (!validatePassword(password)) {
      return res.status(400).json({
        success: false,
        message: 'Password must include uppercase, lowercase, a number, and a special character',
      });
    }

    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ success: false, message: 'Email is already registered' });

    const user = await User.create({ first_name, last_name, email, password_hash: password, role: 'patient', phone_number });
    await Patient.create({ user_id: user._id, date_of_birth, gender, address });

    const otp = generateOtp();
    const emailSent = await sendOtpEmail(user, otp);

    if (!emailSent) {
      user.isVerified = true;
      user.otpCode = undefined;
      user.otpExpires = undefined;
      await user.save({ validateBeforeSave: false });
    }

    res.status(201).json({
      success: true,
      email,
      requiresOtp: emailSent,
      message: emailSent
        ? 'Registration successful. Enter the 6-digit code sent to your email.'
        : 'Registration successful. Email service not configured — account auto-verified.',
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── REGISTER DOCTOR ─────────────────────────────────────────────────────────
router.post('/register/doctor', async (req, res) => {
  try {
    await body('first_name').trim().notEmpty().withMessage('First name is required').run(req);
    await body('last_name').trim().notEmpty().withMessage('Last name is required').run(req);
    await body('email').isEmail().withMessage('Please provide a valid email').run(req);
    await body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters').run(req);
    await body('specialization').trim().notEmpty().withMessage('Specialization is required').run(req);
    await body('organisation_name').trim().notEmpty().withMessage('Organisation name is required').run(req);

    const errors = validationResult(req);
    if (!errors.isEmpty()) return res.status(400).json({ success: false, message: errors.array()[0].msg });

    const { first_name, last_name, email, password, specialization, organisation_name, phone_number } = req.body;

    if (!validatePassword(password)) {
      return res.status(400).json({
        success: false,
        message: 'Password must include uppercase, lowercase, a number, and a special character',
      });
    }

    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ success: false, message: 'Email is already registered' });

    const user = await User.create({ first_name, last_name, email, password_hash: password, role: 'doctor', phone_number });
    await HealthcareProvider.create({ user_id: user._id, specialization, organisation_name });

    const otp = generateOtp();
    const emailSent = await sendOtpEmail(user, otp);

    if (!emailSent) {
      user.isVerified = true;
      user.otpCode = undefined;
      user.otpExpires = undefined;
      await user.save({ validateBeforeSave: false });
    }

    res.status(201).json({
      success: true,
      email,
      requiresOtp: emailSent,
      message: emailSent
        ? 'Registration successful. Enter the 6-digit code sent to your email.'
        : 'Registration successful. Email service not configured — account auto-verified.',
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── VERIFY OTP ──────────────────────────────────────────────────────────────
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ success: false, message: 'Email and OTP are required' });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: 'Account not found' });
    if (user.isVerified) return res.status(400).json({ success: false, message: 'Account is already verified' });

    if (!user.otpCode || !user.otpExpires || user.otpExpires < Date.now()) {
      return res.status(400).json({ success: false, message: 'OTP has expired. Please request a new one.' });
    }

    const hashedOtp = crypto.createHash('sha256').update(otp.toString()).digest('hex');
    if (hashedOtp !== user.otpCode) {
      return res.status(400).json({ success: false, message: 'Invalid OTP. Please try again.' });
    }

    user.isVerified = true;
    user.otpCode = undefined;
    user.otpExpires = undefined;
    await user.save({ validateBeforeSave: false });

    sendToken(user, 200, res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── RESEND OTP ──────────────────────────────────────────────────────────────
router.post('/resend-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Please provide your email' });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: 'No account found with that email' });
    if (user.isVerified) return res.status(400).json({ success: false, message: 'Account is already verified' });

    const otp = generateOtp();
    await sendOtpEmail(user, otp);

    res.status(200).json({ success: true, message: 'A new verification code has been sent to your email.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── LOGIN ────────────────────────────────────────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ success: false, message: 'Please provide email and password' });

    const user = await User.findOne({ email }).select('+password_hash');
    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    if (!user.isVerified) {
      return res.status(401).json({ success: false, message: 'Please verify your email first.', requiresOtp: true, email });
    }

    const patientId = await getPatientId(user._id);
    await AuditLog.create({
      patient_id: patientId,
      actor_user_id: user._id,
      action_type: 'login',
      action_status: 'success',
      details: 'User logged in',
      ip_address: req.ip,
    });

    sendToken(user, 200, res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── LOGOUT ──────────────────────────────────────────────────────────────────
router.post('/logout', protect, async (req, res) => {
  try {
    const patientId = await getPatientId(req.user._id);
    await AuditLog.create({
      patient_id: patientId,
      actor_user_id: req.user._id,
      action_type: 'logout',
      action_status: 'success',
      details: 'User logged out',
      ip_address: req.ip,
    });
    res.status(200).json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── FORGOT PASSWORD ─────────────────────────────────────────────────────────
router.post('/forgot-password', async (req, res) => {
  try {
    const user = await User.findOne({ email: req.body.email });
    if (!user) return res.status(404).json({ success: false, message: 'No account found with that email' });

    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    user.resetPasswordExpires = Date.now() + 10 * 60 * 1000;
    await user.save({ validateBeforeSave: false });

    const resetUrl = `https://medi-vault-backend-28w8.onrender.com/reset-password/${resetToken}`;
    await sendPasswordResetEmail(user, resetUrl);

    res.status(200).json({ success: true, message: 'Password reset email sent' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── RESET PASSWORD ──────────────────────────────────────────────────────────
router.put('/reset-password/:token', async (req, res) => {
  try {
    const hashed = crypto.createHash('sha256').update(req.params.token).digest('hex');
    const user = await User.findOne({ resetPasswordToken: hashed, resetPasswordExpires: { $gt: Date.now() } });
    if (!user) return res.status(400).json({ success: false, message: 'Token is invalid or has expired' });

    if (!validatePassword(req.body.password)) {
      return res.status(400).json({ success: false, message: 'Password must include uppercase, lowercase, a number, and a special character' });
    }

    user.password_hash = req.body.password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    const patientId = await getPatientId(user._id);
    await AuditLog.create({
      patient_id: patientId || user._id,
      actor_user_id: user._id,
      action_type: 'password_reset',
      action_status: 'success',
      details: 'Password was reset via email link',
      ip_address: req.ip,
    });

    sendToken(user, 200, res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── CHANGE PASSWORD ─────────────────────────────────────────────────────────
router.put('/change-password', protect, async (req, res) => {
  try {
    const { current_password, new_password } = req.body;
    if (!current_password || !new_password) {
      return res.status(400).json({ success: false, message: 'Please provide current and new password' });
    }

    const user = await User.findById(req.user.id).select('+password_hash');
    if (!user || !(await user.matchPassword(current_password))) {
      return res.status(401).json({ success: false, message: 'Current password is incorrect' });
    }

    if (!validatePassword(new_password)) {
      return res.status(400).json({ success: false, message: 'New password must include uppercase, lowercase, a number, and a special character' });
    }

    if (current_password === new_password) {
      return res.status(400).json({ success: false, message: 'New password must be different from current password' });
    }

    user.password_hash = new_password;
    await user.save();

    res.status(200).json({ success: true, message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── DELETE ACCOUNT ──────────────────────────────────────────────────────────
router.delete('/delete-account', protect, async (req, res) => {
  try {
    const { password } = req.body;
    const user = await User.findById(req.user.id).select('+password_hash');

    if (user.auth_provider !== 'google') {
      if (!password) return res.status(400).json({ success: false, message: 'Please provide your password to confirm' });
      if (!user || !(await user.matchPassword(password))) {
        return res.status(401).json({ success: false, message: 'Password is incorrect' });
      }
    }

    const MedicalRecord = require('../models/MedicalRecord');
    const AccessPermission = require('../models/AccessPermission');

    if (user.role === 'patient') {
      const patient = await Patient.findOne({ user_id: user._id });
      if (patient) {
        await MedicalRecord.deleteMany({ patient_id: patient._id });
        await AccessPermission.deleteMany({ patient_id: patient._id });
        await AuditLog.deleteMany({ patient_id: patient._id });
        await Patient.deleteOne({ _id: patient._id });
      }
    } else if (user.role === 'doctor') {
      const provider = await HealthcareProvider.findOne({ user_id: user._id });
      if (provider) {
        await AccessPermission.deleteMany({ provider_id: provider._id });
        await HealthcareProvider.deleteOne({ _id: provider._id });
      }
    }

    await User.deleteOne({ _id: user._id });
    res.status(200).json({ success: true, message: 'Account deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── PROFILE ─────────────────────────────────────────────────────────────────
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    let profile = {
      id: user._id, first_name: user.first_name, last_name: user.last_name,
      email: user.email, phone_number: user.phone_number || '', role: user.role,
      auth_provider: user.auth_provider,
      gender: user.gender || '',
      profile_picture: user.profile_picture || null,
    };

    if (user.role === 'patient') {
      const patient = await Patient.findOne({ user_id: user._id });
      if (patient) {
        profile.date_of_birth = patient.date_of_birth || null;
        profile.address = patient.address || '';
      }
    } else if (user.role === 'doctor') {
      const provider = await HealthcareProvider.findOne({ user_id: user._id });
      if (provider) {
        profile.specialization = provider.specialization || '';
        profile.organisation_name = provider.organisation_name || '';
      }
    }

    res.status(200).json({ success: true, profile });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.put('/profile', protect, async (req, res) => {
  try {
    const { first_name, last_name, phone_number, gender, specialization, organisation_name, date_of_birth, address } = req.body;

    const userSet = {};
    if (first_name     !== undefined) userSet.first_name     = first_name;
    if (last_name      !== undefined) userSet.last_name      = last_name;
    if (phone_number   !== undefined) userSet.phone_number   = phone_number;
    if (gender         !== undefined) userSet.gender         = gender || null;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      { $set: userSet },
      { new: true }
    );
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if (user.role === 'patient') {
      const patientSet = {};
      if (date_of_birth !== undefined) patientSet.date_of_birth = date_of_birth;
      if (gender        !== undefined) patientSet.gender        = gender || null;
      if (address       !== undefined) patientSet.address       = address;
      if (Object.keys(patientSet).length) {
        await Patient.findOneAndUpdate({ user_id: user._id }, { $set: patientSet });
      }
    } else if (user.role === 'doctor') {
      const providerSet = {};
      if (specialization    !== undefined) providerSet.specialization    = specialization;
      if (organisation_name !== undefined) providerSet.organisation_name = organisation_name;
      if (Object.keys(providerSet).length) {
        await HealthcareProvider.findOneAndUpdate({ user_id: user._id }, { $set: providerSet });
      }
    }

    res.status(200).json({ success: true, message: 'Profile updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── PROFILE PICTURE ─────────────────────────────────────────────────────────
router.post('/profile/picture', protect, require('../middleware/upload').single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });
    if (!req.file.mimetype.startsWith('image/')) {
      return res.status(400).json({ success: false, message: 'Only image files are allowed' });
    }

    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const ext = req.file.originalname.split('.').pop().toLowerCase();
    const fileName = `profile_pictures/${user._id}_${Date.now()}.${ext}`;
    let fileUrl;

    if (bucket) {
      const firebaseFile = bucket.file(fileName);
      await firebaseFile.save(req.file.buffer, { metadata: { contentType: req.file.mimetype } });
      await firebaseFile.makePublic();
      fileUrl = `https://storage.googleapis.com/${process.env.FIREBASE_STORAGE_BUCKET}/${fileName}`;
    } else {
      const fs = require('fs/promises');
      const path = require('path');
      const uploadDir = path.join(__dirname, '..', 'uploads');
      await fs.mkdir(uploadDir, { recursive: true });
      const localName = `profile_${user._id}_${Date.now()}.${ext}`;
      await fs.writeFile(path.join(uploadDir, localName), req.file.buffer);
      fileUrl = `${req.protocol}://${req.get('host')}/uploads/${localName}`;
    }

    user.profile_picture = fileUrl;
    await user.save({ validateBeforeSave: false });

    res.status(200).json({ success: true, profile_picture: fileUrl });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── SEARCH DOCTOR ───────────────────────────────────────────────────────────
router.get('/search-doctor', protect, authorise('patient'), async (req, res) => {
  try {
    const { email } = req.query;
    if (!email) return res.status(400).json({ success: false, message: 'Please provide an email to search' });

    const user = await User.findOne({ email: { $regex: email, $options: 'i' }, role: 'doctor' });
    if (!user) return res.status(404).json({ success: false, message: 'No doctor found with that email' });

    const provider = await HealthcareProvider.findOne({ user_id: user._id });

    res.status(200).json({
      success: true,
      doctor: {
        user_id: user._id,
        name: `${user.first_name} ${user.last_name}`,
        email: user.email,
        specialization: provider?.specialization || '',
        organisation_name: provider?.organisation_name || '',
        gender: user.gender || null,
        profile_picture: user.profile_picture || null,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/doctors', protect, authorise('patient'), async (req, res) => {
  try {
    const organisationName = (req.query.organisation_name || '').toString().trim();
    const specialization = (req.query.specialization || '').toString().trim();
    const search = (req.query.search || '').toString().trim();

    const providerFilter = {};
    if (organisationName) providerFilter.organisation_name = { $regex: `^${escapeRegex(organisationName)}$`, $options: 'i' };
    if (specialization) providerFilter.specialization = { $regex: `^${escapeRegex(specialization)}$`, $options: 'i' };

    const userMatch = { role: 'doctor' };
    if (search) {
      userMatch.$or = [
        { first_name: { $regex: escapeRegex(search), $options: 'i' } },
        { last_name: { $regex: escapeRegex(search), $options: 'i' } },
        { email: { $regex: escapeRegex(search), $options: 'i' } },
      ];
    }

    const providers = await HealthcareProvider.find(providerFilter)
      .populate({ path: 'user_id', select: 'first_name last_name email role isVerified gender profile_picture', match: userMatch })
      .sort({ organisation_name: 1, specialization: 1, createdAt: -1 });

    const doctors = providers.filter(p => p.user_id).map(p => ({
      user_id: p.user_id._id,
      name: `${p.user_id.first_name} ${p.user_id.last_name}`,
      email: p.user_id.email,
      specialization: p.specialization || '',
      organisation_name: p.organisation_name || '',
      gender: p.user_id.gender || null,
      profile_picture: p.user_id.profile_picture || null,
    }));

    const [hospitalsRaw, specializationsRaw] = await Promise.all([
      HealthcareProvider.distinct('organisation_name', {}),
      HealthcareProvider.distinct('specialization', {}),
    ]);

    const hospitals = mergeWithDefaults(hospitalsRaw.map(v => v?.toString().trim()).filter(Boolean), SL_DEFAULT_HOSPITALS);
    const specializations = mergeWithDefaults(specializationsRaw.map(v => v?.toString().trim()).filter(Boolean), SL_DEFAULT_SPECIALIZATIONS);

    res.status(200).json({ success: true, doctors, filters: { hospitals, specializations } });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
