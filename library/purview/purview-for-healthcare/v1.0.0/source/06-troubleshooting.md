# 6. Troubleshooting Guide — Microsoft Purview for Healthcare (HIPAA/PHI)

Use `PHI-Discovery.ps1` for the tenant's current config, `PHI-Validation.ps1` to confirm the named
objects are in place, `PHI-Report.ps1` for PHI classification and DLP-event coverage, and
`PHI-Remediation.ps1` (default `-WhatIf`) for safe fixes. Purview is licensing-dependent and evolving —
if a feature or portal path is missing, **verify your licensing/tenant** before assuming a defect.

## A. PHI sensitivity labels not appearing for users
| Symptom | Cause | Remediation |
|---|---|---|
| No Sensitivity button / PHI labels missing | Label policy not published to the user, or publish still propagating | Confirm the user is in `Purview - PHI Pilot Users`; verify `Label Policy - Healthcare PHI Taxonomy - All Users` targets them; allow up to 24 hours to propagate |
| Labels appear but no encryption | Label scoped to items but encryption not configured | Edit the label (`Sensitivity Label - Confidential - PHI - All Users`), enable **Configure encryption**, republish |
| Wrong label order/priority | Labels created out of sensitivity order | Reorder `Public` → `Internal` → `Confidential - PHI` → `Highly Confidential - PHI Restricted`; order sets priority |

## B. Label encryption breaks a clinical app / blocks care access
- This is the healthcare-specific risk. If a **legacy EHR/PACS integration or clinical viewer** cannot
  open PHI-labeled content, **do not enforce encryption broadly** — this can impede continuity of care.
- Test the inventoried clinical apps (Requirement 2.6) on the pilot; if an app is incompatible, keep
  encryption in pilot, document the emergency ("break-glass") access approach, and involve clinical IT
  and the Privacy/Security Officer before expanding.
- For the `Highly Confidential - PHI Restricted` label, confirm the **named care-team group** actually
  contains the clinicians who need access (minimum-necessary must not become no-access).

## C. PHI auto-labeling not labeling
- Confirm `Auto-Label - PHI Health Records - Pilot` is turned on (not left in simulation). Simulation
  reports matches but applies nothing — by design you review simulation first.
- Auto-labeling for SharePoint/OneDrive at rest requires the higher plan; verify licensing with
  `PHI-Discovery.ps1` and Requirement 2.1.
- Check the rule's health/PHI sensitive-information types and confidence — too high a confidence or
  instance count can suppress real PHI matches.

## D. HIPAA DLP is too noisy (false positives)
- Expected before the audit gate — keep `DLP Policy - PHI HIPAA - Audit` in test/audit mode and tune.
  Raise the match confidence, require a higher instance count, and add exceptions for legitimate
  referral, billing, and care-coordination flows.
- Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
  `PHI-Report.ps1`.
- **Do not** switch to enforce until the noise is acceptable — erroneously blocking clinicians is a
  patient-care risk, not just a help desk ticket.

## E. HIPAA DLP not blocking after enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Enforce policy does not block | Policy left in test mode, or scope excludes the user | Confirm `DLP Policy - PHI HIPAA - Enforce` mode is **Turn the policy on**; confirm the user/location is in scope |
| Endpoint (device) rules never fire | Device not onboarded to Purview | Onboard the device (Purview → **Settings → Device onboarding**); verify with `PHI-Discovery.ps1` |
| Teams/SharePoint PHI not covered | Location not enabled on the policy | Edit the policy and enable the missing location |

## F. Retention disposing too much or nothing
- **Over-disposal:** confirm the duration on `Retention Policy - Healthcare Baseline - Schedule-Defined`
  and the end action; pilot on `Purview - PHI Pilot Users` before widening. Disposal is irreversible —
  and the duration must come from your **records schedule**, not a default.
- **Nothing retained:** confirm the policy shows **On** and is scoped to the correct locations; run
  `PHI-Validation.ps1`.
- For clinical records, enable **disposition review** so PHI is reviewed before deletion rather than
  auto-deleted. Keep the HIPAA-documentation 6-year label (`Retention Label - HIPAA Documentation -
  6 Year`) distinct from the clinical-records label.

## G. Retention duration uncertainty (which schedule?)
- Retention durations are a **records/legal determination — deferred**. If the correct medical-record
  retention period is unknown, **do not guess**: leave the clinical label in pilot and obtain the
  schedule from your records/privacy/legal function (state law varies, often longer for minors). The
  solution implements the schedule; it does not decide it.

## H. Licensing / feature missing
- Auto-labeling at rest, endpoint DLP, DSPM / DSPM for AI, insider risk, communication compliance, and
  advanced records require Microsoft 365 E5 or the E5 Compliance add-on. If a feature is absent from
  the portal, verify the plan with `PHI-Discovery.ps1` and Requirement 2.1 — **verify your
  licensing/tenant** (availability evolves).

## I. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority, ContentType
Get-LabelPolicy | Select-Object Name, Enabled
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode
```
For PHI classification and DLP events, use the Purview **Activity explorer** and the unified audit log
(Requirement 2.7).

## J. When to escalate
If a PHI label policy is published and propagated, the user is in scope, licensing is correct, and
labels still do not appear (or DLP still does not act) after 24 hours and a `PHI-Remediation.ps1` run,
collect the output of `PHI-Discovery.ps1` and `PHI-Validation.ps1` and open a Microsoft support case.
Route any regulatory, records, or legal question (retention schedule, records file plan, legal hold,
insider-risk/communication-compliance case action) to your compliance, records, privacy, and legal
functions — those determinations are **deferred**, not made here.
