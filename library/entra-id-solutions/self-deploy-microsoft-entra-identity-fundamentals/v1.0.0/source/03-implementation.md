# 3. Implementation Guide — Self-Deploy: Microsoft Entra Identity Fundamentals

This is the exact, ordered guide — a sequence of **guided hands-on labs**. Every object you create is
**named** with a consistent convention — `<Purpose> - <Scope> - <Stage>` — and the same name is
reused in later labs, the knowledge-check, and the scripts. Labs run **read-only first**, and every
object you create is a **cloud-only sandbox** object you can delete afterward. The only Conditional
Access object built is created in **report-only** and can never enforce.

> **Before you start:** confirm portal access (**R1**), the cohort and least-privilege roles
> (**R2**), the cloud-only sandbox posture (**R3**), break-glass accounts (**R4**, **G4**), your
> licensing tier (**R5**), and the toolchain (**R6**). This guide **explores and practices** on a
> sandbox; it does not reconfigure production identity.

**Object naming convention (used everywhere below and in the scripts): `<Purpose> - <Scope> -
<Stage>`.** Create these once and reuse the exact names in testing, troubleshooting, and scripts:

| Object | Name | What it is |
| --- | --- | --- |
| Learner cohort group | `Grp-EntraFund-Cohort` | Entra security group of kit learners |
| Lab practice team group | `Grp-EntraFund-LabTeam-Pilot` | Assigned security group used in the groups & CA labs |
| Lab dynamic group | `Grp-EntraFund-DynamicDept-Pilot` | Dynamic membership group (rule-driven) demo |
| Lab cloud-only test user | `Lab-EntraFund-User1` | UPN `lab-entrafund-user1@contoso.onmicrosoft.com` — a disposable test identity |
| Lab app registration | `App-EntraFund-LabApp-Pilot` | An app registration created to see the registration vs enterprise-app split |
| Lab Conditional Access policy | `CAFund-RequireMFA-LabTeam-ReportOnly` | A **report-only** CA policy scoped to the lab team only |
| Knowledge-check | `Check-EntraFund-Pilot` | The scored end-of-kit knowledge-check |

The runnable sign-in/audit queries for the sign-in and MFA labs live in the delivered
**`EKIDFUND-Labs.kql`** pack, organized by lab. You can paste them into **Entra -> Monitoring ->
Sign-in logs** log-analytics view (where exported) or run the read-only equivalents from PowerShell.

---

## Phase 0 — Assess (read-only, changes nothing)

### Step 0.1 — Confirm readiness

1. Sign in to the **Microsoft Entra admin center** -> `https://entra.microsoft.com` and confirm the
   **Overview** blade shows your tenant name and tenant ID.
2. From PowerShell, take a read-only picture of the tenant fundamentals:

   ```
   pwsh -File .\EKIDFUND-Discovery.ps1
   ```

   It reports, read-only: user and guest counts, group counts (security vs M365, assigned vs
   dynamic), directory-role assignments (and whether Global Administrator is over-assigned), app
   registration and enterprise-app counts, the licensing tier (P1/P2), MFA-registration coverage, and
   any existing Conditional Access policies. **Nothing is modified.** Save the output — it is your
   before picture and a teaching prop.

### Step 0.2 — Create the learner cohort

1. In the Entra admin center -> **Groups -> All groups -> New group**.
2. Type **Security**; **Group name** `Grp-EntraFund-Cohort`; add the learners as members.
3. Confirm each learner holds a read role (**Global Reader** / **Directory Readers**) and the
   instructor holds the setup roles (**R2**).

---

## Phase 1 — Configure (stand up the cloud-only lab sandbox)

### Step 1.1 — Create the lab sandbox (instructor)

1. Preview what the sandbox setup would create (changes nothing):

   ```
   pwsh -File .\EKIDFUND-LabSetup.ps1
   ```

2. Review the preview, then create the sandbox objects (still small, cloud-only, disposable):

   ```
   pwsh -File .\EKIDFUND-LabSetup.ps1 -WhatIf:$false
   ```

   It creates `Grp-EntraFund-LabTeam-Pilot`, `Grp-EntraFund-DynamicDept-Pilot`, the cloud-only test
   user `Lab-EntraFund-User1`, and the app registration `App-EntraFund-LabApp-Pilot`. All are named
   for easy cleanup. *You can also create each object by hand in the labs below — the script just
   makes setup and teardown one command.*

---

## Phase 2 — Pilot (the guided labs)

Run each lab with the cohort. Each lab states the **concept**, the **task**, and the **check**.

### Lab 1 — Tenant tour: what you are looking at

- **Concept.** A tenant is your isolated directory instance. It has an initial domain
  (`contoso.onmicrosoft.com`), a tenant ID, verified custom domains, and every identity/config below.
- **Task.** In **Overview**, find the tenant name, tenant ID, and primary domain. Open **Identity ->
  Settings -> Domain names** and note which domains are **Verified**. Open the left-nav and locate
  Users, Groups, Roles and administrators, Applications, and Protection.
- **Check.** You can state your tenant ID, primary domain, and where each major blade lives.

### Lab 2 — Users and identities

- **Concept.** Entra holds **member** users, **guest** users (B2B), and **service principals**
  (apps/automation, not people). Each has a UPN, object ID, and attributes.
- **Task.** Open **Users -> All users**; open `Lab-EntraFund-User1` and read its UPN, object ID,
  usage location, and assigned roles/groups. Filter the list to **Guest** user type and note how a
  guest UPN differs (`#EXT#`). *Do not modify a real user.*
- **Check.** You can tell a member from a guest from a service principal, and read a user's UPN and
  object ID.

### Lab 3 — Groups and dynamic membership

- **Concept.** A **security group** targets access/policy to many users; a **Microsoft 365 group**
  also backs a mailbox/Team. Membership is **assigned** or **dynamic** (rule-driven).
- **Task.** Open `Grp-EntraFund-LabTeam-Pilot` and add `Lab-EntraFund-User1` as a member (assigned).
  Open `Grp-EntraFund-DynamicDept-Pilot` and read its **dynamic membership rule** (e.g.
  `user.department -eq "LabDept"`); set `Lab-EntraFund-User1`'s department to `LabDept` and watch it
  join automatically. *These are sandbox groups only.*
- **Check.** You can create/target a security group and explain assigned vs dynamic membership.

### Lab 4 — Roles and RBAC (least privilege)

- **Concept.** Built-in **directory roles** bundle permissions. Global Administrator is
  all-powerful and should be rare; most tasks need a narrow role (User Administrator, Helpdesk
  Administrator, Security Reader).
- **Task.** Open **Roles and administrators**; open **Global Administrator** and read its members
  (note how few there should be). Open **Helpdesk Administrator** and read what it can and cannot do.
  Using `EKIDFUND-Discovery.ps1` output, discuss whether any role is over-assigned. *Read-only — do
  not change a real assignment.*
- **Check.** You can name three least-privilege roles, explain why Global Administrator is guarded,
  and read who holds a role.

### Lab 5 — App registrations vs enterprise applications

- **Concept.** An **app registration** is the *definition* of an app (identity, redirect URIs, API
  permissions, secrets). An **enterprise application** (service principal) is the *instance* users
  sign in to and that you assign/consent/govern.
- **Task.** Open **App registrations** and open `App-EntraFund-LabApp-Pilot`; read its Application
  (client) ID, redirect URIs, and **API permissions** (note delegated vs application permissions, and
  what "admin consent" means — do not grant consent in the lab). Then open **Enterprise applications**
  and find the matching service principal — the *instance* of the same app. *Read-only.*
- **Check.** You can explain the registration vs enterprise-app split and where API permissions and
  consent live.

### Lab 6 — Sign-in, MFA, and a report-only Conditional Access policy

- **Concept.** A sign-in is authenticated, then evaluated by **Conditional Access** (an if-then
  engine) before a token is issued. **MFA** adds a second factor; **phishing-resistant** methods
  (FIDO2/passkey) are the strongest. **Report-only** lets a policy be fully evaluated and logged
  **without enforcing** — the safe way to learn CA.
- **Task (read the sign-in logs).** Open **Monitoring -> Sign-in logs**; open one sign-in and read its
  **Conditional Access** tab, **Authentication details** (which method satisfied MFA), and status.
  Run the sign-in KQL from `EKIDFUND-Labs.kql` (Lab 6 section) to summarize sign-ins by method and
  result.
- **Task (build a report-only policy — P1 required, safe).** In **Protection -> Conditional Access ->
  Policies -> New policy**, create `CAFund-RequireMFA-LabTeam-ReportOnly`: **Assignments -> Users ->
  Include** `Grp-EntraFund-LabTeam-Pilot`; **Exclude** your break-glass accounts (**R4/G4**);
  **Target resources -> All cloud apps**; **Grant -> Require multifactor authentication**; set
  **Enable policy = Report-only**. Save. *It is report-only — it evaluates and logs but cannot block
  anyone.* If the tenant has no P1, make this a **read-only tour** of the CA blade instead (**R5**).
- **Check.** You can trace a sign-in through MFA and Conditional Access in the logs, and you built a
  policy that is scoped to the lab team, excludes break-glass, and is **report-only**.

---

## Phase 3 — Validate (capstone + knowledge-check)

1. **Capstone.** Each learner, unaided, does the following on the sandbox: create a new cloud-only
   test user, add it to `Grp-EntraFund-LabTeam-Pilot`, confirm the report-only CA policy *would* apply
   to it (via **Conditional Access -> What If**), and explain each step aloud. *No production object
   is touched; the CA policy stays report-only.*
2. **Knowledge-check.** Score the knowledge-check `Check-EntraFund-Pilot`:

   ```
   pwsh -File .\EKIDFUND-Validate.ps1
   ```

   It walks the pass/fail gates in `05-testing.md` — sandbox objects exist, the CA lab policy is
   report-only and excludes break-glass, licensing is as expected — and prints the knowledge-check
   answer key for the instructor to score.
3. **Cohort report.** Summarize the fundamentals picture and cohort progress:

   ```
   pwsh -File .\EKIDFUND-Report.ps1 -OutputCsv .\ekidfund-cohort.csv
   ```

---

## Phase 4 — Expand (operate with confidence)

1. **Keep or tear down the sandbox.** If the kit was a one-off, remove the sandbox objects (Step
   "Rollback" below). If you will re-run for new hires, keep them and re-use the runbook.
2. **Progress to the advanced solutions.** With the fundamentals in place, the natural next steps are
   the **Zero Trust Conditional Access Baseline (ENTZTCA)** and **Conditional Access Integration**
   (design a real, enforced baseline), **Privileged Identity Management (ENTPIM)** (just-in-time
   admin), **Passwordless & Passkey (ENTPASSKEY)** (phishing-resistant MFA), and **Identity Governance
   & Access Reviews (ENTIGA)**.
3. **Adopt the runbook.** Move the take-home fundamentals runbook and glossary into the team's
   standing operations documentation so the grounding is reused, not re-explained.

---

## Rollback / safe-off

- **Exploration labs (1, 2, 4, 5):** read-only — nothing to roll back.
- **Sandbox objects (Labs 1–5):** delete `Grp-EntraFund-LabTeam-Pilot`,
  `Grp-EntraFund-DynamicDept-Pilot`, `Lab-EntraFund-User1`, and `App-EntraFund-LabApp-Pilot` (and its
  enterprise-app) if the kit was one-off — or run `EKIDFUND-LabSetup.ps1 -Remove -WhatIf:$false` after
  previewing.
- **Conditional Access lab policy:** the policy is **report-only** and cannot enforce; set it to
  `Off` or delete `CAFund-RequireMFA-LabTeam-ReportOnly` to remove it entirely. Break-glass is
  excluded throughout, so there is no lock-out risk.
