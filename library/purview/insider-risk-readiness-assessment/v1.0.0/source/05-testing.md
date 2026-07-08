# 5. Testing & Validation — Insider Risk Readiness Assessment (Microsoft Purview)

Validate the IRM **readiness** implementation against explicit **pass/fail gates**. The four headline gates
are: **(A) the tenant is licensed and privacy-configured**, **(B) roles are strictly separated**, **(C) the
signal substrate (audit + connectors) is present and healthy**, and **(D) the scope is minimal and the pilot
is least-exposing**. Because IRM concerns named people, **every test uses fabricated/test data and touches no
real individual** — the readiness pilot policy stays **disabled/minimal**, the backing scope group uses
**test accounts only**, and the reporting is **pseudonymized (counts, not names)**. Record the evidence.

> IRM is **portal-configured** for several of these gates — where a test is a portal check it is marked
> **VERIFY-IN-PORTAL**; the scripts confirm what is scriptable and flag the rest. Nothing here enables a
> policy or runs IRM against anyone.

---

## Test A — Licensing & privacy-by-design (the capability is present and private)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Licensing signal | Run `IRMASSESS-Discovery.ps1` and confirm in the M365 admin center. | An insider-risk service plan is present (script signal) **and** IRM is openable in the Purview portal — **verify your licensing/tenant**. |
| A2 | Anonymization ON | **Purview portal → Insider Risk Management → Settings → Privacy.** | **"Show anonymized versions of usernames" is ON** — analysts triage pseudonymized identities. **VERIFY-IN-PORTAL.** |
| A3 | Minimum indicators | **Settings → Policy indicators.** | Only the indicators the intended template needs are enabled — not the full set. **VERIFY-IN-PORTAL.** |
| A4 | Privacy sign-off | Confirm the documented privacy decision (Req 2.7). | Anonymization + indicator set + region/retention are recorded and signed off by the privacy stakeholder. |

**Gate A (pass):** IRM is licensed and openable; anonymization is on; indicators are minimized; the privacy
decision is signed off — **before** any analyst has access.

---

## Test B — Role separation (the central control)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Four roles distinct | `IRMASSESS-Discovery.ps1` / `IRMASSESS-Validate.ps1` enumerate the IRM role groups + members. | **Admins, Analysts, Investigators, Auditors** are each held by a **different** owner. |
| B2 | No conflicting membership | Review the scripts' separation-conflict flags. | **No** identity is in two conflicting roles (e.g. Analyst *and* Investigator); the script reports no conflict. |
| B3 | Super-group minimal | Review membership of the **Insider Risk Management** super-group. | The super-group has the minimum necessary members (ideally break-glass only). |
| B4 | Separate from HR/Legal | Confirm who holds **Investigator** (de-anonymization). | HR/Legal are **escalation/reviewers**, **not** default Investigators (Req 2.2/2.7). |

**Gate B (pass):** the four roles are separated across distinct owners, no conflict is flagged, the
super-group is minimal, and the de-anonymizing Investigator role is not held by HR/Legal by default.

---

## Test C — Signal substrate (audit + connectors present and healthy)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Audit logging on | `IRMASSESS-Validate.ps1 -Gate Audit` reads `UnifiedAuditLogIngestionEnabled`. | Returns **PASS** (unified audit log enabled) — the correlation substrate exists. |
| C2 | HR connector healthy | **Purview portal → Data Connectors** (if the template needs HR). | `HR Connector – Readiness` shows a **recent, successful import**. **VERIFY-IN-PORTAL.** |
| C3 | Built-in signals | **Settings** integration toggles for Entra/DLP/Defender. | The signals the template requires (e.g. Defender for security-violation indicators) are enabled. **VERIFY-IN-PORTAL.** |
| C4 | Connector negative | Confirm no *unneeded* connector is importing data. | Only connectors the intended policy needs are active — data minimization holds. |

**Gate C (pass):** audit logging is on (script PASS) and every connector the intended template requires is
healthy in the portal, with no unnecessary connector collecting data.

---

## Test D — Least-exposing scope & pilot (nothing runs against anyone)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| D1 | Analytics-first | Confirm **Analytics** was run before any policy (**Insider Risk Management → Analytics**). | Aggregated, **anonymized** insight was reviewed **without** a named-user policy. **VERIFY-IN-PORTAL.** |
| D2 | Backing group exists & minimal | `IRMASSESS-Set-Scope.ps1 -ScopeGroupName ... -WhatIf` reports members. | `IRM Priority Users – Readiness – Scope` exists and contains **only test accounts** (or is empty). |
| D3 | Policy is disabled/minimal | **Settings → Policies.** | `IRM – Data Theft Departing Users – Readiness Pilot` exists **disabled/minimal**, scoped to the priority-user group **only**. **VERIFY-IN-PORTAL.** |
| D4 | No broad enforcement | Confirm no IRM policy is enabled tenant-wide. | No policy is operating against real users — the assessment operates against **no** individual. |
| D5 | Scripts safe-by-default | Run `IRMASSESS-Config.ps1` / `IRMASSESS-Set-Scope.ps1` **without** `-Commit`. | They make **no** change (`-WhatIf` output only); Discovery/Validate/Report are read-only; **no** script enables a policy. |

**Gate D (pass):** Analytics ran before any policy; the scope group is minimal/test-only; the readiness policy
is disabled/minimal and narrowly scoped; nothing enforces against real users; scripts are safe-by-default.

---

## Pseudonymization & data-handling validation

| # | Test | Pass condition |
|---|---|---|
| P1 | Scorecard is pseudonymized | `IRMASSESS-Report.ps1` output contains **counts and gate status only** — **no** usernames, no case content, no personal data. Safe to share with HR/privacy/legal. |
| P2 | No de-anonymization in readiness | No case is opened and no identity is de-anonymized during the assessment — de-anonymization is an Investigator action inside an operational case, out of scope here. |
| P3 | Evidence access | The readiness evidence (scorecard, validation CSV) is stored where only appropriately-roled stakeholders can read it. |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0): IRM role-group membership (with separation-conflict flags), audit-log
  state, licensing signal.
- The **privacy sign-off** (anonymization on, indicator set, region/retention) — Gate A.
- The **role-separation confirmation** (four distinct owners, super-group minimal, HR/Legal not
  Investigators) — Gate B.
- The **connector health** portal screenshots and the audit-log PASS — Gate C.
- The **Analytics-reviewed** note, the minimal backing group membership, and the **disabled/minimal** policy
  confirmation — Gate D.
- The **pseudonymized readiness scorecard** (`IRMASSESS-Report.ps1`) handed to HR/privacy/legal — P1.

> **Determination boundary.** These tests prove the capability is **ready** — licensed, private, role-
> separated, connected, minimally scoped. Whether to **deploy** IRM, whether monitoring is **lawful** in your
> jurisdiction, whether to **open a case**, and any **HR/disciplinary/legal action** are HR/privacy/legal
> determinations, captured alongside the evidence above. The assessment runs against **no** individual.
