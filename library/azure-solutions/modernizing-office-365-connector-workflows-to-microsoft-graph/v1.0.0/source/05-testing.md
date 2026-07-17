# 5. Testing Guide — Modernizing Office 365 Connector Workflows to Microsoft Graph

Run after the pilot cutover (Implementation Phase 5) and again after each wave (Phase 6) and as the governance scan (Phase 7). Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names. Every test is **PASS/FAIL**.

## Test 1 — Inventory completeness
**Do:** Compare `Connector-Flow-Inventory – Estate – Program.csv` against a fresh `scripts\O365GRAPH-Discovery.ps1` run (Logic Apps) plus the Power Platform enumeration (Power Automate).
**Expected (PASS):** Every in-scope Logic App and Power Automate flow that uses an Office 365 connector appears in the register, each with an auth model recorded. **FAIL** if any connector-based flow is missing or has no auth model.

## Test 2 — Per-flow parity (migrated matches legacy)
**Do:** For the migrated flow, compare its behaviour against the captured parity baseline (requirement 2.7) — same trigger condition, same outputs, same schedule/cadence. Exercise it end-to-end (send a test mail / raise the trigger event / let the poll run).
**Expected (PASS):** The migrated flow produces the **same** observable result as the legacy connector flow did. **FAIL** if any output, trigger behaviour, or schedule differs.

## Test 3 — Migrated flow uses managed identity + Graph
**Do:** Run `scripts\O365GRAPH-Validate.ps1` for the flow; or inspect the Logic App's workflow definition and identity.
**Expected (PASS):** The migrated Logic App calls **Microsoft Graph** authenticated by its **managed identity** `<FlowName> – Graph MI – Target`. **FAIL** if it still calls an Office 365 connector or authenticates any other way.

## Test 4 — No residual stored credentials in the migrated cohort
**Do:** Run `scripts\O365GRAPH-Validate.ps1` across the migrated cohort; confirm no API connection is backed by a user token or service-account secret.
**Expected (PASS):** **Zero** migrated flows carry a stored-credential connection. **FAIL** if any migrated flow still has a user/service-account connection.

## Test 5 — Scoped mailbox permission (least privilege, per #4)
**Do:** Confirm the flow's Graph mail **application** permission is scoped to only the mailbox(es) it needs (Application Access Policy or Graph RBAC-for-Exchange, per sibling #4). Attempt access to an out-of-scope mailbox with the flow's identity.
**Expected (PASS):** The identity can access only its scoped mailbox(es); an out-of-scope mailbox is **denied**. **FAIL** if the permission is tenant-wide or reaches an out-of-scope mailbox. *(Mechanism specifics: verify against current Microsoft documentation.)*

## Test 6 — Per-flow rollback works
**Do:** On a test flow, exercise the rollback (re-enable the legacy connector flow, disable the migrated one) and confirm the legacy flow resumes correct behaviour.
**Expected (PASS):** The legacy flow was **disabled, not deleted**, and resumes on rollback; the migrated flow can be re-cut-over afterward. **FAIL** if rollback is not possible or the legacy flow was already deleted.

## Test 7 — Program progress / no regression
**Do:** Run `scripts\O365GRAPH-Report.ps1`.
**Expected (PASS):** The report shows total connector flows, migrated, and remaining, with risk buckets; the governance scan shows **no new** connector-based flow and **no migrated flow reverted** to a stored credential. **FAIL** if a new connector/credential flow appeared or a migrated flow regressed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot gate (go/no-go)** | Tests 1–6 PASS for every flow in `PILOT – Connector Migration – Pilot` |
| **Wave gate** | Tests 2–5 PASS for every flow in the wave; Test 6 spot-checked |
| **Governance gate** | Test 7 PASS each cycle — falling connector/credential count, no regression |
