# Testing — Purview DLP, Labels & Retention (Government / GCC High)

Run these gates against the **pilot** (`SG-Purview-Pilot`) before expanding. Each gate has an
explicit **PASS / FAIL** condition. A FAIL sends you to `06-troubleshooting.md`; do not expand scope
or enable enforcement until every applicable gate is **PASS**. Portals are the GCC High `.us` hosts;
scripts connect with **`Connect-MgGraph -Environment USGov`**.

---

## Gate 0 — Sovereign-cloud sanity (must pass first)

- **Test:** In a browser, load `https://compliance.microsoft.us`; run
  `PURVIEWG-Discovery.ps1` and confirm it connected to the **US Gov** Graph endpoint.
- **PASS:** Portal loads at a `.us` host; script reports environment `USGov` /
  `graph.microsoft.us`.
- **FAIL:** Any portal or script resolves to a `.com` host → you are targeting Commercial; stop and
  fix endpoint/environment before any other test.

## Gate 1 — Licensing & roles present

- **Test:** `portal.office365.us → Billing → Licenses` shows G3/G5 (+ G5 Compliance/IP&G);
  `compliance.microsoft.us → Settings → Roles & scopes → Permissions` shows the operator in
  **Compliance Administrator** and **Information Protection**.
- **PASS:** Both present. **FAIL:** Missing SKU or role → cannot author the corresponding feature.

## Gate 2 — Parity check completed

- **Test:** For every feature this deployment uses, `gcc-high-parity-notes.md` status is **Available**
  and the option is visible in `compliance.microsoft.us`.
- **PASS:** Every needed feature is Available and visible. **FAIL:** A needed feature is *in
  development / backlog* (e.g. named-entity SIT, mobile auto-label, classifier-based record label) →
  substitute the GA alternative before continuing.

## Gate 3 — Labels published and visible

- **Test:** A pilot user opens Word/Excel/PowerPoint/Outlook and checks the **Sensitivity** control.
- **PASS:** `Public`, `General`, `Confidential`, `Confidential \ CUI` all appear; `General` is the
  default; removing/lowering a label prompts for justification.
- **FAIL:** Labels missing after replication time → check `LP-Purview-Pilot` assignment to
  `SG-Purview-Pilot`; see troubleshooting.

## Gate 4 — Manual + mandatory labeling works

- **Test:** Pilot user saves a new document without a label.
- **PASS:** Mandatory labeling prompts for a label before save/send; applying `Confidential \ CUI`
  encrypts and marks the file per its config.
- **FAIL:** No prompt, or encryption/marking absent → verify label protection settings and policy
  mandatory-labeling toggle.

## Gate 5 — Service-side auto-labeling simulation is accurate

- **Test:** `AL-CUI-ServiceSide` runs in **simulation**; review matched items.
- **PASS:** Expected CUI content matches; false-positive rate acceptable; no unexpected mass match.
- **FAIL:** Over/under-matching → tune conditions (GA SITs/EDM/keywords only) and re-simulate.
  Confirm you did **not** use a named-entity SIT (not available in GCC High).

## Gate 6 — DLP detects in audit (no block yet)

- **Test:** Pilot user triggers a match for `DLP-CUI-Baseline` / `DLP-CUI-Baseline-Rule1` (e.g.
  emails/shares test CUI content). Check **DLP → Alerts** and **Activity Explorer**.
- **PASS:** The event is detected and recorded in audit; **no user was blocked** (policy still in
  test mode).
- **FAIL:** No detection → verify conditions, locations, and that the policy is scoped to the pilot;
  confirm SIT types are GA in GCC High.

## Gate 7 — Endpoint DLP (only if in scope)

- **Test:** On an **onboarded** device, a pilot user attempts a monitored action (copy CUI to USB /
  print / cloud upload).
- **PASS:** The action is recorded in audit for onboarded devices.
- **FAIL:** Nothing recorded → confirm the device is onboarded (`Settings → Device onboarding`) and
  device location is enabled in the policy.

## Gate 8 — DLP enforcement (post-tuning, change-controlled)

- **Test:** After audit tuning and change-control approval, enable **Block/Restrict** on
  `DLP-CUI-Baseline` and re-test the same action.
- **PASS:** Action is blocked/restricted with the expected policy tip; override/justification behaves
  as configured.
- **FAIL:** Not blocked, or blocks legitimate work → revert to audit, retune, re-approve.

## Gate 9 — Retention applied

- **Test:** Confirm `RP-Baseline-Retain` covers the intended locations; confirm `Ret-CUI-7yr` (via
  `RP-CUI-7yr-Auto`) applies to matching pilot content.
- **PASS:** Retention label present on matching items; org-wide policy active; end-of-period behavior
  is a **supported** action (not the unavailable "apply label action at end of period").
- **FAIL:** Label not applied → verify auto-apply conditions are GA SITs/EDM/keywords (not
  classifier-based for records) and scope.

## Gate 10 — Records & disposition (only if records in scope)

- **Test:** Declare a test item a record via `Ret-CUI-7yr`; open **Records Management → Disposition**.
- **PASS:** Item is a record (locked as configured); disposition review is reachable; proof of
  disposal available.
- **FAIL:** Record behavior missing → confirm records management is licensed (G5) and the label's
  "mark as record" is set; multi-stage review is *rolling out* — verify presence.

## Gate 11 — Script validation clean

- **Test:** Run `PURVIEWG-Validation.ps1` and `PURVIEWG-Report.ps1` (US Gov Graph).
- **PASS:** Validation reports labels/DLP/retention present and scoped as designed; report lists
  coverage with no unexpected gaps.
- **FAIL:** Reported gaps → remediate (see `PURVIEWG-Remediation.ps1`, which defaults to `-WhatIf`)
  and re-run.

---

**Expansion gate:** proceed from Pilot to Expand **only** when Gates 0–6 and 9 are PASS (plus 7/8/10
where in scope) and any DLP enforcement change has change-control approval.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
