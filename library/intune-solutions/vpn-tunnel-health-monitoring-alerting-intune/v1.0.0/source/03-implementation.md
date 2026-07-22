# 3. Implementation — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

Follow these steps **in order**. The *why* lives in the Solution Overview; the steps below are short
and exact so you can **click to implement**. The design is: **define the health signals and thresholds
→ author the read-only, VPN-type-aware detection health check → package it as a named Proactive
Remediations detection (no remediation) → scope to a pilot ring → wire telemetry (Log Analytics/KQL) →
build the fleet health dashboard → configure alert rules → validate against seeded failures → expand
to the fleet in waves.** Pilot first: **Assess → Configure → Pilot → Validate → Expand.**

Consoles used:
- **Microsoft Intune admin center** — `https://intune.microsoft.com`
- **Microsoft Entra admin center** — `https://entra.microsoft.com`
- **Microsoft Azure portal** — `https://portal.azure.com` (Log Analytics + Azure Monitor)

> **Read-only, by contract.** Every device-side probe in this solution is **read-only**. Nothing in
> this implementation restarts, reconnects, renews, or re-pushes a VPN. There is **no remediation
> script** — this is a monitoring package. Fixes are deferred to the deployment/troubleshooting
> products named in the Triage runbook (Troubleshooting).

> **Navigation & data-path flag.** The exact **Remediations** location in Intune, the **Log Analytics**
> data path for Proactive Remediations output, and the **Azure Monitor** alert-rule experience change
> over time and differ by cloud (Commercial vs. GCC / GCC High / DoD). This guide uses the common paths
> and **flags every place you must verify against current Microsoft documentation** before relying on
> it.

---

## Phase 1 — Define healthy and author the read-only health check

### Step 1. Define the health signals and thresholds (configure the script header)
1. Open the included **`VPNHEALTH-Detect-TunnelHealth.ps1`** — the read-only, VPN-type-aware device
   health check. You will deploy this file **as-is** as the detection script; you only edit the
   **configuration block at the top**.
2. Set these values for your environment (each maps to a health signal in the Overview):
   - **`$VpnType`** — `MicrosoftTunnel`, `AlwaysOnDevice`, `AlwaysOnUser`, or `ThirdParty` (the script
     adapts what it probes per type). For a third-party client, also set the vendor **adapter/service
     name** — **verify the exact name against the vendor's documentation.**
   - **`$ExpectedProfileName`** — the VPN profile/connection name to look for (adapter/profile-present
     signal).
   - **`$TestRouteTarget`** — an **internal** host/IP that should be reachable **through the tunnel**
     (key-route signal), e.g. `10.20.0.10`.
   - **`$TestDnsName`** — an **internal** DNS name that should resolve through the tunnel (DNS signal),
     e.g. `intranet.contoso.com`.
   - **`$CertSubjectMatch`** / **`$CertIssuerMatch`** — a substring identifying the VPN **auth
     certificate** (cert signal).
   - **`$CertWarningDays`** — the cert-expiry **warning window** (default **`30`**). Inside this window
     → **Degraded (warn)**; expired/missing → **Unhealthy (fail)**.
3. Save the file. **Do not** add any code that changes the device — the check is read-only by contract.

### Step 2. Confirm the verdict + exit-code contract
1. The health check emits a single structured **health line** (surfaced in the console's detection
   output) and communicates overall health through the **exit-code contract**:
   - **`exit 0`** = **Healthy** — all signals pass (cert may be Healthy).
   - **`exit 1`** = **Degraded or Unhealthy** — one or more signals warn/fail (including cert inside the
     warning window). In the Proactive Remediations console this shows the device as **With issue**.
2. Because this is a **detection-only** package, "With issue" means **"this device's tunnel is not
   fully healthy — investigate"**, *not* "a remediation will run". There is no paired remediation.

---

## Phase 2 — Package and scope to a pilot ring

### Step 3. Create the pilot and production groups
1. Entra → **Groups → New group → Security**; **name it `PILOT – VPN Health – Devices`** and add a small
   set of representative devices that already have a VPN profile (Requirements §R2, §R8).
2. Entra → **Groups → New group → Security**; **name it `VPN Health – Windows – Production`** (it may
   start empty; you fill it in waves during Expand — §R9).

### Step 4. Package the health check as a Proactive Remediations detection — name it
1. In Intune, go to **Reports → Endpoint analytics → Remediations → Create script package** (*verify
   the current path per the navigation flag above; some tenants surface it under **Devices →
   Remediations***).
2. **Basics:** **name it `VPNHEALTH – Tunnel Health – Detect – Pilot`**; add a clear description and the
   **publisher** (your team name — white-label; do not brand it).
3. **Settings:**
   - **Detection script file:** upload **`VPNHEALTH-Detect-TunnelHealth.ps1`** (Step 1).
   - **Remediation script file:** **leave empty.** This is a **detection-only** monitor — do **not**
     attach a remediation. (If your tenant requires a remediation file, attach a no-op that only writes
     a log line and `exit 0` — it must make **no** change. Fixes belong to the deployment/troubleshooting
     products, not to this monitor.)
   - **Run this script using the logged-on credentials:** **No** (system context) for Microsoft Tunnel,
     Always On **device** tunnel, and most third-party checks; set **Yes** only when monitoring a
     user-context VPN such as an Always On **user** tunnel or a user-store certificate (Requirements §R7).
   - **Enforce script signature check** and **Run script in 64-bit PowerShell:** set per your signing
     posture and the target's needs. **Verify current option names/behavior against Microsoft's
     documentation.**
4. **Review + create.**

### Step 5. Assign to the pilot ring and schedule
1. Open **`VPNHEALTH – Tunnel Health – Detect – Pilot`** → **Assignments → Select groups to include** →
   choose **`PILOT – VPN Health – Devices`**.
2. Set the **schedule** for the assignment. Start with **Daily** so you get a clean daily health signal.
   (Available cadences — Once / Hourly / Daily — and their exact behavior should be **verified against
   current Microsoft documentation**.)
3. **Save.** The read-only health check now runs on the pilot devices on that schedule and reports each
   device's verdict back to the console. **No device is changed** — this is monitoring.

---

## Phase 3 — Read results, wire telemetry, and build the dashboard

### Step 6. Read per-device health in the console
1. Open **`VPNHEALTH – Tunnel Health – Detect – Pilot`** → the **Overview / Device status** view.
2. Read the columns Endpoint Analytics reports (names may vary — **verify current column labels**):
   - **Detection status** — **Without issue** = Healthy; **With issue** = Degraded/Unhealthy.
   - **Detection output** — the structured health line your script wrote (which signals passed/failed,
     and cert days-to-expiry).
3. Confirm the pilot splits into Healthy vs. not as expected. Run the included
   **`VPNHEALTH-Discovery.ps1`** and **`VPNHEALTH-Validate.ps1`** for a tenant-side view (the package
   exists, is assigned, is running, and is reporting; telemetry path present).

### Step 7. Wire telemetry into Log Analytics (optional but recommended) — **verify the data path**
1. In the Azure portal, confirm the workspace **`LA – Endpoint – VPNHealth`** exists (Requirements §R3).
2. Route the health results into the workspace. **The exact data path for Proactive Remediations output
   into Log Analytics — whether it is natively queryable, and via which table/connector — must be
   verified against current Microsoft documentation for your tenant and cloud.** Use whichever of these
   Microsoft currently supports for your environment:
   - **Intune → Log Analytics data path** (Intune reporting / data collection into a workspace), if
     Proactive Remediations results are included; **verify** the table name your data lands in.
   - A **device data-collection path** that ingests the structured health line the check emits, if a
     native path is unavailable.
   Do **not** assume a specific table name — confirm it, then use that name in the KQL (Step 9).
3. Save a **named saved query** in the workspace — **`VPN Tunnel Health – Fleet Rollup`** — using the
   KQL below (Step 9) once you have confirmed the correct source table.

### Step 8. Configure the alert rule (optional but recommended) — **verify the alert wiring**
1. Azure portal → **Monitor → Alerts → Create → Alert rule**; **scope** it to the workspace
   `LA – Endpoint – VPNHealth`.
2. **Condition:** a **log search (scheduled query) alert** whose query returns the degraded cohort (for
   example: devices reporting Unhealthy, or certs inside the warning window, grouped so a *cohort*
   threshold — not a single device — triggers). Set the threshold and evaluation cadence.
3. **Details:** **name the rule `ALERT – VPN Tunnel Health – Degraded`**; attach an **action group**
   (email/Teams/ITSM) for the notification.
4. **Create.** The alert now fires when the tunnel health telemetry crosses your threshold — cert
   nearing expiry, a cohort failing to establish, or a gateway unreachable.
   > **Flag:** the alert-rule type, evaluation cadence, threshold/grouping options, and action-group
   > wiring **change over time and must be verified against current Microsoft documentation** for your
   > cloud before you rely on them.

### Step 9. Build the fleet health rollup (KQL)
Use this KQL as the `VPN Tunnel Health – Fleet Rollup` saved query and as the alert condition base.
**Replace `VpnTunnelHealth_CL` with the actual table your data lands in (Step 7) — verify it; do not
assume this name.** The same query ships as a comment in **`VPNHEALTH-Report.ps1`**.

```kql
// VPN Tunnel Health – Fleet Rollup (by VPN type and gateway)
// NOTE: table name is a placeholder — set it to the table your health data lands in (verify per Step 7).
VpnTunnelHealth_CL
| summarize arg_max(TimeGenerated, *) by DeviceName_s        // latest verdict per device
| summarize
    Devices        = count(),
    Healthy        = countif(Verdict_s == "Healthy"),
    Degraded       = countif(Verdict_s == "Degraded"),
    Unhealthy      = countif(Verdict_s == "Unhealthy"),
    CertExpiringSoon = countif(CertDaysToExpiry_d <= 30 and CertDaysToExpiry_d >= 0)
    by VpnType_s, Gateway_s
| extend UnhealthyPct = round(100.0 * Unhealthy / Devices, 1)
| sort by Unhealthy desc, Degraded desc
```

Pin the result to an **Azure dashboard** (or an Intune/Workbook view) so the fleet health rollup by VPN
type and gateway is visible at a glance.

---

## Phase 4 — Validate, then expand to the fleet

### Step 10. Validate against seeded failures
Run the Testing guide against the pilot ring before widening: a healthy device reports **Healthy**; a
device with a broken tunnel (adapter down / route unreachable / cert near expiry) reports the correct
red signal; the **fleet rollup** shows the cohort; an **alert fires** on a seeded failure; and the
checks made **no change** to any tunnel. Do not expand until the acceptance gate passes.

### Step 11. Expand to production in waves
1. Only after the pilot passes, create the production assignment. Recommended: **clone** the pilot
   package to a production copy **named `VPNHEALTH – Tunnel Health – Detect – Production`** (or re-assign
   the same package to the production group — keep pilot and production distinguishable).
2. Assign **`VPNHEALTH – Tunnel Health – Detect – Production`** to **`VPN Health – Windows – Production`**,
   and fill that group in **waves** (a first wave, validate, then widen) rather than the whole fleet at
   once.
3. Keep the schedule conservative (Daily), watch the fleet rollup and the alert, and widen only as each
   wave stays clean. Because the check is read-only, expansion carries no risk to the tunnels — but
   waves keep the telemetry/alert signal clean and interpretable.
