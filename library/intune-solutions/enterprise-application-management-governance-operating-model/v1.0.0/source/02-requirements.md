# Requirements

Confirm every item below **before** you begin Section 3. The **category-level global requirements**
(Entra tenant, Intune subscription, enrolled devices, supported Windows baseline, network access) are
listed in `global-requirements-intune-solutions.md` and are assumed here. This file covers the
requirements specific to standing up an **application management governance and operating model**.

Each requirement is written as **Description / Why required / How to verify / How to implement if
missing.** Do not assume any of them already exist — several are organisational rather than technical
and are the most common reason this kind of programme stalls.

> **Government tenants:** wherever a URL appears below, substitute the sovereign equivalent —
> `https://endpoint.microsoft.us` for Intune, `https://portal.azure.us` for Entra/Azure,
> `https://login.microsoftonline.us` for sign-in, and `https://graph.microsoft.us` for Graph. The
> steps themselves are unchanged.

---

## R1. A named executive sponsor with authority over application decisions

**Description:** A single named executive — typically the CIO, IT Director, or Head of Digital
Workplace — who publicly owns the operating model and will uphold an Application Review Board
decision when it is challenged.

**Why required:** The Application Review Board's decision rights are the core of this model. Without
a sponsor who will back a rejection, the first time a senior stakeholder is told "no" the board
becomes advisory, and the model collapses into a request queue. This is the single most common
failure mode of application governance programmes, and it is an organisational prerequisite, not a
technical one.

**How to verify:** You can name the individual, and they have confirmed in writing (email is
sufficient) that (a) they endorse the operating model and (b) escalations of a board decision come to
them. If you cannot produce that email, this requirement is **not met**.

**How to implement if missing:** Prepare a one-page brief using `executive-summary.md` from this
package, present the current state (use the output of `APPOPS-Discovery.ps1` — the count of
unowned and orphaned applications is usually persuasive on its own), and ask explicitly for the
sponsorship and the escalation path. **Do not begin Step 3 (standing up the board) until this is
secured.**

---

## R2. Intune Administrator role (for the initial build)

**Description:** The **Intune Administrator** Entra role, held by the person performing the
configuration steps in Section 3.

**Why required:** Steps 4, 5, 6, and 8 create Intune scope tags, a custom Intune role, role
assignments, and app metadata changes. Scope tag and role creation require Intune Administrator;
they are not available to Help Desk Operator or to a read-only role.

**How to verify:** Sign in to `https://intune.microsoft.com`, then navigate to **Tenant
administration → Roles → All roles**. If the blade loads and you can open **Create** on the **Scope
(Tags)** page (**Tenant administration → Roles → Scope (Tags)**), you hold sufficient rights.

**How to implement if missing:** Have a Global Administrator navigate to
`https://entra.microsoft.com` → **Identity → Roles & admins → Roles & admins** → search for and
select **Intune Administrator** → **Add assignments** → select your account → **Add**. Prefer a
**time-bound eligible** assignment through Privileged Identity Management where licensed; the build
work takes hours, not permanent access.

---

## R3. Least-privilege operating roles (the steady-state model)

**Description:** After the build, day-to-day application work must **not** run on Intune
Administrator. You need the ability to create a **custom Intune role** — named `Role – App Deployment
Engineer` in this solution — granting only Managed apps **Read**, **Create**, **Update**, **Delete**,
and **Assign**, scoped by scope tag.

**Why required:** Governance that grants every packaging engineer full Intune Administrator is not
governance. The custom role is what makes the deployment engineer accountability in the RACI real:
the engineer can change applications and nothing else, and only within the scope tags they are
assigned. It also means an audit can show that application change rights are separable from device,
compliance, and Conditional Access rights.

**How to verify:** In Intune, navigate to **Tenant administration → Roles → All roles → Create**. If
the **Add Custom Role** wizard opens and lets you set permissions, you can create the role. Then
check **Tenant administration → Roles → All roles** and confirm whether `Role – App Deployment
Engineer` already exists (it will not, on a first run).

**How to implement if missing:** Section 3, Step 5 creates the role from scratch, click by click.
The only prerequisite is R2.

---

## R4. Ability to create Microsoft Entra security groups

**Description:** Rights to create Entra ID security groups, and — critically — confirmation that the
tenant's **group creation restriction** setting does not block you.

**Why required:** The model creates seven named security groups (four role groups, three deployment
ring groups) in Step 4 and Step 7. Many tenants restrict group creation to a specific group of users
via the Entra **Groups → General → Security group creation** setting; if you are not in that allowed
set, every group-creation step will fail with a permissions error that does not obviously say why.

**How to verify:** Navigate to `https://entra.microsoft.com` → **Identity → Groups → All groups** →
**New group**. If the **New Group** blade opens and the **Create** button is enabled after you fill
the required fields, you can create groups. Also check **Identity → Groups → General** and read the
value of **Users can create security groups in Azure portals, API or PowerShell** — if it is **No**,
you must be in the delegated group or hold a directory role.

**How to implement if missing:** Have a Global Administrator or Groups Administrator either (a)
assign you the **Groups Administrator** Entra role, or (b) add your account to the group nominated in
**Identity → Groups → General → Security group creation**. Groups Administrator is the least-
privilege option and is sufficient for everything in this package.

---

## R5. Microsoft Graph PowerShell SDK and the required delegated scopes

**Description:** A workstation with Windows PowerShell 5.1 or PowerShell 7 and the
**Microsoft.Graph** module installed, plus consent to the delegated Graph permissions the five
scripts require:

| Script | Scopes required |
|---|---|
| `APPOPS-Discovery.ps1` | `DeviceManagementApps.Read.All`, `DeviceManagementRBAC.Read.All`, `Group.Read.All` |
| `APPOPS-Validation.ps1` | `DeviceManagementApps.Read.All`, `DeviceManagementRBAC.Read.All` |
| `APPOPS-Report.ps1` | `DeviceManagementApps.Read.All`, `DeviceManagementRBAC.Read.All`, `Group.Read.All` |
| `APPOPS-Export-ApprovalEvidence.ps1` | `DeviceManagementApps.Read.All`, `DeviceManagementApps.Read.All`, `DeviceManagementConfiguration.Read.All` |
| `APPOPS-Remediation.ps1` | `DeviceManagementApps.ReadWrite.All`, `DeviceManagementRBAC.Read.All` |

Four of the five scripts are **strictly read-only**. Only `APPOPS-Remediation.ps1` writes, and it
defaults to `-WhatIf`.

**Why required:** The scripts read the application estate, assignments, scope tags, role definitions,
and audit events through Microsoft Graph. Without the module and consent, they return nothing or
fail at `Connect-MgGraph`.

**How to verify:** Run `$PSVersionTable.PSVersion` (expect `5.1.x` or `7.x`), then
`Get-Module Microsoft.Graph -ListAvailable` (expect at least one version listed). Then run
`APPOPS-Discovery.ps1` — at the first `Connect-MgGraph` prompt, sign in and consent. If it returns a
table of applications, access is working. You can confirm granted permissions afterwards at
`https://entra.microsoft.com` → **Identity → Applications → Enterprise applications** → search
**Microsoft Graph Command Line Tools** → **Security → Permissions**.

**How to implement if missing:** Install the SDK with
`Install-Module Microsoft.Graph -Scope CurrentUser -Force`. Run scripts with
`powershell -ExecutionPolicy Bypass -File .\APPOPS-Discovery.ps1`. If your tenant requires admin
consent for the **Microsoft Graph Command Line Tools** application, a Global Administrator must grant
it once at Enterprise applications → the app → **Security → Permissions → Grant admin consent**.

---

## R6. A system of record for the Application Register

**Description:** A durable, access-controlled place to hold the **Application Register**, the **ARB
Decision Records**, and the **Application Runbooks**. Acceptable options, in descending order of
preference: your ITSM/CMDB configuration item class; a SharePoint Online list; a Microsoft Lists
list; a governed Excel workbook in SharePoint with version history enabled.

**Why required:** Intune holds *technical* facts about applications. It does not hold business
ownership, licence entitlement position, review dates, or approval evidence, and its Notes field is
not a substitute for a register that can be reported on and audited. Without a system of record the
model has nowhere to store its own output.

**How to verify:** You can name the specific list/table/CI class, you can create items in it, and it
has (a) version history or an audit trail and (b) access control such that Application Owners can
read and only the register custodian can edit key fields.

**How to implement if missing:** The fastest acceptable option is a SharePoint Online list. Navigate
to your IT team's SharePoint site → **New → List → Blank list** → name it `Application Register` →
**Create**. Section 3, Step 2 defines the exact columns. Enable version history at **Settings → List
settings → Versioning settings → Create a version each time you edit an item in this list → Yes**.

---

## R7. An existing change management process (or a decision that none exists)

**Description:** Knowledge of whether the organisation operates a formal **Change Advisory Board
(CAB)** or equivalent change control, and if so, its cadence, its lead time, and what it classifies as
a standard/normal/emergency change.

**Why required:** Step 8 defines the **interface** between application change and enterprise change
control. If a CAB exists and you do not integrate with it, application changes will either bypass
change control (an audit finding) or clog it with routine version updates (a political problem). If
no CAB exists, the model's risk tiers become the change process itself, which changes how Step 8 is
implemented.

**How to verify:** You can state the CAB's meeting cadence, its submission deadline, and where
standard/pre-approved changes are recorded. Ask your Service Management or IT Operations lead
directly; do not infer this from a wiki page.

**How to implement if missing:** If no CAB exists, that is a valid answer — record it, and implement
Step 8 with the Application Review Board holding change authority for all four risk tiers. If a CAB
exists but is undocumented, get the cadence and standard-change definition in writing from the
process owner before drafting the change matrix.

---

## R8. An application discovery data source beyond Intune

**Description:** At least one source that shows what is actually *installed on endpoints*, as opposed
to what Intune deploys. Options: **Microsoft Defender for Endpoint** software inventory
(**Vulnerability management → Software inventory** in the Defender portal), Intune **Discovered
apps** (**Apps → Monitor → Discovered apps**), or a third-party asset management tool.

**Why required:** The Application Register must reconcile against reality. Applications present on
endpoints but absent from Intune and from the Register are ungoverned by definition — they were
installed by users, by legacy imaging, or by a departed process. Step 2 cannot produce a truthful
register without this reconciliation input, and the "shadow application" count is one of the
scorecard's most useful risk metrics.

**How to verify:** In Intune, navigate to **Apps → Monitor → Discovered apps**. If the list populates
with applications and device counts, you have a usable source. If you have Defender for Endpoint,
also confirm **Vulnerability management → Software inventory** loads in the Defender portal.

**How to implement if missing:** Intune Discovered apps requires no additional configuration for
enrolled devices — if it is empty, confirm devices have checked in recently (**Devices → All
devices**, review **Last check-in**). If you have no Defender for Endpoint licence and Discovered
apps is unavailable, record this as a known gap in the register's accuracy and plan a manual
sampling exercise instead; do not skip the reconciliation entirely.

---

## R9. Nominated individuals for the four RACI roles

**Description:** Named people (not job titles, not teams) willing to hold each of the four
accountabilities for the pilot scope: **Application Owner**, **Technical Owner**, **Security
Reviewer**, **Deployment Engineer**.

**Why required:** Step 1 populates the RACI, and Step 4 puts these people into named Entra security
groups. An unfilled role means the corresponding gate in the model has no owner, which in practice
means it is skipped. Security Reviewer is the role most often left unnamed and the one whose absence
does the most damage.

**How to verify:** You have a list with four names (or four sets of names, where a role is shared)
and each individual has been asked and agreed. Their manager is aware of the time commitment — a
realistic figure for the ARB is 60–90 minutes per cycle plus review preparation.

**How to implement if missing:** Take the gap list to the executive sponsor from R1. The Security
Reviewer must come from Information Security, not from IT operations — self-review is not review.
Where an organisation genuinely has no security function, the model still works, but record the
compensating control (for example, an external annual assessment) explicitly in the standards
document rather than pretending the gate exists.

---

## R10. Licence and entitlement data access

**Description:** Access to the organisation's software licence position — the contracts, entitlement
counts, and renewal dates — held by Procurement, Finance, or a Software Asset Management function.

**Why required:** The intake workflow's licensing gate (Step 3) and the standards document's
entitlement criterion (Step 6) both require somebody to answer "do we have the right to deploy this
to N devices?" If nobody can answer, the gate is theatre and the organisation carries unquantified
audit exposure from its own deployments.

**How to verify:** You can name the person or system that holds the entitlement record, and you have
successfully retrieved the entitlement position for one existing application as a test.

**How to implement if missing:** Identify the contract owner in Procurement and agree a service —
even an informal one — where an intake request can be checked for entitlement within the intake SLA
defined in Step 3. Record the agreed turnaround in the Application Standards Document. If no such
function exists, assign the entitlement check to the Application Owner and require them to attach the
licence agreement to the intake request.
