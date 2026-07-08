# Testing & Validation — Teams Chat & Channel DLP

This is the pass/fail gate set. Run it in two passes: **once in simulation** (Phase 3 — the message/
file is *seen* and the policy *would* act, nothing is blocked) and **again after enforce** (Phase 4 —
the block actions *actually* apply). Every test uses **benign test content** deliberately marked to
match your policy conditions (e.g. a message or document carrying your *Confidential* sensitivity
label and/or seeded with a matching sensitive information type) — **never** real regulated data.

> **Determination boundary.** These tests prove the **control works as configured**. Whether a given
> real message or shared file is a *violation*, and any consequence, is a **compliance / security /
> HR-legal** determination — not a test outcome (see `global-requirements-purview.md` §5).

Run `.\DLPTEAMS-Validate.ps1` for the configuration gates and `.\DLPTEAMS-Report.ps1` for the
activity/telemetry rollup between passes.

---

## A. Configuration gates (automated — `DLPTEAMS-Validate.ps1`, read-only)

| # | Check | PASS signal |
|---|---|---|
| A1 | Policy exists | `DLP-Teams-Pilot` is present. |
| A2 | Teams-messages location | The policy covers the **Teams chat and channel messages** location. |
| A3 | File locations | The policy also covers **SharePoint** and **OneDrive** (so Teams-shared files are governed). |
| A4 | Simulation first | In the pilot pass, the policy **Mode** is a **Test/simulation** mode (not `Enable`). |
| A5 | Pilot scope | The policy is scoped to `SG-TeamsDLP-Pilot`, **not** all users. |
| A6 | Two rules present | `DLP-Rule-TeamsMessages` and `DLP-Rule-TeamsFiles` both exist and are enabled. |
| A7 | Sensitive-content condition | Each rule carries a sensitivity-label and/or sensitive-info-type condition (not "all content"). |

**Gate A:** All applicable rows PASS. Any FAIL → fix in `03-implementation.md` before behavioural
testing. **A3 (file locations) failing is the classic "messages covered, files uncovered" gap.**

---

## B. Behavioural tests — messages and files (manual, as a pilot user)

Perform each action with a **matching** test message/file and record the result. In the **simulation
pass** the expected result is *"activity recorded in Activity explorer / simulation results; no
block."* In the **enforce pass** the expected result is the **R6** action for that path.

| # | Path | Test action (as a pilot user, with matching test content) | Simulation PASS | Enforce PASS (per R6) |
|---|---|---|---|---|
| B1 | **1:1 / group chat message** | Post the matching test string in a chat with an **internal** user | Activity recorded; no block | Handled per R6 (often audit/policy-tip for internal) |
| B2 | **Channel message** | Post the matching test string in a standard channel | Activity recorded; no block | Handled per R6 |
| B3 | **Message to external** | Post the matching string in a chat/channel including an **external/federated** user (if in scope) | Activity recorded; no block | **Blocked** with policy tip per R6 |
| B4 | **File shared in chat (OneDrive)** | Share the matching test file in a 1:1 chat | Activity recorded; no block | Handled per R6 (e.g. block external share) |
| B5 | **File shared in channel (SharePoint)** | Share the matching test file in a channel | Activity recorded; no block | Handled per R6 |

**Gate B (simulation pass):** Every in-scope path **B1–B5** recorded the activity. A path that records
**nothing** is a coverage failure — do not enforce it; diagnose per `06-troubleshooting.md`
(location not enabled, latency, condition match, licensing for message DLP).

**Gate B (enforce pass):** Every path enforces its **R6** action, the **internal-vs-external**
differentiation behaves as designed, and the **policy tip** appears where configured. Any deviation →
roll the policy back to simulation and tune.

---

## C. Negative / false-positive tests (both passes)

| # | Check | PASS signal |
|---|---|---|
| C1 | Non-matching content | A message/file carrying **no** matching label/SIT triggers **no** DLP match. |
| C2 | Internal allowed where designed | Where R6 permits internal sharing, an internal-only matching message is **not** blocked in the enforce pass. |
| C3 | Out-of-scope user | A user **not** in `SG-TeamsDLP-Pilot` shows **no** enforcement from this policy. |
| C4 | Override/justification | Where **override / business justification** is configured, the prompt appears and the override is **logged**. |

**Gate C:** All applicable rows PASS. A false positive (C1/C2 fails) must be tuned **before** wider
enforcement — false positives erode user trust and drive shadow workarounds.

---

## D. Evidence to capture (for the defensibility pack)

Capture and retain, for each pass:

- `DLPTEAMS-Validate.ps1` output (configuration gate results, including the three-location check).
- `DLPTEAMS-Report.ps1` output (policy modes + DLP activity/incident export where available).
- Screenshots of **Purview → Activity explorer** showing message and file activity, and of the
  **policy tip / block notification** in a Teams message during the enforce pass.
- A completed **B-path matrix** signed off by the change owner, plus the **R6 action decision** and
  the confirmation that all **three locations** are enabled.

> This evidence set is what makes the control **defensible** — it shows *what* was configured across
> messages **and** files, *that* each path was validated in simulation before enforcement, and *that*
> enforcement (including internal-vs-external) behaves as designed. Store it with the change record.
