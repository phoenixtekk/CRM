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
