# 6. Troubleshooting — Microsoft Purview Data Loss Prevention (DLP)

Symptom-first fixes for the failures you actually hit implementing DLP across email, cloud, Teams, and
endpoint. Most problems are one of: a policy not matching, the endpoint location unavailable, too many
false positives, or matches that raise no alert.

---

## Policy / detection

**A DLP policy matches nothing even though the content clearly contains sensitive data.**
- Confirm the policy is actually **enabled and in a mode that evaluates** — a *disabled* policy does
  nothing; a **simulation** policy evaluates and logs but does not block. Check with
  `PURVDLP-Discovery.ps1` (Mode column).
- Check the **instance count and confidence** on the rule — if it requires ≥10 matches at High confidence
  and your test has 1, it correctly won't fire. Lower the threshold for testing, or add more sample
  instances.
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (and
  longer for some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing (e.g. the specific site/user), and that the
  test identity isn't in an **exclusion**.

**A custom SIT never matches.**
- Test the SIT's **regex + keywords** in the SIT wizard's **Test** step with known-matching text. A too-
  strict regex, wrong **character proximity**, or a required keyword that isn't present will suppress all
  matches. Loosen and re-test incrementally.

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block, move the policy to
  **enforce** for the pilot ring (Implementation Phase 4). If you expected blocking, you're still in
  simulation.

## Endpoint DLP

**The Devices/Endpoint location isn't available when creating a policy.**
- **Licensing:** Endpoint DLP requires the appropriate plan (E5 / E5 Compliance) — run
  `PURVDLP-EndpointReadiness.ps1` for the licensing signal and **verify in the admin center**.
- **Onboarding:** the Devices location depends on **onboarded devices** — confirm in **Purview portal →
  Settings → Device onboarding**. No onboarded devices → the location does nothing even if selectable.

**Endpoint policy is enforced but device activities (USB/print/upload) aren't caught.**
- Confirm the specific **device is onboarded and reporting** (portal device list), meets the **minimum OS
  build**, and — for some activities — that the required agent/AV prerequisites per Microsoft docs are met.
- Confirm the **activity is in scope** of the rule (e.g. "copy to USB" is enabled) and that the app/browser
  or network path isn't on an **allowed/exception** list.
- Allow for **reporting latency** — endpoint events can take time to surface in Activity Explorer.

## False positives (the adoption killer)

**Users are getting policy tips on legitimate, non-sensitive content.**
- Export matches with `PURVDLP-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Raise confidence** (medium→high) and/or **instance count** so single/low-confidence hits don't fire.
- Add **supporting keywords/proximity** to custom SITs so context is required.
- For a built-in SIT that over-matches your internal identifiers, move that category to **Exact Data
  Match** so only your real data matches.
- Add a targeted **exception** where justified (specific sender/site) — narrowly, with a documented reason.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

## Alerts / incident handling

**Policy matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data loss
  prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on it.
- Confirm the **triage owner/queue** (`DLP Alerts – Triage – Operations`) exists and, if forwarding to
  SIEM/Sentinel, that the connector is healthy (Req 2.7).

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
| Nothing blocked | Still in **simulation** — that's expected; enforce the ring to block |
| Devices location missing | Licensing (E5/E5 Compliance) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed-app/network exceptions |
| Too many false positives | Raise confidence/instance count, add keywords/EDM, exceptions, re-simulate |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |
