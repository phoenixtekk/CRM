# 6. Troubleshooting Guide — Technical Blocker Mitigation: Defender for Office 365

The four blocker classes in **symptom → cause → fix** form, plus escalation. Run `TBMMDO-Discovery.ps1` and `TBMMDO-MailFlow.ps1` first — most causes surface there. This *is* the troubleshooting solution, so this guide is the core reference.

## Mail bypasses filtering (routing conflict)
**Symptom:** Messages arrive without any MDO stamps; Safe Attachments / anti-phish never act; `EmailEvents` shows mail not scanned by EOP.
**Cause:** Inbound mail does not reach **EOP** first — MX points elsewhere, or an inbound connector / third-party gateway / hybrid path pre-delivers or forwards mail past filtering.
**Fix:** Run `TBMMDO-MailFlow.ps1`; correct the public **MX** to EOP, or adjust/remove the **inbound connector** or gateway that bypasses filtering (per Requirements 2.4). *This changes delivery — pilot on the affected recipients' path and confirm mail flows before wider change.* Re-run `TBMMDO-Validate.ps1`.

## Policy configured but never applies (precedence)
**Symptom:** A Safe Links / Safe Attachments / anti-phish policy exists and looks correct, but the affected recipients get a different (or no) protection.
**Cause:** A **preset security policy** or a higher-priority **custom policy** wins, or the affected recipients are in the policy's **exclusion** list — only one policy of each type applies per recipient.
**Fix:** In `TBMMDO-Discovery.ps1` output, find the **winning** policy for the affected recipients. Adjust **priority** so the intended policy wins, or remove the exclusion, in **Threat policies**. Do not clone more policies. Re-run `TBMMDO-Validate.ps1`.

## Safe Links not rewriting
**Symptom:** URLs in test mail are not wrapped/rewritten; `UrlClickEvents` shows nothing for the affected recipients.
**Cause:** The winning Safe Links policy is disabled, not scoped to the recipients, or URL-rewrite is off; or mail bypassed EOP (see routing).
**Fix:** Confirm routing (Test 2). Enable the Safe Links policy and add `MDO Blocker Triage – Affected Recipients – Diagnose` to its included scope; confirm URL rewrite is on. Allow propagation, send the safe test URL, re-run `TBMMDO-Validate.ps1`.

## Safe Attachments not detonating
**Symptom:** Test attachment is delivered without detonation/hold; no Safe Attachments action in message trace.
**Cause:** The winning Safe Attachments policy is disabled or unscoped, the action is set to Off/Monitor, or mail bypassed EOP.
**Fix:** Confirm routing. Enable the policy, scope it to the affected recipients, set the intended action (Block/Dynamic Delivery per your design). Allow propagation, send the benign test attachment (standard Microsoft procedure), re-run `TBMMDO-Validate.ps1`.

## Licensing gap
**Symptom:** Safe Links/Attachments (P1) or Explorer/Attack Simulation (P2) options are missing or greyed out.
**Cause:** The MDO plan the feature needs is not assigned.
**Fix:** Assign the plan (**Billing → Licenses**). *Verify the exact plan the feature needs — availability changes; confirm in your tenant.* Re-run `TBMMDO-Discovery.ps1`.

## Script cannot authenticate
**Symptom:** `TBMMDO-*.ps1` fails on `Connect-ExchangeOnline` / `Connect-MgGraph` or returns access-denied.
**Cause:** The ExchangeOnlineManagement module is missing, the account lacks a View-Only Exchange / Reader role, or `ThreatHunting.Read.All` consent was not granted.
**Fix:** `Install-Module ExchangeOnlineManagement`; sign in with a Global/Security Reader + View-Only Exchange role; consent to `ThreatHunting.Read.All`. Re-run.

## When to escalate to Microsoft support
Escalate — and attach `MDO Support Bundle – <case> – Escalate` — when **all** of the following hold:
- Mail routing reaches EOP (Test 2 passes).
- The **winning** policy for the affected recipients is the intended one, enabled and scoped (Tests 3–5).
- The required MDO plan is assigned (Test 6).
- Policy propagation time elapsed, yet the test message still is not protected.
In that case the root cause is likely a **service-side issue**, not your configuration. Run `TBMMDO-SupportBundle.ps1`, open the case, and attach the bundle with message-trace IDs. *Incident-response decisions remain the SOC's; this is a service-support escalation.*
