# 6. Troubleshooting — ITAR DLP Pack (Microsoft Purview)

Symptom-first fixes for the failures you actually hit standing up ITAR technical-data DLP across email,
SharePoint/OneDrive, Teams, and endpoint. Most problems reduce to one of: the technical-data classification
not firing, a policy scoped or moded wrong, egress not being restricted as expected, too many false
positives on routine engineering work, or matches that raise no alert/evidence. All the delivered scripts
are **read-only or `-WhatIf` by default** — recovery is almost always a return to **simulation/test**, which
changes nothing for users.

---

## Detection / classification

**The `Technical Data SIT – Export Markings – Custom` never matches marked technical data.**
- Test the SIT's **regex, keyword dictionary, and character proximity** in the SIT wizard's **Test** step
  with a *fabricated* document carrying the export-control markings in scope (ITAR/USML references,
  distribution statements, the AECA warning legend). A too-strict regex, wrong proximity window, or a
  required keyword that isn't present suppresses all matches. Loosen and re-test incrementally.
- Confirm the **instance count / confidence** on the rule — if it requires several instances at High
  confidence and your test document has one marking, it correctly won't fire. Lower for testing, then re-tune.
- Prefer the **label condition** where you can: a rule keyed on *content has label `Export Controlled //
  ITAR`* is the most durable signal and sidesteps regex tuning entirely for labeled items.

**The classification matches *too much* (routine engineering docs flagged).**
- That is a precision problem, not a miss — add/require **supporting keywords** and tighten **proximity** so
  a bare part-number pattern alone doesn't fire, and raise **confidence/instance count**. Where E5 permits,
  move a high-value identifier set to **Exact Data Match (EDM)** so only known controlled records match.
- See *False positives* below — export matches with `DLPITAR-Report.ps1` first, classify TP/FP, then tune
  one driver at a time and re-simulate.

## Policy / scope / mode

**A DLP policy matches nothing even though the content clearly contains technical data.**
- Confirm the policy is in a **mode that evaluates**: *Disable* does nothing; *TestWithNotifications /
  TestWithoutNotifications* (**simulation**) evaluates and logs but does not block; *Enable* enforces. Check
  the mode with `DLPITAR-Discovery.ps1` or `DLPITAR-Validation.ps1`.
- **Propagation takes time** — a newly created or changed DLP policy can take **up to ~1 hour (longer for
  some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **workload scope** covers where you're testing and that the test identity isn't in an
  **exclusion** or outside `ITAR Pilot Ring – Stage1`. Run `DLPITAR-Scope-Health.ps1` to see the coverage map.

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation records what *would* have happened without enforcing. To restrict egress,
  the policy must be promoted to **enforce** (`DLPITAR-Set-Policy.ps1 -PromoteToEnforce -Commit`) after the
  gates pass and export/legal approve. If you expected blocking, you are still in test mode.

**The `Devices/Endpoint` location isn't available when creating or scoping the policy.**
- **Licensing:** Endpoint DLP generally requires **E5 / E5 Compliance / A5** — confirm in the admin center
  and with `DLPITAR-Scope-Health.ps1` (verify your licensing/tenant).
- **Onboarding:** the Devices location depends on **onboarded devices** — check **Purview portal → Settings
  → Device onboarding**. With no onboarded devices the location does nothing even when selectable.

## Egress behaviour

**External send/share isn't being restricted after enforcement.**
- Confirm the rule's **scope condition** actually targets egress outside the org (recipient/share scope is
  `NotInOrganization` / "outside the organization") and that the **action** is Block / block-with-override —
  a rule that only *notifies* will not restrict. `DLPITAR-Validation.ps1 -ExpectEnforce` checks for both.
- Some condition/action combinations are **portal-only** in a given tenant — the config helper creates a
  safe simulation shell and prints exactly what to finish in the portal. Complete the label condition,
  external scope, and Block action there, then re-validate.
- SharePoint/OneDrive **external sharing** is also governed by tenant/site sharing settings — a DLP block and
  the sharing configuration must both be consistent with the intended restriction.

**Endpoint activities (USB / print / cloud upload) aren't caught after enforcement.**
- Confirm the device is **onboarded and reporting**, meets the **minimum OS build**, and that the specific
  **activity is in scope** of the rule (e.g. "copy to USB" enabled) and not on an **allowed app / network**
  exception. Allow for **reporting latency** — endpoint events take time to surface in Activity Explorer.

## False positives (the adoption killer)

**Engineers are getting policy tips on legitimate internal work.**
- Export matches with `DLPITAR-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Raise confidence/instance count**, add **supporting keywords/proximity**, and prefer the **label
  condition** so context is required, not just a pattern. Move over-matching identifier sets to **EDM** where
  licensed.
- Add a **targeted exception** only where export-compliance has justified it (a specific mailbox/site/group),
  narrowly and with a documented reason recorded in `Change Record – ITAR DLP – ChangeControl`.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

## Alerts / evidence

**Policy matches occur but no alert appears / the report returns nothing.**
- Confirm **alerts are configured** on the rule and check **Purview → Data loss prevention → Alerts**.
- Confirm **audit logging is enabled** in the tenant — `DLPITAR-Report.ps1` reads the unified audit log and
  will return nothing without it. Widen `-Days` for latency, and allow **dwell time** on fresh policies.
- Confirm your account holds a **View-Only DLP / audit** role; a missing role looks like "no data."

**Reviewers can see too much (or too little) match evidence.**
- Match evidence for controlled technical data is itself sensitive — access is governed by **role**. Confirm
  reviewers hold the least-privilege **Data Loss Prevention / View-Only DLP** role and nothing broader.

## Connectivity / tooling

**`Connect-IPPSSession` or a DLP cmdlet fails.**
- Ensure **ExchangeOnlineManagement** is installed/updated and you're using a **modern-auth / MFA-capable**
  admin. For a sovereign cloud, pass the correct `-ConnectionUri` (Commercial / GCC High / DoD).
- Confirm the account holds the required **DLP role** (Compliance Administrator / Compliance Data
  Administrator / DLP Compliance Management) — a missing role surfaces as "cmdlet not recognized" or access
  denied.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`. If a change
  landed it was committed intentionally — the safe recovery is always `DLPITAR-Set-Policy.ps1 -Disable
  -Commit` (or back to `-Mode TestWithNotifications -Commit`), which is instant and non-enforcing.

---

### Fast triage table

| Symptom | First check |
|---|---|
| Technical-data SIT never fires | Test regex+keywords+proximity in the SIT wizard; prefer the label condition |
| SIT over-matches routine docs | Require keywords, tighten proximity, raise confidence/instance, or move to EDM |
| Policy matches nothing | Mode (disable/sim), propagation time, workload scope/exclusion, pilot-ring membership |
| Nothing blocked | Still in **simulation** — expected; promote to enforce after gates pass + approval |
| External send/share not restricted | Rule scope = NotInOrganization, action = Block, finish portal-only conditions, re-validate |
| Devices location missing | Licensing (E5/E5 Compliance/A5) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed app/network exceptions, latency |
| Too many false positives | Export/classify with Report, tune one driver, prefer label/EDM, re-simulate |
| No alert / report empty | Alert config on rule, audit logging on, widen -Days, dwell time, View-Only DLP role |
| Evidence access wrong | Least-privilege DLP role on reviewers |
| Cmdlet/connect fails | Module updated, modern auth, correct `-ConnectionUri`, correct DLP role |

> **Boundary reminder.** These are the *technical* fixes. Whether an item is ITAR-controlled technical data,
> who is a foreign person, the deemed-export access question, and the enforced action per case remain
> **Empowered Official / export-compliance / legal** determinations — captured alongside the evidence, not
> decided here.
