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
