# 5. Testing Guide — Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)

Run after building the workflow (Implementation Step 5) and piloting (Step 6), and again after each expansion. Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names. The core proof is **exactly-once**: each message is processed **once** across two consecutive runs — never skipped, never doubled.

## Test 1 — Managed identity authenticates to Graph
**Do:** Manually **Run trigger** on `Mail Polling – Support Mailbox – Pilot`; open the run history and inspect the HTTP-to-Graph action; or run `GRAPHPOLL-Validate.ps1`.
**Expected:** The Graph GET returns **200** using **Managed identity** auth — no secret in the workflow, no service account. A **401/403** here means the app-role/consent (Step 2) or mailbox scope (Step 3) is wrong.
**PASS/FAIL:** PASS if the read succeeds via managed identity with no stored credential.

## Test 2 — Least-privilege permission is scoped to the one mailbox
**Do:** Confirm the identity reads `supportmailbox@contoso.com`; attempt (per product #4) to read a **different** mailbox.
**Expected:** The target mailbox reads succeed; **any other mailbox is denied**. `GRAPHPOLL-Validate.ps1` confirms the target is reachable.
**PASS/FAIL:** PASS only if the target is readable **and** a non-target mailbox is denied.

## Test 3 — Each message is processed exactly once across TWO runs
**Do:** Send **three** known messages to `supportmailbox@contoso.com`. Run the workflow (**run A**). Without sending anything new, run it again (**run B**). Inspect which messages each run processed (run history and the `Processed` folder); or run `GRAPHPOLL-Test-Watermark.ps1`.
**Expected:** **Run A** processes the three messages and moves/marks them; **run B** processes **zero** (they are past the watermark and out of the polled folder). No message is processed twice; none is skipped.
**PASS/FAIL:** PASS only if total processings across A+B = 3 (each exactly once).

## Test 4 — The watermark advances and persists
**Do:** Note the watermark row (`watermark` for `supportmailbox@contoso.com`) in table `mailpollingwatermark` before and after a run; or run `GRAPHPOLL-Report.ps1`.
**Expected:** After a run that processed mail, the stored watermark equals the **newest processed `receivedDateTime`** (or the new `@odata.deltaLink`) and **survives** to the next run.
**PASS/FAIL:** PASS if the watermark moved forward and is readable by the next run.

## Test 5 — A burst does not double-process
**Do:** Send a **burst** of ~20–30 messages quickly, then run the workflow once (or let one recurrence fire).
**Expected:** All burst messages are processed **once**; the **`@odata.nextLink`** paging loop drains the backlog in the run; the watermark advances to the newest. A second run processes none.
**PASS/FAIL:** PASS if every burst message is processed exactly once and none is skipped by page truncation.

## Test 6 — Throttling is handled gracefully (429)
**Do:** Drive enough volume to trigger throttling, or inspect a run that received **HTTP 429** from Graph in the run history.
**Expected:** On 429 the workflow reads **`Retry-After`**, **waits**, and **retries** — the run **completes** rather than failing, and no message is lost or double-processed. **The exact throttling threshold is not assumed; the workflow defers to the returned `Retry-After` (verify limits against current Microsoft documentation).**
**PASS/FAIL:** PASS if a throttled run recovers and still processes each message exactly once.

## Test 7 — Idempotent re-run after interruption
**Do:** Simulate an interruption — e.g. process a message but interrupt before the watermark write; then run again.
**Expected:** Because processed items are **marked read / moved to `Processed`**, the re-run does **not** re-process them even though the watermark may not have advanced; the mark/move backstop preserves exactly-once.
**PASS/FAIL:** PASS if an interrupted-then-rerun sequence never double-processes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Auth & scope pass** | Tests 1–2 pass — managed identity reads via Graph and access is confined to the one mailbox |
| **Exactly-once pass** | Tests 3–5 pass — three messages processed once across two runs, watermark advances, a burst does not double-process |
| **Resilience pass** | Tests 6–7 pass — throttling recovers gracefully and an interrupted re-run stays idempotent |
