const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  first_name:    { type: String, required: true, trim: true },
  last_name:     { type: String, required: true, trim: true },
  email:         { type: String, required: true, unique: true, lowercase: true, trim: true },
  password_hash: { type: String, required: true, minlength: 8, select: false },
  role:          { type: String, enum: ['patient', 'doctor'], required: true },
  phone_number:  { type: String, trim: true },
  resetPasswordToken:        String,
  resetPasswordExpires:      Date,
  isVerified:                { type: Boolean, default: false },
  emailVerificationToken:    String,
  emailVerificationExpires:  Date,
}, { timestamps: true });

userSchema.pre('save', async function () {
  if (!this.isModified('password_hash')) return;
  const salt = await bcrypt.genSalt(12);
  this.password_hash = await bcrypt.hash(this.password_hash, salt);
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password_hash);
};

module.exports = mongoose.model('User', userSchema);