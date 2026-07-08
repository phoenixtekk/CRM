# 7. Best Practices — Print DLP (Microsoft Purview)

Field-proven recommendations for a print restriction that survives contact with real users.

## Design
- **Simulate before you enforce — always.** Print blocking is high-impact and visible. Build the policy in
  **simulation/audit**, measure real print volume and false positives, tune, and only then enforce. This is
  the single biggest predictor of whether the control stays on.
- **Key off precise detectors, not broad ones.** A print rule tied to a **sensitivity label** or a
  well-tuned **SIT** (right confidence + instance count) fires on the right documents; a broad, low-confidence
  SIT floods the help desk and gets the policy disabled. Prefer a **label condition** where content is
  already labelled.
- **Let compliance own the "what" and "how enforced."** Which categories must not be printed, and whether the
  action is audit / warn / block, are **compliance/privacy/legal determinations**. You configure and prove
  the control; you don't decide the policy.

## Printer groups
- **Allow the sanctioned path; restrict the rest.** Define `Printers – Corporate – Allowed` for the managed,
  locked-down queue and keep it at *allow/audit*, then focus enforcement on **network**, **local
  (USB/directly attached)**, and **universal / print-to-PDF/XPS** printing. Blocking *all* printing is almost
  never the requirement and guarantees pushback.
- **Keep printer groups current.** Printers move, get replaced, and change IPs. A stale group either misses a
  new risky printer or wrongly catches a moved corporate one. Review printer groups whenever the print estate
  changes and re-run **`DLPPRINT-Validation.ps1`**.
- **Watch print-to-PDF/XPS ("universal").** Printing to a file is a quiet exfiltration path that bypasses
  physical-printer controls entirely — make sure the universal/print-to-file class is covered by the
  restriction, not just physical printers.

## Detection & tuning
- **Tune against the simulation sample, one change at a time.** Raise confidence/instance count, add
  supporting keywords/proximity, or switch to a label condition — then re-simulate and re-measure. Changing
  several knobs at once hides which one helped.
- **Use EDM where pattern SITs over-match.** For structured data (customer/account numbers), **Exact Data
  Match** dramatically cuts false positives versus a regex SIT. Refresh the EDM data on cadence.
- **Set an honest false-positive threshold and hold to it.** Agree the acceptable rate with the business
  before enforcing, and don't move to block until the simulation sample meets it.

## Rollout
- **Pilot on a ring, then wave.** Prove enforcement on `DLP Pilot Ring – Stage1` with **block-with-override**
  first (a business escape hatch that still captures evidence), pass all three testing gates, then expand in
  waves — validating each. Never flip the whole tenant at once.
- **Escalate to hard block deliberately.** Move from *block with override* to *hard block* per printer group,
  one at a time, only where compliance requires it, re-validating after each. Keep documented exclusions.
- **Simulation is your instant rollback.** Setting the policy back to simulation removes enforcement
  immediately with no data change — the safety switch for any surprise after go-live.

## Operations
- **Triage means someone, not somewhere.** Assign `DLP Alerts – Print – Operations` to a real owner/queue,
  set severities, and (optionally) forward to Sentinel. A restricted print with no triage owner is not a
  control. Triage a real alert during the pilot to prove the workflow.
- **Review overrides, not just blocks.** If users are justifying overrides legitimately, the policy is
  calibrated; if they're bypassing routinely, the detector or printer groups need work. Report on overrides
  as a first-class signal.
- **Report on a schedule.** Run **`DLPPRINT-Report.ps1`** on a cadence to watch false-positive drift, new
  printers, and alert volume — catch drift before it becomes a ticket storm.

## Complementary control
- **Use sensitivity-label PRINT usage rights where labels exist.** For encrypted-labelled Office files,
  removing the **PRINT** usage right blocks printing regardless of endpoint or OS — a useful complement to
  Endpoint DLP for the highest-sensitivity content. Confirm the labeling design with the information-
  protection owner; don't change usage rights unilaterally.

## Automation & security
- **Run the scripts read-only first.** `DLPPRINT-Discovery` / `DLPPRINT-Validation` / `DLPPRINT-Report` /
  `DLPPRINT-EndpointReadiness` are read-only; the config helper defaults to **`-WhatIf`** — preview before
  `-Commit`, and it never leaves a policy in enforce.
- **Least privilege, no secrets.** Connect with the **least S&C PowerShell / Graph scopes** each task needs;
  never place credentials or tokens in scripts or source control.
- **Verify OS-dependent behaviour.** Windows print restriction is the most complete; **macOS print support
  and specific behaviours evolve — verify against current Microsoft guidance / your tenant** before relying
  on them fleet-wide.
