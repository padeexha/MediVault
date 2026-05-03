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

    let permission = await AccessPermission.findOne({ patient_id: patient._id, provider_id: provider._id });

    if (permission) {
      permission.scope_type      = scope_type || 'all';
      permission.shared_category = shared_category || null;
      permission.record_id       = record_id || null;
      permission.access_status   = 'granted';
      permission.granted_at      = new Date();
      permission.revoked_at      = null;
      await permission.save();
    } else {
      permission = await AccessPermission.create({
        patient_id:      patient._id,
        provider_id:     provider._id,
        scope_type:      scope_type || 'all',
        shared_category: shared_category || null,
        record_id:       record_id || null,
      });
    }

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
router.put('/revoke/:permissionId', protect, authorise('patient'), async (req, res) => {
  try {
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

// List doctors with access (patient view)
router.get('/my-doctors', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    const permissions = await AccessPermission.find({ patient_id: patient._id, access_status: 'granted' })
      .populate({ path: 'provider_id', populate: { path: 'user_id', select: 'first_name last_name email' } });
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
        populate: { path: 'user_id', select: 'first_name last_name email' },
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