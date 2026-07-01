# 6. Troubleshooting Guide — Microsoft Purview: DLP, Sensitivity Labels & Retention

Use `PURVIEW-Discovery.ps1` for the tenant's current config, `PURVIEW-Validation.ps1` to confirm the
named objects are in place, `PURVIEW-Report.ps1` for classification and DLP-event coverage, and
`PURVIEW-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Sensitivity labels not appearing for users
| Symptom | Cause | Remediation |
|---|---|---|
| No Sensitivity button / labels missing | Label policy not published to the user, or publish still propagating | Confirm the user is in `Purview - Pilot Users`; verify `Label Policy - Sensitivity Taxonomy - All Users` targets them; allow up to 24 hours to propagate |
| Labels appear but no encryption | Label scoped to items but encryption not configured | Edit the label (`Sensitivity Label - Confidential - All Users`), enable **Configure encryption**, republish |
| Wrong label order/priority | Labels created out of sensitivity order | Reorder labels `Public` → `General` → `Confidential` → `Highly Confidential`; order sets priority |

## B. Auto-labeling not labeling
- Confirm the policy `Auto-Label - Confidential Financial - Pilot` is turned on (not left in
  simulation). Simulation reports matches but applies nothing.
- Auto-labeling for SharePoint/OneDrive at rest requires the higher plan; verify licensing with
  `PURVIEW-Discovery.ps1`.
- Check the rule's sensitive-information types and confidence — too high a confidence or instance
  count can suppress matches.

## C. DLP is too noisy (false positives)
- This is expected before the audit gate — keep the policy in test/audit mode and tune. Raise the
  match confidence, require a higher instance count, and add exceptions.
- Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
  `PURVIEW-Report.ps1`.
- Do not switch `DLP Policy - Financial and PII - Audit` to enforce until the noise is acceptable.

## D. DLP not blocking after enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Enforce policy does not block | Policy left in test mode, or scope excludes the user | Confirm `DLP Policy - Financial and PII - Enforce` mode is **Turn the policy on**; confirm the user/location is in scope |
| Endpoint (device) rules never fire | Device not onboarded to Purview | Onboard the device (Purview → **Settings → Device onboarding**); verify with `PURVIEW-Discovery.ps1` |
| Teams/SharePoint not covered | Location not enabled on the policy | Edit the policy and enable the missing location |

## E. Retention deleting too much or nothing
- Over-deletion: confirm the duration on `Retention Policy - M365 Baseline - 5 Year` and the end
  action; pilot on `Purview - Pilot Users` before widening. Deletion is irreversible.
- Nothing retained: confirm the policy shows **On** and is scoped to the correct locations; run
  `PURVIEW-Validation.ps1`.
- For records, enable **disposition review** so items are reviewed before deletion rather than
  auto-deleted.

## F. Licensing / feature missing
- Auto-labeling at rest, endpoint DLP, and advanced records require Microsoft 365 E5 or the E5
  Compliance add-on. If a feature is absent from the portal, verify the plan with
  `PURVIEW-Discovery.ps1` and Requirement 2.1.

## G. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority, ContentType
Get-LabelPolicy | Select-Object Name, Enabled
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode
```
For classification and DLP events, use the Purview **Activity explorer** and the unified audit log
(Requirement 2.7).

## H. When to escalate
If a label policy is published and propagated, the user is in scope, licensing is correct, and labels
still do not appear (or DLP still does not act) after 24 hours and a `PURVIEW-Remediation.ps1` run,
collect the output of `PURVIEW-Discovery.ps1` and `PURVIEW-Validation.ps1` and open a Microsoft
support case.
