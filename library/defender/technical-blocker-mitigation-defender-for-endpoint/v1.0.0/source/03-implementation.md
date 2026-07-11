# 3. Implementation Guide — Technical Blocker Mitigation: Defender for Endpoint

Follow these steps **in order**. This is a **diagnostic loop**, not a build: you assess to pinpoint the blocker, apply one targeted documented fix, re-test the affected subset, and only then resume the rollout. All scripts are **read-only**; every *fix* is a manual step you apply deliberately. Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Assess (pinpoint) → Configure (fix) → Pilot (re-test affected subset) → Validate (confirm cleared) → Expand (resume rollout). Never disable an existing control to "test," and keep response actions approval-gated throughout.

## Naming (set once, reuse verbatim)
- Affected device subset (Entra/Intune): `MDE Blocker Triage – Affected Ring – Diagnose`
- Advanced-hunting saved query (onboarding/telemetry check): `MDE Onboarding Blocker Check – Tenant – Diagnose`
- Support bundle output: `MDE Support Bundle – <case> – Escalate`
- Discovery snapshot file: `MDE-blocker-discovery.json`

## Step 1 — Assess: pinpoint the blocker (read-only)
1. Sign in to `security.microsoft.com` as **Security Reader**.
2. Run `TBMMDE-Discovery.ps1`. It captures the full signal chain in one snapshot (`MDE-blocker-discovery.json`): licensed Defender plans, the account's roles, the **Intune ↔ MDE connector** state, any EDR onboarding policy and its assignment, device onboarding coverage, and a per-state device count (Onboarded / Can be onboarded / Inactive / Impaired).
3. In **Entra/Intune**, create the group `MDE Blocker Triage – Affected Ring – Diagnose` and add the devices showing the symptom.
4. Read the snapshot top-down against the signal chain (Overview §"How onboarding actually works") and identify the **earliest broken link**. That link is your blocker class:
   - No plan / not activated → **licensing/activation blocker**
   - Connector disabled/expired, or policy unassigned → **connector / onboarding blocker**
   - Devices "Can be onboarded" → **onboarding blocker**
   - Devices Onboarded but Inactive/Impaired → **sensor-health / connectivity blocker**
   - Healthy but no hunting rows → **telemetry blocker**

## Step 2 — Assess: test connectivity where the chain looks broken (read-only)
1. If the blocker looks like sensor-health/connectivity (or you are not yet sure), run `TBMMDE-Connectivity.ps1` on or against a **sample device from** `MDE Blocker Triage – Affected Ring – Diagnose`.
2. It tests outbound HTTPS to the documented Defender service endpoints and reports each as reachable/blocked. *Verify the current endpoint URL/IP list in your tenant.*
3. Record the result — a blocked endpoint confirms a proxy/firewall blocker and points the fix at networking, not at MDE.

## Step 3 — Configure: apply the one targeted fix (manual, documented)
Apply **only** the fix for the blocker you identified. Each is a deliberate manual step — the scripts never make these changes.

- **Licensing / activation:** Assign the Defender for Endpoint plan (Admin center → **Billing → Licenses**), then complete first-service activation in `security.microsoft.com` → **Settings → Endpoints → Onboarding**. *Verify the exact plan the feature needs in your tenant.*
- **Connector / onboarding (Intune channel):** `intune.microsoft.com` → **Endpoint security → Microsoft Defender for Endpoint** → set **Connection status: Enabled** (re-establish the connection if it shows disabled/expired). Then confirm the EDR policy exists, uses **client configuration package type = Auto from connector**, and is **assigned** to `MDE Blocker Triage – Affected Ring – Diagnose`. Force an Intune sync on a sample device.
- **Onboarding (GPO/script channel):** Re-apply the current onboarding package from **Settings → Endpoints → Onboarding** to the affected OU/device; confirm the onboarding scheduled task/service ran.
- **Sensor-health / connectivity:** Fix the blocked endpoints found in Step 2 at the proxy/firewall (allow the documented Defender endpoints per `global-requirements-defender.md` G5). If connectivity is fine, run the Microsoft Defender **client analyzer** on the device to confirm agent health and reconnect.
- **Telemetry:** If onboarded and healthy but no hunting rows, allow warm-up time (tables populate over hours), confirm the device is not excluded by a device group scope, and confirm advanced hunting is enabled for the tenant.

## Step 4 — Pilot: re-test the fix on the affected subset only
1. Apply the fix to (or force a sync on) the devices in `MDE Blocker Triage – Affected Ring – Diagnose` only — not the whole fleet.
2. Give the change time to take effect (Intune sync / sensor check-in can take minutes to hours).
3. Move to validation before touching any other device.

## Step 5 — Validate: confirm the blocker is cleared
1. Run `TBMMDE-Validate.ps1`. It re-checks the same signal chain for the affected subset and returns a **pass/fail** per link (onboarded state, sensor health, recent telemetry).
2. Run `TBMMDE-Report.ps1` to produce a before/after status report from the Step 1 snapshot versus now — this is your evidence the blocker cleared.
3. Complete the **Testing Guide** for the specific blocker class before expanding.

## Step 6 — Expand: resume the stalled rollout
1. With the affected subset green, resume the rollout to the remaining devices in waves (broaden the Intune assignment / re-apply the package to the next ring).
2. Re-run `TBMMDE-Validate.ps1` after each wave and compare with `TBMMDE-Report.ps1`.
3. If a wave re-introduces the symptom, return to Step 1 for that subset — the blocker class may differ by network segment or OS.

## Step 7 — Escalate (only if it is a service issue, not your config)
1. If discovery, connectivity, and the fix all check out but the blocker persists, it may be a Microsoft service issue.
2. Run `TBMMDE-SupportBundle.ps1` to assemble `MDE Support Bundle – <case> – Escalate` — the read-only diagnostic snapshot, connectivity results, affected device IDs, and timestamps — plus run the on-device **client analyzer** for the local bundle.
3. Open a Microsoft support case, attach the bundle, and reference the escalation criteria in the Troubleshooting Guide. *Incident-response decisions remain the SOC's; this is a service-support escalation.*

---
### Order of operations
`Assess (discovery + connectivity) → identify earliest broken link → apply the one targeted fix → re-test the affected subset → validate cleared → resume rollout → escalate with a bundle only if it is a service issue`
