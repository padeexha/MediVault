const express = require('express');
const router = express.Router();
const fs = require('fs/promises');
const path = require('path');
const upload = require('../middleware/upload');
const { protect, authorise } = require('../middleware/auth');
const MedicalRecord = require('../models/MedicalRecord');
const Patient = require('../models/Patient');
const HealthcareProvider = require('../models/HealthcareProvider');
const AccessPermission = require('../models/AccessPermission');
const AuditLog = require('../models/AuditLog');
const bucket = require('../config/firebase');

const saveRecordFile = async (req, patientId) => {
  const fileName = `records/${patientId}/${Date.now()}_${req.file.originalname}`;

  if (bucket) {
    const firebaseFile = bucket.file(fileName);
    await firebaseFile.save(req.file.buffer, {
      metadata: { contentType: req.file.mimetype },
    });
    await firebaseFile.makePublic();
    return `https://storage.googleapis.com/${process.env.FIREBASE_STORAGE_BUCKET}/${fileName}`;
  }

  const localName = `${Date.now()}_${req.file.originalname}`;
  const uploadDir = path.join(__dirname, '..', '..', 'uploads');
  await fs.mkdir(uploadDir, { recursive: true });
  await fs.writeFile(path.join(uploadDir, localName), req.file.buffer);
  return `${req.protocol}://${req.get('host')}/uploads/${localName}`;
};

const logAudit = async ({ patientId, actorUserId, recordId = null, permissionId = null, actionType, actionStatus = 'success', details, ip }) => {
  try {
    await AuditLog.create({
      patient_id:    patientId,
      actor_user_id: actorUserId,
      record_id:     recordId,
      permission_id: permissionId,
      action_type:   actionType,
      action_status: actionStatus,
      details,
      ip_address: ip,
    });
  } catch (e) {
    console.error('Audit log error:', e.message);
  }
};

router.post('/upload', protect, authorise('patient'), upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file provided' });

    const { title, category, notes } = req.body;
    if (!title || !category) return res.status(400).json({ success: false, message: 'Title and category are required' });

    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });

    const fileUrl = await saveRecordFile(req, patient._id);

    const record = await MedicalRecord.create({
      patient_id:          patient._id,
      uploaded_by_user_id: req.user._id,
      title,
      category,
      notes,
      file_path: fileUrl,
      file_name: req.file.originalname,
      file_type: req.file.mimetype,
      file_size: req.file.size,
    });

    await logAudit({
      patientId:   patient._id,
      actorUserId: req.user._id,
      recordId:    record._id,
      actionType:  'upload',
      details:     `Uploaded: ${title}`,
      ip:          req.ip,
    });

    res.status(201).json({ success: true, record });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    const records = await MedicalRecord.find({ patient_id: patient._id, is_deleted: false })
      .sort({ upload_date: -1 });
    res.status(200).json({ success: true, count: records.length, records });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.get('/:id', protect, async (req, res) => {
  try {
    const record = await MedicalRecord.findById(req.params.id);
    if (!record || record.is_deleted) return res.status(404).json({ success: false, message: 'Record not found' });

    const patient = await Patient.findById(record.patient_id);
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });

    if (req.user.role === 'patient') {
      if (patient.user_id.toString() !== req.user._id.toString()) {
        return res.status(403).json({ success: false, message: 'Access denied' });
      }
    }

    if (req.user.role === 'doctor') {
      const provider = await HealthcareProvider.findOne({ user_id: req.user._id });
      if (!provider) return res.status(404).json({ success: false, message: 'Healthcare provider profile not found' });
      const permission = await AccessPermission.findOne({
        patient_id:    record.patient_id,
        provider_id:   provider._id,
        access_status: 'granted',
        $or: [
          { scope_type: 'all' },
          { scope_type: 'record',   record_id:       record._id },
          { scope_type: 'category', shared_category: record.category },
        ],
      });

      if (!permission) {
        await logAudit({
          patientId:    patient._id,
          actorUserId:  req.user._id,
          recordId:     record._id,
          actionType:   'view',
          actionStatus: 'failure',
          details:      `Unauthorised view attempt on: ${record.title}`,
          ip:           req.ip,
        });
        return res.status(403).json({ success: false, message: 'You do not have permission to view this record' });
      }
    }

    await logAudit({
      patientId:   patient._id,
      actorUserId: req.user._id,
      recordId:    record._id,
      actionType:  'view',
      details:     `Viewed: ${record.title}`,
      ip:          req.ip,
    });

    res.status(200).json({ success: true, record });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.put('/:id', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    const record = await MedicalRecord.findOne({ _id: req.params.id, patient_id: patient._id });
    if (!record || record.is_deleted) return res.status(404).json({ success: false, message: 'Record not found' });

    const { title, notes, category } = req.body;
    if (title)               record.title    = title;
    if (notes !== undefined) record.notes    = notes;
    if (category)            record.category = category;
    await record.save();

    await logAudit({
      patientId:   patient._id,
      actorUserId: req.user._id,
      recordId:    record._id,
      actionType:  'edit',
      details:     `Edited: ${record.title}`,
      ip:          req.ip,
    });

    res.status(200).json({ success: true, record });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.delete('/:id', protect, authorise('patient'), async (req, res) => {
  try {
    const patient = await Patient.findOne({ user_id: req.user._id });
    if (!patient) return res.status(404).json({ success: false, message: 'Patient profile not found' });
    const record = await MedicalRecord.findOne({ _id: req.params.id, patient_id: patient._id });
    if (!record || record.is_deleted) return res.status(404).json({ success: false, message: 'Record not found' });

    record.is_deleted = true;
    record.deleted_at = new Date();
    await record.save();

    await logAudit({
      patientId:   patient._id,
      actorUserId: req.user._id,
      recordId:    record._id,
      actionType:  'delete',
      details:     `Deleted: ${record.title}`,
      ip:          req.ip,
    });

    res.status(200).json({ success: true, message: 'Record deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

router.post('/:id/download', protect, async (req, res) => {
  try {
    const record = await MedicalRecord.findById(req.params.id);
    if (!record || record.is_deleted) return res.status(404).json({ success: false, message: 'Record not found' });

    const patient = await Patient.findById(record.patient_id);

    await logAudit({
      patientId:   patient._id,
      actorUserId: req.user._id,
      recordId:    record._id,
      actionType:  'download',
      details:     `Downloaded: ${record.title}`,
      ip:          req.ip,
    });

    res.status(200).json({ success: true, download_url: record.file_path });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;
