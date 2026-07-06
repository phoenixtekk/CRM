# Best Practices

Durable practices for integrating partner digital-twin / synthetic-data capabilities so they
are leveraged consistently and stay portable.

## Treat the target model as the contract, not the vendor

- Author every integration against the declared **target model** (FHIR / OMOP / native), never
  against a vendor's native shape. Your harness and AI test environments should only ever see
  the target-model contract.
- Keep the interface contract **machine-readable and versioned**. When it changes, bump the
  contract version and re-run Gate B on every integrated vendor.

## Isolate vendor code to exactly two adapters

- All vendor-specific code lives in the **data-in** and **data-out** adapters — nowhere else.
  If a vendor SDK call or native key appears in the harness, that is a lock-in defect; fix it
  before it spreads.
- Keep adapters **thin**: map shapes, don't add business logic. Logic in an adapter is logic
  you re-implement when you swap vendors.

## Score before you select, and keep the evidence

- Agree the **weighted criteria and thresholds before** scoring (Requirement 4) so selection is
  defensible, not post-hoc. Treat *missing evaluation evidence* as a scoring signal, not a
  neutral gap.
- Re-score periodically. A vendor's fidelity, privacy posture, or portability can drift across
  versions — re-run the scorecard at major upgrades.

## Design the exit on day one

- Capture the **exit path and rollback per vendor during Design**, not at renewal time. A
  vendor you cannot leave cheaply is a vendor that sets your price.
- **Exercise the exit** — a portability score that has never produced a working export is
  aspirational. The portability gate requires a real test export that re-loads without vendor
  tooling.

## Hold partner output to your own privacy bar

- Judge vendor-produced synthetic data by the **same disclosure-risk threshold and quasi-
  identifier checks** as internally generated data. "It's synthetic, from a vendor" is not a
  privacy control.
- Keep any real reference **read-only, minimized, and out of the shared harness**. The privacy
  gate produces **evidence**; **defer the acceptance** to privacy/compliance/legal — never let
  a green tool output stand in for a de-identification determination.

## Keep the safety and boundary discipline

- **Never** place real PHI into the shared harness, twin, or AI test environment. Do all
  integration and validation in the **isolated non-production environment**.
- Reference vendor capabilities at the **pattern level**; for anything version-specific, verify
  against the vendor's documentation rather than assuming — and record the version you verified.

## Govern the portfolio, not just the pilot

- Maintain a **vendor register** linking each capability to its contract, adapters, portability/
  exit plan, and latest validation. This is what makes partner capabilities *consistent across
  programs* instead of a set of one-off integrations.
- Re-run Gates B–F on every expansion and every vendor upgrade — conformance and portability
  are properties to keep, not achieve once.
