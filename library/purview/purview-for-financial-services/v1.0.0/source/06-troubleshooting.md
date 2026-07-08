# 6. Troubleshooting Guide — Microsoft Purview for Financial Services

Use `FS-Purview-Discovery.ps1` for the tenant's current config, `FS-Purview-Validation.ps1` to confirm
the named objects are in place, `FS-Purview-Report.ps1` for classification and DLP-event coverage, and
`FS-Purview-Remediation.ps1` (default `-WhatIf`) for safe fixes. Remediation **never** enforces DLP and
**never** applies Preservation Lock.

## A. FS sensitivity labels not appearing for users
| Symptom | Cause | Remediation |
|---|---|---|
| No Sensitivity button / labels missing | Label policy not published to the user, or publish still propagating | Confirm the user is in `Purview - FS Pilot Users`; verify `Label Policy - FS Taxonomy - Pilot` targets them; allow up to 24 hours to propagate |
| Labels appear but no encryption on NPI/MNPI | Label scoped to items but encryption not configured | Edit the label (`Sensitivity Label - FS Confidential (NPI/GLBA)` / `... FS Restricted (MNPI)`), enable **Configure encryption**, republish |
| Wrong label order/priority | Labels created out of sensitivity order | Reorder `FS Public` → `FS Internal` → `FS Confidential (NPI/GLBA)` → `FS Restricted (MNPI)`; order sets priority |

## B. NPI auto-labeling not labeling
- Confirm `Auto-Label - FS NPI (GLBA) - Simulation` is turned on (not left in simulation). Simulation
  reports matches but applies nothing.
- Auto-labeling for SharePoint/OneDrive at rest requires the higher plan; verify licensing with
  `FS-Purview-Discovery.ps1`.
- Check the rule's financial sensitive-information types and confidence — too high a confidence or
  instance count can suppress matches on bank-account / routing / SSN data.

## C. DLP is too noisy (false positives)
- Expected before the audit gate — keep `DLP Policy - FS NPI and Financial - Test` in test/audit and
  tune. Raise match confidence, require a higher instance count, and add exceptions (e.g. known
  internal financial systems).
- Review matches in Purview → **Data Loss Prevention → Alerts** and **Activity explorer**; run
  `FS-Purview-Report.ps1`.
- Do **not** switch to enforce until the noise is acceptable — a blocked-work storm on advisers/traders
  undermines the program.

## D. DLP not blocking after enforce
| Symptom | Cause | Remediation |
|---|---|---|
| Enforce policy does not block | Policy left in test mode, or scope excludes the user | Confirm `DLP Policy - FS NPI and Financial - Enforce` mode is **Turn the policy on**; confirm the user/location is in scope |
| Endpoint (device) rules never fire | Device not onboarded to Purview | Onboard the device (Purview → **Settings → Device onboarding**); verify with `FS-Purview-Discovery.ps1` |
| Teams/SharePoint not covered | Location not enabled on the policy | Edit the policy and enable the missing location |

## E. Retention / records issues
- **Nothing retained:** confirm `Retention Policy - FS Communications Supervision - 6 Year` shows **On**
  and is scoped to the correct locations; run `FS-Purview-Validation.ps1`.
- **Cannot shorten/disable/unscope a retention policy:** it is **locked** with Preservation Lock — this
  is **irreversible by design**. There is no rollback; the policy stays as configured for its life.
  This is expected once records/legal have signed off and you locked it (Step 9.5). Confirm the lock
  state with `FS-Purview-Discovery.ps1`.
- **Cannot un-mark a regulatory record:** a retention label marked as a **regulatory record** cannot be
  removed for its retention period — this is intended for SEC 17a-4-style immutability. Verify it was
  only applied where records/legal required it.
- **Records deleted unreviewed:** enable **disposition review** on the file plan so items are reviewed
  before deletion rather than auto-deleted.

## F. Communication compliance (supervision) issues
| Symptom | Cause | Remediation |
|---|---|---|
| Communication Compliance node/cmdlet absent | Licensing (E5 / E5 Compliance) or missing role | Verify licensing; add the operator to the correct **Communication Compliance** role group (see role separation, Requirement 2.2) |
| No alerts generated | Policy scope too narrow, review percentage too low, or lexicon/conditions not matching | Confirm `Comm Compliance - FS Supervision (FINRA 3110) - Pilot` is scoped to `Purview - FS Pilot Users`, raise the review percentage, and confirm the compliance-supplied lexicon |
| One person can configure, triage, and investigate | Roles not separated | Separate the **Admin / Analyst / Investigator** roles across different people; this is a privacy/role-separation requirement, not optional |
| Reviewer sees real identities during triage | Pseudonymization off | Turn on pseudonymization in **Communication Compliance → Settings** |

*Any supervision case **outcome** is a compliance/HR/legal determination — the tool provides the
evidence, not the decision.*

## G. Licensing / feature missing
- Auto-labeling at rest, endpoint DLP, records management, communication compliance, and Audit
  (Premium) require Microsoft 365 E5 or the E5 Compliance add-on. If a feature is absent from the
  portal, verify the plan with `FS-Purview-Discovery.ps1` and Requirement 2.1, and **verify your
  tenant** — the portal evolves.

## H. Diagnostics quick reference
```powershell
# Security & Compliance PowerShell (Exchange Online Management module)
Connect-IPPSSession
Get-Label | Select-Object DisplayName, Priority, ContentType
Get-LabelPolicy | Select-Object Name, Enabled
Get-DlpCompliancePolicy | Select-Object Name, Mode, Enabled
Get-RetentionCompliancePolicy | Select-Object Name, Enabled, Mode, RestrictiveRetention  # RestrictiveRetention = Preservation Lock
Get-ComplianceTag | Select-Object Name, RetentionDuration, RetentionAction
# Communication compliance (role-gated):
Get-SupervisoryReviewPolicyV2 | Select-Object Name, Enabled
```
For classification and DLP events, use the Purview **Activity explorer** and the unified audit log
(Requirement 2.7).

## I. When to escalate
If a policy is published and propagated, the user/location is in scope, licensing is correct, and the
capability still does not behave after 24 hours and an `FS-Purview-Remediation.ps1` run, collect the
output of `FS-Purview-Discovery.ps1` and `FS-Purview-Validation.ps1` and open a Microsoft support case.
For any **records-retention, regulatory-record, supervision, or FINRA/SEC/GLBA applicability**
question, escalate to the firm's **compliance, records, privacy, or legal** owners — those are
determinations, not support issues.
