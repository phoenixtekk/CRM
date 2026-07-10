# Requirements — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

These are the **solution-specific** prerequisites for standing up the post-delivery detect / hunt /
simulate / respond capability. The **category baseline** — an active Microsoft 365 / Entra tenant,
Defender licensing in general, least-privilege admin roles, onboarding reach, network access to
Defender endpoints, a pilot ring, a workspace where required, and response governance — is covered
once in **`global-requirements-defender.md`** (**G1–G8**). Read that first; the items below layer on
top of it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Defender for Office 365 **Plan 2** licensing

- **Description:** Defender for Office 365 **Plan 2** assigned to the users in scope (bundled in
  Microsoft 365 E5 / Office 365 E5, E5 Security, or as an add-on). Plan 2 is what gates **Threat
  Explorer**, **Attack Simulation Training**, **AIR**, and the **email Advanced Hunting tables**.
- **Why required:** Plan 1 provides Real-time detections and the prevention features, but the
  hunting depth, simulation, automated investigation, and email hunting tables in this solution are
  **Plan 2** capabilities. Without Plan 2 the features are absent or limited.
- **How to verify:** Microsoft 365 admin center → **Billing → Licenses** shows a plan that includes
  MDO Plan 2; in `security.microsoft.com` the **Attack simulation training** and **Explorer** blades
  are present. Or run `DEFMDOP2-Discovery.ps1`, which reports Plan 2 service-plan presence and
  feature availability. *Verify current availability and exact plan mapping in your tenant.*
- **How to implement if missing:** Assign MDO Plan 2 (or an E5 bundle that includes it) to the users
  in scope, then allow time for the features to surface. Do not proceed against Plan 1 only.

## R2. The prevention layer is already in place (the companion solution)

- **Description:** Anti-spam, anti-malware, anti-phishing, **Safe Links**, **Safe Attachments**,
  connection filtering, and ZAP **policy** settings are configured — the *Microsoft 365 Mail
  Hygiene: Anti-Spam, EOP & Defender for Office 365* companion solution.
- **Why required:** This solution is the **post-delivery** half. Hunting, simulation, and AIR assume
  the preset/custom protection policies exist and are generating the signal (Safe Links click data,
  ZAP verdicts, detonation results) that Explorer and Advanced Hunting surface.
- **How to verify:** In `security.microsoft.com` → **Email & collaboration → Policies & rules →
  Threat policies**, confirm anti-phishing, anti-malware, anti-spam, Safe Links and Safe Attachments
  policies exist (or a Preset security policy is enabled).
- **How to implement if missing:** Deploy the prevention layer first (the companion solution). This
  solution does **not** configure those policies and depends on them being present.

## R3. Roles to hunt, simulate, investigate, and remediate

- **Description:** **Security Administrator** (or the granular Defender RBAC equivalents) for
  configuration; **Security Operator / Security Reader** for analysts who hunt and triage; and the
  rights to approve actions in the **Action center**. Attack Simulation Training and remediation
  approvals are privileged actions.
- **Why required:** Explorer take-action, launching simulations, changing AIR posture, and approving
  remediation are all elevated operations; least-privilege keeps who-can-delete-mail small.
- **How to verify:** Entra → **Roles and administrators**, or the Defender portal **Permissions &
  roles**, show the operating accounts hold the required roles.
- **How to implement if missing:** Assign the roles at the appropriate scope (prefer **PIM-eligible**
  for the administrator role where Entra ID P2 is available — *verify licensing*). Reserve broad
  roles for named operators only.

## R4. A defined pilot group

- **Description:** A named group of pilot users — `Grp-MDO-Pilot-Users` — to receive the first
  simulation, be the initial hunting/remediation scope, and validate AIR behavior before org-wide
  rollout. Ideally a mix of roles, but **not** high-risk executives for the very first simulation
  unless leadership approves.
- **Why required:** Simulations, AIR, and remediation are validated on a ring first (category **G6**).
  A first simulation aimed at everyone, or a remediation practiced on production mail, is avoidable
  risk.
- **How to verify:** The group exists in Entra with the intended members; it is selectable as a
  simulation target and hunting filter.
- **How to implement if missing:** Create `Grp-MDO-Pilot-Users` in Entra and populate it with a
  representative, consented pilot cohort.

## R5. A written simulation and communications plan

- **Description:** A short, **leadership-approved** plan covering **who** gets simulated, **when**,
  **how results are used** (training, not punishment), whether **HR / works councils / employee
  representatives** must be informed, and any **regional legal constraints** on simulating employees.
- **Why required:** Phishing simulation touches employees and, in some jurisdictions, employment and
  privacy law. How simulation data is used is a **people and compliance decision**, not a technical
  default.
- **How to verify:** Confirm a written, approved plan exists and names an owner.
- **How to implement if missing:** Facilitate a short session with security leadership and HR to
  agree scope, cadence, communications, and the non-punitive use of results. *Employee-simulation
  legality and works-council notification are the customer's HR/legal determinations — the solution
  provides the technical capability, not the decision.*

## R6. An agreed remediation and AIR-automation posture

- **Description:** A written position on **how remediation is approved** (who may approve soft-delete
  vs hard-delete), and the **AIR automation level** the organization will start at (this solution
  starts **approval-required**) and the criteria to raise it later.
- **Why required:** Remediation deletes mail and AIR can act automatically; the organization must
  decide the guardrails (category **G8**). Hard-delete is irreversible and must be a deliberate,
  approved action.
- **How to verify:** A documented response/approval policy exists; AIR is in an approval-required
  posture; hard-delete requires a named approver.
- **How to implement if missing:** Define the approval matrix and start AIR approval-required. Raising
  automation is a **documented operations decision** made after the pilot builds trust — not a
  default this solution flips.

## R7. The PowerShell + hunting toolchain

- **Description:** A workstation with **Microsoft.Graph** (security modules), **Exchange Online
  Management** (`Connect-ExchangeOnline`, and `Connect-IPPSSession` for Security & Compliance
  cmdlets), signed in with an MFA-capable admin; and access to **Advanced Hunting** in the Defender
  portal for the KQL library.
- **Why required:** The five delivered tools use these modules and KQL to inventory Plan 2 readiness,
  run email hunting, report threats and simulation risk, validate configuration, and **preview**
  remediation.
- **How to verify:** `Get-Module Microsoft.Graph, ExchangeOnlineManagement -ListAvailable` returns
  versions; `Connect-MgGraph` and `Connect-ExchangeOnline` succeed; Advanced Hunting loads in the
  portal.
- **How to implement if missing:** `Install-Module Microsoft.Graph, ExchangeOnlineManagement -Scope
  CurrentUser`; sign in. For Government cloud, connect with the matching environment/endpoints —
  *verify the correct endpoints for your cloud*. Some Graph attack-simulation endpoints are **beta**
  — *verify current availability before relying on them*.
