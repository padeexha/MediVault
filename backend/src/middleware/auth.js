const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Verifies the Bearer token from the Authorization header and attaches the
// full user document to req.user so downstream handlers don't have to re-query.
exports.protect = async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not logged in. Please log in to continue.',
    });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // Load from DB so changes like account deletion take effect immediately
    req.user = await User.findById(decoded.id);
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired session. Please log in again.',
    });
  }
};

// Factory that returns a middleware checking req.user.role against the allowed list.
// Must be used after protect() since it relies on req.user being set.
exports.authorise = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role: ${roles.join(' or ')}`,
      });
    }
    next();
  };
};
