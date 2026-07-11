# 5. Testing — Security Optimization Assessment: Defender for Office 365

Because this is a **read-only** assessment, "testing" proves two things: the assessor has **read-only** access (and no write), and the **report is accurate** (it reconciles with the Defender portal and Exchange configuration). Run these gates in order; each has an explicit **pass/fail**.

## Gate 1 — Read-only access proven (run `SOAMDO-Validate.ps1`)
**Procedure:** Run `SOAMDO-Validate.ps1` with the assessor identity.
**Pass:** Success on all of — `Connect-ExchangeOnline` / `Connect-IPPSSession`; read an anti-phish, Safe Links, Safe Attachments, anti-spam and anti-malware policy; read the **preset** rules; read **transport rules** and the **Tenant Allow/Block List**; run a Graph hunting query; and it confirms **no write role/scope** is present.
**Fail:** Any read fails (fix access per R2–R4) **or** a write capability is detected (reduce the assessor to a read-only role — an assessment must not be able to change policy).

## Gate 2 — Discovery completeness (run `SOAMDO-Discovery.ps1`)
**Procedure:** Run discovery; inspect the run folder.
**Pass:** Raw outputs exist for every area — anti-spam/malware/phish, Safe Links, Safe Attachments, preset rules, connection filter, DKIM, **transport rules**, **Tenant Allow/Block List**, Secure Score, and `EmailEvents` signals — and policy counts match the portal's Threat policies view.
**Fail:** An area file is empty. A missing **transport rules** or **Tenant Allow/Block List** file is the most dangerous — it makes the report look falsely clean. Confirm the read role (R3) and re-run before trusting bypass results.

## Gate 3 — Effective-policy and coverage are real (run `SOAMDO-Coverage.ps1`)
**Procedure:** Run coverage with the **expected mailbox count** (R5).
**Pass:** Coverage resolves the **effective** policy per recipient using policy **priority** (not just "a policy exists"), names recipients covered by nothing/weak policy, and produces a consolidated **bypass** list (allow lists + transport rules + connection filter + disabled protections).
**Fail:** Coverage reports "policy exists" without resolving priority/recipient scope, or the bypass list omits transport rules — re-check discovery inputs and re-run.

## Gate 4 — Scoring is defensible (run `SOAMDO-Assess.ps1`)
**Procedure:** Run scoring; open the scorecard CSV.
**Pass:** Every check has **Pass/Partial/Fail/N-A**, a **severity** on each non-pass, the **baseline name** stamped in, and the weighted posture score computes. MDO-only checks on an EOP-only tenant are **N-A**, not Fail. Bypass findings carry high severity.
**Fail:** Checks unscored, severities missing, or MDO-only features scored Fail on an unlicensed tenant (should be N-A findings).

## Gate 5 — Report reconciles with the portal (run `SOAMDO-Report.ps1`)
**Procedure:** Generate the report; spot-check the **top three** findings.
**Pass:** Each matches the portal/Exchange config — e.g. a Safe Attachments policy the report shows as **Monitor** reads Monitor in the portal; a transport rule flagged as setting **SCL -1** reads that in Mail flow → Rules; an impersonation-protection gap matches the anti-phish policy. Findings sorted High → Low with evidence and remediation pointers.
**Fail:** A spot-checked finding does not match — re-run discovery for a fresh snapshot and confirm scope before delivery.

## Gate 6 — Repeatability (trend)
**Procedure:** Re-run the full sequence against the same scope file into a new dated folder.
**Pass:** Runs are comparable (same checks, same baseline); the posture score trends and the bypass list can be shown shrinking as remediation lands.
**Fail:** Scope or baseline drifted — pin them in the scope file.

> These gates test the **assessment**, not the tenant's email security. A low score with a long bypass list is a *successful* assessment — it found the real gaps. The failure conditions are about the assessment's own accuracy and read-only guarantee.
