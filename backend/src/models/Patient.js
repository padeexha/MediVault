const mongoose = require('mongoose');

// Stores patient-only profile data and links it one-to-one with a User document.
// The unique user_id prevents a single login account from owning multiple patient profiles.
const patientSchema = new mongoose.Schema({
  user_id:       { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  date_of_birth: { type: Date },
  gender:        { type: String, enum: ['male', 'female', 'other', 'prefer not to say'] },
  address:       { type: String },
}, { timestamps: true });

module.exports = mongoose.model('Patient', patientSchema);
