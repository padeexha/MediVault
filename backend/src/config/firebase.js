const admin = require('firebase-admin');

const hasUsableFirebaseConfig = () => {
  const privateKey = process.env.FIREBASE_PRIVATE_KEY || '';
  return Boolean(
    process.env.FIREBASE_PROJECT_ID &&
    process.env.FIREBASE_CLIENT_EMAIL &&
    process.env.FIREBASE_STORAGE_BUCKET &&
    privateKey.includes('BEGIN PRIVATE KEY') &&
    privateKey.includes('END PRIVATE KEY') &&
    !privateKey.includes('your_key_here')
  );
};

if (!hasUsableFirebaseConfig()) {
  // Fall back to local disk storage when Firebase is not set up
  console.warn('Firebase credentials are not configured. File uploads will use local storage.');
  module.exports = null;
} else {
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      // The private key comes in as a single-line string with literal \n sequences
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    }),
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  });

  const bucket = admin.storage().bucket();
  module.exports = bucket;
}
