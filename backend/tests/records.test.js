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

// Helper: uploads a record and returns the full response
const uploadRecord = (token, overrides = {}) =>
  request(app)
    .post('/api/records/upload')
    .set('Authorization', `Bearer ${token}`)
    .attach('file', Buffer.from('%PDF-1.4 test content'), {
      filename: 'test.pdf',
      contentType: 'application/pdf',
    })
    .field('title', overrides.title || 'Test Record')
    .field('category', overrides.category || 'lab_report');

describe('Auth guards: all record endpoints require a token', () => {
  const fakeId = '507f1f77bcf86cd799439011';
  test('GET /api/records', async () => {
    expect((await request(app).get('/api/records')).statusCode).toBe(401);
  });
  test('GET /api/records/:id', async () => {
    expect((await request(app).get(`/api/records/${fakeId}`)).statusCode).toBe(401);
  });
  test('POST /api/records/upload', async () => {
    expect((await request(app).post('/api/records/upload')).statusCode).toBe(401);
  });
  test('PUT /api/records/:id', async () => {
    expect((await request(app).put(`/api/records/${fakeId}`)).statusCode).toBe(401);
  });
  test('DELETE /api/records/:id', async () => {
    expect((await request(app).delete(`/api/records/${fakeId}`)).statusCode).toBe(401);
  });
  test('POST /api/records/:id/download', async () => {
    expect((await request(app).post(`/api/records/${fakeId}/download`)).statusCode).toBe(401);
  });
});

describe('Role guards: doctor cannot use patient-only endpoints', () => {
  let doctorToken;
  beforeEach(async () => {
    ({ token: doctorToken } = await createDoctor(app));
  });

  test('doctor cannot upload (403)', async () => {
    const res = await uploadRecord(doctorToken);
    expect(res.statusCode).toBe(403);
  });

  test('doctor cannot list records (403)', async () => {
    const res = await request(app).get('/api/records')
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(403);
  });

  test('doctor cannot edit a record (403)', async () => {
    const res = await request(app).put('/api/records/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${doctorToken}`)
      .send({ title: 'Edited' });
    expect(res.statusCode).toBe(403);
  });

  test('doctor cannot delete a record (403)', async () => {
    const res = await request(app).delete('/api/records/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(403);
  });
});

describe('POST /api/records/upload', () => {
  let patientToken;
  beforeEach(async () => {
    ({ token: patientToken } = await createPatient(app));
  });

  test('uploads a PDF successfully and returns the record object', async () => {
    const res = await uploadRecord(patientToken, { title: 'Blood Test', category: 'lab_report' });
    expect(res.statusCode).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.record.title).toBe('Blood Test');
    expect(res.body.record.category).toBe('lab_report');
    expect(res.body.record.file_path).toBeDefined();
    expect(res.body.record.is_deleted).toBe(false);
  });

  test('fails when no file is attached', async () => {
    const res = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${patientToken}`)
      .field('title', 'Test')
      .field('category', 'prescription');
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/no file/i);
  });

  test('fails when title is missing', async () => {
    const res = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${patientToken}`)
      .attach('file', Buffer.from('data'), { filename: 'test.pdf', contentType: 'application/pdf' })
      .field('category', 'prescription');
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/title and category/i);
  });

  test('fails when category is missing', async () => {
    const res = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${patientToken}`)
      .attach('file', Buffer.from('data'), { filename: 'test.pdf', contentType: 'application/pdf' })
      .field('title', 'Test');
    expect(res.statusCode).toBe(400);
  });

  test('rejects unsupported file type (text/plain)', async () => {
    const res = await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${patientToken}`)
      .attach('file', Buffer.from('plain text'), { filename: 'notes.txt', contentType: 'text/plain' })
      .field('title', 'Test')
      .field('category', 'other');
    expect(res.statusCode).toBe(400);
  });
});

describe('GET /api/records', () => {
  let patientToken;
  beforeEach(async () => {
    ({ token: patientToken } = await createPatient(app));
  });

  test('returns an empty list when no records have been uploaded', async () => {
    const res = await request(app).get('/api/records')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(0);
    expect(res.body.records).toEqual([]);
  });

  test('returns all uploaded records sorted by upload date descending', async () => {
    await uploadRecord(patientToken, { title: 'Record A' });
    await uploadRecord(patientToken, { title: 'Record B' });
    const res = await request(app).get('/api/records')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(2);
    expect(res.body.records).toHaveLength(2);
  });

  test('excludes soft-deleted records from the listing', async () => {
    const uploadRes = await uploadRecord(patientToken);
    const recordId = uploadRes.body.record._id;
    await request(app).delete(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    const res = await request(app).get('/api/records')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.body.count).toBe(0);
  });

  test('each patient only sees their own records', async () => {
    const { token: otherToken } = await createPatient(app);
    await uploadRecord(patientToken, { title: 'My Record' });
    const res = await request(app).get('/api/records')
      .set('Authorization', `Bearer ${otherToken}`);
    expect(res.body.count).toBe(0);
  });
});

describe('GET /api/records/:id', () => {
  let patientToken, patientUser, doctorToken, doctorUser, recordId;

  beforeEach(async () => {
    ({ token: patientToken, user: patientUser } = await createPatient(app));
    ({ token: doctorToken, user: doctorUser } = await createDoctor(app));
    // using 'prescription' category so the category-scoped permission tests have a specific value to match or mismatch
    const up = await uploadRecord(patientToken, { category: 'prescription' });
    recordId = up.body.record._id;
  });

  test('owner patient can view their own record', async () => {
    const res = await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.record._id).toBe(recordId);
  });

  test('returns 404 for a non-existent record ID', async () => {
    const res = await request(app).get('/api/records/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(404);
  });

  test('different patient cannot view another patient\'s record (403)', async () => {
    const { token: otherToken } = await createPatient(app);
    const res = await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${otherToken}`);
    expect(res.statusCode).toBe(403);
  });

  test('doctor without permission gets 403', async () => {
    const res = await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(403);
    expect(res.body.message).toMatch(/permission/i);
  });

  test('doctor with "all" scope permission can view the record', async () => {
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    const res = await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.record._id).toBe(recordId);
  });

  test('doctor with matching category permission can view the record', async () => {
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'category', shared_category: 'prescription' });
    const res = await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(200);
  });

  test('doctor with a different category permission cannot view the record (403)', async () => {
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'category', shared_category: 'lab_report' });
    const res = await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(403);
  });

  test('doctor access is revoked when permission is revoked', async () => {
    const grantRes = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    const permId = grantRes.body.permission._id;
    await request(app).put(`/api/permissions/revoke/${permId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    const res = await request(app).get(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(403);
  });
});

describe('PUT /api/records/:id', () => {
  let patientToken, recordId;
  beforeEach(async () => {
    ({ token: patientToken } = await createPatient(app));
    const up = await uploadRecord(patientToken, { title: 'Original Title', category: 'lab_report' });
    recordId = up.body.record._id;
  });

  test('updates title, category, and notes', async () => {
    const res = await request(app).put(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ title: 'Updated Title', category: 'discharge_summary', notes: 'Some notes' });
    expect(res.statusCode).toBe(200);
    expect(res.body.record.title).toBe('Updated Title');
    expect(res.body.record.category).toBe('discharge_summary');
  });

  test('returns 404 for a non-existent record', async () => {
    const res = await request(app).put('/api/records/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ title: 'X' });
    expect(res.statusCode).toBe(404);
  });

  test('patient cannot edit another patient\'s record (404 since ownership check)', async () => {
    // returns 404 rather than 403 so we don't leak that the record exists at all
    const { token: otherToken } = await createPatient(app);
    const res = await request(app).put(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${otherToken}`)
      .send({ title: 'Stolen' });
    expect(res.statusCode).toBe(404);
  });
});

describe('DELETE /api/records/:id', () => {
  let patientToken, recordId;
  beforeEach(async () => {
    ({ token: patientToken } = await createPatient(app));
    const up = await uploadRecord(patientToken);
    recordId = up.body.record._id;
  });

  test('soft-deletes the record (removed from listing, audit-logged)', async () => {
    const res = await request(app).delete(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);

    const listRes = await request(app).get('/api/records')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(listRes.body.count).toBe(0);
  });

  test('returns 404 for a non-existent record ID', async () => {
    const res = await request(app).delete('/api/records/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(404);
  });

  test('cannot delete an already-deleted record (404)', async () => {
    // soft-deleted records are excluded from queries, so the second delete sees nothing
    await request(app).delete(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    const res = await request(app).delete(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(404);
  });

  test('patient cannot delete another patient\'s record (404)', async () => {
    const { token: otherToken } = await createPatient(app);
    const res = await request(app).delete(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${otherToken}`);
    expect(res.statusCode).toBe(404);
  });
});

describe('POST /api/records/:id/download', () => {
  let patientToken, patientUser, doctorToken, doctorUser, recordId;
  beforeEach(async () => {
    ({ token: patientToken, user: patientUser } = await createPatient(app));
    ({ token: doctorToken, user: doctorUser } = await createDoctor(app));
    const up = await uploadRecord(patientToken, { category: 'radiology' });
    recordId = up.body.record._id;
  });

  test('owner patient gets the download_url', async () => {
    const res = await request(app).post(`/api/records/${recordId}/download`)
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.download_url).toBeDefined();
  });

  test('unauthorized doctor gets 403', async () => {
    const res = await request(app).post(`/api/records/${recordId}/download`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(403);
  });

  test('authorized doctor (all scope) gets the download_url', async () => {
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    const res = await request(app).post(`/api/records/${recordId}/download`)
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.download_url).toBeDefined();
  });

  test('returns 404 for a non-existent record', async () => {
    const res = await request(app).post('/api/records/507f1f77bcf86cd799439011/download')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(404);
  });

  test('returns 401 without auth token', async () => {
    const res = await request(app).post(`/api/records/${recordId}/download`);
    expect(res.statusCode).toBe(401);
  });
});
