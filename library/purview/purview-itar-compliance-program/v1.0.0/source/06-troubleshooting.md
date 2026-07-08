# 6. Troubleshooting Guide — Microsoft Purview ITAR Compliance Program

Common field issues for the ITAR export-control program and how to resolve them. Objects are named
verbatim from the Implementation Guide. Most problems are **licensing/cloud gaps**, **replication delay**,
or **audit not-yet-tuned** — not step mistakes. When a feature is simply absent, treat it as a plan/cloud
gap (Requirement 2.1) and **verify your licensing/tenant** first. Remember the boundary: **ITAR
applicability, USML classification, the U.S.-person determination, licenses/agreements, the sovereign-
cloud decision, retention schedules, and any voluntary-disclosure decision are export-control/legal
determinations** — the tooling configures and evidences, it does not decide. And for ITAR, **under-blocking
is an unauthorized-export risk** — prefer keeping the recipient hard-block on and tuning exceptions.

## ITAR data is in the wrong cloud
- **Symptom:** Uncertainty whether the tenant/cloud is appropriate for ITAR technical data.
- **Likely cause:** ITAR data generally requires a **U.S. sovereign cloud (GCC High)** (Requirement 2.1).
- **Resolve:** Confirm the cloud/tenant with **export-control/legal before placing any controlled data**.
  This is a legal/tenant determination, not a technical default — **verify your licensing/tenant.**

## The label doesn't restrict to authorized U.S. persons
- **Symptom:** An authorized user is blocked, or an unauthorized user can open a labelled item.
- **Likely cause:** The label's **encryption permissions** don't match the authorized-U.S.-person list, or
  replication delay.
- **Resolve:** Open `Sensitivity Label - ITAR Technical Data - Authorized US Persons` and confirm the
  encryption permissions restrict to the authorized list (Requirement 2.3); allow propagation; re-test.
  **The U.S.-person / authorized-recipient determination is export-control/legal's** — capture it, don't
  invent it.

## The custom SIT matches too much or too little
- **Symptom:** `SIT - ITAR/USML Markers` fires on ordinary text or misses real markings.
- **Likely cause:** Regex too broad/narrow, wrong **confidence level**, or too-wide **proximity**; missing
  supporting keywords.
- **Resolve:** Open the SIT → **Test** with real and decoy samples; tighten the regex, raise the
  confidence, add supporting keywords, reduce proximity. Prefer available export-control SITs where
  present.

## Auto-labeling simulation shows nothing (or the wrong items)
- **Symptom:** `Auto-Label - ITAR Technical Data - Pilot` simulation is empty or mislabels.
- **Likely cause:** Simulation still crawling; the condition/label is wrong; no matching content in scope.
- **Resolve:** Let the simulation complete; confirm the condition uses `SIT - ITAR/USML Markers` and
  applies the correct label; seed a pilot site with sample marked content; re-run. Never turn the policy
  on until the simulation is clean.

## DLP records nothing in audit
- **Symptom:** No policy tips or events from `DLP Policy - ITAR Export-Controlled - Audit`.
- **Likely cause:** Policy still deploying; **audit off** (Requirement 2.7); location out of scope;
  endpoint devices not onboarded.
- **Resolve:** Confirm auditing is on and returning results (`ITAR-EvidenceReport.ps1`); verify locations/
  scope; for endpoint rules, confirm devices show under **Settings → Device onboarding**.

## DLP blocks authorized program work after enforce
- **Symptom:** After enforce, sends to **authorized** recipients are blocked.
- **Likely cause:** The authorized recipients (Requirement 2.5) aren't in the DLP recipient exceptions, or
  the policy was enforced before the audit gate was clean.
- **Resolve:** Add the authorized recipients as exceptions; **keep the hard-block to unauthorized/foreign
  recipients on** and tune the exceptions rather than disabling the rule (under-blocking is an
  unauthorized-export risk). Re-tune in audit if needed, then re-enforce.

## Unauthorized/foreign send is NOT blocked
- **Symptom:** A send of marked/labelled data to an unauthorized recipient goes through.
- **Likely cause:** The DLP recipient condition is mis-scoped, the policy is still in test mode, or the
  content wasn't detected (SIT/label).
- **Resolve:** This is the highest-priority failure — confirm the DLP policy is in **Enforce** with the
  recipient **hard-block**, that the item is labelled/detected, and that the recipient condition covers
  the domains. **Deemed exports are an access/recipient problem** — fix detection and the recipient rule.

## Endpoint DLP rules don't fire (USB / print / upload)
- **Symptom:** Copy-to-USB, print, or upload of a marked item isn't audited/blocked.
- **Likely cause:** Workstations aren't **onboarded**, or **Devices** isn't a location on the policy.
- **Resolve:** Onboard devices, confirm they appear under device onboarding, and ensure the DLP policy
  includes **Devices** with the endpoint actions.

## Label encryption breaks a legacy engineering app
- **Symptom:** An encrypted technical-data file won't open in a legacy app.
- **Likely cause:** The application doesn't understand Microsoft Purview encryption/rights.
- **Resolve:** Pilot encryption on a small scope; for apps that can't consume protection, adjust the
  label's permissions or exclude those paths from auto-labeling; validate with data owners before broad
  enforcement.

## Retention isn't applying (export records)
- **Symptom:** `Retention Label - Export Records - Retention` doesn't behave as expected.
- **Likely cause:** Policy still propagating; wrong locations; duration/end-action from a **guess**.
- **Resolve:** Confirm the policy is **On** and scoped (`ITAR-Validation.ps1`); use **disposition
  review**. **Retention durations are a records/legal determination** — confirm the schedule.

## Export-control / ITAR assessment template not available
- **Symptom:** An ITAR-specific Compliance Manager template can't be found.
- **Likely cause:** No ITAR-specific template in your plan/cloud.
- **Resolve:** Evidence the controls against **NIST SP 800-171** / a custom assessment and record the
  mapping (Requirement 2.8); **verify your tenant.** Applicability remains an export-control determination.

## PowerShell can't connect or a cmdlet is missing
- **Symptom:** `Connect-IPPSSession` / `Connect-MgGraph` fails or a cmdlet is unavailable.
- **Likely cause:** Modules missing/old, MFA/modern-auth blocked, or (for GCC High) the wrong endpoint.
- **Resolve:** `Install-Module ExchangeOnlineManagement -Scope CurrentUser` (and Microsoft.Graph for the
  scope script); for GCC High confirm the correct sovereign endpoints; sign in with an MFA-capable
  authorized-U.S.-person Compliance Administrator; retry. A cmdlet still missing after a good connection is
  a plan/cloud gap — **verify your tenant.**

---
### Escalation & rollback
| Situation | Action |
|---|---|
| DLP enforce blocks authorized work | Add authorized-recipient exceptions; **keep the unauthorized hard-block on**; re-tune in audit |
| Unauthorized send not blocked | Highest priority — fix detection + recipient hard-block; confirm Enforce mode |
| Auto-labeling mislabels | Return the policy to **simulation**; fix the rule; re-simulate |
| Retention deleting wrongly | Disable the retention policy; enable **disposition review**; confirm the schedule with records/legal |
| Feature genuinely absent | Treat as licensing/cloud gap (Req 2.1) — **verify your licensing/tenant** |
| Applicability / USML / U.S.-person / disclosure question | **Determination deferred** to export-control/legal — capture, don't decide |
