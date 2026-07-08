# 6. Troubleshooting Guide — CJIS DLP Pack (Microsoft Purview)

Field issues and fixes, in the order you'll hit them. Symptom → likely cause → remediation. When in
doubt, stay in **simulation/test** and re-tune rather than enforcing.

## Connection & permissions

**"Not connected to Security & Compliance PowerShell" / `Get-DlpCompliancePolicy` not found.**
- Cause: no `Connect-IPPSSession`, or the `ExchangeOnlineManagement` module isn't installed.
- Fix: `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; `Connect-IPPSSession` with a
  modern-auth/MFA admin (Requirement 2.3). The DLP cmdlets exist only inside that session.

**"Access denied" reading or creating DLP policies.**
- Cause: the account lacks a DLP-capable role.
- Fix: add it to **Compliance Administrator** / **Compliance Data Administrator** or a role group with
  **DLP Compliance Management** (Requirement 2.2). Keep DLP admin separate from matched-content reviewer.

**Graph evidence report: "Not connected to Graph" / consent error.**
- Cause: no `Connect-MgGraph`, or `SecurityEvents.Read.All` not consented.
- Fix: `Connect-MgGraph -Scopes 'SecurityEvents.Read.All'` (or `SecurityAlert.Read.All`); a Global Admin
  grants admin consent once if required (Requirement 2.7).

## Detection (the most common tuning problem)

**Policy matches routine documents (false positives / over-matching).**
- Cause: detection too broad — a generic SIT (e.g. SSN) matching without CJI context, confidence too low,
  or instance count too low.
- Fix: raise the SIT **confidence** (Medium→High), increase **MinCount**, and require **keyword evidence**
  (`CJI Keyword Dictionary – CJIS – Terms`) so an identifier only matches in CJI context. Re-test against
  the routine-document set (Testing Test 3). This is expected tuning — do it in simulation, not enforce.

**Real CJI is not matched (false negatives / under-matching).**
- Cause: detection too narrow — regex doesn't cover the identifier format, dictionary missing terms, or
  threshold too high.
- Fix: broaden the custom SIT regex / keyword dictionary, or lower confidence/instance count; verify the
  synthetic-CJI test document matches. Where licensed, use **EDM** against a known CJI export for
  high-precision matching of specific records.

**`DLPCJIS-Report.ps1` shows zero matches during an active simulation.**
- Cause: under-matching detection (above), the workload is out of scope, or DLP alert latency.
- Fix: confirm detection with the synthetic-CJI doc; confirm scope with `DLPCJIS-Validation.ps1`; allow
  time — DLP events/alerts can take several minutes to surface. Zero matches does **not** prove no CJI
  moved; verify detection first.

## Policy creation & mode

**`DLPCJIS-Set-Policy.ps1` printed a WHATIF message and made no change.**
- Cause: working as designed — no `-Commit`. Safe-by-default forces `-WhatIf` unless you pass `-Commit`.
- Fix: re-run with `-Commit` (in a change window for enforce).

**"Create must use a TEST mode (simulation-first)."**
- Cause: you passed a non-test `-Mode` to the create path.
- Fix: create with `-Mode TestWithNotifications` (or `TestWithoutNotifications`), pilot, then
  `-PromoteToEnforce` to enable. The tool intentionally will not create straight to enforce.

**Policy already exists warning on create.**
- Cause: the pilot policy is already there.
- Fix: don't recreate — change mode with `-PromoteToEnforce` / `-Disable`, or tune the rule in the portal.
  Use `DLPCJIS-Discovery.ps1` to see the current state.

**Users are blocked while the policy is supposedly "in test."**
- Cause: the policy is actually in `Enable`, not a `Test*` mode.
- Fix: `Get-DlpCompliancePolicy` to confirm the mode; roll back immediately with
  `DLPCJIS-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications` via the portal), then
  re-pilot.

## Scope & coverage

**Endpoint DLP shows unavailable / devices not protected.**
- Cause: Endpoint DLP requires **E5 / E5 Compliance** *and* onboarded devices; onboarding is separate.
- Fix: confirm licensing (`DLPCJIS-Scope-Health.ps1`), onboard devices (Purview → `Settings → Device
  onboarding`, verify path), then add `-IncludeEndpoint`. Until then, record endpoints as a **coverage
  gap** — do not assume USB/print/upload is protected.

**A workload isn't being protected even though the policy exists.**
- Cause: the workload isn't in the policy's scope, or content hasn't been re-evaluated yet.
- Fix: confirm scope with `DLPCJIS-Validation.ps1`; SharePoint/OneDrive DLP evaluates on crawl/change and
  can lag; test with a fresh upload of the synthetic-CJI doc.

## Enforcement & change control

**Enforcement blocks legitimate case work.**
- Cause: promoted before detection was tuned, or the action is too aggressive.
- Fix: **roll back now** — `DLPCJIS-Set-Policy.ps1 -Disable -Commit` (or `-Mode TestWithNotifications`) —
  then re-tune in simulation. Consider **block-with-override + justification** before hard block for
  borderline actions (Best Practices).

**Drift check reports an unexpected mode change on the CJI policy.**
- Cause: someone changed the policy outside change control (e.g. it silently moved to `Disable`).
- Fix: treat as a change-control incident; reconcile with `Change Record – CJIS DLP – ChangeControl`,
  restore the intended mode, and re-baseline (`DLPCJIS-Discovery.ps1 -SaveBaseline`) only after approval.

## Licensing & portal drift

**A cmdlet, SIT, or portal path in the guide isn't present in your tenant.**
- Cause: the capability is plan-gated or in preview, or the portal changed.
- Fix: this is expected — Purview features are **licensing-dependent** and the portal **evolves**. Confirm
  capability and the current portal path for **your** tenant; where a surface isn't licensed, scope the
  program to what you can enforce and record the gap.

## When to stop and escalate (defer, don't guess)
- **Is this data actually CJI?** → your **CSO/TAC / compliance authority**, not DLP tuning.
- **CJI retention / records / legal hold?** → **records / legal**.
- **CJIS audit conclusion, personnel screening, FIPS encryption, physical media?** → the broader **CJIS
  program owners**. This pack delivers and evidences the DLP control; the determinations are theirs.
