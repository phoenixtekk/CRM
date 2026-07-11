# Executive Summary — Technical Blocker Mitigation: Defender for Identity

**White-label · Defender**

A Defender for Identity (MDI) rollout almost always stalls on the same short list of blockers: a **sensor that will not install or reports Unhealthy**, a **Directory Service Account (DSA)** with the wrong permissions, **missing network traffic** so Network Name Resolution (NNR) and lateral-movement detection are blind, or **event-collection gaps** where the required Windows audit events never reach the sensor. Left undiagnosed, MDI looks "deployed" but detects nothing. This solution is a **diagnostic-first playbook**: read-only discovery that pinpoints *which* blocker you actually have, the **targeted, documented manual fix**, and the verification that proves the sensor is healthy and identity signal is flowing — so a stuck rollout gets moving again fast.

This is a **run-it-yourself** package written for an administrator with no prior deep MDI troubleshooting experience. Every script is **read-only** — it reads sensor and DSA state, audit-policy readiness, and identity telemetry; it never changes a sensor, an account, or an audit policy. Any fix is a **documented manual step** you apply deliberately, on the affected sensor/domain-controller subset first.

## What you get
- A plain-language **Solution Overview** of the MDI signal chain — activation, sensor health, the DSA, network traffic / NNR, and event collection — and where each one breaks.
- A **Requirements Guide** with verify / implement-if-missing for the diagnostic-specific prerequisites.
- An **Implementation Guide** that walks the diagnostic loop end to end — pinpoint the blocker, apply the targeted fix, re-test the affected sensor, confirm healthy, resume the rollout.
- Five **read-only PowerShell scripts** (Microsoft Graph advanced-hunting KQL + a local DC audit-policy/NNR readiness check) for discovery, audit-policy readiness, blocker validation, a status report, and a support-ready data bundle.
- **Testing** and **Troubleshooting** guides that map every common symptom to its cause and fix.

## What this delivers
A previously stuck Defender for Identity rollout **moving again** — the blocker diagnosed, the targeted fix applied and verified on the affected sensor, and, if the root cause is a Microsoft service issue rather than your configuration, a **support-ready diagnostic bundle** and clear escalation criteria.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — assess with read-only discovery to pinpoint the blocker, apply the targeted fix, pilot the fix on the affected sensor/DC, validate the sensor is healthy and identity signal flows, then expand by resuming the stalled rollout to the remaining domain controllers.

## Boundary
This is a **diagnostic and troubleshooting** solution. It gets a *stalled* MDI deployment unstuck; it does **not** replace the full identity-onboarding engagement (see the adjacent *Defender XDR Deployment & Unified Onboarding* solution). All scripts are **read-only**. Identity response actions (disable user, force password reset, confirm compromised) stay **approval-gated** and are the SOC's call; incident-response and licensing determinations remain the customer's functions — this guide provides the technical diagnosis and the documented fix, not the decision.

## Effort
A competent administrator can run discovery, identify the blocker, apply the documented fix, and verify sensor health for a single blocker class in a focused session. Rolling the fix and sensors out to the remaining domain controllers scales with DC count and change windows.
