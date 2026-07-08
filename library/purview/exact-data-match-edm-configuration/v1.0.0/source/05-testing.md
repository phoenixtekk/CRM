# 5. Testing & Validation — Exact Data Match (EDM) in Microsoft Purview

Validate the EDM implementation against explicit **pass/fail gates**. The three headline gates are:
**(A) it matches your real records exactly**, **(B) it does NOT match look-alikes / not-in-data
values** (the whole point of EDM), and **(C) the SIT enforces correctly in a policy**. Run every test
with **values you are authorised to use for testing** — a small set of test records you control, or
sanctioned sample values — and record the evidence. **Never** paste real customer/employee records
into ad-hoc test documents outside the sanctioned set.

> All tests assume the schema/SIT from the Implementation Guide, the data **hashed & uploaded** and
> **fully indexed** (allow the documented indexing time before judging results), and the DLP policy
> proven in **simulation** before enforcement.

---

## Test A — Exact match on real data (it detects what it should)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Primary + supporting match | Put an **in-data** `AccountNumber` value **and** a matching supporting value (`LastName`/`SSN`/`Email`) in a test document; run the portal **Test** on the SIT (or `PURVEDM-Validate.ps1`). | The SIT **matches** at the expected confidence. |
| A2 | Configurable-match (delimiters) | Use an in-data value with **different delimiters** than stored (e.g. `123456789` vs stored `123-45-6789`) on a field flagged *ignore delimiters*. | Still **matches** — confirms the configurable-match option works. |
| A3 | Configurable-match (case) | Vary the **case** of a supporting value on a field flagged *ignore case*. | Still **matches**. |
| A4 | Second-tier (stricter) confidence | If a higher-confidence variant (primary + **two** supporting elements) was defined, test a document meeting it. | Matches at the **higher** confidence tier. |

**Gate A (pass):** in-data values (with a supporting element in proximity) match, and the configurable
match options behave as designed.

---

## Test B — Exactness (it does NOT match look-alikes) — the defining EDM gate

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Not-in-data value | Put a **correctly formatted but NOT-in-your-data** primary value (e.g. a random valid-looking account number) + a supporting value in a document. | **No match** — this is the core EDM advantage over pattern SITs. |
| B2 | Primary with no supporting element | Put an **in-data** primary value **alone**, with no supporting element in proximity. | **No match** (or only the primary-only tier if you deliberately defined one) — confirms supporting-element/proximity logic. |
| B3 | Supporting element only | Put a supporting value (e.g. a common `LastName`) **without** any in-data primary value. | **No match** — a supporting element alone never triggers. |
| B4 | Pattern-SIT comparison (optional) | Run the same B1 document past the equivalent **built-in pattern SIT**. | The pattern SIT **would** match (false positive) while EDM does **not** — demonstrates the false-positive reduction. |

**Gate B (pass):** not-in-data and unsupported values are correctly **not** matched — EDM is exact.

---

## Test C — Policy enforcement (the control is operable)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Simulation match | With `DLP-EDM-CustomerRecords-Sim` in **simulation**, move a document with an in-data match through a covered workload (e.g. email to external, external share). | Simulation reports the rule **would** act; a simulation match/alert is recorded — **no user impact**. |
| C2 | Enforced action (pilot ring) | After enforcing to `SG-EDM-Pilot`, repeat C1 as a pilot-ring user. | The action (block / block-with-override) fires; the user sees the policy tip; a DLP **alert** is raised. |
| C3 | Alert + evidence trail | Locate the match in **Purview → DLP → Alerts** and **Data classification → Activity explorer**. | Alert present with the correct policy/severity; full evidence trail (user, location, SIT, action) in Activity explorer. |
| C4 | Scope containment | As a user **outside** `SG-EDM-Pilot`, repeat C1 during pilot. | **Not** enforced — confirms scope containment. |

**Gate C (pass):** simulation reports would-act with no impact; enforced action fires for the ring and
is alerted/trailed; out-of-scope users are unaffected.

---

## Test D — Data store health & refresh (matching stays accurate)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| D1 | Upload/index confirmed | `EdmUploadAgent.exe /GetDataStore /DataStoreName CustomerRecords` (and `PURVEDM-Report.ps1`). | Expected **row count** and a recent **upload timestamp**; session **completed**. |
| D2 | Refresh applied | After a refresh (`/UploadData` of updated data), add a **newly-added** record's value to a test doc and re-test (A1). | The **new** value now matches — confirms refresh took effect. |
| D3 | Removed record no longer matches | After a refresh that **removed** a record, test that record's value. | **No longer matches** — confirms removals propagate. |

**Gate D (pass):** the data store reports healthy with the expected rows; adds/removes propagate after
refresh.

---

## Simulation-first & rollback validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Nothing enforced outside the ring | Users outside `SG-EDM-Pilot` experience no blocking during pilot (same as C4). |
| S2 | Instant rollback | Setting `DLP-EDM-CustomerRecords-Sim` back to **simulation** immediately removes enforcement with no data change (a previously-blocked action now only simulates). |
| S3 | No secrets in tooling | Confirm no script, log, or repo contains the **salt**, the **plaintext export**, or real record values (the provided scripts never read source data or accept a salt). |

---

### Evidence to capture

- Portal **Test** results / `PURVEDM-Validate.ps1` output for A1–A4 and B1–B3.
- Simulation match report and the enforced **DLP alert** + **Activity explorer** trail (C1–C3).
- `PURVEDM-Report.ps1` / `/GetDataStore` output showing data-store health (D1) and refresh (D2–D3).
- The measured **false-positive rate** (expected near-zero) versus the equivalent pattern SIT (B4).

> **Boundary:** the tests prove the **technical control and its evidence**. *Which* records are in
> scope, the **enforced action**, and the **retention of the loaded data** are compliance/privacy/legal
> determinations, captured alongside the evidence.
