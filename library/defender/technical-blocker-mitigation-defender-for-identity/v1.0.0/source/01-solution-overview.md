# 1. Solution Overview — Technical Blocker Mitigation: Defender for Identity

## What this solution is
This is a **diagnostic and troubleshooting playbook** for a **stalled Microsoft Defender for Identity (MDI) rollout**. It assumes you have started deploying sensors and hit a wall — a sensor that will not go healthy, or one that is "healthy" but detects nothing. Its job is to answer three questions quickly and in order:

1. **Which blocker do I actually have?** (read-only discovery of sensor, DSA, traffic, and event state — not guesswork)
2. **What is the exact, documented fix?** (a targeted manual step, applied deliberately)
3. **Is the sensor healthy and is identity signal flowing?** (verification before you resume)

It targets the four blocker classes that stall almost every MDI deployment:

- **Sensor install / health failures** — the sensor will not install, or shows **Unhealthy / Not configured / disconnected** in the portal (service not running, outbound reach to the MDI service blocked, unsupported OS, or an out-of-date sensor).
- **DSA permission issues** — the **Directory Service Account** (gMSA recommended) is missing or under-permissioned, so the sensor cannot query AD for the context several detections need.
- **Missing network traffic** — the sensor is not seeing the domain controller's traffic, so **Network Name Resolution (NNR)** and network-based detections are blind (NNR ports blocked, or the wrong adapter).
- **Event-collection gaps** — the required **Windows Security audit events** (e.g. the account-logon / directory-service audit categories) are not being generated or forwarded, so event-based detections are silent.

## How Defender for Identity signal actually works (so you can find the break)
MDI has a signal chain, and a blocker is always a break in one specific link:

1. **Licensing/activation** — the tenant has an MDI plan and the MDI workspace is activated in `security.microsoft.com` → **Settings → Identities**. *Verify current plan requirements in your tenant.*
2. **Sensor installed & healthy** — the sensor is installed on the domain controller (and AD FS / AD CS where present), the service runs, and it has **outbound reach** to the MDI service so it reports **Running / Healthy**.
3. **DSA configured** — a read-only **Directory Service Account** is registered so the sensor can enrich detections with AD queries.
4. **Network traffic seen** — the sensor captures the DC's network traffic and performs **NNR** (needs the relevant ports open to endpoints) to resolve IPs to devices.
5. **Events collected** — the required **advanced audit policy** is enabled so the sensor receives the Windows Security events its detections depend on.
6. **Verification** — sensor health shows **Healthy** in the portal, and advanced-hunting tables (`IdentityInfo`, `IdentityLogonEvents`, `IdentityDirectoryEvents`, `IdentityQueryEvents`) stream.

Find the earliest broken link and you have found the blocker. Discovery reports the state of each link so you are not guessing.

## The standard deployment model (applied to a blocker)
> **Assess → Configure → Pilot → Validate → Expand.**
> **Assess** — run read-only discovery and the audit-policy readiness check to pinpoint the earliest broken link. **Configure** — apply the single documented fix for that blocker (a manual step in a change window, not a script action). **Pilot** — re-test on the **affected sensor/DC** only. **Validate** — confirm the sensor is healthy and identity signal flows. **Expand** — resume the stalled rollout to the remaining domain controllers.

## Scope
- Diagnosing and clearing the four blocker classes above for a stalled MDI rollout.
- Read-only discovery, audit-policy / NNR readiness checking, validation, status reporting, and a support-ready bundle.
- Documented manual fixes for each blocker, applied affected-sensor-first, in a change window.
- Clear escalation criteria and the exact data to collect when the root cause is a Microsoft service issue.

## Out of scope
- **First-time identity onboarding of a greenfield tenant** — that is part of the *Defender XDR Deployment & Unified Onboarding* solution; this one unblocks a rollout already in progress.
- **Identity response and incident handling** — disable user, force password reset, and confirm-compromised actions stay **approval-gated** and are the SOC's decision.
- **Broader identity hardening** (Conditional Access, PIM, passwordless) — see the adjacent Entra solutions.
- **Licensing determinations** — the guide tells you *which* plan the feature needs and how to verify it; assigning it is the customer's licensing function.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com`) — **Settings → Identities → Sensors / Directory Service accounts**, sensor health.
- **Microsoft Graph advanced-hunting API** (via `Microsoft.Graph`) for read-only `Identity*` table validation.
- **A local, read-only check on the domain controller** — `auditpol` and configuration reads to confirm the advanced audit policy and NNR readiness the sensor needs (no changes made).
- Least-privilege roles: **Security Reader** for the cloud diagnostics; local **read** access on the DC for the audit-policy check; **Security Administrator** (and a change window on the DC) only to apply a fix.
