# 5. Testing Guide — Print DLP (Microsoft Purview)

Run after the Endpoint DLP print policy is built in **simulation** (Implementation Phases 2–3) and again
after each enforcement stage (Phases 4–5). Back each test with **`DLPPRINT-Discovery.ps1`** (posture),
**`DLPPRINT-Validation.ps1`** (policy shape), **`DLPPRINT-EndpointReadiness.ps1`** (onboarding), and
**`DLPPRINT-Report.ps1`** (activity). Where print behaviour is **OS-/tenant-dependent (e.g. macOS), verify
against current Microsoft guidance / your tenant** rather than assuming.

## Test 1 — Licensing and endpoint readiness
**Do:** Run **`DLPPRINT-EndpointReadiness.ps1`**; check **Purview portal → Settings → Device onboarding**.
**Expected:** Target devices are **onboarded** and reporting, meet the minimum OS build, and the **Print**
activity is selectable when authoring a Devices-location rule. Any gap is listed to fix before enforcement.

## Test 2 — Policy is Devices-only and in simulation
**Do:** Run **`DLPPRINT-Discovery.ps1`** / **`DLPPRINT-Validation.ps1`**; check the policy in the portal.
**Expected:** `DLP – Endpoint Print – Simulation` exists, scoped to **Devices only**, its rule sets the
**Print** activity, and its mode is a **`Test*` (simulation)** mode — not enforce.

## Test 3 — Printer groups resolve correctly
**Do:** Run **`DLPPRINT-Validation.ps1`**; check **Endpoint DLP settings → Printer groups**.
**Expected:** `Printers – Corporate – Allowed` exists and contains the sanctioned corporate printers; the
rule treats corporate printing distinctly from network / local / universal (print-to-PDF/XPS).

## Test 4 — Simulation detects a sensitive print (true positive)
**Do:** On a ring device, print a document containing clearly-**fake** but SIT-matching content (e.g. a test
credit-card / SSN pattern) to a **non-corporate** printer. Run **`DLPPRINT-Report.ps1 -Days 1`**.
**Expected:** The print appears in **Activity Explorer** / simulation **Alerts** as a match, with the SIT,
confidence, and printer — showing it *would* have been restricted. No user impact (simulation).

## Test 5 — Corporate printing is not caught
**Do:** Print the same test document to a printer in `Printers – Corporate – Allowed`. Re-run the report.
**Expected:** Printing to the sanctioned corporate queue is **allowed / audit-only** per design — not
flagged as a would-be block. This is the "don't break legitimate printing" gate.

## Test 6 — Non-sensitive print does not match (no false positive)
**Do:** Print a plainly non-sensitive document (no SIT/label match) to any printer.
**Expected:** No print DLP match is recorded — the detector is specific enough not to fire on ordinary
content.

## Test 7 — False-positive rate meets the gate
**Do:** After the agreed simulation dwell time, run **`DLPPRINT-Report.ps1 -Days <dwell>`** and classify
matches true/false positive.
**Expected:** The measured **false-positive rate is at/under the agreed threshold**, with true positives
still detected. If not, tune (Implementation Phase 3) and re-measure before enforcing.

## Test 8 — Enforcement blocks with override on the pilot ring
**Do:** After moving `DLP Pilot Ring – Stage1` to enforce (Block with override), print sensitive test
content to a **non-corporate** printer on a ring device.
**Expected:** The `DLP Notice – Print – Standard` policy tip appears and the print requires **justification
to override** (or is blocked outright if hard block is configured). Corporate printing still works.

## Test 9 — Enforcement is scoped to the ring only
**Do:** Run **`DLPPRINT-Discovery.ps1`** / **`DLPPRINT-Validation.ps1`**; on a **non-ring** device print the
same sensitive test content.
**Expected:** The report shows mode `Enable` scoped to the ring identities only; the non-ring device is
**not** restricted. No enforcement leaks outside the pilot.

## Test 10 — Alerts raise and triage end-to-end
**Do:** From the enforced ring, trigger a restricted print; check **Data loss prevention → Alerts** and the
`DLP Alerts – Print – Operations` queue.
**Expected:** A **DLP alert** is generated at the configured severity, is assigned to the owner/queue, and
can be **dispositioned** (and forwarded to SIEM/Sentinel if wired). A restricted print with no triage is not
a control.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Readiness pass** | Tests 1–3 pass (onboarded + licensed; Devices-only simulation policy; printer groups resolve) |
| **Simulation pass** | Tests 4–7 pass (sensitive print detected; corporate printing not caught; no FP on ordinary content; FP rate ≤ threshold) |
| **Enforcement pass** | Tests 8–10 pass (ring blocks with override; scoped to ring only; alerts raise and triage) |

> Do not expand beyond the pilot until all three gates pass. Re-run Tests 4–10 after each expansion wave and
> after any printer-group or detector change.
