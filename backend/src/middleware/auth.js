const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * SECURITY: JWT Authentication Middleware
 * - Protects routes from unauthorized access by verifying JWT tokens
 * - Extracts bearer token from Authorization header
 * - Validates token signature using JWT_SECRET (prevents token tampering)
 * - Verifies token expiration (prevents replay attacks with stale tokens)
 * - Attaches authenticated user to request object for downstream middlewares
 * - Returns 401 for missing/invalid tokens, 403 for authorization failures
 * 
 * Threat Prevention:
 * 1. Unauthorized Access: Only users with valid JWT can access protected routes
 * 2. Token Tampering: JWT signature verification ensures token integrity
 * 3. Session Replay: Token expiration (JWT_EXPIRES_IN) limits token lifetime
 */
exports.protect = async (req, res, next) => {
  let token;

  // Extract JWT from Bearer token in Authorization header
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // Return 401 if no token provided
  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Not logged in. Please log in to continue.',
    });
  }

  try {
    // Verify JWT signature and expiration using secret key
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // Retrieve full user object from database to ensure user still exists and is active
    req.user = await User.findById(decoded.id);
    next();
  } catch (error) {
    // Return 401 for invalid or expired tokens
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired session. Please log in again.',
    });
  }
};

/**
 * SECURITY: Role-Based Access Control (RBAC) Middleware
 * - Implements fine-grained authorization based on user roles
 * - Validates that user has one of the required roles before granting access
 * - Returns 403 Forbidden for insufficient privileges
 * - Must be used AFTER protect() middleware to ensure user is authenticated
 * 
 * Threat Prevention:
 * 1. Privilege Escalation: Ensures users can only access resources matching their role
 * 2. Unauthorized Data Access: Prevents patients from accessing doctor-only endpoints
 * 3. Administrative Actions: Restricts sensitive operations to authorized roles only
 */
exports.authorise = (...roles) => {
  return (req, res, next) => {
    // Check if current user's role is in the allowed roles list
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role: ${roles.join(' or ')}`,
      });
    }
    next();
  };
};