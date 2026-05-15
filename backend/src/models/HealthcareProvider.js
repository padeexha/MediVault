const mongoose = require('mongoose');

// Stores doctor/provider-specific details separately from the shared User account.
// The unique user_id keeps each doctor account mapped to one provider profile.
const healthcareProviderSchema = new mongoose.Schema({
  user_id:           { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  specialization:    { type: String },
  organisation_name: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('HealthcareProvider', healthcareProviderSchema);
