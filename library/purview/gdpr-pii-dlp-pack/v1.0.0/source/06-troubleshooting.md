# 6. Troubleshooting — GDPR / PII DLP Pack (Microsoft Purview)

Symptom-first fixes for the failures you actually hit implementing personal-data DLP across email, cloud,
Teams, and endpoint. Most problems are one of: a policy not matching, the custom SIT not firing, the endpoint
location unavailable, too many false positives, or matches that raise no alert.

---

## Policy / detection

**A DLP policy matches nothing even though the content clearly contains personal data.**
- Confirm the policy is actually **enabled and in a mode that evaluates** — a *disabled* policy does nothing;
  a **simulation** policy evaluates and logs but does not block. Check with `DLPGDPR-Discovery.ps1` (Mode
  column) or `DLPGDPR-Validate.ps1`.
- Check the **instance count and confidence** on the rule — if it requires ≥5 identifiers at High confidence
  and your test has 1, it correctly won't fire. Lower the threshold for testing, or add more sample
  instances.
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (and longer
  for some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing (e.g. the specific site/user), and that the
  test identity isn't in an **exclusion** (e.g. a DPO/HR mailbox the privacy function scoped out).

**The `EU National ID – Custom SIT – GDPR` never matches.**
- Test the SIT's **regex + keywords** in the SIT wizard's **Test** step with a fabricated ID that matches
  your format. A too-strict regex, wrong **character proximity**, or a required keyword that isn't present
  will suppress all matches. Loosen and re-test incrementally.
- If it matches *too much* (e.g. every number of that length), that's a precision problem, not a miss — add/
  require supporting keywords ("national ID", the member-state term) and tighten proximity (see False
  positives below).

**An EU built-in SIT (e.g. EU National Identification Number) isn't in the SIT list.**
- SIT names and availability are **version-/tenant-dependent** — the exact display name may differ or a SIT
  may be surfaced under a per-country name. Run `DLPGDPR-Discovery.ps1` (it probes the EU set by name) and
  **verify the current name in your tenant** rather than assuming; do not hand-invent a SIT name in a rule.

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block, move the policy to
  **enforce** for the pilot ring (Implementation Phase 4). If you expected blocking, you're still in
  simulation.

**A match to an external recipient — is it a cross-border transfer?**
- DLP flags the *content* and (with the *recipient is external* condition) that it left to an external party.
  **Whether that is a restricted cross-border transfer, and what safeguard applies, is a DPO/legal
  determination** — not a detector fault. Route it to the DPO hand-off (Req 2.7); don't weaken the detector.

## Endpoint DLP

**The Devices/Endpoint location isn't available when creating a policy.**
- **Licensing:** Endpoint DLP requires the appropriate plan (E5 / E5 Compliance) — check the licensing signal
  with `DLPGDPR-Validate.ps1` and **verify in the admin center**.
- **Onboarding:** the Devices location depends on **onboarded devices** — confirm in **Purview portal →
  Settings → Device onboarding**. No onboarded devices → the location does nothing even if selectable.

**Endpoint policy is enforced but device activities (USB/print/upload) aren't caught.**
- Confirm the specific **device is onboarded and reporting** (portal device list), meets the **minimum OS
  build**, and — for some activities — that the required agent/AV prerequisites per Microsoft docs are met.
- Confirm the **activity is in scope** of the rule (e.g. "copy to USB" is enabled) and that the app/browser
  or network path isn't on an **allowed/exception** list (e.g. a sanctioned CRM/HR tool).
- Allow for **reporting latency** — endpoint events can take time to surface in Activity Explorer.

## False positives (the adoption killer)

**Staff are getting policy tips on legitimate, non-personal-data content.**
- Export matches with `DLPGDPR-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Raise confidence** (medium→high) and/or **instance count** (a single ID is often legitimate; a bulk list
  is a leak) so low-signal hits don't fire.
- Add **supporting keywords/proximity** to the custom SIT so context is required, not just a number pattern.
- For a built-in SIT (or a pattern SIT) that over-matches your identifiers, move that category to **Exact
  Data Match** (`Data Subject Records – EDM – GDPR`) so only your real records match.
- Add a targeted **exception** where the DPO function has justified it (specific mailbox/site) — narrowly,
  with a documented reason.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

## Alerts / incident handling

**Policy matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data loss
  prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on it.
- Confirm the **triage owner/queue** (`GDPR DLP Alerts – Triage – Operations`) exists and, if forwarding to
  SIEM/Sentinel, that the connector is healthy (Req 2.7).

**A real exposure occurred — who decides if it's a notifiable breach?**
- The control raises the alert and preserves the evidence; **whether the exposure is a notifiable
  personal-data breach (and the GDPR notification timeline) is a DPO/legal determination.** Ensure the triage
  workflow hands off to the DPO/breach process (Req 2.7) — the control does not make the breach call.

**Triage staff can't see the alert evidence (or see too much).**
- Alert evidence contains personal data — access is governed by **role**. Confirm the triage owner holds the
  least-privilege **Data Loss Prevention / View-Only DLP** role and nothing broader (Req 2.2/2.7) — this is
  data-minimisation applied to the control's own records.

**The report script returns no matches.**
- **Audit log latency:** DLP events can take time to appear; widen `-Days` and re-run.
- Freshly created policies need **dwell time** — there may simply be no matches yet.
- Confirm **audit logging is on** and your account has the **View-Only DLP / audit** role.

## Connectivity / tooling

**`Connect-IPPSSession` or a DLP cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin.
- Confirm the account holds the required **DLP role** (Compliance Administrator / Compliance Data
  Administrator / DLP Compliance Management) — a missing role surfaces as "cmdlet not recognized" or access
  denied.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`. If a change
  landed, it was committed intentionally — the config helper never leaves a policy in **enforce**, so the
  safe recovery is always to set the policy back to **simulation** in the portal (one setting, no data
  change).

---

### Fast triage table

| Symptom | First check |
|---|---|
| Policy matches nothing | Mode (disabled/sim), instance count/confidence, propagation time, scope/exclusion |
| Custom SIT never fires | Test regex+keywords+proximity in the SIT wizard |
| Custom SIT over-matches | Require supporting keywords, tighten proximity, or move to EDM |
| EU built-in SIT not listed | Verify current SIT name in tenant (version-dependent) — don't invent a name |
| Nothing blocked | Still in **simulation** — that's expected; enforce the ring to block |
| External-recipient match | May be a cross-border transfer — a DPO/legal call, route to breach hand-off |
| Devices location missing | Licensing (E5/E5 Compliance) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed-app/network exceptions |
| Too many false positives | Raise confidence/instance count, add keywords/EDM, exceptions, re-simulate |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Breach or not? | DPO/legal determination — control preserves evidence, doesn't decide |
| Evidence access wrong | Least-privilege DLP role on the triage owner (data-minimisation) |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |
