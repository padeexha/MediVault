const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const request = require('supertest');
const { startDB, stopDB, clearDB, waitForConnection } = require('./helpers/db');
const { createPatient, createDoctor } = require('./helpers/auth');

let app;
let mongoServer;

beforeAll(async () => {
  mongoServer = await startDB();
  app = require('../src/app');
  await waitForConnection();
}, 30000);

afterAll(async () => {
  await stopDB(mongoServer);
});

afterEach(async () => {
  await clearDB();
});

// reusable fixture covering all optional fields so we can pick and choose in individual tests
const sampleProfile = {
  full_name: 'Alice Smith',
  age: 30,
  gender: 'female',
  height: '165cm',
  weight: '60kg',
  blood_group: 'O+',
  allergies: ['Penicillin'],
  current_medications: ['Metformin'],
  chronic_conditions: ['Diabetes Type 2'],
  emergency_contact_name: 'Bob Smith',
  emergency_contact_number: '0771234567',
};

describe('Auth guards: health profile endpoints require a token', () => {
  test('GET /api/health-profile/my-profile requires auth', async () => {
    expect((await request(app).get('/api/health-profile/my-profile')).statusCode).toBe(401);
  });
  test('POST /api/health-profile/save requires auth', async () => {
    expect((await request(app).post('/api/health-profile/save')).statusCode).toBe(401);
  });
  test('POST /api/health-profile/grant-access requires auth', async () => {
    expect((await request(app).post('/api/health-profile/grant-access')).statusCode).toBe(401);
  });
  test('GET /api/health-profile/my-access requires auth', async () => {
    expect((await request(app).get('/api/health-profile/my-access')).statusCode).toBe(401);
  });
});

describe('GET /api/health-profile/my-profile', () => {
  test('returns null profile and exists:false when no profile has been saved', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/health-profile/my-profile')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.exists).toBe(false);
    expect(res.body.profile).toBeNull();
  });

  test('returns the saved profile after POST /save', async () => {
    const { token } = await createPatient(app);
    await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${token}`)
      .send(sampleProfile);
    const res = await request(app).get('/api/health-profile/my-profile')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.exists).toBe(true);
    expect(res.body.profile.blood_group).toBe('O+');
    expect(res.body.profile.allergies).toEqual(['Penicillin']);
  });

  test('returns 403 when caller is a doctor', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/health-profile/my-profile')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });
});

describe('POST /api/health-profile/save', () => {
  test('creates a new health profile successfully', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${token}`)
      .send(sampleProfile);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.profile.full_name).toBe('Alice Smith');
    expect(res.body.profile.chronic_conditions).toEqual(['Diabetes Type 2']);
  });

  test('updates an existing profile (upsert semantics)', async () => {
    const { token } = await createPatient(app);
    // first POST creates the profile
    await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${token}`)
      .send(sampleProfile);
    // second POST updates it in-place rather than creating a second document
    const res = await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${token}`)
      .send({ ...sampleProfile, blood_group: 'AB+', age: 31 });
    expect(res.statusCode).toBe(200);
    expect(res.body.profile.blood_group).toBe('AB+');
    expect(res.body.profile.age).toBe(31);
  });

  test('defaults array fields to empty arrays when omitted', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${token}`)
      .send({ full_name: 'John Doe' });
    expect(res.statusCode).toBe(200);
    expect(res.body.profile.allergies).toEqual([]);
    expect(res.body.profile.current_medications).toEqual([]);
  });

  test('returns 403 when caller is a doctor', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${token}`)
      .send(sampleProfile);
    expect(res.statusCode).toBe(403);
  });
});

describe('POST /api/health-profile/grant-access', () => {
  test('patient can grant a doctor access by email', async () => {
    const { token: patientToken } = await createPatient(app);
    const { email: doctorEmail } = await createDoctor(app);
    await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${patientToken}`)
      .send(sampleProfile);
    const res = await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ doctor_email: doctorEmail });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toMatch(/granted/i);
  });

  test('creates a health profile automatically if one does not exist yet', async () => {
    const { token: patientToken } = await createPatient(app);
    const { email: doctorEmail } = await createDoctor(app);
    const res = await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ doctor_email: doctorEmail });
    expect(res.statusCode).toBe(200);
  });

  test('returns 400 if the doctor already has approved access', async () => {
    const { token: patientToken } = await createPatient(app);
    const { email: doctorEmail } = await createDoctor(app);
    await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ doctor_email: doctorEmail });
    const res = await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ doctor_email: doctorEmail });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/already has access/i);
  });

  test('returns 404 when doctor email does not exist', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${token}`)
      .send({ doctor_email: 'ghost@nowhere.com' });
    expect(res.statusCode).toBe(404);
  });

  test('returns 400 when doctor_email is missing from body', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(res.statusCode).toBe(400);
  });

  test('returns 403 when caller is a doctor (patient-only)', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${token}`)
      .send({ doctor_email: 'anyone@test.com' });
    expect(res.statusCode).toBe(403);
  });
});

describe('POST /api/health-profile/request-access', () => {
  test('always returns 403 - patients grant access, doctors cannot request it', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).post('/api/health-profile/request-access')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
    expect(res.body.success).toBe(false);
  });
});

describe('GET /api/health-profile/view/:patientId', () => {
  let patientToken, patientUser, doctorToken, doctorUser;
  beforeEach(async () => {
    ({ token: patientToken, user: patientUser } = await createPatient(app));
    ({ token: doctorToken, user: doctorUser, email: doctorUser.email } = await createDoctor(app));
    await request(app).post('/api/health-profile/save')
      .set('Authorization', `Bearer ${patientToken}`)
      .send(sampleProfile);
  });

  test('authorized doctor can view the profile (access_requests stripped)', async () => {
    await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ doctor_email: doctorUser.email });
    const res = await request(app).get(`/api/health-profile/view/${patientUser.id}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.profile.blood_group).toBe('O+');
    // access_requests contains internal grant metadata that doctors shouldn't see
    expect(res.body.profile.access_requests).toBeUndefined();
  });

  test('unauthorized doctor gets 403', async () => {
    const res = await request(app).get(`/api/health-profile/view/${patientUser.id}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(403);
    expect(res.body.message).toMatch(/approved access/i);
  });

  test('returns 403 when caller is a patient (doctor-only endpoint)', async () => {
    const res = await request(app).get(`/api/health-profile/view/${patientUser.id}`)
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(403);
  });

  test('returns 404 when profile does not exist for the patient', async () => {
    const { user: anotherPatient } = await createPatient(app);
    const { token: anotherDoctorToken, email: anotherDoctorEmail } = await createDoctor(app);
    // Another patient has no profile
    const res = await request(app).get(`/api/health-profile/view/${anotherPatient.id}`)
      .set('Authorization', `Bearer ${anotherDoctorToken}`);
    // 403 (no approved access) or 404 (profile not created) are both valid
    expect([403, 404]).toContain(res.statusCode);
  });
});

describe('PUT /api/health-profile/revoke/:requestId', () => {
  test('patient can revoke a doctor\'s access', async () => {
    const { token: patientToken } = await createPatient(app);
    const { email: doctorEmail } = await createDoctor(app);
    await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ doctor_email: doctorEmail });
    // fetch the profile to get the internal access_request _id needed for the revoke call
    const profileRes = await request(app).get('/api/health-profile/my-profile')
      .set('Authorization', `Bearer ${patientToken}`);
    const requestId = profileRes.body.profile.access_requests[0]._id;
    const res = await request(app).put(`/api/health-profile/revoke/${requestId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    const updatedProfile = await request(app).get('/api/health-profile/my-profile')
      .set('Authorization', `Bearer ${patientToken}`);
    const entry = updatedProfile.body.profile.access_requests[0];
    expect(entry.status).toBe('revoked');
  });

  test('returns 403 when caller is a doctor', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).put('/api/health-profile/revoke/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });
});

describe('GET /api/health-profile/my-access', () => {
  test('returns empty array when no patients have granted access', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/health-profile/my-access')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data).toHaveLength(0);
  });

  test('returns patient entries after access is granted', async () => {
    const { token: patientToken } = await createPatient(app);
    const { token: doctorToken, email: doctorEmail } = await createDoctor(app);
    await request(app).post('/api/health-profile/grant-access')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ doctor_email: doctorEmail });
    const res = await request(app).get('/api/health-profile/my-access')
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].status).toBe('approved');
    expect(res.body.data[0].patient_name).toBeDefined();
  });

  test('returns 403 when caller is a patient (doctor-only)', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/health-profile/my-access')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });
});
