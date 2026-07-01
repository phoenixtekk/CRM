# Endpoint Health & Digital Experience Monitoring

> **Version 1.0.0** · Category: Infrastructure · Solution code: EHEM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Endpoint Health & Digital Experience Monitoring (Microsoft Intune)

Most endpoint problems are invisible until a user complains: slow boots, app crashes, failing
disks, battery wear, devices that never restart. By then the productivity is already lost. This
package stands up **endpoint health and digital experience monitoring** using
`Microsoft Intune Endpoint analytics` — startup performance, application reliability,
work-from-anywhere, and resource performance scores — with `proactive remediations` that fix common
degradations automatically, so you find and resolve issues before the help-desk call.

This is a complete, deploy-it-today package, written for an administrator with no prior
experience-monitoring background. It centers on the built-in Intune capability and treats a
dedicated digital-experience (DEX) platform such as Nexthink or Tanium as an **optional** integration
path — useful where deeper telemetry is required, with vendor-specific setup deferred to that
vendor's own documentation.

## What you get
- A plain-language **Solution Overview** of Endpoint analytics (startup, app reliability,
  work-from-anywhere, resource performance), the Endpoint analytics score, and proactive remediations.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, including the
  baseline period and optional DEX licensing.
- An **Implementation Guide** of precise, click-by-click steps in the Intune admin center, in the
  required order.
- Five **PowerShell scripts** for monitoring-readiness discovery, device data-collection validation,
  a fleet health-score and issues report, safe remediation of common degradations, and a
  monitoring-scope group builder.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A working **endpoint health and digital experience monitoring** layer — Endpoint analytics enabled,
devices onboarded and reporting, a baseline established, scores interpreted, and proactive
remediations wired for the most common issues — proven on a pilot before it scales, with an optional
path to a dedicated DEX platform when you need it.

## The repeatable deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
Proactive visibility into how every endpoint really performs — startup, reliability, and resource
health scored and trending, common issues remediated quietly — deployable by a single administrator
and validated on a pilot before fleet rollout.


---


# 1. Solution Overview — Endpoint Health & Digital Experience Monitoring

## What endpoint health and digital experience monitoring is
Digital experience monitoring (DEX) measures how technology actually *feels* to the people using it
— not just whether a server is up, but whether a laptop boots quickly, apps stay responsive, and
hardware is healthy. `Microsoft Intune Endpoint analytics` is the built-in DEX capability in Intune:
it collects telemetry from enrolled Windows devices and turns it into scores and recommendations for
startup performance, application reliability, work-from-anywhere readiness, and resource performance.
This solution stands that capability up end to end, and treats a dedicated DEX platform (such as
Nexthink or Tanium) as an optional path for organizations needing deeper telemetry.

## Why it matters
Reactive support is expensive and invisible until users complain. By the time a slow-booting laptop
or a crash-prone app generates a ticket, productivity is already lost. Endpoint analytics flips this:
degradations surface as falling scores and named recommendations *before* the call, so you fix the
trend instead of the symptom.

## How it works
1. You enable `Endpoint analytics` in the Intune admin center and choose the data sources (Intune
   enrolled devices, and optionally Configuration Manager devices).
2. Enrolled Windows devices send device-performance telemetry; Intune aggregates it into an
   **Endpoint analytics score** (0–100) with sub-scores.
3. `Startup performance` scores boot and sign-in time and breaks it down (core boot, group policy,
   sign-in) so you can see what is slow.
4. `Application reliability` scores app crashes and hangs per app and per device, surfacing the
   least reliable apps in your fleet.
5. `Work from anywhere` reports modern-management readiness (cloud identity, cloud management,
   Windows, and Autopilot eligibility).
6. `Resource performance` scores CPU and RAM (spike time) so you can spot under-resourced devices.
7. `Proactive remediations` run script packages (detection + remediation) on a schedule to fix
   common issues automatically and report on what they found.
8. A **baseline** lets you compare your scores against your own history or a tenant/industry median,
   so you measure improvement over time.

## What you can see and control
- The overall **Endpoint analytics score** and its startup, reliability, work-from-anywhere, and
  resource sub-scores, trended over time.
- Per-device and per-model breakdowns so you can target the worst offenders.
- The list of **model scores** to see whether a specific hardware model drags the fleet down.
- **Recommended software** and configuration changes Intune surfaces to raise the score.
- **Proactive remediation** packages (detect + fix) scoped to groups, with run history and output.
- A **baseline** you set once so every later report is measured against it.

## Where a dedicated DEX platform fits (optional)
Endpoint analytics covers the most valuable signals for most organizations at no extra cost. A
dedicated DEX platform (Nexthink, Tanium, or similar) adds deeper real-time telemetry, richer
sentiment/experience scoring, and broader OS coverage where that is required. This solution treats
such a platform as an **optional integration path**: decide whether you need it, license it, then
follow the **vendor's own documentation** to deploy its collector and dashboards. We do not
reproduce vendor-specific setup here — the repeatable core is Endpoint analytics.

## Limitations (be honest with buyers)
- Endpoint analytics primarily covers **Windows** enrolled (and Configuration Manager-attached)
  devices; macOS/mobile experience monitoring needs a dedicated DEX platform.
- Scores require a **data-collection period** — a fresh tenant shows limited data until devices have
  reported for several days (the baseline period).
- It measures **performance and reliability signals**, not deep root-cause forensics; complex issues
  may still need device logs.
- Some sub-scores depend on **diagnostic data** being enabled and devices checking in regularly.
- A dedicated DEX platform is a **separate licensed product** — its setup, cost, and capabilities are
  the vendor's, not part of this solution.

## Object naming convention (used throughout)
Every object you create is named `<Purpose> – <Scope> – <Stage>` so it is self-documenting and
repeatable. Examples reused verbatim later: `Endpoint Analytics – Pilot Devices – Monitoring`,
`Endpoint Analytics – All Windows – Monitoring`, `Proactive Remediation – Restart Stale Devices – Pilot`.

## The repeatable deployment model
> Enable Endpoint analytics → onboard devices and set a baseline → interpret scores → wire proactive
> remediations → pilot → validate → expand. The repeatable way: **Assess → Configure → Pilot →
> Validate → Expand.**


---


# 2. Requirements Guide — Endpoint Health & Digital Experience Monitoring

Verify **every** requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-infrastructure.md`.

## 2.1 Licensing
Description: Microsoft Intune (Plan 1). Endpoint analytics is included at no extra cost.
Why: Endpoint analytics is delivered by Intune; proactive remediations require Intune (and, for
device-scoped remediations, an eligible Windows Enterprise/Education entitlement).
Verify: M365 admin center → **Billing → Licenses**; Intune is assigned.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## 2.2 Device enrollment
Description: Targeted Windows devices enrolled in Intune (or Configuration Manager-attached).
Why: Endpoint analytics only scores devices it manages and that report telemetry.
Verify: Intune → **Devices → All devices**; targeted devices appear. Run `EHEM-Discovery.ps1`.
Implement: Enable automatic enrollment; Entra-join and enroll the devices.

## 2.3 Supported Windows OS
Description: Windows 10 (Pro/Enterprise/Education) or Windows 11, current build.
Why: Endpoint analytics data collection and proactive remediations require a supported build.
Verify: `winver`; run `EHEM-Discovery.ps1`.
Implement: Patch/upgrade to a supported build (deploy update rings or upgrade to Windows 11).

## 2.4 Endpoint analytics enabled
Description: Endpoint analytics is turned on for the tenant with a data source selected.
Why: No scores or reports exist until the capability is enabled and devices are onboarded.
Verify: `https://intune.microsoft.com` → **Reports → Endpoint analytics**; the dashboard loads with
a score (not the "get started" prompt).
Implement: Enable it in Implementation Step 1 (Reports → Endpoint analytics → Start).

## 2.5 Device data collection / diagnostic data
Description: Devices send the device-performance telemetry Endpoint analytics uses, with required
diagnostic data permitted by policy.
Why: Startup, reliability, and resource sub-scores depend on this telemetry; remediation output
reporting benefits from it too.
Verify: Intune → **Reports → Endpoint analytics → Settings**; devices show as **enrolled** for
analytics. Run `EHEM-Validation.ps1` on a device.
Implement: Confirm the Endpoint analytics data collection policy is assigned; ensure no policy forces
diagnostic data below the required level.

## 2.6 Network access for Endpoint analytics telemetry
Description: Outbound HTTPS from devices to the Intune/Endpoint analytics and Microsoft telemetry
endpoints.
Why: Devices must reach the service to upload performance data.
Verify: From a device, reach `https://login.microsoftonline.com` and the Microsoft telemetry/Intune
endpoints (see Microsoft's published URL list).
Implement: Allow the Microsoft 365 / Intune / connected-experiences URL and IP ranges through the
proxy/firewall.

## 2.7 Baseline period (data warm-up)
Description: A short period (typically several days) after onboarding before scores are meaningful.
Why: Scores are computed from collected telemetry; a fresh tenant has too little data to trust.
Verify: Endpoint analytics → **Startup performance** shows device counts climbing day over day.
Implement: Onboard the pilot, then wait the baseline period before judging scores (the pilot gate).

## 2.8 (Optional) Dedicated DEX platform licensing
Description: Licensing and tenant for a dedicated DEX platform (e.g. Nexthink, Tanium) — only if you
need deeper telemetry than Endpoint analytics provides.
Why: A dedicated platform is a separate product with its own collector, console, and cost.
Verify: Confirm the platform subscription and admin access exist.
Implement: Acquire the licensing, then follow the **vendor's own documentation** to deploy its
collector and dashboards. Vendor-specific steps are intentionally out of scope here.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled (or Configuration Manager-attached) — `EHEM-Discovery.ps1`
- [ ] Windows 10/11 supported build — `EHEM-Discovery.ps1`
- [ ] Endpoint analytics enabled with a data source
- [ ] Device data collection / diagnostic data permitted — `EHEM-Validation.ps1`
- [ ] Network allows Endpoint analytics telemetry
- [ ] Baseline period planned (data warm-up = pilot gate)
- [ ] Pilot Entra group created (`Endpoint Analytics – Pilot Devices – Monitoring`)
- [ ] (Optional) Dedicated DEX platform licensed — vendor docs for setup


---


# Global Requirements — Infrastructure Solutions (category-level)

These requirements apply to **every** solution in the **Infrastructure** category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying *any* Infrastructure solution. Each entry: Description · Why · Verify · Implement-if-missing.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID (Azure AD) tenant.
Why: It is the identity backbone for Microsoft 365, Entra ID, and Intune-managed infrastructure — including device sign-in, group targeting, and shared cloud resources.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft 365 / Intune subscription
Description: A Microsoft 365 plan that includes Microsoft Intune and the cloud service the solution relies on.
Why: Intune delivers configuration, deployment, and policy targeting; the bundled Microsoft 365 services back the cloud capability being deployed.
Verify: `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
Description: Appropriate Entra / Intune admin roles for the operator.
Why: Creating cloud service settings, policies, and deployments requires elevated rights.
Verify: Entra → **Roles and administrators**; confirm **Intune Administrator** (plus any service-specific admin role the solution calls out).
Implement: Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
Description: Targeted Windows devices are enrolled and manageable.
Why: Deployments and policies only reach enrolled, Entra-joined devices.
Verify: Intune → **Devices → All devices**; the device appears and is **compliant**.
Implement: Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
Description: A Microsoft Entra security group for the pilot population (users or devices).
Why: Every solution is piloted before fleet rollout — the pilot is the gate.
Verify: Entra → **Groups**; the pilot group exists.
Implement: Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
Description: Windows 10 21H2+ or Windows 11 with current updates.
Why: Modern Intune and Microsoft 365 cloud features assume a patched, supported OS.
Verify: `winver`, or Intune → device → **Hardware**.
Implement: Deploy update rings or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
Why: Enrollment, policy sync, authentication, and the cloud service traffic depend on these endpoints.
Verify: From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through the proxy/firewall.

---
The repeatable deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


# 3. Implementation Guide — Endpoint Health & Digital Experience Monitoring

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).
Navigation for the dashboard is `Reports → Endpoint analytics`.

> **Model:** Enable Endpoint analytics, onboard a small **pilot**, let it collect a **baseline**,
> interpret the scores, wire **proactive remediations** for common issues, validate, then expand to
> the fleet. The pilot's baseline period is the gate.

> **Naming:** every object is named `<Purpose> – <Scope> – <Stage>`. Reuse the names below verbatim.

## Step 1 — Enable Endpoint analytics
1. Go to `Reports → Endpoint analytics`.
2. On the **Overview** tab, select **Start** (first run only). This enables the capability.
3. Open the **Settings** tab and confirm the data source includes **Intune enrolled devices** (add
   **Configuration Manager** devices only if you use co-management).
4. Leave the default startup-performance data collection on. Endpoint analytics begins collecting
   from enrolled devices.

## Step 2 — Create the pilot group
1. Entra → **Groups → New group → Security**.
2. **Name:** `Endpoint Analytics – Pilot Devices – Monitoring`. Add a few representative devices
   (mix of models). **Create**.
3. (Optional, for later) create `Endpoint Analytics – All Windows – Monitoring` for the broad scope —
   or use the script `EHEM-Set-MonitoringScopeTargeting.ps1` to build it.

## Step 3 — Confirm device data collection
1. In `Reports → Endpoint analytics → Settings`, confirm devices are enrolling for analytics.
2. On a pilot device, run `EHEM-Validation.ps1` to confirm the device is reporting and diagnostic
   data is at the required level.
3. If devices are not appearing, ensure they are enrolled and have synced (`EHEM-Remediation.ps1`
   can force a sync).

## Step 4 — Let the pilot collect a baseline
1. Allow the **baseline period** (typically several days) for the pilot devices to report.
2. Watch device counts climb in **Startup performance**, **Application reliability**, and
   **Resource performance**.
3. Do not judge scores until enough data has accrued — this warm-up is the pilot gate.

## Step 5 — Interpret the scores
1. **Overview** — read the overall Endpoint analytics score (0–100) and the four sub-scores.
2. **Startup performance** — sort by **Core boot time** and **Core sign-in time**; note the slowest
   models and devices.
3. **Application reliability** — review the least reliable apps (crashes/hangs) across the pilot.
4. **Resource performance** — find devices with high CPU/RAM spike time (under-resourced hardware).
5. **Work from anywhere** — review cloud-management and Autopilot readiness gaps.
6. Run `EHEM-Report.ps1` to pull the same scores and the top issues into a summary you can share.

## Step 6 — Wire proactive remediations for common issues
1. Go to `Reports → Endpoint analytics → Proactive remediations → Create script package`.
2. **Name:** `Proactive Remediation – Restart Stale Devices – Pilot` (this example nudges devices
   that have not restarted in N days — a frequent cause of slow, flaky endpoints).
3. Upload a **detection** script and a **remediation** script (Microsoft publishes sample packages;
   start from those, or use your own tested scripts). Set **Run this script using the logged-on
   credentials** as appropriate and **Enforce script signature check** per your policy.
4. **Scope tags / Assignments → Add groups →** `Endpoint Analytics – Pilot Devices – Monitoring`. Set
   the schedule (e.g. daily). **Create**.
5. Repeat for other common issues you found in Step 5 (e.g. clear temp files, reset a stuck service),
   each named `Proactive Remediation – <Issue> – Pilot`.

## Step 7 — (Optional) Integrate a dedicated DEX platform
1. Only if Step 5 shows you need deeper telemetry than Endpoint analytics provides, and you have
   licensing (Requirement 2.8).
2. Follow the **vendor's own documentation** (Nexthink, Tanium, etc.) to deploy the collector to a
   pilot group and stand up its console. Vendor-specific steps are intentionally out of scope here —
   use the vendor's deployment guide.
3. Keep Endpoint analytics running alongside it; treat the dedicated platform as additive.

## Step 8 — Validate the pilot
1. Run `EHEM-Validation.ps1` on pilot devices → confirms they are reporting for analytics.
2. Run `EHEM-Report.ps1` → confirms scores and the top issues are populated.
3. Confirm each proactive remediation shows **run history** with detections and successful fixes in
   `Proactive remediations → (package) → Device status`. Complete the **Testing Guide**.

## Step 9 — Expand to production
1. Re-point (or re-create) the proactive remediation assignments to
   `Endpoint Analytics – All Windows – Monitoring` once the pilot passes.
2. Continue to monitor the overall score trend; chase the worst models/devices.
3. Re-validate each cycle with `EHEM-Report.ps1`; add new remediation packages as new common issues
   emerge.

---
### Order of operations
`Enable analytics → pilot group → confirm data collection → baseline period → interpret scores → proactive remediations → (optional DEX platform) → validate → expand`


---


# 5. Testing Guide — Endpoint Health & Digital Experience Monitoring

Run after the pilot has collected its baseline (Implementation Step 4) and after wiring proactive
remediations (Step 6). Repeat each monitoring cycle.

## Test 1 — Endpoint analytics is enabled and reporting
**Do:** `Reports → Endpoint analytics → Overview`.
**Expected:** A score (0–100) and the four sub-scores are shown — not the "get started" prompt.

## Test 2 — Pilot devices are onboarded for analytics
**Do:** On a pilot device run `EHEM-Validation.ps1`; cross-check `Endpoint analytics → Settings`.
**Expected:** The device reports as enrolled for analytics; diagnostic data is at the required level.

## Test 3 — Startup performance data is present
**Do:** `Endpoint analytics → Startup performance`; or run `EHEM-Report.ps1`.
**Expected:** Pilot devices appear with boot/sign-in times; counts grew over the baseline period.

## Test 4 — Application reliability data is present
**Do:** `Endpoint analytics → Application reliability`.
**Expected:** Apps are listed with crash/hang scores for the pilot devices.

## Test 5 — Resource performance data is present
**Do:** `Endpoint analytics → Resource performance`.
**Expected:** Devices show CPU/RAM spike-time scores; outliers are identifiable.

## Test 6 — Proactive remediation runs and fixes
**Do:** `Endpoint analytics → Proactive remediations →` open the pilot package **→ Device status**.
**Expected:** Run history shows detections and successful remediations on pilot devices.

## Test 7 — Fleet report
**Do:** Run `EHEM-Report.ps1`.
**Expected:** A clear summary of the overall/sub-scores and the top startup, reliability, and
resource issues across the monitored devices.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass; the baseline period completed and scores are populated for the pilot |
| **Broad pass** | Tests 1, 3–5, 7 pass for the broad scope, and remediation run history is healthy |


---


# 6. Troubleshooting Guide — Endpoint Health & Digital Experience Monitoring

Use `EHEM-Validation.ps1` / `EHEM-Discovery.ps1` for device state, `EHEM-Report.ps1` for fleet
scores, and `EHEM-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. No data / scores not appearing
| Symptom | Cause | Remediation |
|---|---|---|
| Overview shows "get started", no score | Endpoint analytics not enabled | Reports → Endpoint analytics → Start (Implementation Step 1) |
| Devices missing from analytics | Not enrolled, not synced, or data collection blocked | Run `EHEM-Validation.ps1`; confirm enrollment; run `EHEM-Remediation.ps1` to force a sync |
| Scores look empty after enabling | Baseline period not elapsed | Wait the data warm-up; watch device counts climb day over day |

## B. Device not reporting telemetry
- Confirm the device is enrolled and checking in (Intune → device → **last check-in**).
- Confirm diagnostic data is not forced below the required level by another policy; run
  `EHEM-Validation.ps1`.
- Confirm the device can reach the Microsoft telemetry/Intune endpoints through the proxy/firewall
  (Requirement 2.6).

## C. Startup / resource scores look wrong or volatile
- Low device counts produce volatile averages — wait for more data and judge the **trend**.
- A single bad model can skew the fleet score; use the **model** breakdown to isolate it rather than
  reacting to the overall number.

## D. Proactive remediation not running or not fixing
| Symptom | Cause | Remediation |
|---|---|---|
| Package shows no run history | Not assigned, or device not synced | Confirm assignment to the scope group; run `EHEM-Remediation.ps1` (sync); check schedule |
| Detection runs, remediation skipped | Detection script exit code not signalling "issue found" | Detection must exit non-zero (or per package contract) to trigger remediation; re-test the script |
| Remediation blocked | Signature check on, script unsigned | Sign the script or adjust the package's signature-check setting per policy |

## E. Optional DEX platform issues
- Endpoint analytics is the supported core here. For a dedicated DEX platform (Nexthink, Tanium,
  etc.), collector/console problems are **vendor-specific** — use the vendor's documentation and
  support. Confirm only that the platform is licensed and its collector reaches its own service.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion
Get-CimInstance Win32_OperatingSystem | Select-Object LastBootUpTime   # restart age
dsregcmd /status                                                       # Entra join / MDM state
```
Force a management sync from the device, then re-check after a policy cycle:
```powershell
Start-Process "$env:WINDIR\System32\deviceenroller.exe" -ArgumentList "/c /AutoEnrollMDM" -WindowStyle Hidden
```

## G. When to escalate
If the device is enrolled, syncing, diagnostic data is permitted, the network reaches the service,
and the device still does not appear in Endpoint analytics after the baseline period, collect
`dsregcmd /status` output and the device's last check-in time and open a Microsoft support case. For
dedicated DEX platform problems, escalate to that vendor.


---


# 7. Best Practices — Endpoint Health & Digital Experience Monitoring

- **Pilot first, always.** Onboard a small representative pilot and let it collect a baseline before
  judging scores — the baseline period is the gate that keeps you from chasing noise.
- **Name everything consistently.** Use `<Purpose> – <Scope> – <Stage>` for every group and
  remediation package (e.g. `Proactive Remediation – Restart Stale Devices – Pilot`) so the tenant
  stays self-documenting and repeatable.
- **Trend, don't snapshot.** A single score means little; watch the overall and sub-scores move over
  weeks and react to declines, not one-off dips.
- **Target the worst models and devices.** Endpoint analytics breaks scores down by model and device
  — fix the heaviest offenders first for the biggest fleet-wide gain.
- **Start remediations from tested packages.** Begin with Microsoft's sample proactive-remediation
  packages or your own validated scripts; pilot every package before broad assignment and review its
  run history.
- **Keep remediations safe and reversible.** Detection scripts should be read-only; remediation
  scripts should do one well-understood thing and log what they changed.
- **Don't over-collect.** Enable the diagnostic data Endpoint analytics needs and no more; respect
  your data-governance policy.
- **Treat a dedicated DEX platform as additive and optional.** Only adopt Nexthink/Tanium when
  Endpoint analytics genuinely falls short, and follow the vendor's own documentation for its setup.
- **Close the loop with users.** Pair proactive fixes (e.g. restart nudges) with a short user message
  to reduce confusion and tickets.
- **Document the cadence.** Record which scores you review, on what schedule, and which remediation
  packages run where — for audits and repeatability.


---


# 8. Deliverables Summary — Endpoint Health & Digital Experience Monitoring

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What endpoint health/DEX monitoring is, the Endpoint analytics model, proactive remediations, where a dedicated DEX platform fits, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps (enable analytics, onboard, baseline, interpret, remediations, optional DEX) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `EHEM-Discovery.ps1` | Reports OS build, enrollment/diagnostic-data posture, restart age, and Endpoint analytics readiness (read-only) |
| `EHEM-Validation.ps1` | Confirms a device is reporting for Endpoint analytics and diagnostic data is at the required level (read-only) |
| `EHEM-Report.ps1` | Fleet Endpoint analytics scores + top startup/reliability/resource issues via Microsoft Graph (read-only) |
| `EHEM-Remediation.ps1` | Safe remediation of common degradations; forces an MDM sync and re-collection (default `-WhatIf`) |
| `EHEM-Set-MonitoringScopeTargeting.ps1` | Builds/updates the monitoring-scope Entra group and assignment for the analytics population |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Proactive endpoint visibility — startup, reliability, and resource health scored and trending, common
issues remediated automatically, with an optional path to a dedicated DEX platform — proven on a pilot
before you scale.
