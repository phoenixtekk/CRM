# 5. Testing & Validation — Secure Microsoft 365 Copilot: Oversharing & SharePoint Permissions Remediation

Validate the build against explicit **pass/fail gates** before expanding beyond the pilot ring. Discovery,
validation, and reporting are automated; the decisive Copilot-side check is a short manual test. Run the
scripts read-only (they change nothing) and record each result against the named object.

> **Principle:** the pilot gate is *both* a measured reduction in the oversharing signal **and** a
> Copilot-side confirmation that a user who should not have access can no longer surface the content —
> with no legitimate collaboration broken. Do not enforce broadly until every gate below passes.

## Test 1 — Scope & connections (Step 0)
- **Procedure:** Run `CPLTSHARE-Discovery.ps1 -ScopeOnly`.
- **Pass:** Graph/PnP sign-ins succeed; module and SAM availability are reported; auditing is on; pilot
  ring and change window are agreed.
- **Fail:** A sign-in fails or auditing is off → resolve (Requirements 2.1–2.3, 2.8) before proceeding.

## Test 2 — Oversharing discovery produced (Step 1)
- **Procedure:** Run `CPLTSHARE-Discovery.ps1`; open `Oversharing Discovery – Estate – Assess`.
- **Pass:** The export lists in-scope sites with an oversharing signal (EEEU / anonymous links / broad
  links / large membership / stale access); the top targets can be named; where SAM is licensed, the
  numbers reconcile with the **Data Access Governance** reports.
- **Fail:** Empty or partial export → confirm read scope (`Sites.Read.All`) and site enumeration; fall
  back to the SharePoint admin **Active sites** export as the site list.

## Test 3 — Reduction list & owner decisions (Step 2)
- **Procedure:** Run `CPLTSHARE-Remediation.ps1 -Action BuildList -Name "Site Access Reduction – Sites – Pilot"`.
- **Pass:** A ranked per-site action list is produced; owner decisions (audience, grants/links to remove,
  RAC/RCD) are recorded for each pilot site.
- **Fail:** No owner for a site → escalate to name one before remediating (Requirement 2.5).

## Test 4 — Remediation preview is safe (Step 3)
- **Procedure:** Run `CPLTSHARE-Remediation.ps1 -Action ReduceAccess -Name "Site Access Reduction – Sites – Pilot" -WhatIf`.
- **Pass:** The preview lists exactly which grants/links **would** be removed and changes nothing; the set
  matches the owner-approved decisions.
- **Fail:** The preview would touch a site/grant not approved → correct the list before any `-Commit`.

## Test 5 — Pilot access reduced (Step 3)
- **Procedure:** After `-Commit` (and manual RAC/RCD/RSS as agreed), re-run `CPLTSHARE-Discovery.ps1`
  scoped to the pilot sites.
- **Pass:** EEEU/org-wide grants and anonymous/broad links are gone on the pilot sites; RAC limits the
  agreed sites to a named group; RCD/RSS are in the recorded state.
- **Fail:** A broad grant/link remains → re-check the site's **Manage access** and re-run remediation.

## Test 6 — Copilot honors the corrected permissions (Step 5) — decisive
- **Procedure:** Run `CPLTSHARE-Validate.ps1`, then perform the manual `Copilot Permission Verification –
  Pilot – Validate` check:
  1. As a **test user who should NOT have access** to a remediated site, prompt Copilot for content that
     was previously reachable, and search for a known phrase from that content.
  2. As a **legitimate user**, confirm the content they *should* see is still reachable.
- **Pass:** The unauthorized user gets **no** access to the remediated content via Copilot or search; the
  legitimate user's access is intact; `CPLTSHARE-Validate.ps1` shows the oversharing signal lower than the
  baseline and RAC/RCD/RSS in the expected state.
- **Fail:** The unauthorized user can still surface the content → confirm the grant/link was actually
  removed, allow for Copilot re-indexing latency (Troubleshooting), and consider interim RCD/RSS fencing;
  do not expand until this passes.

## Test 7 — No legitimate collaboration broke (Step 5)
- **Procedure:** With site owners, spot-check that pilot-site members can still open, edit, and share as
  intended.
- **Pass:** Owners confirm expected access is intact; no broken links or lost membership for legitimate
  users.
- **Fail:** A legitimate access broke → restore it from the discovery before-state and re-scope the
  reduction.

## Test 8 — Before/after evidence & recurring review (Step 6)
- **Procedure:** Run `CPLTSHARE-Report.ps1`; open `Oversharing Remediation Report – Tenant – Expand`;
  confirm the recurring `Oversharing Review – Tenant – Recurring` chain is scheduled.
- **Pass:** The report shows the before/after oversharing, controls applied and their state, and residual
  risk; interim RSS/RCD removed where access is fixed; the read-only review chain is scheduled.
- **Fail:** Report incomplete or interim controls still in place without justification → complete
  remediation and re-run.

## Evidence to retain
- `Oversharing Discovery – Estate – Assess` (baseline) and the post-remediation re-measure.
- `Copilot Permission Verification – Pilot – Validate` (both the script output and the manual test
  outcomes).
- `Oversharing Remediation Report – Tenant – Expand` (the before/after sign-off record).
- The recorded owner decisions from Step 2 (the data-owner determinations behind each change).
