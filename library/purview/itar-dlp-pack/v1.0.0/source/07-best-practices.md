# Best Practices — ITAR DLP Pack in Microsoft Purview

Field-tested guidance for running technical-data DLP well. It follows the same order the solution is
built: get **detection** right, pilot in **simulation**, enforce **proportionately**, and keep the
**evidence** intact — deferring every export determination to the accountable owners.

## 1. Detection is the product — invest the pilot time there

- The difference between a DLP program that works and one that gets turned off is **detection accuracy**.
  Budget most of the pilot for tuning the technical-data classification, not for building the policy.
- Prefer the **`Export Controlled // ITAR` sensitivity label** as the primary DLP condition. A label
  travels with the item, survives copy/rename, and is the most precise and durable signal — far better
  than trying to regex every possible marking. Use marking/keyword SITs to *find* content to label and as
  a backstop, not as the only signal.

## 2. Never make the export determination in the tool

- Whether an item **is** ITAR-controlled technical data, whether a person is a **U.S. person** or a
  **foreign person**, USML categorization, ITAR-vs-EAR jurisdiction, and licensing/authorization are
  **legal/export determinations** made by your **Empowered Official and export-compliance function**
  (`global-requirements-purview.md` §5). The DLP pack implements and evidences the control; it does not
  classify the data or the person.
- Capture those determinations in writing **before** enforcing, and reference them in the change record.

## 3. Always pilot in simulation/test first

- **DLP → `TestWithNotifications` / `TestWithoutNotifications`** is a non-negotiable first state. It proves
  the classification matches and the egress rule *would* act **without disrupting engineering work**.
- Keep the pilot scoped to **`ITAR Pilot Ring – Stage1`** and expand **group-by-group** — never flip to
  enforce, tenant-wide, in one move. Re-run the validation gates after each expansion.

## 4. Make the egress action proportionate

- Reserve the hardest action (hard **block external send/share**) for the highest-confidence signal
  (labeled content, or high-confidence marking matches). Prefer **block-with-override / justification** for
  lower-confidence matches so legitimate, authorized transfers have a documented path.
- A false block on a defense program stops mission work; a missed egress is an export exposure. Tune so the
  rule is tight on real technical data and quiet on routine internal collaboration.

## 5. Cover every egress channel — email is not enough

- Technical data leaves through **email, external sharing, Teams, and endpoints** (USB, print, cloud
  upload). A mail-only policy leaves removable media and personal-cloud upload wide open — classic ITAR
  gaps. Extend to **Endpoint DLP** as soon as E5 and device onboarding allow.
- Make coverage **explicit and licensing-aware** with `DLPITAR-Scope-Health.ps1`; record any un-covered
  channel as a known gap rather than assuming it is protected.

## 6. Know the boundary between egress control and deemed-export access

- DLP as built here controls **egress out of the tenant**. Preventing a **foreign person inside your
  tenant** from *accessing* technical data (the classic **deemed export**) is an **access-control**
  problem — sensitivity-label encryption/permissions, site/library access, and Conditional Access — driven
  by a **legal foreign-person determination**. Do not assume egress DLP closes the deemed-export gap.
- Flag deemed-export access as a distinct program dependency and route it to your export authority; this
  pack is honest about where its control ends.

## 7. Confirm the right sovereign cloud before you build

- Defense programs frequently require **GCC High** or **DoD**. Capability availability, portal paths, and
  Graph/PowerShell endpoints differ across **Commercial / GCC High / DoD**. Which cloud your ITAR data must
  reside in is an **export/legal determination** — confirm it before relying on any path, and pass the
  matching `-ConnectionUri` / Graph environment to the scripts.

## 8. Change everything under control, `-WhatIf` first

- Every configuration change runs **`-WhatIf` first**, is applied only with `-Commit` under a change
  window, and is stamped into `Change Record – ITAR DLP – ChangeControl`. Promotion to enforce is a
  reviewed, reversible event — rollback to test/disabled is a single command.

## 9. Baseline and watch for drift

- Establish a **policy baseline** (`DLPITAR-Discovery.ps1 -SaveBaseline`) after each approved change set and
  run `-CompareBaseline` on a cadence. An ITAR egress policy that silently moved to `Disable` is a
  change-control incident, not a footnote.

## 10. Verify against your tenant — the surfaces evolve

- Purview DLP, Endpoint DLP, EDM, and the exact portal paths are **licensing-dependent** and the portals
  **change**. Confirm capability availability and exact paths **against your licensing/tenant** rather than
  assuming; where a capability is in preview, treat it as such.

## 11. Keep the evidence trail intact

- Do **not** delete DLP alerts, matched-content records, or audit entries to "clean up" — they are the
  defensible, auditor-facing evidence that the technical-data control is live and working. Retention and
  disposition of those records is a **records/legal determination**, not an admin convenience.
