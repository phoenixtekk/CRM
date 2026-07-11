# Testing & Validation — Enablement Kit: Microsoft Defender for Office 365

Validate the enablement kit against explicit **pass/fail gates** — that the **environment** supports the
labs and that the **skills** landed. Run the scripts and walk the manual checks. The automated gates
are produced by **`WSMDO-Validate.ps1`**; readiness comes from **`WSMDO-Discovery.ps1`**, running a
lab query from **`WSMDO-RunLab.ps1`**, and cohort evidence from **`WSMDO-Report.ps1`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — MDO Plan 2 features are present

- **What good looks like:** Explorer, Attack Simulation Training, Action center, and Advanced hunting
  blades are all visible.
- **How to test:** Run `WSMDO-Discovery.ps1`; confirm it reports the Plan 2 service plan present; in
  the portal confirm the four blades load (not just "Real-time detections").
- **If it fails:** Assign MDO **Plan 2** (R1) and allow provisioning time; on Plan 1 run the
  Real-time-detections + protection-stack labs and defer the Plan 2 labs. *Verify licensing.*

## Gate 2 — The protection stack exists (to inspect)

- **What good looks like:** Anti-phish, anti-malware, anti-spam, Safe Links, and Safe Attachments
  policies (or an enabled Preset) exist.
- **How to test:** **Email & collaboration → Policies & rules → Threat policies** lists them.
- **If it fails:** Deploy the **Mail Hygiene** solution first; Lab 3 needs policies to inspect (R2).

## Gate 3 — Email advanced-hunting tables have data

- **What good looks like:** `EmailEvents` (and related email tables) return recent rows.
- **How to test:** In Advanced hunting run `EmailEvents | where Timestamp > ago(24h) | count`, or read
  `WSMDO-Discovery.ps1` freshness. Rows return.
- **If it fails:** Confirm Plan 2 provisioned and mail flowing; email tables are Plan 2 — *verify
  availability in your tenant*.

## Gate 4 — The lab simulation ran and reported

- **What good looks like:** `Sim-MDOLab-Pilot` completed against `Grp-MDO-LabUsers-Pilot` with per-user
  results and `Training-MDOLab-Pilot` auto-assigned to those compromised.
- **How to test:** **Attack simulation training → Simulations** shows the campaign complete with a
  report; `WSMDO-Report.ps1` returns the user-risk summary where the API allows.
- **If it fails:** Confirm the campaign launched (not just staged), the target group was correct, and
  training assignment was enabled (Lab 4).

## Gate 5 — Email hunting returns results

- **What good looks like:** `Explorer-MDOLab-Pilot` and the KQL library return who received / who
  clicked for a test or real post-delivery scenario.
- **How to test:** `pwsh -File .\WSMDO-RunLab.ps1 -Lab 5` returns matching recipients/clicks; the saved
  Explorer view loads and filters.
- **If it fails:** Check table freshness (Gate 3), the query filters, and hunting permissions (R5).

## Gate 6 — AIR actions are pending approval, not auto-applied

- **What good looks like:** An AIR investigation opened and its recommended actions are **waiting in
  the Action center**, not executed.
- **How to test:** **Actions & submissions → Action center → Pending** shows the AIR-recommended
  actions as pending; `WSMDO-Validate.ps1` flags any auto-applied action as a concern.
- **If it fails:** Set AIR back to approval-required (Step 1.2); the enablement kit must not auto-remediate
  (R6).

## Gate 7 — The lab detection exists and is alert-only

- **What good looks like:** `Detect-MDOLab-Pilot` exists as a custom detection rule that **generates an
  alert only** — no automatic remediation.
- **How to test:** **Advanced hunting → Custom detection rules** lists it; its response action is
  alert-only. `WSMDO-Validate.ps1` confirms presence.
- **If it fails:** Recreate it from the tuned Lab 5 query (Lab 7) and set the response to alert-only.

## Gate 8 — The knowledge-check passes

- **What good looks like:** Each learner passes `Check-MDOLab-Pilot` (prevention vs post-delivery,
  Explorer pivots, Safe Links/Attachments purpose, simulation-not-punishment, AIR approval posture,
  email tables).
- **How to test:** Run `WSMDO-Validate.ps1`; it prints the knowledge-check answer key and score.
- **If it fails:** Revisit the mapped lab for any missed question.

## Gate 9 — Read-only / preview posture held; roles least-privilege

- **What good looks like:** No production remediation executed; Explorer take-action not performed
  against production; learners held read/hunt roles and only the instructor launched the simulation /
  authored the detection.
- **How to test:** Review **Permissions & roles** (R5); confirm the Action center shows no
  enablement-kit-executed deletions; confirm the simulation targeted only the lab group.
- **If it fails:** Tighten role assignments; reaffirm the posture (R6).

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | Plan 2 features present | Four blades visible; Plan 2 assigned |
| 2 | Protection stack present | Threat policies / preset exist to inspect |
| 3 | Email tables have data | `EmailEvents` returns recent rows |
| 4 | Lab simulation ran | `Sim-MDOLab-Pilot` reported; training assigned |
| 5 | Email hunting returns | KQL library + `Explorer-MDOLab-Pilot` return data |
| 6 | AIR pending, not auto-applied | Actions in Action center **Pending** |
| 7 | Lab detection alert-only | `Detect-MDOLab-Pilot` exists, alert-only |
| 8 | Knowledge-check passes | `Check-MDOLab-Pilot` scored to threshold |
| 9 | Read-only + least-privilege | No production remediation; roles scoped |

All gates pass ⇒ the cohort is enabled; proceed to **Expand** (hand off to the implementation
solution). Any fail ⇒ reinforce the mapped lab and re-check.
