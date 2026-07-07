# 5. Testing & Validation

Run these after configuration and before each expansion. Each test states the procedure and the
**expected pass/fail** signal. The reusable check is `TEAMSCOMP-Validation.ps1`; the tests below name
the exact artifacts from the Implementation Guide.

---

## Test 1 — IB segments and policy exist and are Active
- **Procedure:** In Security & Compliance PowerShell:
  `Get-OrganizationSegment | Select Name, UserGroupFilter` and
  `Get-InformationBarrierPolicy -Identity "IB Policy – GroupA-blocks-GroupB – Pilot" | Select Name, State`.
- **Pass:** both segments `IB Segment – GroupA – Prod` and `IB Segment – GroupB – Prod` are listed with
  the expected filter; the policy `State` is **Active**.
- **Fail:** a segment is missing, the filter is wrong, or `State` is `Inactive` → revisit Stage 2 IB.

## Test 2 — IB application completed
- **Procedure:** `Get-InformationBarrierPoliciesApplicationStatus`.
- **Pass:** the latest application status is **Completed** with no failed recipients.
- **Fail:** status `Failed`/`In progress` past the expected window → inspect the error, confirm the
  segment attribute is populated, re-run `Start-InformationBarrierPoliciesApplication`.

## Test 3 — IB blocks communication (functional, in the Teams client)
- **Procedure:** As a **GroupA** pilot user, try to (a) start a chat with a **GroupB** pilot user,
  (b) search for that user, and (c) add them to a team.
- **Pass:** all three are blocked / the GroupB user is not discoverable; `Get-InformationBarrierRecipientStatus
  -Identity groupa-user@contoso.com` shows the expected policy.
- **Fail:** communication is allowed → confirm scoped directory search is enabled (Requirements item 5),
  the users carry the segment attribute, and application completed (Test 2).

## Test 4 — Teams retention policy enabled with correct rule
- **Procedure:**
  `Get-RetentionCompliancePolicy -Identity "Retention Policy – Teams Chat+Channel – Pilot" | Select Name, Enabled` and
  `Get-RetentionComplianceRule -Policy "Retention Policy – Teams Chat+Channel – Pilot" | Select Name, RetentionDuration, RetentionComplianceAction`.
- **Pass:** policy `Enabled = True`; rule shows the compliance-defined duration and action
  (for example `2555` / `KeepAndDelete`); policy scoped to the **Teams** locations only.
- **Fail:** disabled, wrong duration/action, or the policy also contains non-Teams locations → fix per
  Stage 2 retention (Teams locations must be in their own policy).

## Test 5 — Teams DLP policy present with the audit/enforce mode intended
- **Procedure:**
  `Get-DlpCompliancePolicy -Identity "DLP Policy – Teams Sensitive – Pilot" | Select Name, Mode` and
  `Get-DlpComplianceRule -Policy "DLP Policy – Teams Sensitive – Pilot" | Select Name, BlockAccess, ContentContainsSensitiveInformation`.
- **Pass (audit gate):** `Mode` is a **Test** value and the rule references the approved SITs with
  `BlockAccess $false`.
- **Pass (post-gate, enforce):** `Mode = Enable`; `BlockAccess` matches the decision.
- **Fail:** the policy is enforcing before the audit gate passed, or references SITs not approved by
  the Purview owner → return to test mode and re-run the audit gate.

## Test 6 — Teams DLP functional check (test then enforce)
- **Procedure:** In a pilot Teams chat, send a message containing a **synthetic** matched value (for
  example a test credit-card number from Microsoft's SIT test data — never real PII).
- **Pass (test mode):** the event appears in Purview **Activity explorer / DLP alerts**; the message is
  **not** blocked.
- **Pass (enforce mode):** the sender sees the policy tip / the message is blocked per `BlockAccess`.
- **Fail:** no event logged in test mode → confirm the `-TeamsLocation` scope covers the pilot chat and
  the SIT actually matches your test value.

## Test 7 — Automated validation report
- **Procedure:** `powershell -ExecutionPolicy Bypass -File .\TEAMSCOMP-Validation.ps1`.
- **Pass:** every expected named artifact (segments, IB policy Active, retention policy Enabled + rule,
  DLP policy + rule mode) reports **PASS**; scoped directory search reports enabled.
- **Fail:** any **FAIL** line → the message names the artifact and expected state; remediate and re-run.

## Test 8 — No collision with the broader Purview program
- **Procedure:** Confirm no **other** retention policy already covers the same Teams locations for the
  pilot scope (`Get-RetentionCompliancePolicy` review), and that the Teams DLP reuses approved SITs/labels
  rather than new ones.
- **Pass:** Teams retention/DLP are additive to the Purview program, no double-coverage conflict.
- **Fail:** overlapping Teams retention or a duplicated label/SIT → reconcile with the Purview owner
  before expanding.
