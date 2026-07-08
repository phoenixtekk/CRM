# 2. Requirements Guide — Microsoft Purview Optimization & Tune-Up

Verify **every** requirement before tuning anything. Each entry follows **Description · Why required ·
How to verify · How to implement if missing.** The category-wide Purview prerequisites (compliance
licensing, least-privilege Purview roles, Security & Compliance PowerShell + Graph toolchain, in-scope
data sources, compliance/records/privacy/legal stakeholders, and a pilot scope + change control) are in
`global-requirements-purview.md` — confirm those **six first**; this guide adds the tuning-specific
detail and does not duplicate them.

> **Object names used throughout (use verbatim):**
> pilot tuning scope group `Purview Tuning - Pilot` (Entra security group scoping the pilot); tuning
> output/evidence folder `.\OPSOPT-out`; change record label `OPSOPT Tuning Change`. **This solution
> creates no new DLP/label/insider-risk/alert policies** — it tunes the ones that already exist, named
> by *your* tenant (e.g. an existing `PII - Exchange DLP`). Placeholder policy names in examples are
> illustrative; substitute your real object names.

## 2.1 An existing Purview deployment with policies already live (the thing being tuned)
**Description:** Live, already-deployed **DLP policies**, **sensitivity/auto-labeling policies**,
**insider-risk policies**, and/or **alert policies** producing the noise you want to reduce.
**Why required:** This is a **tune-up**, not a build — there must be existing policies and existing
alert/false-positive history to measure and adjust. A greenfield tenant has nothing to tune.
**How to verify:** `Get-DlpCompliancePolicy`, `Get-AutoSensitivityLabelPolicy`, `Get-LabelPolicy`, and
`Get-ProtectionAlert` return existing objects; the Purview alert queue shows recent volume.
`OPSOPT-Discovery.ps1` inventories what exists and its current mode.
**How to implement if missing:** If policies do not yet exist, the relevant **build** solution (DLP,
labeling, insider risk) comes first — this solution optimizes the result.

## 2.2 Licensing that unlocks the capabilities being tuned (category GR1)
**Description:** The **advanced** capabilities most in need of tuning — advanced DLP conditions,
**auto-labeling**, and **Insider Risk Management** — generally require **Microsoft 365 E5** or the
**E5 Compliance** add-on. Baseline DLP/labeling exists at lower tiers.
**Why required:** Simulation modes, advanced SIT conditions, and IRM tuning surfaces are plan-gated;
without the plan the tuning surfaces are missing.
**How to verify:** M365 admin center → confirm E5 / E5 Compliance; in the Purview portal confirm
auto-labeling **simulation** and Insider Risk are present. Flag **"verify your licensing/tenant"** on
any capability a plan gate touches.
**How to implement if missing:** Assign/purchase the required licensing before relying on the
plan-gated tuning surfaces.

## 2.3 Least-privilege tuning roles — separated from policy authorship and from insider-risk (category GR2)
**Description:** To tune DLP/labeling/alerts you need **Compliance Administrator** or **Compliance Data
Administrator** (or the specific **DLP Compliance Management** / **Information Protection** role groups).
To tune **Insider Risk Management** you need an **Insider Risk Management** role group, held **separately**
from DLP/label admins and from HR/legal reviewers.
**Why required:** Purview uses fine-grained role groups; tuning requires the matching role, and
**Insider Risk is HR/privacy-sensitive** — role separation between *tuning the noise* and *reviewing a
case* is mandatory.
**How to verify:** Purview portal → **Roles & scopes → Permissions** (or `Get-RoleGroupMember`) shows
the tuning roles held by the tuning admin and the IRM role held by a separate identity.
**How to implement if missing:** Assign the least-privilege role group under change control; keep the
IRM role separate. `OPSOPT-Discovery.ps1` reports the current role membership it can see.

## 2.4 A false-positive / noise signal to tune against (the evidence)
**Description:** Enough recent **DLP match history**, **override / false-positive reports**, and **alert
volume** to identify the noisiest rules. `Get-DlpDetailReport` surfaces per-match records including user
**overrides** and **reported false positives**; `Search-UnifiedAuditLog` and `Get-ProtectionAlert`
surface alert volume.
**Why required:** Tuning without measurement is guessing. You tune the rules the evidence shows are
noisy, not the ones you suspect.
**How to verify:** `Get-DlpDetailReport` returns rows for a recent window; **unified audit log
ingestion** is on (`Get-AdminAuditLogConfig | Select UnifiedAuditLogIngestionEnabled` = **True**).
`OPSOPT-Report.ps1` produces the noise baseline.
**How to implement if missing:** Enable audit ingestion (`Set-AdminAuditLogConfig
-UnifiedAuditLogIngestionEnabled $true`) and allow the reporting window to populate before tuning; the
report window is tenant-dependent — **verify** your retention.

## 2.5 Simulation / test mode available on each policy being tuned (category GR6)
**Description:** Each capability's **non-enforcing** mode: DLP **`TestWithNotifications` /
`TestWithoutNotifications`**, auto-labeling **`TestWithoutNotifications`** (simulation), and, for
insider-risk and alert policies, the ability to observe without acting. Tuning is **always** validated
in these modes before re-enforcing.
**Why required:** DLP/label/insider-risk changes are high-impact; the house model requires **pilot in
simulation/test first** so a mis-tuned rule cannot block or mislabel real content.
**How to verify:** `Get-DlpCompliancePolicy | Select Name,Mode` shows the mode; auto-labeling policies
expose a simulation state; alert policies can be set non-notifying.
**How to implement if missing:** If a policy cannot be placed in a test mode, do not tune it live —
escalate to change control. `OPSOPT-Tune.ps1` moves a policy **into** simulation as its first action.

## 2.6 A named pilot scope and change control (category GR6)
**Description:** A limited **pilot scope** — the Entra group `Purview Tuning - Pilot` (users/sites the
tuned policy will apply to first) — plus a **change-control** path and named approver for the re-enforce
step.
**Why required:** Every tuning change is piloted on a bounded scope and validated before tenant-wide
re-enforcement; the re-enforce is a governed action.
**How to verify:** The group `Purview Tuning - Pilot` exists and is populated; a change window and
approver are named.
**How to implement if missing:** Create and populate the pilot group and agree the change window before
running `OPSOPT-Tune.ps1 -Commit`.

## 2.7 PowerShell toolchain — S&C PowerShell + Exchange Online (category GR3)
**Description:** A workstation with the **ExchangeOnlineManagement** module (provides both
`Connect-IPPSSession` for Security & Compliance PowerShell — home of `Get/Set-DlpCompliancePolicy`,
`Get/Set-DlpComplianceRule`, `Get/Set-AutoSensitivityLabelPolicy`, `Get/Set-ProtectionAlert`,
`Get-DlpDetailReport` — and `Connect-ExchangeOnline` for `Search-UnifiedAuditLog` /
`Get-AdminAuditLogConfig`), with a modern-auth / MFA-capable admin.
**Why required:** The five provided scripts and the exports run through these cmdlets.
**How to verify:** `Connect-IPPSSession` and `Connect-ExchangeOnline` succeed; `Get-Command
Get-DlpDetailReport` resolves (its availability is tenant/version-dependent — **verify**).
**How to implement if missing:** `Install-Module ExchangeOnlineManagement`, confirm modern-auth
sign-in, then run the scripts.

## 2.8 Business-workflow context for exceptions (so tuning removes noise, not signal)
**Description:** Knowledge of the **legitimate business workflows** that currently trip DLP/labeling
(e.g. a finance team that must email invoices, a legal team that handles contracts with ID-like
numbers) so exceptions are **justified**, not blanket.
**Why required:** A false positive is only false *relative to intended policy*. Adding an `ExceptIf`
without business context can silently open a real gap — a **determination** owned by compliance/data
owners, not the tuner.
**How to verify:** Each proposed exception has a named business owner and a written justification
captured in `.\OPSOPT-out`.
**How to implement if missing:** Confirm the workflow and owner **before** adding the exception; record
the justification with the change. The tuner supplies the technical method; compliance/data owners rule
on whether the exception is acceptable.
