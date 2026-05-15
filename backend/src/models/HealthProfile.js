const mongoose = require('mongoose');

// Embedded subdocument used to store doctor access decisions inside a patient's profile.
// Keeping these with the profile makes profile-access checks a single document lookup.
const accessRequestSchema = new mongoose.Schema({
  doctor_id:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  doctor_name:  { type: String, default: '' },
  doctor_email: { type: String, default: '' },
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'revoked'],
    default: 'pending',
  },
  requested_at: { type: Date, default: Date.now },
  responded_at: { type: Date },
}, { _id: true });

// Stores structured health information for a patient account.
// patient_id references User here because this profile is managed directly by the patient login.
const healthProfileSchema = new mongoose.Schema({
  patient_id:               { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  full_name:                { type: String, default: '' },
  age:                      { type: Number, default: null },
  gender:                   { type: String, default: '' },
  height:                   { type: String, default: '' },
  weight:                   { type: String, default: '' },
  blood_group:              { type: String, default: '' },
  allergies:                { type: [String], default: [] },
  current_medications:      { type: [String], default: [] },
  chronic_conditions:       { type: [String], default: [] },
  emergency_contact_name:   { type: String, default: '' },
  emergency_contact_number: { type: String, default: '' },
  access_requests:          { type: [accessRequestSchema], default: [] },
}, { timestamps: true });

module.exports = mongoose.model('HealthProfile', healthProfileSchema);
