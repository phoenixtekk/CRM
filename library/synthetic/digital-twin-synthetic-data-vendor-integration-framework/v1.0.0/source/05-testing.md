# Testing & Validation

These procedures are the pass/fail gates for a partner integration. Run them on
`Vendor Output – Pilot – v1` (and on each expansion) and record results in
`Integration Validation – Pilot – v1`. Each gate has an explicit **expected pass/fail**.
Privacy and fidelity gates produce **evidence**; the regulatory/disclosure **acceptance** is
deferred to the organization's privacy, compliance, and legal functions.

> All validation runs in the **isolated non-production environment**. **Never** load real PHI
> into the shared harness/twin/AI test environment. The tools are safe-by-default (read-only or
> dry-run) and produce evidence, not approvals.

## Test 1 — Contract conformance (Gate B)

- **Purpose:** Confirm vendor output satisfies the declared target-model interface contract.
- **Tool:** `integration_contract_validator.py --contract "Integration Contract – <Vendor
  Capability> – Design" --data <Vendor Output – Pilot – v1>`
- **Procedure:** Validate required entities, required fields, types, and identifier/reference
  (foreign-key) rules against the contract.
- **Expected — PASS:** all required entities/fields present and typed correctly; every
  reference resolves; zero contract violations.
- **Expected — FAIL:** any missing required field, wrong type, or unresolved reference. Fix in
  the data-out adapter, re-run.

## Test 2 — Adapter conformance / round-trip (Gate C)

- **Purpose:** Confirm the data-in and data-out adapters are lossless for in-scope fields and
  that no vendor-native shape leaks past the adapter boundary.
- **Tool:** `adapter_conformance_checker.py --direction both --fixtures <paired fixtures>`
- **Procedure:** Feed known fixtures through data-in → (vendor) → data-out and compare against
  the expected target-model records; scan the output for vendor-native keys.
- **Expected — PASS:** in-scope fields round-trip without loss or type drift; no vendor-native
  keys present in the harness-facing output.
- **Expected — FAIL:** any dropped/renamed in-scope field, type drift, or a leaked native key.

## Test 3 — Fidelity & coverage (Gate D)

- **Purpose:** Confirm the vendor output is statistically credible against the reference and
  covers the required scenarios/domains.
- **Procedure (documented comparison):** Compare in-scope column distributions of
  `Vendor Output – Pilot – v1` to the read-only reference (global Requirement 6) — e.g.
  category frequencies and numeric summary statistics / divergence — and complete the required
  scenario/domain **coverage matrix**. Record the metrics and the agreed tolerances alongside
  the result. (This gate is procedural against your reference rather than a bundled tool, since
  the reference and tolerances are organization-specific.)
- **Expected — PASS:** every required distribution within the agreed tolerance and all required
  scenarios/domains covered.
- **Expected — FAIL:** any required metric outside tolerance or a coverage gap. Regenerate or
  adjust scope; re-run.

## Test 4 — Privacy / disclosure-risk validation (Gate E)

- **Purpose:** Confirm vendor-produced synthetic output does not reproduce real records and its
  disclosure-risk signals are within the agreed threshold.
- **Tool:** `privacy_validation_check.py --data <Vendor Output – Pilot – v1> --reference
  <read-only reference> --quasi-identifiers <QI list> --k <agreed k>`
- **Procedure:** Check for exact matches against the read-only reference, compute
  uniqueness / k-anonymity on the agreed quasi-identifiers, and flag any record below k.
- **Expected — PASS:** zero exact real-record matches; uniqueness/k-anonymity signals within
  the agreed threshold.
- **Expected — FAIL:** any exact match or any signal over threshold. Quarantine the output;
  escalate to privacy/governance. **Acceptance of residual risk is deferred** to those
  stakeholders — a PASS here is evidence, not a compliance determination.

## Test 5 — Portability / lock-in (Gate F)

- **Purpose:** Confirm the vendor remains replaceable — adapter isolation holds, the exit path
  works, and the portability score meets the agreed minimum.
- **Tool:** `portability_lockin_assessor.py --plan "Portability & Exit Plan – <Vendor
  Capability> – Design" --contract "Integration Contract – <Vendor Capability> – Design"`
- **Procedure:** Score the anti-lock-in criteria (open target model, exportable artifacts,
  adapter isolation, documented exit, exit cost) and exercise a **test export** of the vendor
  output to a portable format.
- **Expected — PASS:** portability score at/above the agreed minimum **and** the test export
  succeeds (output re-loads without vendor tooling).
- **Expected — FAIL:** score below minimum or the export cannot be produced/re-loaded. Improve
  adapter isolation / negotiate exit terms before expanding.

## Gate summary & rollback

- **All of Gates B–F must PASS** before expansion (Implementation Stage 5).
- A failed gate **blocks expansion** and triggers the documented **rollback** (revert to the
  prior vendor/state, quarantine `Vendor Output – Pilot – v1`).
- Record every gate result, the tool output, and the governance sign-off in
  `Integration Validation – Pilot – v1`.
