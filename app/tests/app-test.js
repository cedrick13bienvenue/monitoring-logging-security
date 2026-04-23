'use strict';

const { expect } = require('chai');
const request    = require('supertest');
const app        = require('../src/app');

describe('GET /', () => {
  it('returns 200 with a welcome message', async () => {
    const res = await request(app).get('/');
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('message', 'Hello from the CI/CD Pipeline!');
    expect(res.body).to.have.property('version');
  });
});

describe('GET /health', () => {
  it('returns 200 with a healthy status object', async () => {
    const res = await request(app).get('/health');
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('status', 'healthy');
    expect(res.body).to.have.property('uptime').that.is.a('number');
    expect(res.body).to.have.property('timestamp').that.is.a('string');
  });

  it('timestamp is a valid ISO 8601 date string', async () => {
    const res = await request(app).get('/health');
    expect(new Date(res.body.timestamp).getTime()).to.be.a('number').and.not.NaN;
  });
});

describe('GET /api/items', () => {
  it('returns 200 with items array matching the count field', async () => {
    const res = await request(app).get('/api/items');
    expect(res.status).to.equal(200);
    expect(res.body).to.have.property('count');
    expect(res.body.items).to.be.an('array').with.lengthOf(res.body.count);
  });

  it('each item has a numeric id and a non-empty name', async () => {
    const res = await request(app).get('/api/items');
    res.body.items.forEach((item) => {
      expect(item).to.have.property('id').that.is.a('number');
      expect(item).to.have.property('name').that.is.a('string').and.not.empty;
    });
  });
});

describe('GET /undefined-route', () => {
  it('returns 404 with a structured error body', async () => {
    const res = await request(app).get('/undefined-route');
    expect(res.status).to.equal(404);
    expect(res.body).to.have.property('error', 'Route not found');
  });
});
