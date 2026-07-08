# 6. Troubleshooting Guide — Microsoft Purview for Manufacturing

Common field issues for the Manufacturing IP + CUI program and how to resolve them. Objects are named
verbatim from the Implementation Guide. Most problems are **licensing/cloud gaps**, **replication
delay**, or **audit-not-yet-tuned** — not step mistakes. When a feature is simply absent, treat it as a
plan/cloud gap (Requirement 2.1) and **verify your licensing/tenant** before assuming a fault.

## A label or feature is missing from the portal
- **Symptom:** Auto-labeling at rest, endpoint DLP, trainable classifiers, or advanced records don't
  appear.
- **Likely cause:** These need **Microsoft 365 E5 / E5 Compliance**; DIB tenants often need **GCC /
  GCC High** for CUI. Basic labels + DLP ship in E3/Business Premium.
- **Resolve:** Run `PURVIEW-MFG-Discovery.ps1` to see what the tenant exposes; confirm the plan in the
  M365 admin center; assign the required add-on. **Verify your licensing/tenant** — availability
  evolves and is cloud-dependent.

## New labels don't show in Office / Outlook for pilot users
- **Symptom:** `Sensitivity Label - MFG-*` labels aren't visible after publishing.
- **Likely cause:** **Replication delay** (labels/policies can take hours to appear), the user isn't in
  `Purview - Manufacturing Pilot`, or the client hasn't refreshed.
- **Resolve:** Confirm publication with `PURVIEW-MFG-Validation.ps1`; verify the user is in the pilot
  group (`PURVIEW-MFG-Set-ScopeTargeting.ps1`); have them restart the Office app / re-sign-in; allow
  time to propagate before re-publishing.

## The custom SIT matches too much or too little
- **Symptom:** `SIT - MFG Part/Drawing Number` fires on ordinary text, or misses real part numbers.
- **Likely cause:** Regex too broad/narrow, wrong **confidence level**, or too-wide **character
  proximity**; missing supporting keywords.
- **Resolve:** Open the SIT → **Test** with real and decoy samples; tighten the regex, raise the
  confidence, add supporting keywords (`drawing`, `rev`, `assembly`, `BOM`), and reduce proximity.
  Where the plan provides the built-in **CUI classifier/SITs**, prefer them for CUI.

## Auto-labeling simulation shows nothing (or wrong labels)
- **Symptom:** `Auto-Label - CUI and Export-Controlled - Pilot` simulation is empty or mislabels.
- **Likely cause:** Simulation needs time to crawl; the rule condition or target label is wrong; the
  in-scope locations hold no matching content yet.
- **Resolve:** Allow the simulation to complete; confirm the condition uses `SIT - MFG Part/Drawing
  Number` (and/or the CUI classifier) and applies the correct label; seed a pilot site with sample IP/
  CUI content and re-run. Never turn the policy on until the simulation is clean.

## DLP policy tips don't appear / no audit events
- **Symptom:** No policy tips or Activity-explorer events from `DLP Policy - Manufacturing IP and CUI -
  Audit`.
- **Likely cause:** Policy still deploying; **audit logging off** (Requirement 2.7); the location isn't
  in scope; endpoint devices not onboarded.
- **Resolve:** Confirm auditing is on and returning results; run `PURVIEW-MFG-Report.ps1` for the
  event summary; verify the policy's locations and pilot scoping; for endpoint rules, confirm devices
  show under **Settings → Device onboarding**.

## DLP blocks legitimate supplier / engineering work
- **Symptom:** After enforce, real drawings/specs to trusted partners are blocked.
- **Likely cause:** The policy was enforced before the **audit gate** was clean, or the trusted partner
  domains (Requirement 2.6) aren't in the recipient exceptions.
- **Resolve:** **Rollback** — set `DLP Policy - Manufacturing IP and CUI - Enforce` back to **Test
  mode** (audit); add the trusted partner domains as exceptions; keep export-control as a hard block;
  re-tune in audit, then re-enforce only after the gate passes.

## Label encryption breaks a legacy CAD / engineering app
- **Symptom:** An encrypted `MFG-Confidential-IP` / `MFG-CUI` file won't open in a legacy app.
- **Likely cause:** The application doesn't understand Microsoft Purview encryption/rights.
- **Resolve:** Pilot encryption on a small scope first; for apps that can't consume protection, adjust
  the label's encryption/permissions or exclude those file paths from auto-labeling; validate with data
  owners before broad enforcement.

## Endpoint DLP rules don't fire (USB / print / upload)
- **Symptom:** Copy-to-USB, print, or browser-upload of a labelled drawing isn't audited/blocked.
- **Likely cause:** Engineering workstations aren't **onboarded** to Purview, or **Devices** isn't a
  location on the policy.
- **Resolve:** Onboard devices (the Defender for Endpoint / Intune onboarding), confirm they appear
  under device onboarding, and ensure the DLP policy includes **Devices** with the endpoint actions.

## Retention isn't applying (or deleted too much)
- **Symptom:** `Retention Label - Quality and Contract Records - 7 Year` or `Retention Policy -
  Manufacturing Baseline - 5 Year` doesn't behave as expected.
- **Likely cause:** Policy still propagating; wrong locations; duration/end-action from a **guess**
  rather than the records schedule.
- **Resolve:** Confirm the policy is **On** and scoped (`PURVIEW-MFG-Validation.ps1`); use **disposition
  review** so nothing auto-deletes unreviewed. **Retention durations and records determinations are
  records/compliance/legal calls** — confirm the schedule before activating deletion.

## CMMC / NIST 800-171 assessment template not available
- **Symptom:** `Assessment - CMMC / NIST 800-171 - Manufacturing` can't be created.
- **Likely cause:** The premium **Compliance Manager** template needs E5 / E5 Compliance and varies by
  cloud.
- **Resolve:** Confirm the plan; **verify your tenant**. Where the template is absent, evidence the same
  controls against the available baseline and record the gap — **the CMMC applicability is a compliance
  determination**, deferred.

## PowerShell can't connect or a cmdlet is missing
- **Symptom:** `Connect-IPPSSession` fails, or `Get-Label` / `Get-DlpCompliancePolicy` is unavailable.
- **Likely cause:** ExchangeOnlineManagement module missing/old, or MFA/modern-auth blocked.
- **Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser`; sign in with an MFA-capable
  Compliance Administrator; retry. A cmdlet that stays missing after a good connection is a plan/cloud
  gap — **verify your tenant.**

---
### Escalation & rollback
| Situation | Action |
|---|---|
| DLP enforce disrupts work | Revert to **Test mode** (audit); fix exceptions; re-run the audit gate |
| Auto-labeling mislabels | Turn the policy back to **simulation**; fix the rule; re-simulate |
| Retention deleting wrongly | Disable the retention policy; enable **disposition review**; confirm the schedule with records/legal |
| Feature genuinely absent | Treat as licensing/cloud gap (Req 2.1) — **verify your licensing/tenant**, not a step error |
| Records / CUI / export-control question | **Determination deferred** to compliance/records/legal/export-control — capture, don't decide |
