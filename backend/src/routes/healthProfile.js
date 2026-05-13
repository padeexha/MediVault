const express = require('express');
const router  = express.Router();
const { protect } = require('../middleware/auth');
const HealthProfile = require('../models/HealthProfile');
const User = require('../models/User');

// ── Patient: get own health profile (with access requests) ──────────────────
router.get('/my-profile', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });
    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    return res.json({ success: true, profile: profile || null, exists: !!profile });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── Patient: save (create or update) health profile ─────────────────────────
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

// ── Doctor: request access to a patient's health profile ────────────────────
router.post('/request-access', protect, async (req, res) => {
  try {
    if (req.user.role !== 'doctor')
      return res.status(403).json({ success: false, message: 'Doctors only' });

    const { patient_email } = req.body;
    if (!patient_email)
      return res.status(400).json({ success: false, message: 'patient_email is required' });

    const patientUser = await User.findOne({
      email: patient_email.toLowerCase().trim(),
      role: 'patient',
    });
    if (!patientUser)
      return res.status(404).json({ success: false, message: 'Patient not found' });

    const doctorName = `${req.user.first_name || ''} ${req.user.last_name || ''}`.trim();

    let profile = await HealthProfile.findOne({ patient_id: patientUser._id });
    if (!profile) profile = new HealthProfile({ patient_id: patientUser._id });

    const existing = profile.access_requests.find(
      r => r.doctor_id.toString() === req.user._id.toString(),
    );

    if (existing) {
      if (existing.status === 'approved')
        return res.status(400).json({ success: false, message: 'You already have access to this profile' });
      if (existing.status === 'pending')
        return res.status(400).json({ success: false, message: 'Access request is already pending' });
      existing.status       = 'pending';
      existing.requested_at = new Date();
      existing.responded_at = undefined;
    } else {
      profile.access_requests.push({
        doctor_id:    req.user._id,
        doctor_name:  doctorName,
        doctor_email: req.user.email,
        status:       'pending',
      });
    }

    await profile.save();
    res.json({ success: true, message: 'Access request sent to patient' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ── Patient: approve a doctor's access request ──────────────────────────────
router.put('/approve/:requestId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    if (!profile) return res.status(404).json({ success: false, message: 'Profile not found' });

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

// ── Patient: reject a doctor's access request ───────────────────────────────
router.put('/reject/:requestId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    if (!profile) return res.status(404).json({ success: false, message: 'Profile not found' });

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

// ── Patient: revoke an approved doctor's access ─────────────────────────────
router.put('/revoke/:requestId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'patient')
      return res.status(403).json({ success: false, message: 'Patients only' });

    const profile = await HealthProfile.findOne({ patient_id: req.user._id });
    if (!profile) return res.status(404).json({ success: false, message: 'Profile not found' });

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

// ── Doctor: view a patient's health profile (approved only) ─────────────────
router.get('/view/:patientId', protect, async (req, res) => {
  try {
    if (req.user.role !== 'doctor')
      return res.status(403).json({ success: false, message: 'Doctors only' });

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

// ── Doctor: list all patients they have requested / have access to ───────────
router.get('/my-access', protect, async (req, res) => {
  try {
    if (req.user.role !== 'doctor')
      return res.status(403).json({ success: false, message: 'Doctors only' });

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
