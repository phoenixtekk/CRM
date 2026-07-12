# 2. Requirements Guide — Self-Deploy: Microsoft Entra Identity Fundamentals

These are the **solution-specific** prerequisites for running the Identity Fundamentals enablement
kit. The **category baseline** — an active Microsoft Entra tenant, Entra licensing, least-privilege
admin roles, break-glass accounts, and network access — is covered once in
**`global-requirements-entra-id-solutions.md`** (**G1–G8**). Read that first; the items below layer on
top of it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Portal access to the Microsoft Entra admin center

- **Description:** Learners can open **`https://entra.microsoft.com`** and see the directory —
  Overview, Users, Groups, Roles and administrators, Applications, and Protection (Conditional
  Access).
- **Why required:** The interactive labs are performed in this portal; without access there is nothing
  to explore.
- **How to verify:** Sign in and confirm the **Overview** blade loads and shows the tenant name and
  tenant ID. Or run `EKIDFUND-Discovery.ps1`, which confirms the directory is reachable read-only.
- **How to implement if missing:** Grant each learner at least a read role (e.g. **Global Reader**);
  confirm they can reach the portal from their workstation (network access is **G8**).

## R2. A learner cohort and least-privilege lab roles

- **Description:** A named group of learners — `Grp-EntraFund-Cohort` — each holding a **read** role
  for exploration (**Global Reader** or **Directory Readers**). The instructor holds the higher roles
  needed to *create* the lab sandbox objects (**User Administrator** + **Groups Administrator** +
  **Application Administrator**, or **Global Administrator** for the one-time setup).
- **Why required:** Labs run at **least privilege** — learners read and follow along, and only the
  instructor creates the sandbox objects. This models the real least-privilege discipline the kit
  teaches.
- **How to verify:** Entra -> **Roles and administrators**; confirm the cohort holds read roles and
  the instructor holds the setup roles. `EKIDFUND-Discovery.ps1` lists directory-role assignments.
- **How to implement if missing:** Create `Grp-EntraFund-Cohort` in Entra (or with
  `EKIDFUND-LabSetup.ps1`); assign read roles to learners; reserve create/change roles to the
  instructor (prefer **PIM-eligible** where Entra ID P2 is available — *verify licensing*).

## R3. A safe, cloud-only lab sandbox posture

- **Description:** An agreed rule that all labs are performed on **cloud-only, clearly named test
  objects** (users prefixed `Lab-EntraFund-`, groups prefixed `Grp-EntraFund-`) in the
  `contoso.onmicrosoft.com` initial domain — never on real staff, production groups, or the
  synchronized (on-prem) objects.
- **Why required:** Learners practice creating and changing objects; doing that on production
  identities risks breaking sign-in. A named sandbox keeps every lab reversible and obvious to clean
  up.
- **How to verify:** Confirm the kickoff states the sandbox rule; confirm the sandbox objects carry
  the agreed prefixes. `EKIDFUND-Validate.ps1` lists the sandbox objects it finds.
- **How to implement if missing:** State it at kickoff; create the sandbox with `EKIDFUND-LabSetup.ps1`
  (preview by default); if the tenant is synced from AD, do **not** create lab users in synced OUs —
  keep them cloud-only.

## R4. Break-glass accounts protected (before any Conditional Access lab)

- **Description:** Two cloud-only emergency access (break-glass) accounts exist (global requirement
  **G4**) and are known to the team, so the Lab 6 **report-only** Conditional Access policy can be
  built with confidence.
- **Why required:** Even a report-only CA lab is a good moment to teach the anti-lockout discipline —
  break-glass is excluded from CA policies and never enrolled in a policy that could block it. The
  lab reinforces the habit before anyone builds a real, enforced policy elsewhere (ENTZTCA).
- **How to verify:** Entra -> **Users**; confirm two cloud-only `@onmicrosoft.com` admin accounts
  exist. `EKIDFUND-Discovery.ps1` flags whether break-glass-style accounts are present.
- **How to implement if missing:** Create them per **G4** before the Conditional Access lab; store the
  credentials securely; the lab policy is report-only so it cannot enforce, but the habit is taught
  regardless.

## R5. Entra ID licensing awareness (P1/P2 and add-ons)

- **Description:** Knowledge of what the tenant is licensed for — Microsoft 365 core, **Entra ID P1**
  (Conditional Access, group-based licensing), **Entra ID P2** (Identity Protection risk, PIM), and
  any add-ons (Identity Governance, Global Secure Access, Verified ID).
- **Why required:** The licensing/admin-role lab teaches which features are available; some labs
  (report-only Conditional Access) assume **P1**. *Verify current availability — bundles change and
  differ by cloud.*
- **How to verify:** M365 admin center -> **Billing -> Licenses**; or `EKIDFUND-Discovery.ps1` reports
  the detected licensing tier (P1/P2 service plans).
- **How to implement if missing:** If the tenant is core-only (no P1), the Conditional Access lab
  becomes a **read-only tour** of the CA blade instead of a report-only policy build — note the gap;
  every other lab runs in full.

## R6. The PowerShell + KQL helper toolchain

- **Description:** A workstation with the **Microsoft Graph PowerShell SDK** installed, signed in with
  an MFA-capable account holding at least read scopes; plus access to **sign-in and audit logs** (in
  the portal, or a Log Analytics workspace where sign-in logs are exported) for the KQL labs.
- **Why required:** The five delivered helpers check readiness, set up the sandbox (gated), run the
  sign-in/audit KQL lab pack context, validate skills, and report cohort progress.
- **How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph`
  succeeds; sign-in logs load in **Entra -> Monitoring -> Sign-in logs**.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`; sign in. For
  Government cloud, connect with the matching environment/endpoints — *verify the correct endpoints
  for your cloud*.

---

## Checklist

- [ ] Portal access to `entra.microsoft.com` confirmed for every learner (**R1**)
- [ ] `Grp-EntraFund-Cohort` created; learners hold read roles; instructor holds setup roles (**R2**)
- [ ] Cloud-only lab-sandbox posture agreed; naming prefixes set (**R3**)
- [ ] Break-glass accounts confirmed before the Conditional Access lab (**R4**, **G4**)
- [ ] Licensing tier known (P1 for the report-only CA lab; note gaps) (**R5**)
- [ ] Microsoft Graph SDK installed and consented; sign-in logs reachable (**R6**)
