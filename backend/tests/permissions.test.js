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

describe('Auth guards: all permissions endpoints require a token', () => {
  // valid ObjectId format avoids a Mongoose CastError before the auth check even runs
  const fakeId = '507f1f77bcf86cd799439011';
  test('POST /api/permissions/grant', async () => {
    expect((await request(app).post('/api/permissions/grant')).statusCode).toBe(401);
  });
  test('PUT /api/permissions/revoke/:id', async () => {
    expect((await request(app).put(`/api/permissions/revoke/${fakeId}`)).statusCode).toBe(401);
  });
  test('PUT /api/permissions/:id', async () => {
    expect((await request(app).put(`/api/permissions/${fakeId}`)).statusCode).toBe(401);
  });
  test('GET /api/permissions/my-doctors', async () => {
    expect((await request(app).get('/api/permissions/my-doctors')).statusCode).toBe(401);
  });
  test('GET /api/permissions/shared-with-me', async () => {
    expect((await request(app).get('/api/permissions/shared-with-me')).statusCode).toBe(401);
  });
});

describe('POST /api/permissions/grant', () => {
  let patientToken, doctorToken, doctorUser;
  beforeEach(async () => {
    ({ token: patientToken } = await createPatient(app));
    ({ token: doctorToken, user: doctorUser } = await createDoctor(app));
  });

  test('grants full access and returns the permission document', async () => {
    const res = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.permission.scope_type).toBe('all');
    expect(res.body.permission.access_status).toBe('granted');
  });

  test('grants category-scoped access', async () => {
    const res = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'category', shared_category: 'prescription' });
    expect(res.statusCode).toBe(200);
    expect(res.body.permission.scope_type).toBe('category');
    expect(res.body.permission.shared_category).toBe('prescription');
  });

  test('upserts: granting twice updates scope instead of creating a duplicate', async () => {
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    // second grant should overwrite the first, not create a second permission record
    const res = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'category', shared_category: 'lab_report' });
    expect(res.statusCode).toBe(200);
    expect(res.body.permission.scope_type).toBe('category');

    const listRes = await request(app).get('/api/permissions/my-doctors')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(listRes.body.permissions).toHaveLength(1);
  });

  test('re-grants a previously revoked permission (sets status back to granted)', async () => {
    const grantRes = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    const permId = grantRes.body.permission._id;
    // revoke it first, then re-grant - the same document should be reactivated
    await request(app).put(`/api/permissions/revoke/${permId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    const res = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    expect(res.statusCode).toBe(200);
    expect(res.body.permission.access_status).toBe('granted');
  });

  test('returns 404 for a non-existent provider_user_id', async () => {
    const res = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: '507f1f77bcf86cd799439011', scope_type: 'all' });
    expect(res.statusCode).toBe(404);
  });

  test('returns 404 when provider_user_id belongs to a patient (not a doctor)', async () => {
    const { user: anotherPatient } = await createPatient(app);
    const res = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: anotherPatient.id, scope_type: 'all' });
    expect(res.statusCode).toBe(404);
  });

  test('returns 403 when caller is a doctor (patient-only endpoint)', async () => {
    const res = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${doctorToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    expect(res.statusCode).toBe(403);
  });
});

describe('PUT /api/permissions/revoke/:permissionId', () => {
  let patientToken, doctorUser, permissionId;
  beforeEach(async () => {
    ({ token: patientToken } = await createPatient(app));
    ({ user: doctorUser } = await createDoctor(app));
    const grantRes = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    permissionId = grantRes.body.permission._id;
  });

  test('revokes an existing granted permission', async () => {
    const res = await request(app).put(`/api/permissions/revoke/${permissionId}`)
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.success).toBe(true);

    const listRes = await request(app).get('/api/permissions/my-doctors')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(listRes.body.permissions).toHaveLength(0);
  });

  test('returns 404 for a non-existent permission', async () => {
    const res = await request(app).put('/api/permissions/revoke/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(404);
  });

  test('returns 403 when a different patient tries to revoke the permission', async () => {
    const { token: otherToken } = await createPatient(app);
    const res = await request(app).put(`/api/permissions/revoke/${permissionId}`)
      .set('Authorization', `Bearer ${otherToken}`);
    expect(res.statusCode).toBe(403);
  });
});

describe('PUT /api/permissions/:permissionId', () => {
  let patientToken, doctorUser, permissionId;
  beforeEach(async () => {
    ({ token: patientToken } = await createPatient(app));
    ({ user: doctorUser } = await createDoctor(app));
    const grantRes = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    permissionId = grantRes.body.permission._id;
  });

  test('updates scope_type to category with a shared_category', async () => {
    const res = await request(app).put(`/api/permissions/${permissionId}`)
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ scope_type: 'category', shared_category: 'radiology' });
    expect(res.statusCode).toBe(200);
    expect(res.body.permission.scope_type).toBe('category');
    expect(res.body.permission.shared_category).toBe('radiology');
  });

  test('clears shared_category when scope is changed back to "all"', async () => {
    await request(app).put(`/api/permissions/${permissionId}`)
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ scope_type: 'category', shared_category: 'radiology' });
    const res = await request(app).put(`/api/permissions/${permissionId}`)
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ scope_type: 'all' });
    expect(res.statusCode).toBe(200);
    expect(res.body.permission.shared_category).toBeNull();
  });

  test('returns 404 for a non-existent permission', async () => {
    const res = await request(app).put('/api/permissions/507f1f77bcf86cd799439011')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ scope_type: 'all' });
    expect(res.statusCode).toBe(404);
  });

  test('returns 403 when a different patient tries to update the permission', async () => {
    const { token: otherToken } = await createPatient(app);
    const res = await request(app).put(`/api/permissions/${permissionId}`)
      .set('Authorization', `Bearer ${otherToken}`)
      .send({ scope_type: 'all' });
    expect(res.statusCode).toBe(403);
  });
});

describe('GET /api/permissions/my-doctors', () => {
  test('returns an empty array when no permissions exist', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/permissions/my-doctors')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.permissions).toHaveLength(0);
  });

  test('returns populated granted permissions with doctor details', async () => {
    const { token: patientToken } = await createPatient(app);
    const { user: doctorUser } = await createDoctor(app);
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    const res = await request(app).get('/api/permissions/my-doctors')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.permissions).toHaveLength(1);
    expect(res.body.permissions[0].access_status).toBe('granted');
  });

  test('does not show revoked permissions', async () => {
    const { token: patientToken } = await createPatient(app);
    const { user: doctorUser } = await createDoctor(app);
    const grantRes = await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    await request(app).put(`/api/permissions/revoke/${grantRes.body.permission._id}`)
      .set('Authorization', `Bearer ${patientToken}`);
    const res = await request(app).get('/api/permissions/my-doctors')
      .set('Authorization', `Bearer ${patientToken}`);
    expect(res.body.permissions).toHaveLength(0);
  });

  test('returns 403 when caller is a doctor (patient-only)', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/permissions/my-doctors')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });
});

describe('GET /api/permissions/shared-with-me', () => {
  test('returns empty data array when no patients have granted access', async () => {
    const { token } = await createDoctor(app);
    const res = await request(app).get('/api/permissions/shared-with-me')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data).toHaveLength(0);
  });

  test('returns patient info and accessible records after grant', async () => {
    const { token: patientToken } = await createPatient(app);
    const { token: doctorToken, user: doctorUser } = await createDoctor(app);
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'all' });
    const res = await request(app).get('/api/permissions/shared-with-me')
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].patient).toBeDefined();
    expect(Array.isArray(res.body.data[0].records)).toBe(true);
  });

  test('returns only records matching shared_category when scope is category', async () => {
    const { token: patientToken } = await createPatient(app);
    const { token: doctorToken, user: doctorUser } = await createDoctor(app);
    // upload one prescription and one lab report so we can verify the filter works
    await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${patientToken}`)
      .attach('file', Buffer.from('%PDF'), { filename: 'a.pdf', contentType: 'application/pdf' })
      .field('title', 'Prescription')
      .field('category', 'prescription');
    await request(app).post('/api/records/upload')
      .set('Authorization', `Bearer ${patientToken}`)
      .attach('file', Buffer.from('%PDF'), { filename: 'b.pdf', contentType: 'application/pdf' })
      .field('title', 'Lab Report')
      .field('category', 'lab_report');
    await request(app).post('/api/permissions/grant')
      .set('Authorization', `Bearer ${patientToken}`)
      .send({ provider_user_id: doctorUser.id, scope_type: 'category', shared_category: 'prescription' });
    const res = await request(app).get('/api/permissions/shared-with-me')
      .set('Authorization', `Bearer ${doctorToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.data[0].records).toHaveLength(1);
    expect(res.body.data[0].records[0].category).toBe('prescription');
  });

  test('returns 403 when caller is a patient (doctor-only)', async () => {
    const { token } = await createPatient(app);
    const res = await request(app).get('/api/permissions/shared-with-me')
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });
});
