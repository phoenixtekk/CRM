# WSUS to Windows Update for Business Patch Modernization

> **Version 1.0.0** · Category: Intune · Solution code: WSUSM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — WSUS to Windows Update for Business Patch Modernization (Microsoft Intune)

**White-label · Intune Solutions**

WSUS is a maintenance tax: a server to patch and back up, a content store that bloats and corrupts,
declined-update cleanup, and approvals that only reach devices on the corporate network — so remote
machines quietly fall behind. This solution is a clean **migration off WSUS to Windows Update for
Business**, managed entirely from Microsoft Intune. You define **update rings** — a phased,
scheduled, policy-driven rollout of quality and feature updates — devices patch **directly from
Microsoft** wherever they are, and you **decommission the WSUS servers**.

This is a complete, **deploy-it-today** package for migrating from WSUS to Windows Update for
Business with Microsoft Intune, written for an administrator with no prior cloud-update experience.

## What you get
- A plain-language **Solution Overview**: why WSUS is a liability, the target WUfB state, and the
  coexistence-then-cutover plan.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click steps: inventory WSUS, build the rings,
  remove the conflicting WSUS/GPO policy, validate the cutover, expand, and decommission WSUS.
- Five **PowerShell scripts** for WSUS/GPO conflict discovery, cutover validation, fleet patch
  reporting, safe remediation, and update-ring group building.
- **Testing** and **Troubleshooting** guides with explicit pass/fail and decommission gates.

## What this delivers
A **migration ring strategy** — a fast `WUfB – Ring – Pilot` and a slower `WUfB – Ring – Broad` —
with quality and feature-update deferrals, deadlines and active hours, a feature update policy that
pins the target Windows version, Delivery Optimization tuned to replace the WSUS local cache, and the
conflicting WSUS pointer removed so devices scan Microsoft.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand**, with a **pilot gate before WSUS decommission**.

## Outcome
Windows patching modernized off WSUS — no update server to maintain, devices patching from Microsoft
on or off the network, no version drift, and the WSUS servers retired — deployable by a single
administrator and validated before fleet rollout.


---


# 1. Solution Overview — WSUS to Windows Update for Business Patch Modernization

## What this solution is
This is a **migration**: it retires **WSUS** (Windows Server Update Services) and moves Windows
patching to **Windows Update for Business** (WUfB), managed entirely from **Microsoft Intune**.
Instead of approving updates on an on-premises server that only reaches devices on the corporate
network, you define **update rings** in Intune that defer, schedule, and deadline updates; devices
then pull patches **directly from Microsoft** with **Delivery Optimization** peer caching —
wherever they are. The end state is a cloud-managed patch program and **decommissioned WSUS
servers**.

## Why move off WSUS (read this first)
WSUS is a maintenance tax with real failure modes, which is *why* this migration is worth doing:
- **A server to own.** WSUS itself must be patched, backed up, and monitored; its content store
  bloats and periodically needs cleanup, and the SUSDB/WID database can corrupt.
- **LAN-only reach.** Approvals only flow to devices that can reach the WSUS server. Remote and
  hybrid workers fall behind and quietly drift out of compliance.
- **Manual approvals.** Someone has to approve, decline, and supersede updates every cycle —
  human effort that scales badly and stalls when that person is out.
- **No single source of truth.** Patch status lives on the WSUS console, separate from Intune,
  so the fleet is hard to report on.
Windows Update for Business removes all of this: no server, no approvals, no LAN dependency, and a
single Intune-based report.

## How the target state works
1. An Intune **Update ring** sets quality- and feature-update **deferral** periods, **deadlines**,
   **active hours**, restart behavior, and the user experience.
2. Rings are assigned to groups in a **migration ring strategy** — a small **Pilot** ring cuts over
   first (short deferral), then a **Broad** ring follows once the pilot is healthy.
3. A **Feature update policy** pins the target OS version (e.g. Windows 11 23H2) so devices don't
   drift ahead or fall behind.
4. **Delivery Optimization** lets devices share update content on the LAN to save WAN bandwidth —
   replacing the role WSUS used to play as a local content cache.
5. Devices scan **Microsoft** (not the WSUS server); update status is reported in Intune.

## The coexistence-then-cutover plan
The migration runs in this order so devices are never left without a patch authority:
1. **Inventory** the current WSUS approvals, the WSUS server pointer, and the GPO/registry update
   policy on devices.
2. **Design** the migration rings and **create** the WUfB update ring policies in Intune.
3. **Pilot:** assign the rings to a small pilot group and **remove the conflicting WSUS/GPO update
   policy from those devices** so they scan Microsoft.
4. **Validate** that pilot devices scan Microsoft (not WSUS) and patch on schedule.
5. **Expand** to the broad ring, removing the WSUS/GPO policy fleet-wide.
6. **Decommission WSUS** only after the fleet is validated on WUfB.

## The conflicting settings being removed
Two update authorities fight and stall updates, so the WSUS-era policy must be removed before a
device will scan Microsoft. These are the specific GPO settings (and the registry values they write)
to remove:
- **Specify intranet Microsoft update service location** — writes `WUServer` and `WUStatusServer`
  under `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`, and `UseWUServer` under
  `...\WindowsUpdate\AU`. This is what points a device at WSUS.
- **Do not connect to any Windows Update Internet locations** — writes
  `DoNotConnectToWindowsUpdateInternetLocations`; it blocks the device from scanning Microsoft even
  after WSUS is gone.
Removing these (and any related GPO update policy) lets the device scan Microsoft and obey the
Intune update ring instead.

## What you can control after migration
- **Quality update deferral** (0–30 days) and **deadline** with grace period.
- **Feature update deferral** / **target version** (pin the OS build).
- **Active hours** and **auto-restart** behavior; user notifications and the option to pause.
- **Driver updates** (approve/defer) and **Delivery Optimization** download mode/bandwidth.

## Benefits
- **No server to maintain** — the WSUS host, content store, and SUSDB are retired.
- **Patch anywhere** — devices update from Microsoft on or off the corporate network.
- **Stability** — ring-based rollout catches a bad update on the pilot before it hits the fleet.
- **No version drift** — feature update policies keep the fleet on a known, supported build.
- **Bandwidth-friendly** — Delivery Optimization replaces the WSUS local cache.
- **Visibility** — per-device and fleet-wide update status from one Intune report.

## Limitations (be honest with buyers)
- WUfB manages **Microsoft** updates (Windows + drivers + Microsoft Store); third-party app patching
  is separate.
- Rich Windows Update for Business **reports** need diagnostic data enabled and a Log Analytics
  workspace (optional, noted in requirements).
- Feature updates are large; the first cloud rollout timing should account for bandwidth now that
  WSUS no longer caches content locally.
- During coexistence, a device with the old WSUS pointer still present will not scan Microsoft —
  removing that pointer is the gating step, not an afterthought.

## The deployment model
> **Inventory WSUS → design + create WUfB rings in Intune → remove conflicting WSUS/GPO policy on
> the pilot → validate devices scan Microsoft → expand → decommission WSUS.** Pattern:
> **Assess → Configure → Pilot → Validate → Expand**, with a **pilot gate before WSUS decommission**.


---


# 2. Requirements Guide — WSUS to Windows Update for Business Migration

Verify **every** requirement before you start the cutover. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Intune (Plan 1). Windows Update for Business itself is a free Windows feature.
**Why:** Intune delivers the update rings/policies and reports status; it is the replacement control
plane for WSUS.
**Verify:** M365 admin center → **Billing → Licenses**.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune included).

## 2.2 Device enrollment
**Description:** Targeted devices enrolled in Intune (Entra-joined or hybrid-joined).
**Why:** Update rings apply only to enrolled devices; WSUS-managed devices that are not yet enrolled
cannot receive WUfB policy.
**Verify:** Intune → **Devices → All devices**.
**Implement:** Enable automatic enrollment; enroll/join the devices currently served by WSUS.

## 2.3 Supported Windows OS
**Description:** Windows 10/11 (Pro/Enterprise/Education).
**Why:** WUfB policies (rings, feature/quality update policies) require a supported build.
**Verify:** `winver`; run `WSUSM-Discovery.ps1`.
**Implement:** Patch/upgrade to a supported build.

## 2.4 Inventory of the current WSUS configuration
**Description:** A record of the WSUS server URL, the GPO/registry update policy in force, and the
current approvals/groups in the WSUS console.
**Why:** You cannot safely remove the old authority or confirm the cutover without knowing what is
in place today.
**Verify:** Run `WSUSM-Discovery.ps1` on representative devices (reads `WUServer`,
`DoNotConnectToWindowsUpdateInternetLocations`, `UseWUServer`); review the WSUS console for approval
groups.
**Implement:** Capture the discovery output and the WSUS group/approval list before changing
anything.

## 2.5 Network (Windows Update + Delivery Optimization)
**Description:** Outbound HTTPS to Windows Update and Delivery Optimization endpoints.
**Why:** After cutover, devices pull updates from Microsoft and share content via Delivery
Optimization instead of from the WSUS server.
**Verify:** From a device, Windows Update can check online; DO endpoints reachable.
**Implement:** Allow Windows Update / Delivery Optimization URLs through proxy/firewall; do not block
DO peer ports if you want LAN caching. Ensure `DoNotConnectToWindowsUpdateInternetLocations` is not
left enabled (it blocks the online scan).

## 2.6 Single update authority (remove the WSUS/GPO conflict)
**Description:** Intune/WUfB becomes the only update authority — the leftover WSUS pointer and
GPO update policy must be removed from migrated devices.
**Why:** Two authorities fight: a device that still has `WUServer`/`UseWUServer` set will keep
scanning WSUS and ignore the Intune ring.
**Verify:** Run `WSUSM-Discovery.ps1` (flags `WUServer`/`UseWUServer`) and `WSUSM-Validation.ps1`
(confirms the device scans Microsoft).
**Implement:** Remove the **Specify intranet Microsoft update service location** and **Do not connect
to any Windows Update Internet locations** GPO settings; clear the residual registry pointers with
`WSUSM-Remediation.ps1`.

## 2.7 Migration ring groups
**Description:** Entra security groups for the pilot and broad migration rings.
**Why:** Rings are assigned to groups; the pilot cuts over first, the broad ring follows.
**Verify:** Entra → **Groups** show the pilot and broad groups.
**Implement:** Create `WUfB – Ring – Pilot` and `WUfB – Ring – Broad` (see Implementation Step 1).

## 2.8 (Optional) Windows Update for Business reports
**Description:** Diagnostic data enabled + a Log Analytics workspace for the WUfB reports.
**Why:** Required only for the richer reporting experience that replaces WSUS console reporting.
**Verify:** Devices send **Required** diagnostic data; the workspace is configured.
**Implement:** Set diagnostic data via an Intune policy and connect Windows Update for Business
reports (optional).

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Devices enrolled / Entra-joined
- [ ] Windows 10/11 supported build — `WSUSM-Discovery.ps1`
- [ ] Current WSUS server, GPO policy, and approvals inventoried
- [ ] Network allows Windows Update + Delivery Optimization
- [ ] Conflicting WSUS/GPO update authority identified for removal
- [ ] `WUfB – Ring – Pilot` and `WUfB – Ring – Broad` Entra groups created
- [ ] (Optional) Diagnostic data + Log Analytics for WUfB reports


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


# 3. Implementation Guide — WSUS to Windows Update for Business Migration

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). This is a cutover: you build the cloud rings first, then remove
the WSUS authority on a pilot, validate, expand, and only then decommission WSUS.

> **Model:** A fast **Pilot** migration ring and a slower **Broad** ring, plus a feature update
> policy that pins the target Windows version. The pilot validates the cutover before the fleet —
> and **before any WSUS server is decommissioned**.

> **Naming convention used throughout (reuse verbatim):** `<Purpose> – <Scope> – <Stage>`.
> Objects created: groups `WUfB – Ring – Pilot` and `WUfB – Ring – Broad`; update ring policies
> `WUfB – Update Ring – Pilot` and `WUfB – Update Ring – Broad`; feature update policy
> `WUfB – Feature Update – Target`; Delivery Optimization profile `WUfB – Delivery Opt – Fleet`.

## Step 1 — Inventory the current WSUS state
1. Run `WSUSM-Discovery.ps1` on representative devices to capture the WSUS server pointer
   (`WUServer`), `UseWUServer`, and `DoNotConnectToWindowsUpdateInternetLocations`.
2. In the WSUS console, record the existing computer groups and approvals — they inform your ring
   design. Do not change WSUS yet.

## Step 2 — Create the migration ring groups
1. Entra → **Groups → New group** → Security → `WUfB – Ring – Pilot` (a few representative devices,
   ideally drawn from a current WSUS group). **Create**.
2. Create `WUfB – Ring – Broad` (the rest of the fleet). **Create**.

## Step 3 — Create the Pilot update ring
1. Intune → **Devices → Manage updates → Windows updates → Update rings → Create profile**.
2. **Name:** `WUfB – Update Ring – Pilot`. **Next**.
3. **Update settings:**
   - **Quality update deferral period (days):** **0**.
   - **Feature update deferral period (days):** **0**.
   - **Automatic update behavior:** Auto install and restart at a scheduled time (or at maintenance
     time).
   - **Active hours:** 8:00–18:00 (adjust to your org).
   - **Deadline for quality updates:** **2 days**; **feature updates:** **3 days**; **grace
     period:** **2 days**.
   - **User experience:** allow the user to pause = your policy.
4. **Next → Assignments → Add groups →** `WUfB – Ring – Pilot`. **Next → Create**.

## Step 4 — Create the Broad update ring
1. **Create profile** again. **Name:** `WUfB – Update Ring – Broad`.
2. **Update settings:** **Quality deferral 7 days**, **Feature deferral 14 days**, deadlines as
   above.
3. **Assignments → Add groups →** `WUfB – Ring – Broad`. **Create**.

## Step 5 — Create the feature update policy (pin the version)
1. Intune → **Devices → Manage updates → Windows updates → Feature updates → Create profile**.
2. **Name:** `WUfB – Feature Update – Target`. **Feature update version:** select your target (e.g.
   **Windows 11, version 23H2**).
3. **Rollout options:** Make update available as soon as possible (or schedule a gradual rollout).
4. **Assignments → Add groups →** `WUfB – Ring – Pilot` and `WUfB – Ring – Broad`. **Create**.

## Step 6 — Configure Delivery Optimization (replaces the WSUS local cache)
1. **Devices → Configuration → Create → Settings catalog →** search **Delivery Optimization**.
2. **Name:** `WUfB – Delivery Opt – Fleet`. Set **Download Mode** to **HTTP blended with peering
   behind same NAT (1)** or **LAN (1)**; set max bandwidth as needed. Assign to `WUfB – Ring – Pilot`
   and `WUfB – Ring – Broad`. **Create**.

## Step 7 — Remove the conflicting WSUS/GPO update policy on the pilot
This is the gating cutover step — until the WSUS pointer is gone, pilot devices keep scanning WSUS.
1. In Group Policy (the GPO that targets the pilot OU/devices), set to **Not Configured** (or remove
   the OU link):
   - **Specify intranet Microsoft update service location** (writes `WUServer`/`WUStatusServer` and
     `UseWUServer`).
   - **Do not connect to any Windows Update Internet locations** (writes
     `DoNotConnectToWindowsUpdateInternetLocations`).
2. On pilot devices, run `gpupdate /force`, then clear any residual registry pointers with
   `WSUSM-Remediation.ps1 -WhatIf` to preview, then `WSUSM-Remediation.ps1 -Confirm` to apply.
3. The pilot devices should now have no `WUServer`/`UseWUServer` value and scan Microsoft.

## Step 8 — Apply and sync on a pilot device
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Confirm the ring's deferral/deadline settings applied (**Settings → Windows Update →
   … managed by your organization**), or run `WSUSM-Validation.ps1`.

## Step 9 — Validate the pilot (gate before decommission)
1. Run `WSUSM-Validation.ps1` → confirms the device scans **Microsoft/WUfB**, not WSUS (no
   `WUServer`; online scan reachable), and the ring policy applied.
2. Run `WSUSM-Report.ps1` → confirms pilot devices' update status, OS build, and ring assignment.
3. Let the next quality update install on the pilot from Microsoft and confirm a healthy result.
   Complete the **Testing Guide**. **Do not decommission WSUS until this gate passes.**

## Step 10 — Expand to the broad ring
1. Remove the **Specify intranet Microsoft update service location** and **Do not connect to any
   Windows Update Internet locations** GPO settings fleet-wide; run `gpupdate /force` (or let it
   refresh) and use `WSUSM-Remediation.ps1` to clear residual pointers.
2. The `WUfB – Update Ring – Broad` ring already covers the fleet; confirm it is healthy each cycle.
3. Re-validate each cycle with `WSUSM-Validation.ps1` and `WSUSM-Report.ps1`.

## Step 11 — Decommission WSUS
1. With the fleet validated on WUfB (devices scanning Microsoft, patching on schedule), in the WSUS
   console stop approving updates and confirm no devices are still reporting in.
2. Uninstall the **Windows Server Update Services** role (and remove the WID/SUSDB and content
   store), or decommission the server.
3. Remove any remaining WSUS-related GPOs from Active Directory.

---
### Order of operations
`Inventory WSUS → ring groups → Pilot ring → Broad ring → Feature update policy → Delivery
Optimization → remove WSUS/GPO on pilot → apply → validate (gate) → expand → decommission WSUS`


---


# 5. Testing Guide — WSUS to Windows Update for Business Migration

Run after the pilot ring applies and the WSUS/GPO policy is removed (Implementation Steps 7–9), and
again before decommissioning WSUS (Step 11). The central question every test answers: **is the
device now scanning Microsoft instead of WSUS, and patching on the Intune ring?**

## Test 1 — WSUS pointer removed
**Do:** On a pilot device run `WSUSM-Validation.ps1` (or `WSUSM-Discovery.ps1`).
**Expected:** No `WUServer`/`WUStatusServer`, `UseWUServer = 0` or absent, and
`DoNotConnectToWindowsUpdateInternetLocations` not enabled.

## Test 2 — Ring policy applied
**Do:** Intune → **Devices → Manage updates → Windows updates → Update rings →**
`WUfB – Update Ring – Pilot` **→ Device status**.
**Expected:** Pilot devices show **Succeeded**.

## Test 3 — Device scans Microsoft
**Do:** On a pilot device, run `WSUSM-Validation.ps1`; it triggers a scan and confirms the source.
**Expected:** The device checks Windows Update online (Microsoft), not the WSUS server; quality/
feature deferral and deadline values match the ring.

## Test 4 — Updates install on schedule from Microsoft
**Do:** Let the current quality update flow to the pilot; observe install + scheduled restart within
the deadline.
**Expected:** The update downloads from Microsoft/Delivery Optimization and the device restarts per
the deadline/active-hours policy.

## Test 5 — Feature version pinned
**Do:** Run `WSUSM-Report.ps1` (or check `winver`).
**Expected:** Pilot devices are on (or moving to) the **targeted** feature version — not drifting.

## Test 6 — Delivery Optimization active
**Do:** On a pilot device: `Get-DeliveryOptimizationStatus` after an update downloads.
**Expected:** Peer/LAN bytes are used where available — confirming DO replaces the WSUS local cache.

## Test 7 — Fleet report
**Do:** Run `WSUSM-Report.ps1`.
**Expected:** A clear per-device update status + OS-build inventory with ring assignments; no device
still reporting a WSUS source.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (cutover gate)** | Tests 1–5 pass; the cycle's quality update installs cleanly from Microsoft on the pilot |
| **Broad pass** | Tests 1–4, 7 pass for the broad ring |
| **Decommission gate** | No device reports a WSUS source (Test 7); broad pass achieved — only then retire WSUS |


---


# 6. Troubleshooting Guide — WSUS to Windows Update for Business Migration

Use `WSUSM-Validation.ps1` / `WSUSM-Discovery.ps1` for device state, `WSUSM-Report.ps1` for fleet
status, and `WSUSM-Remediation.ps1` for safe fixes (default `-WhatIf`).

## A. Device still scans WSUS after cutover
| Symptom | Cause | Remediation |
|---|---|---|
| Device ignores the Intune ring | `WUServer`/`UseWUServer` still set | Run `WSUSM-Discovery.ps1` (flags them); remove the **Specify intranet Microsoft update service location** GPO; `gpupdate /force`; clear residual values with `WSUSM-Remediation.ps1` |
| "Some settings managed" but no online updates | `DoNotConnectToWindowsUpdateInternetLocations` enabled | Remove the **Do not connect to any Windows Update Internet locations** GPO; clear the value with `WSUSM-Remediation.ps1`; re-scan |
| GPO removed but pointer persists | Cached registry/Group Policy not refreshed | `gpupdate /force`, then `WSUSM-Remediation.ps1`; confirm with `WSUSM-Validation.ps1` |

## B. Updates not installing / stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Device never updates | Not synced, deferral too long, or paused | Sync policy; run a USO scan (`usoclient StartScan`); check the ring deferral/deadline; ensure not paused |
| Ring shows Error | Device not enrolled/checked in | Confirm enrollment and group membership; sync |

## C. Surprise / unwanted restarts
- Tune **active hours** and the **auto-restart / deadline grace** in the ring; communicate the
  deadline to users during the cutover.
- For sensitive groups, lengthen the grace period or allow user-scheduled restart.

## D. Feature update issues
| Symptom | Cause | Remediation |
|---|---|---|
| Device jumped to an unexpected version | No feature update policy pinning the version | Create/assign `WUfB – Feature Update – Target` with the target version |
| Feature update won't offer | Safeguard hold, or device below target | Check compatibility/safeguard holds; confirm the target version and rollout setting |

## E. Bandwidth / Delivery Optimization
- WAN saturated on the first cloud feature-update day (WSUS no longer caches content) → set Delivery
  Optimization download mode to LAN/peer and cap foreground/background bandwidth; stage the rollout
  gradually.

## F. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -EA SilentlyContinue      # WUServer / DoNotConnect...
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -EA SilentlyContinue   # UseWUServer
usoclient StartScan                # trigger an update scan
Get-DeliveryOptimizationStatus     # DO peer/LAN usage
```
Update logs: `Get-WindowsUpdateLog` (generates a merged log on the desktop).

## G. When to escalate
If the WSUS pointer is removed, the ring shows Succeeded, the device is synced and not paused, and
updates still won't install from Microsoft after a USO scan, collect `Get-WindowsUpdateLog` output
and open a Microsoft support case.


---


# 7. Best Practices — WSUS to Windows Update for Business Migration

- **Inventory before you touch anything.** Capture the WSUS server pointer, the GPO update policy,
  and the existing approval groups with `WSUSM-Discovery.ps1` first — you can't safely remove an
  authority you haven't mapped.
- **Remove the WSUS pointer — it's the gate, not an afterthought.** A device that still has
  `WUServer`/`UseWUServer` set keeps scanning WSUS and ignores the Intune ring. The cutover isn't
  done until that pointer is gone and the device scans Microsoft.
- **Pilot the cutover before decommissioning WSUS.** Keep WSUS running during coexistence so nothing
  is left without an authority; only retire it after the fleet validates on WUfB.
- **Use rings, always.** A small fast `WUfB – Ring – Pilot` catches a bad update before it reaches
  the broad fleet — the single most important practice after the cutover.
- **Pin the feature version.** `WUfB – Feature Update – Target` prevents drift; move it forward only
  after the pilot validates the new version.
- **Set realistic deadlines + active hours.** Patches must install on a schedule, but respect working
  hours and give a grace period to avoid surprise reboots.
- **Tune Delivery Optimization to replace the WSUS cache.** Use LAN/peer caching and bandwidth caps
  so the first cloud feature-update day doesn't saturate the WAN now that WSUS no longer caches
  content.
- **Watch for `DoNotConnectToWindowsUpdateInternetLocations`.** This leftover GPO silently blocks the
  online scan even after WSUS is gone — confirm it is removed.
- **Communicate to users.** A short note about the new deadline and restart behavior dramatically
  reduces tickets during the cutover.
- **Watch the reports.** Track update status and OS-build inventory with `WSUSM-Report.ps1` and chase
  any device still reporting a WSUS source.
- **Name everything consistently.** Reuse the `<Purpose> – <Scope> – <Stage>` convention for every
  group and policy so the migration is auditable and repeatable.


---


# 8. Deliverables Summary — WSUS to Windows Update for Business Migration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case for retiring WSUS and what's in the box |
| 1. Solution Overview | Why WSUS is a liability, the target WUfB state, the coexistence-then-cutover plan, the conflicting settings removed |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: inventory WSUS, build rings, remove WSUS/GPO, validate, expand, decommission |
| 5. Testing Guide | Validation procedures with pass/fail and decommission gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `WSUSM-Discovery.ps1` | Read-only: detects the WSUS server pointer and conflicting GPO/registry update policy (`WUServer`, `UseWUServer`, `DoNotConnectToWindowsUpdateInternetLocations`) plus OS build |
| `WSUSM-Validation.ps1` | Read-only: confirms a device scans Microsoft/WUfB (not WSUS) and the ring policy applied |
| `WSUSM-Report.ps1` | Read-only: fleet patch-status + ring report (Microsoft Graph) |
| `WSUSM-Remediation.ps1` | Default `-WhatIf`: clears residual WSUS pointers / conflicting policy |
| `WSUSM-Set-UpdateRingTargeting.ps1` | Builds the update-ring device groups (Microsoft Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable migration following the model: **Assess → Configure → Pilot → Validate → Expand**,
  with a pilot gate before WSUS decommission.

## Outcome
Windows patching modernized off WSUS — devices scanning Microsoft via Intune update rings wherever
they are, the conflicting WSUS/GPO policy removed, and the WSUS servers decommissioned — proven on a
pilot before scale.
