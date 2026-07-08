# 6. Troubleshooting — HIPAA / PHI DLP Pack (Microsoft Purview)

Symptom-first fixes for the failures you actually hit implementing PHI DLP across email, cloud, Teams,
and endpoint. Most problems are one of: a policy not matching PHI, PHI *over*-matching (false
positives), the endpoint location unavailable, or matches that raise no alert / no escalation.

---

## Policy / PHI detection

**A PHI DLP policy matches nothing even though the content clearly contains PHI.**
- Confirm the policy is actually **enabled and in a mode that evaluates** — a *disabled* policy does
  nothing; a **simulation** policy evaluates and logs but does not block. Check with
  `PHIDLP-Discovery.ps1` / `PHIDLP-Validate.ps1` (Mode column).
- **PHI often needs a combination.** If the rule requires *both* an identifier (SSN/MRN) **and** a
  clinical detector (ICD-9/ICD-10) and your test has only one, it correctly won't fire. Test with a
  paired sample, or relax the co-occurrence for the test.
- Check the **instance count and confidence** on the rule — if it requires high confidence / multiple
  instances and your sample is a single low-confidence hit, it won't match. Adjust for testing.
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (and
  longer for some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing (the specific site/user), and that the
  test identity isn't in an **exclusion**.

**The custom MRN SIT never matches.**
- Test the SIT's **regex + keywords** in the SIT wizard's **Test** step with a known-matching (fake)
  MRN. A too-strict regex, wrong **character proximity**, or a required keyword ("MRN"/"medical record")
  that isn't present will suppress all matches. Loosen and re-test incrementally.

**The built-in HIPAA template / a HIPAA SIT isn't available.**
- The template lives under **Data loss prevention → Create policy → Medical and health records → U.S.
  Health Insurance Act (HIPAA)** — but the **SIT library and templates evolve and are licensing-
  dependent**. If it's absent, **verify your licensing/tenant** and build a custom policy with the
  available SITs (SSN, ICD-9-CM, ICD-10-CM, DEA Number) instead. Don't assume a named SIT exists —
  confirm it in **Data classification → Classifiers → Sensitive info types**.

**Matches appear in simulation but nothing is blocked/encrypted.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block/encrypt, move
  the policy to **enforce** for the pilot ring (Implementation Phase 4). If you expected action, you're
  still in simulation.

## PHI over-matching (the adoption killer)

**Clinicians are getting policy tips on legitimate, non-PHI content (account numbers, order IDs).**
- Export matches with `PHIDLP-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Require co-occurrence** (identifier + clinical detector) so a lone 9-digit number or a lone ICD code
  doesn't fire — this removes the biggest PHI false-positive source.
- **Raise confidence** (medium→high) and/or **instance count** so single/low-confidence hits don't fire.
- Add **supporting keywords/proximity** to the custom MRN SIT so context is required.
- For a built-in SIT that over-matches your internal identifiers, move that category to **Exact Data
  Match** against your roster so only your real identifiers match.
- Add a targeted **exception** where justified (e.g. a sanctioned claims clearinghouse address) —
  narrowly, with a documented reason.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

## Endpoint DLP

**The Devices/Endpoint location isn't available when creating a policy.**
- **Licensing:** Endpoint DLP requires the appropriate plan (E5 / E5 Compliance) — run
  `PHIDLP-ScopeHealth.ps1` for the licensing signal and **verify in the admin center**.
- **Onboarding:** the Devices location depends on **onboarded devices** — confirm in **Purview portal →
  Settings → Device onboarding**. No onboarded devices → the location does nothing even if selectable.

**Endpoint policy is enforced but device activities (USB/print/upload) aren't caught.**
- Confirm the specific **device is onboarded and reporting** (portal device list), meets the **minimum
  OS build**, and — for some activities — that the required agent/AV prerequisites per Microsoft docs
  are met.
- Confirm the **activity is in scope** of the rule (e.g. "copy to USB" is enabled) and that the
  app/browser or network path isn't on an **allowed/exception** list.
- Allow for **reporting latency** — endpoint events can take time to surface in Activity Explorer.

## Alerts / incident handling & escalation

**PHI matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data
  loss prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on
  it.
- Confirm the **triage owner/queue** (`PHI DLP Alerts – Triage – Operations`) exists and that the
  **Privacy/Security-Officer escalation path** is wired (Req 2.7). If forwarding to SIEM/Sentinel,
  confirm the connector is healthy.

**A possible reportable disclosure was found — what does the tool decide?**
- **Nothing.** The DLP tool surfaces and evidences a *potential* PHI disclosure; the **breach
  determination (and any notification) is a Privacy/Security-Officer and legal decision** — escalate via
  the C3 path, don't treat a DLP alert as a breach ruling.

**The report script returns no matches.**
- **Audit log latency:** DLP events can take time to appear; widen `-Days` and re-run.
- Freshly created policies need **dwell time** — there may simply be no matches yet.
- Confirm **audit logging is on** and your account has the **View-Only DLP / audit** role.

## Connectivity / tooling

**`Connect-IPPSSession` or a DLP cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin.
- Confirm the account holds the required **DLP role** (Compliance Administrator / Compliance Data
  Administrator / DLP Compliance Management) — a missing role surfaces as "cmdlet not recognized" or
  access denied.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`, and the
  config helper is **simulation-only**. If a change landed, it was committed intentionally — the config
  helper never leaves a policy in **enforce**, so the safe recovery is always to set the policy back to
  **simulation** in the portal (one setting, no data change).

---

### Fast triage table

| Symptom | First check |
|---|---|
| PHI policy matches nothing | Mode (disabled/sim), **co-occurrence** requirement, instance count/confidence, propagation, scope/exclusion |
| Custom MRN SIT never fires | Test regex+keywords+proximity in the SIT wizard |
| HIPAA template/SIT missing | Licensing/tenant; build custom with SSN/ICD-9/ICD-10/DEA instead |
| Nothing blocked/encrypted | Still in **simulation** — that's expected; enforce the ring to act |
| Too many false positives | Require co-occurrence, raise confidence/instance count, add keywords/EDM, exceptions, re-simulate |
| Devices location missing | Licensing (E5/E5 Compliance) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed-app/network exceptions |
| No alert on match | Alert config on rule, audit logging on, triage owner + Privacy/Security escalation, SIEM connector |
| "Is this a breach?" | Not a DLP decision — **escalate to Privacy/Security/legal** |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |
