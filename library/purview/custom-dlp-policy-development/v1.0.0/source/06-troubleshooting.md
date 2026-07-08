# 6. Troubleshooting Guide — Custom DLP Policy Development (Microsoft Purview)

Field issues and how to resolve them, in the order you are likely to hit them. Every check here is safe.

## DLP does not appear, or a workload can't be targeted
**Symptom:** `Data loss prevention` is missing from the Purview portal, or you can't scope a policy to
endpoints.
**Cause:** DLP is licensing-gated — baseline DLP (Exchange/SharePoint/OneDrive/Teams) is broadly licensed,
but **Endpoint DLP** and advanced classification inputs (trainable classifiers, EDM) need **E5 / E5
Compliance**.
**Fix:** Run `DLPCUSTOM-Assess-DlpEnvironment.ps1` and confirm the SKU in `Billing → Licenses`. Target only
the licensed workloads; record the rest as deferred. Verify availability against **your own tenant and
plan** — the script's mapping is indicative.

## `Connect-IPPSSession` fails or DLP cmdlets are not found
**Symptom:** Connection errors, repeated auth prompts, or `Get-DlpCompliancePolicy` "is not recognized."
**Cause:** Missing/old ExchangeOnlineManagement module, or basic-auth/legacy sign-in — DLP cmdlets live in
**Security & Compliance PowerShell**, reached via `Connect-IPPSSession` (not `Connect-ExchangeOnline`).
**Fix:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force`; use a modern-auth/MFA admin
account and connect with `Connect-IPPSSession`. Close/reopen PowerShell if a stale session is cached.

## A referenced sensitive info type "does not exist"
**Symptom:** `DLPCUSTOM-New-DlpPolicy.ps1 -WhatIf` prints `[MISSING SIT]`, or a rule detects nothing.
**Cause:** The condition references a SIT/label that isn't in the tenant — commonly a **custom** identifier
(your customer-ID format) that was never built, or a name typo.
**Fix:** Run `DLPCUSTOM-Assess-DlpEnvironment.ps1 -NeededSit '<name>'` to confirm presence and exact name.
Build any missing **custom SIT / Exact Data Match / document fingerprint / trainable classifier** in its own
dedicated solution first, then reference it here. Do **not** invent a SIT inside this policy work.

## The policy is over-firing (too many false positives)
**Symptom:** The simulation match report is full of matches on content that isn't really sensitive.
**Cause:** Conditions are too broad — low confidence, a low instance-count minimum, an overly generic SIT,
or a missing exception for an approved flow.
**Fix:** Tune with `DLPCUSTOM-New-DlpPolicy.ps1 … -Update` (dry-run `-WhatIf`, then `-Commit`): raise the
**confidence** requirement, raise the **instance-count** minimum, narrow the **SIT**, or add an
**`ExceptIf…` exception** for the approved flow. Re-simulate and re-report. Precision is the goal — an
over-firing policy trains users to ignore DLP.

## The policy misses known-sensitive data (false negatives)
**Symptom:** Seeded known-sensitive test samples do **not** appear in the match report.
**Cause:** The condition is too strict (confidence/instance count set too high), the wrong SIT is used, or
the sample sits in a workload the policy doesn't cover.
**Fix:** Lower the over-strict threshold, add/broaden the **SIT**, or extend the policy's **locations**.
Confirm the sample is in a targeted workload. Re-simulate; every seeded sample should match.

## A pilot user sees a policy tip or a block during simulation
**Symptom:** Users are being notified or blocked while you intended a no-impact pilot.
**Cause:** The policy is **not** in `TestWithoutNotifications` — it may be in `TestWithNotifications` (tips
on) or already `Enable` (enforcing).
**Fix:** Run `DLPCUSTOM-Test-DlpPolicy.ps1 -PolicyName '<name>'` to read the mode. To return to no-impact
simulation: `Set-DlpCompliancePolicy -Identity '<name>' -Mode TestWithoutNotifications` (the author script
prints this reverse command). Only move to notifications/enforcement deliberately, after the tuning gate.

## Simulation shows no matches at all
**Symptom:** The match report is empty even though matching content exists.
**Cause:** Content hasn't been evaluated yet (new/edited items evaluate as they change; existing content is
scanned over time — allow ~24–48 hours, longer for large SharePoint/OneDrive estates), or the policy scope
doesn't include where the content lives, or the reporting look-back window is too short.
**Fix:** Wait and re-run `DLPCUSTOM-Report-DlpMatches.ps1 -Days <n>`; confirm the pilot scope covers the
content's location with `DLPCUSTOM-Test-DlpPolicy.ps1`; seed a fresh test item to force near-term
evaluation.

## Matches can't be exported by the reporting script
**Symptom:** `DLPCUSTOM-Report-DlpMatches.ps1` reports the export was unavailable.
**Cause:** DLP reporting surfaces evolve — several legacy `Get-Dlp*Report` cmdlets were retired in favour of
**Activity Explorer**; `Export-ActivityExplorerData` may not be present/consented in your tenant.
**Fix:** Review matches in the portal instead: **Data loss prevention → Alerts**, or **Data classification →
Activity explorer** filtered to `Activity = DLPRuleMatch` and your policy (verify path). The script prints
this fallback. The reporting *method* varies; the *evidence* (matches) is the same.

## Endpoint DLP policy has no effect on devices
**Symptom:** A policy scoped to endpoints records nothing from devices.
**Cause:** Devices aren't **onboarded to Purview** (separate from Intune/device management), or Endpoint DLP
isn't licensed (E5 / E5 Compliance).
**Fix:** Run `DLPCUSTOM-Scope-Health.ps1 -TargetEndpoint` to report readiness. Onboarding devices to Purview
(`Settings → Device onboarding`, verify path) is performed in the **endpoint-DLP** solution — this policy
targets endpoints once they're onboarded. Record the gap as a hand-off item.

## An approved business flow is being blocked after enforcement
**Symptom:** A legitimate flow (partner email, service mailbox, a specific site) is blocked once the policy
is enforcing.
**Cause:** The exception for that flow is missing or wrong — or you moved to a restrictive action before the
exceptions were validated in simulation.
**Fix:** Immediately roll back to no-impact simulation (`Set-DlpCompliancePolicy -Mode
TestWithoutNotifications`) or `-Mode Disable`, add/correct the `ExceptIf…` exception with
`DLPCUSTOM-New-DlpPolicy.ps1 … -Update`, re-simulate to confirm the flow no longer matches, then re-enforce.
This is exactly why exceptions are validated (Testing Guide Test 6) **before** any block is enabled.

---
### When to stop and escalate
- A required capability/workload is **not licensed** → scope the policy to what you have and record the rest
  as deferred; do not attempt to force it.
- You are asked to decide **what data is sensitive, which regulation applies, or a records/retention
  implication** → escalate to compliance, privacy, records, or legal. This solution provides the technical
  policy and the match evidence, never the determination.
- A portal path or reporting surface here **doesn't match your tenant** → the Purview DLP portal and
  reporting surfaces are actively evolving; verify the current path/method in your tenant before assuming
  the guide is wrong about the *step*.
