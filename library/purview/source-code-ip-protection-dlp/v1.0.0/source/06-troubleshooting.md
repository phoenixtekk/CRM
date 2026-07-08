# 6. Troubleshooting — Source-Code & IP Protection DLP (Microsoft Purview)

Symptoms, likely causes, and fixes for source-code/IP DLP. Stay in **test mode** while diagnosing —
reproduce on `Source-Code DLP – Pilot Ring – Stage1` before enforcing or expanding, and never flip a policy
to enforce to "test" a theory against real developer workflow.

## The policy matches nothing / no matches in reports
- **Propagation delay.** New DLP policies take time (often up to ~1 hour, longer at scale) to activate;
  endpoint policies also need the device to sync. Confirm the policy exists and wait before concluding
  failure.
- **Source Code classifier not on the rule.** The Source Code trainable classifier is added by **classifier
  reference in the portal** (the script scaffolds the policy/rule and custom SITs; the classifier is
  completed in the portal). Confirm the rule actually references the classifier.
- **Custom IP types too specific / wrong name.** Verify custom SIT names (`DLPCODE-Discover.ps1` lists info
  types) and that your test content matches them.
- **Channel not in scope.** Confirm the egress channel you're testing (email/SharePoint/OneDrive/Teams/
  Endpoint) is in the policy's locations.

## Endpoint (USB/upload) activity isn't detected
- **Device not onboarded.** Endpoint DLP requires the device to be **onboarded** (shared with Defender for
  Endpoint). Confirm the pilot device shows in Purview → Settings → Endpoint DLP.
- **Egress activity not enabled.** The specific activities (copy to removable media, upload to cloud/
  unmanaged browser) must be enabled in Endpoint DLP settings and referenced by the rule. Confirm both.
- **Licensing.** Endpoint DLP requires **E5 / E5 Compliance**. `DLPCODE-Check-Prereqs.ps1` flags the DLP
  signal; where endpoint is out of plan, record it **deferred** and rely on email/collaboration channels.
- **Sync lag.** Endpoint policy changes take time to reach the device. Have the device sync and retry.

## The policy blocks legitimate developer activity (false positives)
- **Classifier confidence too low / condition too broad.** Raise the Source Code classifier confidence or
  tighten the conditions so comments, config, and docs don't trigger it.
- **Add an exception for approved egress.** Except approved repositories, build systems, CI/CD, and
  sanctioned partner-sharing paths. This is expected tuning — do it in **test mode** before enforcing.
- **Still in test mode?** *Would-block* entries in test mode are impact reporting, not live blocks — which
  is exactly why you pilot in test mode first.

## Enforcement is blocking developers unexpectedly
- **Enforced too early.** Enforcement should follow a validated test-mode pilot. If it's blocking
  legitimate work, return to test mode immediately: `DLPCODE-Set-DlpPolicy.ps1 -Action Test -Commit`, then
  tune.
- **Missing exception.** An approved repo/tool wasn't excepted. Add the exception, re-validate in test
  mode, then re-enforce.

## Policy tips don't appear
- **Notifications off / wrong mode.** Tips show in **enforce** mode and **test-with-notifications**, not in
  test-without-notifications. Confirm the mode and that the rule's policy tip / user notification is
  enabled. Endpoint tips also depend on device support.
- **Tip text not configured.** Complete the tip text in the portal (not asserted by the script).

## `DLPCODE-Set-DlpPolicy.ps1 -Commit` fails
- **Not connected / wrong session.** Ensure `Connect-IPPSSession` succeeded
  (`Get-Command Get-DlpCompliancePolicy` resolves).
- **Insufficient role.** Creating DLP policies needs Compliance Administrator / DLP Compliance Management.
  Confirm in Purview → Roles & scopes / Permissions.
- **Parameter/location shape by module version.** `-EndpointDlpLocation`, `-TeamsLocation`,
  `-ContentContainsSensitiveInformation`, and `-Mode` values vary across ExchangeOnlineManagement versions.
  Verify against your version; update the module if it's far behind.
- **Classifier not addable via cmdlet.** The Source Code trainable classifier is typically added by
  reference in the portal rather than a simple parameter — complete it there and re-validate.

## `DLPCODE-Validate.ps1` reports a channel/mode wrong
- **Module-version property shape.** Location and mode properties are exposed under different names across
  module versions. Confirm the intended state in the portal (Data Loss Prevention → the policy) and treat
  the validator line as informational where the portal disagrees; note the module version.

---
### When to stop and escalate
- A required capability is unavailable on your licensing/tenant (Endpoint DLP, the Source Code classifier)
  — record it **deferred** and route the licensing decision to the owner; do not design around an
  unavailable feature.
- **What is protected IP and which egress is acceptable** is a stakeholder determination (security/IP/
  legal), not a technical fix — capture it in `Source-Code DLP – Map` and defer the determination.
- If match or enforcement behavior can't be reconciled with the policy, keep it in test mode on the pilot
  ring, gather `DLPCODE-Validate.ps1` + `DLPCODE-Report.ps1` output as evidence, and raise with Microsoft
  support before enforcing or expanding.
