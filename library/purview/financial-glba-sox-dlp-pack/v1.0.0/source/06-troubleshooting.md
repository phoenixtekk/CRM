# 6. Troubleshooting — Financial (GLBA/SOX) DLP Pack (Microsoft Purview)

Symptom-first fixes for the failures you actually hit implementing financial/NPI DLP across email, cloud,
Teams, and endpoint. Most problems are one of: a policy not matching, the endpoint location unavailable,
too many false positives on financial numbers, or matches that raise no alert.

---

## Policy / detection

**A financial DLP policy matches nothing even though the content clearly contains NPI.**
- Confirm the policy is actually **enabled and in a mode that evaluates** — a *disabled* policy does
  nothing; a **simulation** policy evaluates and logs but does not block. Check with
  `DLPFIN-Discovery.ps1` (Mode column) or `DLPFIN-Validate.ps1`.
- Check the **instance count and confidence** on the rule — if it requires ≥10 matches at High confidence
  and your test file has 1 fake account number, it correctly won't fire. Lower the threshold for testing,
  or add more sample instances.
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (and
  longer for some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing (e.g. the specific finance site/user), and
  that the test identity isn't in an **exclusion** (e.g. the payments-processor mailbox you excepted).

**A custom `Account Number` / `GL Account Code` SIT never matches.**
- Test the SIT's **regex + keywords** in the SIT wizard's **Test** step with known-matching text. A too-
  strict regex, wrong **character proximity**, or a required keyword (e.g. *account*, *acct*) that isn't
  present will suppress all matches. Loosen and re-test incrementally.

**The GLBA / U.S. Financial Data template isn't where the docs say, or has different SITs.**
- **Template names and membership evolve.** Verify the exact template name and its bundled SITs in your
  tenant (**Data loss prevention → Create policy**); the pack flags this rather than asserting a fixed
  name. If the template doesn't fit, build a custom policy with the financial SITs you confirmed in
  Discovery.

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block, move the policy to
  **enforce** for the finance ring (Implementation Phase 4) after compliance signs off the enforced action.

## Endpoint DLP (finance/treasury laptops)

**The Devices/Endpoint location isn't available when creating a policy.**
- **Licensing:** Endpoint DLP requires the appropriate plan (E5 / E5 Compliance) — run `DLPFIN-Scope.ps1`
  (health section) for the licensing signal and **verify in the admin center**.
- **Onboarding:** the Devices location depends on **onboarded devices** — confirm in **Purview portal →
  Settings → Device onboarding**. No onboarded finance devices → the location does nothing even if
  selectable.

**Endpoint policy is enforced but device activities (USB/print/upload) aren't caught.**
- Confirm the specific **finance device is onboarded and reporting** (portal device list), meets the
  **minimum OS build**, and — for some activities — that the required agent/AV prerequisites per Microsoft
  docs are met.
- Confirm the **activity is in scope** of the rule (e.g. "copy to USB" is enabled) and that the app/browser
  or network path isn't on an **allowed/exception** list (a sanctioned finance tool may be allow-listed).
- Allow for **reporting latency** — endpoint events can take time to surface in Activity Explorer.

## False positives (the adoption killer for finance)

**Finance users get policy tips on legitimate, non-sensitive content (GL codes, invoice IDs, reference numbers).**
- Export matches with `DLPFIN-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver — often a
  built-in *Credit Card* / *ABA Routing* SIT firing on internal numbers, or an over-broad custom
  `Account Number` SIT.
- **Raise confidence** (medium→high) and/or **instance count** so single/low-confidence hits don't fire.
- Add **supporting keywords/proximity** to custom SITs so financial context is required, not just a numeric
  pattern.
- For a built-in SIT that over-matches your internal identifiers, move that category to **Exact Data Match**
  (`Customer NPI – EDM – Financial`) so only your real account data matches.
- Add a targeted **exception** where justified (e.g. the reconciliation site, the payments mailbox) —
  narrowly, with a documented reason.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

## Alerts / incident handling

**Financial DLP matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data loss
  prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on it.
- Confirm the **triage owner/queue** (`DLP Alerts – Financial – Operations`) exists and, if forwarding to
  SIEM/Sentinel, that the connector is healthy (Req 2.7).

**Triagers can't see (or can see too much of) the NPI in the match evidence.**
- Match evidence contains protected data. Confirm the **evidence-access control** (Req 2.7) grants view of
  NPI only to the authorized role — adjust role-group membership so triage works without over-exposing NPI.

**The report script returns no matches.**
- **Audit log latency:** DLP events can take time to appear; widen `-Days` and re-run (default 30 spans a
  reporting cycle).
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
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`. `DLPFIN-Config.ps1`
  never leaves a policy in **enforce** and `DLPFIN-Scope.ps1` never flips enforcement mode, so the safe
  recovery is always to set the policy back to **simulation** in the portal (one setting, no data change).

---

### Fast triage table

| Symptom | First check |
|---|---|
| Policy matches nothing | Mode (disabled/sim), instance count/confidence, propagation time, scope/exclusion |
| Custom account/GL SIT never fires | Test regex+keywords+proximity in the SIT wizard |
| GLBA template missing/different | Template names evolve — verify in tenant; build custom from confirmed SITs |
| Nothing blocked | Still in **simulation** — that's expected; enforce the finance ring to block |
| Devices location missing | Licensing (E5/E5 Compliance) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed-app/network exceptions |
| Too many false positives | Raise confidence/instance count, add keywords/EDM, exceptions, re-simulate |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Evidence over/under exposed | Evidence-access role (Req 2.7) |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |
