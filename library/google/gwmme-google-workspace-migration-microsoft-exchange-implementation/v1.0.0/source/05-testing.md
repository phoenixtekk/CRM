# Testing & Validation

Run these validations at the gates defined in Implementation (03). Each has an **expected pass/fail**.
Use the named artifacts (`Migration Wave – …`, `Validation Report – …`) consistently. Validation is
**read-only** — comparing source and destination — and never modifies mailboxes.

> **Verify for your version.** Where a check depends on GWMME's own logs or supported behavior,
> confirm the exact log fields/formats against Google's current GWMME documentation for your build.

---

## T1. Prerequisite readiness (Gate C)

- **Procedure:** Run `gwmme_prereq_validator.py` against the host, source, and destination — it checks
  host reachability to source EWS and Google endpoints, that `Source Access – Exchange – App
  Impersonation` can open a test mailbox, that `Service Identity – Google – Migration` is authorized,
  and that `Mapping – Users – Master` is well-formed.
- **Pass:** every check reports OK; no missing targets, no unreachable endpoints, no malformed rows.
- **Fail:** any check red → resolve (Requirements 02 / Troubleshooting 06) **before** installing/running
  GWMME. Do not proceed on a partial pass.

## T2. Mapping integrity (Gate C)

- **Procedure:** Run `gwmme_config_helper.py --validate` on `Mapping – Users – Master`.
- **Pass:** every in-scope source mailbox maps to exactly one **existing, licensed** Google target;
  no duplicate source or target rows; wave subsets sum to the master.
- **Fail:** duplicates, orphan rows, or unmatched targets → correct the mapping; re-run.

## T3. Pilot wave completeness — mail (Gate E)

- **Procedure:** After `Migration Wave – Pilot – 01`, run `gwmme_validation_report.py` to compare
  **source vs. destination** mail folder/item counts per user; produce `Validation Report – Pilot – 01`.
- **Pass:** destination mail item counts match source **within the agreed tolerance** for every pilot
  user; no folder is missing.
- **Fail:** a user is short beyond tolerance or a folder is missing → triage (throttling? oversized/
  unsupported items? delta gap?) per Troubleshooting; re-run a delta; re-validate.

## T4. Pilot wave completeness — calendar (Gate E)

- **Procedure:** For each pilot user, compare **calendar events** source vs. destination via the
  validation report; spot-check a **recurring** meeting and an event with attendees.
- **Pass:** event counts match within tolerance; recurring meetings expand correctly; attendees present.
- **Fail:** missing events or broken recurrence → triage and re-run; re-validate.

## T5. Pilot wave completeness — contacts (Gate E)

- **Procedure:** Compare **contacts** counts source vs. destination via the validation report;
  spot-check a contact with multiple fields (phone, address, notes).
- **Pass:** contact counts match within tolerance; sampled contact fields render correctly in Gmail.
- **Fail:** missing contacts or dropped fields → triage and re-run; re-validate.

## T6. Error triage completeness (Gate E)

- **Procedure:** Review GWMME's per-item error output for the pilot; classify every error
  (permission / throttling / unsupported-or-oversized item / delta).
- **Pass:** every error is classified and either resolved or accepted with a documented reason.
- **Fail:** unexplained errors remain → do not pass the gate; investigate.

## T7. Throttling headroom (Gate D/F)

- **Procedure:** Run `gwmme_config_helper.py --throttle-check` to review the run against the throttling
  budget (concurrent mailboxes, wave size/volume estimate) and check observed retry/throttle signals in
  the GWMME logs.
- **Pass:** the wave completed within the budget without sustained throttling; no runaway retries.
- **Fail:** sustained throttling/retries → reduce concurrency/wave size (re-plan with
  `gwmme_batch_planner.py`) before scaling.

## T8. Per-wave production completeness (Gate F, each wave)

- **Procedure:** Repeat T3–T7 for each `Migration Wave – <Scope> – <NN>`, producing
  `Validation Report – <Scope> – <NN>`.
- **Pass:** the wave's report is complete within tolerance and errors triaged **before** the next wave
  starts.
- **Fail:** hold the sequence; fix and re-validate the current wave.

## T9. Cutover mail flow (Gate F, cutover)

- **Procedure:** After MX/DNS cutover, send inbound test mail from an external sender to a migrated
  user and confirm delivery to Google; confirm no bounces.
- **Pass:** inbound mail delivers to Gmail; no NDRs.
- **Fail:** mail bounces or routes to the old source → execute `Rollback Plan – Cutover – Mail`
  (revert MX/DNS), restore source flow, diagnose DNS/MX before re-attempting.

---

### Validation summary

| Test | Gate | Pass signal |
|---|---|---|
| T1 Prereq readiness | C | All checks green |
| T2 Mapping integrity | C | 1:1 source→licensed target, no dups |
| T3 Mail completeness | E | Item counts within tolerance |
| T4 Calendar completeness | E | Events + recurrence intact |
| T5 Contacts completeness | E | Contacts + fields intact |
| T6 Error triage | E | Every error classified/resolved |
| T7 Throttling headroom | D/F | No sustained throttling |
| T8 Per-wave completeness | F | Each wave report passes before next |
| T9 Cutover mail flow | F | Inbound delivers to Google, no bounces |
