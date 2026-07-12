# Testing & Validation — Microsoft Defender for Office 365

Validate the solution against explicit **pass/fail gates** covering both tracks: that the
**environment** supports the labs and PoC, that the **skills** landed (Track A), and that the **PoC
proved the detections** (Track B). Run the scripts and walk the manual checks. The automated gates are
produced by **`MDOFULL-Validate.ps1`**; readiness comes from **`MDOFULL-Discovery.ps1`**, running a
lab query from **`MDOFULL-RunLab.ps1`**, benign signal from **`MDOFULL-TestSignal.ps1`**, and cohort /
PoC evidence from **`MDOFULL-Report.ps1`**.

Each gate lists **What good looks like / How to test / If it fails.** All PoC signal is **benign**
(Attack Simulation Training / GTUBE / EICAR / benign test URL).

---

## Gate 1 — MDO Plan 2 features are present

- **What good looks like:** Explorer, Attack Simulation Training, Action center, and Advanced hunting
  blades are all visible.
- **How to test:** Run `MDOFULL-Discovery.ps1`; confirm it reports the Plan 2 service plan present; in
  the portal confirm the four blades load (not just "Real-time detections").
- **If it fails:** Assign MDO **Plan 2** (R1) and allow provisioning time; on Plan 1 run the
  Real-time-detections + protection-stack labs and the GTUBE/EICAR/Safe Links PoC path, and defer the
  Plan 2 labs/demos. *Verify licensing.*

## Gate 2 — The protection stack exists and covers the pilot users

- **What good looks like:** Anti-phish, anti-malware, anti-spam, Safe Links, and Safe Attachments
  policies (or an enabled Preset) exist and apply to `Grp-MDOFULL-PilotUsers-Pilot`.
- **How to test:** **Email & collaboration → Policies & rules → Threat policies** lists them and shows
  the pilot group in scope.
- **If it fails:** Deploy/scope the **Mail Hygiene** solution first; Lab 3 needs policies to inspect and
  the PoC needs them applied to the pilot users (R2).

## Gate 3 — Email advanced-hunting tables have data

- **What good looks like:** `EmailEvents` (and related email tables) return recent rows.
- **How to test:** In Advanced hunting run `EmailEvents | where Timestamp > ago(24h) | count`, or read
  `MDOFULL-Discovery.ps1` freshness. Rows return.
- **If it fails:** Confirm Plan 2 provisioned and mail flowing; email tables are Plan 2 — *verify
  availability in your tenant.*

## Gate 4 — The simulation ran and reported

- **What good looks like:** `Sim-MDOFULL-Pilot` completed against `Grp-MDOFULL-PilotUsers-Pilot` with
  per-user results and `Training-MDOFULL-Pilot` auto-assigned to those compromised.
- **How to test:** **Attack simulation training → Simulations** shows the campaign complete with a
  report; `MDOFULL-Report.ps1` returns the user-risk summary where the API allows.
- **If it fails:** Confirm the campaign launched (not just staged), the target group was correct, and
  training assignment was enabled (Lab 4).

## Gate 5 — Email hunting returns results

- **What good looks like:** `Explorer-MDOFULL-Pilot` and the KQL library return who received / who
  clicked for a test or real post-delivery scenario.
- **How to test:** `pwsh -File .\MDOFULL-RunLab.ps1 -Lab 5a` returns matching recipients/clicks; the
  saved Explorer view loads and filters.
- **If it fails:** Check table freshness (Gate 3), the query filters, and hunting permissions (R5).

## Gate 6 — Benign PoC signal generated and actioned

- **What good looks like:** The GTUBE / EICAR / Safe Links test messages were sent to the pilot group
  and MDO actioned them (rewritten / detonated / quarantined); no real phishing/malware used.
- **How to test:** Run `MDOFULL-TestSignal.ps1` (preview then send); confirm delivery/quarantine in
  **Review → Quarantine** and via `MDOFULL-Validate.ps1`.
- **If it fails:** EICAR/GTUBE are *meant* to be caught (check quarantine — that is a pass); if nothing
  sent, see Troubleshooting *Benign test message not delivered*.

## Gate 7 — Safe Links / Safe Attachments / spam-phish detections observed

- **What good looks like:** Safe Links rewrote the test URL (`UrlClickInfo`/`UrlClickEvents`), Safe
  Attachments actioned the EICAR message (`EmailAttachmentInfo`), and the GTUBE spam string was handled.
- **How to test:** `MDOFULL-Validate.ps1` prints a PASS/FAIL per capability; the portal Explorer view
  shows each.
- **If it fails:** Allow warm-up (detonation/ZAP act after delivery); confirm the pilot users are in
  the prevention scope (Gate 2); re-check.

## Gate 8 — AIR actions are pending approval, not auto-applied

- **What good looks like:** An AIR investigation opened and its recommended actions are **waiting in the
  Action center**, not executed.
- **How to test:** **Actions & submissions → Action center → Pending** shows the AIR-recommended actions
  as pending; `MDOFULL-Validate.ps1` flags any auto-applied action as a concern.
- **If it fails:** Set AIR back to approval-required (Step 1.2); this solution must not auto-remediate
  (R6).

## Gate 9 — The capstone detection exists and is alert-only

- **What good looks like:** `Detect-MDOFULL-Pilot` exists as a custom detection rule that **generates an
  alert only** — no automatic remediation.
- **How to test:** **Advanced hunting → Custom detection rules** lists it; its response action is
  alert-only. `MDOFULL-Validate.ps1` confirms presence.
- **If it fails:** Recreate it from the tuned Lab 5 query (Lab 7) and set the response to alert-only.

## Gate 10 — The knowledge-check passes

- **What good looks like:** Each learner passes `Check-MDOFULL-Pilot` (prevention vs post-delivery,
  Explorer pivots, Safe Links/Attachments purpose, simulation-not-punishment, AIR approval posture,
  email tables, benign-signal PoC).
- **How to test:** Run `MDOFULL-Validate.ps1`; it prints the knowledge-check answer key and score.
- **If it fails:** Revisit the mapped lab for any missed question.

## Gate 11 — PoC evidence captured against the criteria

- **What good looks like:** `MDOFULL Evidence – Pilot Users – Validate.json` is written with a pass/fail
  per agreed criterion (R7).
- **How to test:** Run `MDOFULL-Report.ps1 -CriteriaPath .\criteria.json -EvidenceOut ...`; confirm the
  file maps every observation to a criterion.
- **If it fails:** Re-run the relevant validate step first; confirm criteria were supplied.

## Gate 12 — Read-only / preview / -WhatIf posture held; roles least-privilege; teardown clean

- **What good looks like:** No production remediation executed; Explorer take-action not performed
  against production; learners held read/hunt roles; only the instructor/operator launched the
  simulation, sent signal, authored the detection, and purged quarantine; the PoC signal was
  purged with no residue.
- **How to test:** Review **Permissions & roles** (R5); confirm the Action center shows no
  solution-executed deletions; confirm the simulation and signal targeted only the pilot group; re-run
  `MDOFULL-Validate.ps1` after `MDOFULL-TestSignal.ps1 -Teardown` to confirm no residue.
- **If it fails:** Tighten role assignments; reaffirm the posture (R6); complete teardown.

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | Plan 2 features present | Four blades visible; Plan 2 assigned |
| 2 | Protection stack present + scoped | Threat policies / preset cover the pilot group |
| 3 | Email tables have data | `EmailEvents` returns recent rows |
| 4 | Simulation ran | `Sim-MDOFULL-Pilot` reported; training assigned |
| 5 | Email hunting returns | KQL library + `Explorer-MDOFULL-Pilot` return data |
| 6 | Benign signal actioned | GTUBE/EICAR/Safe Links sent and actioned (benign only) |
| 7 | Detections observed | Safe Links rewrote, Safe Attachments actioned, spam handled |
| 8 | AIR pending, not auto-applied | Actions in Action center **Pending** |
| 9 | Capstone detection alert-only | `Detect-MDOFULL-Pilot` exists, alert-only |
| 10 | Knowledge-check passes | `Check-MDOFULL-Pilot` scored to threshold |
| 11 | PoC evidence captured | Evidence file maps observations to criteria |
| 12 | Posture + least-privilege + clean teardown | No production remediation; roles scoped; no residue |

Gates 1–11 pass ⇒ the cohort is enabled and the PoC is conclusive; Gate 12 passes to close out
cleanly. Any fail ⇒ reinforce the mapped lab / step and re-check.
