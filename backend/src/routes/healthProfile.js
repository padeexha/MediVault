const express = require('express');
const router  = express.Router();
const { protect } = require('../middleware/auth');
const HealthProfile = require('../models/HealthProfile');
const User = require('../models/User');

// Returns the patient's own health profile including the access_requests array
// so the client can show which doctors currently have access.
router.get('/my-profile', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });
    // HealthProfile uses the patient's User id as patient_id, so this lookup returns the caller's profile.
    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    return res.json({ success: true, profile: profile || null, exists: !!profile });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Create or update the patient's health profile (upsert).
// Array fields default to empty arrays if not provided so partial saves work correctly.
router.post('/save', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    const {
      full_name, age, gender, height, weight, blood_group,
      allergies, current_medications, chronic_conditions,
      emergency_contact_name, emergency_contact_number,
    } = req.body;

    const update = {
      full_name:                full_name || '',
      age:                      age ?? null,
      gender:                   gender || '',
      height:                   height || '',
      weight:                   weight || '',
      blood_group:              blood_group || '',
      allergies:                Array.isArray(allergies) ? allergies : [],
      current_medications:      Array.isArray(current_medications) ? current_medications : [],
      chronic_conditions:       Array.isArray(chronic_conditions) ? chronic_conditions : [],
      emergency_contact_name:   emergency_contact_name || '',
      emergency_contact_number: emergency_contact_number || '',
    };

    // Upsert creates the profile on first save and updates the same document after that.
    const profile = await HealthProfile.findOneAndUpdate(
      { patient_id: req.user._id },
      { $set: update },
      { new: true, upsert: true, setDefaultsOnInsert: true },
    );

    res.json({ success: true, message: 'Health profile saved', profile });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Disabled — doctors can't request access; patients must grant it directly via /grant-access
router.post('/request-access', protect, async (_req, res) => {
  return res.status(403).json({
    success: false,
    message: 'Doctors cannot request Health Profile access. Patients must grant access directly.',
  });
});

// Allows a patient to grant a doctor access by email without waiting for a request.
// If the doctor already has a non-approved entry, it gets flipped to approved.
router.post('/grant-access', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    const { doctor_email } = req.body;
    if (!doctor_email)
      return res.status(400).json({ success: false, message: 'doctor_email is required' });

    const doctorUser = await User.findOne({
      email: doctor_email.toLowerCase().trim(),
      role: 'doctor',
    });
    if (!doctorUser)
      return res.status(404).json({ success: false, message: 'Doctor not found' });

    const doctorName = `${doctorUser.first_name || ''} ${doctorUser.last_name || ''}`.trim();

    // Load or create the profile document before updating its embedded access_requests array.
    let profile = await HealthProfile.findOne({ patient_id: req.user._id });
    if (!profile) profile = new HealthProfile({ patient_id: req.user._id });

    // Embedded access requests are matched by doctor id to avoid duplicate access entries.
    const existing = profile.access_requests.find(
      r => r.doctor_id.toString() === doctorUser._id.toString(),
    );

    if (existing) {
      if (existing.status === 'approved')
        return res.status(400).json({ success: false, message: 'This doctor already has access to your profile' });
      existing.status       = 'approved';
      existing.responded_at = new Date();
    } else {
      profile.access_requests.push({
        doctor_id:    doctorUser._id,
        doctor_name:  doctorName,
        doctor_email: doctorUser.email,
        status:       'approved',
        responded_at: new Date(),
      });
    }

    await profile.save();
    res.json({ success: true, message: `Access granted to Dr. ${doctorName}` });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/approve/:requestId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    // Only the patient owner can update a request stored inside their profile document.
    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    if (!profile) return res.status(404).json({ success: false, message: 'Profile not found' });

    // Mongoose subdocument lookup finds the embedded request by its _id.
    const request = profile.access_requests.id(req.params.requestId);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    request.status       = 'approved';
    request.responded_at = new Date();
    await profile.save();
    res.json({ success: true, message: 'Access approved' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/reject/:requestId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    // Only the patient owner can update a request stored inside their profile document.
    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    if (!profile) return res.status(404).json({ success: false, message: 'Profile not found' });

    // Mongoose subdocument lookup finds the embedded request by its _id.
    const request = profile.access_requests.id(req.params.requestId);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    request.status       = 'rejected';
    request.responded_at = new Date();
    await profile.save();
    res.json({ success: true, message: 'Access rejected' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.put('/revoke/:requestId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    // Only the patient owner can revoke a request stored inside their profile document.
    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    if (!profile) return res.status(404).json({ success: false, message: 'Profile not found' });

    // Mongoose subdocument lookup finds the embedded request by its _id.
    const request = profile.access_requests.id(req.params.requestId);
    if (!request) return res.status(404).json({ success: false, message: 'Request not found' });

    request.status       = 'revoked';
    request.responded_at = new Date();
    await profile.save();
    res.json({ success: true, message: 'Access revoked' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Doctor can view a patient's profile only if there's an approved entry in access_requests.
// The access_requests array is stripped from the response so doctors can't see who else has access.
router.get('/view/:patientId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'doctor')
      return res.status(403).json({ success: false, message: 'Doctors only' });

    // Doctors request a patient profile by User id, then access is checked against embedded approvals.
    const profile = await HealthProfile.findOne({ patient_id: req.params.patientId });
    if (!profile)
      return res.status(404).json({ success: false, message: 'Profile not found or not yet created' });

    const access = profile.access_requests.find(
      r => r.doctor_id.toString() === req.user._id.toString() && r.status === 'approved',
    );
    if (!access)
      return res.status(403).json({ success: false, message: 'You do not have approved access to this profile' });

    const { access_requests, ...profileData } = profile.toObject();
    res.json({ success: true, profile: profileData });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// Returns all patients that have an access_requests entry for this doctor,
// regardless of status, so the doctor can see approved and revoked history.
router.get('/my-access', protect, async (req, res) => {
  try {
    if (req.user.role !== 'doctor')
      return res.status(403).json({ success: false, message: 'Doctors only' });

    // Query embedded access_requests to list every patient profile connected to this doctor.
    const profiles = await HealthProfile.find({
      'access_requests.doctor_id': req.user._id,
    }).populate('patient_id', 'first_name last_name email profile_picture gender');

    const result = profiles
      .filter(p => p.patient_id)
      .map(p => {
        const myRequest = p.access_requests.find(
          r => r.doctor_id.toString() === req.user._id.toString(),
        );
        const patient = p.patient_id;
        return {
          patient_id:      patient._id,
          patient_name:    `${patient.first_name || ''} ${patient.last_name || ''}`.trim(),
          patient_email:   patient.email,
          patient_picture: patient.profile_picture,
          patient_gender:  patient.gender,
          request_id:      myRequest._id,
          status:          myRequest.status,
          requested_at:    myRequest.requested_at,
          responded_at:    myRequest.responded_at,
        };
      });

    res.json({ success: true, data: result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
