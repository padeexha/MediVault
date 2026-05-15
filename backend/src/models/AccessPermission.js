const mongoose = require('mongoose');

// Defines what one healthcare provider can access for one patient.
// Permissions are scoped instead of duplicating record data in this collection.
const accessPermissionSchema = new mongoose.Schema({
  patient_id:  { type: mongoose.Schema.Types.ObjectId, ref: 'Patient',  required: true },
  provider_id: { type: mongoose.Schema.Types.ObjectId, ref: 'HealthcareProvider', required: true },

  // scope_type controls which of the two nullable fields below is used:
  // 'all'      -> full access, both record_id and shared_category are null
  // 'record'   -> record_id is set, shared_category is null
  // 'category' -> shared_category is set, record_id is null
  scope_type: {
    type: String,
    enum: ['all', 'record', 'category'],
    required: true,
  },

  record_id:       { type: mongoose.Schema.Types.ObjectId, ref: 'MedicalRecord', default: null },
  shared_category: { type: String, default: null },

  access_status: { type: String, enum: ['granted', 'revoked'], default: 'granted' },
  granted_at:    { type: Date, default: Date.now },
  revoked_at:    { type: Date, default: null },
  expires_at:    { type: Date, default: null },
}, { timestamps: true });

// A patient/provider pair has one permission document that is updated
// when the patient changes the access scope or grants access again.
accessPermissionSchema.index({ patient_id: 1, provider_id: 1 }, { unique: true });

module.exports = mongoose.model('AccessPermission', accessPermissionSchema);
