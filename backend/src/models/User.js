const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

/**
 * SECURITY: User Schema with Email Verification & Password Reset Security
 * - Email field is unique to prevent duplicate registrations and credential confusion
 * - Password stored as hash only (never plaintext) using bcrypt with salt
 * - Role-based access control: restricted to 'patient' or 'doctor' enum
 * - Email verification required before account activation
 * - Separate reset tokens prevent password recovery attacks
 * - Timestamps track account creation/modification for audit purposes
 */
const userSchema = new mongoose.Schema({
  first_name:    { type: String, required: true, trim: true },
  last_name:     { type: String, required: true, trim: true },
  email:         { type: String, required: true, unique: true, lowercase: true, trim: true }, // Unique index prevents duplicate accounts
  password_hash: { type: String, select: false }, // Excluded from queries by default to prevent accidental exposure
  role:          { type: String, enum: ['patient', 'doctor'], required: true }, // Enum restricts role injection attacks
  phone_number:  { type: String, trim: true },
  google_id:     { type: String, sparse: true },
  auth_provider: { type: String, enum: ['local', 'google'], default: 'local' },

  // Email verification fields - prevents unverified account access
  isVerified:          { type: Boolean, default: false }, // Account inactive until verified
  verificationToken:   String, // Hash of token sent via email
  verificationExpires: Date, // Token expires after 24 hours

  // Profile extras
  gender:          { type: String, enum: ['male', 'female', 'other', 'prefer_not_to_say'], default: null },
  profile_picture: { type: String, default: null },

  // Password reset security - separate from password to prevent attacks
  resetPasswordToken:   String, // Hash of reset token sent via email
  resetPasswordExpires: Date, // Token expires after 10 minutes
}, { timestamps: true });

/**
 * SECURITY: Pre-save Middleware - Password Hashing
 * - Hash password before storing in database using bcrypt
 * - Bcrypt includes random salt generation (salt rounds = 12)
 * - 12 salt rounds = ~2^12 computational cost (balances security vs performance)
 * - Never stores plaintext password (security vs usability tradeoff)
 * - Automatically hashes on password modification only
 * 
 * Threat Prevention:
 * 1. Database Breach: Attacker cannot reverse bcrypt hashes to recover passwords
 * 2. Rainbow Tables: Salt makes pre-computed hash tables ineffective
 * 3. Password Reuse: Bcrypt's slow hashing prevents efficient offline cracking
 */
userSchema.pre('save', async function () {
  // Skip hashing if password not modified (optimization for other schema updates)
  if (!this.isModified('password_hash') || !this.password_hash) return;
  // Generate salt with 12 rounds (NIST recommendation: 10-12 for balanced security/speed)
  const salt = await bcrypt.genSalt(12);
  // Hash password with salt - creates unique hash even for identical passwords
  this.password_hash = await bcrypt.hash(this.password_hash, salt);
});

/**
 * SECURITY: Password Verification Method
 * - Compares plaintext input against stored bcrypt hash
 * - Bcrypt's timing-safe comparison prevents timing attacks
 * - Returns false if password_hash is missing (handles OAuth accounts)
 * - Used during login to verify credentials
 * 
 * Threat Prevention:
 * 1. Timing Attacks: Bcrypt.compare takes constant time regardless of match/mismatch
 * 2. Brute-Force Detection: Expensive bcrypt computation slows attack attempts
 */
userSchema.methods.matchPassword = async function (enteredPassword) {
  // Guard against OAuth accounts without password_hash
  if (!this.password_hash) return false;
  // Constant-time comparison prevents timing-based password disclosure
  return await bcrypt.compare(enteredPassword, this.password_hash);
};

module.exports = mongoose.model('User', userSchema);
