# Testing & Validation — Workshop: Microsoft Defender for Endpoint

Validate the workshop against explicit **pass/fail gates** — that the **environment** supports the
labs and that the **skills** landed. Run the scripts and walk the manual checks. The automated gates
are produced by **`WSMDE-Validate.ps1`**; readiness comes from **`WSMDE-Discovery.ps1`**, running a
lab query from **`WSMDE-RunLab.ps1`**, and cohort evidence from **`WSMDE-Report.ps1`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — MDE is onboarded and endpoint tables have data

- **What good looks like:** Active devices are listed; `DeviceProcessEvents`, `DeviceNetworkEvents`,
  and `DeviceEvents` return recent rows.
- **How to test:** Run `WSMDE-Discovery.ps1`; confirm device count > 0 and the freshness section shows
  rows in the last 24h.
- **If it fails:** Onboard devices (the MDE onboarding accelerator) and allow ingestion time (**R1**);
  run available labs meanwhile.

## Gate 2 — The plan supports the P2 labs

- **What good looks like:** Advanced hunting, Live Response, and Custom detection rules are present.
- **How to test:** Confirm the three surfaces load in the portal; `WSMDE-Discovery.ps1` reports Live
  Response / advanced features enabled.
- **If it fails:** Assign Defender for Endpoint **Plan 2** (R2); on P1, run the prevention/ASR labs and
  defer the P2-only labs. *Verify licensing.*

## Gate 3 — Each hunting lab query resolves

- **What good looks like:** Labs 4–5 from `WSMDE-Labs.kql` run without schema errors and return
  explainable results.
- **How to test:** `pwsh -File .\WSMDE-RunLab.ps1 -Lab 4` returns rows; repeat for Lab 5.
- **If it fails:** Correct any table/column name to your tenant’s schema (Advanced hunting → schema)
  and re-run.

## Gate 4 — Learners can investigate an incident

- **What good looks like:** In the capstone, a learner establishes **root cause** and **scope** from
  the incident graph + device timeline and names the recommended response action.
- **How to test:** Observe the capstone; confirm the two-line summary correctly identifies the origin
  process and impacted assets.
- **If it fails:** Re-run Labs 2 and 3 (incident graph, device timeline) before repeating the capstone.

## Gate 5 — ASR lab rules are audit-only

- **What good looks like:** `ASR-Lab-AuditOnly-Pilot` is set to **audit** (never block) on
  `Grp-MDE-LabDevices-Pilot`, and audit events appear in `DeviceEvents`.
- **How to test:** Confirm the ASR rule mode in the portal is **audit**; run the Lab 5 hunt and see
  audit entries. `WSMDE-Validate.ps1` flags any block-mode lab rule as a concern.
- **If it fails:** Set the lab rules back to **audit**; never block during the workshop (**R5**).

## Gate 6 — Live Response used read-only

- **What good looks like:** The Live Response transcript for the lab device shows **only** `processes`,
  `dir`, `fileinfo`, `getfile` — no change commands.
- **How to test:** Review the Live Response session history for `Grp-MDE-LabDevices-Pilot` devices;
  confirm no `run` / `remediate` / `putfile`.
- **If it fails:** Reaffirm the read-only posture; change commands are out of scope for the workshop
  (**R5**).

## Gate 7 — The lab detection exists and is alert-only

- **What good looks like:** `Detect-MDELab-Pilot` exists as a custom detection rule that **generates an
  alert only** — no isolation or remediation.
- **How to test:** **Advanced hunting → Custom detection rules** lists it; its response action is
  alert-only. `WSMDE-Validate.ps1` confirms presence.
- **If it fails:** Recreate it from the tuned Lab 4 query (Lab 8) and set the response to alert-only.

## Gate 8 — The knowledge-check passes

- **What good looks like:** Each learner passes `Check-MDELab-Pilot` (incident vs alert, reading a
  timeline, ASR modes, Live Response read vs change commands, the response actions and their
  approvals).
- **How to test:** Run `WSMDE-Validate.ps1`; it prints the knowledge-check answer key and score.
- **If it fails:** Revisit the mapped lab for any missed question.

## Gate 9 — Read-only posture held; roles least-privilege

- **What good looks like:** No production response action was taken; learners held read/hunt roles and
  only the instructor held Live Response + authoring rights.
- **How to test:** Review **Permissions & roles** (R4); confirm the audit shows read/hunt/audit
  activity only.
- **If it fails:** Tighten role assignments; reaffirm the posture (**R5**).

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | MDE onboarded + data | Devices active; endpoint tables return rows |
| 2 | Plan supports P2 labs | Advanced hunting / Live Response / detections present |
| 3 | Hunting labs resolve | Labs 4–5 run without schema errors |
| 4 | Investigate an incident | Capstone identifies root cause + scope |
| 5 | ASR audit-only | `ASR-Lab-AuditOnly-Pilot` in audit; events in `DeviceEvents` |
| 6 | Live Response read-only | Only read-only commands in the transcript |
| 7 | Lab detection alert-only | `Detect-MDELab-Pilot` exists, alert-only |
| 8 | Knowledge-check passes | `Check-MDELab-Pilot` scored to threshold |
| 9 | Read-only + least-privilege | No production response; roles scoped |

All gates pass ⇒ the cohort is enabled; proceed to **Expand**. Any fail ⇒ reinforce the mapped lab and
re-check.
