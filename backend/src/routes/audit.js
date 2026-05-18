const express = require('express');
const router = express.Router();
const { protect, authorise } = require('../middleware/auth');
const AuditLog = require('../models/AuditLog');
const Patient = require('../models/Patient');

// Returns all audit log entries for the logged-in patient, newest first.
// Populates actor, record and permission fields so the client can display names
// without making extra requests.
router.get('/my-logs', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });

    // Populate references so audit results include readable actor, record, and permission details.
    const logs = await AuditLog.find({ patient_id: patient._id })
      .populate('actor_user_id', 'first_name last_name role')
      .populate('record_id',     'title category')
      .populate('permission_id', 'scope_type access_status')
      .sort({ action_date: -1 });

    res.status(200).json({ success: true, count: logs.length, logs });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
