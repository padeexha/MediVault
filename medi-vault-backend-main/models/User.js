const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  first_name:    { type: String, required: true, trim: true },
  last_name:     { type: String, required: true, trim: true },
  email:         { type: String, required: true, unique: true, lowercase: true, trim: true },
  password_hash: { type: String, select: false },
  role:          { type: String, enum: ['patient', 'doctor'], required: true },
  phone_number:  { type: String, trim: true },
  google_id:     { type: String, sparse: true },
  auth_provider: { type: String, enum: ['local', 'google'], default: 'local' },

  // Email verification OTP
  otpCode:        String,
  otpExpires:     Date,
  isVerified:     { type: Boolean, default: false },

  // Profile extras
  gender:          { type: String, enum: ['male', 'female', 'other', 'prefer_not_to_say'], default: null },
  profile_picture: { type: String, default: null },

  // Password reset
  resetPasswordToken:   String,
  resetPasswordExpires: Date,
}, { timestamps: true });

userSchema.pre('save', async function () {
  if (!this.isModified('password_hash') || !this.password_hash) return;
  const salt = await bcrypt.genSalt(12);
  this.password_hash = await bcrypt.hash(this.password_hash, salt);
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  if (!this.password_hash) return false;
  return await bcrypt.compare(enteredPassword, this.password_hash);
};

module.exports = mongoose.model('User', userSchema);
