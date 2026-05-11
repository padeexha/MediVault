const mongoose = require('mongoose');

const healthcareProviderSchema = new mongoose.Schema({
  user_id:           { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  specialization:    { type: String },
  organisation_name: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('HealthcareProvider', healthcareProviderSchema);