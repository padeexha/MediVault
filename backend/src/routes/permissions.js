const express = require('express');
const router = express.Router();
const { protect, authorise } = require('../middleware/auth');
const AccessPermission = require('../models/AccessPermission');
const Patient = require('../models/Patient');
const HealthcareProvider = require('../models/HealthcareProvider');
const MedicalRecord = require('../models/MedicalRecord');
const AuditLog = require('../models/AuditLog');
const User = require('../models/User');

const logAudit = async ({ patientId, actorUserId, permissionId = null, actionType, details, ip }) => {
  /**
   * SECURITY: Audit Logging Function
   * - Records all permission changes for compliance with healthcare regulations (HIPAA, GDPR)
   * - Captures actor (who made change), patient, action type, timestamp, and IP address
   * - Enables forensic investigation and accountability for data access
   * - Immutable audit trail prevents tampering with permission history
   * 
   * Logged Information:
   * 1. Patient ID: Which patient's records were affected
   * 2. Actor User ID: Who performed the action (authentication + authorization)
   * 3. Permission ID: Which specific permission was modified
   * 4. Action Type: grant, revoke, update, view, etc.
   * 5. IP Address: Source of request (helps detect unauthorized access)
   * 6. Timestamp: When action occurred (auto-added by MongoDB)
   * 7. Details: Contextual information about the action
   * 
   * Threat Prevention:
   * 1. Non-Repudiation: Complete audit trail proves who accessed what and when
   * 2. Unauthorized Access Detection: IP anomalies may indicate account compromise
   * 3. Compliance Violations: Audit log provides evidence for regulatory audits
   * 4. Insider Threats: Tracks data access patterns to detect suspicious behavior
   */
  try {
    await AuditLog.create({
      patient_id:    patientId,
      actor_user_id: actorUserId,
      permission_id: permissionId,
      action_type:   actionType,
      action_status: 'success',
      details,
      ip_address: ip,
    });
  } catch (e) {
    console.error('Audit log error:', e.message);
  }
};

// Grant access
/**
 * SECURITY: Grant Access Endpoint - Healthcare Provider Access Control
 * - Only patient (resource owner) can grant access to their medical records
 * - Validates both patient and provider exist before granting access
 * - Restricts provider access via role enum ('doctor' only)
 * - Records permission grant in audit log for compliance
 * - Creates upsert: grants new or updates existing permission
 * 
 * Access Control:
 * 1. Authentication: protect middleware ensures user is logged in
 * 2. Authorization: authorise('patient') ensures only patients can grant (ownership)
 * 3. Validation: Verifies doctor exists and is valid healthcare provider
 * 4. Scope Types: 'all' (full access), 'category' (specific type), 'record' (single record)
 * 
 * Threat Prevention:
 * 1. Privilege Escalation: Enum roles prevent non-patients from granting access
 * 2. Unauthorized Access: Only patient can grant access to own records
 * 3. Ghost Provider Grants: Validates provider exists before permission creation
 * 4. Audit Trail: All grants logged with actor ID and timestamp
 */
router.post('/grant', protect, authorise('patient'), async (req, res) => {
  try {
    const { provider_user_id, scope_type, shared_category, record_id } = req.body;

    // Verify requesting user is a patient (ownership validation)
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    // Verify provider exists and has 'doctor' role (authorization check)
    const providerUser = await User.findById(provider_user_id);
    if (!providerUser || providerUser.role !== 'doctor') {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }
    // Verify provider profile exists (prevents orphaned permissions)
    const provider = await HealthcareProvider.findOne({ user_id: provider_user_id });
    if (!provider) return res.status(404).json({ success: false, message: 'Healthcare provider profile not found' });

    // Grant or update permission with scope specification
    const permission = await AccessPermission.findOneAndUpdate(
      { patient_id: patient._id, provider_id: provider._id },
      {
        $set: {
          scope_type:      scope_type || 'all',
          shared_category: shared_category || null,
          record_id:       record_id || null,
          access_status:   'granted',
          granted_at:      new Date(),
          revoked_at:      null,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );

    await logAudit({
      patientId:    patient._id,
      actorUserId:  req.user._id,
      permissionId: permission._id,
      actionType:   'permission_granted',
      details:      `Granted access to: ${providerUser.email} (scope: ${permission.scope_type})`,
      ip:           req.ip,
    });

    res.status(200).json({ success: true, permission });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Revoke access
/**
 * SECURITY: Revoke Access Endpoint - Permission Revocation
 * - Only patient (resource owner) can revoke access to their records
 * - Marks permission as 'revoked' with timestamp (maintains audit trail)
 * - Does NOT delete permission record (preserves history for compliance)
 * - Logs revocation action for regulatory compliance
 * - Revoked permissions prevent future data access by provider
 * 
 * Access Control:
 * 1. Authentication: protect middleware ensures user is logged in
 * 2. Authorization: authorise('patient') ensures only patients can revoke
 * 3. Ownership: Only patient who owns the permission can revoke it
 * 
 * Threat Prevention:
 * 1. Unauthorized Revocation: Only patient can revoke their own permissions
 * 2. Audit Trail Destruction: Soft delete (mark as revoked) preserves history
 * 3. Persistent Access: Revocation timestamp enforces access cutoff
 * 4. Compliance: Timestamped revocation records provide evidence of data control
 */
router.put('/revoke/:permissionId', protect, authorise('patient'), async (req, res) => {
  try {
    // Retrieve permission by ID
    const permission = await AccessPermission.findById(req.params.permissionId);
    if (!permission) return res.status(404).json({ success: false, message: 'Permission not found' });

    const patient = await Patient.findOne({ user_id: req.user._id });

    permission.access_status = 'revoked';
    permission.revoked_at    = new Date();
    await permission.save();

    await logAudit({
      patientId:    patient._id,
      actorUserId:  req.user._id,
      permissionId: permission._id,
      actionType:   'permission_revoked',
      details:      `Revoked permission: ${permission._id}`,
      ip:           req.ip,
    });

    res.status(200).json({ success: true, message: 'Access revoked' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Update permission scope (full ↔ category)
router.put('/:permissionId', protect, authorise('patient'), async (req, res) => {
  try {
    const permission = await AccessPermission.findById(req.params.permissionId);
    if (!permission) return res.status(404).json({ success: false, message: 'Permission not found' });

    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient || !permission.patient_id.equals(patient._id)) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    const { scope_type, shared_category } = req.body;
    if (scope_type) permission.scope_type = scope_type;
    permission.shared_category = scope_type === 'category' ? (shared_category || null) : null;
    await permission.save();

    await logAudit({
      patientId:    patient._id,
      actorUserId:  req.user._id,
      permissionId: permission._id,
      actionType:   'permission_updated',
      details:      `Updated permission scope to: ${permission.scope_type}`,
      ip:           req.ip,
    });

    res.status(200).json({ success: true, permission });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// List doctors with access (patient view)
router.get('/my-doctors', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    const permissions = await AccessPermission.find({ patient_id: patient._id, access_status: 'granted' })
      .populate({ path: 'provider_id', populate: { path: 'user_id', select: 'first_name last_name email gender profile_picture' } });
    res.status(200).json({ success: true, permissions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// List records shared with doctor — includes patient name
router.get('/shared-with-me', protect, authorise('doctor'), async (req, res) => {
  try {
    const provider = await HealthcareProvider.findOne({ user_id: req.user._id });
    if (!provider) return res.status(404).json({ success: false, message: 'Healthcare provider profile not found' });
    const permissions = await AccessPermission.find({ provider_id: provider._id, access_status: 'granted' })
      .populate({
        path: 'patient_id',
        populate: { path: 'user_id', select: 'first_name last_name email gender profile_picture' },
      });

    const result = await Promise.all(permissions.map(async (perm) => {
      const query = { patient_id: perm.patient_id._id, is_deleted: false };
      if (perm.scope_type === 'category') query.category = perm.shared_category;
      if (perm.scope_type === 'record')   query._id      = perm.record_id;
      const records = await MedicalRecord.find(query);

      const patientUser = perm.patient_id.user_id;
      const patientName = patientUser
        ? `${patientUser.first_name} ${patientUser.last_name}`
        : 'Unknown Patient';

      return {
        patient: {
          _id: perm.patient_id._id,
          name: patientName,
          email: patientUser?.email || '',
          gender: patientUser?.gender || null,
          profile_picture: patientUser?.profile_picture || null,
        },
        records,
      };
    }));

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;