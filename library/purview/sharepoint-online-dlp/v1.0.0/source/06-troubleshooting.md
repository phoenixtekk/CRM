# 6. Troubleshooting — SharePoint Online DLP (Microsoft Purview)

Symptoms, likely causes, and fixes for SharePoint/OneDrive DLP. Stay in **test mode** while diagnosing —
reproduce on `SPO DLP – Pilot Sites – Stage1` before enforcing or expanding, and never flip a policy to
enforce to "test" a theory.

## The policy matches nothing / no matches in reports
- **Propagation delay.** New DLP policies take time (often up to ~1 hour, longer at scale) to activate and
  begin evaluating. Confirm the policy exists and wait before concluding failure.
- **Wrong sensitive info type / too-high count.** Verify the exact SIT name (`DLPSPO-Discover.ps1` lists
  them) and that your test content actually matches it in the right format, and that `minCount` isn't set
  higher than your test document contains.
- **Location not in scope.** Confirm the site/account is in the policy's SharePoint/OneDrive locations.
- **Test content not indexed yet.** DLP evaluates on content processing; a just-uploaded document may not
  be evaluated instantly. Wait and re-check the reports.

## The policy blocks legitimate content (false positives)
- **Condition too broad.** Tighten the sensitive info type (raise confidence/count) or add supporting
  conditions so common formats don't trigger it.
- **Add an exception.** Except the site/group/condition that legitimately holds the content, or scope the
  policy away from it. This is expected tuning — do it in **test mode** before enforcing.
- **Still in test mode?** If you're seeing *would-block* entries, that's test mode reporting impact, not a
  live block — which is exactly the point of piloting in test mode first.

## Enforcement is blocking users unexpectedly
- **Enforced too early.** Enforcement should follow a validated test-mode pilot. If a policy is blocking
  legitimate work, return it to test mode immediately: `DLPSPO-Set-DlpPolicy.ps1 -Action Test -Commit` (or
  `Set-DlpCompliancePolicy ... -Mode TestWithoutNotifications`), then tune.
- **Missing exception.** A legitimate case wasn't excepted. Add the exception, re-validate in test mode,
  then re-enforce.

## Policy tips don't appear
- **Notifications off / wrong mode.** Policy tips show in **enforce** mode and **test-with-notifications**
  mode, not in test-without-notifications. Confirm the mode and that the rule's user notification / policy
  tip is enabled.
- **Tip text not configured.** Complete the policy-tip text in the portal (it isn't asserted by the
  script). Verify the rule's notification settings.
- **Client/surface support.** Tip display varies by surface (SharePoint web, sync client, Office). Verify
  the specific surface supports tips for the scenario.

## `DLPSPO-Set-DlpPolicy.ps1 -Commit` fails
- **Not connected / wrong session.** Ensure `Connect-IPPSSession` succeeded
  (`Get-Command Get-DlpCompliancePolicy` resolves).
- **Insufficient role.** Creating DLP policies needs Compliance Administrator / DLP Compliance Management.
  Confirm in Purview → Roles & scopes / Permissions.
- **Parameter shape by module version.** `-ContentContainsSensitiveInformation`, `-AccessScope`, and
  `-Mode` values vary across ExchangeOnlineManagement versions. Verify against your version; update the
  module if it's far behind.
- **Bad SIT name.** A name in `-SensitiveTypes` must exactly match a `Get-DlpSensitiveInformationType`
  entry. Copy the exact `Name`.

## `DLPSPO-Validate.ps1` reports the mode wrong or a property mismatch
- **Module-version property shape.** Location and mode properties are exposed under different names across
  module versions. Confirm the intended state in the portal (Data Loss Prevention → the policy) and treat
  the validator line as informational where the portal disagrees; note the module version.

## OneDrive isn't covered even though I set it
- **OneDrive location value.** OneDrive is scoped as `All` (or by account) separately from SharePoint.
  Confirm `-IncludeAllOneDrive` was used (or the OneDrive location is set in the portal) and that the
  policy's OneDrive location is populated in `DLPSPO-Discover.ps1`.

---
### When to stop and escalate
- A required capability is unavailable on your licensing/tenant (an advanced classifier/condition) —
  record it **deferred** and route the licensing decision to the owner; do not design around an
  unavailable feature.
- **Which content is sensitive and which sharing is acceptable** is a stakeholder determination
  (compliance/security/privacy), not a technical fix — capture it in `DLP Scope – Map` and defer the
  determination.
- If match or enforcement behavior can't be reconciled with the policy, keep it in test mode on the pilot,
  gather `DLPSPO-Validate.ps1` + `DLPSPO-Report.ps1` output as evidence, and raise with Microsoft support
  before enforcing or expanding.
