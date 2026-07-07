# Testing & Validation

Validate the operating model before (Pilot) and after (Expand) rollout. Each procedure states the
**expected pass/fail** signal. These map to the pass/fail gates in the Implementation Guide
(`Validation Gates – Messaging – Validate`). Run the read-only scripts first — they are safe by default.

## T1. Tooling connects and reads (pre-flight)

**Procedure**
1. `Connect-ExchangeOnline` with an L2 and an L3 account.
2. Run `.\Get-ServiceHealthTriage.ps1 -CheckScope` (the scope/health helper) to confirm each account's
   effective role/permission posture and module versions.
3. Run `.\Get-ServiceHealthTriage.ps1` after `Connect-MgGraph -Scopes "ServiceHealth.Read.All"`.

**Expected — PASS:** both accounts connect; the scope helper reports the expected least-privilege posture
(L2 read/triage, L3 change-capable); the Service Health helper returns the current Exchange Online
service-issue/advisory list (or an explicit "no active issues"). **FAIL:** a connect error, a missing
module, or a permission the tier should not have (over-privileged L2).

## T2. Priority matrix produces consistent triage

**Procedure**
1. Take 10 recent, already-closed tickets of mixed impact.
2. Have two analysts independently assign priority using `Priority Matrix – Messaging – Design`.

**Expected — PASS:** ≥ 8/10 priorities agree between analysts **and** match the blast-radius definition
(org/domain = P1, group/site = P2, single user = P3, how-to = P4). **FAIL:** frequent disagreement →
the matrix wording needs tightening before pilot.

## T3. Escalation criteria are followed (Gate G2)

**Procedure**
1. Sample escalated tickets from the pilot window.
2. For each, confirm a **defined L2→L3 criterion** (1.2) was actually met and the **diagnostic bundle**
   was attached.

**Expected — PASS:** escalation accuracy ≥ target; no "escalated because stuck" without a criterion; every
escalation carries the bundle. **FAIL:** premature/missed escalations, or bundles missing → coach and
re-measure.

## T4. Incident lifecycle completeness

**Procedure**
1. Sample closed pilot incidents.
2. Confirm each has: a logged record, a category, a priority, a resolution note with the **KB article
   used**, a closure code, and (where required) CSAT captured.

**Expected — PASS:** all sampled incidents complete on every field. **FAIL:** missing categories,
priorities, or closure codes → metrics will be unreliable; fix the lifecycle enforcement.

## T5. Service-availability first step works

**Procedure**
1. During a suspected outage (or a drill), run the on-call **service-availability first step**: portal
   Service Health + `.\Get-ServiceHealthTriage.ps1`.
2. Confirm the ticket is annotated with the correct call — *"Microsoft-side, MS incident <ID>"* vs
   *"local issue, proceed"*.

**Expected — PASS:** the team reaches an "is it us or Microsoft?" determination within the target time and
records the MS incident ID when one matches. **FAIL:** the team chased a local root cause while an active
MS incident existed (or vice-versa) → reinforce the first-step discipline.

## T6. Problem loop and root-cause (Gate G4)

**Procedure**
1. Run `.\Find-RecurringMessagingIncidents.ps1 -TicketCsv .\tickets.csv`.
2. Confirm the top candidate has a **Problem record** with a documented **root-cause** (or a published
   **Known-Error + workaround** if the fix is pending).

**Expected — PASS:** the top repeat-incident candidate is under problem management with root-cause or a
known-error workaround published to the KB. **FAIL:** repeat incidents with no Problem record → the loop
isn't running.

## T7. Metrics report is correct and reproducible

**Procedure**
1. Run `.\Get-MessagingSlaMetricsReport.ps1 -TicketCsv .\tickets.csv` on a known export.
2. Manually spot-check a handful of tickets against the reported SLA attainment / FCR / reopen rate.

**Expected — PASS:** the script's SLA attainment, FCR, CSAT, and reopen rate match the manual spot-check;
re-running on the same CSV yields identical numbers (deterministic). **FAIL:** mismatch → check the CSV
column mapping (the script's `-ColumnMap` / defaults) against your ITSM export.

## T8. Mailbox / mail-flow health-check for common tickets

**Procedure**
1. For a representative "user can't send/receive" ticket, run
   `.\Test-MailboxMailFlowHealth.ps1 -Identity user@contoso.com` (read-only).

**Expected — PASS:** the check returns the mailbox's key health facts (mailbox exists/type, primary SMTP,
litigation/retention hold state, forwarding, recent message-trace summary for the user) so L2 can
diagnose from one place. **FAIL:** the script errors on a valid mailbox → verify permissions/module.

## T9. KB coverage and currency (Gate G5)

**Procedure**
1. For each ticket **category** (2.1), confirm a current KB article exists with an **owner** and a
   **next-review date** not in the past.

**Expected — PASS:** every category has a current, owned article. **FAIL:** a category with no article or
a stale (past-review) article → assign an owner and update before Expand.

## T10. Overall validation gate roll-up

**Procedure** — Consolidate T1–T9 into the gate sheet: G1 (SLA), G2 (escalation accuracy), G3 (reopen ≤
baseline), G4 (problem loop), G5 (KB coverage + CSAT).

**Expected — PASS:** all five gates pass → proceed to **Expand**. **FAIL:** any gate fails → remain in
**Pilot**, remediate, re-measure.
