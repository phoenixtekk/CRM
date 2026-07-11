# 1. Solution Overview — Technical Blocker Mitigation: Defender for Endpoint

## What this solution is
This is a **diagnostic and troubleshooting playbook** for a **stalled Microsoft Defender for Endpoint (MDE) rollout**. It does not re-teach onboarding from scratch — it assumes you have started and hit a wall. Its job is to answer three questions quickly and in order:

1. **Which blocker do I actually have?** (read-only discovery, not guesswork)
2. **What is the exact, documented fix?** (a targeted manual step, applied deliberately)
3. **Is the blocker cleared?** (verification that proves the fix worked before you resume)

It targets the four blocker classes that stall almost every MDE deployment:

- **Devices not onboarding** — a device stays *"Can be onboarded"* in the portal and never becomes managed.
- **Sensor health failures** — an onboarded device reports **Inactive**, **Impaired communication**, or **No sensor data**.
- **Missing telemetry** — the device is onboarded and healthy, but EDR/antivirus events do not appear in advanced hunting or Secure Score.
- **MDE ↔ Intune connector issues** — the connector shows a disabled/expired state, so the auto-generated onboarding package never reaches devices.

## How Defender for Endpoint onboarding actually works (so you can find the break)
MDE has a signal chain, and a blocker is always a break in one specific link:

1. **Licensing/activation** — the tenant has a Defender for Endpoint plan (P1/P2) and the service is activated in `security.microsoft.com`. *Verify current plan requirements in your tenant.*
2. **Onboarding channel** — Intune (default), Configuration Manager, Group Policy, or the local onboarding script pushes the onboarding configuration to the device. With Intune, the **Microsoft Defender for Endpoint connector** must be **Enabled** so the onboarding blob is generated and consumed automatically.
3. **The sensor onboards** — the device applies the onboarding configuration and registers with the service; it appears under **Assets → Devices** as **Onboarded**.
4. **The sensor reports** — the onboarded device needs **outbound HTTPS reachability** to the Defender service endpoints; if a proxy/firewall blocks them, the sensor onboards but then goes **Inactive / Impaired communication**.
5. **Telemetry lands** — healthy sensors stream to the advanced-hunting tables (`DeviceInfo`, `DeviceEvents`, `DeviceNetworkEvents`, etc.) and to Secure Score.

Find the earliest broken link and you have found the blocker. The discovery script reports the state of each link so you are not guessing.

## The standard deployment model (applied to a blocker)
> **Assess → Configure → Pilot → Validate → Expand.**
> **Assess** — run read-only discovery and connectivity checks to pinpoint the earliest broken link. **Configure** — apply the single documented fix for that blocker (a manual step, not a script action). **Pilot** — re-test the fix on the **affected device subset** only. **Validate** — confirm telemetry/health is restored and the blocker is cleared. **Expand** — resume the stalled rollout across the remaining devices.

## Scope
- Diagnosing and clearing the four blocker classes above for a stalled MDE rollout.
- Read-only discovery, connectivity testing, validation, status reporting, and a support-ready bundle.
- Documented manual fixes for each blocker, applied affected-subset-first.
- Clear escalation criteria and the exact data to collect when the root cause is a Microsoft service issue.

## Out of scope
- **First-time onboarding of a greenfield tenant** — that is the *Defender XDR Deployment & Unified Onboarding* solution; this one unblocks a rollout already in progress.
- **Posture/optimization work** (Secure Score improvement, ASR tuning, hardening) — see the adjacent CSPM / Secure Score and endpoint-security optimization solutions.
- **Response and incident handling** — device isolation, investigation packages, and automated response stay **approval-gated** and are the SOC's decision.
- **Licensing determinations** — the guide tells you *which* plan a feature needs and how to verify it; buying/assigning it is the customer's licensing function.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com`) — Assets, Settings → Endpoints, device health.
- **Microsoft Graph Security** and the **Microsoft 365 Defender advanced-hunting API** (via `Microsoft.Graph` PowerShell modules) for read-only discovery, validation, reporting, and KQL hunting.
- **Intune / Microsoft Endpoint Manager** (`intune.microsoft.com`) — the Defender for Endpoint connector and EDR onboarding policy state.
- Least-privilege roles: **Security Reader** for all read-only diagnostics; **Security Administrator** only to apply a configuration fix; **Global Administrator** only for one-time first-service activation.
