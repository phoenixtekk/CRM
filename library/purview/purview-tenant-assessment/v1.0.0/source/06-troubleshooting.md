# 6. Troubleshooting — Microsoft Purview Tenant Assessment

Common issues, grouped by stage. Each has a **symptom**, the **likely cause**, and a **resolution**.
The assessment tools are read-only except `PURVASSESS-Remediate.ps1`, which is `-WhatIf` by default and
writes only with `-Commit` — so most "it didn't work" issues here are connection, role, or licensing
gaps rather than damage. When a capability legitimately reads as **not licensed / not enabled /
portal-only**, that is a *finding*, not a failure to fix.

## Connectivity & authentication

**Symptom:** `Connect-IPPSSession` or `Connect-ExchangeOnline` fails or hangs.
**Likely cause:** the `ExchangeOnlineManagement` module is missing/outdated, MFA prompt was missed, or
a conditional-access policy blocks the sign-in.
**Resolution:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (or `Update-Module`),
complete the interactive modern-auth prompt, and pass `-UserPrincipalName` so the right admin is used.
Confirm the account is allowed by conditional access for PowerShell.

**Symptom:** the Graph licensing section is skipped or errors.
**Likely cause:** `Microsoft.Graph` module not installed, or consent not granted for
`Organization.Read.All` / `Directory.Read.All`.
**Resolution:** `Install-Module Microsoft.Graph -Scope CurrentUser`, re-run and consent, or run
`PURVASSESS-Scope.ps1 -SkipGraph` and confirm licensing manually in the Microsoft 365 admin center.

## Roles & permissions (a permission gap looks like a coverage gap)

**Symptom:** `PURVASSESS-Scope.ps1` reports a capability read as **FAILED (role/permission)**.
**Likely cause:** the signed-in admin lacks the least-privilege role for that capability (Requirement 2.2).
**Resolution:** grant the reader role (e.g. **Compliance Administrator** / **Global Reader** / capability-
specific reader) in the Purview portal `Roles & scopes` or Entra, wait for propagation (can take minutes),
and re-run. **Do not** record the capability as a gap until the read succeeds — otherwise you flag a
missing permission as a missing control.

**Symptom:** `PURVASSESS-Remediate.ps1 -Commit` throws an access-denied error.
**Likely cause:** the write role for that fix is missing (Requirement 2.5) — read access is not enough to
change a policy.
**Resolution:** grant the appropriate write role, re-preview with `-WhatIf`, then re-run with `-Commit`.

## Discovery / inventory

**Symptom:** a capability you know is enabled shows no data in `PURVASSESS-Discovery.ps1`.
**Likely cause:** wrong endpoint for that capability (retention/labels via `Connect-IPPSSession`; audit via
`Connect-ExchangeOnline`), or a role gap (see above).
**Resolution:** confirm the endpoint connected in Step 1, resolve any Gate-1 read failure, and re-run.

**Symptom:** Insider Risk, Communication Compliance, DSPM, Compliance Manager, or Unified Catalog show as
**portal-only — review manually**.
**Likely cause:** these have no reliable read cmdlet — this is expected, not an error.
**Resolution:** open the exact portal location the tool records and capture current state by hand. Never
substitute an invented value.

**Symptom:** a DLP policy's **mode** or a retention policy's **Enabled** state doesn't match the portal.
**Likely cause:** stale session, or reading with a role that returns a partial view.
**Resolution:** reconnect, re-read, and compare against the Purview portal DLP/retention list; the portal
value is authoritative.

## Remediation (simulation-first)

**Symptom:** `-WhatIf` prints nothing / the fix seems to do nothing.
**Likely cause:** `-Commit` was omitted (correct behaviour — no change is intended without it), or
`-PolicyName` doesn't match an existing policy.
**Resolution:** confirm the policy name exactly (`Get-DlpCompliancePolicy | Select Name`), review the
`-WhatIf` cmdlet line, then re-run with `-Commit`.

**Symptom:** enabling a retention policy is questioned by the records owner.
**Likely cause:** whether a retention policy *should* run is a **records/compliance determination**
(Requirement 2.6), not a technical fix.
**Resolution:** get the records owner's written approval before `-Commit`; record it as evidence. If it was
enabled prematurely, `PURVASSESS-Remediate.ps1 -Fix EnableRetentionPolicy -PolicyName "<policy>" -Revert -Commit`.

**Symptom:** a committed fix needs to be undone.
**Resolution:** `PURVASSESS-Remediate.ps1 -Fix <name> -Revert -Commit` restores the recorded prior state
from `PURVASSESS-Remediate-state.json`. Keep that state file with your evidence for the duration of the pilot.

## Validation

**Symptom:** `PURVASSESS-Validate.ps1` reports FAIL after a committed fix.
**Likely cause:** the change hasn't propagated yet (audit ingestion can take up to ~60 minutes), the wrong
policy name was validated, or the commit didn't actually run.
**Resolution:** wait for propagation and re-validate; confirm you passed the exact remediated policy names;
if it truly didn't take, revert and investigate before expanding.

## Scope of these gates

Every gate here proves the assessment **read the tenant correctly** and that a quick-win fix **took effect**.
None of them judge whether a policy is *correct* or *sufficient for a regulation* — retention durations,
DLP regulatory sufficiency, records applicability, and whether a capability is *required* are
**compliance / records / legal determinations** routed to their owners (Requirement 2.6), not resolved here.
