# 6. Troubleshooting Guide — Microsoft Purview for Retail

Use `RETAIL-Discovery.ps1` for the tenant's current config, `RETAIL-Validation.ps1` to confirm the
named objects are in place, `RETAIL-Report.ps1` for classification and DLP-event coverage, and
`RETAIL-Configuration.ps1` (default `-WhatIf`) for safe fixes. `RETAIL-Set-Scope.ps1` builds/checks the
`Purview - Retail Pilot` group.

## A. Sensitivity labels not appearing for retail users
| Symptom | Cause | Remediation |
|---|---|---|
| No Sensitivity button / labels missing | Label policy not published to the user, or publish still propagating | Confirm the user is in `Purview - Retail Pilot`; verify `Label Policy - Retail Data Classification - Pilot` targets them; allow up to 24 hours to propagate |
| Labels appear but no encryption | Label scoped to items but encryption not configured | Edit the label (`Sensitivity Label - Customer PII - Confidential` / `Sensitivity Label - Cardholder Data - Restricted`), enable **Configure encryption**, republish |
| Wrong label order/priority | Labels created out of sensitivity order | Reorder `Retail Public` → `Retail Internal` → `Customer PII - Confidential` → `Cardholder Data - Restricted`; order sets priority |

## B. Auto-labeling not finding cardholder data
- Confirm `Auto-Label - PCI Cardholder Data - Simulation` is running; simulation reports matches but
  applies nothing (by design — leave it in simulation until reviewed).
- Auto-labeling at rest (SharePoint/OneDrive) requires the higher plan; verify licensing with
  `RETAIL-Discovery.ps1` and Requirement 2.1 (**verify your licensing/tenant**).
- Check the rule uses the **Credit Card Number** SIT and that confidence/instance count is not set so
  high it suppresses matches. Confirm the SIT exists via `RETAIL-Discovery.ps1`.

## C. PCI/PII DLP is too noisy (false positives)
- This is expected **before** the audit gate — keep the policies in test/audit mode and tune. Common
  retail noise: order numbers, SKUs, or loyalty IDs that resemble a PAN. Raise the Credit Card Number
  match confidence, require a higher instance count, and add exceptions for known patterns.
- Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
  `RETAIL-Report.ps1`.
- Do **not** switch `DLP Policy - Retail PCI Cardholder Data - Test` or `DLP Policy - Retail Customer
  PII - Test` to block until the noise is acceptable.

## D. DLP not blocking after enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Enforce policy does not block PAN | Policy left in test mode, or scope excludes the user | Confirm `DLP Policy - Retail PCI Cardholder Data - Enforce` mode is **Turn the policy on**; confirm the user/location is in scope; run `RETAIL-Validation.ps1` to see the mode |
| Endpoint (device) rules never fire | Device not onboarded to Purview | Onboard the device (Purview → **Settings → Device onboarding**); verify with `RETAIL-Discovery.ps1` |
| Teams/SharePoint not covered | Location not enabled on the policy | Edit the policy and enable the missing location; re-run `RETAIL-Report.ps1` to confirm the coverage matrix |

## E. Cardholder data still found in M365 after enforcement
- Enforcement blocks **new** movement; it does not remove PAN already at rest. Use the
  `Auto-Label - PCI Cardholder Data - Simulation` results (Test 3) to locate existing PAN, then have
  the data owner remove/relocate it to the certified payment environment.
- Re-run the simulation after clean-up to confirm the location is clear. Removing existing cardholder
  data from out-of-scope systems is a **compliance/QSA-directed** activity — coordinate, don't delete
  unilaterally.

## F. Retention deleting too much or nothing
- Over-deletion: confirm the duration on `Retention Policy - Retail Baseline - 5 Year` and the
  `Retention Label - *` end action; pilot on `Purview - Retail Pilot` before widening. Deletion is
  irreversible.
- Nothing retained: confirm the policy shows **On** and is scoped to the correct locations; run
  `RETAIL-Validation.ps1`.
- For records, enable **disposition review** so items are reviewed before deletion rather than
  auto-deleted. **Retention periods are set by compliance/records**, not IT.

## G. PCI-DSS Compliance Manager template missing
- The PCI-DSS assessment template is a **premium** template requiring Microsoft 365 E5 / E5 Compliance;
  if it is absent from **Compliance Manager → Assessment templates**, verify the plan (Requirement 2.1,
  **verify your licensing/tenant**). Compliance Manager tracks/evidences controls — it does not certify
  PCI compliance; certification is a QSA activity.

## H. Licensing / feature missing
- Auto-labeling at rest, endpoint DLP, and the PCI-DSS Compliance Manager template require Microsoft
  365 E5 or the E5 Compliance add-on. If a feature is absent from the portal, verify the plan with
  `RETAIL-Discovery.ps1` and Requirement 2.1.

## I. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority, ContentType
Get-LabelPolicy | Select-Object Name, Enabled
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode
Get-DlpSensitiveInformationType | Where-Object Name -match 'Credit Card'
```
For classification and DLP events, use the Purview **Activity explorer** and the unified audit log
(Requirement 2.8).

## J. When to escalate
If a policy is published and propagated, the user is in scope, licensing is correct, and labels still
do not appear (or DLP still does not act) after 24 hours and a `RETAIL-Configuration.ps1` run, collect
the output of `RETAIL-Discovery.ps1` and `RETAIL-Validation.ps1` and open a Microsoft support case.
