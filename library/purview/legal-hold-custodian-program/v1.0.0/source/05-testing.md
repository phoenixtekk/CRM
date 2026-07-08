# 5. Testing & Validation — Legal-Hold & Custodian Management Program (Microsoft Purview)

Validate the legal-hold and custodian-management program against explicit **pass/fail gates**. The three
headline gates are: **(A) the hold actually preserves**, **(B) custodians and notices are covered and
tracked**, and **(C) the program is operable and defensible**. Run **every** test on the **pilot matter**
`Legal Hold Case – Contoso-Matter-001 – Pilot` with **fabricated test custodians and content only** — never
real people, real matters, or real data. Record the evidence.

> All tests assume the case, case hold, and (Premium) custodians/notices from the Implementation Guide,
> proven on the pilot matter first. Custodian/communications tests require **eDiscovery (Premium)** (Req 2.1);
> on Standard, run Gate A and the Standard rows of Gate C, and operate the notice workflow manually.

> **Preservation-critical.** These tests validate that holds work **before** a real matter's preservation
> depends on them. **No test releases a hold on a real matter.** The only "release" exercised here is removing
> a **pilot** hold on **test** custodians (S2), which is safe by construction.

---

## Test A — Preservation is effective (the hold actually holds)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| A1 | Hold distribution succeeds | After placing the pilot hold, run `EDHOLD-Validate.ps1 -CaseName '…Pilot'` and check the case hold policy's distribution status. | Distribution status = **Success** across every held location (allow service-timer latency — minutes to hours before judging). |
| A2 | Deleted content is preserved | On a **held** test mailbox, hard-delete a fabricated item (empty Deleted Items / purge). | The item is **recoverable** from the preservation/Recoverable Items location — the hold prevented permanent purge. |
| A3 | Query-based hold captures the right scope | If the pilot uses a query-based rule, place fabricated content **inside** and **outside** the `ContentMatchQuery`/date scope. | In-scope content is preserved; out-of-scope content behaves per policy — the query scope matches legal's intent. |
| A4 | Every intended location is on hold | Compare the held locations to the design (Req 2.3) via `EDHOLD-Validate.ps1 -ExpectedExchangeLocation …`. | No intended custodian mailbox / OneDrive / site / non-custodial location is missing from the hold. |
| A5 | Litigation Hold reinforcement (if used) | Where a test mailbox has Litigation Hold enabled, confirm state. | `LitigationHoldEnabled = True` with the intended duration — the belt-and-suspenders hold is live. |

**Gate A (pass):** distribution = Success on all pilot locations, deleted held content is recoverable, the
query scope (if used) matches intent, and no intended location is missing.

---

## Test B — Custodians & notices are covered and tracked (Premium)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| B1 | Custodian data-source mapping | For each **test** custodian, confirm the mapped data sources (primary mailbox/OneDrive + associated Teams/Groups + additional sites). | Each custodian shows **on hold** with the expected data sources mapped — nothing responsive un-mapped. |
| B2 | Non-custodial data held | Confirm the non-custodial locations (shared mailbox / departmental site) are held on the case. | Each non-custodial location is preserved — content belonging to no single person is not missed. |
| B3 | Notice issued | Confirm `Hold Notice – Contoso-Matter-001 – Issuance` was issued to the test custodians in **Communications**. | Every test custodian received the issuance notice with an acknowledgment requirement. |
| B4 | Acknowledgment tracked | Acknowledge as one test custodian; leave another un-acknowledged. | The case tracks **acknowledged** vs **not yet**; the un-acknowledged custodian is eligible for reminder/escalation. |
| B5 | Reminder / escalation cadence | Advance (or simulate) the cadence for the non-responder. | A **reminder** (`– Reminder`) and then **escalation** (`– Escalation`) fire per legal's configured cadence. |
| B6 | Register reflects reality | Run `EDHOLD-Report.ps1 -CaseName '…Pilot' -CsvPath …`. | The exported `Custodian Hold Register – … – Report` matches the portal state (custodians, hold status, notice/ack status, dates). |

**Gate B (pass):** every test custodian on hold with mapped sources, non-custodial locations held, notice
issued, acknowledgment/reminder/escalation tracked, and the register faithfully reflects the case.

---

## Test C — Operable & defensible (the control can be run and proven)

| # | Test | Steps | Pass condition |
|---|---|---|---|
| C1 | Evidence trail present | Confirm hold-placement, notice, and access events are in the case history / unified audit log (Req 2.6). | A complete, exportable evidence trail exists (who placed the hold, when; who was noticed; who acknowledged). |
| C2 | Role separation holds | Confirm who can see/manage the case and who can authorize release. | Least-privilege eDiscovery roles hold (Req 2.2); the **release authority** is distinct and named (Req 2.5). |
| C3 | Overlapping-hold safety | Place a fabricated location under **two** pilot holds; release one. | The location stays preserved by the remaining hold — releasing one matter does not un-preserve content another still holds. |
| C4 | Register is defensible | Review the exported register as the record of the matter. | The register answers "who is on hold, since when, noticed, acknowledged, released?" without reconstructing from memory. |
| C5 | Release is deliberate, not scripted | Confirm the release path. | Release happens **only** in the portal with the release authority's written sign-off — **no script releases a hold** (verify the pack has no release automation). |

**Gate C (pass):** the evidence trail is complete and exportable, roles/release authority are separated and
named, overlapping holds are safe, the register is defensible, and release is a signed portal action with no
automation.

---

## Simulation-first & safety validation

| # | Test | Pass condition |
|---|---|---|
| S1 | Pilot isolation | All tests run on `Legal Hold Case – Contoso-Matter-001 – Pilot` with **fabricated** custodians/content — no real matter or person is touched. |
| S2 | Safe pilot teardown | Removing the **pilot** hold on **test** custodians (portal or `EDHOLD-Config.ps1 -Action RemoveCaseHold`, previewed with `-WhatIf`) cleanly removes only the pilot preservation — real matters are unaffected. |
| S3 | Scripts are safe-by-default | `EDHOLD-Config.ps1` and `EDHOLD-Set-Scope.ps1` run **without** `-Commit` make no change (`-WhatIf` output only); Discovery / Validate / Report are read-only; **none** releases a real-matter hold. |
| S4 | No auto-release | Confirm no delivered script performs a hold **release** on any non-pilot case — release is portal + sign-off only (Req 2.5). |

---

## Evidence to capture (for the deliverable record)
- Baseline posture CSV (Phase 0): existing cases, holds and distribution status, role membership.
- Distribution = Success screenshot/log across pilot locations (Gate A1) and the deleted-item recovery
  evidence (A2).
- Custodian data-source mapping and non-custodial hold confirmation (B1/B2).
- Notice issuance + acknowledgment/reminder/escalation tracking (B3–B5) and the exported hold register (B6).
- The audit/evidence trail (C1), the role/release-authority separation (C2), and the overlapping-hold safety
  result (C3).
- Confirmation of safe pilot teardown (S2) and that no script releases a real-matter hold (S3/S4).

> **Determination boundary.** These tests prove the **program works and is defensible**. *Whether* a given
> custodian, preservation scope, notice, or release is legally sufficient is an **eDiscovery-counsel / legal**
> sign-off, captured alongside the evidence above. This solution proves the mechanics; legal owns the
> determination.
