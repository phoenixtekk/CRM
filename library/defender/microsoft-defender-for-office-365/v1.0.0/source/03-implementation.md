# Implementation — Microsoft Defender for Office 365 (Enable & Prove)

This is the exact, ordered playbook. It runs two joined tracks against one consented pilot group:
**Track A — enable the team** (guided hands-on labs) and **Track B — prove value** (a scoped, safe
PoC). Every object you create is **named** with a consistent convention — `<Purpose> – <Scope> –
<Stage>` — and the same name is reused in later steps, the knowledge-check, the tests, and the
scripts. Run everything against **real telemetry, read-only or preview-first**; the only changes to the
tenant are a benign **simulation**, benign **test messages** to the pilot group, and one **alert-only**
capstone detection — all reversible.

> **Before you start:** confirm MDO feature availability (**R1**), that the prevention stack exists to
> inspect and is applied to the pilot users (**R2**), a consented pilot group (**R3**), a
> simulation/communications note (**R4**), split roles (**R5**), the **read-only / preview-first /
> approval-required / -WhatIf** posture (**R6**), agreed PoC evaluation criteria (**R7**), and the
> toolchain (**R8**). This solution **inspects** the protection policies and does **not** reconfigure
> them; the configuration baseline is the cross-referenced **Mail Hygiene** and **Defender for Office
> 365 (Plan 2)** solutions.

**Named objects created here (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-MDOFULL-Cohort-Pilot` | Entra security group of the learners |
| Pilot user group | `Grp-MDOFULL-PilotUsers-Pilot` | Consented users: hunting scope + simulation target + PoC signal recipients |
| Explorer saved view | `Explorer-MDOFULL-Pilot` | Saved Threat Explorer query for the labs |
| Shared saved-query set | `Hunt-MDOFULL-Pilot` | The email lab queries saved to shared queries |
| Simulation | `Sim-MDOFULL-Pilot` | The benign Attack Simulation campaign, pilot group only |
| Training assignment | `Training-MDOFULL-Pilot` | Targeted training auto-assigned to those compromised |
| Custom detection (capstone) | `Detect-MDOFULL-Pilot` | Alert-only detection built from a tuned lab hunt |
| Knowledge-check | `Check-MDOFULL-Pilot` | The scored end-of-labs knowledge-check |
| PoC test-signal tag | `MDOFULL-TESTSIGNAL` | Subject tag on the benign GTUBE/EICAR/Safe Links messages |
| PoC evidence file | `MDOFULL Evidence – Pilot Users – Validate.json` | The captured capability evidence / scorecard |

The runnable queries for the hunting labs and PoC validation live in the delivered
**`MDOFULL-Labs.kql`** pack. Paste them into Advanced hunting, or run one read-only via
`MDOFULL-RunLab.ps1`.

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm readiness

1. Sign in to `https://security.microsoft.com` and confirm the **Explorer**, **Attack simulation
   training**, **Action center**, and **Advanced hunting** blades are present.
2. From PowerShell:

   ```
   pwsh -File .\MDOFULL-Discovery.ps1
   ```

   It reports Plan 2 presence, email-table freshness (`EmailEvents`, `UrlClickInfo`, …), the pilot-group
   membership, and the Action center pending posture. **Read-only.**
3. Confirm the **prevention baseline exists to inspect** — **Email & collaboration → Policies & rules →
   Threat policies** lists anti-phish / Safe Links / Safe Attachments (or a Preset), applied to the
   pilot users (**R2**). If not, deploy/scope it with the **Mail Hygiene** solution first.

### Step 0.2 — Create the cohort and pilot group

1. In **Entra** → **Groups → New group**: Security; **Name** `Grp-MDOFULL-Cohort-Pilot`; add the
   learners.
2. Create the mail-enabled security group **`Grp-MDOFULL-PilotUsers-Pilot`** with a consented set of
   test/volunteer pilot users (avoid executives for a first simulation unless leadership approves —
   **R3**). Tell those users a benign simulation is coming.
3. Assign read/hunt roles to learners; reserve simulation-launch, detection-authoring, benign-signal
   sending, and quarantine purge to the instructor/operator (**R5**).

---

## Phase 1 — Configure (load the lab pack; confirm posture; nothing org-wide)

### Step 1.1 — Load the KQL lab pack and shared query set

1. Open `MDOFULL-Labs.kql`; confirm you can paste a query into **Advanced hunting** and run it.
2. Save your first working query into **shared queries** under a folder **`Hunt-MDOFULL-Pilot`**.

### Step 1.2 — Confirm AIR is approval-required

1. In the Defender portal, confirm **AIR** is enabled but configured so recommended actions **require
   approval** (they land in the **Action center**, not auto-applied). *Exact path evolves — verify.*
2. Record the setting so the labs and PoC can prove actions are **pending, not applied**.

> **Note on production configuration.** Turning the prevention policies on/tuning them, and turning the
> post-delivery features on org-wide, are **not** done here — they are the **Mail Hygiene** and
> **Defender for Office 365 (Plan 2)** solutions. This phase only loads the lab pack and confirms the
> safe posture.

---

## Phase 2A — Pilot: enable the team (guided labs)

### Lab 1 — The MDO console and the email-security model

- **Concept.** Two halves — prevention (block) and post-delivery (hunt/respond). Where Explorer,
  Attack Simulation, Action center, AIR, and Advanced hunting live.
- **Task.** Tour each blade; locate **Threat policies** (prevention) and **Explorer** (post-delivery).
- **Check.** You can navigate the whole MDO surface and say which half each feature belongs to.

### Lab 2 — Threat Explorer: hunt post-delivery

- **Concept.** Pivot on sender / recipient / URL / file / click verdict / delivery location; answer
  "who else got this, who clicked, is it still in inboxes?"
- **Task.** In **Explorer**, set a view, add filters (e.g. **Delivery action = Delivered**, a URL click
  column), and save it as **`Explorer-MDOFULL-Pilot`**. Pivot on a real or benign scenario.
- **Check.** You can find recipients and clicks for a message and read the delivery location. *Explorer
  take-action is understood here, not executed against production (R6).*

### Lab 3 — Inspect the protection stack (read-only)

- **Concept.** Anti-phishing, **Safe Links**, and **Safe Attachments** produce the verdicts and click
  data Explorer surfaces. Reading them explains *why* a message was caught.
- **Task.** In **Threat policies**, **open (do not change)** the anti-phish, Safe Links, and Safe
  Attachments policies; map each setting to what it does. Note where Safe Links click data comes from.
- **Check.** You can explain a verdict from the policy configuration. *Changing these policies is the
  Mail Hygiene solution — this lab is read-only (R2).*

### Lab 4 — Attack Simulation Training (benign, pilot group only)

- **Concept.** A safe, benign simulated phish measures who is compromised and auto-assigns training.
- **Task.** With the communications note confirmed (**R4**), launch a **Credential Harvest** simulation
  **`Sim-MDOFULL-Pilot`** targeting **`Grp-MDOFULL-PilotUsers-Pilot`** only, using a built-in benign
  payload, with training assignment **`Training-MDOFULL-Pilot`** enabled.
- **Check.** The campaign runs against the pilot group and reports per-user results. *(This same
  simulation is also the phishing signal for the PoC track — Phase 2B.)*

### Lab 5 — Email advanced hunting

- **Concept.** KQL over `EmailEvents`, `EmailUrlInfo`, `UrlClickInfo`, `EmailAttachmentInfo`.
- **Task.** Run the pack's **Lab 5** queries — post-delivery clicks, recipients of a sender/subject
  indicator, bad-attachment hash — read-only:

  ```
  pwsh -File .\MDOFULL-RunLab.ps1 -Lab 5a
  ```

- **Check.** You can find who clicked after delivery and who received a campaign, and explain the join.

### Lab 6 — AIR: investigate, hold actions for approval

- **Concept.** AIR opens investigations automatically; in an approval posture its actions **wait** in
  the Action center.
- **Task.** Trigger AIR the safe way — have a pilot user **Report** a benign/test message — then go to
  **Actions & submissions → Action center → Pending** and confirm the recommended actions are **waiting
  for approval**, not applied.
- **Check.** You can show AIR investigating while a human retains the approval. *Do not approve a
  production deletion in class (R6).*

### Lab 7 — From hunt to detection (alert-only)

- **Concept.** A tuned email hunt becomes a scheduled custom detection that **alerts only**.
- **Task.** Open your tuned Lab 5 query and choose **Create detection rule**. Name it
  **`Detect-MDOFULL-Pilot`**, map the entities (RecipientEmailAddress, Url), and set the response to
  **generate an alert only** — no automatic remediation.
- **Check.** `Detect-MDOFULL-Pilot` exists and is alert-only.

### Lab 8 — Reporting and user-risk

- **Concept.** The simulation produces a susceptibility / repeat-offender picture; hunting + Explorer
  produce a post-delivery threat picture.
- **Task.** Review the `Sim-MDOFULL-Pilot` report and run:

  ```
  pwsh -File .\MDOFULL-Report.ps1 -OutputCsv .\mdofull-cohort.csv
  ```

- **Check.** You can read the user-risk report and the per-lab data summary.

---

## Phase 2B — Pilot: prove value (the guided PoC)

The PoC runs on the **same pilot group** already protected by the configured prevention stack (**R2**).
It fires **benign** signal, demonstrates the headline detections, and captures evidence — then cleans
up in Phase 4.

### Step P.1 — Generate benign test signal

1. Preview first, then send:

   ```
   pwsh -File .\MDOFULL-TestSignal.ps1 -WhatIf
   pwsh -File .\MDOFULL-TestSignal.ps1 -From tester@contoso.com -To pilotuser@contoso.com
   ```

   It performs only **benign, documented** actions, tagged `MDOFULL-TESTSIGNAL`:
   - Prints the exact steps to launch the Attack Simulation campaign `Sim-MDOFULL-Pilot` (the same
     one from Lab 4 — Microsoft's safe simulator, no real phishing).
   - Sends a benign **GTUBE** anti-spam test message.
   - Sends a benign **EICAR** attachment message (exercises Safe Attachments).
   - Sends a benign **Safe Links** test URL message (exercises time-of-click rewriting).
2. **Do not** send real phishing, real malware, or live malicious URLs. The benign signals above are
   sufficient.
3. Note the time of each signal for latency comparison.

### Step P.2 — Demonstrate the detections

1. Confirm the detections read-only:

   ```
   pwsh -File .\MDOFULL-Validate.ps1
   ```

   It confirms Safe Links rewrote (`UrlClickInfo`/`UrlClickEvents`), Safe Attachments actioned the
   EICAR message (`EmailAttachmentInfo`/`EmailEvents`), the spam string was handled, and the signal
   appears in `EmailEvents`.
2. In the portal, walk the live demo: **Explorer** (Threat Explorer, P2) shows the simulation and test
   messages; open a message → view the **Safe Links** verdict; **Review → Quarantine** shows
   quarantined `MDOFULL-TESTSIGNAL` items; **Attack simulation training** shows the campaign results.
3. Confirm no production mailbox outside `Grp-MDOFULL-PilotUsers-Pilot` was affected.

---

## Phase 3 — Validate (capstone + knowledge-check + PoC evidence)

1. **Capstone hunt.** Each learner reproduces the Lab 5 post-delivery-click hunt from a blank editor
   and explains who received / who clicked.
2. **Knowledge-check + gates.** Score `Check-MDOFULL-Pilot` and run the pass/fail gates:

   ```
   pwsh -File .\MDOFULL-Validate.ps1
   ```

   It walks the `05-testing.md` gates — readiness, email tables have data, hunting resolves, the PoC
   capability checks (Safe Links / Safe Attachments / spam-phish), AIR **pending (not auto-applied)**,
   and `Detect-MDOFULL-Pilot` **alert-only** — and prints a score plus the knowledge-check answer key.
3. **Capture PoC evidence.** Map the observations to your agreed criteria (**R7**) and write the
   evidence file:

   ```
   pwsh -File .\MDOFULL-Report.ps1 -CriteriaPath .\criteria.json -EvidenceOut "MDOFULL Evidence – Pilot Users – Validate.json"
   ```

   Review it with stakeholders — the decision artefact. *Whether the PoC "passed" and how criteria are
   weighted is the customer's decision.*

---

## Phase 4 — Expand (operationalise) + tear down the PoC signal

1. **Adopt the hunts.** Move the tuned queries from `Hunt-MDOFULL-Pilot` and the saved
   `Explorer-MDOFULL-Pilot` view into the team's standing library.
2. **Hand off the rollout.** Turning these features on across the org, tuning AIR automation, and
   running gated production remediation is the **Defender for Office 365 (Plan 2)** solution — hand it
   the skills, artifacts, and evidence this solution produced.
3. **Tighten prevention deliberately.** Any change to the anti-phish / Safe Links / Safe Attachments
   policies you learned to read is the **Mail Hygiene** solution — not a default this solution flips.
4. **Widen simulation deliberately.** Broadening the simulation beyond the pilot group and setting a
   cadence is a **people/security decision (R4)**, made with HR.
5. **Promote detections deliberately.** If `Detect-MDOFULL-Pilot` proves quiet and accurate, security
   operations may **document a decision** to promote it (renamed for production).
6. **Tear down the benign PoC signal.** Preview, then apply:

   ```
   pwsh -File .\MDOFULL-TestSignal.ps1 -Teardown -WhatIf
   pwsh -File .\MDOFULL-TestSignal.ps1 -Teardown
   ```

   It purges the `MDOFULL-TESTSIGNAL` messages from quarantine and prints the steps to end the
   simulation `Sim-MDOFULL-Pilot`. Keep the evidence file as your record.

---

## Rollback / safe-off

- **Benign PoC signal:** run `MDOFULL-TestSignal.ps1 -Teardown` to purge the `MDOFULL-TESTSIGNAL`
  messages; the signal is benign and needs no other cleanup.
- **Simulation:** stop or cancel `Sim-MDOFULL-Pilot` in Attack Simulation Training; it delivers no real
  payload, so stopping it has no cleanup cost.
- **AIR / remediation:** AIR stayed **approval-required** and no remediation was executed — reject any
  pending action in the Action center to "undo".
- **Hunting / Explorer / policy inspection:** read-only — nothing to roll back.
- **Custom detection:** disable or delete `Detect-MDOFULL-Pilot`; it is alert-only and never
  remediates.
- **Groups / saved queries:** delete `Grp-MDOFULL-Cohort-Pilot`, `Grp-MDOFULL-PilotUsers-Pilot`,
  `Explorer-MDOFULL-Pilot`, and the `Hunt-MDOFULL-Pilot` folder if this was one-off; keep them if
  operationalising.
- **Prevention policies:** never touched here — they belong to the **Mail Hygiene** solution.
