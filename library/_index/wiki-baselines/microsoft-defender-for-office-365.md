# Microsoft Defender for Office 365

> **Version 1.0.0** · Category: Defender · Solution code: MDOFULL

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Microsoft Defender for Office 365

## What this is

The complete **Microsoft Defender for Office 365 (MDO)** solution for the phase most teams never
reach: **operating** the product for detection and response, **enabling** the people who run it, and
**proving** — in your own tenant, on real-but-safe signal — that it works. Blocking spam is table
stakes; the value of MDO is post-delivery **hunting, investigation, and response**, and a team that
can drive it. This package takes MDO end to end across two joined tracks:

- **Enable the team** — a set of **guided hands-on labs** that upskill admins and SOC analysts on the
  whole MDO surface: **Threat Explorer** hunting, reading the **anti-phish / Safe Links / Safe
  Attachments** protection stack, running **Attack Simulation Training**, working **Automated
  Investigation & Response (AIR)** in an approval posture, and **email advanced hunting** with KQL.
- **Prove value** — a **scoped, safe, reversible proof of concept** that generates benign, simulated
  test signal (Attack Simulation Training, the **GTUBE** spam-test string, the **EICAR** test file, a
  benign **Safe Links** test URL — never real phishing or malware), demonstrates the headline
  detections on that signal, captures the evidence, and cleanly cleans up.

## The outcome

A team that can **hunt, simulate, investigate, and respond** on email with MDO, and a documented,
in-tenant **proof** that the product catches phishing and malicious mail on your own mail flow — the
evidence a stakeholder needs to commit, and the skills to keep operating it afterward.

## The boundary — this is the operate/enable/prove layer

This solution deliberately **does not re-do configuration or onboarding**. It sits **on top of** two
adjacent catalog solutions and **cross-references** them rather than repeating them:

- **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for Office 365** — *configures the
  prevention policies* (anti-spam/-malware/-phishing, Safe Links, Safe Attachments, connection
  filtering, mail-flow hygiene). This solution **inspects** those policies read-only to teach how
  verdicts are produced; it does **not** reconfigure them.
- **Defender for Office 365 (Plan 2) — Threat Explorer, Attack Simulation & AIR** — *turns the
  post-delivery features on and operationalises them across the org*. This solution builds the
  **skill and the proof**; that solution owns the **production rollout and tuning**.

All labs and the PoC are **read-only or preview-first**: AIR stays **approval-required**, remediation
is **previewed only**, Threat Explorer take-action is understood but not executed against production,
the capstone detection is **alert-only**, and every PoC change is **`-WhatIf`-gated** and reversible.
This solution provides the **technical skill, the labs, and the proof** — not the **decisions**: which
users to simulate, acceptable click-rate, the AIR automation level, what counts as a "pass," and every
production remediation are the customer's **security-operations / HR-legal** calls.

## Effort

A competent administrator can run the enablement labs with a small learner cohort and complete the
scoped PoC — signal, demonstrate, validate, capture evidence, and clean up — in a short, focused
engagement on a handful of pilot mailboxes. No organisation-wide mail-flow change is required, and
every step is reversible.

**Licensing note:** Threat Explorer, Attack Simulation Training, AIR, and the email advanced-hunting
tables require **Defender for Office 365 Plan 2** — *verify current availability and licensing in your
tenant; feature availability can differ by cloud (Commercial vs GCC / GCC High).*


---


# Solution Overview — Microsoft Defender for Office 365

## What this is

A complete, self-guided solution for **operating, enabling, and proving** **Microsoft Defender for
Office 365 (MDO)**. It joins two tracks into one lifecycle:

- **Track A — Enable the team:** guided hands-on labs across the whole MDO surface — **Threat
  Explorer**, the **anti-phish / Safe Links / Safe Attachments** protection stack, **Attack Simulation
  Training**, **Automated Investigation & Response (AIR)**, and **email advanced hunting** — with a
  runnable email KQL pack and a knowledge-check.
- **Track B — Prove value:** a scoped, safe, reversible **proof of concept (PoC)** that fires benign
  test signal at a pilot group, demonstrates the headline detections, and captures the evidence.

It is the **operate/enable/prove layer** over two adjacent solutions. It **cross-references** — and
does not repeat — the **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for Office 365**
solution (which *configures* the prevention policies) and the **Defender for Office 365 (Plan 2) —
Threat Explorer, Attack Simulation & AIR** solution (which *turns the post-delivery features on and
operationalises them org-wide*). This solution **inspects** the prevention policies read-only, builds
the **skill** to drive the post-delivery half, and **proves** the product on real-but-safe signal.

## How the technology works (the mental model)

- **Two halves: prevention and post-delivery.** MDO both **blocks** mail (anti-spam, anti-malware,
  anti-phishing, Safe Links, Safe Attachments) and lets you **hunt and respond** to what gets through
  (Threat Explorer, AIR, email hunting). This solution operates and proves both halves; it
  **configures** neither.
- **Threat Explorer / Real-time detections.** The interactive hunting surface for email — pivot on
  **sender, recipient, subject, URL, file hash, delivery location, click verdict** and **take action**
  on results. Answers "who else got this, who clicked, is it still in inboxes?" **Real-time
  detections** is the Plan 1 view; **Threat Explorer** (Plan 2) adds depth and retention. *Verify plan
  mapping for your tenant.*
- **The protection stack (inspect, don't reconfigure).** **Anti-phishing** (impersonation & spoof
  intelligence), **Safe Links** (time-of-click URL rewriting/detonation), and **Safe Attachments**
  (sandbox detonation) produce the verdicts and click data Explorer and hunting surface. Here you
  **read** these policies to understand *why* a message was caught; changing them is the **Mail
  Hygiene** solution.
- **Attack Simulation Training.** A Plan 2 feature that sends **benign, controlled** simulated phishing
  to chosen users, measures who is **compromised**, and **auto-assigns targeted training**. Safe by
  design — no real payload. It is also the sanctioned way to generate benign phishing signal for the
  PoC.
- **Automated Investigation & Response (AIR).** When certain email alerts fire, AIR **opens an
  investigation**, correlates evidence, and **recommends** remediation. In an **approval-required**
  posture those actions wait in the **Action center** for a human — nothing auto-deletes.
- **Email advanced hunting.** KQL over the email tables — `EmailEvents`, `EmailAttachmentInfo`,
  `EmailUrlInfo`, `EmailPostDeliveryEvents`, `UrlClickInfo` — for proactive hunting and custom
  detections. Email tables are Plan 2 — *verify availability in your tenant.*
- **Benign PoC signal.** The **GTUBE** anti-spam test string, the **EICAR** anti-malware test file, and
  a benign **Safe Links** test URL are industry-standard, harmless triggers that exercise the
  detection pipeline without any real threat. Combined with an Attack Simulation campaign, they let you
  *watch MDO catch the simulation* instead of trusting a slide deck.

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the enable-and-prove
lifecycle:

1. **Assess.** Confirm the MDO features are available and the email tables have data
   (`MDOFULL-Discovery.ps1`); confirm the prevention baseline exists to inspect (from the **Mail
   Hygiene** solution); create the learner cohort and the consented pilot group.
2. **Configure.** Load the KQL lab pack `MDOFULL-Labs.kql`; confirm **AIR is approval-required**; agree
   the **read-only / preview-first / `-WhatIf`** posture. (Production policy configuration itself is the
   cross-referenced solutions' job — not this one.)
3. **Pilot.** Run **Track A** (guided Labs 1–8) with the cohort, and **Track B** (the guided PoC:
   benign signal → demonstrate Safe Links / Safe Attachments / ZAP / Threat Explorer) against the
   pilot group.
4. **Validate.** Run the **capstone** hunt, score the **knowledge-check**, and run the PoC capability
   validation and **evidence capture** (`MDOFULL-Validate.ps1`, `MDOFULL-Report.ps1`); confirm AIR
   actions are **pending (not auto-applied)** and the detection `Detect-MDOFULL-Pilot` is
   **alert-only**.
5. **Expand.** Fold the skills, saved hunts, and evidence into the **live email-security practice** —
   handing the operational rollout to the **Defender for Office 365 (Plan 2)** solution and any
   prevention tightening to the **Mail Hygiene** solution — and **tear down** the benign PoC signal.

## Scope — what this solution covers

- **Threat Explorer** — post-delivery email hunting and pivoting (take-action understood, not executed
  against production).
- **The protection stack (read-only)** — inspecting anti-phish / Safe Links / Safe Attachments to
  understand verdicts.
- **Attack Simulation Training** — a benign campaign on the pilot group; susceptibility measurement and
  auto-assigned training.
- **AIR** — triggering an investigation the safe way and confirming actions are **held for approval**.
- **Email advanced hunting** — a KQL lab pack over the email tables, ending in an **alert-only** custom
  detection.
- **A scoped, safe PoC** — benign signal (Attack Simulation / GTUBE / EICAR / Safe Links), a demo of
  the headline detections, capability validation, an **evidence scorecard**, and clean teardown.
- **Reporting / user-risk** and a **take-home runbook + knowledge-check**.

## Out of scope (handled by the cross-referenced solutions)

- **Configuring the prevention policies.** Anti-spam/-malware/-phishing, Safe Links, Safe Attachments,
  connection filtering, and mail-flow hygiene are the **Microsoft 365 Mail Hygiene & Anti-Spam — EOP /
  Defender for Office 365** solution. This solution **inspects** them read-only.
- **The operational post-delivery rollout.** Turning these features on across the org, tuning AIR
  automation, and running gated production remediation is the **Defender for Office 365 (Plan 2) —
  Threat Explorer, Attack Simulation & AIR** solution. This solution builds the **skill** and the
  **proof**; that solution does the **rollout**.
- **Executing production remediation.** Soft/hard-delete and ZAP-style purge against real mail are
  approval-gated incident actions — not labs, and not part of the PoC.
- **The security / HR-legal decisions.** Which users to simulate, acceptable click-rate, the AIR
  automation level, works-council notification, what counts as a PoC "pass," and every production
  remediation are **the customer's determinations**; this solution provides the skill, the labs, the
  data, and the proof.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.com`) for Threat Explorer, Attack Simulation
  Training, Action center, AIR settings, Advanced hunting, custom detection rules, and quarantine.
- **PowerShell** with **Microsoft.Graph** (security — advanced hunting via `security/runHuntingQuery`;
  `Mail.Send` for the benign PoC test messages; attack-simulation reporting where available — *some
  endpoints are beta; verify*) and, where used, **Exchange Online / Security & Compliance** for MDO
  reporting and quarantine cmdlets — used only to **check readiness, run lab queries read-only**,
  generate benign signal, validate detections, and capture evidence.
- All helpers authenticate **interactively** with an MFA-capable account holding at least read/hunt
  scopes; **no credentials are stored in code**. Government-cloud tenants pass the matching endpoints
  — *verify endpoints for your cloud.*


---


# Requirements — Microsoft Defender for Office 365

These are the **solution-specific** prerequisites for **operating, enabling, and proving** MDO. The
**category baseline** — an active Microsoft 365 / Entra tenant, Defender licensing in general,
least-privilege admin roles, onboarding reach, network access to Defender endpoints, a pilot ring, a
workspace where required, and response governance — is covered once in
**`global-requirements-defender.md`** (**G1–G8**). Read that first; the items below layer on top of it
and are not repeated here.

This solution also assumes the **configuration baseline is already in place** via the two adjacent
solutions it cross-references — **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for Office
365** (the prevention policies) and, where the post-delivery features are already being rolled out,
**Defender for Office 365 (Plan 2) — Threat Explorer, Attack Simulation & AIR**. This solution does
not configure those; it operates on top of them.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing.**

---

## R1. MDO feature availability (Plan 1 vs Plan 2)

- **Description:** The MDO features in scope are present. **Threat Explorer, Attack Simulation
  Training, AIR, and the email advanced-hunting tables are Plan 2**; Real-time detections and the
  prevention stack are broader. *Verify current plan-to-feature mapping in your tenant.*
- **Why required:** The hunting, simulation, AIR, email-hunting labs, and the PoC's Explorer/simulation
  demos depend on **Plan 2** features. On Plan 1 those cannot run in full.
- **How to verify:** In `security.microsoft.com` confirm the **Explorer**, **Attack simulation
  training**, **Action center**, and **Advanced hunting** blades are present; run
  `MDOFULL-Discovery.ps1`, which reports Plan 2 presence and email-table freshness.
- **How to implement if missing:** Assign MDO **Plan 2** (bundled in M365/Office 365 E5 or E5
  Security) and allow provisioning time. On Plan 1, run the Real-time-detections + protection-stack
  labs and the GTUBE/EICAR/Safe Links PoC path, and defer the Plan 2 labs/demos. *Verify licensing.*

## R2. The prevention stack exists (to inspect and prove against)

- **Description:** Anti-phishing, anti-malware, anti-spam, **Safe Links**, and **Safe Attachments**
  policies exist (or a Preset security policy is enabled) and apply to the pilot users — configured by
  the **Mail Hygiene** solution.
- **Why required:** The labs **inspect** these policies to teach how verdicts and click data are
  produced, and the PoC needs them **applied to the pilot users** so the benign signal is actioned. If
  none exist, there is nothing to read and no detections to prove.
- **How to verify:** **Email & collaboration → Policies & rules → Threat policies** lists the policies
  (or a Preset is enabled), and the pilot group is in scope.
- **How to implement if missing:** Deploy/scope the prevention stack first (the **Mail Hygiene**
  solution). This solution does **not** configure it and only reads it.

## R3. A consented pilot group (labs + simulation + PoC)

- **Description:** A small, **consented** group of pilot users — `Grp-MDOFULL-PilotUsers-Pilot` — that
  serves as the hunting scope, the simulation target, and the recipients of the benign PoC signal.
  Prefer test/volunteer mailboxes who expect the simulation; avoid executives for a first simulation
  unless leadership approves.
- **Why required:** Attack Simulation Training and the benign PoC signal go to real users; using one
  dedicated, consented pilot group keeps the wider org untouched and teardown clean (category **G6**).
- **How to verify:** A mail-enabled security group `Grp-MDOFULL-PilotUsers-Pilot` exists in Entra with
  the intended members and is selectable as a simulation target; `MDOFULL-Discovery.ps1` lists its
  membership.
- **How to implement if missing:** Create `Grp-MDOFULL-PilotUsers-Pilot` and populate it with a
  representative, consented cohort. *Coordinate with the users so the benign simulation is expected.*

## R4. A simulation & communications note (people/legal)

- **Description:** A short, **leadership-approved** note covering **who** is simulated, **when**, that
  results are used for **training not punishment**, and whether **HR / works councils / employee
  representatives** must be informed in your jurisdiction.
- **Why required:** Phishing simulation and the PoC's benign signal touch employees and, in some
  regions, employment/privacy law. How simulation data is used is a **people and compliance decision**,
  not a technical default.
- **How to verify:** A written, approved note exists and names an owner.
- **How to implement if missing:** Agree scope, cadence, and non-punitive use with security leadership
  and HR before the simulation lab / PoC. *Employee-simulation legality and works-council notification
  are the customer's HR/legal determinations — this solution provides the capability, not the
  decision.*

## R5. Roles: read/hunt for learners, elevated for the instructor/operator

- **Description:** Learners hold a **read/hunt** role (**Security Reader** with hunting, or **Security
  Operator**). The instructor/operator holds the rights to **launch a simulation** (**Attack Simulation
  Administrator**), **read AIR/Action center**, **create a custom detection**, and **review/purge
  quarantine** for the PoC teardown (**Security Administrator** / **Quarantine Administrator** or the
  granular equivalents).
- **Why required:** Labs and PoC validation run at **least privilege** — reading and hunting. Only
  launching the simulation, authoring the detection, sending benign signal, and purging test
  quarantine need elevation, and only for the instructor/operator.
- **How to verify:** Defender **Permissions & roles** (and Entra **Roles and administrators**) show the
  split.
- **How to implement if missing:** Assign read/hunt roles to the cohort (prefer **PIM-eligible** for
  elevated roles where Entra ID P2 is available — *verify licensing*); reserve simulation-launch,
  detection-authoring, benign-signal sending, and quarantine purge to the instructor/operator.

## R6. A read-only / preview-first / approval-required / -WhatIf posture

- **Description:** An agreed rule that all labs are **read-only or preview-first** and all PoC changes
  are **`-WhatIf`-gated**: AIR stays **approval-required**, remediation is **previewed only** (never
  executed), Threat Explorer take-action is understood **not** performed against production, the
  capstone detection is **alert-only**, and the PoC generates only **benign** signal and is fully
  reversible.
- **Why required:** Learners and the PoC operate against production mailboxes. The posture must be
  explicit so no one deletes real mail "to test," sends anything but benign signal, or leaves residue.
- **How to verify:** The plan states the posture; AIR is approval-required; the detection is alert-only;
  no remediation was executed; PoC signal is benign only; teardown confirms no residue.
- **How to implement if missing:** State it at kickoff; route any real finding to the SOC's normal
  incident process (category **G8**). Remediation is **taught and gated**, not performed here.

## R7. Evaluation criteria for the PoC (agreed up front)

- **Description:** A short, written list of what a PoC **"pass"** means — e.g. *Safe Links rewrote the
  test URL, Safe Attachments actioned EICAR, the spam string was handled, the simulation was captured
  in Threat Explorer.*
- **Why required:** A PoC is only conclusive if the bar is set **before** you run it; the evidence
  capture maps observations to these criteria.
- **How to verify:** A criteria list exists; `MDOFULL-Report.ps1` accepts it as input.
- **How to implement if missing:** Draft 5–8 criteria with the evaluating stakeholders before running
  the PoC track. *What counts as "good enough" is the customer's decision.*

## R8. The PowerShell + hunting toolchain

- **Description:** A workstation with **Microsoft.Graph** (security modules) and, where the reporting
  and quarantine steps use them, **Exchange Online Management** (`Connect-ExchangeOnline` /
  `Connect-IPPSSession`), signed in with an MFA-capable account holding at least read/hunt scopes (and
  `Mail.Send` for the benign PoC test messages); plus portal access to Threat Explorer, Attack
  Simulation, Advanced hunting, and quarantine.
- **Why required:** The delivered helpers check readiness, run lab queries read-only, generate benign
  signal, validate detections, and capture evidence.
- **How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph`
  succeeds; Advanced hunting loads in the portal.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` (and
  `ExchangeOnlineManagement` if using the EXO reporting/quarantine steps); sign in. For Government
  cloud, connect with the matching environment/endpoints — *verify the correct endpoints for your
  cloud.* Some Graph attack-simulation endpoints are **beta** — *verify current availability.*


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


---


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


---


# Troubleshooting — Microsoft Defender for Office 365

The common failure modes, each as **symptom → cause → fix**. Most issues are licensing, email-table
freshness, an approval-posture surprise, or a benign-signal timing/scope question — not a broken
feature. Run `MDOFULL-Discovery.ps1` and `MDOFULL-Validate.ps1` first — most causes surface there. All
PoC signal is benign (Attack Simulation / GTUBE / EICAR / benign test URL).

---

## 1. "Explorer" is missing — I only see "Real-time detections"

- **Symptom:** Under Email & collaboration there is **Real-time detections** but no **Explorer**.
- **Cause:** The tenant/user is on **MDO Plan 1**; Threat Explorer is a Plan 2 feature.
- **Fix:** Verify licensing (R1) — assign MDO **Plan 2** and allow provisioning time; confirm with
  `MDOFULL-Discovery.ps1`. On Plan 1 run the Real-time-detections + protection-stack labs and the
  GTUBE/EICAR/Safe Links PoC path. *Verify plan-to-feature mapping.*

## 2. Attack Simulation Training blade is absent or greyed out

- **Symptom:** No **Attack simulation training** blade, or "not available".
- **Cause:** Missing Plan 2, still provisioning, or the account lacks the **Attack Simulation
  Administrator** role.
- **Fix:** Confirm Plan 2 (R1); wait for provisioning; confirm the instructor holds the role (R5). If
  P2 is unavailable, run the GTUBE/EICAR/Safe Links signal only and record the simulation demo as "not
  licensed," not "failed." *Feature availability can differ by cloud (GCC/GCC High) — verify.*

## 3. Email advanced-hunting tables return nothing (EmailEvents empty)

- **Symptom:** `EmailEvents | count` returns 0; hunts and PoC validation come back empty.
- **Cause:** Plan 2 not provisioned, no mail flowing yet, or table/column names differ in your cloud.
- **Fix:** Confirm Plan 2 and that mail is flowing; check freshness with `MDOFULL-Discovery.ps1`. If a
  query errors on a column, **verify the schema for your tenant/cloud** — Microsoft renames hunting
  tables periodically.

## 4. A hunting query errors ("unknown table/column")

- **Symptom:** A Lab 5 or validation query fails to resolve a table/column (e.g. `UrlClickInfo` vs
  `UrlClickEvents`, `IsClickedThrough`).
- **Cause:** Schema drift — the pack uses representative names that evolve and can differ by plan/cloud.
- **Fix:** Open **Advanced hunting → schema** and correct the name to your tenant's current schema.
  *Verify current schema.*

## 5. The protection-stack policies aren't there to inspect (Lab 3), or don't cover the pilot users

- **Symptom:** **Threat policies** has no anti-phish / Safe Links / Safe Attachments to open, or the
  PoC signal isn't actioned for the pilot users.
- **Cause:** The prevention stack hasn't been deployed, or it isn't scoped to
  `Grp-MDOFULL-PilotUsers-Pilot`.
- **Fix:** Deploy/scope the **Mail Hygiene** solution first (R2); Lab 3 needs existing policies to read
  and the PoC needs them applied to the pilot users. This solution inspects but does not create or scope
  them.

## 6. AIR auto-deleted mail during a lab or the PoC

- **Symptom:** Mail was removed without anyone approving it.
- **Cause:** AIR automation is set **higher than approval-required**.
- **Fix:** Set AIR back to **approval-required** (Step 1.2) so actions land in **Action center →
  Pending**. This solution must not auto-remediate (R6). Raising automation is the **Defender for Office
  365 (Plan 2)** solution's decision, not this one's.

## 7. AIR actions never appear for approval

- **Symptom:** Nothing shows in **Action center → Pending** even after an alert.
- **Cause:** AIR not enabled, no qualifying alert fired, or the account can't see the Action center.
- **Fix:** Confirm AIR is enabled; trigger it the safe way (have a pilot user **Report** a benign
  message); confirm the account has rights to view the Action center (R5).

## 8. Benign test message not delivered (GTUBE / EICAR / Safe Links)

- **Symptom:** A GTUBE / EICAR / Safe Links test message never arrives at the pilot mailbox.
- **Cause:** The message was **caught before delivery** (expected for EICAR/GTUBE — check quarantine),
  the sending account is not permitted, or mail flow is misrouted.
- **Fix:** Check **Review → Quarantine** — EICAR/GTUBE messages are *meant* to be caught; that is a
  **pass**, not a delivery failure. Confirm the `-From` sender is permitted (has `Mail.Send`) and
  Exchange Online mail flow. Re-run `MDOFULL-TestSignal.ps1`.

## 9. Safe Links not rewriting / Safe Attachments not detonating

- **Symptom:** The benign test URL isn't rewritten, or the EICAR attachment is delivered without action.
- **Cause:** The prevention preset isn't applied to the pilot users, Safe Links/Safe Attachments is off
  in the applied policy, the MDO plan isn't licensed, or the message bypassed policy (internal-sender
  exceptions).
- **Fix:** Confirm the prevention policy covers the pilot users and Safe Links/Safe Attachments is on
  (Gate 2 — deploy via **Mail Hygiene** if missing); send from an **external** test sender; allow a
  moment for time-of-click / detonation and re-check `UrlClickInfo` / `EmailAttachmentInfo` with
  `MDOFULL-Validate.ps1`. *Verify current plan features.*

## 10. Simulated phish was blocked / never delivered to the pilot users

- **Symptom:** Pilot users didn't receive `Sim-MDOFULL-Pilot`; results are empty.
- **Cause:** The simulation URLs/domains aren't allowed, or advanced delivery isn't configured for the
  simulation source.
- **Fix:** Configure the **Advanced delivery** policy for simulation URLs so simulations bypass
  filtering as intended. *This is a prevention-layer setting — confirm with the Mail Hygiene solution;
  verify current steps.*

## 11. "Create detection rule" is greyed out, or the detection is noisy

- **Symptom:** You can't create `Detect-MDOFULL-Pilot`, or once created it floods with alerts.
- **Cause:** The account lacks the authoring role; or the underlying hunt wasn't tuned before promotion.
- **Fix:** Have the **instructor** author it (R5); ensure the query projects the mapped entities
  (RecipientEmailAddress, Url). If noisy, disable it, tighten the Lab 5 query, and recreate it
  **alert-only**. Never promote a noisy hunt.

## 12. No Explorer / simulation visibility during the PoC demo

- **Symptom:** Threat Explorer or the simulation shows nothing during the live demo.
- **Cause:** Threat Explorer / Attack Simulation Training require **P2**, or the signal hasn't populated
  yet (detonation/ZAP act after delivery).
- **Fix:** Confirm **P2** licensing (*verify current availability*); allow warm-up time for
  `EmailEvents`; re-run `MDOFULL-Validate.ps1`. If P2 is unavailable, record the Explorer/simulation
  demos as "not licensed," not "failed."

## 13. Attack-sim report is empty from PowerShell but present in the portal

- **Symptom:** `MDOFULL-Report.ps1` shows no simulations, but the portal does.
- **Cause:** The Graph **attack-simulation endpoints are beta** and may be unavailable, permission-
  gated, or absent in your cloud.
- **Fix:** Use the portal report for authoritative per-user detail; grant `AttackSimulation.Read.All`
  where the beta API is available. *Verify current API availability for your cloud.* The script degrades
  gracefully by design.

## 14. Graph/EXO connection or permission errors

- **Symptom:** `Connect-MgGraph` / `Connect-ExchangeOnline` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph, ExchangeOnlineManagement`; connect with the correct
  `-Environment` for Government cloud; consent the read/hunt (and `Mail.Send` for signal) scopes in each
  script header; confirm the account holds the right role (R5). *Verify the correct endpoints for your
  cloud.*

## 15. Teardown left residue

- **Symptom:** After `MDOFULL-TestSignal.ps1 -Teardown`, benign test messages or the simulation remain.
- **Cause:** Teardown ran in `-WhatIf` only, the quarantine purge needs the quarantine role, or the
  simulation must be ended in the portal.
- **Fix:** Run teardown **without** `-WhatIf`; confirm the **Quarantine / Security Administrator** role;
  end the campaign `Sim-MDOFULL-Pilot` in Attack Simulation Training; re-confirm with
  `MDOFULL-Validate.ps1`.


---


# Best Practices — Microsoft Defender for Office 365

Keep-it-clean guidance for operating MDO for detection and response, enabling the team, and running a
clean, conclusive proof — so the capability stays sharp over time.

## Hunt on a question, not a hunch

- **Start every hunt from an answerable question** — "who else received this?", "who clicked after
  delivery?", "is it still in inboxes?" — and pivot in Explorer on the entity (sender, URL, hash, click
  verdict). Save the good hunts (`Explorer-MDOFULL-Pilot`, `Hunt-MDOFULL-Pilot`) so the team reuses
  them.
- **Prefer post-delivery signal.** The prevention stack already blocked the obvious; the value is in
  what got through and what changed after delivery (weaponized-after-delivery URLs, late clicks).
- **Re-hunt after every incident.** A new indicator (sender, domain, hash) is a new query — run it
  across the whole tenant, not just the reporting user.

## Understand the protection stack — then let the right solution change it

- **Read before you reason.** Knowing how anti-phish, Safe Links, and Safe Attachments decide lets you
  explain a verdict instead of guessing. Inspect the policies; don't treat them as a black box.
- **Change is a different job.** Tightening the prevention policies is the **Mail Hygiene** solution;
  operationalizing post-delivery detection/response org-wide is the **Defender for Office 365 (Plan 2)**
  solution. This solution builds the skill and the proof that make both changes safer.

## Prove it, don't pitch it

- **Benign signal only.** Use **Attack Simulation Training**, **GTUBE**, **EICAR**, and a benign **Safe
  Links** test URL exclusively — the sanctioned, harmless ways to exercise MDO. **Never** send real
  phishing, attach real malware, or embed a live malicious URL.
- **Set the bar before you run.** Agree the PoC evaluation criteria in writing first (**R7**) and feed
  them to `MDOFULL-Report.ps1` so the verdict is objective, not a vibe.
- **Allow for delivery, detonation, and ZAP timing.** Safe Attachments detonation, Safe Links
  time-of-click, and ZAP act at different moments — give the pipeline a few minutes before scoring a
  "fail," and use `MDOFULL-Validate.ps1` to see when signal has arrived.
- **Keep the PoC scoped and reversible.** It runs on the pilot group only; every change is
  `-WhatIf`-gated; tear the benign signal down completely when done and keep only the evidence file.

## Simulate to measure, train to fix — never to punish

- **Simulation is a measurement tool.** Its job is honest susceptibility data and targeted training —
  not to embarrass anyone. Make the non-punitive intent explicit (**R4**); a punitive program destroys
  reporting culture.
- **Start easy, escalate slowly.** Begin with credential-harvest to the pilot group
  (`Sim-MDOFULL-Pilot`), then broaden technique and audience over time — a **people/security decision**
  made with HR.
- **Respect people and the law.** Whether, when, and how you simulate employees — and who must be
  informed — are **HR/legal decisions**. Agree them before you launch.

## Automate response only after you trust it

- **Approval-required first.** Keep AIR **approval-required** and route remediation through the **Action
  center** until it is trusted. A human approves every deletion at first.
- **Soft before hard.** Prefer **soft-delete** (recoverable) over **hard-delete** (irreversible); make
  hard-delete a **named-approver-only** action. None of this is executed here — it is taught and gated.
- **Raise automation deliberately.** Lifting AIR automation is a **documented operations decision**,
  owned by the **Defender for Office 365 (Plan 2)** solution — not a default this solution flips.

## Turn hunts into durable coverage — carefully

- **Alert-only first.** Promote a hunt to a custom detection (`Detect-MDOFULL-Pilot`) only once it is
  quiet and accurate, and keep it alert-only until proven.
- **Version your queries.** Keep the email KQL library in source control so hunts are reviewable and
  portable — the same discipline the Sentinel detection-as-code solution applies.

## Run it as a program, not a one-off

- **Loop, don't launch-and-forget.** Hunt → simulate → train → investigate → (gated) remediate →
  report → prove, on a cadence. Post-delivery threats and user behavior both drift.
- **Re-run for new hires.** The take-home runbook, knowledge-check, and PoC make onboarding a new
  analyst — and re-proving value to a new stakeholder — repeatable.

## Where to go next

With the team able to hunt, simulate, respond, and prove MDO on email, the natural next steps in this
catalog are:

- **Defender for Office 365 (Plan 2) — Threat Explorer, Attack Simulation & AIR** — operationalize the
  post-delivery features across the org (the rollout this solution's skills and evidence feed).
- **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for Office 365** — tighten the prevention
  policies you learned to read, reducing what you have to hunt.
- **Advanced KQL for SecOps** — deepen the query language this solution applies to the email tables, and
  extend hunting across Defender XDR and Sentinel.
- **Microsoft Defender XDR onboarding** — bring endpoint, identity, and cloud-app signal into the same
  incident so email threats correlate with the whole kill chain.


---


# Deliverables Summary — Microsoft Defender for Office 365

Everything included in this solution, and what each piece is for. This is the **operate/enable/prove**
layer over MDO — it cross-references the **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for
Office 365** solution (prevention config) and the **Defender for Office 365 (Plan 2) — Threat Explorer,
Attack Simulation & AIR** solution (post-delivery rollout) rather than repeating them.

## Documentation

| Document | Purpose |
| --- | --- |
| **Executive Summary** (`executive-summary.md`) | One-page framing: the "email-security bought and under-driven / value unproven" problem, the two-track solution (enable the team + prove value), the boundary (operate/enable/prove layer; read-only/preview-first; inspects but does not reconfigure; cross-references Mail Hygiene and Plan 2), and effort. |
| **Solution Overview** (`01-solution-overview.md`) | What it is, how MDO works (prevention vs post-delivery, Threat Explorer, the protection stack, Attack Simulation Training, AIR, email hunting, benign PoC signal), the Assess→Configure→Pilot→Validate→Expand model across both tracks, scope, out-of-scope, and connections used. |
| **Requirements** (`02-requirements.md`) | Solution-specific prerequisites (Plan 1-vs-2 availability, the prevention stack to inspect and prove against, a consented pilot group, a simulation/communications note, split roles, a read-only/preview/-WhatIf posture, PoC evaluation criteria, the toolchain) — layered on the shared `global-requirements-defender.md` (G1–G8). |
| **Implementation** (`03-implementation.md`) | The full playbook: assess readiness, create the cohort + pilot group, load the KQL pack, run Track A Labs 1–8 (console/model → Threat Explorer → inspect the stack → benign simulation → email hunting → AIR held for approval → alert-only detection → reporting), run Track B PoC (benign signal → demonstrate detections), then capstone + knowledge-check + PoC evidence, then expand and tear down — every object named, with rollback. |
| **Testing & Validation** (`05-testing.md`) | Twelve pass/fail gates covering environment readiness, skills landed, PoC detections observed, AIR posture, alert-only detection, knowledge-check, evidence capture, and clean teardown — referencing the scripts by name. |
| **Troubleshooting** (`06-troubleshooting.md`) | The common failure modes (Explorer missing, sim blade absent, empty email tables, schema drift, AIR auto-deleting, no pending actions, benign signal not delivered, Safe Links/Attachments not acting, detection noisy, beta API empty, connection errors, teardown residue) as symptom → cause → fix. |
| **Best Practices** (`07-best-practices.md`) | Hunt-on-a-question, understand-the-stack-then-let-the-right-solution-change-it, prove-it-don't-pitch-it, simulate-to-measure-not-punish, automate-only-when-trusted, turn-hunts-into-durable-coverage, run-it-as-a-program — plus where to go next in the catalog. |

## Lab pack + PowerShell helpers (6)

All helpers are **read-only or preview-first / -WhatIf-gated**, authenticate **interactively** (no
credentials in code), and use **Microsoft.Graph** (security — advanced hunting via `runHuntingQuery`;
`Mail.Send` for the benign PoC test messages; attack-sim **beta** reporting where available) and, where
used, **Exchange Online / Security & Compliance** for reporting and quarantine. Government-cloud
tenants pass the matching environment — *verify endpoints for your cloud.*

| File | Type | What it does |
| --- | --- | --- |
| **`MDOFULL-Labs.kql`** | KQL lab pack | The runnable, progressive email query library — one labeled section per hunting lab (post-delivery clicks, sender/subject campaign, bad-attachment hash, delivered-then-detected), the capstone candidate, and the PoC benign-signal validation queries. The core take-home artifact. |
| **`MDOFULL-Discovery.ps1`** | Read-only | Inventories readiness: Plan 2 presence, email-table freshness (`EmailEvents` etc.), pilot-group membership, and the Action center pending posture. Changes nothing. |
| **`MDOFULL-RunLab.ps1`** | Read-only | Runs a chosen email hunting-lab query (`-Lab <n>`) from the pack via Graph and returns the rows — so learners can execute a lab from PowerShell as well as the portal. |
| **`MDOFULL-TestSignal.ps1`** | `-WhatIf`-gated | Generates **benign** PoC signal — prints the Attack Simulation launch steps and sends GTUBE / EICAR / Safe Links test messages (never real threats); a `-Teardown` mode purges the `MDOFULL-TESTSIGNAL` messages from quarantine and prints the steps to end the simulation. |
| **`MDOFULL-Validate.ps1`** | Read-only | Runs the `05-testing.md` gates as PASS/FAIL/MANUAL lines: readiness, email tables have data, hunting resolves, the PoC capability checks (Safe Links / Safe Attachments / spam-phish), AIR pending, `Detect-MDOFULL-Pilot` alert-only — and scores the knowledge-check `Check-MDOFULL-Pilot`. |
| **`MDOFULL-Report.ps1`** | Read-only | Reports cohort progress and per-lab email-data availability, and captures the **PoC evidence** — maps observed capabilities to the agreed criteria and writes `MDOFULL Evidence – Pilot Users – Validate.json` + an optional CSV. |

## Named objects (verbatim — used across docs, scripts, and tests)

- **Learner cohort group:** `Grp-MDOFULL-Cohort-Pilot`
- **Pilot user group:** `Grp-MDOFULL-PilotUsers-Pilot`
- **Explorer saved view:** `Explorer-MDOFULL-Pilot`
- **Shared saved-query set:** `Hunt-MDOFULL-Pilot`
- **Simulation:** `Sim-MDOFULL-Pilot`
- **Training assignment:** `Training-MDOFULL-Pilot`
- **Custom detection (capstone):** `Detect-MDOFULL-Pilot` (alert-only)
- **Knowledge-check:** `Check-MDOFULL-Pilot`
- **PoC test-signal tag:** `MDOFULL-TESTSIGNAL`
- **PoC evidence file:** `MDOFULL Evidence – Pilot Users – Validate.json`

## What this solution deliberately does NOT do

- It does **not** configure the prevention stack — anti-spam/-malware/-phishing, Safe Links, Safe
  Attachments, and mail-flow hygiene are the **Mail Hygiene** solution. This solution **inspects** them
  and proves detections against them.
- It does **not** perform the operational post-delivery rollout — turning the features on org-wide,
  tuning AIR automation, and running gated production remediation is the **Defender for Office 365 (Plan
  2)** solution. This solution builds the **skill** and the **proof**.
- It does **not** execute production remediation — AIR stays **approval-required**, remediation is
  **previewed only**, Explorer take-action is **not** performed against production, the capstone
  detection is **alert-only**, and the PoC generates only **benign** signal.
- It does **not** decide **who to simulate, acceptable click-rate, the AIR automation level, or what
  counts as a PoC "pass"** — those are security-leadership / HR-legal determinations; this solution
  provides the skill, the labs, the data, and the proof.
- It does **not** invent plan, feature, or schema facts — where availability may differ by plan (P1/P2)
  or cloud (GCC/GCC High) it says **verify in your tenant**.

## How it is delivered

Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the documentation as a formatted
Word document and PDF, plus the email KQL lab pack and all five PowerShell helpers, in a single ZIP
(`MDOFULL-Complete-Solution.zip`) — yours to keep and re-run for every new cohort and every new
stakeholder who needs to see the proof.
