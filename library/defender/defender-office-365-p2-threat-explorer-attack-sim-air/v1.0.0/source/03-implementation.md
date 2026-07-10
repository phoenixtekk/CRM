# Implementation — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

This is the exact, ordered build. Every object you create is **named** with a consistent convention
— `<Purpose> – <Scope> – <Stage>` — and the same name is reused in later steps, testing, and the
scripts. Do the pilot phases against **`Grp-MDO-Pilot-Users`** before anything organization-wide.

> **Before you start:** confirm the prevention layer is already deployed (**R2**) and Plan 2 is
> licensed (**R1**). This solution does **not** configure anti-spam / anti-phishing / Safe Links /
> Safe Attachments — it hunts, simulates, and responds on top of them.

**Named objects created in this guide (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Pilot user group | `Grp-MDO-Pilot-Users` | Entra security group — first simulation + hunting/remediation scope |
| Explorer saved view | `Explorer-PostDelivery-Pilot` | Saved Threat Explorer query for post-delivery hunting |
| Simulation (pilot) | `Sim-CredHarvest-Pilot` | First Attack Simulation campaign, pilot group only |
| Training assignment | `Training-PhishAware-Pilot` | Targeted training auto-assigned to those compromised |
| Custom detection | `Detect-PostDeliveryPhish-Pilot` | Advanced Hunting custom detection rule |
| Remediation batch | `Remediation-PhishBatch-Pilot` | Approval-gated response action set |
| Simulation (org wave) | `Sim-CredHarvest-Org` | Organization-wide simulation, created only at Expand |

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm Plan 2 features are present

1. Sign in to the **Microsoft Defender portal** → `https://security.microsoft.com` as a Security
   Administrator.
2. Confirm these blades are visible:
   - **Email & collaboration → Explorer** (Threat Explorer). *If you see only "Real-time detections"
     you are on Plan 1 — verify licensing (R1).*
   - **Email & collaboration → Attack simulation training.**
   - **Actions & submissions → Action center.**
   - **Investigation & response → Hunting → Advanced hunting.**
3. Run the discovery script to inventory readiness from PowerShell:

   ```
   pwsh -File .\DEFMDOP2-Discovery.ps1 -PilotGroup "Grp-MDO-Pilot-Users"
   ```

   It reports Plan 2 service-plan presence, whether the email Advanced Hunting tables have recent
   data, current AIR/automation posture where readable, and any actions already pending in the
   Action center. **Read-only.**

### Step 0.2 — Confirm the prevention layer exists

1. Go to **Email & collaboration → Policies & rules → Threat policies**.
2. Confirm anti-phishing, anti-malware, anti-spam, **Safe Links**, and **Safe Attachments** policies
   exist (or a **Preset security policy** is Standard/Strict enabled). **Do not edit them here** —
   they belong to the prevention (companion) solution. You are only confirming the signal source.

---

## Phase 1 — Configure (build the objects; nothing org-wide yet)

### Step 1.1 — Create the pilot group

1. In **Entra admin center** (`entra.microsoft.com`) → **Groups → New group**.
2. Type **Security**; **Name** `Grp-MDO-Pilot-Users`; add a representative, **consented** set of
   pilot users (avoid top executives for the very first simulation unless leadership approves — R4).
3. Save. This group is the target for the pilot simulation and the scope for pilot hunting and
   remediation.

### Step 1.2 — Set AIR to an approval-required posture

1. In the Defender portal → **Settings → Email & collaboration → (Automation / Advanced automation
   settings)** — *exact path evolves; verify current location in your tenant.*
2. Confirm **Automated Investigation & Response** is **enabled** but configured so that recommended
   remediation actions **require approval** (they land in the Action center rather than auto-apply).
   The goal for the pilot is: **AIR investigates automatically, a human approves every action.**
3. Record the current setting so you can prove (in testing) that actions are pending, not applied.

### Step 1.3 — Save the post-delivery hunting view in Explorer

1. Go to **Email & collaboration → Explorer**.
2. Set the view to **All email** (or **Phish** / **Malware** as needed), set the time range, and add
   filters that represent your standard post-delivery hunt — e.g. **Delivery action = Delivered**,
   **Detection technology**, and a **URL click verdict** column.
3. Save the query as **`Explorer-PostDelivery-Pilot`** (Explorer supports saving/sharing queries —
   *verify current save/track behavior in your tenant*). This is the reusable starting point for
   post-delivery hunts.

### Step 1.4 — Import the email Advanced Hunting query library

1. Go to **Investigation & response → Hunting → Advanced hunting**.
2. Paste each query from the delivered KQL library (surfaced by `DEFMDOP2-Hunt.ps1`) — for example:
   - **Post-delivery malicious URL clicks** — join `UrlClickInfo` / `UrlClickInfo`-style click data
     to `EmailUrlInfo` and `EmailEvents` to find users who **clicked after delivery**.
   - **Recipients of a known-bad sender/subject** — `EmailEvents` filtered to a campaign indicator.
   - **Attachments matching a known-bad hash** — `EmailAttachmentInfo` joined to `EmailEvents`.
   *Table/column names evolve — verify against your tenant's schema.*
3. **Save** the most useful queries to your shared queries so the team reuses them.

### Step 1.5 — Stage (but do not launch) the first simulation

1. Go to **Email & collaboration → Attack simulation training → Simulations → Launch a simulation**.
2. **Technique:** choose **Credential Harvest** for the first run (lowest-risk, highest-signal).
3. **Name:** `Sim-CredHarvest-Pilot`.
4. **Target users:** select **`Grp-MDO-Pilot-Users`** only.
5. **Payload:** choose a built-in benign payload (or a globally provided one). Do **not** craft one
   that impersonates a real internal person or brand without approval.
6. **Training:** enable **assign training** and configure the training assignment
   **`Training-PhishAware-Pilot`** to auto-assign to users who are compromised.
7. **Schedule:** set a launch time but keep the campaign in a **staged / scheduled** state until the
   communications plan (R5) is confirmed. **Do not launch yet.**

---

## Phase 2 — Pilot (run against the pilot group only)

### Step 2.1 — Launch the pilot simulation

1. With the communications/HR plan (R5) confirmed, launch **`Sim-CredHarvest-Pilot`** to
   **`Grp-MDO-Pilot-Users`**.
2. Let it run its window. As users interact, Attack Simulation Training records **compromise** and
   auto-assigns **`Training-PhishAware-Pilot`**.

### Step 2.2 — Hunt post-delivery on the pilot scope

1. Open **`Explorer-PostDelivery-Pilot`** and scope it to `Grp-MDO-Pilot-Users` recipients; review a
   real or test post-delivery scenario (who received, who clicked, current delivery location).
2. Run the Advanced Hunting library from PowerShell:

   ```
   pwsh -File .\DEFMDOP2-Hunt.ps1 -QuerySet PostDeliveryPhish -LookbackDays 7
   ```

   It runs the KQL library via Graph and returns the recipients/clicks/attachments matching the
   indicators. **Read-only.**

### Step 2.3 — Let AIR investigate, and hold actions for approval

1. Trigger an investigation the safe way — e.g. have a pilot user **Report** a test/benign message,
   or use a submitted URL — so AIR opens an investigation.
2. Go to **Actions & submissions → Action center → Pending**. Confirm AIR's **recommended actions**
   are **waiting for approval** (not applied). This proves the approval-required posture (Step 1.2).

### Step 2.4 — Practice a gated remediation in preview (no deletion)

1. From a hunt result, build the response set and **preview** it — never delete blind:

   ```
   pwsh -File .\DEFMDOP2-Remediate.ps1 -InputCsv .\hunt-results.csv `
        -Action SoftDelete -BatchName "Remediation-PhishBatch-Pilot" -WhatIf
   ```

   With `-WhatIf` (the default posture) the script **only prints what it would do** — the messages,
   mailboxes, and action — and changes nothing.
2. To actually remediate, do it **through the Action center approval flow** (or re-run with the
   explicit `-Execute -Confirm` gate the script requires), starting with **SoftDelete** (recoverable)
   before ever considering **HardDelete**. Every execution is approved by a named operator (R6).

### Step 2.5 — Build the custom detection (pilot)

1. In **Advanced hunting**, open the tuned post-delivery query and choose **Create detection rule**.
2. Name it **`Detect-PostDeliveryPhish-Pilot`**, set frequency and the impacted entities, and keep
   its response action to **generate an alert only** during the pilot (no automatic remediation).

---

## Phase 3 — Validate

1. Run the validation script:

   ```
   pwsh -File .\DEFMDOP2-Validate.ps1 -PilotGroup "Grp-MDO-Pilot-Users"
   ```

   It checks the pass/fail gates in `05-testing.md`: Plan 2 present, email tables have data, the
   simulation ran and reported, AIR actions are **pending (not auto-applied)**, the custom detection
   exists in alert-only mode, and the remediation preview resolves.
2. Run the reporting script and review results with stakeholders:

   ```
   pwsh -File .\DEFMDOP2-Report.ps1 -LookbackDays 30 -OutputCsv .\mdop2-report.csv
   ```

   It reports post-delivery threat activity and the **attack-simulation user-risk / repeat-offender**
   picture. Do not expand until the gates pass and the reports look right.

---

## Phase 4 — Expand

1. **Widen the simulation.** Create **`Sim-CredHarvest-Org`** targeting the broader organization (or
   the next ring), per the approved cadence in the communications plan (R5).
2. **Promote the custom detection.** Once `Detect-PostDeliveryPhish-Pilot` is proven quiet and
   accurate, widen its scope (and rename per your convention for production).
3. **Decide the AIR automation level — deliberately.** If the pilot has built trust, security
   operations may **document a decision** to raise AIR from approval-required to a higher automation
   level for specific, well-understood action types. This is an **operations decision (R6)**, made
   with rollback in mind — not a default this solution flips for you.
4. **Institutionalize the loop.** Schedule recurring hunts, simulations, and reporting, and keep
   hard-delete a named-approver-only action.

---

## Rollback / safe-off

- **Simulation:** stop or cancel a running campaign in **Attack simulation training**; it delivers no
  real payload, so stopping it has no cleanup cost.
- **AIR / remediation:** because you started **approval-required** and previewed remediation with
  `-WhatIf`, nothing is auto-applied — reject pending actions in the Action center to "undo". A
  **SoftDelete** is recoverable from Deleted Items; **HardDelete** is not, which is why it is gated.
- **Custom detection:** disable `Detect-PostDeliveryPhish-Pilot` to stop it generating alerts.
- **Explorer / hunting:** read-only — nothing to roll back.
