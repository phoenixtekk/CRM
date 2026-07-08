# Testing & Validation — Exchange Online DLP

This is the pass/fail gate set. Run it in two passes: **once in simulation** (Phase 3 — the scenario
is *matched* and the policy *would* act, nothing is blocked or encrypted) and **again after enforce**
(Phase 4 — the block/encrypt scenarios *actually* act). Every test uses **benign test content**
deliberately marked to match your policy conditions (e.g. a message carrying your `Confidential`
sensitivity label and/or seeded with a matching sensitive information type such as a test credit-card
pattern) — **never** real regulated data — sent to **test mailboxes** you control.

> **Determination boundary.** These tests prove the **control works as configured**. Whether a given
> real-world message is a *violation*, and any consequence, is a **compliance / security / privacy /
> legal** determination — not a test outcome (see `global-requirements-purview.md` §5).

Run `.\DLPEXO-Validate.ps1` for the configuration gates and `.\DLPEXO-Report.ps1` for the rule-match /
policy-tip / block telemetry rollup between passes.

---

## A. Configuration gates (automated — `DLPEXO-Validate.ps1`, read-only)

| # | Check | PASS signal |
|---|---|---|
| A1 | Policy exists | `DLPEXO-Pilot` is present. |
| A2 | Exchange location | The policy covers the **Exchange** (email) location. |
| A3 | Simulation first | In the pilot pass, the policy **Mode** is a **Test/simulation** mode (`TestWithNotifications` / `TestWithoutNotifications`), **not** `Enable`. |
| A4 | Pilot scope | The rules are scoped to `SG-DLPEXO-Pilot` (sender condition), **not** all senders. |
| A5 | Five rules present | `DLPEXO-Rule-Ext-Block`, `-Ext-Notify`, `-Label-Encrypt`, `-Internal-Audit`, `-Ext-Escalate` all exist and are enabled. |
| A6 | Sensitive-content condition | Each content rule carries a sensitive-info-type and/or sensitivity-label condition (not "all mail"). |
| A7 | Partner exception referenced | The external rules reference the trusted-partner domain(s) as an **exception**, as designed. |

**Gate A:** All applicable rows PASS. Any FAIL → fix in `03-implementation.md` before behavioural
testing.

---

## B. Behavioural tests — per scenario (manual, from a pilot mailbox)

For each scenario, send a test message and record the result. In the **simulation pass** the expected
result is *"rule match recorded in simulation results / Activity explorer; message delivered, nothing
blocked or encrypted"* (in `TestWithNotifications`, the **policy tip** may also appear). In the
**enforce pass** the expected result is the **R5** action for that scenario.

| # | Scenario | Test action (benign, matching test content) | Simulation PASS | Enforce PASS (per R5) |
|---|---|---|---|---|
| B1 | **SIT → external, high count** | Send a message with **many** seeded SIT instances to an **external** test address | Match recorded; delivered | **Blocked**; policy tip + incident report generated |
| B2 | **SIT → external, low count** | Send a message with **a few** seeded SIT instances externally | Match recorded; delivered | **Policy tip / warn**; **override with justification** works and is logged |
| B3 | **Labeled → external** | Send a `Confidential`-labeled message externally | Match recorded; delivered | **Encrypted** (Purview Message Encryption) |
| B4 | **SIT → internal** | Send seeded SIT content to an **internal** recipient | Match recorded; delivered | **Notify / incident report** only; **not** blocked |
| B5 | **SIT → very high count → external** | Send a message exceeding the escalation threshold externally | Match recorded; delivered | **Blocked** + escalation incident report to `dlp-alerts@contoso.com` |

**Gate B (simulation pass):** Every in-scope scenario **B1–B5** recorded the rule match. A scenario
that records **nothing** is a coverage failure — do not enforce it; diagnose per `06-troubleshooting.md`
(condition match, SIT threshold, recipient scope, latency).

**Gate B (enforce pass):** Every **block/encrypt** scenario enforces as designed **and** every
**notify/audit** scenario records without blocking; **override with justification** is logged where
configured. Any deviation → roll the policy back to simulation and tune.

---

## C. Negative / false-positive tests (both passes)

| # | Check | PASS signal |
|---|---|---|
| C1 | Non-matching content | A message with **no** matching SIT/label triggers **no** DLP match. |
| C2 | Trusted-partner exception | Sending matching content to a **trusted-partner** domain (`partner.contoso.com`) is **not** blocked/encrypted in the enforce pass. |
| C3 | Out-of-scope sender | A sender **not** in `SG-DLPEXO-Pilot` shows **no** enforcement from this policy during the pilot. |
| C4 | Override / justification | Where **override with business justification** is configured (`DLPEXO-Rule-Ext-Notify`), the policy tip offers override and the override is **logged**. |
| C5 | Transport-rule coexistence | An existing mail-flow rule and the DLP rule do **not** double-act or pre-empt each other unexpectedly (R7). |

**Gate C:** All applicable rows PASS. A false positive (C1/C2 fails) must be tuned **before** wider
enforcement — false positives erode user trust and drive shadow workarounds (e.g. senders switching to
personal email).

---

## D. Evidence to capture (for the defensibility pack)

Capture and retain, for each pass:

- `DLPEXO-Validate.ps1` output (configuration gate results).
- `DLPEXO-Report.ps1` output (policy modes + rule-match / policy-tip / block export, where available).
- Screenshots of **Purview → Activity explorer / DLP simulation results** showing each scenario's
  recorded match, and of the **policy tip / block / encryption** behavior in the enforce pass.
- A completed **B-scenario matrix** signed off by the change owner, plus the **R5 action decision**,
  the **R4 recipient-scope + partner-exception decision**, and the **R7 transport-rule reconciliation**.

> This evidence set is what makes the control **defensible** — it shows *what* was configured, *that*
> each scenario was validated in simulation before enforcement, and *that* enforcement behaves as
> designed. Store it with the change record.
