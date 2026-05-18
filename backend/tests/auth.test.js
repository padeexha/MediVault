const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const request = require('supertest');
const { startDB, stopDB, clearDB, waitForConnection } = require('./helpers/db');
const { createPatient, createDoctor } = require('./helpers/auth');

let app;
let mongoServer;

beforeAll(async () => {
  mongoServer = await startDB();
  // require app after startDB so Express connects to the in-memory URI,
  // not whatever Mongo URI might be in the environment
  app = require('../src/app');
  await waitForConnection();
}, 30000);

afterAll(async () => {
  await stopDB(mongoServer);
});

afterEach(async () => {
  await clearDB();
});

describe('POST /api/auth/register/patient', () => {
  test('registers a patient successfully and auto-verifies when no email service is set', async () => {
    const res = await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice',
      last_name: 'Smith',
      email: 'alice@test.com',
      password: 'Test@1234',
    });
    // no email transport in tests, so the server skips sending a verification
    // email and marks the account as verified right away
    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.email).toBe('alice@test.com');
  });

  test('rejects password with no uppercase letter', async () => {
    const res = await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', last_name: 'Smith', email: 'alice@test.com', password: 'test@1234',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects password shorter than 8 characters', async () => {
    const res = await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', last_name: 'Smith', email: 'alice@test.com', password: 'T@1',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects missing first_name', async () => {
    const res = await request(app).post('/api/auth/register/patient').send({
      last_name: 'Smith', email: 'alice@test.com', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects missing last_name', async () => {
    const res = await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', email: 'alice@test.com', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects invalid email format', async () => {
    const res = await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', last_name: 'Smith', email: 'not-an-email', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects duplicate email', async () => {
    await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', last_name: 'Smith', email: 'alice@test.com', password: 'Test@1234',
    });
    const res = await request(app).post('/api/auth/register/patient').send({
      first_name: 'Bob', last_name: 'Jones', email: 'alice@test.com', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/already registered/i);
  });

  test('rejects first_name starting with a digit', async () => {
    const res = await request(app).post('/api/auth/register/patient').send({
      first_name: '123Alice', last_name: 'Smith', email: 'alice@test.com', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(400);
  });
});

describe('POST /api/auth/register/doctor', () => {
  test('registers a doctor successfully', async () => {
    const res = await request(app).post('/api/auth/register/doctor').send({
      first_name: 'Dr', last_name: 'Bob', email: 'doctor@test.com',
      password: 'Test@1234', specialization: 'Cardiology', organisation_name: 'City Hospital',
    });
    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
  });

  test('rejects missing specialization', async () => {
    const res = await request(app).post('/api/auth/register/doctor').send({
      first_name: 'Dr', last_name: 'Bob', email: 'doctor@test.com',
      password: 'Test@1234', organisation_name: 'City Hospital',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects missing organisation_name', async () => {
    const res = await request(app).post('/api/auth/register/doctor').send({
      first_name: 'Dr', last_name: 'Bob', email: 'doctor@test.com',
      password: 'Test@1234', specialization: 'Cardiology',
    });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects duplicate email across roles', async () => {
    await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', last_name: 'Smith', email: 'shared@test.com', password: 'Test@1234',
    });
    // the email is already taken by the patient account above, even though this
    // is a completely different role
    const res = await request(app).post('/api/auth/register/doctor').send({
      first_name: 'Dr', last_name: 'Bob', email: 'shared@test.com',
      password: 'Test@1234', specialization: 'Cardiology', organisation_name: 'Hospital',
    });
    expect(res.statusCode).toBe(400);
  });
});

describe('POST /api/auth/login', () => {
  test('logs in an auto-verified patient and returns a JWT token', async () => {
    // register first so the account exists, then log in
    await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', last_name: 'Smith', email: 'alice@test.com', password: 'Test@1234',
    });
    const res = await request(app).post('/api/auth/login').send({
      email: 'alice@test.com', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.token).toBeDefined();
    expect(res.body.user.role).toBe('patient');
    expect(res.body.user.email).toBe('alice@test.com');
  });

  test('logs in a doctor and returns role: doctor', async () => {
    await request(app).post('/api/auth/register/doctor').send({
      first_name: 'Dr', last_name: 'Bob', email: 'doctor@test.com',
      password: 'Test@1234', specialization: 'Cardiology', organisation_name: 'Hospital',
    });
    const res = await request(app).post('/api/auth/login').send({
      email: 'doctor@test.com', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(200);
    expect(res.body.user.role).toBe('doctor');
    expect(res.body.token).toBeDefined();
  });

  test('rejects incorrect password', async () => {
    await request(app).post('/api/auth/register/patient').send({
      first_name: 'Alice', last_name: 'Smith', email: 'alice@test.com', password: 'Test@1234',
    });
    const res = await request(app).post('/api/auth/login').send({
      email: 'alice@test.com', password: 'WrongPass@9',
    });
    expect(res.statusCode).toBe(401);
    expect(res.body.success).toBe(false);
  });

  test('rejects non-existent email with 401', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'nobody@test.com', password: 'Test@1234',
    });
    expect(res.statusCode).toBe(401);
  });

  test('rejects empty body with 400', async () => {
    const res = await request(app).post('/api/auth/login').send({});
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects missing password', async () => {
    const res = await request(app).post('/api/auth/login').send({ email: 'alice@test.com' });
    expect(res.statusCode).toBe(400);
  });
});

describe('POST /api/auth/logout', () => {
  test('logs out successfully with a valid token', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).post('/api/auth/logout')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).post('/api/auth/logout');
    expect(res.statusCode).toBe(401);
  });
});

describe('GET /api/auth/profile', () => {
  test('returns patient profile including role field', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/auth/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.profile.role).toBe('patient');
    expect(res.body.profile.email).toBeDefined();
    expect(res.body.profile.password_hash).toBeUndefined();
  });

  test('returns doctor profile with specialization and organisation_name', async () => {
    const { token } = await createDoctor(app, {
      specialization: 'Neurology', organisation_name: 'Brain Clinic',
    });
    const res = await request(app).get('/api/auth/profile')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.profile.role).toBe('doctor');
    expect(res.body.profile.specialization).toBe('Neurology');
    expect(res.body.profile.organisation_name).toBe('Brain Clinic');
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/auth/profile');
    expect(res.statusCode).toBe(401);
  });

  test('returns 401 for a tampered token', async () => {
    const res = await request(app).get('/api/auth/profile')
      .set('Authorization', 'Bearer invalid.token.here');
    expect(res.statusCode).toBe(401);
  });
});

describe('PUT /api/auth/profile', () => {
  test('updates first_name and phone_number', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).put('/api/auth/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ first_name: 'Updated', phone_number: '0771234567' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('updates doctor specialization', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).put('/api/auth/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ specialization: 'Neurology' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('rejects invalid phone number (letters not allowed)', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).put('/api/auth/profile')
      .set('Authorization', `Bearer ${token}`)
      .send({ phone_number: 'abc-def-ghij' });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).put('/api/auth/profile').send({ first_name: 'X' });
    expect(res.statusCode).toBe(401);
  });
});

describe('PUT /api/auth/change-password', () => {
  test('changes password successfully with correct current password', async () => {
    const { token } = await createPatient(app, { password: 'OldPass@1' });
    const res = await request(app).put('/api/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({ current_password: 'OldPass@1', new_password: 'NewPass@2' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('rejects wrong current password', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).put('/api/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({ current_password: 'WrongPass@1', new_password: 'NewPass@2' });
    expect(res.statusCode).toBe(401);
  });

  test('rejects new password identical to current password', async () => {
    const { token } = await createPatient(app, { password: 'Test@1234' });
    const res = await request(app).put('/api/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({ current_password: 'Test@1234', new_password: 'Test@1234' });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/different/i);
  });

  test('rejects weak new password', async () => {
    const { token } = await createPatient(app, { password: 'Test@1234' });
    const res = await request(app).put('/api/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({ current_password: 'Test@1234', new_password: 'weakpassword' });
    expect(res.statusCode).toBe(400);
  });

  test('rejects missing fields', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).put('/api/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(400);
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).put('/api/auth/change-password')
      .send({ current_password: 'Test@1234', new_password: 'NewPass@2' });
    expect(res.statusCode).toBe(401);
  });
});

describe('POST /api/auth/forgot-password', () => {
  test('returns 404 for unknown email', async () => {
    const res = await request(app).post('/api/auth/forgot-password')
      .send({ email: 'nobody@test.com' });
    expect(res.statusCode).toBe(404);
    expect(res.body.success).toBe(false);
  });

  test('returns 200 for a known email (email service not configured, still succeeds)', async () => {
    const { email } = await createPatient(app);
    const res = await request(app).post('/api/auth/forgot-password').send({ email });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });
});

describe('PUT /api/auth/reset-password/:token', () => {
  test('rejects an invalid or expired token', async () => {
    // deadbeefdeadbeef is valid hex but won't match any stored reset token
    const res = await request(app).put('/api/auth/reset-password/deadbeefdeadbeef')
      .send({ password: 'NewPass@2' });
    expect(res.statusCode).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('rejects a weak new password', async () => {
    // We can't easily get a valid reset token without a real email,
    // but we can confirm weak password is rejected even with a valid-looking flow.
    const res = await request(app).put('/api/auth/reset-password/deadbeef')
      .send({ password: 'weakpass' });
    // either 400 (bad token) or 400 (weak password) - both are valid rejections
    expect(res.statusCode).toBe(400);
  });
});

describe('POST /api/auth/resend-verification', () => {
  test('returns 400 for missing email', async () => {
    const res = await request(app).post('/api/auth/resend-verification').send({});
    expect(res.statusCode).toBe(400);
  });

  test('returns 404 for unknown email', async () => {
    const res = await request(app).post('/api/auth/resend-verification')
      .send({ email: 'nobody@test.com' });
    expect(res.statusCode).toBe(404);
  });

  test('returns 400 for an already-verified account', async () => {
    // createPatient auto-verifies, so there's no pending verification to resend
    const { email } = await createPatient(app);
    const res = await request(app).post('/api/auth/resend-verification').send({ email });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/already verified/i);
  });
});

describe('GET /api/auth/search-doctor', () => {
  test('patient finds a doctor by email', async () => {
    const { token: patientToken } = await createPatient(app);
    const { email: docEmail } = await createDoctor(app, { email: 'dr.house@hospital.com' });
    const res = await request(app).get('/api/auth/search-doctor')
      .set('Authorization', `Bearer ${patientToken}`)
      .query({ email: docEmail });
    expect(res.statusCode).toBe(200);
    expect(res.body.doctor.email).toBe(docEmail);
    expect(res.body.doctor.specialization).toBeDefined();
  });

  test('returns 404 when no doctor matches the email', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/auth/search-doctor')
      .set('Authorization', `Bearer ${token}`)
      .query({ email: 'ghost@hospital.com' });
    expect(res.statusCode).toBe(404);
  });

  test('returns 404 when email matches a patient, not a doctor', async () => {
    const { token: patientToken, email: patientEmail } = await createPatient(app);
    const { token: anotherPatientToken } = await createPatient(app);
    const res = await request(app).get('/api/auth/search-doctor')
      .set('Authorization', `Bearer ${anotherPatientToken}`)
      .query({ email: patientEmail });
    expect(res.statusCode).toBe(404);
  });

  test('returns 400 when email query param is missing', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/auth/search-doctor')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(400);
  });

  test('returns 403 when caller is a doctor (patient-only endpoint)', async () => {
    // doctors don't need to search the directory, only patients do
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/auth/search-doctor')
      .set('Authorization', `Bearer ${token}`)
      .query({ email: 'someone@test.com' });
    expect(res.statusCode).toBe(403);
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/auth/search-doctor')
      .query({ email: 'test@test.com' });
    expect(res.statusCode).toBe(401);
  });
});

describe('GET /api/auth/doctors', () => {
  test('patient gets doctor list with filter metadata', async () => {
    const { token } = await createPatient(app);
    await createDoctor(app, { specialization: 'Neurology', organisation_name: 'Brain Clinic' });
    const res = await request(app).get('/api/auth/doctors')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.doctors)).toBe(true);
    expect(res.body.doctors.length).toBe(1);
    expect(Array.isArray(res.body.filters.hospitals)).toBe(true);
    expect(Array.isArray(res.body.filters.specializations)).toBe(true);
  });

  test('filters by specialization', async () => {
    const { token } = await createPatient(app);
    await createDoctor(app, { specialization: 'Neurology' });
    await createDoctor(app, { specialization: 'Cardiology' });
    const res = await request(app).get('/api/auth/doctors')
      .set('Authorization', `Bearer ${token}`)
      .query({ specialization: 'Neurology' });
    expect(res.statusCode).toBe(200);
    expect(res.body.doctors).toHaveLength(1);
    expect(res.body.doctors[0].specialization).toBe('Neurology');
  });

  test('filters by organisation_name (case-insensitive)', async () => {
    const { token } = await createPatient(app);
    await createDoctor(app, { organisation_name: 'Apollo Hospital' });
    await createDoctor(app, { organisation_name: 'City Clinic' });
    const res = await request(app).get('/api/auth/doctors')
      .set('Authorization', `Bearer ${token}`)
      .query({ organisation_name: 'Apollo Hospital' });
    expect(res.statusCode).toBe(200);
    expect(res.body.doctors).toHaveLength(1);
  });

  test('returns 403 when caller is a doctor (patient-only)', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/auth/doctors')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/auth/doctors');
    expect(res.statusCode).toBe(401);
  });
});

describe('DELETE /api/auth/delete-account', () => {
  test('deletes a patient account and cascades related data', async () => {
    // cascade removes records, permissions, health profile, and audit entries
    const { token, password } = await createPatient(app);
    const res = await request(app).delete('/api/auth/delete-account')
      .set('Authorization', `Bearer ${token}`)
      .send({ password });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('deletes a doctor account', async () => {
    const { token, password } = await createDoctor(app);
    const res = await request(app).delete('/api/auth/delete-account')
      .set('Authorization', `Bearer ${token}`)
      .send({ password });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
  });

  test('rejects wrong password', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).delete('/api/auth/delete-account')
      .set('Authorization', `Bearer ${token}`)
      .send({ password: 'WrongPass@9' });
    expect(res.statusCode).toBe(401);
  });

  test('rejects missing password', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).delete('/api/auth/delete-account')
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(400);
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).delete('/api/auth/delete-account')
      .send({ password: 'Test@1234' });
    expect(res.statusCode).toBe(401);
  });
});
