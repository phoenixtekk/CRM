# 5. Testing & Validation — eDiscovery Readiness Assessment (Microsoft Purview)

Run these to **validate readiness** after remediation and the readiness proof. Each test maps to a
rubric domain (**R/H/S/P**), states the **procedure** and the **expected pass/fail**, and where noted
is produced by `EDREADY-Validation.ps1` / `EDREADY-Reporting.ps1`. The proof artifacts are the
Section 1 names on the **test account**.

## Test 1 (R) — Roles are least-privilege, with coverage
**Procedure:** Run `EDREADY-Validation.ps1`; or Purview → **Settings → Roles & scopes** → check
**eDiscovery Manager** / **eDiscovery Administrator** membership.
**Pass:** Operators are in eDiscovery Manager; a small lead group is in eDiscovery Administrator;
**no Global Admin** appears in either group; **≥ 2** trained operators (coverage).
**Fail:** Global Admin is used for matters, no members in the role groups, or a single operator (no
coverage) — see Requirement 2.2 / Implementation Stage C.

## Test 2 (H) — Unified audit log is on
**Procedure:** Run `EDREADY-Validation.ps1` (reads `UnifiedAuditLogIngestionEnabled`); or Purview →
**Audit** returns results.
**Pass:** Auditing is **enabled**; a search for recent activity returns records.
**Fail:** Auditing off (high-severity gap — enable via `EDREADY-Remediation.ps1 -Commit`, Requirement
2.3).

## Test 3 (H) — A hold actually preserves (the readiness proof)
**Procedure:** With `Readiness Hold Policy – Proof – Pilot` / `Readiness Hold Rule – Proof – Pilot`
**enabled** on the **test account**, delete a seeded held item and confirm it is still
recoverable/preserved. `EDREADY-Validation.ps1` confirms the proof policy/rule are enabled over the
test mailbox.
**Pass:** The hold policy/rule are enabled over the test mailbox and the deleted item remains
preserved and discoverable — preservation demonstrably works.
**Fail:** Hold shows disabled/error, or the item is permanently gone (see Troubleshooting) — the
capability is **not** proven.

## Test 4 (H) — Proof hold removed (clean up verified)
**Procedure:** After the proof, run `EDREADY-Validation.ps1` (or `Get-CaseHoldPolicy`) and confirm
`Readiness Hold Policy – Proof – Pilot` no longer exists.
**Pass:** The proof hold and rule are gone; nothing is left preserving on the test account.
**Fail:** The proof hold still exists (remove per Implementation Step 13 / Rollback) — a rehearsal
must not leave a standing hold.

## Test 5 (S) — Scope/coverage is complete
**Procedure:** Run `EDREADY-Scope.ps1`; review workload coverage, **inactive/legacy mailboxes**, and
that **Teams messages (in mailboxes)** and **M365 Group/Teams sites** are accounted for.
**Pass:** Every in-scope workload is discoverable and mapped; inactive mailboxes are inventoried; no
known workload is missing from the scope note.
**Fail:** A workload is unaccounted for (e.g. Teams chat, M365 Group sites, inactive mailboxes) — a
coverage blind spot (Requirement 2.4 / Implementation Step 2).

## Test 6 (S) — Proof search returns the seeded content
**Procedure:** Inspect `Readiness Search – Proof – Pilot` statistics (`EDREADY-Reporting.ps1` or
portal search **Statistics**); preview a sample.
**Pass:** Item count is in the expected order of magnitude for the seeded test content; preview shows
the on-topic seeded items — search over the held location works.
**Fail:** Zero hits when content was seeded, or an implausible count (query/location scope wrong).

## Test 7 (P) — Process artifacts exist
**Procedure:** Confirm the **matter-intake template** (with named legal owner + hold instruction),
the **naming standard**, the **change-control/rollback**, and the **evidence-pack** routine are
adopted.
**Pass:** All four process artifacts exist and are owned; a matter could be intaken today with legal
sign-off before configuration.
**Fail:** Any missing — an org with tooling but no process is **not ready** (Requirement 2.5 /
Implementation Step 8).

## Test 8 (all) — Audit trail of the proof present
**Procedure:** Run `EDREADY-Reporting.ps1` (audit section) or Purview → **Audit** and search for the
proof case/hold/search activity.
**Pass:** Audit records exist for the proof case creation, hold placement/removal, and search —
defensibility evidence is being captured.
**Fail:** No audit activity (auditing off — Test 2 — or insufficient time to populate).

## Test 9 — Licensing/tier recorded honestly
**Procedure:** `EDREADY-Discovery.ps1` case-type/tier signals vs the licensing in Requirement 2.1.
**Pass:** The scorecard records the actual tier (Standard vs **Premium/E5**); any Premium *review*
readiness claim is backed by E5 licensing.
**Fail:** The scorecard claims Premium review readiness without the tier — **verify in your tenant**
and correct.

---
## Validation gate summary (all must pass to declare readiness)
- [ ] Roles least-privilege **with coverage**, no Global Admin (Test 1)
- [ ] **Audit log on** (Test 2)
- [ ] **Hold proven** to preserve on the test account (Test 3) and **proof hold removed** (Test 4)
- [ ] **Scope/coverage complete** — Teams, M365 Groups, inactive mailboxes (Test 5)
- [ ] Proof **search** returns seeded content (Test 6)
- [ ] **Process artifacts** adopted (Test 7)
- [ ] **Audit trail** of the proof present (Test 8)
- [ ] **Tier/licensing** recorded honestly (Test 9)
