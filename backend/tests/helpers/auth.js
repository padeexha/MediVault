const request = require('supertest');

let _seq = 0;

async function createPatient(app, overrides = {}) {
  const seq = ++_seq;
  const email = overrides.email || `patient${seq}@test.com`;
  const password = overrides.password || 'Test@1234';
  const body = {
    first_name: 'Test',
    last_name: 'Patient',
    email,
    password,
    ...overrides,
  };

  const reg = await request(app).post('/api/auth/register/patient').send(body);
  if (!reg.body.success) throw new Error(`Patient registration failed: ${reg.body.message}`);

  const login = await request(app).post('/api/auth/login').send({ email, password });
  if (!login.body.token) throw new Error(`Patient login failed: ${login.body.message}`);

  return { token: login.body.token, user: login.body.user, email, password };
}

async function createDoctor(app, overrides = {}) {
  const seq = ++_seq;
  const email = overrides.email || `doctor${seq}@test.com`;
  const password = overrides.password || 'Test@1234';
  const body = {
    first_name: 'Test',
    last_name: 'Doctor',
    email,
    password,
    specialization: 'Cardiology',
    organisation_name: 'Test Hospital',
    ...overrides,
  };

  const reg = await request(app).post('/api/auth/register/doctor').send(body);
  if (!reg.body.success) throw new Error(`Doctor registration failed: ${reg.body.message}`);

  const login = await request(app).post('/api/auth/login').send({ email, password });
  if (!login.body.token) throw new Error(`Doctor login failed: ${login.body.message}`);

  return { token: login.body.token, user: login.body.user, email, password };
}

module.exports = { createPatient, createDoctor };
