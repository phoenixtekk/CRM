# Workshop — Microsoft Defender for Office 365

> **Version 1.0.0** · Category: Defender · Solution code: WSMDO

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Workshop: Microsoft Defender for Office 365

## The problem

Email is still the number-one way attackers get in, and **Microsoft Defender for Office 365 (MDO)**
is the platform meant to stop them — before and after delivery. Most teams that own it run the
prevention half on defaults and never learn the detection-and-response half, so the tool is bought
and under-driven. The predictable gaps:

- **No post-delivery visibility.** When a phish lands anyway, no one can quickly answer "who else got
  this?", "who clicked?", or "is it still in inboxes?" — because they never learned **Threat
  Explorer**.
- **Protection policies as a black box.** Anti-phishing, **Safe Links**, and **Safe Attachments** are
  configured once and never understood, so no one can read why a message was (or wasn’t) caught.
- **Untrained users, untested.** **Attack Simulation Training** — the safe way to measure who is
  susceptible and train them — sits unused.
- **Manual investigation.** **Automated Investigation & Response (AIR)** and email advanced hunting go
  unused, so removing a malicious message from dozens of mailboxes is done by hand.

## The solution

This is a **structured enablement workshop** — concepts, **guided hands-on labs**, a **take-home
runbook**, and a **knowledge-check** — that takes an admin or SOC analyst across the whole MDO
surface: **Threat Explorer** hunting, understanding **anti-phish / Safe Links / Safe Attachments**,
running **Attack Simulation Training**, working **AIR** in an approval posture, and **email advanced
hunting** with KQL. It is a **skills** product:

- **Teaches post-delivery hunting** — pivot in Threat Explorer on sender, URL, file, or click and see
  who received and who interacted.
- **Makes the protection policies legible** — inspect (read-only) how anti-phish, Safe Links, and
  Safe Attachments decide, so analysts can reason about verdicts.
- **Runs a safe, benign simulation** — measure susceptibility on a lab group and auto-assign training.
- **Practices AIR and remediation safely** — AIR held **approval-required**, remediation **previewed**
  only; ends in an **alert-only** custom detection and a **knowledge-check**.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure →
Pilot → Validate → Expand** — reframed for enablement. We confirm the MDO features are available and
email tables have data, stand up a small **lab user group** and a learner **cohort**, run the
**guided labs** read-only / preview-first against real telemetry, **validate** with a capstone and a
knowledge-check, and then **expand** — folding the skills, saved hunts, and detection into the live
email-security practice.

The package ships as **self-guided, click-by-click documentation plus a runnable email KQL lab pack
and four PowerShell helpers** that check readiness, run a chosen lab query read-only, score the
knowledge-check, and report cohort progress — all **read-only or preview-first**, with **no
credentials in code**.

## Why it matters

- **You see what happens after delivery** — who received, who clicked, whether it’s still in inboxes
  — in minutes, from Explorer and hunting.
- **Users get measurably safer** — real susceptibility data and targeted training, not a once-a-year
  slideshow.
- **Response is fast but controlled** — AIR and remediation understood and practiced safely, then run
  through approvals in real incidents.
- **A fraction of consulting cost** — the same disciplined method a Defender specialist would teach,
  delivered as a repeatable runbook you keep and re-run for new hires.

## Important boundaries

This is a **skills / enablement** product — it teaches people to hunt, simulate, and respond with
MDO. It **cross-references rather than repeats** two adjacent catalog solutions: the **Defender for
Office 365 (Plan 2): Threat Explorer, Attack Simulation & AIR** implementation solution (which turns
these features *on and operationalizes* them) and the **Microsoft 365 Mail Hygiene: Anti-Spam, EOP &
Defender for Office 365** solution (which *configures the prevention policies*). This workshop
**inspects** the protection policies read-only and **does not reconfigure** them. All labs are
**read-only or preview-first**: AIR stays **approval-required**, remediation is **previewed only**,
and no message is deleted in class. It provides the **technical skill and the labs**, not the
**decisions**: which users to simulate, acceptable click-rate, the AIR automation level, and every
production remediation are the customer’s **security-operations / HR-legal calls**. MDO features
(Threat Explorer, Attack Simulation, AIR, email tables) are **Plan-gated and evolve, and can differ
by cloud (Commercial vs GCC / GCC High)** — *verify current availability and licensing in your
tenant*.


---


# Solution Overview — Workshop: Microsoft Defender for Office 365

## What this is

A complete, self-guided **enablement workshop** that takes an admin or SOC analyst across the whole
**Microsoft Defender for Office 365 (MDO)** surface — **Threat Explorer**, the **anti-phish / Safe
Links / Safe Attachments** protection stack, **Attack Simulation Training**, **Automated
Investigation & Response (AIR)**, and **email advanced hunting** — as concepts, **guided hands-on
labs**, a **runnable email KQL lab pack**, a **take-home runbook**, and a **knowledge-check**.

It is a **skills** product — the outcome is people who can drive MDO. It **cross-references** two
adjacent catalog solutions: the **Defender for Office 365 (Plan 2): Threat Explorer, Attack
Simulation & AIR** implementation solution (which turns the post-delivery features on and
operationalizes them), and the **Microsoft 365 Mail Hygiene** solution (which configures the
prevention policies). This workshop **inspects** those policies read-only and applies the skills; it
does not reconfigure the prevention stack or perform the production rollout.

## How the technology works (the mental model)

- **Two halves: prevention and post-delivery.** MDO both **blocks** mail (anti-spam, anti-malware,
  anti-phishing, Safe Links, Safe Attachments) and lets you **hunt and respond** to what gets through
  (Threat Explorer, AIR, email hunting). The workshop teaches both halves; it **configures** neither.
- **Threat Explorer / Real-time detections.** The interactive hunting surface for email — pivot on
  **sender, recipient, subject, URL, file hash, delivery location, click verdict** and **take action**
  on results. Answers "who else got this, who clicked, is it still in inboxes?" **Real-time
  detections** is the Plan 1 view; **Threat Explorer** (Plan 2) adds depth and retention. *Verify plan
  mapping for your tenant.*
- **The protection stack (inspect, don’t reconfigure).** **Anti-phishing** (impersonation & spoof
  intelligence), **Safe Links** (time-of-click URL rewriting/detonation), and **Safe Attachments**
  (sandbox detonation) produce the verdicts and click data Explorer and hunting surface. In this
  workshop you **read** these policies to understand *why* a message was caught; changing them is the
  **Mail Hygiene** solution.
- **Attack Simulation Training.** A Plan 2 feature that sends **benign, controlled** simulated phishing
  to chosen users, measures who is **compromised**, and **auto-assigns targeted training**. Safe by
  design — no real payload.
- **Automated Investigation & Response (AIR).** When certain email alerts fire, AIR **opens an
  investigation**, correlates evidence, and **recommends** remediation. In an **approval-required**
  posture those actions wait in the **Action center** for a human — nothing auto-deletes.
- **Email advanced hunting.** KQL over the email tables — `EmailEvents`, `EmailAttachmentInfo`,
  `EmailUrlInfo`, `EmailPostDeliveryEvents`, `UrlClickInfo` — for proactive hunting and custom
  detections. Email tables are Plan 2 — *verify availability in your tenant*.

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the workshop:

1. **Assess.** Confirm the MDO features are available and the email tables have data (run
   `WSMDO-Discovery.ps1`).
2. **Configure.** Create the learner cohort `Grp-MDOWorkshop-Cohort` and the lab user group
   `Grp-MDO-LabUsers-Pilot`; load the KQL lab pack `WSMDO-Labs.kql`; agree the **read-only /
   preview-first / approval-required** posture.
3. **Pilot.** Run the **guided labs** (Labs 1–8) with the cohort — console & email-security model,
   Threat Explorer hunting, inspecting the protection stack, a benign simulation, email hunting, AIR
   held for approval, hunt→detection, reporting/user-risk.
4. **Validate.** Run the **capstone** hunt and score the **knowledge-check** `Check-MDOLab-Pilot`
   (`WSMDO-Validate.ps1`); confirm AIR actions are **pending (not auto-applied)** and the detection
   `Detect-MDOLab-Pilot` is **alert-only**.
5. **Expand.** Fold the skills, the saved hunts `Hunt-MDOLab-Pilot`, and the detection into the **live
   email-security practice** — handing the operational rollout to the **Defender for Office 365 (Plan
   2)** implementation solution.

## Scope — what this workshop covers

- **Threat Explorer** — post-delivery email hunting and pivoting (take-action understood, not executed
  in class).
- **The protection stack (read-only)** — inspecting anti-phish / Safe Links / Safe Attachments to
  understand verdicts.
- **Attack Simulation Training** — a benign campaign on the lab group, susceptibility measurement,
  auto-assigned training.
- **AIR** — triggering an investigation the safe way and confirming actions are **held for approval**.
- **Email advanced hunting** — a KQL lab pack over the email tables, ending in an **alert-only**
  custom detection.
- **Reporting / user-risk** and a **take-home runbook + knowledge-check**.

## Out of scope (handled elsewhere)

- **Configuring the prevention policies.** Anti-spam/-malware/-phishing, Safe Links, Safe Attachments,
  connection filtering, and mail-flow hygiene are the **Microsoft 365 Mail Hygiene** solution. This
  workshop **inspects** them read-only.
- **The operational post-delivery rollout.** Turning these features on across the org, tuning AIR
  automation, and running gated production remediation is the **Defender for Office 365 (Plan 2)**
  implementation solution. This workshop builds the **skill**; that product does the **rollout**.
- **Executing production remediation.** Soft/hard-delete and ZAP-style purge against real mail are
  approval-gated incident actions — not workshop labs.
- **The security / HR-legal decisions.** Which users to simulate, acceptable click-rate, the AIR
  automation level, works-council notification, and every production remediation are **the customer’s
  determinations**; this workshop provides the skill, the labs, and the data.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.com`) for Threat Explorer, Attack Simulation
  Training, Action center, AIR settings, Advanced hunting, and custom detection rules.
- **PowerShell** with **Microsoft.Graph** (security — advanced hunting via `security/runHuntingQuery`;
  attack-simulation reporting where available — *some endpoints are beta; verify*) and, where used,
  **Exchange Online / Security & Compliance** for MDO reporting cmdlets — used only to **check
  readiness, run lab queries read-only**, score the knowledge-check, and report progress.
- All helpers authenticate **interactively** with an MFA-capable account holding at least read/hunt
  scopes; **no credentials are stored in code**. Government-cloud tenants pass the matching endpoints
  — *verify endpoints for your cloud*.


---


# Requirements — Workshop: Microsoft Defender for Office 365

These are the **solution-specific** prerequisites for running the MDO enablement workshop. The
**category baseline** — an active Microsoft 365 / Entra tenant, Defender licensing in general,
least-privilege admin roles, onboarding reach, network access to Defender endpoints, a pilot ring, a
workspace where required, and response governance — is covered once in
**`global-requirements-defender.md`** (**G1–G8**). Read that first; the items below layer on top of
it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. MDO feature availability (Plan 1 vs Plan 2)

- **Description:** The MDO features in scope are present. **Threat Explorer, Attack Simulation
  Training, AIR, and the email advanced-hunting tables are Plan 2**; Real-time detections and the
  prevention stack are broader. *Verify current plan-to-feature mapping in your tenant.*
- **Why required:** The hunting, simulation, AIR, and email-hunting labs depend on **Plan 2**
  features. On Plan 1 those labs cannot run in full.
- **How to verify:** In `security.microsoft.com` confirm the **Explorer**, **Attack simulation
  training**, **Action center**, and **Advanced hunting** blades are present; run `WSMDO-Discovery.ps1`,
  which reports Plan 2 presence and email-table freshness.
- **How to implement if missing:** Assign MDO **Plan 2** (bundled in M365/Office 365 E5 or E5
  Security) and allow provisioning time. On Plan 1, run the Real-time detections + protection-stack
  labs and defer the Plan 2 labs. *Verify licensing.*

## R2. The prevention stack exists (to inspect)

- **Description:** Anti-phishing, anti-malware, anti-spam, **Safe Links**, and **Safe Attachments**
  policies exist (or a Preset security policy is enabled) — configured by the **Mail Hygiene** solution.
- **Why required:** The workshop **inspects** these policies to teach how verdicts and click data are
  produced. If none exist, there is nothing to read and Explorer/hunting have less signal.
- **How to verify:** **Email & collaboration → Policies & rules → Threat policies** lists the policies
  (or a Preset is enabled).
- **How to implement if missing:** Deploy the prevention stack first (the **Mail Hygiene** solution).
  This workshop does **not** configure it and only reads it.

## R3. A lab user group (for the simulation)

- **Description:** A small, **consented** group of pilot users — `Grp-MDO-LabUsers-Pilot` — to receive
  the benign simulation and be the hunting scope. Avoid executives for a first simulation unless
  leadership approves.
- **Why required:** Attack Simulation Training sends simulated phish to real users; practising on a
  dedicated, consented lab group is the safe way (category **G6**).
- **How to verify:** The group exists in Entra with the intended members and is selectable as a
  simulation target.
- **How to implement if missing:** Create `Grp-MDO-LabUsers-Pilot` in Entra and populate it with a
  representative, consented cohort.

## R4. A simulation & communications note (people/legal)

- **Description:** A short, **leadership-approved** note covering **who** is simulated, **when**, that
  results are used for **training not punishment**, and whether **HR / works councils / employee
  representatives** must be informed in your jurisdiction.
- **Why required:** Phishing simulation touches employees and, in some regions, employment/privacy
  law. How simulation data is used is a **people and compliance decision**, not a technical default.
- **How to verify:** A written, approved note exists and names an owner.
- **How to implement if missing:** Agree scope, cadence, and non-punitive use with security leadership
  and HR before the simulation lab. *Employee-simulation legality and works-council notification are
  the customer’s HR/legal determinations — the workshop provides the capability, not the decision.*

## R5. Roles: read/hunt for learners, config rights for the instructor

- **Description:** Learners hold a **read/hunt** role (**Security Reader** with hunting, or **Security
  Operator**). The instructor holds the rights to **launch a simulation**, **read AIR/Action center**,
  and **create a custom detection** (**Security Administrator** or the granular equivalent).
- **Why required:** Labs run at **least privilege** — reading and hunting. Only launching the
  simulation and authoring the detection need elevation, and only for the instructor.
- **How to verify:** Defender **Permissions & roles** (and Entra **Roles and administrators**) show
  the split.
- **How to implement if missing:** Assign read/hunt roles to the cohort (prefer **PIM-eligible** for
  elevated roles where Entra ID P2 is available — *verify licensing*); reserve simulation-launch and
  detection-authoring to the instructor.

## R6. A read-only / preview-first / approval-required posture

- **Description:** An agreed rule that all labs are **read-only or preview-first**: AIR stays
  **approval-required**, remediation is **previewed only** (never executed), Explorer take-action is
  understood **not** performed against production, and the capstone detection is **alert-only**.
- **Why required:** Learners operate against production mailboxes. The posture must be explicit so no
  one deletes real mail "to test."
- **How to verify:** The workshop plan states the posture; AIR is approval-required; the detection is
  alert-only; no remediation was executed.
- **How to implement if missing:** State it at kickoff; route any real finding to the SOC’s normal
  incident process (category **G8**). Remediation is **taught and gated**, not performed in class.

## R7. The PowerShell + hunting toolchain

- **Description:** A workstation with **Microsoft.Graph** (security modules) and, where the reporting
  labs use them, **Exchange Online Management** (`Connect-ExchangeOnline` / `Connect-IPPSSession`),
  signed in with an MFA-capable account holding at least read/hunt scopes; plus portal access to
  Threat Explorer, Attack Simulation, and Advanced hunting.
- **Why required:** The four delivered helpers check readiness, run a chosen lab query read-only,
  score the knowledge-check, and report cohort progress.
- **How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph`
  succeeds; Advanced hunting loads in the portal.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` (and
  `ExchangeOnlineManagement` if using the EXO reporting labs); sign in. For Government cloud, connect
  with the matching environment/endpoints — *verify the correct endpoints for your cloud*. Some Graph
  attack-simulation endpoints are **beta** — *verify current availability*.


---


# Global Requirements — Defender (category-level)

These requirements apply to every solution in the Defender category (Microsoft Defender XDR and Defender
for Cloud). Published once at the category level so listings stay small. Confirm before deploying any
Defender solution. Each entry: Description / Why / Verify / Implement-if-missing.

> Defender changes touch detection and response for the whole tenant. Onboard in a ring (pilot devices/
> users first), keep automated response in an approval/simulate posture until trusted, and never disable
> an existing control to "test."

## G1. Microsoft 365 / Entra tenant
Description: An active Microsoft 365 tenant with Entra ID.
Why: Defender XDR services and the unified portal (security.microsoft.com) are tenant workloads.
Verify: Sign in to `https://security.microsoft.com` as an administrator.
Implement: Provision a Microsoft 365 tenant and confirm Entra ID identities exist.

## G2. Defender licensing
Description: The Defender plans for the pillars in scope — e.g. Defender for Endpoint P1/P2, Defender for Identity, Defender for Office 365 P1/P2, Defender for Cloud Apps, and Defender for Cloud plans.
Why: Each pillar/feature is license-gated; onboarding without the plan fails or silently limits features.
Verify: Admin center -> `Billing -> Licenses` (or the Defender portal). *Confirm the exact plan each feature needs — verify current availability in your tenant.*
Implement: Assign the required plans (often bundled in M365 E5 / E5 Security) before onboarding.

## G3. Administrative roles (least privilege)
Description: Security Administrator (and Global Administrator for first-time service activation).
Why: Onboarding, RBAC, and policy changes in the Defender portal require these roles.
Verify: Entra -> `Roles and administrators`; confirm Security Administrator.
Implement: Assign Security Administrator; reserve Global Administrator for one-time activations.

## G4. Onboarding reach to endpoints / identity / workloads
Description: A management channel to onboard the pillars — Intune/Configuration Manager/GPO/script for endpoints, domain controllers/AD FS for Identity sensors, and cloud connectors for Defender for Cloud.
Why: Each pillar collects signal from a source that must be reachable and instrumented.
Verify: Endpoints are managed (Intune/CM); DCs are reachable; cloud subscriptions are connected. Run the solution's discovery script.
Implement: Establish the onboarding channel per pillar (see the relevant catalog endpoint/identity solutions).

## G5. Network access to Defender service endpoints
Description: Outbound HTTPS to the Microsoft Defender / Microsoft 365 service URLs from onboarded assets.
Why: Sensors and agents report to the cloud service; blocked endpoints break onboarding and detections.
Verify: Confirm the documented Defender endpoint URLs/IP ranges are allowed. *Verify current endpoint list.*
Implement: Allow the Defender/M365 endpoints through proxy/firewall.

## G6. A pilot ring
Description: A defined set of pilot devices/users/subscriptions to onboard first.
Why: XDR onboarding and automated response are validated on a ring before tenant-wide rollout.
Verify: A pilot group exists in Entra/Intune.
Implement: Create the pilot ring before enabling anything that acts automatically.

## G7. Log Analytics workspace (where required)
Description: A Log Analytics workspace for Defender for Cloud / advanced hunting export where used.
Why: Some Defender data and continuous export land in a workspace.
Verify: A workspace exists and is access-controlled. Run the discovery script.
Implement: Provision a workspace (or reuse the SIEM/observability one) with least-privilege access.

## G8. Response governance
Description: An agreed position on automated response (auto-remediation levels, approval requirements).
Why: XDR/AIR can take disruptive actions (isolate, delete, disable); the organization must decide the guardrails.
Verify: A documented response policy exists; automation is in an approval/simulate posture until trusted.
Implement: Define response guardrails; keep AIR/automation approval-gated at first. *Incident-response decisions are the SOC/security team's; this guide covers the technical configuration.*

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# Implementation — Workshop: Microsoft Defender for Office 365 (Guided Labs)

This is the exact, ordered workshop — a sequence of **guided hands-on labs**. Every object you create
is **named** with a consistent convention — `<Purpose> – <Scope> – <Stage>` — and the same name is
reused in later labs, the knowledge-check, and the scripts. Run the labs against **real telemetry,
read-only or preview-first**; the only changes to the tenant are a benign **simulation** to a
consented lab group and one **alert-only** capstone detection.

> **Before you start:** confirm MDO feature availability (**R1**), the prevention stack exists to
> inspect (**R2**), a consented lab user group (**R3**), a simulation/communications note (**R4**),
> split roles (**R5**), and the **read-only / preview-first / approval-required** posture (**R6**).
> This workshop **inspects** the protection policies and does **not** reconfigure them; it builds
> skill, it does not perform the operational rollout.

**Named objects created in this workshop (verbatim — reused everywhere):**

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-MDOWorkshop-Cohort` | Entra security group of workshop learners |
| Lab user group | `Grp-MDO-LabUsers-Pilot` | Consented users for the simulation + hunting scope |
| Explorer saved view | `Explorer-MDOLab-Pilot` | Saved Threat Explorer query for the labs |
| Shared saved-query set | `Hunt-MDOLab-Pilot` | The email lab queries saved to shared queries |
| Simulation (lab) | `Sim-MDOLab-Pilot` | The benign Attack Simulation campaign, lab group only |
| Training assignment | `Training-MDOLab-Pilot` | Targeted training auto-assigned to those compromised |
| Custom detection (capstone) | `Detect-MDOLab-Pilot` | Alert-only detection built from a tuned lab hunt |
| Knowledge-check | `Check-MDOLab-Pilot` | The scored end-of-workshop knowledge-check |

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

1. In **Entra** → **Groups → New group**: Security; **Name** `Grp-MDOWorkshop-Cohort`; add learners.
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
   solution — hand it the skills and artifacts the workshop produced.
3. **Widen simulation deliberately.** Broadening the simulation beyond the lab group and setting a
   cadence is a **people/security decision (R4)**, made with HR — not a default this workshop flips.
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
- **Groups / saved queries:** delete `Grp-MDOWorkshop-Cohort`, `Grp-MDO-LabUsers-Pilot`,
  `Explorer-MDOLab-Pilot`, and the `Hunt-MDOLab-Pilot` folder if the workshop was one-off; keep them if
  operationalizing.


---


# Testing & Validation — Workshop: Microsoft Defender for Office 365

Validate the workshop against explicit **pass/fail gates** — that the **environment** supports the
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
- **If it fails:** Set AIR back to approval-required (Step 1.2); the workshop must not auto-remediate
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
  workshop-executed deletions; confirm the simulation targeted only the lab group.
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


---


# Troubleshooting — Workshop: Microsoft Defender for Office 365

The common failure modes, each as **symptom → cause → fix**. Most workshop issues are licensing,
email-table freshness, or an approval-posture surprise — not a broken feature.

---

## 1. "Explorer" is missing — I only see "Real-time detections"

- **Symptom:** Under Email & collaboration there is **Real-time detections** but no **Explorer**.
- **Cause:** The tenant/user is on **MDO Plan 1**; Threat Explorer is a Plan 2 feature.
- **Fix:** Verify licensing (R1) — assign MDO **Plan 2** and allow provisioning time; confirm with
  `WSMDO-Discovery.ps1`. On Plan 1 run the Real-time-detections + protection-stack labs. *Verify
  plan-to-feature mapping.*

## 2. Attack Simulation Training blade is absent or greyed out

- **Symptom:** No **Attack simulation training** blade, or "not available".
- **Cause:** Missing Plan 2, still provisioning, or the account lacks the role.
- **Fix:** Confirm Plan 2 (R1); wait for provisioning; confirm the instructor holds the role (R5).
  *Feature availability can differ by cloud (GCC/GCC High) — verify.*

## 3. Email advanced-hunting tables return nothing (EmailEvents empty)

- **Symptom:** `EmailEvents | count` returns 0; hunts come back empty.
- **Cause:** Plan 2 not provisioned, no mail flowing yet, or table/column names differ in your cloud.
- **Fix:** Confirm Plan 2 and that mail is flowing; check freshness with `WSMDO-Discovery.ps1`. If a
  query errors on a column, **verify the schema for your tenant/cloud** — Microsoft renames hunting
  tables periodically.

## 4. A hunting query errors ("unknown table/column")

- **Symptom:** A Lab 5 query fails to resolve a table/column (e.g. `UrlClickInfo`, `IsClickedThrough`).
- **Cause:** Schema drift — the pack uses representative names that evolve.
- **Fix:** Open **Advanced hunting → schema** and correct the name to your tenant’s current schema.
  *Verify current schema.*

## 5. The protection-stack policies aren’t there to inspect (Lab 3)

- **Symptom:** **Threat policies** has no anti-phish / Safe Links / Safe Attachments to open.
- **Cause:** The prevention stack hasn’t been deployed.
- **Fix:** Deploy the **Mail Hygiene** solution first (R2); Lab 3 needs existing policies to read. This
  workshop inspects but does not create them.

## 6. AIR auto-deleted mail during the lab

- **Symptom:** Mail was removed without anyone approving it.
- **Cause:** AIR automation is set **higher than approval-required**.
- **Fix:** Set AIR back to **approval-required** (Step 1.2) so actions land in **Action center →
  Pending**. The workshop must not auto-remediate (R6). Raising automation is the implementation
  solution’s decision, not this workshop’s.

## 7. AIR actions never appear for approval

- **Symptom:** Nothing shows in **Action center → Pending** even after an alert.
- **Cause:** AIR not enabled, no qualifying alert fired, or the account can’t see the Action center.
- **Fix:** Confirm AIR is enabled; trigger it the safe way (have a lab user **Report** a benign
  message); confirm the account has rights to view the Action center (R5).

## 8. Simulated phish was blocked / never delivered to the lab users

- **Symptom:** Lab users didn’t receive `Sim-MDOLab-Pilot`; results are empty.
- **Cause:** The simulation URLs/domains aren’t allowed, or advanced delivery isn’t configured for the
  simulation source.
- **Fix:** Configure the **Advanced delivery** policy for simulation URLs so simulations bypass
  filtering as intended. *This is a prevention-layer setting — confirm with the Mail Hygiene solution;
  verify current steps.*

## 9. "Create detection rule" is greyed out, or the detection is noisy

- **Symptom:** You can’t create `Detect-MDOLab-Pilot`, or once created it floods with alerts.
- **Cause:** The account lacks the authoring role; or the underlying hunt wasn’t tuned before promotion.
- **Fix:** Have the **instructor** author it (R5); ensure the query projects the mapped entities. If
  noisy, disable it, tighten the Lab 5 query, and recreate it **alert-only**. Never promote a noisy
  hunt.

## 10. Attack-sim report is empty from PowerShell but present in the portal

- **Symptom:** `WSMDO-Report.ps1` shows no simulations, but the portal does.
- **Cause:** The Graph **attack-simulation endpoints are beta** and may be unavailable, permission-
  gated, or absent in your cloud.
- **Fix:** Use the portal report for authoritative per-user detail; grant `AttackSimulation.Read.All`
  where the beta API is available. *Verify current API availability for your cloud.* The script
  degrades gracefully by design.

## 11. Graph/EXO connection or permission errors

- **Symptom:** `Connect-MgGraph` / `Connect-ExchangeOnline` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph, ExchangeOnlineManagement`; connect with the correct
  `-Environment` for Government cloud; consent the read/hunt scopes in each script header; confirm the
  account holds a read/hunt role (R5). *Verify the correct endpoints for your cloud.*


---


# Best Practices — Workshop: Microsoft Defender for Office 365

Keep-it-clean guidance for turning an MDO workshop into a durable email-security skill that stays
sharp over time.

## Hunt on a question, not a hunch

- **Start every hunt from an answerable question** — "who else received this?", "who clicked after
  delivery?", "is it still in inboxes?" — and pivot in Explorer on the entity (sender, URL, hash,
  click verdict). Save the good hunts (`Explorer-MDOLab-Pilot`, `Hunt-MDOLab-Pilot`) so the team
  reuses them.
- **Prefer post-delivery signal.** The prevention stack already blocked the obvious; the value is in
  what got through and what changed after delivery (weaponized-after-delivery URLs, late clicks).
- **Re-hunt after every incident.** A new indicator (sender, domain, hash) is a new query — run it
  across the whole tenant, not just the reporting user.

## Understand the protection stack — then let the right solution change it

- **Read before you reason.** Knowing how anti-phish, Safe Links, and Safe Attachments decide lets you
  explain a verdict instead of guessing. Inspect the policies; don’t treat them as a black box.
- **Change is a different job.** Tightening the prevention policies is the **Mail Hygiene** solution;
  operationalizing post-delivery detection/response is the **Defender for Office 365 (Plan 2)**
  implementation solution. The workshop builds the skill that makes both changes safer.

## Simulate to measure, train to fix — never to punish

- **Simulation is a measurement tool.** Its job is honest susceptibility data and targeted training —
  not to embarrass anyone. Make the non-punitive intent explicit (R4); a punitive program destroys
  reporting culture.
- **Start easy, escalate slowly.** Begin with credential-harvest to the lab group (`Sim-MDOLab-Pilot`),
  then broaden technique and audience over time — a **people/security decision** made with HR.
- **Respect people and the law.** Whether, when, and how you simulate employees — and who must be
  informed — are **HR/legal decisions**. Agree them before you launch.

## Automate response only after you trust it

- **Approval-required first.** Keep AIR **approval-required** and route remediation through the **Action
  center** until it is trusted. A human approves every deletion at first.
- **Soft before hard.** Prefer **soft-delete** (recoverable) over **hard-delete** (irreversible); make
  hard-delete a **named-approver-only** action. None of this is executed in the workshop — it is
  taught and gated.
- **Raise automation deliberately.** Lifting AIR automation is a **documented operations decision**,
  owned by the implementation solution — not a default this workshop flips.

## Turn hunts into durable coverage — carefully

- **Alert-only first.** Promote a hunt to a custom detection (`Detect-MDOLab-Pilot`) only once it is
  quiet and accurate, and keep it alert-only until proven.
- **Version your queries.** Keep the email KQL library in source control so hunts are reviewable and
  portable — the same discipline the Sentinel detection-as-code solution applies.

## Run it as a program, not a one-off class

- **Loop, don’t launch-and-forget.** Hunt → simulate → train → investigate → (gated) remediate →
  report, on a cadence. Post-delivery threats and user behavior both drift.
- **Feed the hunt library and the implementation.** Hand tuned hunts to the **Threat Hunting
  hunt-library** program and the operational rollout to the **Defender for Office 365 (Plan 2)**
  solution.
- **Re-run for new hires.** The take-home runbook and knowledge-check make onboarding a new analyst
  repeatable.

## Where to go next

With the team able to hunt, simulate, and respond on email, the natural next steps in this catalog
are:

- **Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & AIR** — operationalize the
  post-delivery features across the org (the rollout this workshop’s skills feed).
- **Microsoft 365 Mail Hygiene: Anti-Spam, EOP & Defender for Office 365** — tighten the prevention
  policies you learned to read, reducing what you have to hunt.
- **Advanced KQL for SecOps workshop** — deepen the query language this workshop applies to the email
  tables, and extend hunting across Defender XDR and Sentinel.
- **Microsoft Defender XDR onboarding** — bring endpoint, identity, and cloud-app signal into the same
  incident so email threats correlate with the whole kill chain.


---


# Deliverables Summary — Workshop: Microsoft Defender for Office 365

Everything included in this workshop, and what each piece is for.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "email-security bought and under-driven" problem, the enablement solution (concepts + labs + runbook + knowledge-check), and the boundary (skills product; read-only/preview-first; inspects but does not reconfigure the prevention stack; cross-references the Plan 2 implementation and Mail Hygiene solutions). |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how MDO works (prevention vs post-delivery, Threat Explorer, the protection stack, Attack Simulation Training, AIR, email advanced hunting), the Assess→Configure→Pilot→Validate→Expand model, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (Plan 1-vs-2 feature availability, the prevention stack to inspect, a consented lab user group, a simulation/communications note, split read/hunt vs instructor roles, a read-only/preview/approval posture, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | The guided labs: assess readiness, create the cohort + lab user group, load the KQL lab pack, run Labs 1–8 (console/email-security model → Threat Explorer → inspect the protection stack → benign simulation → email hunting → AIR held for approval → alert-only detection → reporting/user-risk), then capstone + knowledge-check, then hand off to the implementation solution — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Nine pass/fail gates covering environment readiness (Plan 2 features, protection stack, email tables) and skills landed (simulation reported, email hunting returns, AIR pending-not-auto-applied, alert-only detection, knowledge-check), referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (Explorer missing, sim blade absent, empty email tables, schema drift, AIR auto-deleting, no pending actions, sim not delivered, detection not alert-only, beta API empty, connection errors) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Hunt-on-a-question, understand-the-stack-then-let-the-right-solution-change-it, simulate-to-measure-not-punish, automate-only-when-trusted, turn-hunts-into-durable-coverage, run-it-as-a-program — plus where to go next in the catalog. |

## Lab pack + PowerShell helpers (5)

All helpers are **read-only or preview-first**, authenticate **interactively** (no credentials in
code), and use **Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`; attack-sim
**beta** reporting where available) and, where used, **Exchange Online / Security & Compliance**.
Government-cloud tenants pass the matching environment — *verify endpoints for your cloud*.

| File | Type | What it does |
| --- | --- | --- |
| **`WSMDO-Labs.kql`** | KQL lab pack | The runnable, progressive email query library — one labeled section per hunting lab (post-delivery clicks, sender/subject campaign, bad-attachment hash, delivered-then-detected) plus the capstone candidate. The core take-home artifact. |
| **`WSMDO-Discovery.ps1`** | Read-only | Inventories readiness: Plan 2 presence, email-table freshness (`EmailEvents` etc.), lab-group membership, and the Action center pending posture. Changes nothing. |
| **`WSMDO-RunLab.ps1`** | Read-only | Runs a chosen email hunting-lab query (`-Lab <n>`) from the pack via Graph and returns the rows — so learners can execute a lab from PowerShell as well as the portal. |
| **`WSMDO-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines and scores the knowledge-check `Check-MDOLab-Pilot`: readiness, email tables have data, hunting resolves, AIR pending, detection alert-only. |
| **`WSMDO-Report.ps1`** | Read-only | Reports cohort progress, per-lab email-data availability, and (where the API allows) the attack-simulation user-risk picture; exports to CSV as workshop evidence. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-MDOWorkshop-Cohort`
- **Lab user group:** `Grp-MDO-LabUsers-Pilot`
- **Explorer saved view:** `Explorer-MDOLab-Pilot`
- **Shared saved-query set:** `Hunt-MDOLab-Pilot`
- **Simulation (lab):** `Sim-MDOLab-Pilot`
- **Training assignment:** `Training-MDOLab-Pilot`
- **Custom detection (capstone):** `Detect-MDOLab-Pilot` (alert-only)
- **Knowledge-check:** `Check-MDOLab-Pilot`

## What this workshop deliberately does NOT do

- It does **not** configure the prevention stack — anti-spam/-malware/-phishing, Safe Links, Safe
  Attachments, and mail-flow hygiene are the **Mail Hygiene** solution. This workshop **inspects** them.
- It does **not** perform the operational post-delivery rollout — turning the features on org-wide,
  tuning AIR automation, and running gated production remediation is the **Defender for Office 365
  (Plan 2)** implementation solution. This workshop builds the **skill**.
- It does **not** execute production remediation — AIR stays **approval-required**, remediation is
  **previewed only**, Explorer take-action is **not** performed against production, and the capstone
  detection is **alert-only**.
- It does **not** decide **who to simulate, acceptable click-rate, or the AIR automation level** —
  those are security-leadership / HR-legal determinations; the workshop provides the skill, the labs,
  and the data.
- It does **not** invent plan, feature, or schema facts — where availability may differ by plan
  (P1/P2) or cloud (GCC/GCC High) it says **verify in your tenant**.

## How it is delivered

This workshop is delivered as a **Complete Solution Package (PDF + Word + scripts)** — the
documentation as a formatted Word document and PDF, plus the email KQL lab pack and all four
PowerShell helpers, in a single ZIP (`WSMDO-Complete-Solution.zip`) — yours to keep and re-run for
every new cohort.
