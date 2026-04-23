'use strict';

const express = require('express');
const { register, metricsMiddleware } = require('./metrics');

const app = express();

app.use(express.json());
app.use(metricsMiddleware);

app.get('/', (_req, res) => {
  res.status(200).json({
    message: 'Hello from the CI/CD Pipeline!',
    version: process.env.APP_VERSION || '1.0.0',
  });
});

app.get('/health', (_req, res) => {
  res.status(200).json({
    status:    'healthy',
    uptime:    process.uptime(),
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/items', (_req, res) => {
  const items = [
    { id: 1, name: 'Pipeline Stage: Checkout' },
    { id: 2, name: 'Pipeline Stage: Build' },
    { id: 3, name: 'Pipeline Stage: Test' },
    { id: 4, name: 'Pipeline Stage: Docker Build' },
    { id: 5, name: 'Pipeline Stage: Push Image' },
    { id: 6, name: 'Pipeline Stage: Deploy' },
  ];
  res.status(200).json({ count: items.length, items });
});

app.get('/metrics', async (_req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err.message);
  }
});

app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

module.exports = app;
