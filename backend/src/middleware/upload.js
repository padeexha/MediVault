const multer = require('multer');

// Keep files in memory so they can be streamed straight to Firebase or written
// to disk without creating temp files that need cleanup.
const storage = multer.memoryStorage();

// Whitelist only the three types we actually support. Anything else is rejected
// with an error message that the global error handler will forward to the client.
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Unsupported file type. Only PDF, JPEG, and PNG are allowed.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 20 * 1024 * 1024 }, // 20 MB cap
});

module.exports = upload;
