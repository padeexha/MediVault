const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');

async function startDB() {
  const mongoServer = await MongoMemoryServer.create();
  process.env.MONGO_URI = mongoServer.getUri();
  process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-key-for-unit-tests-only-32chars';
  process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1d';
  process.env.NODE_ENV = 'test';
  return mongoServer;
}

async function stopDB(mongoServer) {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
  if (mongoServer) await mongoServer.stop();
}

async function clearDB() {
  for (const col of Object.values(mongoose.connection.collections)) {
    await col.deleteMany({});
  }
}

async function waitForConnection() {
  return new Promise((resolve, reject) => {
    if (mongoose.connection.readyState === 1) return resolve();
    mongoose.connection.once('open', resolve);
    mongoose.connection.once('error', reject);
    setTimeout(() => reject(new Error('MongoDB connection timeout')), 15000);
  });
}

module.exports = { startDB, stopDB, clearDB, waitForConnection };
