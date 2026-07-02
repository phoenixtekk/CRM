# Windows Updates for Business

> **Version 1.0.0** · Category: Intune · Solution code: WUFB

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Windows Updates for Business (Microsoft Intune)

**White-label · Intune Solutions**

Unpatched devices are how breaches start, and uncontrolled updates are how productivity dies —
surprise reboots, version drift, and a fleet nobody can report on. **Windows Update for Business**,
managed through Microsoft Intune, replaces WSUS and guesswork with **update rings**: a phased,
scheduled, policy-driven rollout of quality and feature updates, the ability to **expedite**
critical zero-day fixes, and clear **compliance reporting** across every device.

This is a complete, **deploy-it-today** package for implementing Windows Update for Business with
Microsoft Intune, written for an administrator with no prior update-management experience.

## What you get
- A plain-language **Solution Overview** of rings, feature updates, expedited updates, and Delivery Optimization.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order.
- Five **PowerShell scripts** for update-status discovery, ring validation, fleet compliance reporting, safe remediation, and ring/assignment auditing.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
A **ring-based update strategy** — a fast **Pilot ring** and a slower **Broad ring** — with quality
and feature-update deferrals, deadlines and active hours, a **feature update profile** that pins the
target Windows version, an **expedite** path for emergencies, and Delivery Optimization tuned to
spare your bandwidth.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Patched, predictable, reportable devices — no surprise reboots, no version drift, and a zero-day
response button — deployable by a single administrator and validated before fleet rollout.


---


# 1. Solution Overview — Windows Updates for Business

## What Windows Update for Business is
Windows Update for Business (WUfB) is Microsoft's cloud service for controlling how and when
Windows devices receive **quality updates** (monthly security/reliability patches) and **feature
updates** (annual OS versions). Managed through Microsoft Intune, it replaces WSUS for
cloud-managed devices: you define **update rings** that defer, schedule, and deadline updates, and
the devices pull updates directly from Microsoft with **Delivery Optimization** peer caching.

## How it works
1. An Intune **Update ring** sets quality- and feature-update **deferral** periods, **deadlines**,
   **active hours**, restart behavior, and the user experience.
2. Rings are assigned to groups in a **ring strategy** — a small **Pilot** ring updates first
   (short deferral), a **Broad** ring follows (longer deferral) once the pilot is healthy.
3. A **Feature update profile** pins the target OS version (e.g. Windows 11 23H2) so devices don't
   drift ahead or fall behind; you control the move to the next version.
4. **Expedited updates** push a specific critical/zero-day patch immediately, bypassing deferrals.
5. **Delivery Optimization** lets devices share update content on the LAN to save WAN bandwidth.
6. Update status is reported in Intune (and, optionally, Windows Update for Business reports).

## What you can control
- **Quality update deferral** (0–30 days) and **deadline** with grace period.
- **Feature update deferral** / **target version** (pin the OS build).
- **Active hours** and **auto-restart** behavior; user notifications and the option to pause.
- **Expedite** a named quality update for emergencies.
- **Driver updates** (approve/defer) and **Delivery Optimization** download mode/bandwidth.

## Benefits
- **Security** — devices stay patched on a predictable cadence; zero-days can be expedited.
- **Stability** — ring-based rollout catches a bad update on the pilot before it hits the fleet.
- **No version drift** — feature update profiles keep the fleet on a known, supported build.
- **Bandwidth-friendly** — Delivery Optimization reduces WAN load.
- **Visibility** — per-device and fleet-wide update status and feature-version inventory.

## Limitations (be honest with buyers)
- WUfB manages **Microsoft** updates (Windows + drivers + Microsoft Store); third-party app patching is separate.
- Rich Windows Update for Business **reports** need diagnostic data enabled and a Log Analytics workspace (optional add-on, noted in requirements).
- Feature updates are large; first rollout timing should account for bandwidth.
- Co-management with ConfigMgr/WSUS requires deciding which authority owns updates (avoid conflicts).

## The standard deployment model
> **Create Pilot + Broad update rings → add a feature update profile → assign by ring → validate on
> the pilot → expand to broad.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Windows Updates for Business

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). WUfB itself is a free Windows feature.
**Why:** Intune delivers the update rings/profiles and reports status.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Device enrollment
**Description:** Targeted devices enrolled in Intune.
**Why:** Update rings apply only to enrolled devices.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll devices.

## 2.3 Supported Windows OS
**Description:** Windows 10/11 (Pro/Enterprise/Education).
**Why:** WUfB policies (rings, feature profiles, expedite) require a supported build.
**Verify:** `winver`; run **`WUFB-Discovery.ps1`**.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Network (Windows Update + Delivery Optimization)
**Description:** Outbound HTTPS to Windows Update and Delivery Optimization endpoints.
**Why:** Devices pull updates from Microsoft and share content via Delivery Optimization.
**Verify:** From a device, Windows Update can check online; DO endpoints reachable.
**Implement:** Allow Windows Update / Delivery Optimization URLs through proxy/firewall; do not block DO peer ports if you want LAN caching.

## 2.5 Single update authority (no conflicts)
**Description:** Intune/WUfB is the authority for updates — not a leftover WSUS/GPO or ConfigMgr.
**Why:** Two update authorities fight and stall updates.
**Verify:** Check for a `WUServer` GPO/registry value; run **`WUFB-Discovery.ps1`** (flags WSUS).
**Implement:** Remove the WSUS/GPO settings (or set co-management update workload to Intune).

## 2.6 (Optional) Windows Update for Business reports
**Description:** Diagnostic data enabled + a Log Analytics workspace for the WUfB reports.
**Why:** Required only for the richer Update Compliance / WUfB reporting experience.
**Verify:** Devices send **Required** diagnostic data; the workspace is configured.
**Implement:** Set diagnostic data via an Intune policy and connect Windows Update for Business reports (optional).

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled
- [ ] Windows 10/11 supported build — `WUFB-Discovery.ps1`
- [ ] Network allows Windows Update + Delivery Optimization
- [ ] No conflicting WSUS/GPO/ConfigMgr update authority
- [ ] (Optional) Diagnostic data + Log Analytics for WUfB reports
- [ ] Pilot + Broad Entra groups created


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Windows Updates for Business

Follow these steps **in order**, in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> **Model:** A fast **Pilot** ring and a slower **Broad** ring, plus a feature update profile that
> pins the target Windows version. Pilot validates every update before the fleet gets it.

## Step 1 — Create the ring groups
1. Entra → **Groups → New group** → Security → `WUfB-Pilot` (a few representative devices). **Create**.
2. Create `WUfB-Broad` (the rest of the fleet). **Create**.

## Step 2 — Create the Pilot update ring
1. Intune → **Devices → Windows → Update rings for Windows 10 and later → Create profile**.
2. **Name:** `Update Ring - Pilot`. **Next**.
3. **Update settings:**
   - **Quality update deferral period (days):** **0**.
   - **Feature update deferral period (days):** **0**.
   - **Automatic update behavior:** Auto install and restart at a scheduled time (or at maintenance time).
   - **Active hours:** 8:00–18:00 (adjust to your org).
   - **Deadline for quality updates:** **2 days**; **feature updates:** **3 days**; **grace period:** **2 days**.
   - **User experience:** allow the user to pause = your policy.
4. **Next → Assignments → Add groups →** `WUfB-Pilot`. **Next → Create**.

## Step 3 — Create the Broad update ring
1. **Create profile** again. **Name:** `Update Ring - Broad`.
2. **Update settings:** **Quality deferral 7 days**, **Feature deferral 14 days**, deadlines as above.
3. **Assignments → Add groups →** `WUfB-Broad`. **Create**.

## Step 4 — Create the feature update profile (pin the version)
1. Intune → **Devices → Windows → Feature updates for Windows 10 and later → Create profile**.
2. **Name:** `Feature Update - Target`. **Feature update version:** select your target (e.g. **Windows 11, version 23H2**).
3. **Rollout options:** Make update available as soon as possible (or schedule a gradual rollout).
4. **Assignments → Add groups →** `WUfB-Pilot` and `WUfB-Broad`. **Create**.

## Step 5 — Configure Delivery Optimization (optional but recommended)
1. **Devices → Configuration → Create → Settings catalog →** search **Delivery Optimization**.
2. Set **Download Mode** to **HTTP blended with peering behind same NAT (1)** or **LAN (1)**; set max bandwidth as needed. Assign to all update groups. **Create**.

## Step 6 — Apply on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Confirm the deferral/deadline settings applied (**Settings → Windows Update → … managed by your organization**), or run **`WUFB-Validation.ps1`**.

## Step 7 — Validate the pilot
1. Run **`WUFB-Validation.ps1`** → confirms the ring policy applied (deferrals/deadlines in registry).
2. Run **`WUFB-ComplianceReport.ps1`** → confirms pilot devices' update status and OS build.
3. Let the next quality update install on the pilot and confirm a healthy result. Complete the **Testing Guide**.

## Step 8 — Expedite path (for emergencies)
1. When a zero-day quality update is released, go to **Devices → Windows → Quality updates (Expedite) → Create profile**, choose the update, set restart grace, and assign — it bypasses deferrals.

## Step 9 — Expand to production
1. The **Broad** ring already covers the fleet; confirm it's healthy after the pilot passes each cycle.
2. Move the feature update target forward only after the pilot validates the new version.
3. Re-validate each cycle with **`WUFB-ComplianceReport.ps1`** / **`WUFB-RingReport.ps1`**.

---
### Order of operations
`Ring groups → Pilot ring → Broad ring → Feature update profile → Delivery Optimization → Apply → Validate → Expedite (as needed) → Expand`


---


# 5. Testing Guide — Windows Updates for Business

Run after the pilot ring applies (Implementation Step 7) and after each update cycle / feature move.

## Test 1 — Ring policy applied
**Do:** Intune → **Devices → Windows → Update rings →** `Update Ring - Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 2 — Settings present on device
**Do:** On a pilot device run `WUFB-Validation.ps1`, or open **Settings → Windows Update** ("Some settings are managed by your organization").
**Expected:** Quality/feature deferral and deadline values match the ring; active hours set.

## Test 3 — Updates install on schedule
**Do:** Let the current quality update flow to the pilot; observe install + scheduled restart within the deadline.
**Expected:** The update installs and the device restarts per the deadline/active-hours policy.

## Test 4 — Feature version pinned
**Do:** Run `WUFB-ComplianceReport.ps1` (or check `winver`).
**Expected:** Pilot devices are on (or moving to) the **targeted** feature version — not drifting ahead.

## Test 5 — Expedite works (when needed)
**Do:** Create an expedite profile for a test/recent quality update; assign to a pilot device.
**Expected:** The device installs that update promptly, bypassing the deferral.

## Test 6 — Delivery Optimization active
**Do:** On a pilot device: `Get-DeliveryOptimizationStatus` after an update downloads.
**Expected:** Peer/LAN bytes are used where available (download mode reflects the policy).

## Test 7 — Fleet report
**Do:** Run `WUFB-ComplianceReport.ps1` and `WUFB-RingReport.ps1`.
**Expected:** A clear per-device update status + OS build inventory and the ring assignments.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; the cycle's quality update installs cleanly on the pilot |
| **Broad pass** | Tests 1–3, 7 pass for the broad ring before the next feature move |


---


# 6. Troubleshooting Guide — Windows Updates for Business

Use **`WUFB-Validation.ps1`** / **`WUFB-Discovery.ps1`** for device state and
**`WUFB-ComplianceReport.ps1`** for fleet status, **`WUFB-Remediation.ps1`** for safe fixes.

## A. Updates not installing / stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Device never updates | Not synced, deferral too long, or paused | Run `WUFB-Remediation.ps1` (sync + USO scan); check deferral/deadline; ensure not paused |
| "Some settings managed" but no updates | Conflicting WSUS/GPO authority | Run `WUFB-Discovery.ps1` (flags `WUServer`); remove WSUS/GPO; for co-management set update workload to Intune |
| Ring shows Error | Device not enrolled/checked in | Confirm enrollment and group membership; sync |

## B. Surprise / unwanted restarts
- Tune **active hours** and the **auto-restart / deadline grace** in the ring; communicate the deadline to users.
- For sensitive groups, lengthen the grace period or allow user-scheduled restart.

## C. Feature update issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device jumped to an unexpected version | No feature update profile pinning the version | Create/assign a Feature update profile with the target version |
| Feature update won't offer | Safeguard hold, or device below target | Check compatibility/safeguard holds; confirm the target version and rollout setting |

## D. Expedite not working
- Expedite requires the Windows Update service healthy and a supported build; confirm the device isn't paused and the Update Health Tools are present (they install automatically on supported builds).

## E. Bandwidth / Delivery Optimization
- WAN saturated on feature-update day → set Delivery Optimization download mode to LAN/peer and cap foreground/background bandwidth; stage feature rollout gradually.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -EA SilentlyContinue   # deferral/WSUS settings
usoclient StartScan        # trigger an update scan
Get-DeliveryOptimizationStatus    # DO peer/LAN usage
```
Update logs: `Get-WindowsUpdateLog` (generates a merged log on the desktop).

## G. When to escalate
If the ring shows Succeeded, no WSUS/GPO conflict exists, the device is synced and not paused, and
updates still won't install after a USO scan, collect `Get-WindowsUpdateLog` output and open a Microsoft support case.


---


# 7. Best Practices — Windows Updates for Business

- **Use rings, always.** A small fast **Pilot** ring catches a bad update before it reaches the **Broad** fleet — the single most important practice.
- **Pin the feature version.** A Feature update profile prevents drift and keeps the fleet on a known, supported build; move it forward only after the pilot validates the new version.
- **Set realistic deadlines + active hours.** Patches must install on a schedule, but respect working hours and give a grace period to avoid surprise reboots.
- **One update authority.** Let Intune/WUfB own updates — remove leftover WSUS/GPO settings and, under co-management, set the update workload to Intune.
- **Keep an expedite path ready.** Pre-plan the expedite profile so a zero-day can ship in minutes, bypassing deferrals.
- **Tune Delivery Optimization.** Use LAN/peer caching and bandwidth caps so feature-update day doesn't saturate the WAN; stage large rollouts.
- **Communicate to users.** A short note about the deadline and restart behavior dramatically reduces tickets.
- **Watch the reports.** Track update status and OS-build inventory with `WUFB-ComplianceReport.ps1` (or Windows Update for Business reports) and chase laggards.
- **Don't over-defer.** Long deferrals leave devices exposed; keep quality-update deferrals short (0 pilot / ~7 broad).
- **Document the cadence.** Record ring deferrals, deadlines, and the target feature version for audits and repeatability.


---


# 8. Deliverables Summary — Windows Updates for Business

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What WUfB is, rings/feature/expedite/Delivery Optimization, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered Intune steps (rings, feature profile, expedite, DO) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WUFB-Discovery.ps1` | Reports OS build, update deferral settings, and any conflicting WSUS authority |
| `WUFB-Validation.ps1` | Confirms the ring policy applied (deferrals/deadlines present) |
| `WUFB-ComplianceReport.ps1` | Fleet-wide update status + OS-build inventory (Microsoft Graph) |
| `WUFB-Remediation.ps1` | Safe remediation; forces a sync and a Windows Update scan (USO) |
| `WUFB-RingReport.ps1` | Lists Intune update rings + feature profiles and their assignments (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Patched, predictable, reportable devices — phased ring rollout, pinned feature version, and a zero-day expedite button.
