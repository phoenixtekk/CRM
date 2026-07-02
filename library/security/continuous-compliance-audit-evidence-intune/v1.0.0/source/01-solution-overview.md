# Solution Overview — Continuous Compliance Monitoring & Audit-Evidence Automation (CIS/STIG on Intune + Entra)

## What this solution is

Passing a CIS or STIG baseline **once** is not the same as **proving** you are still compliant
months later, when an auditor asks for evidence. Devices drift: a policy is edited, an exclusion is
added, a new device enrolls without the baseline, a user with local rights changes a setting. This
solution gives you a **repeatable, operational method** — with PowerShell scripts you keep and
reuse — to:

1. **Baseline** — take the CIS/STIG control set you already deployed to Intune + Entra and treat it
   as the *expected state* (the reference you measure against).
2. **Measure** — read the *current state* of those controls for each in-scope device and identity
   directly from Microsoft Graph (read-only).
3. **Detect drift** — compare current state to the baseline and flag every control that no longer
   matches (drifted, missing, or newly non-conformant).
4. **Evidence / POA&M** — export the measurement as **audit evidence** (a dated, per-control,
   per-device record) and produce a **POA&M-ready gap list** (Plan of Action & Milestones) of the
   controls that fail, so remediation can be planned and tracked.
5. **Remediate / track** — safely re-apply the drifted settings (preview first) and re-measure to
   confirm the gap closed — then keep the cycle running on a schedule.

This is an **operations product**, distinct from a one-time baseline *build*. The build creates the
policies; **this solution watches them stay true and produces the paperwork** an audit requires.

## The continuous-compliance model

```
   Baseline ──▶ Measure ──▶ Detect drift ──▶ Evidence / POA&M ──▶ Remediate / track
   (expected)   (current)    (compare)         (export)             (fix + re-measure)
      ▲                                                                     │
      └─────────────────────────  re-baseline on approved change  ◀────────┘
```

- **Baseline (expected state).** Your approved CIS/STIG configuration in Intune (Settings Catalog /
  device-configuration / compliance policies / Security Baselines) and Entra (Conditional Access,
  authentication methods, tenant security settings). The specific CIS Benchmark / DISA STIG **rule
  IDs and official control text are deferred to CIS and DISA** — this solution does not reproduce or
  fabricate them. You supply *which* Intune/Entra objects encode your baseline; the method measures
  and evidences them.
- **Measure (current state).** The scripts query Microsoft Graph read-only for the live value of
  each monitored control on each in-scope device/identity — no changes are made during measurement.
- **Detect drift.** Current vs. expected, per control per device. Output is a conformance verdict:
  **Pass** (matches baseline), **Drift** (was compliant, now differs), **Missing** (baseline not
  applied to this device), or **Non-conformant** (never matched).
- **Evidence / POA&M.** Two exports: (a) an **audit-evidence** package — timestamped, immutable
  CSV/JSON showing what was measured, when, by whom, and the result; (b) a **POA&M-ready gap** list —
  each failing control with device count, severity, and a milestone/owner column ready to paste into
  your organization's POA&M template.
- **Remediate / track.** For drifted settings only, a safe remediation re-applies the baseline
  targeting (default **preview / -WhatIf** — nothing changes until you confirm). Re-measure to prove
  closure; the evidence trail records the fix.

## How it complements a one-time CIS/STIG build

| One-time baseline build | This continuous-compliance solution |
|---|---|
| Creates the CIS/STIG policies in Intune/Entra | Treats those policies as the measured reference |
| Proves compliance **on deployment day** | Proves compliance **on any day, on demand** |
| Output: configured tenant | Output: drift alerts + dated audit evidence + POA&M gaps |
| Runs once | Runs on a schedule (pilot, then fleet-wide) |
| Answers "did we set it?" | Answers "is it *still* set — and can we prove it?" |

If you have not yet built a CIS/STIG baseline, do that first; this solution assumes an existing
baseline to measure against (see Requirements). If you have, this is the operational layer that keeps
it audit-defensible.

## Where the evidence comes from

All evidence is derived from **authoritative, first-party sources** via Microsoft Graph — never
hand-typed:

- **Intune configuration state** — device configuration / Settings Catalog profiles, compliance
  policies, and Security Baseline assignments and their reported values.
- **Intune device compliance & per-setting state** — each device's compliance status and, where
  exposed, per-setting reporting (`deviceCompliancePolicyDeviceStateSummary`, device configuration
  device-status).
- **Entra configuration state** — Conditional Access policies, authentication-method policy, and
  tenant security-relevant settings that encode identity controls in your baseline.
- **Directory / device inventory** — the in-scope device and group membership that defines *who the
  baseline should apply to*, so "Missing" can be distinguished from "Drift".

Each measurement record carries a **collection timestamp, the tenant, the operator identity, the
control identifier, the expected value, the observed value, and the verdict** — the fields an auditor
expects. Evidence is exported to a **reporting destination** you control (see Requirements) and
retained per your **evidence-retention** policy.

## Deployment model

This solution follows the category standard: **Assess → Configure → Pilot → Validate → Expand**, with
a **pass/fail gate** at each stage. You will first prove the method on a small **pilot group**
(measure, detect a seeded drift, export evidence), validate the outputs against your audit
requirements, then expand to the full fleet on a schedule. The scripts are read-only by default;
the only script that changes anything (Remediation) and the targeting builder (Set-ScopeTargeting)
run in **preview (-WhatIf)** until you explicitly commit.

## What you get

- This documentation set (Overview, Requirements, Implementation, Testing, Troubleshooting, Best
  Practices, Deliverables).
- **Five PowerShell scripts** (Microsoft Graph SDK): control-state **Discovery**, per-device baseline
  **Validation**, an audit-evidence + drift/gap **Report** (POA&M-ready), safe **Remediation** of
  drifted settings (default preview), and a **Set-ScopeTargeting** pilot-group builder (default
  preview).
