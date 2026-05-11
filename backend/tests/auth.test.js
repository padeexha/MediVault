const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
require('dotenv').config();

beforeAll(async () => {
  await mongoose.connect(process.env.MONGO_URI);
});

// This runs once after all tests - closes the database connection
afterAll(async () => {
  await mongoose.connection.close();
});


// AUTH TESTS

describe('Authentication Routes', () => {

  // Test 1 - Registering with a weak password should be rejected
  test('Register patient fails with weak password', async () => {
    const res = await request(app)
      .post('/api/auth/register/patient')
      .send({
        first_name: 'Test',
        last_name: 'User',
        email: 'weakpasstest@test.com',
        password: 'weakpass', // no uppercase, no number, no special char
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  // Test 2 - Registering without required fields should fail
  test('Register patient fails with missing name fields', async () => {
    const res = await request(app)
      .post('/api/auth/register/patient')
      .send({
        email: 'missing@test.com',
        password: 'Password123!',
        // first_name and last_name are missing
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  // Test 3 - Registering a doctor without specialization should fail
  test('Register doctor fails without specialization', async () => {
    const res = await request(app)
      .post('/api/auth/register/doctor')
      .send({
        first_name: 'Test',
        last_name: 'Doctor',
        email: 'testdoc@test.com',
        password: 'Password123!',
        // specialization and organisation_name are missing
      });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  // Test 4 - Logging in with wrong credentials should fail
  test('Login fails with wrong credentials', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'nonexistent@test.com',
        password: 'Password123!',
      });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // Test 5 - Logging in without providing email or password should fail
  test('Login fails with missing credentials', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  // Test 6 - Forgot password with unknown email should return 404
  test('Forgot password fails with unknown email', async () => {
    const res = await request(app)
      .post('/api/auth/forgot-password')
      .send({ email: 'nobody@nowhere.com' });
    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
  });

});


// RECORDS TESTS


describe('Records Routes - Authentication Required', () => {

  // Test 7 - Getting records without a token should be blocked
  test('Get records fails without auth token', async () => {
    const res = await request(app).get('/api/records');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // Test 8 - Viewing a single record without a token should be blocked
  test('View single record fails without auth token', async () => {
    const res = await request(app).get('/api/records/507f1f77bcf86cd799439011');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // Test 9 - Uploading without a token should be blocked
  test('Upload record fails without auth token', async () => {
    const res = await request(app).post('/api/records/upload');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // Test 10 - Deleting a record without a token should be blocked
  test('Delete record fails without auth token', async () => {
    const res = await request(app).delete('/api/records/507f1f77bcf86cd799439011');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

});


// PERMISSIONS TESTS


describe('Permissions Routes - Authentication Required', () => {

  // Test 11 - Listing doctors without a token should be blocked
  test('My doctors fails without auth token', async () => {
    const res = await request(app).get('/api/permissions/my-doctors');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // Test 12 - Shared records without a token should be blocked
  test('Shared with me fails without auth token', async () => {
    const res = await request(app).get('/api/permissions/shared-with-me');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // Test 13 - Granting access without a token should be blocked
  test('Grant permission fails without auth token', async () => {
    const res = await request(app).post('/api/permissions/grant');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

});


// AUDIT TESTS


describe('Audit Routes - Authentication Required', () => {

  // Test 14 - Viewing audit logs without a token should be blocked
  test('Audit logs fail without auth token', async () => {
    const res = await request(app).get('/api/audit/my-logs');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

});


// SEARCH TESTS


describe('Search Routes - Authentication Required', () => {

  // Test 15 - Searching without a token should be blocked
  test('Search fails without auth token', async () => {
    const res = await request(app).get('/api/search');
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

});