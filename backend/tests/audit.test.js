const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const request = require('supertest');
const { startDB, stopDB, clearDB, waitForConnection } = require('./helpers/db');
const { createPatient, createDoctor } = require('./helpers/auth');

let app;
let mongoServer;

beforeAll(async () => {
  mongoServer = await startDB();
  // same pattern as other suites - app is required after the DB starts
  app = require('../src/app');
  await waitForConnection();
}, 30000);

afterAll(async () => {
  await stopDB(mongoServer);
});

afterEach(async () => {
  await clearDB();
});

describe('GET /api/audit/my-logs', () => {
  test('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/audit/my-logs');
    expect(res.statusCode).toBe(401);
  });

  test('returns 403 when caller is a doctor (patient-only endpoint)', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });

  test('returns at least the login event for a new patient', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    // createPatient logs in the user, so at least one login event exists
    expect(res.body.count).toBeGreaterThanOrEqual(1);
    expect(res.body.logs[0].action_type).toBe('login');
  });

  test('login event is recorded in the audit log', async () => {
    const { email, password } = await createPatient(app);
    // Re-login to trigger a fresh login audit event
    await request(app).post('/api/auth/login').send({ email, password });
    const { token } = await request(app).post('/api/auth/login').send({ email, password })
      .then(r => ({ token: r.body.token }));
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    const loginLogs = res.body.logs.filter(l => l.action_type === 'login');
    expect(loginLogs.length).toBeGreaterThan(0);
  });

  test('record upload event is recorded in the audit log', async () => {
    const { token } = await createPatient(app);
    await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${token}`)
      .attach('file', Buffer.from('%PDF-1.4'), { filename: 'test.pdf', contentType: 'application/pdf' })
      .field('title', 'Blood Test')
      .field('category', 'lab_report');
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    const uploadLogs = res.body.logs.filter(l => l.action_type === 'upload');
    expect(uploadLogs).toHaveLength(1);
    expect(uploadLogs[0].action_status).toBe('success');
  });

  test('record view event is recorded in the audit log', async () => {
    const { token } = await createPatient(app);
    const uploadRes = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${token}`)
      .attach('file', Buffer.from('%PDF'), { filename: 'test.pdf', contentType: 'application/pdf' })
      .field('title', 'MRI Scan')
      .field('category', 'radiology');
    const recordId = uploadRes.body.record._id;
    // fetching the record is what triggers the view audit event
    await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${token}`);
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${token}`);
    const viewLogs = res.body.logs.filter(l => l.action_type === 'view');
    expect(viewLogs.length).toBeGreaterThan(0);
  });

  test('permission_granted event is recorded when access is granted', async () => {
    const { token: patientToken } = await createPatient(app);
    // createDoctor returns the full user object so we can pass the doctor's ID to the grant call
    const { user: doctorUser } = await createDoctor(app);
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${patientToken}`);
    const grantLogs = res.body.logs.filter(l => l.action_type === 'permission_granted');
    expect(grantLogs.length).toBeGreaterThan(0);
  });

  test('soft-delete event is recorded in the audit log', async () => {
    const { token } = await createPatient(app);
    const uploadRes = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${token}`)
      .attach('file', Buffer.from('%PDF'), { filename: 'test.pdf', contentType: 'application/pdf' })
      .field('title', 'Old Report')
      .field('category', 'other');
    const recordId = uploadRes.body.record._id;
    await request(app).delete(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${token}`);
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${token}`);
    const deleteLogs = res.body.logs.filter(l => l.action_type === 'delete');
    expect(deleteLogs).toHaveLength(1);
  });

  test('unauthorized doctor access attempt is audit-logged as a failure', async () => {
    const { token: patientToken } = await createPatient(app);
    const { token: doctorToken } = await createDoctor(app);
    const uploadRes = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${patientToken}`)
      .attach('file', Buffer.from('%PDF'), { filename: 'test.pdf', contentType: 'application/pdf' })
      .field('title', 'Private Record')
      .field('category', 'prescription');
    const recordId = uploadRes.body.record._id;
    // Doctor tries to view without permission
    await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${patientToken}`);
    const failureLogs = res.body.logs.filter(l => l.action_status === 'failure');
    expect(failureLogs.length).toBeGreaterThan(0);
  });

  test('audit logs are returned newest first', async () => {
    const { token } = await createPatient(app);
    // Trigger a couple of events
    const uploadRes = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${token}`)
      .attach('file', Buffer.from('%PDF'), { filename: 'test.pdf', contentType: 'application/pdf' })
      .field('title', 'First')
      .field('category', 'other');
    const recordId = uploadRes.body.record._id;
    await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${token}`);
    const res = await request(app).get('/api/audit/my-logs')
      .set('Authorization', `Bearer ${token}`);
    if (res.body.logs.length >= 2) {
      const dates = res.body.logs.map(l => new Date(l.action_date));
      expect(dates[0] >= dates[1]).toBe(true);
    }
  });
});
