const multer = require('multer');

/**
 * SECURITY: File Upload Configuration
 * - Restricts file uploads to sanitized, in-memory storage
 * - Validates MIME types to prevent execution of malicious files
 * - Enforces file size limits (20MB max) to prevent DoS attacks
 * - Uses memory storage instead of disk to avoid filesystem attacks
 * 
 * Threat Prevention:
 * 1. Malicious File Execution: MIME type whitelist blocks executable files (.exe, .js, etc.)
 * 2. Denial of Service (DoS): 20MB file size limit prevents storage exhaustion
 * 3. Malware Distribution: Only safe document/image types allowed (PDF, JPEG, PNG)
 * 4. Filesystem Attacks: In-memory storage prevents directory traversal and symlink exploits
 */

const storage = multer.memoryStorage(); // Store files in RAM instead of disk for enhanced security

/**
 * SECURITY: MIME Type Validation
 * - Whitelist approach: only explicitly allowed file types are accepted
 * - Rejects any file not matching the allowed MIME types
 * - MIME type checking provides first-line defense against executable uploads
 */
const fileFilter = (req, file, cb) => {
  // Whitelist of safe MIME types for healthcare documents and images
  const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    // Reject file with descriptive error message
    cb(new Error('Unsupported file type. Only PDF, JPEG, and PNG are allowed.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 20 * 1024 * 1024 }, // Maximum 20MB per file to prevent storage exhaustion
});

module.exports = upload;