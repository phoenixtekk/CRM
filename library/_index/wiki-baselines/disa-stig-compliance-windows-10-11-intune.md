# DISA STIG Compliance for Windows 10 & 11 in Microsoft Intune

> **Version 1.0.0** · Category: Intune · Solution code: STIG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Defense and federal environments must meet the **DISA STIG** for Windows, and assessors expect proof
for an Authority to Operate — but doing it by hand is brutal: hundreds of rules across CAT I/II/III
severities, rules that break mission apps, and a STIG that DISA *revises* every quarter so your
hard-won baseline silently drifts out of compliance. This package implements the DISA Windows 10/11
STIG as Microsoft Intune policy, proves compliance, and gives you a documented process to keep the
baseline current every time DISA publishes a new STIG release.

This is a complete, **deploy-it-today** package written for an administrator with no prior hardening
experience — and it is deliberately two solutions in one: **net-new implementation** and an **ongoing
update-and-maintain lifecycle**.

## What you get
- A plain-language **Solution Overview** of the DISA STIG, CAT I/II/III severities, how rules map to Intune (settings catalog and imported ADMX), how the STIG differs from the Microsoft security baselines, and how SCAP / the STIG Viewer serve as the authority.
- A **Requirements Guide** with why / verify / implement-if-missing for every prerequisite, plus a consistent object-naming convention and a POA&M exception register.
- An **Implementation Guide** of precise, click-by-click Intune steps to build, pilot, validate, and expand the baseline by CAT severity — with a pilot gate and a rollback note because hardening can break mission apps.
- A **Maintenance & Update Guide** — a first-class lifecycle for every new DISA STIG release: obtain it, diff it against your live baseline, assess and approve, update in a controlled change, re-validate, and record the release.
- Five **PowerShell scripts** for STIG readiness discovery, per-device compliance validation, fleet posture and drift reporting, safe drift remediation, and STIG-release comparison.
- **Testing** and **Troubleshooting** guides for confident rollout and ongoing operation.

## What this delivers
A **hardened, STIG-compliant Windows 10/11 fleet** built as Intune settings-catalog and imported-ADMX
policy by CAT severity, provable per-device compliance reconciled to a SCAP / STIG Viewer scan, drift
detection and remediation, exceptions tracked as POA&M, and a documented STIG-release update lifecycle
so the baseline never silently falls behind.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — and, for each new STIG release,
**Obtain → Diff → Assess/Approve → Update → Re-validate → Record.**

## Outcome
Every Windows 10/11 device hardened to the DISA STIG and provably compliant — kept current as DISA
revises it instead of silently drifting, with exceptions carried as POA&M — deployable by a single
administrator and validated on a pilot before fleet rollout.


---


# 1. Solution Overview — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

## What the DISA STIG is
A STIG (Security Technical Implementation Guide) is a hardening standard published by the Defense
Information Systems Agency (DISA) for the U.S. Department of Defense. The Windows 10 STIG and the
Windows 11 STIG are documents containing hundreds of individual rules — each one a specific setting,
its required value, the discussion/rationale, and check/fix guidance. In defense and federal
environments, "meets the DISA STIG for Windows" is a mandatory bar for an Authority to Operate (ATO),
and assessors expect proof. This solution implements the applicable Windows STIG as Microsoft Intune
policy and then keeps it current as DISA revises the STIG over time.

## CAT I / CAT II / CAT III severities
Every STIG rule carries a severity category that drives priority and risk acceptance:
- CAT I (High) — a weakness that could directly and immediately result in loss of confidentiality,
  availability, or integrity. Address these first; open CAT I findings are the hardest to get accepted.
- CAT II (Medium) — a weakness that could result in loss if exploited; the bulk of the STIG.
- CAT III (Low) — a weakness that degrades defense-in-depth but is lower risk on its own.
Deploy by severity: CAT I and CAT II broadly, CAT III where practical, and track anything you cannot
meet as a POA&M exception (see below).

## How the rules map into Intune
The Windows STIG rules translate into two Intune policy types:
1. Settings catalog — the primary surface. Most STIG rules correspond to a setting in the Intune
   settings catalog (the same CSP/ADMX-backed settings Microsoft exposes), grouped by area (Account
   Policies, Local Policies, Defender, etc.). You build one or more settings-catalog policies that
   carry the required STIG values, organized by CAT severity.
2. Imported ADMX — a minority of STIG rules map to administrative templates not yet in the settings
   catalog. For those you import the relevant ADMX/ADML files into Intune and configure them as
   administrative-template settings.
A small number of STIG rules (BitLocker, Credential Guard, advanced audit policy) are best delivered
through the matching dedicated Intune surface (endpoint security disk encryption, account protection)
and referenced from your baseline.

## The STIG vs the Microsoft security baselines
Intune ships Microsoft-authored security baselines. They overlap with the STIG but are not the same:
they reflect Microsoft's recommendations, use Microsoft's grouping, and revise on Microsoft's
schedule. The DISA STIG is the DoD standard with its own rule IDs (Group/Rule/Vuln IDs), its own CAT
severities, and its own check/fix text — and DoD assessors ask specifically for the STIG. Do not
assume a Microsoft baseline satisfies a STIG assessment; this solution builds the STIG rules
explicitly so you can prove the mapping.

## SCAP and the STIG Viewer are the authority
The authoritative artifacts are the DISA-published STIG (the STIG Viewer `.stig`/XCCDF content) and
the matching SCAP benchmark used for automated scanning. Treat the STIG Viewer and SCAP content as the
source of truth for exact rule IDs, required values, and check/fix procedures — do not work from
memory. This solution gives you the correct procedure to translate the STIG into Intune; where a
specific rule is named it is clearly marked as an illustrative example only.

## The compliance and drift model
Configuring the policy is only half the job. You also:
- Prove compliance — Intune reports per-setting and per-device configuration state, so you can show
  each device received the STIG values; you reconcile that against a STIG Viewer / SCAP scan.
- Detect drift — a device can fall out of compliance (a conflicting policy, a local change, a failed
  apply). The included reporting and validation scripts surface drift so you can reapply.

## Exceptions are tracked as POA&M
No fleet meets 100% of a STIG cleanly. Any rule you cannot implement (it breaks a mission app, the
hardware lacks a feature, an operational constraint) is documented as a POA&M (Plan of Action &
Milestones): the finding, the risk, the compensating control, the owner, and the remediation
milestone/date. A documented POA&M is the accepted way to carry an open finding — a silent gap is not.

## The STIG-release maintenance lifecycle (why this is two solutions in one)
DISA revises the Windows STIGs periodically (typically quarterly). Each release adds, removes,
renumbers, or changes the required value of rules. Without a process, your hard-won baseline silently
falls behind the current STIG and the next assessment fails. This solution therefore includes a
first-class Maintenance & Update Guide (document 4): a repeatable lifecycle of
Obtain → Diff → Assess/Approve → Update → Re-validate → Record version that you run every time DISA
publishes a new STIG release, plus a comparison script that diffs a new STIG export against your live
baseline to drive the change.

## Benefits
- Assessment-ready hardening — every Windows 10/11 device built to the DISA STIG, with evidence.
- Right priority, controlled risk — CAT I/II first, CAT III where practical, piloted before fleet-wide.
- Provable compliance — per-device configuration state plus a fleet posture report, reconciled to SCAP.
- Stays current — a documented STIG-release update lifecycle so the baseline never silently drifts.
- Honest exceptions — anything you cannot meet is carried as a tracked POA&M, not a silent gap.

## Limitations (be honest with buyers)
- The authoritative rule list, values, and check/fix text live in the DISA STIG / STIG Viewer / SCAP
  content; this solution is the Intune implementation and maintenance method, not a copy of the STIG.
- Hardening can break mission applications — a pilot gate and rollback note are mandatory, not optional.
- Some STIG rules are out of scope for Intune settings (physical, procedural, or hardware items).
- Achieving 100% of rules may be neither possible nor desirable; documented POA&M exceptions are part
  of a healthy, assessable baseline.

## The deployment model
> Build the DISA STIG baseline (CAT I / CAT II / CAT III) as Intune settings-catalog and imported-ADMX
> policy, assign to a pilot, prove compliance, then expand fleet-wide — and run the maintenance
> lifecycle on every new STIG release. The repeatable way:
> Assess → Configure → Pilot → Validate → Expand.


---


# 2. Requirements Guide — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Verify every requirement before configuring. Each entry: Description · Why required · How to verify ·
How to implement if missing. Category-wide prerequisites are in
`global-requirements-intune-solutions.md`.

Object names used throughout this solution (reuse them verbatim in Intune):
- Settings-catalog policies (by severity):
  `STIG Win10/11 – CAT I – Pilot` and `STIG Win10/11 – CAT I – Production`
  `STIG Win10/11 – CAT II – Pilot` and `STIG Win10/11 – CAT II – Production`
  `STIG Win10/11 – CAT III – Pilot` and `STIG Win10/11 – CAT III – Production`
- Imported ADMX policy: `STIG Win10/11 – ADMX – Pilot` / `STIG Win10/11 – ADMX – Production`
- Compliance policy: `STIG Win10/11 – Compliance`
- Device groups: `STIG Win10/11 – Pilot Devices` and `STIG Win10/11 – Production Devices`
- Version tag (put in every policy description): `STIG-Win-vYYYY.MM` (the STIG release you are on)

## 2.1 Intune licensing
Description: An Intune-bearing license (Plan 1 is sufficient for settings catalog and ADMX).
Why required: Intune delivers the settings-catalog, imported-ADMX, and compliance policies.
How to verify: Microsoft 365 admin center → Billing → Licenses.
How to implement if missing: Assign M365 E3/E5, Business Premium (Intune included), or standalone Intune Plan 1. For DoD, use the appropriate government cloud offering (GCC High / DoD) where required.

## 2.2 Device enrollment
Description: The targeted Windows 10/11 devices are enrolled in Intune.
Why required: Configuration profiles and compliance policies apply only to enrolled devices.
How to verify: Intune → Devices → All devices; run `STIG-Discovery.ps1`.
How to implement if missing: Enable automatic enrollment (Entra ID join / Hybrid join) and enroll the devices.

## 2.3 Supported Windows 10/11 edition and build
Description: Windows 10 or Windows 11 Enterprise or Education on a currently supported build (Pro is acceptable for most rules; some STIG rules assume Enterprise/Education-class features).
Why required: Many STIG rules (Credential Guard, certain Defender/audit policies) require Enterprise/Education features and a current, supported build.
How to verify: `winver` on a device, or Intune → device → Hardware; run `STIG-Discovery.ps1`.
How to implement if missing: Upgrade to a supported Windows 10/11 edition/build (subscription activation or a feature update).

## 2.4 Official DISA STIG source (STIG Viewer / SCAP)
Description: The current DISA Windows 10 STIG and/or Windows 11 STIG (the STIG Viewer `.stig`/XCCDF content) and, ideally, the matching SCAP benchmark for automated scanning.
Why required: This is the authoritative list of rules, CAT severities, required values, and check/fix text. Exact Rule/Group/Vuln IDs and values are deferred to this source — do not work from memory.
How to verify: You can open the current Windows 10/11 STIG in the DISA STIG Viewer and identify its release (for example `vYYYY.MM` / the DISA quarterly release) and each rule's CAT severity.
How to implement if missing: Download the current Windows 10/11 STIG and its SCAP benchmark from the DISA public cyber exchange, and install the DISA STIG Viewer.

## 2.5 ADMX templates for non-catalog rules
Description: The ADMX/ADML files for any STIG rules not present in the Intune settings catalog (for example, template-only or third-party settings).
Why required: A minority of STIG rules can only be delivered via imported administrative templates.
How to verify: While building, note any STIG rule with no settings-catalog equivalent; those need imported ADMX.
How to implement if missing: Obtain the matching ADMX/ADML files and import them in Intune → Devices → Configuration → Import ADMX.

## 2.6 Pilot and production device groups
Description: Two Entra ID security groups: `STIG Win10/11 – Pilot Devices` (a small representative sample) and `STIG Win10/11 – Production Devices` (the rest of the fleet).
Why required: Hardening is piloted before fleet rollout because STIG rules can break mission apps.
How to verify: Entra → Groups; both groups exist.
How to implement if missing: Entra → Groups → New group → Security; add representative pilot devices to one and the remaining devices to the other.

## 2.7 Change control / approval process
Description: A documented approval step for applying and updating the baseline (aligned with your RMF/change process).
Why required: Hardening and STIG-release updates are production changes; they need review and a rollback plan. This is central to the maintenance lifecycle in document 4.
How to verify: You have a place to record approved changes and the STIG release in use (a change ticket, register, or the policy descriptions).
How to implement if missing: Adopt a change record (who approved, what changed, STIG release, rollback step). Record the version tag `STIG-Win-vYYYY.MM` in each policy description.

## 2.8 POA&M / exception register
Description: A register that tracks any STIG rule you cannot meet as a Plan of Action & Milestones (POA&M) item.
Why required: Open findings must be carried as documented, risk-accepted POA&Ms with a remediation milestone — not silent gaps. Assessors expect this.
How to verify: You have a POA&M/exception register with fields for finding (Rule/Vuln ID), CAT, risk, compensating control, owner, and milestone date.
How to implement if missing: Create the register (spreadsheet or GRC tool). Record each planned exception before it is needed; link it to the STIG rule ID from the STIG Viewer.

---
## Checklist
- [ ] Intune licensing assigned (government cloud where required)
- [ ] Windows 10/11 devices enrolled — `STIG-Discovery.ps1`
- [ ] Supported Windows 10/11 edition/build
- [ ] Current DISA Windows 10/11 STIG (and SCAP) obtained via STIG Viewer — note release `vYYYY.MM`
- [ ] ADMX/ADML files for any non-catalog rules
- [ ] `STIG Win10/11 – Pilot Devices` and `STIG Win10/11 – Production Devices` groups created
- [ ] Change-control / approval process and version tag convention agreed
- [ ] POA&M / exception register in place


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


# 3. Implementation Guide (net-new) — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
This builds the DISA STIG baseline by CAT severity as Intune policy, proves it on a pilot, then
expands fleet-wide.

> Model: Assess → Configure → Pilot → Validate → Expand. A small `STIG Win10/11 – Pilot Devices`
> group validates the hardening before the `STIG Win10/11 – Production Devices` fleet receives it.
> Hardening can break mission apps — do not skip the pilot gate or the rollback note (Step 10).

> Source note: The authoritative rule list, CAT severities, values, and check/fix text come from the
> current DISA Windows 10/11 STIG and its SCAP content, read in the STIG Viewer (Requirement 2.4).
> Rule names shown below are clearly marked examples; configure the actual rules and values from the
> STIG you obtained.

## Step 1 — Stage the STIG (Assess)
1. Open the current DISA Windows 10 and/or Windows 11 STIG in the STIG Viewer and confirm its release (for example `vYYYY.MM`).
2. Decide scope by severity: CAT I and CAT II fleet-wide, CAT III where practical.
3. From the STIG, list any rules that have no settings-catalog equivalent (these become the imported-ADMX policy in Step 6) and any rules you expect to carry as POA&M exceptions (Step 7).
4. Record the release you are targeting as your tag: `STIG-Win-vYYYY.MM`.

## Step 2 — Create the device groups
1. Entra → Groups → New group → Security → name `STIG Win10/11 – Pilot Devices` → add a few representative devices. Create.
2. Create `STIG Win10/11 – Production Devices` for the rest of the fleet. Create.

## Step 3 — Build the CAT I settings-catalog policy
1. Intune → Devices → Manage devices → Configuration → Create → New Policy.
2. Platform: Windows 10 and later. Profile type: Settings catalog. Create.
3. Name: `STIG Win10/11 – CAT I – Pilot`. Description: include the version tag `STIG-Win-vYYYY.MM`. Next.
4. Click Add settings. In the settings picker, search for each CAT I STIG rule and add it, then set the value to the STIG's required value. Work through the STIG's rules in order. Illustrative examples only — use the actual STIG rule values from the STIG Viewer:
   - Account Policies → password/lockout settings (example: minimum password length).
   - Microsoft Defender Antivirus settings (example: real-time protection enabled).
   - Local Policies / Security Options (example: interactive logon legal notice banner).
   *(Use the STIG Viewer check/fix text to confirm each setting maps to the right catalog entry.)*
5. Next → Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Next → Create.

## Step 4 — Build the CAT II settings-catalog policy
1. Repeat Step 3 with Name: `STIG Win10/11 – CAT II – Pilot`, adding only the CAT II rules.
2. Description: version tag `STIG-Win-vYYYY.MM` and "CAT II".
3. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 5 — (Optional) Build the CAT III settings-catalog policy
1. Repeat Step 3 with Name: `STIG Win10/11 – CAT III – Pilot`, adding the CAT III rules you choose to deploy.
2. Description: version tag `STIG-Win-vYYYY.MM` and "CAT III".
3. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 6 — Import ADMX and build the administrative-template policy (only if needed)
1. For any STIG rule with no settings-catalog equivalent (from Step 1.3): Intune → Devices → Manage devices → Configuration → Import ADMX → Import, upload the matching `.admx` and its `.adml` language file. Wait until status shows Available.
2. Configuration → Create → New Policy → Windows 10 and later → Templates → Imported Administrative templates → Create.
3. Name: `STIG Win10/11 – ADMX – Pilot`. Description: version tag. Configure the required template settings to the STIG values.
4. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 7 — Record POA&M exceptions
1. For each rule you cannot meet (it would break a mission app, the hardware lacks a feature, an operational constraint), record a POA&M item in your register: Rule/Vuln ID, CAT, risk, compensating control, owner, remediation milestone/date.
2. Implement the exception by omitting that setting from the policy, or by creating a narrowly scoped exception group and assigning a relaxed policy to it — never silently leave a rule undocumented.

## Step 8 — Create the compliance policy
1. Intune → Devices → Manage devices → Compliance → Create policy → Windows 10 and later → Create.
2. Name: `STIG Win10/11 – Compliance`. Set the compliance rules that represent your STIG posture (for example: minimum OS build, BitLocker required, Defender on, Secure Boot — use the STIG-relevant rules available in compliance).
3. Actions for noncompliance: mark noncompliant after a grace period; optionally email the user.
4. Assignments → Add groups → `STIG Win10/11 – Pilot Devices`. Create.

## Step 9 — Apply and validate on the pilot
1. On a pilot device, sync policy: Settings → Accounts → Access work or school → Info → Sync.
2. In Intune, open `STIG Win10/11 – CAT I – Pilot` → Device status / Per-setting status and confirm Succeeded (repeat for CAT II/III and ADMX policies).
3. On the device run `STIG-Validation.ps1` (per-device STIG-compliance check) and `STIG-Report.ps1` for fleet/pilot posture and drift. Reconcile against a STIG Viewer / SCAP scan of the pilot device.
4. Soak the pilot: have pilot users run their real mission apps for several business days. Watch for breakage (sign-in, line-of-business apps, printing, removable media, scripting). Complete the Testing Guide (document 5).

## Step 10 — Pilot gate and rollback note
1. Gate: do not expand until the pilot passes the Testing Guide gate AND no unresolved app breakage remains, and open CAT I/II findings are either fixed or carried as approved POA&Ms.
2. Rollback (if hardening breaks something): in Intune, remove the assignment of the offending policy from the affected group (or set the specific setting to Not configured), then sync. Removing the assignment is the fastest safe rollback; the device reverts on the next policy cycle. Record the rollback and the offending rule as a POA&M exception (Step 7).

## Step 11 — Expand to production
1. Duplicate each piloted policy (Intune → policy → Duplicate) and rename the copies `STIG Win10/11 – CAT I – Production`, `STIG Win10/11 – CAT II – Production`, `STIG Win10/11 – CAT III – Production`, `STIG Win10/11 – ADMX – Production`. Keep the version tag in the description.
2. Reassign the production copies to `STIG Win10/11 – Production Devices` (or add that group to the existing policies if you prefer a single policy set). Assign `STIG Win10/11 – Compliance` to production too.
3. Roll out in waves if the fleet is large; re-run `STIG-Report.ps1` after each wave to confirm posture and catch drift.

---
### Order of operations
`Stage STIG → Groups → CAT I catalog → CAT II catalog → (CAT III catalog) → Import ADMX → POA&M exceptions → Compliance → Apply + Validate → Pilot gate / rollback → Expand`


---


# 5. Testing Guide — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Run after the pilot policies apply (Implementation Step 9) and again after each STIG-release update
(Maintenance Part B, Step 5).

## Test 1 — Policies applied to the pilot
Do: Intune → Devices → Manage devices → Configuration → `STIG Win10/11 – CAT I – Pilot` → Device status (and Per-setting status). Repeat for CAT II/III.
Expected: Pilot devices show Succeeded; per-setting status shows the STIG settings applied without conflicts.

## Test 2 — Settings present on the device
Do: On a pilot device run `STIG-Validation.ps1`.
Expected: The script reports the device's STIG-relevant settings match the expected baseline values; no drift flagged.

## Test 3 — Compliance policy evaluates the device
Do: Intune → Devices → Compliance → `STIG Win10/11 – Compliance` → Device status; or on the device check Settings → Accounts → Access work or school.
Expected: Pilot devices evaluate Compliant against the STIG-relevant compliance rules.

## Test 4 — Reconcile with a STIG Viewer / SCAP scan
Do: Run a SCAP scan (or import results into the DISA STIG Viewer) against a pilot device and compare the findings to your Intune-applied baseline.
Expected: Applied CAT I/II rules show as Not a Finding (or Open only where a POA&M exists). Any Open finding without a POA&M is investigated.

## Test 5 — Imported ADMX settings applied (if used)
Do: Intune → `STIG Win10/11 – ADMX – Pilot` → Device status; confirm the imported-template settings on the device.
Expected: The imported administrative-template settings show Succeeded and are present on the device.

## Test 6 — App soak (hardening did not break the mission)
Do: Pilot users run their real mission apps for several business days (sign-in, line-of-business apps, printing, removable media, scripting).
Expected: No mission-app breakage. Any breakage is traced to a rule and handled as a POA&M exception or rolled back.

## Test 7 — Fleet posture and drift report
Do: Run `STIG-Report.ps1`.
Expected: A clear per-device STIG posture (compliant / drifted) and a drift list; pilot devices appear compliant.

## Test 8 — STIG-release diff (maintenance dry-run)
Do: Run `STIG-Compare-StigVersion.ps1` against the current live baseline using your current STIG export.
Expected: With no new release, the diff is empty (added/removed/changed = 0) — proving the script and your baseline agree before a real release update.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass; no unresolved mission-app breakage; open CAT I/II findings fixed or carried as approved POA&Ms |
| Production pass | Tests 1–3 and 7 pass for `STIG Win10/11 – Production Devices` after each rollout wave |
| Release-update pass | After a STIG release: Tests 1–6 re-pass on the pilot before promoting to production |


---


# 6. Troubleshooting Guide — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

Use `STIG-Discovery.ps1` / `STIG-Validation.ps1` for device state, `STIG-Report.ps1` for fleet posture
and drift, `STIG-Remediation.ps1` for safe reapply (default `-WhatIf`), and
`STIG-Compare-StigVersion.ps1` when working a release update.

## A. Policy not applying / device not compliant
| Symptom | Cause | Remediation |
|---|---|---|
| Settings-catalog policy shows Error on a device | Device not enrolled / not synced / not in the assigned group | Confirm enrollment (`STIG-Discovery.ps1`) and group membership; sync the device; re-check Per-setting status |
| Some settings Succeeded, others Error | A specific setting unsupported on that edition/build | Confirm a supported Windows 10/11 edition/build; remove or scope the unsupported rule |
| Device drifts back after applying | A conflicting Intune policy sets the same rule differently | Find the conflict (`STIG-Report.ps1` + Intune per-setting status) and resolve it at the policy level, not by repeated remediation |

## B. Hardening broke a mission app
- Identify the offending rule from the app behavior and `STIG-Validation.ps1`.
- Fastest safe rollback: remove the policy assignment from the affected group, or set that single rule to Not configured, then sync; the device reverts on the next policy cycle.
- Record the rollback as a documented POA&M item (Rule/Vuln ID, CAT, risk, compensating control, owner, remediation milestone).

## C. Imported ADMX settings not taking effect
| Symptom | Cause | Remediation |
|---|---|---|
| ADMX policy assigned but setting absent | ADMX/ADML not fully imported, or wrong language file | Intune → Import ADMX; confirm status Available and the matching `.adml`; recreate the template policy if needed |
| Template setting greyed out / unavailable | Rule belongs in the settings catalog, not ADMX | Configure it as a settings-catalog setting instead |

## D. Compliance policy reports noncompliant unexpectedly
- Confirm the compliance rules match rules the device can actually meet (OS build, BitLocker, Defender, Secure Boot).
- Allow the grace period to elapse and let the device re-evaluate; sync if needed.
- Cross-check with `STIG-Validation.ps1` to confirm whether it is a real gap or a reporting lag.

## E. SCAP / STIG Viewer scan disagrees with Intune
| Symptom | Cause | Remediation |
|---|---|---|
| Intune shows Succeeded but SCAP marks a rule Open | The rule maps to a different setting/registry value than the one applied, or a manual/procedural check | Re-check the rule's check text in the STIG Viewer; confirm the settings-catalog entry matches the required value; manual-check rules are handled procedurally, not by Intune |
| Open finding with no matching POA&M | A rule was deferred without being recorded | Add a POA&M item (Rule/Vuln ID, risk, compensating control, owner, milestone) or implement the rule |

## F. STIG-release update issues
| Symptom | Cause | Remediation |
|---|---|---|
| `STIG-Compare-StigVersion.ps1` shows huge unexpected diff | Comparing against the wrong export, or baseline not exported correctly | Re-export the current live baseline and the new STIG; confirm you are diffing the right two files |
| New CAT I rule breaks devices fleet-wide after promotion | Promoted to production without a full pilot soak | Roll back that rule (unassign / Not configured); re-pilot per Maintenance Part B before promoting again |

## G. Graph scripts fail to connect
- `STIG-Report.ps1` needs Microsoft Graph PowerShell and `DeviceManagementConfiguration.Read.All`; consent the scope on first `Connect-MgGraph`.
- If module load fails, run `Install-Module Microsoft.Graph -Scope CurrentUser`.

## H. Diagnostics quick reference
```powershell
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion   # edition/build
Get-MgContext                                                                          # confirm Graph scopes
gpresult /h "$env:TEMP\stig.html"                                                      # resultant settings report
```
Intune-side: device → Device configuration shows each profile's apply status; policy → Per-setting
status shows which STIG settings succeeded or errored.

## I. When to escalate
If the policy shows Succeeded, the device is enrolled, synced, and in the right group, no conflicting
policy exists, and a rule still will not apply, capture the per-setting status, a `gpresult` report,
and the SCAP scan result, and open a Microsoft support case.


---


# 7. Best Practices — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

- Pilot before you harden the fleet. A small `STIG Win10/11 – Pilot Devices` group soaked against real mission apps catches breakage before it reaches production — the single most important practice, because hardening can break mission apps.
- Prioritize by CAT severity. Deploy CAT I and CAT II first and broadly; add CAT III where practical. Open CAT I findings are the hardest to get accepted, so close them earliest.
- Work from the STIG Viewer / SCAP, not memory. The authoritative rule list, CAT severities, values, and check/fix text live in the current DISA Windows 10/11 STIG. Always configure from the release you obtained.
- Use the settings catalog first, ADMX only when needed. Most rules live in the settings catalog; reserve imported ADMX for the minority of rules that have no catalog equivalent.
- Name and tag everything consistently. Use the `<Purpose> – <Scope> – <Stage>` convention (`STIG Win10/11 – CAT II – Pilot`, etc.) and put the version tag `STIG-Win-vYYYY.MM` in every policy description so the live STIG release is always visible and auditable.
- Track every exception as a POA&M. A healthy, assessable baseline has documented POA&M items, not silent gaps — record the Rule/Vuln ID, CAT, risk, compensating control, owner, and remediation milestone.
- Treat each new STIG release as a change, not a footnote. Run the full Obtain → Diff → Assess/Approve → Update → Re-validate → Record lifecycle. Diff with `STIG-Compare-StigVersion.ps1` so you never miss an added or changed rule.
- Detect drift on a cadence. Run `STIG-Report.ps1` regularly and reapply with `STIG-Remediation.ps1` (default `-WhatIf`) so devices don't quietly fall out of compliance between releases.
- Resolve policy conflicts at the source. If a device repeatedly drifts, find the conflicting Intune policy setting the same rule differently — don't just keep remediating the symptom.
- Keep a rollback ready. Removing a policy assignment (or setting a rule to Not configured) is the fastest safe rollback when hardening breaks a mission app; record what you rolled back as a POA&M item.
- Prove compliance with evidence. Use Intune per-setting/device status plus the report script, reconciled to a STIG Viewer / SCAP scan, as your assessment evidence that each device received the STIG values.
- Distinguish the STIG from the Microsoft baselines. Do not assume a Microsoft security baseline satisfies a STIG assessment; build the STIG rules explicitly and keep the mapping.


---


# 8. Deliverables Summary — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What the DISA STIG is, CAT I/II/III severities, how rules map to Intune (settings catalog + ADMX), STIG vs Microsoft baselines, SCAP/STIG Viewer authority, POA&M exceptions, compliance/drift model, release lifecycle |
| 2. Requirements Guide | Every prerequisite with Why / Verify / Implement-if-missing, plus the object-naming convention and POA&M register |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide (net-new) | Exact, ordered Intune steps: stage STIG, build CAT I/II/III, import ADMX, POA&M exceptions, compliance, pilot, validate, rollback, expand |
| 4. Maintenance & Update Guide | The DISA STIG-release lifecycle: Obtain → Diff → Assess/Approve → Update → Re-validate → Record, plus ongoing drift maintenance |
| 5. Testing Guide | Validation procedures with pass/fail gates (including SCAP reconciliation and a maintenance dry-run) |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `STIG-Discovery.ps1` | Tenant/device STIG-readiness: enrollment, edition/build, BitLocker/Defender/Secure Boot, and conflicting authority signals (read-only) |
| `STIG-Validation.ps1` | Per-device STIG-compliance check against the expected baseline values (read-only) |
| `STIG-Report.ps1` | Fleet STIG posture + drift via Microsoft Graph device configuration states (read-only) |
| `STIG-Remediation.ps1` | Reapplies drifted settings by forcing policy sync; `-WhatIf` by default |
| `STIG-Compare-StigVersion.ps1` | Diffs a NEW DISA STIG export against the current live baseline to drive the update process |

## Object naming convention (used across docs and scripts)
- Settings-catalog policies by severity: `STIG Win10/11 – CAT I – Pilot` / `– Production` (and `– CAT II –`, `– CAT III –` variants)
- Imported ADMX policy: `STIG Win10/11 – ADMX – Pilot` / `STIG Win10/11 – ADMX – Production`
- Compliance policy: `STIG Win10/11 – Compliance`
- Device groups: `STIG Win10/11 – Pilot Devices` / `STIG Win10/11 – Production Devices`
- Version tag in every policy description: `STIG-Win-vYYYY.MM`

## What the buyer receives
- These guides as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process for both net-new implementation and ongoing release maintenance:
  Assess → Configure → Pilot → Validate → Expand (and Obtain → Diff → Assess/Approve → Update → Re-validate → Record for each new STIG release).

## Outcome
Every Windows 10/11 device hardened to the DISA STIG and provably compliant — with a documented
release lifecycle that keeps the baseline current each time DISA revises it and exceptions tracked as
POA&M, proven on a pilot before you scale.
