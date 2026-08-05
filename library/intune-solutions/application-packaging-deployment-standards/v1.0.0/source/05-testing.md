# 5. Testing Guide — Application Packaging & Deployment Standards

This guide validates two things: (a) that the **standard's tenant objects and controls exist and
work**, and (b) that **an individual package correctly passes through the standard** end to end. Run
Part A once, when you adopt the standard. Run Part B for every package, using the worked example
`Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1` as the model.

---

## Part A — The standard is in place

### Test A1 — All named objects exist

**Do:** In Entra → **Groups**, confirm `APP – Ring 0 Packaging Lab`, `APP – Ring 1 Pilot Devices`,
`APP – Ring 2 Broad Devices`, `APP – Exclusions – Do Not Deploy`, `ROLE – Package Approvers`, and
`ROLE – Application Packagers` all exist. In Intune → **Tenant administration → Roles → Scope (Tags)**
confirm `SCOPE – Application Packaging`; under **All roles** confirm `Application Packager (Standard)`.
In **Apps → Categories** confirm the six categories.
**Expected:** Every object is present with the exact name. Any missing object is a Step 2 gap.

### Test A2 — The packager role cannot reach Ring 2

**Do:** Sign in as a member of `ROLE – Application Packagers` (or review the role assignment). Confirm
the role's assignment scope lists **only** `APP – Ring 0 Packaging Lab` and `APP – Ring 1 Pilot
Devices`.
**Expected:** A packager can assign to Ring 0 and Ring 1 but **not** Ring 2 — the release gate is
enforced by permissions, not just process.

### Test A3 — The audit scripts connect and return data

**Do:** Run `.\APPSTD-Invoke-PackageStandardAudit.ps1 -WhatIfOnlySummary`.
**Expected:** The script connects to Graph, enumerates apps, and prints a compliant/non-compliant
summary with no error. This confirms Requirements 2.4 and 2.5.

### Test A4 — The evidence store is ready

**Do:** Open the `Application Package Records` SharePoint library. Confirm version history is on,
`_Standard\Baseline`, `_Standard\Exceptions`, and `_Standard\Audit Reports` exist, and permissions
grant Contribute to packagers/approvers and Read to audit.
**Expected:** The store exists and is access-controlled (Requirement 2.7).

---

## Part B — A package passes through the standard

### Test B1 — Intake form is complete before packaging

**Do:** Open `Application Package Records\Acme Software Ltd Acme Invoice Client\7.3.1\01-Intake.md`.
**Expected:** Sections A–D are complete, the format decision (B4) names the deciding question, and no
field is blank. An incomplete form means the package should not have been built yet.

### Test B2 — Naming, version stamping, and metadata are compliant

**Do:** Run `.\APPSTD-Invoke-PackageStandardAudit.ps1 -CreatedSinceDays 7` and find the app, then run
`.\APPSTD-Get-PackageMetadataCompleteness.ps1 -MinimumScore 100`.
**Expected:** The app reports `Compliant: YES` with zero violations, and a metadata score of `100`.
The version `7.3.1` appears identically in the name, the detection rule, and the evidence folder.

### Test B3 — Detection rule passes the quality checker

**Do:** Run
`.\APPSTD-Test-DetectionRuleQuality.ps1 -AppName "Acme Software Ltd. Acme Invoice Client – Win32 – v7.3.1"`.
**Expected:** `Result: PASS`, `FindingCount: 0`. No banned pattern (B1–B10) is triggered. This is the
automated half of acceptance Gate 3.

### Test B4 — Three-state detection proof on Ring 0

**Do:** On a clean `APP – Ring 0 Packaging Lab` VM: (1) confirm detection reports **not installed**
before install; (2) install and confirm detection reports **installed**; (3) on a VM with v7.2.4
present, confirm the v7.3.1 rule reports **not installed** (i.e. it distinguishes versions).
**Expected:** All three states observed and recorded on the acceptance checklist (Gate 3.5).

### Test B5 — Commands are silent and reversible

**Do:** On a Ring 0 VM, run the install command manually, then the uninstall command. Check
`C:\ProgramData\PackageLogs\` for the logs.
**Expected:** Both run with no UI, return exit `0`, and the uninstall genuinely removes the app
(detection then reports not installed). A stub uninstall fails this test (Gate 2.4).

### Test B6 — Assignment hygiene is clean

**Do:** After the app is assigned to Ring 1, run `.\APPSTD-Get-AssignmentHygieneReport.ps1`.
**Expected:** The app reports `Clean: YES`. The `APP – Exclusions – Do Not Deploy` group is present as
an **Excluded** group, and there is no All Devices/All Users target and no Required+Uninstall
conflict.

### Test B7 — Sign-off record exists before Ring 2

**Do:** Open `03-Signoff.md` in the evidence folder.
**Expected:** It names a reviewer who is **not** the packager, records Gates 1–5 as PASS, cites the
detection checker's 0-finding result, and shows Ring 2 approval as pending until pilot validation.

### Test B8 — Pilot install report

**Do:** After Ring 1 assignment and a policy cycle, in Intune open the app → **Device install status**.
**Expected:** Pilot devices report **Installed** (not "Installed but failed", not a reinstall loop),
confirming the detection rule reports the truth on real devices.

---

## Pass/fail gate

| Gate | Requirement |
|---|---|
| **Standard-ready** | Tests A1–A4 pass — objects exist, packager role is scoped, scripts run, evidence store ready |
| **Pilot pass (per package)** | Tests B1–B8 pass on `APP – Ring 1 Pilot Devices`; detection checker 0 findings; signed sign-off filed |
| **Broad pass (per package)** | Test B8 reports Installed across `APP – Ring 2 Broad Devices` after expansion; hygiene report clean |

Do **not** assign a package to Ring 2 until its pilot gate passes and the sign-off record is filed.
