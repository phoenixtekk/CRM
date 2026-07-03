# Implementation Guide — Microsoft 365 Security Baseline & Audit Readiness (Government / GCC High)

This guide takes you, step by step, through raising and documenting your Microsoft 365 security
posture on a **GCC High** tenant using **Microsoft Secure Score** and **Microsoft Purview Compliance
Manager**. Every step uses the **sovereign `*.us` portals** and the **US Gov Graph endpoints**. Do the
phases in order; each phase ends at a **gate** you must pass before continuing.

> **Before you start.** Complete `02-requirements.md`. Have your operator account signed in against
> `login.microsoftonline.us`, and have the Microsoft Graph PowerShell SDK ready to connect with
> `-Environment USGov` (R6). Keep the named pilot group **`SEC-Baseline-Pilot`** handy (R9).
>
> **GCC-High reality check (read once):** the parity gaps in `gcc-high-parity-notes.md` are cited from
> Microsoft docs. Where a Commercial improvement action simply does not appear in your GCC High Secure
> Score, that is expected — do not chase a recommendation that isn't there. Treat anything this guide
> marks **"verify for GCC High"** as something to confirm live in your tenant, not assume.

---

## Phase 0 — Assess (read-only discovery)

**Goal:** capture the starting state of the GCC High tenant with zero changes.

1. **Open the sovereign Defender portal.** Browse to **`https://security.microsoft.us`**. In the left
   navigation, open **Microsoft Secure Score**. Note the current **score**, the **percentage**, and
   the number of **improvement actions**. Screenshot the overview — this is your **baseline**.
   - *GCC-High caveat:* your achievable total and action list will differ from a Commercial tenant
     because **some Secure Score recommendations are not surfaced in GCC High** (parity notes). Do not
     compare your number to a Commercial benchmark.

2. **Open the sovereign Purview portal.** Browse to **`https://compliance.microsoft.us`** →
   **Compliance Manager**. Note your **overall compliance score** and which **assessments** already
   exist. Screenshot the overview.

3. **Run read-only discovery.** From PowerShell, run:
   ```
   powershell -ExecutionPolicy Bypass -File .\M365SECG-Discovery.ps1
   ```
   It connects with **`-Environment USGov`**, then inventories: Secure Score (current + control
   profiles), licensing, admin role assignments, Conditional Access policies, and MFA/registration
   posture — all read-only. Save its output as your evidence baseline.

**Gate 0:** You have a screenshot + script capture of the **current** Secure Score, the current
Compliance Manager score, and the tenant inventory. Nothing has been changed.

---

## Phase 1 — Configure (stage the baseline, create named objects)

**Goal:** decide the target baseline and create the objects you'll reuse, without applying anything
tenant-wide yet.

1. **Confirm / create the pilot group.** In **`https://entra.microsoft.us`** → **Groups**, confirm
   **`SEC-Baseline-Pilot`** exists (R9). If not, create it (**New group → Security**) or use
   `M365SECG-Set-ScopeTargeting.ps1` (defaults to `-WhatIf`; re-run with `-Execute` to apply).

2. **Pick your Compliance Manager assessment(s).** In **`compliance.microsoft.us`** → **Compliance
   Manager → Assessments → Add assessment**:
   - The **Microsoft Data Protection Baseline** is included for everyone — start here.
   - If you hold **G5 (Gov)** licensing and pursue defense work, add **CMMC** (Levels 1–5 are included
     with G5 Gov) and/or **NIST SP 800-171**. Name the assessment clearly (e.g.
     `GCCHigh-DPB-Baseline` or `GCCHigh-CMMC-L2`).
   - *GCC-High caveat:* a few Compliance Manager features (for example **alerts and notifications**,
     **recommended engine for bulk assessment creation**) are listed as *in development / rolling out*
     for GCC High — if you don't see them yet, that's expected (parity notes).

3. **Triage Secure Score improvement actions.** Back in **`security.microsoft.us`** → **Secure Score →
   Improvement actions**, sort by **points + impact**. Build a prioritized backlog of the actions that
   are **actually present** in your GCC High tenant. Favor high-value identity actions first (MFA for
   admins, block legacy authentication, admin role hygiene) — these move the score and reduce real
   risk fastest.
   - For each action, note whether it is configured via **Entra** (Conditional Access / auth methods),
     **Defender**, **Purview**, or **Intune** — and use the corresponding **`*.us`** portal.

4. **Write the change ticket** (R10) for the first batch of actions: approver, maintenance window,
   pilot scope = `SEC-Baseline-Pilot`, and a rollback step per action.

**Gate 1:** Pilot group exists; at least one Compliance Manager assessment is created and named; you
have a prioritized, GCC-High-real Secure Score backlog and an approved change ticket for batch 1.

---

## Phase 2 — Pilot (apply to the named pilot group only)

**Goal:** apply batch 1 of improvement actions to **`SEC-Baseline-Pilot`** only.

1. **Scope every change to the pilot group.** For actions delivered via Conditional Access or auth
   methods, in **`entra.microsoft.us`** create/edit the policy so its **assignment targets
   `SEC-Baseline-Pilot`**, not All users. Give each policy a clear, reusable name (e.g.
   `CA-Baseline-Admins-MFA`, `CA-Baseline-BlockLegacyAuth`).
   - *GCC-High caveat:* Conditional Access and authentication-method features generally reach GCC High,
     but confirm the **specific** control you need is present in your tenant before relying on it
     (**verify for GCC High**).

2. **Apply device/app actions to piloted devices.** For Intune-delivered actions, in
   **`intune.microsoft.us`** assign the configuration/compliance policy to `SEC-Baseline-Pilot`.
   - *GCC-High caveat:* **Microsoft Threat Experts** and **enterprise IoT** Defender features are
     **not available** in GCC High — do not stage improvement actions that depend on them; they won't
     appear or won't complete (parity notes).

3. **Record what you changed.** Keep the change ticket updated with the exact policy names and the
   pilot assignment.

**Gate 2:** Batch 1 actions are applied **only** to `SEC-Baseline-Pilot`. No All-users / tenant-wide
assignment has been made.

---

## Phase 3 — Validate (prove it worked, prove nothing broke)

**Goal:** confirm the pilot changes took effect and produced the intended posture change.

1. **Run validation.** From PowerShell:
   ```
   powershell -ExecutionPolicy Bypass -File .\M365SECG-Validation.ps1
   ```
   It reconnects with **`-Environment USGov`** and checks the pilot state: are the named CA policies
   present and enabled? Is the pilot group targeted? Have the expected control states flipped? It
   reports **PASS/FAIL per check**.

2. **Confirm in the UI.** In **`security.microsoft.us`** → **Secure Score → History**, confirm the
   score moved (Secure Score updates can lag up to ~24–48 hours; re-check the next day if needed —
   **verify for GCC High**, as Gov refresh cadence may differ). In **`compliance.microsoft.us`** →
   Compliance Manager, confirm improvement actions on your assessment show as implemented/tested.

3. **Confirm no user impact.** Verify pilot users can still sign in and reach their apps. If any pilot
   user is blocked, **execute the rollback** from the change ticket immediately, then diagnose (see
   `06-troubleshooting.md`).

**Gate 3:** Validation script reports PASS for batch 1; Secure Score/Compliance Manager reflect the
change; **no pilot user is locked out**.

---

## Phase 4 — Expand (controlled waves to the tenant)

**Goal:** widen scope beyond the pilot in gated waves.

1. **Widen scope one wave at a time.** Change the policy assignment from `SEC-Baseline-Pilot` to the
   next cohort (e.g. a department group, then all users). Use
   `M365SECG-Set-ScopeTargeting.ps1` to build/target the next group (defaults to `-WhatIf`; re-run
   with `-Execute` to apply).

2. **Re-validate at each wave.** Re-run `M365SECG-Validation.ps1` after each expansion. Do **not**
   proceed to the next wave until the current one passes and no lockouts are reported.

3. **Move to the next batch of improvement actions.** Repeat Phases 1–4 for the next prioritized batch
   from your Secure Score backlog.

4. **Produce the audit report.** When a milestone is reached, run:
   ```
   powershell -ExecutionPolicy Bypass -File .\M365SECG-Report.ps1
   ```
   It generates a point-in-time posture report (Secure Score summary, control states, assessment
   progress) suitable for handing to an auditor or leadership.

**Gate 4:** Each expansion wave passed validation with no lockouts; the report has been generated and
archived as evidence.

---

## Optional — Safe remediation via script

For a small set of common, well-understood improvement actions, `M365SECG-Remediation.ps1` can apply
changes through Graph. It **defaults to `-WhatIf`** (it only *previews* what it would do). Review the
preview, ensure the change is in your approved ticket and scoped to `SEC-Baseline-Pilot`, then re-run
with `-Execute` to apply. It connects with **`-Environment USGov`** and requests only the write scopes
it needs.

> **Never** run remediation with `-Execute` against All users on a first pass. Pilot → validate →
> expand, exactly as with portal changes.

---

## Ordering summary

| Phase | Portal(s) `*.us` | Script | Gate |
| --- | --- | --- | --- |
| 0 Assess | security, compliance | Discovery | Baseline captured, nothing changed |
| 1 Configure | entra, security, compliance | (Set-ScopeTargeting `-WhatIf`) | Objects + backlog + ticket ready |
| 2 Pilot | entra, intune | (Remediation `-WhatIf`→`-Execute`) | Applied to pilot only |
| 3 Validate | security, compliance | Validation | PASS, no lockouts |
| 4 Expand | entra, intune | Set-ScopeTargeting, Report | Each wave PASS, report archived |
