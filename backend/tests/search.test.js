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

const uploadRecord = (token, title, category) =>
  request(app)
    .post('/api/records/upload')
    .set('Authorization', `Bearer ${token}`)
    .attach('file', Buffer.from('%PDF-1.4 content'), {
      filename: 'test.pdf',
      contentType: 'application/pdf',
    })
    .field('title', title)
    .field('category', category);

describe('GET /api/search', () => {
  test('returns 401 without auth token', async () => {
    const res = await request(app).get('/api/search');
    expect(res.statusCode).toBe(401);
  });

  test('returns 403 when caller is a doctor (patient-only)', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });

  test('returns empty list when no records exist', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(0);
    expect(res.body.records).toEqual([]);
  });

  test('returns all non-deleted records when no filters applied', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Record A', 'prescription');
    await uploadRecord(token, 'Record B', 'lab_report');
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(2);
  });

  test('filters by partial title match (case-insensitive)', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Blood Glucose Report', 'lab_report');
    await uploadRecord(token, 'MRI Brain Scan', 'radiology');
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ title: 'blood' });
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.records[0].title).toBe('Blood Glucose Report');
  });

  test('filters by category', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Prescription A', 'prescription');
    await uploadRecord(token, 'Lab Report B', 'lab_report');
    await uploadRecord(token, 'Prescription C', 'prescription');
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ category: 'prescription' });
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(2);
    expect(res.body.records.every(r => r.category === 'prescription')).toBe(true);
  });

  test('can combine title and category filters', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Blood Glucose', 'lab_report');
    await uploadRecord(token, 'Blood Pressure', 'prescription');
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ title: 'blood', category: 'lab_report' });
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(1);
    expect(res.body.records[0].category).toBe('lab_report');
  });

  test('filters by date_from (returns records uploaded on or after the date)', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Old Record', 'other');
    // setting date_from to tomorrow means the record uploaded just now falls outside the range
    const future = new Date(Date.now() + 86400000).toISOString();
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ date_from: future });
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(0);
  });

  test('filters by date_to (returns records uploaded on or before the date)', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Recent Record', 'other');
    // setting date_to to yesterday excludes the record we just uploaded
    const past = new Date(Date.now() - 86400000).toISOString();
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ date_to: past });
    expect(res.statusCode).toBe(200);
    expect(res.body.count).toBe(0);
  });

  test('returns 400 for invalid date_from format', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ date_from: 'not-a-date' });
    expect(res.statusCode).toBe(400);
    expect(res.body.message).toMatch(/invalid date/i);
  });

  test('returns 400 for invalid date_to format', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ date_to: 'banana' });
    expect(res.statusCode).toBe(400);
  });

  test('sort_by=date_asc returns oldest record first', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'First Upload', 'other');
    await uploadRecord(token, 'Second Upload', 'other');
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ sort_by: 'date_asc' });
    expect(res.statusCode).toBe(200);
    expect(res.body.records).toHaveLength(2);
    const dates = res.body.records.map(r => new Date(r.upload_date));
    expect(dates[0] <= dates[1]).toBe(true);
  });

  test('sort_by=title_asc returns records alphabetically', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Zebra Report', 'other');
    await uploadRecord(token, 'Apple Report', 'other');
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ sort_by: 'title_asc' });
    expect(res.statusCode).toBe(200);
    expect(res.body.records[0].title).toBe('Apple Report');
  });

  test('sort_by=title_desc returns records reverse-alphabetically', async () => {
    const { token } = await createPatient(app);
    await uploadRecord(token, 'Zebra Report', 'other');
    await uploadRecord(token, 'Apple Report', 'other');
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`)
      .query({ sort_by: 'title_desc' });
    expect(res.statusCode).toBe(200);
    expect(res.body.records[0].title).toBe('Zebra Report');
  });

  test('excludes soft-deleted records from search results', async () => {
    const { token } = await createPatient(app);
    const upRes = await uploadRecord(token, 'Deleted Record', 'other');
    const recordId = upRes.body.record._id;
    await request(app).delete(`/api/records/${recordId}`)
      .set('Authorization', `Bearer ${token}`);
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${token}`);
    expect(res.body.count).toBe(0);
  });

  test('each patient only sees their own records in search', async () => {
    const { token: tokenA } = await createPatient(app);
    const { token: tokenB } = await createPatient(app);
    await uploadRecord(tokenA, 'Patient A Record', 'other');
    // patient B searching should find nothing, even though patient A has a record
    const res = await request(app).get('/api/search')
      .set('Authorization', `Bearer ${tokenB}`);
    expect(res.body.count).toBe(0);
  });
});
