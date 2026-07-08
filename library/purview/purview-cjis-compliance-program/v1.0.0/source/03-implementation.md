# 3. Implementation Guide — Microsoft Purview CJIS Compliance Program

Follow these steps **in order**. Work uses the **Microsoft Purview portal**
(`https://purview.microsoft.com`, or the GCC High / Azure Government equivalent), **Security & Compliance
PowerShell** (`Connect-IPPSSession` — labels, DLP, retention), **Exchange Online** (audit config), and
**Microsoft Graph** (licensing reads). Every write is gated: scripts run **read-only or `-WhatIf` by
default** and change state only with `-Commit`; no high-impact policy **enforces** without a separate,
explicit `-Enforce -Commit`. Artifact names follow the `<Purpose> – <Scope> – <Stage>` convention from
the Overview and are reused verbatim. **Capability availability, portal paths, and cmdlets are
plan-/cloud-dependent and the portal evolves — verify against your tenant and CJIS Security Policy
version with your CSA/CSO.**

> **Model:** confirm the authorized environment and licensing, map the CJIS policy areas to Purview
> controls, configure the CJI label/DLP/retention/audit in **simulation/test**, **pilot** on a bounded
> CJI scope, validate each control's technical state, then expand to enforcement and produce the
> audit-evidence package. Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate →
> Expand.** **Control satisfaction, the retention schedule, and environment authorization are CSA /
> auditor / records determinations throughout — this guide provides the technical method and evidence.**

---

## Step 0 — Confirm the authorized environment (Assess — gate before anything else)
1. With your **CSA/CSO** and Microsoft account team, confirm the tenant is in a **CJIS-authorized cloud**
   (**GCC High** / **Azure Government**) and the **CJIS Security Addendum** is in place (Requirement 2.1).
2. Run `CMPCJIS-Discovery.ps1` (read-only) — it reports **indicative** environment/licensing hints but
   **cannot attest CJIS authorization**; that is the CSA's determination.
3. **Pass/fail gate:** the environment and agreements are confirmed by the CSA/CSO. **Do not configure
   CJI controls in a non-authorized tenant.** Fail → stop and engage CSA/CSO/Microsoft first.

## Step 1 — Assess licensing and current state (Assess)
1. Run `CMPCJIS-Discovery.ps1`. It reports: subscribed SKUs and which CJI-control capabilities are
   licensed (labels+encryption, DLP, retention, **Audit Premium**, Insider Risk); the existing
   CJI-relevant labels/DLP/retention; the **unified audit logging** state; and whether a **CJIS
   assessment template** is visible in Compliance Manager (flagged **verify** — availability differs in
   GCC High). Save this as the `CJIS Discovery – Tenant – Baseline` snapshot.
2. **Pass/fail gate:** the baseline is captured and the licensing gaps for any in-scope control are known
   (assign the plan, or record the control as **deferred — not licensed**). Fail → resolve licensing
   before mapping.

## Step 2 — Map CJIS policy areas to Purview controls (Design)
1. With the control-map owner and the CSA/auditor (Requirement 2.6), build the `CJIS Control Map –
   Purview – Baseline`: for each in-scope **CJIS Security Policy area** (auditing & accountability, access
   control / information flow, information/system protection, media protection/records, personnel/insider
   — **verify area numbers against your policy version**), record the **Purview capability** that
   contributes and the **specific object** that will implement it (`CJI – Protected – Label`, `CJI
   Protection – Exfiltration – Policy`, `CJI Records – Retention – Policy`, audit configuration).
2. Mark each mapping's **status** (in scope / deferred — not licensed / covered elsewhere) and its
   **owner**. **The control-satisfaction determination stays with the CSA/auditor** — the map records the
   technical method and evidence, not the judgement.
3. **Pass/fail gate:** every in-scope policy area maps to a named Purview object and owner; the CSA/auditor
   has reviewed the mapping approach. Fail → complete the map before configuring.

## Step 3 — Define the CJI classification scheme (Design)
1. With the agency's records/security owners (Requirement 2.4), define the `CJI – Protected – Label`
   taxonomy and any **custom Sensitive Information Types** for CJI identifiers — **the specific
   identifiers come from the agency**, not invented here. Decide the label's **encryption** and access
   scope (which groups may access CJI).
2. Record the scheme in the control map. `CMPCJIS-ScopeCheck.ps1` lists existing labels/SITs/workloads to
   build on and confirm the in-scope denominators.
3. **Pass/fail gate:** the label taxonomy, encryption/access intent, and any custom SITs are defined and
   agreed. Fail → complete the scheme before creating objects.

## Step 4 — Configure the controls in simulation/test (Configure → Pilot)
1. Confirm **unified audit logging** is on (Requirement 2.5): `CMPCJIS-Configure.ps1 -EnableAudit -WhatIf`
   → review → `-EnableAudit -Commit` (this enables the source audit trail — it is not a user-impacting
   content policy).
2. Scaffold the CJI label and policies **safe-first**:
   `CMPCJIS-Configure.ps1 -Scope Pilot -WhatIf` prints the exact `New-Label` / `New-DlpCompliancePolicy`
   (**Test mode**) / `New-RetentionCompliancePolicy` (**staged/disabled**) it would run. Review every
   line — confirm the DLP is **test/simulation mode**, the label encryption/access scope matches the
   design, and the scope is the **pilot** set (not tenant-wide).
3. Apply safe-first: re-run with `-Commit`. Result: `CJI – Protected – Label` exists with encryption but
   is **unpublished/pilot-scoped**; `CJI Protection – Exfiltration – Policy` exists in **test/simulation
   mode**; `CJI Records – Retention – Policy` exists **staged/disabled**. **No enforcement yet.**
4. **Pass/fail gate:** `CMPCJIS-Discovery.ps1` shows the pilot objects present in the intended safe-first
   state. **Rollback:** `CMPCJIS-Configure.ps1 -Scope Pilot -Remove -Commit` removes the objects the
   program created (it only touches its own named objects; it does not delete pre-existing policies).

## Step 5 — Pilot on the bounded CJI scope (Pilot)
1. Publish the label / target the DLP+retention to the `CJIS Pilot – CJI Scope – Stage1` population only
   (Requirement 2.7). Generate benign in-scope CJI-like activity and review the **DLP test/simulation
   results** in the portal with the agency's **security officer** — this is where an over-broad or
   mis-scoped rule is caught **before** it enforces. **Verify the simulation view/behavior in your
   tenant.**
2. Confirm CJI-touching activity is appearing in the **audit log** for the pilot scope.
3. **Pass/fail gate:** the pilot label applies, the DLP simulation matches CJI as intended (no material
   false-positives/negatives the officer rejects), retention is staged correctly, and audit captures the
   activity. Fail → tune the label/DLP/scope and re-pilot.

## Step 6 — Validate the controls and role separation (Validate)
1. Run the Testing Guide (`05-testing.md`). Run `CMPCJIS-Validate.ps1` (read-only): it confirms unified
   audit logging is on, each mapped control's Purview object exists and is in the expected state (label
   encrypts, DLP in test mode, retention staged), the **audit-retention** target is met (or flagged for
   Audit Premium), and **separation of duties** holds — a **technical** pass/fail, not an adequacy
   judgement.
2. **Pass/fail gate:** validation is technically green for the pilot and role separation holds. Fail →
   correct the control and re-validate. **Whether the controls are *sufficient* for CJIS is the
   CSA/auditor's determination.**

## Step 7 — Produce the formal-audit evidence package (Validate → Expand)
1. Run `CMPCJIS-Report.ps1` (read-only) to produce `CJIS Evidence – Formal Audit – Package` (CSV + HTML):
   the control map with, per control, the implementing Purview object, its current state, and the audit
   references — the repeatable evidence the auditor/CSA reviews (Requirement 2.8). Optionally align it to
   the `CJIS Assessment – Compliance Manager – Baseline` where the assessment template is available.
2. **Pass/fail gate:** the evidence package is produced, accurate, and delivered via the secured channel.
   Fail → correct the underlying control/evidence and regenerate.

## Step 8 — Expand to enforcement under change control (Expand — gated)
1. Only after Steps 5–7 pass and with CSA/change approval, promote the pilot controls to enforcement:
   `CMPCJIS-Configure.ps1 -Scope Pilot -Enforce -WhatIf` → review → `-Enforce -Commit`. This publishes
   the label, moves the DLP policy to **Enable (enforce)**, and applies retention — the one step that
   turns on real user/data impact, separate from the safe-first deploy by design. Then widen the scope to
   the full CJI estate and repeat Steps 4–7 for the full set.
2. Operate the program as a rhythm: schedule the read-only chain (`CMPCJIS-Discovery.ps1` →
   `CMPCJIS-Validate.ps1` → `CMPCJIS-Report.ps1`) so control **drift** and evidence are current for each
   audit cycle; re-check licensing/environment when plans or the CJIS Security Policy version change.
3. **Pass/fail gate:** the CJI controls enforce cleanly on the full scope, validation stays green, and a
   current evidence package exists for the formal audit. **Rollback:** re-run without `-Enforce`
   (`-Commit`) to return DLP to test mode / unpublish the label / stage retention; or `-Remove -Commit`
   to delete the managed objects.

---

### What this guide does NOT do
- **Attest CJIS compliance or authorize the environment.** The **CSA/CSO/auditor** determine control
  satisfaction and environment authorization; this guide configures technical controls and produces
  evidence.
- **Define the CJI identifiers or the retention schedule.** CJI identifiers come from the **agency**; the
  records retention **schedule** and regulatory applicability are **records/legal/CJIS determinations**.
- **Make insider-risk determinations.** Where Insider Risk is used, only aggregate/de-identified
  indicators are handled under role separation; outcomes are **deferred to HR/legal and CJIS governance**.
