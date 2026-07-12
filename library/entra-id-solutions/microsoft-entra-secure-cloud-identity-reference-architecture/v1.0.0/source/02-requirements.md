# 2. Requirements Guide — Microsoft Entra: Secure Cloud Identity Reference Architecture

Verify every requirement before you begin the design work. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites (tenant, licensing, admin roles, break-glass
accounts, healthy AD, Connect host, UPN hygiene, network access) are in
`global-requirements-entra-id-solutions.md` — this guide adds only what is specific to producing the
reference architecture. Because this is a **design deliverable**, most requirements are about **access
to evidence and to decision owners**, not about standing up infrastructure.

## 2.1 Read-only access to the current tenant (for Assess)
Description: `Global Reader` (and `Security Reader`) on the production tenant, so the discovery,
inventory, posture, and privileged-access scripts can read the current identity posture.
Why: The design is grounded in the actual current state — humans, workloads, guests, privileged roles,
Conditional Access, licensing. Read-only roles keep the assessment safe and least-privilege.
Verify: Entra -> `Roles and administrators`; confirm the operator holds `Global Reader` (and
`Security Reader`). Run `ENTARCH-Discovery.ps1` — it should read without error and change nothing.
Implement: Assign `Global Reader` + `Security Reader` (ideally PIM-eligible). No write roles are needed
to produce the design.

## 2.2 Microsoft Graph PowerShell SDK and the Az module
Description: The Microsoft Graph PowerShell SDK and the Azure Az PowerShell module on the operator
workstation, consented to read-only scopes.
Why: All five scripts read posture through Microsoft Graph (identities, roles, policies, licensing)
and, for subscription/RBAC context, through the Az module. They are the evidence engine for Assess and
the validation engine for Validate.
Verify: `Get-Module -ListAvailable Microsoft.Graph.Authentication` and `Get-Module -ListAvailable Az.Accounts`
each return a version; a test `Connect-MgGraph` succeeds.
Implement: `Install-Module Microsoft.Graph -Scope CurrentUser` and `Install-Module Az -Scope CurrentUser`.
Scripts request least privilege (for example `Directory.Read.All`, `Policy.Read.All`,
`RoleManagement.Read.Directory`, `AuditLog.Read.All`, `Application.Read.All`).

## 2.3 Access to Entra sign-in and audit logs (for the posture KQL)
Description: Read access to Entra sign-in and audit logs — in the portal (`Monitoring -> Sign-in logs`)
and, if streamed, in a Log Analytics workspace for the KQL queries.
Why: The assessment quantifies the real posture — MFA coverage, legacy-auth usage, risky sign-ins,
privileged sign-in patterns — which drives several architecture decisions. Sign-in log retention and
KQL both benefit from Entra ID P1+ and (for longer history) a Log Analytics workspace.
Verify: `Monitoring -> Sign-in logs` returns recent events; if using KQL, the Log Analytics workspace
has the `SigninLogs` / `AuditLogs` tables populated.
Implement: Confirm Entra ID P1+ for sign-in log access; if you want history beyond the built-in
retention, configure `Diagnostic settings` to stream `SignInLogs` and `AuditLogs` to a Log Analytics
workspace. *Verify current retention and licensing in your tenant.*

## 2.4 A current licensing and product inventory
Description: A clear picture of which identity licenses the tenant actually holds — Entra ID P1/P2,
Entra ID Governance, Global Secure Access, Verified ID — and any add-ons.
Why: The target-state design must be honest about license reality: risk-based Conditional Access and
PIM need **P2**; entitlement management and lifecycle workflows need **Entra ID Governance**; Global
Secure Access and Verified ID are **separately licensed / partly in preview**. Decisions that assume an
unlicensed feature are not defensible. *Verify current availability in your tenant.*
Verify: Run `ENTARCH-Discovery.ps1` (licensing section) and cross-check M365 admin center ->
`Billing -> Licenses`.
Implement: Record the true license position; where a target-state decision needs a license the tenant
lacks, either flag it as a roadmap prerequisite (acquire the license) or design an interim P1-only
alternative and note the gap.

## 2.5 Named decision owners (the design cannot be made for them)
Description: Named owners from **security**, **IT operations**, and **compliance/legal** who own the
determinations the architecture must not make unilaterally.
Why: Tenant topology, what counts as "privileged," data-residency and regulatory constraints,
acceptable external-collaboration posture, and change-approval are **business/security/compliance
decisions**. The architect frames the options and the tradeoffs; these owners decide, and their
decisions become `ADR-0nn` entries with an owner attributed.
Verify: Each of the six design domains has a named accountable owner recorded before the Configure
stage.
Implement: Identify the owners at kickoff; if a domain has no owner, that is itself a finding — the
design records the open decision rather than inventing an answer.

## 2.6 Inventory of existing identity controls (avoid re-deciding what exists)
Description: Knowledge of what identity controls already exist — current Conditional Access policies,
any PIM configuration, existing governance (access reviews/access packages), current hybrid sync, and
existing break-glass accounts.
Why: This is a **gap-only** design. Where a control already exists and is sound, the architecture
adopts it (and records why); it does not rebuild it. The scripts surface what is already there so the
roadmap targets only the gaps.
Verify: Run `ENTARCH-Discovery.ps1` and `ENTARCH-PrivilegedAccessReview.ps1`; review the existing CA
policies, PIM assignments, and break-glass accounts they list.
Implement: Capture the current-state inventory as the "Assess" appendix of the Design Document; each
existing control is either **adopt**, **adjust**, or **replace** in the Decision Record.

## 2.7 Break-glass accounts (design prerequisite, not a build here)
Description: At least two cloud-only emergency access accounts (global requirement G4) — the design
assumes and mandates them, and the privileged-access domain records their standard.
Why: The privileged access model depends on break-glass being the anti-lockout guarantee behind every
future Conditional Access and PIM build. The architecture defines the standard even though the builds
implement the exclusions.
Verify: Entra -> `Users`; confirm two cloud-only `@onmicrosoft.com` accounts; `ENTARCH-PrivilegedAccessReview.ps1`
lists them.
Implement: If missing, create them (per G4) and record the break-glass standard as an `ADR`. Do not
proceed to design the privileged access model without them.

## 2.8 A place to author the design artifacts
Description: A location to author and version the three deliverables — the Architecture Design Document,
the Decision Record, and the Roadmap (a document library, repo, or wiki).
Why: A reference architecture is only useful if it is versioned, reviewable, and durable. The Decision
Record in particular is a living log that outlives any single build.
Verify: The team has a versioned home for the three artifacts, with the decision owners able to review.
Implement: Use the organization's standard docs location; keep the Decision Record under version
control so each `ADR` change is traceable.

---
## Checklist
- [ ] `Global Reader` + `Security Reader` on the production tenant (read-only) — `ENTARCH-Discovery.ps1` runs clean
- [ ] Microsoft Graph SDK and Az module installed and consented (read-only scopes)
- [ ] Sign-in / audit log access (portal, and Log Analytics if using the posture KQL)
- [ ] True licensing position recorded (P1/P2, Governance, GSA, Verified ID) — *verify availability*
- [ ] Named decision owners for all six domains (security / ops / compliance)
- [ ] Existing identity controls inventoried — adopt / adjust / replace decided per control
- [ ] Two cloud-only break-glass accounts confirmed (global requirement G4)
- [ ] Versioned home for the Design Document, Decision Record, and Roadmap
