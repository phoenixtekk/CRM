# Implementation — Enablement Kit: Microsoft Defender for Office 365 (Guided Labs)

This is the exact, ordered enablement kit — a sequence of **guided hands-on labs**. Every object you create
is **named** with a consistent convention — `<Purpose> – <Scope> – <Stage>` — and the same name is
reused in later labs, the knowledge-check, and the scripts. Run the labs against **real telemetry,
read-only or preview-first**; the only changes to the tenant are a benign **simulation** to a
consented lab group and one **alert-only** capstone detection.

> **Before you start:** confirm MDO feature availability (**R1**), the prevention stack exists to
> inspect (**R2**), a consented lab user group (**R3**), a simulation/communications note (**R4**),
> split roles (**R5**), and the **read-only / preview-first / approval-required** posture (**R6**).
> This enablement kit **inspects** the protection policies and does **not** reconfigure them; it builds
> skill, it does not perform the operational rollout.

**Named objects created in this enablement kit (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-MDOEnablement Kit-Cohort` | Entra security group of enablement kit learners |
| Lab user group | `Grp-MDO-LabUsers-Pilot` | Consented users for the simulation + hunting scope |
| Explorer saved view | `Explorer-MDOLab-Pilot` | Saved Threat Explorer query for the labs |
| Shared saved-query set | `Hunt-MDOLab-Pilot` | The email lab queries saved to shared queries |
| Simulation (lab) | `Sim-MDOLab-Pilot` | The benign Attack Simulation campaign, lab group only |
| Training assignment | `Training-MDOLab-Pilot` | Targeted training auto-assigned to those compromised |
| Custom detection (capstone) | `Detect-MDOLab-Pilot` | Alert-only detection built from a tuned lab hunt |
| Knowledge-check | `Check-MDOLab-Pilot` | The scored end-of-enablement kit knowledge-check |

The runnable queries for the hunting labs live in the delivered **`WSMDO-Labs.kql`** pack. Paste them
into Advanced hunting, or run one read-only via `WSMDO-RunLab.ps1`.

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm readiness

1. Sign in to `https://security.microsoft.com` and confirm the **Explorer**, **Attack simulation
   training**, **Action center**, and **Advanced hunting** blades are present.
2. From PowerShell:

   ```
   pwsh -File .\WSMDO-Discovery.ps1
   ```

   It reports Plan 2 presence, email-table freshness (`EmailEvents`, `UrlClickInfo`, …), the lab-group
   membership, and the Action center pending posture. **Read-only.**

### Step 0.2 — Create the cohort and lab user group

1. In **Entra** → **Groups → New group**: Security; **Name** `Grp-MDOEnablement Kit-Cohort`; add learners.
2. Create **`Grp-MDO-LabUsers-Pilot`** with a consented set of pilot users (avoid executives for the
   first simulation unless leadership approves — **R3**).
3. Assign read/hunt roles to learners; reserve simulation-launch + detection-authoring to the
   instructor (**R5**).

---

## Phase 1 — Configure (load the lab pack; nothing org-wide yet)

### Step 1.1 — Load the KQL lab pack and shared query set

1. Open `WSMDO-Labs.kql`; confirm you can paste a query into **Advanced hunting** and run it.
2. Save your first working query into **shared queries** under a folder **`Hunt-MDOLab-Pilot`**.

### Step 1.2 — Confirm AIR is approval-required

1. In the Defender portal, confirm **AIR** is enabled but configured so recommended actions **require
   approval** (they land in the **Action center**, not auto-applied). *Exact path evolves — verify.*
2. Record the setting so the lab can prove actions are **pending, not applied**.

---

## Phase 2 — Pilot (the guided labs)

### Lab 1 — The MDO console and the email-security model

- **Concept.** Two halves — prevention (block) and post-delivery (hunt/respond). Where Explorer,
  Attack Simulation, Action center, AIR, and Advanced hunting live.
- **Task.** Tour each blade; locate **Threat policies** (prevention) and **Explorer** (post-delivery).
- **Check.** You can navigate the whole MDO surface and say which half each feature belongs to.

### Lab 2 — Threat Explorer: hunt post-delivery

- **Concept.** Pivot on sender / recipient / URL / file / click verdict / delivery location; answer
  "who else got this, who clicked, is it still in inboxes?"
- **Task.** In **Explorer**, set a view, add filters (e.g. **Delivery action = Delivered**, a URL
  click column), and save it as **`Explorer-MDOLab-Pilot`**. Pivot on a real or benign scenario.
- **Check.** You can find recipients and clicks for a message and read the delivery location. *Explorer
  take-action is understood here, not executed against production (R6).*

### Lab 3 — Inspect the protection stack (read-only)

- **Concept.** Anti-phishing, **Safe Links**, and **Safe Attachments** produce the verdicts and
  click data Explorer surfaces. Reading them explains *why* a message was caught.
- **Task.** In **Threat policies**, **open (do not change)** the anti-phish, Safe Links, and Safe
  Attachments policies; map each setting to what it does. Note where Safe Links click data comes from.
- **Check.** You can explain a verdict from the policy configuration. *Changing these policies is the
  Mail Hygiene solution — this lab is read-only (R2).*

### Lab 4 — Attack Simulation Training (benign, lab group only)

- **Concept.** A safe, benign simulated phish measures who is compromised and auto-assigns training.
- **Task.** With the communications note confirmed (**R4**), launch a **Credential Harvest**
  simulation **`Sim-MDOLab-Pilot`** targeting **`Grp-MDO-LabUsers-Pilot`** only, using a built-in
  benign payload, with training assignment **`Training-MDOLab-Pilot`** enabled.
- **Check.** The campaign runs against the lab group and reports per-user results.

### Lab 5 — Email advanced hunting

- **Concept.** KQL over `EmailEvents`, `EmailUrlInfo`, `UrlClickInfo`, `EmailAttachmentInfo`.
- **Task.** Run the pack’s **Lab 5** queries — post-delivery clicks, recipients of a sender/subject
  indicator, bad-attachment hash — read-only:

  ```
  pwsh -File .\WSMDO-RunLab.ps1 -Lab 5
  ```

- **Check.** You can find who clicked after delivery and who received a campaign, and explain the join.

### Lab 6 — AIR: investigate, hold actions for approval

- **Concept.** AIR opens investigations automatically; in an approval posture its actions **wait** in
  the Action center.
- **Task.** Trigger AIR the safe way — have a lab user **Report** a benign/test message — then go to
  **Actions & submissions → Action center → Pending** and confirm the recommended actions are
  **waiting for approval**, not applied.
- **Check.** You can show AIR investigating while a human retains the approval. *Do not approve a
  production deletion in class (R6).*

### Lab 7 — From hunt to detection (alert-only)

- **Concept.** A tuned email hunt becomes a scheduled custom detection that **alerts only**.
- **Task.** Open your tuned Lab 5 query and choose **Create detection rule**. Name it
  **`Detect-MDOLab-Pilot`**, map the entities, and set the response to **generate an alert only** — no
  automatic remediation.
- **Check.** `Detect-MDOLab-Pilot` exists and is alert-only.

### Lab 8 — Reporting and user-risk

- **Concept.** The simulation produces a susceptibility / repeat-offender picture; hunting + Explorer
  produce a post-delivery threat picture.
- **Task.** Review the `Sim-MDOLab-Pilot` report and run:

  ```
  pwsh -File .\WSMDO-Report.ps1 -OutputCsv .\wsmdo-cohort.csv
  ```

- **Check.** You can read the user-risk report and the per-lab data summary.

---

## Phase 3 — Validate (capstone + knowledge-check)

1. **Capstone hunt.** Each learner reproduces the Lab 5 post-delivery-click hunt from a blank editor
   and explains who received / who clicked.
2. **Knowledge-check.** Score `Check-MDOLab-Pilot`:

   ```
   pwsh -File .\WSMDO-Validate.ps1
   ```

   It walks the `05-testing.md` gates — readiness, email tables have data, the simulation reported,
   hunting resolves, AIR **pending (not auto-applied)**, and `Detect-MDOLab-Pilot` **alert-only** —
   and prints a score.

---

## Phase 4 — Expand (operationalize the skills)

1. **Adopt the hunts.** Move the tuned queries from `Hunt-MDOLab-Pilot` and the saved
   `Explorer-MDOLab-Pilot` view into the team’s standing library.
2. **Hand off the rollout.** Turning these features on across the org, tuning AIR automation, and
   running gated production remediation is the **Defender for Office 365 (Plan 2)** implementation
   solution — hand it the skills and artifacts the enablement kit produced.
3. **Widen simulation deliberately.** Broadening the simulation beyond the lab group and setting a
   cadence is a **people/security decision (R4)**, made with HR — not a default this enablement kit flips.
4. **Promote detections deliberately.** If `Detect-MDOLab-Pilot` proves quiet and accurate, security
   operations may **document a decision** to promote it (renamed for production).

---

## Rollback / safe-off

- **Simulation:** stop or cancel `Sim-MDOLab-Pilot` in Attack Simulation Training; it delivers no real
  payload, so stopping it has no cleanup cost.
- **AIR / remediation:** AIR stayed **approval-required** and no remediation was executed — reject any
  pending action in the Action center to "undo".
- **Hunting / Explorer / policy inspection:** read-only — nothing to roll back.
- **Custom detection:** disable or delete `Detect-MDOLab-Pilot`; it is alert-only and never remediates.
- **Groups / saved queries:** delete `Grp-MDOEnablement Kit-Cohort`, `Grp-MDO-LabUsers-Pilot`,
  `Explorer-MDOLab-Pilot`, and the `Hunt-MDOLab-Pilot` folder if the enablement kit was one-off; keep them if
  operationalizing.
