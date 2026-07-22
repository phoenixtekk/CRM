# 5. Testing & Validation — VPN Tunnel Health Monitoring & Alerting in Microsoft Intune (Scheduled Connectivity Health Checks, Telemetry & Alerts)

Validate against the **pilot ring** (`PILOT – VPN Health – Devices`) before expanding. Each test has an
explicit **PASS/FAIL** gate. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device / console / Azure steps for behavior. The package under test is
**`VPNHEALTH – Tunnel Health – Detect – Pilot`** built in Implementation.

> **Set up the positive and negative cases first.** Keep at least one pilot device fully **healthy**
> (VPN profile present, tunnel connected, cert well within validity) as the negative control. Then, on
> other pilot devices, **seed** each failure below so the monitor has something to catch. All seeding
> is on the *device/VPN* side; the health check itself changes nothing.

## Test 0 — The health check makes NO changes (read-only proof) — do this first
**Procedure:** On one pilot device, record the VPN state (profile present, connection status, adapter
state, certificate). Run **`VPNHEALTH-Detect-TunnelHealth.ps1`** locally (or let one scheduled cycle
run). Re-record the same state.
**PASS:** The VPN state is **identical** before and after — the tunnel was not restarted, reconnected,
renewed, or reconfigured; only the log file under `C:\ProgramData\VPNHealth\` was written. The monitor
is read-only.
**FAIL:** Any change to the tunnel/adapter/certificate state → stop; the script has been modified to do
more than observe. Restore the read-only script before proceeding.

## Test 1 — Package is present, assigned, reporting, and detection-only
**Procedure:** Run `VPNHEALTH-Discovery.ps1`, then `VPNHEALTH-Validate.ps1`.
**PASS:** `VPNHEALTH – Tunnel Health – Detect – Pilot` exists, is assigned to `PILOT – VPN Health –
Devices`, is returning run status (devices reporting), and has **no remediation script attached**
(read-only monitor).
**FAIL:** Missing / unassigned / no status → fix the assignment and schedule (Implementation §Step 4–5),
confirm the Intune Management Extension is healthy (Requirements §R6), then re-run. A remediation script
present → remove it; this monitor must be detection-only.

## Test 2 — A healthy device reports Healthy
**Procedure:** After a detection cycle, open the package → **Device status**, or read the healthy
device's detection output line.
**PASS:** The healthy control device reports **Without issue** (exit 0) and its output line reads
`verdict=Healthy` with every signal passing. Detection did **not** change the device.
**FAIL:** A genuinely healthy device reports **With issue** → a false red. Check the configuration block
(right `$VpnType`, `$ExpectedProfileName`, `$TestRouteTarget`, `$TestDnsName`, `$CertSubjectMatch`) and
the run context (Requirements §R7); the probe targets must be reachable from a healthy device.

## Test 3 — A broken tunnel reports the correct red signal
Seed **one** break per device and confirm the specific signal (not just "something's wrong"):
- **Adapter/profile down** — disconnect or remove the VPN profile → expect `verdict=Unhealthy` with
  `ProfilePresent=False` and/or `TunnelConnected=False`.
- **Route unreachable through the tunnel** — block/withdraw the internal `$TestRouteTarget` route while
  the tunnel is up → expect `verdict=Unhealthy` with `RouteThroughTunnel=False`.
- **DNS not through the tunnel** — make `$TestDnsName` fail to resolve → expect `DnsThroughTunnel=False`.
- **Gateway unreachable** — point at an unreachable gateway (or block it) → expect
  `GatewayReachable=False`.
- **Cert near expiry** — target a certificate inside the **30-day** warning window → expect
  `verdict=Degraded` with `CertValid=False` and `certDaysToExpiry` ≤ 30.
**PASS:** Each seeded device reports the **matching** red signal in its detection output, and the
verdict is `Unhealthy` (hard signals) or `Degraded` (cert warning). The healthy control stays Healthy.
**FAIL:** Wrong or missing signal → check that the seeded condition matches the configured probe target,
and the run context (Requirements §R7). No device was changed by the check.

## Test 4 — The fleet rollup shows the cohort
**Procedure:** Run `VPNHEALTH-Report.ps1` (Graph or `-Source Local`), and — if telemetry is wired —
run the `VPN Tunnel Health – Fleet Rollup` KQL in `LA – Endpoint – VPNHealth`.
**PASS:** The rollup groups devices **by VPN type and gateway** and shows the seeded failures as a
counted cohort (Unhealthy/Degraded/CertExpiringSoon counts reflect the seeded devices); the healthy
control counts as Healthy.
**FAIL:** The cohort is missing → confirm the report source has data (allow a cycle), and — for the KQL
— that the **table name matches the actual data path** (Implementation §Step 7, **verify-with-Microsoft**).

## Test 5 — An alert fires on a seeded failure
**Procedure:** With `ALERT – VPN Tunnel Health – Degraded` configured (Implementation §Step 8), keep a
seeded cohort failing across an evaluation cycle.
**PASS:** The alert rule fires and the action group delivers the notification (email/Teams/ITSM) for the
seeded cohort — for example, the cert-expiry or gateway-unreachable condition raises the alert.
**FAIL:** No alert → confirm the alert query returns the seeded cohort, the threshold/grouping is set so
a cohort (not a single transient device) triggers, and the action group is attached. The exact
alert-rule wiring is **verify-with-Microsoft** for your cloud.

## Test 6 — Steady state (no thrash, still read-only)
**Procedure:** Over several cycles, watch the healthy control and a device you have since **repaired**
(using the appropriate deployment/troubleshooting product — not this monitor).
**PASS:** The healthy device stays **Healthy** every cycle; the repaired device flips from red to
**Healthy** on the next cycle after *you* fixed it — evidence the monitor tracks reality without acting.
Across all cycles, no device's tunnel state was changed by the check.
**FAIL:** A device flaps Healthy/Unhealthy with no underlying change → tighten a probe target that is
intermittently reachable (e.g. a flaky test route) so the signal reflects real health, not probe noise.

## Acceptance gate
Proceed to **Expand** (production waves) only when **Tests 0–6 pass**: the check is proven **read-only**,
the package is assigned and reporting **detection-only**, a **healthy device reports Healthy**, each
**seeded break reports the correct red signal**, the **fleet rollup shows the cohort**, an **alert fires
on a seeded failure**, and steady state shows **no thrash** with **no tunnel changes**. Anything less
stays in the pilot ring until it passes.
