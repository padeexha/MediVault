const mongoose = require('mongoose');

const medicalRecordSchema = new mongoose.Schema({
  patient_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Patient',
    required: true,
  },
  uploaded_by_user_id: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
  },
  notes:     { type: String },
  category:  {
    type: String,
    enum: ['prescription', 'lab_report', 'radiology', 'discharge_summary', 'other'],
    required: true,
  },
  file_name: { type: String },
  file_type: { type: String },
  file_size: { type: Number },
  file_path: { type: String, required: true },
  upload_date: { type: Date, default: Date.now },
  is_deleted:  { type: Boolean, default: false },
  deleted_at:  { type: Date, default: null },
}, { timestamps: true });

module.exports = mongoose.model('MedicalRecord', medicalRecordSchema);