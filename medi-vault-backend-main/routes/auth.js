const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { body, validationResult } = require('express-validator');

const User = require('../models/User');
const Patient = require('../models/Patient');
const HealthcareProvider = require('../models/HealthcareProvider');
const AuditLog = require('../models/AuditLog');
const { protect, authorise } = require('../middleware/auth');

const getPatientId = async (userId) => {
  const patient = await Patient.findOne({ user_id: userId });
  return patient ? patient._id : null;
};

const hasEmailService = () => {
  const apiKey = process.env.BREVO_API_KEY || '';
  return apiKey && !apiKey.includes('your_');
};

const sendVerificationEmail = async (user) => {
  const verificationToken = crypto.randomBytes(32).toString('hex');
  user.emailVerificationToken = crypto.createHash('sha256').update(verificationToken).digest('hex');
  user.emailVerificationExpires = Date.now() + 24 * 60 * 60 * 1000;
  await user.save({ validateBeforeSave: false });

  const verifyUrl = `https://medi-vault-backend-28w8.onrender.com/verify-email/${verificationToken}`;

  if (!hasEmailService()) {
    console.warn(`Email service not configured. Local verification URL: ${verifyUrl}`);
    return false;
  }

  const { BrevoClient } = require('@getbrevo/brevo');
  const client = new BrevoClient({ apiKey: process.env.BREVO_API_KEY });

  await client.transactionalEmails.sendTransacEmail({
    sender: { email: 'medivault41@gmail.com', name: 'Medi Vault' },
    to: [{ email: user.email, name: `${user.first_name} ${user.last_name}` }],
    subject: 'Medi Vault — Verify Your Email',
    htmlContent: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #0F6E56;">Welcome to Medi Vault</h2>
        <p>Thank you for registering. Please verify your email address.</p>
        <p>This link is valid for <strong>24 hours</strong>.</p>
        <a href="${verifyUrl}" style="display: inline-block; padding: 12px 24px; background: #0F6E56; color: white; text-decoration: none; border-radius: 8px; margin: 16px 0;">Verify Email</a>
        <p>If you did not request this, please ignore this email.</p>
      </div>
    `,
  });
  return true;
};

const sendPasswordResetEmail = async (user, resetUrl) => {
  if (!hasEmailService()) {
    console.warn(`Email service not configured. Local reset URL: ${resetUrl}`);
    return false;
  }

  const { BrevoClient } = require('@getbrevo/brevo');
  const client = new BrevoClient({ apiKey: process.env.BREVO_API_KEY });

  await client.transactionalEmails.sendTransacEmail({
    sender: { email: 'medivault41@gmail.com', name: 'Medi Vault' },
    to: [{ email: user.email }],
    subject: 'Medi Vault — Password Reset',
    htmlContent: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #0F6E56;">Medi Vault — Password Reset</h2>
        <p>You requested a password reset. Click the button below.</p>
        <p>This link is valid for <strong>10 minutes</strong>.</p>
        <a href="${resetUrl}" style="display: inline-block; padding: 12px 24px; background: #0F6E56; color: white; text-decoration: none; border-radius: 8px; margin: 16px 0;">Reset Password</a>
        <p>If you did not request this, please ignore this email.</p>
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
  if (password.length < 8) return false;
  if (!/[a-z]/.test(password)) return false;
  if (!/[A-Z]/.test(password)) return false;
  if (!/[0-9]/.test(password)) return false;
  if (!/[^A-Za-z0-9]/.test(password)) return false;
  return true;
};

const escapeRegex = (value = '') => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const SL_DEFAULT_HOSPITALS = [
  'Apollo Hospital Colombo',
  'Asiri Central Hospital',
  'Asiri Surgical Hospital',
  'Base Hospital Kurunegala',
  'District General Hospital Batticaloa',
  'District General Hospital Galle',
  'District General Hospital Matara',
  'District General Hospital Ratnapura',
  'Durdans Hospital',
  'Hemas Hospital Colombo',
  'Hemas Hospital Wattala',
  'Lady Ridgeway Hospital',
  'Lanka Hospital',
  'Nawaloka Hospital',
  'National Hospital of Sri Lanka',
  'Ninewells Hospital',
  'Sirimavo Bandaranaike Children\'s Hospital',
  'Sri Jayewardenepura General Hospital',
  'Teaching Hospital Jaffna',
  'Teaching Hospital Kandy',
  'Teaching Hospital Karapitiya',
  'Teaching Hospital Kurunegala',
  'Teaching Hospital Ratnapura',
];

const SL_DEFAULT_SPECIALIZATIONS = [
  'Anesthesiology',
  'Cardiology',
  'Dermatology',
  'Emergency Medicine',
  'Endocrinology',
  'ENT (Ear, Nose & Throat)',
  'Family Medicine',
  'Gastroenterology',
  'General Medicine',
  'General Surgery',
  'Gynecology & Obstetrics',
  'Hematology',
  'Infectious Diseases',
  'Nephrology',
  'Neurology',
  'Oncology',
  'Ophthalmology',
  'Orthopedic Surgery',
  'Pediatrics',
  'Plastic Surgery',
  'Psychiatry',
  'Pulmonology',
  'Radiology',
  'Rheumatology',
  'Urology',
];

const mergeWithDefaults = (dbValues, defaults) => {
  const seen = new Set(dbValues.map(v => v.toLowerCase()));
  const merged = [...dbValues];
  for (const d of defaults) {
    if (!seen.has(d.toLowerCase())) merged.push(d);
  }
  return merged.sort((a, b) => a.localeCompare(b));
};

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
        message: 'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character',
      });
    }

    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ success: false, message: 'Email is already registered' });

    const user = await User.create({
      first_name, last_name, email,
      password_hash: password,
      role: 'patient',
      phone_number,
    });

    await Patient.create({ user_id: user._id, date_of_birth, gender, address });
    const verificationSent = await sendVerificationEmail(user);
    if (!verificationSent) {
      user.isVerified = true;
      user.emailVerificationToken = undefined;
      user.emailVerificationExpires = undefined;
      await user.save({ validateBeforeSave: false });
    }

    res.status(201).json({
      success: true,
      message: verificationSent
        ? 'Registration successful. Please check your email to verify your account.'
        : 'Registration successful. Email service is not configured locally, so the account was auto-verified.',
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

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
        message: 'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character',
      });
    }

    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ success: false, message: 'Email is already registered' });

    const user = await User.create({
      first_name, last_name, email,
      password_hash: password,
      role: 'doctor',
      phone_number,
    });

    await HealthcareProvider.create({ user_id: user._id, specialization, organisation_name });
    const verificationSent = await sendVerificationEmail(user);
    if (!verificationSent) {
      user.isVerified = true;
      user.emailVerificationToken = undefined;
      user.emailVerificationExpires = undefined;
      await user.save({ validateBeforeSave: false });
    }

    res.status(201).json({
      success: true,
      message: verificationSent
        ? 'Registration successful. Please check your email to verify your account.'
        : 'Registration successful. Email service is not configured locally, so the account was auto-verified.',
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ success: false, message: 'Please provide email and password' });

    const user = await User.findOne({ email }).select('+password_hash');
    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    if (!user.isVerified) {
      return res.status(401).json({ success: false, message: 'Please verify your email before logging in. Check your inbox.' });
    }

    const patientId = await getPatientId(user._id);
    await AuditLog.create({
      patient_id:    patientId,
      actor_user_id: user._id,
      action_type:   'login',
      action_status: 'success',
      details:       'User logged in',
      ip_address:    req.ip,
    });

    sendToken(user, 200, res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/logout', protect, async (req, res) => {
  try {
    const patientId = await getPatientId(req.user._id);
    await AuditLog.create({
      patient_id:    patientId,
      actor_user_id: req.user._id,
      action_type:   'logout',
      action_status: 'success',
      details:       'User logged out',
      ip_address:    req.ip,
    });
    res.status(200).json({ success: true, message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

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

router.put('/reset-password/:token', async (req, res) => {
  try {
    const hashed = crypto.createHash('sha256').update(req.params.token).digest('hex');
    const user = await User.findOne({
      resetPasswordToken: hashed,
      resetPasswordExpires: { $gt: Date.now() },
    });
    if (!user) return res.status(400).json({ success: false, message: 'Token is invalid or has expired' });

    if (!validatePassword(req.body.password)) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters and include uppercase, lowercase, a number, and a special character',
      });
    }

    user.password_hash = req.body.password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    const patientId = await getPatientId(user._id);
    await AuditLog.create({
      patient_id:    patientId || user._id,
      actor_user_id: user._id,
      action_type:   'password_reset',
      action_status: 'success',
      details:       'Password was reset via email link',
      ip_address:    req.ip,
    });

    sendToken(user, 200, res);
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

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
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 8 characters and include uppercase, lowercase, a number, and a special character',
      });
    }

    if (current_password === new_password) {
      return res.status(400).json({ success: false, message: 'New password must be different from your current password' });
    }

    user.password_hash = new_password;
    await user.save();

    res.status(200).json({ success: true, message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.delete('/delete-account', protect, async (req, res) => {
  try {
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({ success: false, message: 'Please provide your password to confirm' });
    }

    const user = await User.findById(req.user.id).select('+password_hash');
    if (!user || !(await user.matchPassword(password))) {
      return res.status(401).json({ success: false, message: 'Password is incorrect' });
    }

    const MedicalRecord   = require('../models/MedicalRecord');
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

router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    let profile = {
      id: user._id,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      phone_number: user.phone_number || '',
      role: user.role,
    };

    if (user.role === 'patient') {
      const patient = await Patient.findOne({ user_id: user._id });
      if (patient) {
        profile.date_of_birth = patient.date_of_birth || null;
        profile.gender = patient.gender || '';
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
    const { first_name, last_name, phone_number } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user.id,
      { first_name, last_name, phone_number },
      { new: true, runValidators: true }
    );

    if (user.role === 'patient') {
      const { date_of_birth, gender, address } = req.body;
      await Patient.findOneAndUpdate(
        { user_id: user._id },
        { date_of_birth, gender, address },
        { runValidators: true }
      );
    } else if (user.role === 'doctor') {
      const { specialization, organisation_name } = req.body;
      await HealthcareProvider.findOneAndUpdate(
        { user_id: user._id },
        { specialization, organisation_name },
        { runValidators: true }
      );
    }

    res.status(200).json({ success: true, message: 'Profile updated successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/verify-email/:token', async (req, res) => {
  try {
    const hashed = crypto.createHash('sha256').update(req.params.token).digest('hex');
    const user = await User.findOne({
      emailVerificationToken: hashed,
      emailVerificationExpires: { $gt: Date.now() },
    });

    if (!user) return res.status(400).json({ success: false, message: 'Verification link is invalid or has expired' });

    user.isVerified = true;
    user.emailVerificationToken = undefined;
    user.emailVerificationExpires = undefined;
    await user.save();

    res.status(200).json({ success: true, message: 'Email verified successfully. You can now log in.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Resend verification email
router.post('/resend-verification', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: 'Please provide your email address' });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, message: 'No account found with that email' });
    if (user.isVerified) return res.status(400).json({ success: false, message: 'This account is already verified' });

    await sendVerificationEmail(user);

    res.status(200).json({ success: true, message: 'Verification email sent. Please check your inbox.' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/search-doctor', protect, authorise('patient'), async (req, res) => {
  try {
    const { email } = req.query;
    if (!email) return res.status(400).json({ success: false, message: 'Please provide an email to search' });

    const user = await User.findOne({
      email: { $regex: email, $options: 'i' },
      role: 'doctor',
    });

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
    if (organisationName) {
      providerFilter.organisation_name = {
        $regex: `^${escapeRegex(organisationName)}$`,
        $options: 'i',
      };
    }
    if (specialization) {
      providerFilter.specialization = {
        $regex: `^${escapeRegex(specialization)}$`,
        $options: 'i',
      };
    }

    const userMatch = { role: 'doctor' };
    if (search) {
      userMatch.$or = [
        { first_name: { $regex: escapeRegex(search), $options: 'i' } },
        { last_name: { $regex: escapeRegex(search), $options: 'i' } },
        { email: { $regex: escapeRegex(search), $options: 'i' } },
      ];
    }

    const providers = await HealthcareProvider.find(providerFilter)
      .populate({
        path: 'user_id',
        select: 'first_name last_name email role isVerified',
        match: userMatch,
      })
      .sort({ organisation_name: 1, specialization: 1, createdAt: -1 });

    const doctors = providers
      .filter((provider) => provider.user_id)
      .map((provider) => ({
        user_id: provider.user_id._id,
        name: `${provider.user_id.first_name} ${provider.user_id.last_name}`,
        email: provider.user_id.email,
        specialization: provider.specialization || '',
        organisation_name: provider.organisation_name || '',
      }));

    const hospitalFilter = {};
    if (specialization) {
      hospitalFilter.specialization = {
        $regex: `^${escapeRegex(specialization)}$`,
        $options: 'i',
      };
    }
    const specializationFilter = {};
    if (organisationName) {
      specializationFilter.organisation_name = {
        $regex: `^${escapeRegex(organisationName)}$`,
        $options: 'i',
      };
    }

    const [hospitalsRaw, specializationsRaw] = await Promise.all([
      HealthcareProvider.distinct('organisation_name', hospitalFilter),
      HealthcareProvider.distinct('specialization', specializationFilter),
    ]);

    const hospitalsFromDb = hospitalsRaw.map((v) => v?.toString().trim()).filter(Boolean);
    const specializationsFromDb = specializationsRaw.map((v) => v?.toString().trim()).filter(Boolean);

    const hospitals = mergeWithDefaults(hospitalsFromDb, SL_DEFAULT_HOSPITALS);
    const specializations = mergeWithDefaults(specializationsFromDb, SL_DEFAULT_SPECIALIZATIONS);

    res.status(200).json({
      success: true,
      doctors,
      filters: {
        hospitals,
        specializations,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
