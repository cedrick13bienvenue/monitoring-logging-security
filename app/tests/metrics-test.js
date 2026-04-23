'use strict';

const { expect } = require('chai');
const request    = require('supertest');
const app        = require('../src/app');

describe('GET /metrics — format', () => {
  it('returns HTTP 200', async () => {
    const res = await request(app).get('/metrics');
    expect(res.status).to.equal(200);
  });

  it('sets Content-Type to Prometheus text format', async () => {
    const res = await request(app).get('/metrics');
    expect(res.headers['content-type']).to.include('text/plain');
  });

  it('response body is a non-empty string', async () => {
    const res = await request(app).get('/metrics');
    expect(res.text).to.be.a('string').and.not.empty;
  });
});

describe('GET /metrics — custom metric names', () => {
  let body;

  before(async () => {
    const res = await request(app).get('/metrics');
    body = res.text;
  });

  it('exports http_requests_total counter', () => {
    expect(body).to.include('# HELP http_requests_total');
    expect(body).to.include('# TYPE http_requests_total counter');
  });

  it('exports http_request_duration_seconds histogram', () => {
    expect(body).to.include('# HELP http_request_duration_seconds');
    expect(body).to.include('# TYPE http_request_duration_seconds histogram');
  });

  it('exports default Node.js process metrics with node_app_ prefix', () => {
    expect(body).to.include('node_app_process_cpu_seconds_total');
  });
});

describe('GET /metrics — counter behaviour', () => {
  it('increments http_requests_total after a request to /api/items', async () => {
    const before      = await request(app).get('/metrics');
    const countBefore = extractCounter(before.text, 'GET', '/api/items', '200');

    await request(app).get('/api/items');

    const after      = await request(app).get('/metrics');
    const countAfter = extractCounter(after.text, 'GET', '/api/items', '200');

    expect(countAfter).to.equal(countBefore + 1);
  });

  it('records a 404 counter entry for unknown routes', async () => {
    await request(app).get('/this-does-not-exist');
    const res = await request(app).get('/metrics');
    expect(res.text).to.include('status_code="404"');
  });
});

// ---------------------------------------------------------------------------

function extractCounter(body, method, route, statusCode) {
  const orderings = [
    new RegExp(`http_requests_total\\{[^}]*method="${method}"[^}]*route="${escapeRegex(route)}"[^}]*status_code="${statusCode}"[^}]*\\}\\s+(\\d+)`),
    new RegExp(`http_requests_total\\{[^}]*route="${escapeRegex(route)}"[^}]*method="${method}"[^}]*status_code="${statusCode}"[^}]*\\}\\s+(\\d+)`),
    new RegExp(`http_requests_total\\{[^}]*status_code="${statusCode}"[^}]*method="${method}"[^}]*route="${escapeRegex(route)}"[^}]*\\}\\s+(\\d+)`),
  ];

  for (const re of orderings) {
    const match = body.match(re);
    if (match) return parseInt(match[1], 10);
  }
  return 0;
}

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
