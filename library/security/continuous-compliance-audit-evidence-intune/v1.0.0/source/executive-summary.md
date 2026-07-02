# Executive Summary — Continuous Compliance Monitoring & Audit-Evidence Automation

## The problem

Passing a CIS or STIG baseline **once** is not the same as **proving** you are still compliant months
later. In a federally regulated environment, endpoints drift — a policy is edited, an exclusion is
added, a device enrolls without the baseline — and when an auditor asks for evidence, teams scramble
to gather it by hand. Point-in-time compliance and manual evidence collection are a standing audit
risk.

## The solution

A **repeatable operational method — with PowerShell scripts you keep** — to continuously monitor
baseline **drift** and automate **audit evidence** for Intune + Entra endpoints. It follows a simple,
provable cycle:

**Baseline → Measure → Detect drift → Evidence / POA&M → Remediate / track.**

The scripts read the live state of your CIS/STIG controls from Microsoft Graph (read-only), compare it
to your approved baseline, flag every control that has drifted, and export **dated audit evidence**
plus a **POA&M-ready gap list** — the exact artifacts an auditor expects. Drifted settings can then be
safely re-applied (preview first) and re-measured to prove closure.

This is an **operations product**, distinct from a one-time baseline build. The build creates the
policies; this solution proves they stay true and produces the paperwork on demand.

## What is included

- A complete documentation set: Overview, Requirements, Implementation, Testing, Troubleshooting, Best
  Practices, and Deliverables.
- **Five PowerShell scripts** (Microsoft Graph SDK): control-state discovery, per-device baseline
  conformance, an audit-evidence + drift/gap report (POA&M-ready), safe remediation (preview by
  default), and a target-group builder (preview by default).
- A phased rollout — **Assess → Configure → Pilot → Validate → Expand** — with pass/fail gates and a
  scheduled fleet-wide cadence.

## Business value

- **Prove compliance any day**, not just deployment day.
- **Detect drift automatically** before an auditor does.
- **Cut audit-prep effort** — evidence and POA&M gaps export on demand, correctly formatted.
- **Reduce risk** — safe, preview-first remediation and full change control.
- **Own the capability** — a method and scripts you reuse across audit cycles, at a fraction of
  ongoing consulting cost.

## Bottom line

Continuous, provable endpoint compliance — drift detected and audit evidence exported on demand — with
a repeatable method and scripts you keep and reuse between audits. The specific CIS/STIG rule content
is deferred to CIS and DISA; this solution delivers the precise monitoring and evidence method on
Intune + Entra.
