# Observability & Security Report — Full Monitoring Stack

**Project:** Full Observability & Security Solution  
**Date:** 2026-04-29  
**Author:** Cedrick Bienvenue  
**Stack:** Node.js / Express · Prometheus · Grafana · AWS CloudWatch · CloudTrail · GuardDuty

---

## 1. Executive Summary

This report documents the implementation and verification of a complete observability and security stack for a containerised Node.js application. The system was built to answer three questions that no traditional deployment can answer: *Is the application performing correctly right now?* *What happened in the AWS account over the last 24 hours?* *Is anyone attacking the infrastructure?*

Prometheus and Grafana address the first question through real-time metrics and dashboards. CloudWatch addresses log persistence outside the container lifecycle. CloudTrail and GuardDuty address the second and third questions through API audit trails and continuous threat detection. All infrastructure was provisioned with Terraform modules and all EC2 configuration was automated with Ansible — no manual server steps.

---

## 2. Metrics & Instrumentation

### What Was Instrumented

The Node.js application was instrumented using `prom-client`. Two custom metrics were added:

| Metric | Type | Labels | Purpose |
|---|---|---|---|
| `http_requests_total` | Counter | `method`, `route`, `status_code` | Counts every HTTP request by route and outcome |
| `http_request_duration_seconds` | Histogram | `method`, `route`, `status_code` | Measures latency distribution with 12 buckets (5ms → 10s) |

Default process metrics (`collectDefaultMetrics`) added CPU usage, memory (RSS, heap), event loop lag, and process uptime automatically — no additional code required.

### Scrape Configuration

Prometheus was configured to scrape three targets every 15 seconds:

| Target | Job | Metrics |
|---|---|---|
| `app:3000/metrics` | `node-app` | HTTP counters, histograms, process metrics |
| `node-exporter:9100/metrics` | `node-exporter` | Host CPU, memory, disk, network |
| `prometheus:9090/metrics` | `prometheus` | Prometheus internal metrics |

All three targets reported **UP** throughout the verification period.

### Dashboard Insights

The Grafana dashboard revealed the following during load testing (20 sequential requests):

- **Requests/sec** peaked at `0.87 req/s` — confirming the counter was incrementing correctly per route
- **p95 Latency** held at `4.75ms` — all responses well within acceptable bounds, confirming no blocking I/O
- **App Uptime** computed as `time() - node_app_process_start_time_seconds` — confirmed continuous process health
- **Error Rate** showed `No data` on the 5xx panel — expected, as no errors were injected during normal load

---

## 3. Alert Rules

Three alert rules were defined in `prometheus/alert_rules.yml`:

| Alert | Expression | Threshold | Severity |
|---|---|---|---|
| `HighErrorRate` | `rate(http_requests_total{status_code=~"5.."}[1m]) / rate(http_requests_total[1m])` | > 5% for 1m | critical |
| `HighLatency` | `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[2m]))` | > 500ms for 2m | warning |
| `AppDown` | `up{job="node-app"} == 0` | 1 minute | critical |

### Alert Verification

The `AppDown` alert was deliberately triggered by stopping the app container:

```bash
docker stop node-app
```

After 60 seconds, the alert transitioned from **pending** to **firing** in the Prometheus UI — confirming the alerting pipeline was functional end-to-end. Restarting the container resolved the alert within the next scrape cycle (15 seconds).

`HighErrorRate` and `HighLatency` remained **inactive** throughout normal operation — confirming the application performs within defined SLOs under the test load.

---

## 4. Log Management — CloudWatch

### Architecture

The Docker `awslogs` log driver was configured via a Compose override file (`docker-compose.cloudwatch.yml`). When the stack starts with the override, the Docker daemon on EC2 streams every line written to `stdout`/`stderr` by the app container directly to AWS CloudWatch — bypassing the container filesystem entirely.

Authentication is handled by the IAM instance profile attached to the EC2 instance. No AWS credentials are stored in environment variables or files on the server.

### Key Insight

Container logs written to `stdout` are ephemeral by default — they vanish when the container or instance is terminated. Routing them to CloudWatch makes them durable, searchable, and accessible without SSH access to the server. The `/monitoring-lab/app` log group captured the server startup message (`Server running on port 3000`) and subsequent HTTP request logs immediately after container start, confirming the log pipeline was working within seconds.

The CloudTrail event `CreateLogStream` from principal `i-0bda6054279387ddf` (the EC2 instance itself) confirmed the IAM instance profile was being used — not static credentials.

---

## 5. Security Findings

### CloudTrail

CloudTrail was configured as a multi-region trail with log file validation enabled, streamed to both an S3 bucket and a CloudWatch log group. The S3 bucket is encrypted with AES-256, versioned, and subject to a lifecycle policy that transitions logs to STANDARD_IA at 30 days, GLACIER at 90 days, and expires them at 365 days.

During the lab, CloudTrail recorded the complete infrastructure lifecycle:

| Event | Actor | Significance |
|---|---|---|
| `RunInstances` | cedrick13bienvenue | EC2 launch recorded with full resource list |
| `CreateTrail` | cedrick13bienvenue | Trail creation itself is audited |
| `AssociateIamInstanceProfile` | cedrick13bienvenue | Role attachment to EC2 recorded |
| `CreateLogStream` | EC2 instance | Confirms instance-role auth (not user keys) |
| `ModifySecurityGroupRules` | cedrick13bienvenue | IP-based SSH rule update captured |
| `ConsoleLogin` | cedrick13bienvenue | All console access tracked |

This trail provides a complete forensic record. Any future unauthorized API call — from a compromised key, an insider, or a misconfigured service — will appear in this log with timestamp, source IP, and the exact resource affected.

### GuardDuty

GuardDuty was enabled with a finding publishing frequency of `SIX_HOURS` (non-production setting). It continuously analyzes CloudTrail management events, VPC flow logs, and DNS query logs for anomalous patterns.

**Findings: 0** throughout the lab period.

This is the expected and correct outcome — the infrastructure was accessed only from known IPs using legitimate credentials. A real threat scenario (e.g., credential theft, port scanning, crypto-mining process spawning) would generate findings in the GuardDuty console within minutes, without any log parsing or manual analysis.

---

## 6. Key Insights

**Ansible over user_data is strictly better for server configuration.** `user_data` scripts run once at boot with no output visible until the instance is fully up. Ansible gives live task-by-task feedback, is idempotent (safe to re-run), and separates infrastructure provisioning from server configuration cleanly. The `PLAY RECAP` line (`ok=12 changed=8 failed=0`) is an unambiguous confirmation that every step succeeded.

**IAM instance profiles eliminate credential sprawl.** The CloudWatch log driver authenticated using the EC2 instance profile — no `AWS_ACCESS_KEY_ID` was stored anywhere on the server. This is the correct pattern: credentials should never leave IAM. Static keys in `.env` files on servers are a common source of credential leaks.

**The Compose override pattern keeps environments clean.** `docker-compose.yml` uses `json-file` logging for local development. `docker-compose.cloudwatch.yml` switches only the app service to `awslogs`. The same codebase runs locally (no AWS dependency) and in production (CloudWatch) without any file modifications — just a different startup command.

**CloudTrail answers "who did what" retroactively.** The trail captured every Terraform action — resource creation, security group modifications, IAM role attachments — as a timestamped, signed audit record. This is the only reliable way to investigate a production incident or a compliance audit after the fact.

**Metrics without alerts are incomplete.** Dashboards show what is happening now. Alert rules encode what "wrong" looks like and notify before a human notices. The `AppDown` alert firing within 60 seconds of the container stopping demonstrates that the monitoring system is faster than any on-call engineer.
