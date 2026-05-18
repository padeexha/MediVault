const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  first_name:    { type: String, required: true, trim: true },
  last_name:     { type: String, required: true, trim: true },
  email:         { type: String, required: true, unique: true, lowercase: true, trim: true },
  // Excluded from query results by default so it doesn't leak into API responses accidentally
  password_hash: { type: String, select: false },
  role:          { type: String, enum: ['patient', 'doctor'], required: true },
  phone_number:  { type: String, trim: true },
  // sparse so the index doesn't reject multiple null values
  google_id:     { type: String, sparse: true },
  auth_provider: { type: String, enum: ['local', 'google'], default: 'local' },

  isVerified:          { type: Boolean, default: false },
  // Token is stored as a SHA-256 hash so the plaintext is only ever in the email
  verificationToken:   String,
  verificationExpires: Date,

  gender:          { type: String, enum: ['male', 'female', 'other', 'prefer_not_to_say'], default: null },
  profile_picture: { type: String, default: null },

  resetPasswordToken:   String,
  resetPasswordExpires: Date,
}, { timestamps: true });

// Hash password_hash on create and on any update that touches that field
userSchema.pre('save', async function () {
  if (!this.isModified('password_hash') || !this.password_hash) return;
  const salt = await bcrypt.genSalt(12);
  this.password_hash = await bcrypt.hash(this.password_hash, salt);
});

// Used during login to compare the submitted password against the stored hash.
// Returns false for OAuth accounts that have no password_hash.
userSchema.methods.matchPassword = async function (enteredPassword) {
  if (!this.password_hash) return false;
  return await bcrypt.compare(enteredPassword, this.password_hash);
};

module.exports = mongoose.model('User', userSchema);
