const express = require('express');
const router = express.Router();
const { protect, authorise } = require('../middleware/auth');
const AccessPermission = require('../models/AccessPermission');
const Patient = require('../models/Patient');
const HealthcareProvider = require('../models/HealthcareProvider');
const MedicalRecord = require('../models/MedicalRecord');
const AuditLog = require('../models/AuditLog');
const User = require('../models/User');

// Writes an audit entry for permission events. Failures here shouldn't break
// the main request, so errors are swallowed after logging.
const logAudit = async ({ patientId, actorUserId, permissionId = null, actionType, details, ip }) => {
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

// Grant or update access from a patient to a specific doctor.
// Uses upsert so granting again updates scope rather than creating a duplicate.
router.post('/grant', protect, authorise('patient'), async (req, res) => {
  try {
    const { provider_user_id, scope_type, shared_category, record_id } = req.body;

    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });

    const providerUser = await User.findById(provider_user_id);
    if (!providerUser || providerUser.role !== 'doctor') {
      return res.status(404).json({ success: false, message: 'Doctor not found' });
    }

    const provider = await HealthcareProvider.findOne({ user_id: provider_user_id });
    if (!provider) return res.status(404).json({ success: false, message: 'Healthcare provider profile not found' });

    // Upsert keeps one permission document per patient/provider pair and changes its scope in place.
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

// Marks the permission as revoked rather than deleting it so the audit trail stays complete
router.put('/revoke/:permissionId', protect, authorise('patient'), async (req, res) => {
  try {
    const permission = await AccessPermission.findById(req.params.permissionId);
    if (!permission) return res.status(404).json({ success: false, message: 'Permission not found' });

    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });

    // Make sure this permission actually belongs to the requesting patient
    if (!permission.patient_id.equals(patient._id)) {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

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

// Update permission scope (e.g. switching from full access to category-level)
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
    // Clear shared_category when scope is not 'category'
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

// Patient view: lists all doctors currently with granted access
router.get('/my-doctors', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    // Populate provider_id.user_id so the API returns doctor profile fields with each permission.
    const permissions = await AccessPermission.find({ patient_id: patient._id, access_status: 'granted' })
      .populate({ path: 'provider_id', populate: { path: 'user_id', select: 'first_name last_name email gender profile_picture' } });
    res.status(200).json({ success: true, permissions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Doctor view: fetches all patients that have granted the doctor access,
// along with the specific records they can see based on permission scope.
router.get('/shared-with-me', protect, authorise('doctor'), async (req, res) => {
  try {
    const provider = await HealthcareProvider.findOne({ user_id: req.user._id });
    if (!provider) return res.status(404).json({ success: false, message: 'Healthcare provider profile not found' });
    // Load active permission documents first, then translate each scope into a MedicalRecord query.
    const permissions = await AccessPermission.find({ provider_id: provider._id, access_status: 'granted' })
      .populate({
        path: 'patient_id',
        populate: { path: 'user_id', select: 'first_name last_name email gender profile_picture' },
      });

    const result = await Promise.all(permissions.map(async (perm) => {
      // Build the record query from the permission scope without exposing unrelated records.
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
