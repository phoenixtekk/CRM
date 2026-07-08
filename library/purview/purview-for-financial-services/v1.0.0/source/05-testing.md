# 5. Testing Guide — Microsoft Purview for Financial Services

Run after publishing to `Purview - FS Pilot Users` (Implementation Step 3 onward), before the DLP
audit gate (Step 6), and again after each expansion. Tests validate the **mechanism and evidence** —
they do not judge regulatory sufficiency, which is the compliance/records/legal owners' call.

## Test 1 — FS labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`FS-Purview-Validation.ps1`.
**Expected:** All four labels appear (`Sensitivity Label - FS Public` through
`Sensitivity Label - FS Restricted (MNPI)`) via `Label Policy - FS Taxonomy - Pilot`.

## Test 2 — NPI/MNPI label protection applies
**Do:** Apply `Sensitivity Label - FS Confidential (NPI/GLBA)` to a test document and try to open it as
an out-of-scope external user; apply `Sensitivity Label - FS Restricted (MNPI)` and confirm only the
named group can open it.
**Expected:** The document is encrypted/marked; external/out-of-group users are denied per the label's
permissions.

## Test 3 — NPI auto-labeling simulation matches
**Do:** Purview → **Information Protection → Auto-labeling →** open `Auto-Label - FS NPI (GLBA) -
Simulation` → **Simulation**.
**Expected:** The simulation lists items matching the rule (e.g. files with bank-account / routing /
SSN data) and does **not** flag routine, non-sensitive content. It applies nothing while in simulation.

## Test 4 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing fake bank-account/routing or SSN data to an
external address; check Purview → **Data Loss Prevention → Alerts** and **Activity explorer**. Or run
`FS-Purview-Report.ps1`.
**Expected:** `DLP Policy - FS NPI and Financial - Test` records the match (policy tip shown, no block)
— the audit gate has data to review.

## Test 5 — DLP enforces (after the gate)
**Do:** After Step 7, repeat Test 4 against `DLP Policy - FS NPI and Financial - Enforce`.
**Expected:** The action now blocks (or blocks-with-override) per the enforce rule; the event is logged.

## Test 6 — Retention label applied and honored
**Do:** Apply `Retention Label - FS Broker-Dealer Records (SEC 17a-4) - 6yr` to a test item and attempt
to delete it.
**Expected:** The item is retained for the period (or declared a **regulatory record** and blocked from
deletion / un-marking) per the label.

## Test 7 — Retention policy scoped (and lock state correct)
**Do:** Confirm `Retention Policy - FS Communications Supervision - 6 Year` is applied to the pilot
locations (Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`FS-Purview-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams. During
the pilot it should be **unlocked** (Preservation Lock is applied only after records/legal sign-off,
Step 9.5).

## Test 8 — Communication-compliance policy live with role separation
**Do:** Confirm `Comm Compliance - FS Supervision (FINRA 3110) - Pilot` exists and is scoped to
`Purview - FS Pilot Users`; confirm the Admin/Analyst/Investigator roles are held by different people
and that alerts are pseudonymized. Generate a benign test communication matching a lexicon term as a
pilot user.
**Expected:** A pseudonymized alert reaches the **Analyst** role for triage; the Admin cannot also act
as Investigator. *No case outcome is judged here — evidence only.*

## Test 9 — Coverage report
**Do:** Run `FS-Purview-Report.ps1`.
**Expected:** A summary of classification (labeled items), DLP events, and DLP service coverage across
the enabled workloads, so coverage and gaps are visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4, 6–8 pass on `Purview - FS Pilot Users`; the DLP audit shows real matches and acceptable noise; comms roles are separated |
| **Audit gate** | DLP audit reviewed and tuned; only then is Test 5 (enforce) run |
| **Records/legal sign-off** | Preservation Lock (Step 9.5) applied **only after** records/legal sign-off — never during the pilot |
| **Expand pass** | Tests 1, 4/5, 7, 8, 9 pass after widening scope beyond the pilot |
