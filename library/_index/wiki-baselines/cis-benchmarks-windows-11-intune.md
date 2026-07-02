# Implement & Manage CIS Benchmarks for Windows 11 Devices for Microsoft Intune

> **Version 1.0.0** · Category: Intune · Solution code: CIS11

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — CIS Benchmarks for Windows 11 (Microsoft Intune)

Security teams, auditors, and cyber-insurers increasingly require Windows 11 endpoints to meet the
**CIS Benchmarks** — but doing it by hand is brutal: hundreds of settings, Level 1 vs Level 2
decisions, controls that break business apps, and a benchmark that CIS *revises* every few months so
your hard-won baseline silently drifts out of compliance. This package implements the CIS Benchmark
for Windows 11 as Microsoft Intune policy, proves compliance, and gives you a documented process to
keep the baseline current every time CIS publishes a new version.

This is a complete, **deploy-it-today** package written for an administrator with no prior
hardening experience — and it is deliberately two solutions in one: **net-new implementation** and an
**ongoing update-and-maintain lifecycle**.

## What you get
- A plain-language **Solution Overview** of CIS Benchmarks, Level 1 vs Level 2, how controls map to Intune (settings catalog and imported ADMX), and how CIS differs from the Microsoft security baselines.
- A **Requirements Guide** with why / verify / implement-if-missing for every prerequisite, plus a consistent object-naming convention.
- An **Implementation Guide** of precise, click-by-click Intune steps to build, pilot, validate, and expand the baseline — with a pilot gate and a rollback note because hardening can break apps.
- A **Maintenance & Update Guide** — a first-class lifecycle for every new CIS benchmark version: obtain it, diff it against your live baseline, assess and approve, update in a controlled change, re-validate, and record the version.
- Five **PowerShell scripts** for CIS readiness discovery, per-device compliance validation, fleet posture and drift reporting, safe drift remediation, and benchmark-version comparison.
- **Testing** and **Troubleshooting** guides for confident rollout and ongoing operation.

## What this delivers
A **hardened, CIS-compliant Windows 11 fleet** built as Intune settings-catalog and imported-ADMX
policy at Level 1 (with optional, tested Level 2), provable per-device compliance, drift detection
and remediation, and a documented benchmark-version update lifecycle so the baseline never silently
falls behind.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — and, for each new benchmark version,
**Obtain → Diff → Assess/Approve → Update → Re-validate → Record.**

## Outcome
Every Windows 11 device hardened to the CIS Benchmark and provably compliant — kept current as CIS
revises it instead of silently drifting — deployable by a single administrator and validated on a
pilot before fleet rollout.


---


# 1. Solution Overview — CIS Benchmarks for Windows 11 (Microsoft Intune)

## What the CIS Benchmarks are
The CIS Benchmarks are a set of consensus-developed, prescriptive security configuration
recommendations published by the Center for Internet Security. The Windows 11 Benchmark is a single
document containing hundreds of individual control recommendations — each one a specific setting,
the recommended value, the rationale, and the audit/remediation guidance. Auditors, cyber-insurers,
and security teams increasingly treat "meets the CIS Benchmark for Windows 11" as the bar for a
hardened endpoint. This solution implements that benchmark as Microsoft Intune policy and then keeps
it current as CIS revises the benchmark over time.

## Level 1 vs Level 2
- **Level 1 (L1)** — the baseline. Practical, broadly safe hardening that reduces attack surface
  with minimal impact on day-to-day use. This is what most fleets deploy first.
- **Level 2 (L2)** — defense-in-depth for high-security environments. Stronger, but more likely to
  break business applications or workflows (e.g. stricter PowerShell, network, or removable-media
  controls). Apply L2 selectively, on top of L1, after extra testing.
- There is also a **BitLocker / Next Generation Windows Security (NG)** profile in the benchmark for
  devices that meet the hardware prerequisites. Treat it as an add-on profile, not a replacement.

## How the controls map into Intune
The CIS Windows 11 controls translate into two Intune policy types:
1. **Settings catalog** — the primary surface. Most CIS controls correspond to a setting in the
   Intune settings catalog (the same CSP/ADMX-backed settings Microsoft exposes), grouped by area
   (Account Policies, Local Policies, Defender, etc.). You build one or more settings-catalog
   policies that carry the L1 (and optionally L2) values.
2. **Imported ADMX** — a minority of CIS controls map to administrative templates that are not yet
   in the settings catalog. For those you import the relevant ADMX/ADML files into Intune and
   configure them as administrative-template settings.
A small number of CIS items (BitLocker, Credential Guard, audit policy) are best delivered through
the matching dedicated Intune surface (endpoint security disk encryption, account protection) and
referenced from your baseline.

## CIS Benchmark vs the Microsoft security baselines
Intune ships Microsoft-authored security baselines. They overlap with CIS but are **not the same**:
they reflect Microsoft's recommendations, use Microsoft's grouping, and revise on Microsoft's
schedule. CIS is an independent consensus standard with its own control numbering and its own L1/L2
split, and audits ask specifically for CIS. Do not assume a Microsoft baseline satisfies a CIS
audit — this solution builds the CIS controls explicitly so you can prove the mapping.

## The compliance and drift model
Configuring the policy is only half the job. You also:
- **Prove compliance** — Intune reports per-setting and per-device configuration state, so you can
  show each device received the CIS values.
- **Detect drift** — a device can fall out of compliance (a conflicting policy, a local change, a
  failed apply). The included reporting and validation scripts surface drift so you can reapply.

## The benchmark-version maintenance lifecycle (why this solution is two solutions in one)
CIS revises the Windows 11 Benchmark periodically (typically every several months). Each revision
adds, removes, renumbers, or changes the recommended value of controls. Without a process, your
hard-won baseline silently falls behind the current benchmark and an audit fails. This solution
therefore includes a first-class **Maintenance & Update Guide** (document 4): a repeatable lifecycle
of **Obtain → Diff → Assess/Approve → Update → Re-validate → Record version** that you run every time
CIS publishes a new version, plus a comparison script that diffs a new CIS export against your live
baseline to drive the change.

## Source-of-truth note (CIS membership content)
CIS publishes the Benchmark PDF and a Microsoft Intune "Build Kit" / GPO content behind CIS
membership. The exact CIS control numbers and the Build Kit internals are the authoritative source —
treat them as deferred to the official CIS Benchmark document and CIS WorkBench. This solution gives
you the correct procedure to import and translate the benchmark into Intune; where a specific control
is named it is clearly marked as an example only.

## Benefits
- **Audit-ready hardening** — every Windows 11 device built to the CIS Benchmark, with evidence.
- **Right level, controlled risk** — deliberate L1 baseline with optional, tested L2 hardening.
- **Provable compliance** — per-device configuration state and a fleet posture report.
- **Stays current** — a documented version-update lifecycle so the baseline never silently drifts.
- **Safe rollout** — piloted before fleet-wide, with a rollback note because hardening can break apps.

## Limitations (be honest with buyers)
- The authoritative control list and values live in the CIS membership content; this solution is the
  Intune implementation and maintenance method, not a copy of the benchmark.
- Hardening can break business applications — L2 especially. A pilot gate and rollback note are
  mandatory, not optional.
- Some CIS controls are out of scope for Intune settings (physical, procedural, or hardware items).
- Achieving 100% of controls may be neither possible nor desirable; documented break-glass
  exceptions are part of a healthy baseline.

## The deployment model
> Build the Level 1 (and optional Level 2) baseline as Intune settings-catalog and imported-ADMX
> policy, assign to a pilot, prove compliance, then expand fleet-wide — and run the maintenance
> lifecycle on every new benchmark version. The repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — CIS Benchmarks for Windows 11 (Microsoft Intune)

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- Settings-catalog policy: `CIS Win11 – L1 – Pilot` (and later `CIS Win11 – L1 – Production`)
- Optional Level 2 policy: `CIS Win11 – L2 – Pilot` / `CIS Win11 – L2 – Production`
- Imported ADMX policy: `CIS Win11 – ADMX – Pilot` / `CIS Win11 – ADMX – Production`
- Compliance policy: `CIS Win11 – Compliance`
- Device groups: `CIS Win11 – Pilot Devices` and `CIS Win11 – Production Devices`
- Version tag (put in every policy description): `CIS-Win11-vX.Y.Z` (the benchmark version you are on)

## 2.1 Intune licensing
**Description:** An Intune-bearing license (Plan 1 is sufficient for settings catalog and ADMX).
**Why required:** Intune delivers the settings-catalog, imported-ADMX, and compliance policies.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**.
**How to implement if missing:** Assign M365 E3/E5 or Business Premium (Intune included), or standalone Intune Plan 1.

## 2.2 Device enrollment
**Description:** The targeted Windows 11 devices are enrolled in Intune.
**Why required:** Configuration profiles and compliance policies apply only to enrolled devices.
**How to verify:** Intune → **Devices → All devices**; run `CIS11-Discovery.ps1`.
**How to implement if missing:** Enable automatic enrollment (Entra ID join / Hybrid join) and enroll the devices.

## 2.3 Supported Windows 11 edition
**Description:** Windows 11 Pro, Enterprise, or Education on a currently supported build.
**Why required:** Many CIS controls (Credential Guard, certain Defender/audit policies) require Enterprise/Education-class features and a current build.
**How to verify:** `winver` on a device, or Intune → device → **Hardware**; run `CIS11-Discovery.ps1`.
**How to implement if missing:** Upgrade to a supported Windows 11 edition/build (subscription activation or a feature update).

## 2.4 Official CIS Benchmark source (membership content)
**Description:** The current CIS Microsoft Windows 11 Benchmark PDF and, ideally, the CIS Intune "Build Kit" / GPO content from CIS WorkBench.
**Why required:** This is the authoritative list of controls, levels, and values. The exact control numbers and Build Kit settings are deferred to this source — do not work from memory.
**How to verify:** You can open the current Windows 11 Benchmark document and identify its version (e.g. `vX.Y.Z`) and the L1/L2 designations.
**How to implement if missing:** Obtain CIS membership (or the free benchmark PDF) and download the current Windows 11 Benchmark and its Build Kit from CIS WorkBench.

## 2.5 ADMX templates for non-catalog controls
**Description:** The ADMX/ADML files for any CIS controls not present in the Intune settings catalog (for example, third-party or template-only settings).
**Why required:** A minority of CIS controls can only be delivered via imported administrative templates.
**How to verify:** While building, note any CIS control with no settings-catalog equivalent; those need imported ADMX.
**How to implement if missing:** Obtain the matching ADMX/ADML files and import them in Intune → **Devices → Configuration → Import ADMX**.

## 2.6 Pilot and production device groups
**Description:** Two Entra ID security groups: `CIS Win11 – Pilot Devices` (a small representative sample) and `CIS Win11 – Production Devices` (the rest of the fleet).
**Why required:** Hardening is piloted before fleet rollout because L1/L2 controls can break apps.
**How to verify:** Entra → **Groups**; both groups exist.
**How to implement if missing:** Entra → **Groups → New group → Security**; add representative pilot devices to one and the remaining devices to the other.

## 2.7 Change control / approval process
**Description:** A lightweight, documented approval step for applying and updating the baseline.
**Why required:** Hardening and benchmark-version updates are production changes; they need review and a rollback plan. This is central to the maintenance lifecycle in document 4.
**How to verify:** You have a place to record approved changes and the benchmark version in use (a change ticket, register, or the policy descriptions).
**How to implement if missing:** Adopt a simple change record (who approved, what changed, benchmark version, rollback step). Record the version tag `CIS-Win11-vX.Y.Z` in each policy description.

## 2.8 (Optional) Application inventory for break-glass exceptions
**Description:** A short list of business-critical apps that may conflict with hardening (legacy line-of-business, scripting, removable-media workflows).
**Why required:** Lets you plan documented exceptions before they cause an outage.
**How to verify:** You can name the apps and which CIS controls might affect them.
**How to implement if missing:** Collect the list from app owners during the Assess phase; record planned exceptions in your change record.

---
## Checklist
- [ ] Intune licensing assigned
- [ ] Windows 11 devices enrolled — `CIS11-Discovery.ps1`
- [ ] Supported Windows 11 edition/build
- [ ] Current CIS Windows 11 Benchmark (and Build Kit) obtained — note version `vX.Y.Z`
- [ ] ADMX/ADML files for any non-catalog controls
- [ ] `CIS Win11 – Pilot Devices` and `CIS Win11 – Production Devices` groups created
- [ ] Change-control / approval process and version tag convention agreed
- [ ] (Optional) App inventory for planned break-glass exceptions


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


# 3. Implementation Guide (net-new) — CIS Benchmarks for Windows 11 (Microsoft Intune)

Follow these steps **in order**, in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`). This builds the CIS Level 1 baseline (and optional Level 2) as
Intune policy, proves it on a pilot, then expands fleet-wide.

> **Model:** Assess → Configure → Pilot → Validate → Expand. A small `CIS Win11 – Pilot Devices`
> group validates the hardening before the `CIS Win11 – Production Devices` fleet receives it.
> **Hardening can break business apps — do not skip the pilot gate or the rollback note (Step 9).**

> **Source note:** The authoritative control list, levels, and values come from the current CIS
> Windows 11 Benchmark and its Build Kit (Requirement 2.4). Control names shown below are clearly
> marked examples; configure the actual controls and values from the benchmark you obtained.

## Step 1 — Stage the benchmark (Assess)
1. Open the current CIS Windows 11 Benchmark you obtained and confirm its version (for example `vX.Y.Z`).
2. Decide scope: **Level 1 for all devices**, and **Level 2 for the high-security subset** (if any).
3. From the benchmark, list any controls that have **no settings-catalog equivalent** (these become the imported-ADMX policy in Step 5) and any planned **break-glass exceptions** (Step 6).
4. Record the version you are targeting as your tag: `CIS-Win11-vX.Y.Z`.

## Step 2 — Create the device groups
1. Entra → **Groups → New group → Security →** name `CIS Win11 – Pilot Devices` → add a few representative devices. **Create**.
2. Create `CIS Win11 – Production Devices` for the rest of the fleet. **Create**.

## Step 3 — Build the Level 1 settings-catalog policy
1. Intune → **Devices → Manage devices → Configuration → Create → New Policy**.
2. **Platform:** Windows 10 and later. **Profile type:** **Settings catalog**. **Create**.
3. **Name:** `CIS Win11 – L1 – Pilot`. **Description:** include the version tag `CIS-Win11-vX.Y.Z`. **Next**.
4. Click **Add settings**. In the settings picker, search for each CIS Level 1 control and add it, then set the value to the benchmark's recommended value. Work through the benchmark sections in order. *Illustrative examples only — use the actual benchmark values:*
   - Account Policies → password/lockout settings (example: minimum password length).
   - Microsoft Defender Antivirus settings (example: real-time protection enabled).
   - Local Policies / User Rights / Security Options (example: interactive logon banner).
   *(If you have the CIS Build Kit, use it to confirm each setting maps to the right catalog entry.)*
5. **Next → Assignments → Add groups →** `CIS Win11 – Pilot Devices`. **Next → Create**.

## Step 4 — (Optional) Build the Level 2 settings-catalog policy
1. Repeat Step 3 with **Name:** `CIS Win11 – L2 – Pilot`, adding only the **Level 2** controls (L2 sits on top of L1).
2. **Description:** version tag `CIS-Win11-vX.Y.Z` and "Level 2 — high-security subset only".
3. **Assignments → Add groups →** `CIS Win11 – Pilot Devices` (only if your pilot includes an L2 device). **Create**.

## Step 5 — Import ADMX and build the administrative-template policy (only if needed)
1. For any CIS control with no settings-catalog equivalent (from Step 1.3): Intune → **Devices → Manage devices → Configuration → Import ADMX → Import**, upload the matching `.admx` and its `.adml` language file. Wait until status shows **Available**.
2. **Configuration → Create → New Policy → Windows 10 and later → Templates → Imported Administrative templates → Create**.
3. **Name:** `CIS Win11 – ADMX – Pilot`. **Description:** version tag. Configure the required template settings to the benchmark values.
4. **Assignments → Add groups →** `CIS Win11 – Pilot Devices`. **Create**.

## Step 6 — Handle break-glass exceptions
1. For each planned exception (a control that would break a business app), document it in your change record: control, why, compensating control, owner, review date.
2. Implement the exception by **omitting that setting** from the policy, or by creating a narrowly scoped exception group and assigning a relaxed policy to it — never silently leave it undocumented.

## Step 7 — Create the compliance policy
1. Intune → **Devices → Manage devices → Compliance → Create policy → Windows 10 and later → Create**.
2. **Name:** `CIS Win11 – Compliance`. Set the compliance rules that represent your CIS posture (for example: minimum OS build, BitLocker required, Defender on — use the benchmark-relevant rules available in compliance).
3. **Actions for noncompliance:** mark noncompliant after a grace period; optionally email the user.
4. **Assignments → Add groups →** `CIS Win11 – Pilot Devices`. **Create**.

## Step 8 — Apply and validate on the pilot
1. On a pilot device, sync policy: **Settings → Accounts → Access work or school → Info → Sync**.
2. In Intune, open `CIS Win11 – L1 – Pilot` → **Device status / Per-setting status** and confirm **Succeeded**.
3. On the device run `CIS11-Validation.ps1` (per-device CIS-compliance check) and `CIS11-Report.ps1` for fleet/pilot posture and drift.
4. **Soak the pilot:** have pilot users run their real apps for several business days. Watch for breakage (sign-in, line-of-business apps, printing, removable media, scripting). Complete the **Testing Guide** (document 5).

## Step 9 — Pilot gate and rollback note
1. **Gate:** do not expand until the pilot passes the Testing Guide gate AND no unresolved app breakage remains.
2. **Rollback (if hardening breaks something):** in Intune, **remove the assignment** of the offending policy from the affected group (or set the specific setting to *Not configured*), then sync. Removing the assignment is the fastest safe rollback; the device reverts on the next policy cycle. Record the rollback and the offending control as a break-glass exception (Step 6).

## Step 10 — Expand to production
1. Duplicate each piloted policy (Intune → policy → **Duplicate**) and rename the copies `CIS Win11 – L1 – Production`, `CIS Win11 – L2 – Production`, `CIS Win11 – ADMX – Production`. Keep the version tag in the description.
2. Reassign the production copies to `CIS Win11 – Production Devices` (or simply add that group to the existing policies if you prefer a single policy set). Assign `CIS Win11 – Compliance` to production too.
3. Roll out in waves if the fleet is large; re-run `CIS11-Report.ps1` after each wave to confirm posture and catch drift.

---
### Order of operations
`Stage benchmark → Groups → L1 catalog policy → (L2 catalog) → Import ADMX → Exceptions → Compliance → Apply + Validate → Pilot gate / rollback → Expand`


---


# 5. Testing Guide — CIS Benchmarks for Windows 11 (Microsoft Intune)

Run after the pilot policies apply (Implementation Step 8) and again after each benchmark-version
update (Maintenance Part B, Step 5).

## Test 1 — Policies applied to the pilot
**Do:** Intune → **Devices → Manage devices → Configuration →** `CIS Win11 – L1 – Pilot` **→ Device status** (and **Per-setting status**).
**Expected:** Pilot devices show **Succeeded**; per-setting status shows the CIS settings applied without conflicts.

## Test 2 — Settings present on the device
**Do:** On a pilot device run `CIS11-Validation.ps1`.
**Expected:** The script reports the device's CIS-relevant settings match the expected baseline values; no drift flagged.

## Test 3 — Compliance policy evaluates the device
**Do:** Intune → **Devices → Compliance →** `CIS Win11 – Compliance` **→ Device status**; or on the device check **Settings → Accounts → Access work or school**.
**Expected:** Pilot devices evaluate **Compliant** against the CIS-relevant compliance rules.

## Test 4 — Level 2 controls present (if deployed)
**Do:** On an L2 pilot device, run `CIS11-Validation.ps1` (it includes L2 checks when the L2 policy is assigned).
**Expected:** L2 settings are present in addition to L1; no L1/L2 conflicts.

## Test 5 — Imported ADMX settings applied (if used)
**Do:** Intune → `CIS Win11 – ADMX – Pilot` **→ Device status**; confirm the imported-template settings on the device.
**Expected:** The imported administrative-template settings show **Succeeded** and are present on the device.

## Test 6 — App soak (hardening did not break the business)
**Do:** Pilot users run their real apps for several business days (sign-in, line-of-business apps, printing, removable media, scripting).
**Expected:** No business-app breakage. Any breakage is traced to a control and handled as a break-glass exception or rolled back.

## Test 7 — Fleet posture and drift report
**Do:** Run `CIS11-Report.ps1`.
**Expected:** A clear per-device CIS posture (compliant / drifted) and a drift list; pilot devices appear compliant.

## Test 8 — Benchmark-version diff (maintenance dry-run)
**Do:** Run `CIS11-Compare-BenchmarkVersion.ps1` against the current live baseline using your current benchmark export.
**Expected:** With no new version, the diff is empty (added/removed/changed = 0) — proving the script and your baseline agree before a real version update.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6 pass; no unresolved business-app breakage on the pilot |
| **Production pass** | Tests 1–3 and 7 pass for `CIS Win11 – Production Devices` after each rollout wave |
| **Version-update pass** | After a benchmark update: Tests 1–6 re-pass on the pilot before promoting to production |


---


# 6. Troubleshooting Guide — CIS Benchmarks for Windows 11 (Microsoft Intune)

Use `CIS11-Discovery.ps1` / `CIS11-Validation.ps1` for device state, `CIS11-Report.ps1` for fleet
posture and drift, `CIS11-Remediation.ps1` for safe reapply (default `-WhatIf`), and
`CIS11-Compare-BenchmarkVersion.ps1` when working a version update.

## A. Policy not applying / device not compliant
| Symptom | Cause | Remediation |
|---|---|---|
| Settings-catalog policy shows Error on a device | Device not enrolled / not synced / not in the assigned group | Confirm enrollment (`CIS11-Discovery.ps1`) and group membership; sync the device; re-check **Per-setting status** |
| Some settings Succeeded, others Error | A specific setting unsupported on that edition/build | Confirm a supported Windows 11 edition/build; remove or scope the unsupported control |
| Device drifts back after applying | A conflicting Intune policy sets the same control differently | Find the conflict (`CIS11-Report.ps1` + Intune per-setting status) and resolve it at the policy level, not by repeated remediation |

## B. Hardening broke a business app
- Identify the offending control from the app behavior and `CIS11-Validation.ps1`.
- **Fastest safe rollback:** remove the policy assignment from the affected group, or set that single control to **Not configured**, then sync; the device reverts on the next policy cycle.
- Record the rollback as a documented break-glass exception (control, reason, compensating control, owner, review date).

## C. Imported ADMX settings not taking effect
| Symptom | Cause | Remediation |
|---|---|---|
| ADMX policy assigned but setting absent | ADMX/ADML not fully imported, or wrong language file | Intune → **Import ADMX**; confirm status **Available** and the matching `.adml`; recreate the template policy if needed |
| Template setting greyed out / unavailable | Control belongs in the settings catalog, not ADMX | Configure it as a settings-catalog setting instead |

## D. Compliance policy reports noncompliant unexpectedly
- Confirm the compliance rules match controls the device can actually meet (OS build, BitLocker, Defender).
- Allow the grace period to elapse and let the device re-evaluate; sync if needed.
- Cross-check with `CIS11-Validation.ps1` to confirm whether it is a real gap or a reporting lag.

## E. Benchmark-version update issues
| Symptom | Cause | Remediation |
|---|---|---|
| `CIS11-Compare-BenchmarkVersion.ps1` shows huge unexpected diff | Comparing against the wrong export, or baseline not exported correctly | Re-export the current live baseline and the new benchmark; confirm you are diffing the right two files |
| New L1 control breaks devices fleet-wide after promotion | Promoted to production without a full pilot soak | Roll back that control (unassign / Not configured); re-pilot per Maintenance Part B before promoting again |

## F. Graph scripts fail to connect
- `CIS11-Report.ps1` needs Microsoft Graph PowerShell and `DeviceManagementConfiguration.Read.All`; consent the scope on first `Connect-MgGraph`.
- If module load fails, run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## G. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion   # edition/build
Get-MgContext                                                                          # confirm Graph scopes
gpresult /h "$env:TEMP\cis.html"                                                       # resultant settings report
```
Intune-side: device → **Device configuration** shows each profile's apply status; policy → **Per-setting status** shows which CIS settings succeeded or errored.

## H. When to escalate
If the policy shows Succeeded, the device is enrolled, synced, and in the right group, no conflicting
policy exists, and a control still will not apply, capture the per-setting status and a `gpresult`
report and open a Microsoft support case.


---


# 7. Best Practices — CIS Benchmarks for Windows 11 (Microsoft Intune)

- **Pilot before you harden the fleet.** A small `CIS Win11 – Pilot Devices` group soaked against real apps catches breakage before it reaches production — the single most important practice, because hardening can break business apps.
- **Start at Level 1, add Level 2 deliberately.** Deploy L1 broadly; apply L2 only to the high-security subset that needs it and only after extra testing. Never enable L2 fleet-wide on day one.
- **Work from the official benchmark, not memory.** The authoritative control list, levels, and values live in the current CIS Windows 11 Benchmark and Build Kit. Always configure from the version you obtained.
- **Use the settings catalog first, ADMX only when needed.** Most controls live in the settings catalog; reserve imported ADMX for the minority of controls that have no catalog equivalent.
- **Name and tag everything consistently.** Use the `<Purpose> – <Scope> – <Stage>` convention (`CIS Win11 – L1 – Pilot`, etc.) and put the benchmark version tag `CIS-Win11-vX.Y.Z` in every policy description so the live version is always visible and auditable.
- **Document every break-glass exception.** A healthy baseline has documented exceptions, not silent gaps — record the control, reason, compensating control, owner, and review date.
- **Treat each new benchmark version as a change, not a footnote.** Run the full Obtain → Diff → Assess/Approve → Update → Re-validate → Record lifecycle. Diff with `CIS11-Compare-BenchmarkVersion.ps1` so you never miss an added or changed control.
- **Detect drift on a cadence.** Run `CIS11-Report.ps1` regularly and reapply with `CIS11-Remediation.ps1` (default `-WhatIf`) so devices don't quietly fall out of compliance between versions.
- **Resolve policy conflicts at the source.** If a device repeatedly drifts, find the conflicting Intune policy setting the same control differently — don't just keep remediating the symptom.
- **Keep a rollback ready.** Removing a policy assignment (or setting a control to *Not configured*) is the fastest safe rollback when hardening breaks an app; record what you rolled back as an exception.
- **Prove compliance with evidence.** Use Intune per-setting/device status plus the report script as your audit evidence that each device received the CIS values.


---


# 8. Deliverables Summary — CIS Benchmarks for Windows 11 (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What CIS Benchmarks are, L1 vs L2, how controls map to Intune (settings catalog + ADMX), CIS vs Microsoft baselines, compliance/drift model, version lifecycle |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing, plus the object-naming convention |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide (net-new) | Exact, ordered Intune steps: stage benchmark, build L1/L2, import ADMX, exceptions, compliance, pilot, validate, rollback, expand |
| 4. Maintenance & Update Guide | The CIS benchmark-version lifecycle: Obtain → Diff → Assess/Approve → Update → Re-validate → Record, plus ongoing drift maintenance |
| 5. Testing Guide | Validation procedures with pass/fail gates (including a maintenance dry-run) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CIS11-Discovery.ps1` | Tenant/device CIS-readiness: enrollment, edition/build, and conflicting authority signals (read-only) |
| `CIS11-Validation.ps1` | Per-device CIS-compliance check against the expected baseline values (read-only) |
| `CIS11-Report.ps1` | Fleet CIS posture + drift via Microsoft Graph device configuration states (read-only) |
| `CIS11-Remediation.ps1` | Reapplies drifted settings by forcing policy sync; `-WhatIf` by default |
| `CIS11-Compare-BenchmarkVersion.ps1` | Diffs a NEW CIS benchmark export against the current live baseline to drive the update process |

## Object naming convention (used across docs and scripts)
- Settings-catalog policies: `CIS Win11 – L1 – Pilot` / `CIS Win11 – L1 – Production` (and `– L2 –` variants)
- Imported ADMX policy: `CIS Win11 – ADMX – Pilot` / `CIS Win11 – ADMX – Production`
- Compliance policy: `CIS Win11 – Compliance`
- Device groups: `CIS Win11 – Pilot Devices` / `CIS Win11 – Production Devices`
- Version tag in every policy description: `CIS-Win11-vX.Y.Z`

## What the buyer receives
- These guides as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process for both net-new implementation and ongoing version maintenance:
  **Assess → Configure → Pilot → Validate → Expand** (and **Obtain → Diff → Assess/Approve → Update → Re-validate → Record** for each new benchmark version).

## Outcome
Every Windows 11 device hardened to the CIS Benchmark and provably compliant — with a documented
update lifecycle that keeps the baseline current each time CIS revises it, proven on a pilot before
you scale.
