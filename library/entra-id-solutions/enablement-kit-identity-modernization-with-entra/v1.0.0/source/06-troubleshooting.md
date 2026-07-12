# 6. Troubleshooting — Enablement Kit: Identity Modernization with Entra

Common failures while working the labs, as **symptom → cause → fix**. These are lab-scoped issues;
production troubleshooting for each building block lives in that block's implementation solution.

## Scripts

### `Connect-MgGraph` fails or prompts endlessly
- **Symptom:** the discovery/validation/report scripts cannot connect to Graph.
- **Cause:** the `Microsoft.Graph` module is missing/old, or consent to the read scopes was declined.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and **accept** the requested
  read scopes (e.g. `Directory.Read.All`, `Policy.Read.All`, `AuditLog.Read.All`,
  `UserAuthenticationMethod.Read.All`). Confirm with `Get-MgContext`.

### "Insufficient privileges" running a read script
- **Symptom:** cmdlets return authorization errors.
- **Cause:** the signed-in operator lacks a directory-read role, or admin consent is required for a scope.
- **Fix:** sign in with an account holding at least a reader role (e.g. Global Reader / Security
  Reader). For scopes needing admin consent, have a Global Administrator consent once.

### `EKIDMOD-LabSetup.ps1` "made no changes"
- **Symptom:** the script reports what it *would* do but nothing is created.
- **Cause:** this is expected — it defaults to `-WhatIf` preview.
- **Fix:** re-run with `-Commit` to create the pilot group + sample users (or `-Remove` to tear down).

### `EKIDMOD-Validate.ps1` reports the pilot group missing after setup
- **Symptom:** validation FAILs on the pilot group right after creating it.
- **Cause:** directory replication / caching delay, or the group name does not match exactly.
- **Fix:** wait 1–2 minutes and re-run; confirm the group is named exactly
  `Identity Modernization – Pilot – Lab` (en dash, not hyphen, matters for name matching).

## Conditional Access labs

### A report-only policy is not showing any impact in logs
- **Symptom:** the report-only workbook shows nothing for the policy.
- **Cause:** no pilot user has signed in since the policy was created, or the scope excludes them.
- **Fix:** sign in as a pilot lab user, wait a few minutes for sign-in logs, then re-check
  **Conditional Access → Insights and reporting**. Confirm the pilot group is *included*.

### Legacy-auth block policy seems to do nothing
- **Symptom:** the "Block Legacy Auth (Report-only)" policy never matches.
- **Cause:** no legacy-auth sign-ins occurred, or the client-app conditions were not selected.
- **Fix:** confirm **Conditions → Client apps** has *Exchange ActiveSync* and *Other clients* checked.
  Legacy auth only matches when a legacy client actually connects; use `EKIDMOD-Signals.kql` to find
  real legacy-auth sign-ins.

### Accidentally set a lab policy to "On"
- **Symptom:** a pilot user is unexpectedly prompted/blocked.
- **Cause:** the policy was enabled instead of left report-only.
- **Fix:** set it back to **Report-only** immediately. This is why labs are pilot-scoped and
  break-glass is excluded — a mistake affects only lab users, and break-glass restores admin access.

## Identity Protection / licensing

### Risk reports or risk-based CA are unavailable / greyed out
- **Symptom:** Identity Protection blades or the sign-in/user-risk conditions are not selectable.
- **Cause:** the tenant/lab users lack **Entra ID P2**. Some features are preview.
- **Fix:** assign P2 to the lab users, or complete the lab as concept-only and note it in the runbook.
  *Verify current licensing and preview status in your tenant.*

## Passwordless

### A lab user cannot register a passkey / FIDO2 key
- **Symptom:** the method is missing from the security-info page.
- **Cause:** the method is not enabled for the pilot group, or the platform/browser is unsupported, or
  the capability is in preview.
- **Fix:** confirm **Authentication methods → Policies → FIDO2** is Enabled and targeted at the pilot
  group; use a supported browser/OS. *Verify current passkey availability in your tenant.*

## Governance

### Access review or access package options are missing
- **Symptom:** Identity Governance blades are unavailable.
- **Cause:** governance features require **Entra ID P2 / Entra ID Governance**.
- **Fix:** assign the governance license to lab users, or read the lab as concept-only. *Verify.*

## Global Secure Access / KQL

### Global Secure Access is not available
- **Symptom:** the GSA blade shows onboarding only, or capabilities are locked.
- **Cause:** GSA is not enabled/licensed in the tenant; some capabilities are preview.
- **Fix:** treat Lab 5 as concept-only and record where GSA fits in the runbook. *Verify availability.*

### KQL queries return nothing or error on table not found
- **Symptom:** `SigninLogs` (or similar) is unknown, or queries are empty.
- **Cause:** Entra diagnostic settings are not exporting logs to the Log Analytics workspace, or the
  time range predates log collection.
- **Fix:** configure Entra → **Diagnostic settings** to send `SignInLogs`/`AuditLogs` to the
  workspace; widen the query time range; confirm you are querying the right workspace.
