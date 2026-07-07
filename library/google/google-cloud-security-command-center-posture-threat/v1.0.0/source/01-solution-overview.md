# Solution Overview

## What this is

**Security Command Center (SCC)** is Google Cloud's built-in security and risk-management
platform. It scans the resource hierarchy for **misconfigurations and vulnerabilities**
(posture findings), surfaces **active threats** from log- and behavior-based detectors, and
presents everything as normalized **findings** in one console. This solution takes SCC from
"turned on somewhere" to **operationalized at the Organization**: enabled org-wide, tuned to
cut noise, wired to **Pub/Sub notifications** and a **SIEM export**, and backed by a
**triage / ownership / remediation-SLA workflow** so findings are not just seen but worked.

The engagement delivers the enablement design, the exact `gcloud`/Console procedure, a triage
operating model, and **five Python tools** (`gcloud` / Cloud Client Library automation,
read-only or dry-run by default) that assess coverage, set up exports, generate an SLA triage
report, check posture guardrails, and manage notification/export configuration.

> **Editions & detectors are version-dependent — verify your edition.** SCC is offered in
> tiers/editions whose exact names, packaging, and included detectors **change over time**
> (historically Standard / Premium, and the **Security Command Center Enterprise** tier). Which
> **posture services** (e.g. Security Health Analytics), **vulnerability** scanners, and
> **threat detectors** (e.g. Event Threat Detection, Container Threat Detection, Virtual Machine
> Threat Detection) are available — and whether a feature is GA or preview — **depends on your
> active edition and can change**. This solution names detectors and services **as categories**
> and instructs you to **confirm the exact set in your Organization** against Google's current
> SCC documentation before relying on any single one. Do not assume a detector exists because it
> is referenced here.

## How it works

SCC operates at or below the **Organization** node and aggregates findings from its enabled
**services**:

1. **Posture / misconfiguration** — a health-analytics service continuously evaluates resources
   against a catalog of detectors (public buckets, open firewall rules, over-broad IAM, disabled
   logging, weak key rotation, etc.) and raises a finding per violation, each with a severity and
   a category.
2. **Vulnerabilities** — scanners identify software/package vulnerabilities and exposed
   surfaces on in-scope workloads (availability depends on edition).
3. **Threat detection** — log- and behavior-based detectors raise findings on suspicious
   activity (anomalous IAM grants, crypto-mining signals, malware, data-exfiltration patterns,
   and similar) — the exact detector set is **edition-dependent**.
4. **Notifications & export** — SCC publishes findings to a **Pub/Sub topic** via a
   **notification config**; downstream subscribers (a SIEM connector, a ticketing webhook, a
   function) act on them. Continuous export to a **SIEM** (via the Pub/Sub topic or the SCC API)
   gives SecOps a single stream.
5. **Triage & remediation** — findings are routed to an **owner** by project/service/category,
   worked to a **remediation SLA** keyed to severity, and their state (`ACTIVE` → `INACTIVE`)
   plus mute rules drive the metrics that prove risk is being reduced.

## Reference design

The reference design in this guide uses these named artifacts (reused verbatim in the steps,
tests, and scripts):

- **SCC Enablement – Org – Pilot** — the org-level activation and service configuration validated
  first against a pilot scope.
- **Finding Notification – Org – v1** — the SCC notification config that publishes findings to
  Pub/Sub.
- **Finding Export Topic – SecOps – v1** — the Pub/Sub topic (+ subscription) that carries
  findings to the SIEM / downstream consumers.
- **Posture Baseline – Corp – v1** — the agreed set of enabled posture detectors and their
  mute/exception rules (the "known-good" posture).
- **Triage Runbook – SecOps – v1** — the ownership matrix, severity→SLA table, and triage cycle.
- **Pilot Scope – Prod-Ready – v1** — the folder/project subset the whole configuration is
  validated on before org-wide expansion.

## Benefits

- **One console for cloud risk** — posture, vulnerabilities, and threats in a single normalized
  finding stream instead of scattered, per-service alerts.
- **Findings that get worked, not just seen** — explicit ownership and severity-based SLAs turn a
  dashboard into an operating process with measurable closure.
- **SIEM-native** — findings flow to existing SecOps tooling via Pub/Sub, so cloud risk joins the
  same detection-and-response pipeline as the rest of the estate.
- **Noise controlled** — a deliberate posture baseline plus mute rules keep the signal high so
  responders trust the queue.
- **Safe to adopt** — pilot-first, with pass/fail gates and a documented rollback for every
  org-wide change.

## Limitations & boundaries

- **Edition-gated capability.** The available services and detectors depend on your **SCC
  edition** — verify the exact set; this solution does not guarantee any specific detector is
  present in your tenant.
- **Detection ≠ prevention.** SCC surfaces and routes risk; it does not by itself remediate.
  Remediation is performed by the owning team (optionally with SCC/Cloud Functions automation
  you build separately).
- **Scope is Google Cloud.** SCC covers the Google Cloud Organization and its resources; other
  clouds/estates are out of scope (some editions offer multi-cloud connectors — **verify**).
- **Legal/compliance interpretation deferred.** Whether a finding constitutes a reportable
  compliance gap is a determination for the organization's security/compliance/legal functions;
  this solution provides the technical detection, routing, and evidence.
- **IaC at the pattern level.** Terraform / Cloud Foundation Toolkit blueprints are shown as a
  pattern with representative snippets; module internals defer to the provider's own docs.

## Deployment model

This solution follows the house model — **Assess → Design → Configure → Pilot → Validate →
Expand** — pilot-first, with explicit pass/fail gates and a documented rollback before any
org-wide change:

1. **Assess** — inventory current SCC state, edition, org access, and SIEM/notification targets
   (read-only; script #1).
2. **Design** — decide the posture baseline, notification/export topology, ownership matrix, and
   severity→SLA table; pick the pilot scope.
3. **Configure** — enable/tune SCC services, create the notification config and export topic,
   apply the posture baseline (dry-run first; scripts #2, #5).
4. **Pilot** — run the configuration against **Pilot Scope – Prod-Ready – v1**; confirm findings
   surface, route, and export end-to-end.
5. **Validate** — run a full triage cycle; confirm findings are owned and closed within SLA
   (scripts #3, #4) against the pass/fail gates.
6. **Expand** — extend org-wide once the gates pass; keep the triage runbook and metrics running.
