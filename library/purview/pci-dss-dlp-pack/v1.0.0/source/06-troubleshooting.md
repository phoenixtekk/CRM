# 6. Troubleshooting — PCI-DSS DLP Pack (Microsoft Purview)

Symptom-first fixes for the failures you actually hit implementing cardholder-data DLP across email,
cloud, Teams, and endpoint. Most problems are one of: a PAN policy not matching, the endpoint location
unavailable, too many false positives (Luhn-valid internal numbers), or matches that raise no alert.

---

## Policy / PAN detection

**A PAN DLP policy matches nothing even though the content clearly contains a card number.**
- Confirm the policy is actually **enabled and in a mode that evaluates** — a *disabled* policy does
  nothing; a **simulation** policy evaluates and logs but does not block. Check with
  `PURVPCI-Discovery.ps1` (Mode column).
- Check the **instance count and confidence** on the rule — if it requires ≥10 PANs at High confidence and
  your test has 1, it correctly won't fire. Use the **single-PAN** policy (MinCount 1) for lone-card tests,
  or add more fake test PANs.
- **Use a Luhn-valid test PAN.** The built-in Credit Card Number SIT enforces the **Luhn checksum** — an
  invalid number (random digits) will not match by design. Use a documented test PAN
  (`4111 1111 1111 1111`, `4242 4242 4242 4242`).
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (and
  longer for some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing, and that the test identity isn't in an
  **exclusion** (e.g. the sanctioned in-CDE application you scoped out).

**High-confidence matching seems to miss some card numbers.**
- The built-in SIT raises confidence when **supporting keywords** (card-brand names, "credit card", etc.)
  are near the number. A bare PAN with no context matches at **lower** confidence — if your rule requires
  High, add a medium-confidence tier or a keyword-independent variant for the "bare PAN in a file" case.

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block, move the policy to
  **enforce** for the pilot ring (Implementation Phase 4). If you expected blocking, you're still in
  simulation.

## Endpoint DLP

**The Devices/Endpoint location isn't available when creating a policy.**
- **Licensing:** Endpoint DLP requires the appropriate plan (E5 / E5 Compliance) — run
  `PURVPCI-EndpointReadiness.ps1` for the licensing signal and **verify in the admin center**.
- **Onboarding:** the Devices location depends on **onboarded devices** — confirm in **Purview portal →
  Settings → Device onboarding**. No onboarded devices → the location does nothing even if selectable.

**Endpoint policy is enforced but device activities (USB/print/upload) aren't caught.**
- Confirm the specific **device is onboarded and reporting** (portal device list), meets the **minimum OS
  build**, and — for some activities — that the required agent/AV prerequisites per Microsoft docs are met.
- Confirm the **activity is in scope** of the rule (e.g. "copy to USB" is enabled) and that the app/browser
  or network path isn't on an **allowed/exception** list.
- Allow for **reporting latency** — endpoint events can take time to surface in Activity Explorer.

## False positives (the adoption killer)

**Users get policy tips on legitimate content — the number is an internal reference/order number, not a
card.**
- This is the classic PAN false positive: the Credit Card SIT fires on any **Luhn-valid 13–19 digit**
  sequence. Export matches with `PURVPCI-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Raise confidence** so only keyword-supported (High) matches fire, and/or **raise instance count** so a
  single stray number doesn't trigger.
- For internal identifiers that keep over-matching, move that PAN check to **Exact Data Match**
  (`Cardholder PAN – EDM – PCI`) so only your *real* card numbers match — internal reference numbers won't.
- Add a targeted **exception** where justified (the sanctioned in-CDE payment mailbox/site) — narrowly,
  with a documented reason.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

**A truncated/masked card number is being flagged.**
- A properly **truncated** PAN (first-six/last-four per PCI display rules) is not a full PAN and should not
  match a full-PAN detector — if it does, your content likely contains **more than the allowed digits**.
  Confirm what's actually in the content before treating it as a false positive.

## Alerts / incident handling

**PAN matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data loss
  prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on it.
- Confirm the **triage owner/queue** (`PCI DLP Alerts – Triage – Operations`) exists and, if forwarding to
  SIEM/Sentinel, that the connector is healthy (Req 2.7).

**The report script returns no matches.**
- **Audit log latency:** DLP events can take time to appear; widen `-Days` and re-run.
- Freshly created policies need **dwell time** — there may simply be no card-data matches yet.
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
| PAN policy matches nothing | Mode (disabled/sim), instance count/confidence, Luhn-valid test PAN, propagation time, scope/exclusion |
| High-confidence misses bare PANs | Bare PAN matches at lower confidence — add a keyword-independent/medium tier |
| Nothing blocked | Still in **simulation** — that's expected; enforce the ring to block |
| Devices location missing | Licensing (E5/E5 Compliance) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed-app/network exceptions |
| FP on internal reference numbers | Raise confidence/instance count, move to **EDM**, add exceptions, re-simulate |
| Truncated PAN flagged | Confirm content isn't carrying more than first-six/last-four |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |
