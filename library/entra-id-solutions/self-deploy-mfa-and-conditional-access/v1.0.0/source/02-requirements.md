# 2. Requirements Guide — Self-Deploy: Multi-Factor Authentication & Conditional Access

These are the **solution-specific** prerequisites for running the MFA & Conditional Access enablement
kit. The **category baseline** — an active Microsoft Entra tenant, Entra licensing, least-privilege
admin roles, break-glass accounts, and network access — is covered once in
**`global-requirements-entra-id-solutions.md`** (**G1–G8**). Read that first; the items below layer on
top of it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Entra ID licensing for Conditional Access (P1; P2 for risk labs)

- **Description:** **Microsoft Entra ID P1** for Conditional Access itself; **Entra ID P2**
  additionally if you want to *discuss/observe* the risk-based conditions (sign-in risk, user risk
  from Identity Protection) in the design lab.
- **Why required:** CA is a P1 feature; the report-only lab policies (Lab 4) need P1 to be created.
  Risk conditions need P2. *Verify current availability — bundles change and differ by cloud.*
- **How to verify:** M365 admin center -> **Billing -> Licenses**; or `EKMFACA-Discovery.ps1` reports
  the detected P1/P2 tier.
- **How to implement if missing:** Assign M365 E3/E5, EMS E3/E5, or standalone P1/P2. If the tenant
  has no P1, Labs 2–6 become a **read-only tour** of the CA and sign-in-log blades (no policy build) —
  note the gap; the MFA-methods lab still runs in full.

## R2. A learner cohort and least-privilege lab roles

- **Description:** A named group of learners — `Grp-MfaCa-Cohort` — each holding a **read** role
  (**Global Reader** / **Security Reader**). The instructor holds **Conditional Access Administrator**
  (or **Security Administrator**) to *create* the report-only lab policies, and **Authentication
  Policy Administrator** to view/adjust the methods policy.
- **Why required:** Labs run at **least privilege** — learners read and follow along; only the
  instructor creates the report-only lab policies. This models the real least-privilege discipline the
  kit teaches.
- **How to verify:** Entra -> **Roles and administrators**; confirm the cohort holds read roles and
  the instructor holds `Conditional Access Administrator`. `EKMFACA-Discovery.ps1` lists role
  assignments.
- **How to implement if missing:** Create `Grp-MfaCa-Cohort`; assign read roles to learners; assign
  the instructor `Conditional Access Administrator` (prefer **PIM-eligible** where Entra ID P2 is
  available — *verify licensing*).

## R3. Lab persona groups (the lab scope)

- **Description:** A small set of **cloud-only lab persona groups** the report-only policies target —
  `Grp-MfaCa-Persona-Internals-Pilot`, `Grp-MfaCa-Persona-Admins-Pilot`,
  `Grp-MfaCa-Persona-Guests-Pilot` — each containing only a few disposable test users (or the cohort
  members themselves for observation).
- **Why required:** The kit teaches **design by persona**; the report-only policies scope to these
  groups so the labs are legible, contained, and obviously safe (report-only + a tiny scope).
- **How to verify:** The groups exist with a handful of test members; `EKMFACA-Discovery.ps1` /
  `EKMFACA-Validate.ps1` list them.
- **How to implement if missing:** Create them (or run `EKMFACA-LabPolicy.ps1`, which creates the
  persona groups if absent before previewing the policies). Use cloud-only test users, never
  production staff.

## R4. Break-glass accounts and an exclusion group

- **Description:** Two cloud-only emergency-access (break-glass) accounts (global requirement **G4**)
  and a dedicated exclusion group `Grp-MfaCa-Excl-BreakGlass` containing them, excluded from **every**
  lab policy.
- **Why required:** Even in report-only, the kit teaches the anti-lockout guarantee — break-glass
  excluded from every policy — so the habit is second nature before anyone builds an enforced policy
  (ENTZTCA).
- **How to verify:** Entra -> **Users**; two cloud-only `@onmicrosoft.com` admins exist and are
  members of `Grp-MfaCa-Excl-BreakGlass`. `EKMFACA-Discovery.ps1` flags whether break-glass-style
  accounts are present; `EKMFACA-Validate.ps1` checks every lab policy excludes the group.
- **How to implement if missing:** Create the accounts (**G4**) and the exclusion group; the lab
  policies exclude the group from the first save.

## R5. MFA methods understood; sign-in logs available

- **Description:** Access to **Protection -> Authentication methods** (to see which methods are
  enabled and registration coverage) and to **Monitoring -> Sign-in logs** (for the CA-evaluation and
  troubleshooting labs), ideally exported to a **Log Analytics workspace** for the KQL labs.
- **Why required:** Lab 1 explores MFA methods and registration; Lab 6 reads sign-in failures and CA
  results — both need these blades. The KQL pack runs over exported sign-in logs.
- **How to verify:** The Authentication methods blade loads and shows enabled methods; Sign-in logs
  return recent rows. `EKMFACA-Discovery.ps1` reports the enabled methods and MFA-registration
  coverage.
- **How to implement if missing:** Grant read access to the blades; export sign-in logs to a workspace
  (**Diagnostic settings**) for the KQL labs, or use the portal sign-in-log view. *Sign-in-log export
  and retention depend on P1/P2 — verify.*

## R6. The PowerShell + KQL helper toolchain

- **Description:** A workstation with the **Microsoft Graph PowerShell SDK**, signed in with an
  MFA-capable account holding at least read scopes (and, for the instructor,
  `Policy.ReadWrite.ConditionalAccess` for the report-only lab-policy builder); plus access to sign-in
  logs for the KQL labs.
- **Why required:** The five delivered helpers check readiness, build the report-only lab policies
  (gated), run the sign-in/CA KQL context, validate skills, and report impact + progress.
- **How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph`
  succeeds; sign-in logs load.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in. For
  Government cloud, connect with the matching environment/endpoints — *verify the correct endpoints
  for your cloud*.

---

## Checklist

- [ ] Entra ID P1 confirmed (P2 to observe risk conditions) (**R1**)
- [ ] `Grp-MfaCa-Cohort` created; learners hold read roles; instructor holds `Conditional Access Administrator` (**R2**)
- [ ] Lab persona groups created with test members (**R3**)
- [ ] Break-glass accounts + `Grp-MfaCa-Excl-BreakGlass` created; excluded from every lab policy (**R4/G4**)
- [ ] Authentication methods + Sign-in logs reachable; export to workspace for KQL labs (**R5**)
- [ ] Microsoft Graph SDK installed and consented (**R6**)
