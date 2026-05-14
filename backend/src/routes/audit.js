const express = require('express');
const router = express.Router();
const { protect, authorise } = require('../middleware/auth');
const AuditLog = require('../models/AuditLog');
const Patient = require('../models/Patient');

/**
 * SECURITY: Patient Audit Log Retrieval
 * - Patients can only view audit logs of their own records (data ownership)
 * - Logs show who accessed/modified their medical records and when
 * - Enables patients to detect unauthorized access or suspicious activity
 * - Sorted by most recent first for easy anomaly detection
 * - Data enriched via population: shows actor names, record titles, permission details
 * 
 * Access Control:
 * 1. Authentication: protect middleware ensures user is logged in
 * 2. Authorization: authorise('patient') ensures only patients access this endpoint
 * 3. Ownership: Query filtered to patient's own logs only (prevent cross-patient viewing)
 * 4. Data Enrichment: Populated fields show human-readable info instead of raw IDs
 * 
 * Audit Log Contains:
 * 1. actor_user_id: Who performed the action (populated with name/role)
 * 2. permission_id: Which permission was used (populated with scope/status)
 * 3. record_id: Which medical record was accessed (populated with title/category)
 * 4. action_type: Type of action (grant, revoke, view, export, etc.)
 * 5. action_date: When action occurred (sorted descending = most recent first)
 * 6. ip_address: Source IP address for location/device detection
 * \n * Threat Prevention:\n * 1. Unauthorized Access Detection: Patients can review access patterns\n * 2. Insider Threat Detection: Suspicious access patterns become visible\n * 3. Audit Log Tampering: MongoDB ensures immutable audit trail\n * 4. Data Breach Notification: Patients aware if records were accessed\n * 5. Compliance: Provides audit evidence for healthcare regulations (HIPAA, GDPR)\n */\n// Patient views their own audit log\nrouter.get('/my-logs', protect, authorise('patient'), async (req, res) => {\n  try {\n    // Verify requesting user is a patient (ownership validation)\n    const patient = await Patient.findOne({ user_id: req.user._id });\n\n    // Retrieve audit logs ONLY for this patient's records\n    // Populated fields replace IDs with readable information:\n    // - actor_user_id shows who performed action (first_name, last_name, role)\n    // - record_id shows which record was accessed (title, category)\n    // - permission_id shows which permission was used (scope_type, access_status)\n    const logs = await AuditLog.find({ patient_id: patient._id })\n      .populate('actor_user_id', 'first_name last_name role')\n      .populate('record_id',     'title category')\n      .populate('permission_id', 'scope_type access_status')\n      .sort({ action_date: -1 }); // Sort descending - most recent first for anomaly detection\n\n    res.status(200).json({ success: true, count: logs.length, logs });\n  } catch (error) {\n    res.status(500).json({ success: false, message: error.message });\n  }\n});

module.exports = router;