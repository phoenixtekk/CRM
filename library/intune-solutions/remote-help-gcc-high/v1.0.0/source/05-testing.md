# 5. Testing Guide — Remote Help — Government (GCC High) Edition

Run after Implementation. **Test 0 is the gate** — everything after it depends on which branch you are
in. All sovereign specifics are **verify against current Microsoft documentation**.

## Test 0 — Availability gate resolved (do this first)
**Do:** Confirm Remote Help's status for your tier per current Microsoft docs; run
`RHELPG-Test-Endpoints.ps1` and `RHELPG-Discovery.ps1`.
**Expected:**
- **GCC** → Remote Help supported; tenant resolves the **commercial** endpoints; proceed to Path A tests
  (1–7).
- **GCC High / DoD** → Remote Help **not** present; tenant resolves the **`*.us`** endpoints; proceed to
  Path B tests (A1–A3).
**PASS:** the branch is correctly identified and matches the endpoints observed. **FAIL:** a GCC tenant
on `*.us`, a GCC High/DoD tenant on `.com`, or an attempt to configure a Remote Help blade that isn't
there.

---

## Path A — Remote Help available (GCC)

## Test A1 — Correct (commercial) plane
**Do:** Sign in at `https://intune.microsoft.com`; run `RHELPG-Test-Endpoints.ps1`.
**Expected:** Commercial endpoints resolve for the GCC (commercial-instance) tenant.

## Test A2 — Remote Help enabled with chosen options
**Do:** Intune → **Tenant administration → Remote Help**; or `RHELPG-Validate.ps1`.
**Expected:** Remote Help is **Enabled** with your chosen unenrolled / full-control / chat options.

## Test A3 — App deployed
**Do:** On pilot helper and sharer devices run `RHELPG-Discovery.ps1`.
**Expected:** The Remote Help app is present (assignment shows Succeeded in Intune → Apps). AVD hosts
are excluded.

## Test A4 — RBAC gates access (least privilege)
**Do:** A non-help-desk account attempts **Give help**; a view-only helper attempts full control.
**Expected:** Only the RBAC-holding helpers can give help; view-only cannot take full control.

## Test A5 — Governed session with consent
**Do:** Sharer requests help; helper joins and signs in with Entra; sharer consents.
**Expected:** Session connects; the sharer sees the on-screen indicator; the granted capability behaves
per the role.

## Test A6 — Compliance surfaced
**Do:** During the session, observe the compliance indicator shown to the helper.
**Expected:** The helper sees the device compliance state before assisting.

## Test A7 — Session audited
**Do:** `RHELPG-Report.ps1` (or Intune → Tenant administration → Remote Help usage).
**Expected:** The session appears with helper, sharer, and timestamp.

---

## Path B — Remote Help NOT available (GCC High / DoD)

## Test B1 — Sovereign plane confirmed
**Do:** Sign in at `https://intune.microsoft.us`; run `RHELPG-Test-Endpoints.ps1 -Environment USGov`
(or `USGovDoD`).
**Expected:** The tenant resolves the `*.us` (or DoD) endpoints — not commercial.

## Test B2 — Remote Help absence confirmed (expected)
**Do:** Look for the Remote Help tenant blade; run `RHELPG-Discovery.ps1 -Environment USGov`.
**Expected:** **Remote Help is not present** — this is the correct, expected result for GCC High / DoD.
A "missing" Remote Help here is a **PASS** of the availability check, not a failure to fix.

## Test B3 — Compliant alternative validated
**Do:** Exercise the chosen alternative (from `gcc-high-parity-notes.md` §4) end-to-end.
**Expected:** Remote assistance works and is authenticated, least-privilege, consent-based, and audited,
with authorization evidence recorded for your IL/ATO.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Availability** | Test 0 passes — the branch matches the tier and endpoints |
| **Path A pilot pass** | Tests A1–A7 pass for the pilot helpers/sharers |
| **Path A wave pass** | Tests A3, A5, A7 pass before each production wave |
| **Path B pass** | B1–B2 confirm the gap on the sovereign plane; B3 validates the compliant alternative |
