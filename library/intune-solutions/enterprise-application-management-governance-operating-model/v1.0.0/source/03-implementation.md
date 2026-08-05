# Implementation

This section stands up the operating model end to end. Work through the steps **in order** — later
steps depend on objects created by earlier ones. Every object you create is given an **exact name**;
use that name verbatim, because Section 5 (Testing), Section 6 (Troubleshooting), and all five
PowerShell scripts refer to these names directly.

**Naming convention used throughout:** `<Purpose> – <Scope> – <Stage>`, using an en dash (`–`)
surrounded by single spaces. Keep it consistent; the validation script matches on it.

> **Government tenants:** substitute `https://endpoint.microsoft.us` for `https://intune.microsoft.com`
> and `https://portal.azure.us` for `https://entra.microsoft.com` in every navigation path below. The
> blade names, tab names, and field names are the same.

**Total elapsed time:** expect 3–5 working days of effort for Steps 1–8, then two full board cycles
(typically 4–6 weeks) for the pilot in Step 13.

---

## Step 1 — Baseline the current application estate

You cannot govern what you have not counted. Produce the "before" picture first; it is also the
evidence you will use to hold the executive sponsor's attention.

1. On your admin workstation, open **PowerShell** as your normal (non-elevated) user.
2. Install the Graph SDK if it is not present:
   ```
   Install-Module Microsoft.Graph -Scope CurrentUser -Force
   ```
3. Change to the folder containing this package's scripts.
4. Run the discovery script, exporting to CSV:
   ```
   powershell -ExecutionPolicy Bypass -File .\APPOPS-Discovery.ps1 -CsvPath .\AppEstate-Baseline.csv
   ```
   For a Government tenant add `-GraphEnvironment USGov`.
5. At the `Connect-MgGraph` prompt, sign in with an account holding the rights from R2 and **Accept**
   the consent prompt.
6. Open `AppEstate-Baseline.csv` in Excel. Record these five numbers — they are your baseline
   scorecard, and Step 13 will measure against them:

   | Metric | Where it comes from |
   |---|---|
   | Total applications in Intune | Row count |
   | Applications with **no assignment** (orphaned) | `AssignmentCount` = 0 |
   | Applications assigned to **All Users** or **All Devices** | `TargetsAllUsers` or `TargetsAllDevices` = `True` |
   | Applications with **no owner recorded** | `GovernedOwner` is blank |
   | Applications with **no scope tag** other than Default | `ScopeTags` = `Default` |

7. Now capture what is installed but **not** deployed by Intune. In Intune, navigate to
   **Apps → Monitor → Discovered apps**. Click **Export** → **Yes** to generate the CSV, then
   download it when the notification appears.
8. In Excel, compare the Discovered apps list against the Intune-deployed list from step 6. Count the
   applications present on endpoints but **absent from Intune**. Record this as **Shadow
   applications** — it is usually the most uncomfortable and most useful number in the baseline.
9. Save all three files to your system of record (R6) in a folder named `Application Governance –
   Baseline – <YYYY-MM>`. Do not skip this; Step 13 compares against it.

---

## Step 2 — Create the Application Register

The Application Register is the authoritative record. Intune is the *technical* system of record;
the Register is the *governance* system of record.

1. Open your system of record from R6. These instructions use SharePoint Online; adapt the field
   types if you are using an ITSM CI class.
2. Navigate to your IT team's SharePoint site → **New → List → Blank list**.
3. In **Name**, enter exactly `Application Register`. In **Description**, enter
   `Authoritative record of every application in the managed estate, its owners, approval status, and lifecycle state.`
   Leave **Show in site navigation** ticked. Click **Create**.
4. Add the following columns. For each, click **+ Add column**, choose the type shown, enter the name
   exactly as written, then click **Save**.

   | Column name | Type | Notes |
   |---|---|---|
   | `Application Name` | Single line of text | Rename the default `Title` column to this. |
   | `Vendor` | Single line of text | |
   | `Version` | Single line of text | Current approved version. |
   | `Application Owner` | Person | Business accountability. Required. |
   | `Technical Owner` | Person | Package and runbook accountability. Required. |
   | `Security Reviewer` | Person | Who signed the risk assessment. |
   | `Deployment Engineer` | Person | Who executes changes. |
   | `Data Classification` | Choice | `Public`, `Internal`, `Confidential`, `Restricted`. |
   | `Business Justification` | Multiple lines of text | Copied from the intake request. |
   | `Licence Position` | Choice | `Entitled`, `Entitlement pending`, `Free/no licence`, `Non-compliant`. |
   | `Entitlement Count` | Number | Seats or devices licensed. |
   | `Lifecycle State` | Choice | `Requested`, `In review`, `Approved – pilot`, `Approved – production`, `Deprecated`, `Retired`. |
   | `ARB Decision Reference` | Single line of text | Format `ARB-<YYYY>-<NNN>`. |
   | `Approval Date` | Date and time | Date only. |
   | `Next Review Date` | Date and time | Approval date + review interval (Step 6). |
   | `Intune App Id` | Single line of text | The GUID from Intune; the join key to the scripts. |
   | `Risk Tier` | Choice | `Tier 1 – Low`, `Tier 2 – Moderate`, `Tier 3 – High`, `Tier 4 – Critical`. |
   | `Runbook Link` | Hyperlink | Points at the Application Runbook. |
   | `Support Tier` | Choice | `L1 resolvable`, `L2 required`, `L3/vendor required`. |

5. Enable version history: click the **gear icon** (top right) → **List settings** → **Versioning
   settings** → set **Create a version each time you edit an item in this list** to **Yes** → **OK**.
6. Set permissions: **gear icon → List settings → Permissions for this list → Stop Inheriting
   Permissions → OK**. Then **Grant Permissions** and give the register custodian **Edit**, and all
   Application Owners **Read**. Approval fields must not be editable by requesters.
7. Import your Step 1 baseline. Open `AppEstate-Baseline.csv`, and for each application create a
   register item populating `Application Name`, `Vendor`, and `Intune App Id`. Leave the ownership
   and approval fields blank — the gaps are the point, and Step 12 will fill them.
8. Create a second list named exactly `ARB Decision Record` with these columns: `Decision Reference`
   (single line of text, format `ARB-<YYYY>-<NNN>`), `Application Name` (single line of text),
   `Decision Date` (date), `Decision` (choice: `Approved`, `Approved with conditions`, `Deferred –
   evidence required`, `Rejected`), `Conditions` (multiple lines of text), `Members Present`
   (multiple lines of text), `Evidence Pack Link` (hyperlink), `Decision Rationale` (multiple lines
   of text). Enable version history as in step 5.

---

## Step 3 — Define the four accountabilities (the RACI)

1. Create a document in your system of record named exactly
   `Application Management RACI – Enterprise – v1.0`.
2. Populate it with the following matrix. This is the model's authority definition; adapt names, not
   structure.

   | Activity | Application Owner | Technical Owner | Security Reviewer | Deployment Engineer | ARB |
   |---|---|---|---|---|---|
   | Raise intake request | **A/R** | C | I | I | I |
   | Provide business justification | **A/R** | I | I | I | C |
   | Confirm licence entitlement | **A** | I | I | I | C |
   | Perform security review | C | C | **A/R** | I | C |
   | Assess technical supportability | C | **A/R** | C | C | C |
   | Approve for production | C | C | C | I | **A/R** |
   | Package and configure the application | I | **A** | I | **R** | I |
   | Classify a change's risk tier | C | **A/R** | C | C | I |
   | Execute a ringed deployment | I | **A** | I | **A/R** | I |
   | Authorise a rollback | C | **A** | I | **R** | I |
   | Own the Application Runbook | I | **A/R** | I | C | I |
   | Answer L2 support escalations | I | **A/R** | I | C | I |
   | Approve retirement | **A/R** | C | C | I | **A** |
   | Sign off the periodic review | **A/R** | C | **C** | I | **A** |

   *A = Accountable (one only), R = Responsible, C = Consulted, I = Informed.*

3. Immediately below the matrix, record **the four escalation rules** verbatim:
   - A request with no named **Application Owner** is returned to the requester, not queued.
   - A change with no named **Technical Owner** cannot be approved at any risk tier.
   - An application handling `Confidential` or `Restricted` data with no completed **Security
     Reviewer** sign-off cannot reach `Approved – production`.
   - A rollback may be authorised by the **Deployment Engineer** without further approval; it is
     always a safe action and must never require a meeting.
4. Have the executive sponsor from R1 approve the document, and record the approval date in it.

---

## Step 4 — Create the four role security groups in Entra ID

These groups make the RACI enforceable — they are what the Intune custom role and the ARB invitation
are bound to.

1. Navigate to `https://entra.microsoft.com` and sign in with an account holding the rights from R4.
2. In the left navigation, expand **Identity**, then click **Groups → All groups**.
3. Click **+ New group** at the top of the blade.
4. Complete the **New Group** form for the first group:
   - **Group type:** `Security`
   - **Group name:** `APPGOV – Application Owners`
   - **Group description:** `Business owners accountable for applications in the managed estate. Membership is maintained by the register custodian.`
   - **Microsoft Entra roles can be assigned to the group:** `No`
   - **Membership type:** `Assigned`
   - **Owners:** add the register custodian.
   - **Members:** add the individuals nominated in R9 for this role.
5. Click **Create**.
6. Repeat steps 3–5 exactly three more times, creating:

   | Group name | Membership type | Description |
   |---|---|---|
   | `APPGOV – Technical Owners` | `Assigned` | `Engineers accountable for application packages, configuration, and runbooks.` |
   | `APPGOV – Security Reviewers` | `Assigned` | `Information Security staff who perform and sign application risk assessments.` |
   | `APPGOV – Deployment Engineers` | `Assigned` | `Operators authorised to execute approved application changes in Intune.` |

7. **Use `Assigned`, not `Dynamic`, for all four.** These are accountability groups whose membership
   is a deliberate governance decision; a dynamic rule would let an HR attribute change silently
   grant or remove application change rights.
8. Verify: still in **Identity → Groups → All groups**, type `APPGOV` in the search box. Exactly four
   groups must be listed. Record each group's **Object Id** (open the group → **Overview** → copy
   **Object Id**) into the RACI document from Step 3.

---

## Step 5 — Create the scope tags and the least-privilege Intune role

This is the step that converts "the deployment engineers own application changes" from a sentence
into a permission boundary.

### 5a — Create the two scope tags

1. Navigate to `https://intune.microsoft.com`.
2. In the left navigation, click **Tenant administration**, then **Roles**, then **Scope (Tags)**.
3. Click **+ Create**.
4. On the **Basics** tab, enter:
   - **Name:** `Scope – App Management – Prod`
   - **Description:** `Applications approved by the Application Review Board for production deployment.`
   Click **Next**.
5. On the **Assignments** tab, click **+ Add groups**, select `APPGOV – Deployment Engineers`, and
   click **Select**. Click **Next**.
6. On the **Review + create** tab, confirm the name reads exactly `Scope – App Management – Prod`,
   then click **Create**.
7. Repeat steps 3–6 to create a second scope tag:
   - **Name:** `Scope – App Management – Pilot`
   - **Description:** `Applications in pilot or under review; not yet approved for production.`
   - **Assignments:** `APPGOV – Deployment Engineers`

### 5b — Create the custom Intune role

1. Still in Intune, navigate to **Tenant administration → Roles → All roles**.
2. Click **+ Create**, then select **Windows role** (this is the standard custom-role wizard;
   despite the label, the permissions you select govern the resources chosen, and Managed apps
   permissions are platform-independent).
3. On the **Basics** tab:
   - **Name:** `Role – App Deployment Engineer`
   - **Description:** `Least-privilege role permitting application creation, update, deletion, and assignment within assigned scope tags only. Does not grant device, compliance, or Conditional Access rights.`
   Click **Next**.
4. On the **Permissions** tab, expand **Managed apps** and set:
   - **Read** → `Yes`
   - **Create** → `Yes`
   - **Update** → `Yes`
   - **Delete** → `Yes`
   - **Assign** → `Yes`
   Then expand **Organization** and set **Read** → `Yes` (required for the console to render).
   **Leave every other permission category set to `No`.** In particular do not grant **Device
   configurations**, **Device compliance policies**, **Security baselines**, or **Remote tasks**.
   Click **Next**.
5. On the **Scope tags** tab, click **+ Select scope tags**, tick `Scope – App Management – Prod` and
   `Scope – App Management – Pilot`, and click **Select**. Click **Next**.
6. On the **Review + create** tab, confirm the name and permissions, then click **Create**.

### 5c — Assign the role

1. Navigate to **Tenant administration → Roles → All roles** and click `Role – App Deployment
   Engineer`.
2. In the role's left menu click **Assignments**, then click **+ Assign**.
3. On the **Basics** tab, enter **Assignment name:** `Assign – App Deployment Engineers – Prod`, and
   an optional description. Click **Next**.
4. On the **Admin Groups** tab, click **+ Select groups to include**, choose
   `APPGOV – Deployment Engineers`, and click **Select**. Click **Next**.
5. On the **Scope Groups** tab, choose the scope of devices/users these admins may act on. For a
   first deployment select **All devices** and **All users** unless you are delegating by business
   unit. Click **Next**.
6. On the **Scope tags** tab, click **+ Select scope tags** and tick both
   `Scope – App Management – Prod` and `Scope – App Management – Pilot`. Click **Next**.
7. On the **Review + create** tab, click **Create**.
8. **Now remove the broad grants.** Navigate to `https://entra.microsoft.com` → **Identity → Roles &
   admins → Roles & admins** → **Intune Administrator** → **Assignments**. Review every standing
   assignment. Anyone whose only need is application work should be removed here and left with
   `Role – App Deployment Engineer` instead. Do this **after** confirming the new role works
   (Section 5, Gate 3) — never before.

---

## Step 6 — Create the deployment ring groups

Ringed deployment is the change-management control that makes rollback cheap. No application may be
assigned directly to *All Users* or *All Devices* under this model.

1. Navigate to `https://entra.microsoft.com` → **Identity → Groups → All groups → + New group**.
2. Create the first ring:
   - **Group type:** `Security`
   - **Group name:** `PILOT – App Ring 1 – Validation`
   - **Group description:** `Ring 1. IT and technical validators. First recipients of every approved application change. Target size 1–2% of the estate.`
   - **Membership type:** `Assigned`
   - **Members:** the endpoint engineering team and the Technical Owners.
   Click **Create**.
3. Repeat for the remaining two rings:

   | Group name | Membership type | Intended population |
   |---|---|---|
   | `PILOT – App Ring 2 – Early Adopters` | `Assigned` | Volunteer business users across every major function. Target 5–10% of the estate. |
   | `PROD – App Ring 3 – Broad` | `Dynamic User` or `Assigned` | The remainder of the estate. |

4. If you make Ring 3 dynamic, on the **New Group** blade set **Membership type** to `Dynamic User`,
   click **Add dynamic query**, switch to the **Rule syntax** editor, and enter a rule that excludes
   the earlier rings — for example:
   ```
   (user.accountEnabled -eq true) and (user.userType -eq "Member")
   ```
   then manage Ring 1 and Ring 2 exclusion at the **assignment** level in Intune (each app's
   assignment lets you add an **excluded group**). Click **Save**, then **Create**.
5. Record all three group **Object Ids** in the RACI document.
6. Define and publish the **ring dwell times** — the minimum time an application must sit in a ring
   before promotion. Add this table to the standards document you create in Step 7:

   | From → To | Minimum dwell | Promotion gate |
   |---|---|---|
   | Ring 1 → Ring 2 | 3 business days | Zero Sev-1/Sev-2 incidents; install success ≥ 95%. |
   | Ring 2 → Ring 3 | 5 business days | Zero Sev-1 incidents; install success ≥ 98%; no open licence question. |

---

## Step 7 — Publish the Application Standards Document

This is the document that makes "approved" a test rather than an opinion.

1. Create a document in your system of record named exactly
   `Application Standards – Enterprise – v1.0`.
2. Include the following six sections. Each must be written so that a reviewer can answer *yes* or
   *no* — avoid "should be considered".

   **Section 1 — Definition of approved.** An application is `Approved – production` only when all of
   the following are true: a named Application Owner and Technical Owner exist in the register; the
   security review is complete and signed; the licence position is `Entitled` or `Free/no licence`; a
   runbook exists and is linked; the package conforms to the naming standard; and an ARB Decision
   Record exists with a decision of `Approved` or `Approved with conditions` (with all conditions
   met).

   **Section 2 — Security review criteria.** The Security Reviewer must record a determination
   against each of: data classification handled; whether the application transmits data outside the
   tenant boundary and to where; authentication method (SSO-capable vs local credentials); whether it
   requires local administrator rights to run; its network egress requirements; vendor security
   posture evidence (a current SOC 2 / ISO 27001 attestation or equivalent, or a documented
   exception); known CVEs at the proposed version; and whether it requires an App Protection Policy
   or an application-control allow-list entry.

   **Section 3 — Licensing and entitlement check.** Record the licence model (per-user, per-device,
   site, free, open-source), the entitlement count held, the count required by the proposed
   assignment, the contract owner, and the renewal date. A proposed deployment that exceeds the
   entitlement count is `Non-compliant` and cannot be approved.

   **Section 4 — Naming standard.** Every application object in Intune must be named:
   ```
   <Vendor> <Product> <Version> – <Platform> – <Ring>
   ```
   For example: `Adobe Acrobat Reader 24 – Win – Ring1`, `Google Chrome 126 – Win – Ring3`,
   `Zoom Workplace 6.1 – macOS – Ring2`. Use the en dash with single spaces. `APPOPS-Validation.ps1`
   tests conformance to exactly this pattern.

   **Section 5 — Supportability bar.** Before production approval an application must have: a
   documented install and uninstall method; a documented rollback method; a named L2 owner; a runbook
   covering the five most likely failure modes; and a vendor support contract or a documented
   acceptance that none exists.

   **Section 6 — Review interval.** Set `Next Review Date` by risk tier: `Tier 4 – Critical` every 6
   months; `Tier 3 – High` every 12 months; `Tier 1 – Low` and `Tier 2 – Moderate` every 24 months. A
   review that lapses moves the application to `Deprecated` until it is re-reviewed.

3. Have the executive sponsor and the Head of Information Security approve the document. Record both
   approval dates.
4. Publish it where every requester can read it **before** raising a request. A standards document
   nobody can find generates the same rework as no standards document.

---

## Step 8 — Stand up the intake workflow

1. Create the intake form. Using Microsoft Forms: navigate to `https://forms.office.com` → **New
   Form** → name it exactly `Application Intake Request Form`. Add these questions, all marked
   **Required** unless stated:

   | # | Question | Type |
   |---|---|---|
   | 1 | Application name, vendor, and version | Text |
   | 2 | Named Application Owner (business accountability) | Text |
   | 3 | Business justification — what problem does this solve, and what happens if we do not deploy it? | Long text |
   | 4 | Has an existing approved application been evaluated for this need? Which, and why is it insufficient? | Long text |
   | 5 | How many users or devices require it? | Number |
   | 6 | Data classification handled | Choice: Public / Internal / Confidential / Restricted |
   | 7 | Licence model and entitlement already held | Text |
   | 8 | Contract or quote reference | Text (optional) |
   | 9 | Required by date, and the driver for that date | Text |
   | 10 | Platforms required | Choice, multiple: Windows / macOS / iOS / Android |
   | 11 | Does it require local administrator rights to install or run? | Choice: Yes / No / Unknown |
   | 12 | Vendor security documentation attached? | File upload (optional) |

2. Route the responses. Open the form → **Responses** tab → the **⋯** menu → **Create a Flow** to
   send each response into a SharePoint list named `Application Intake Queue`, or simply export
   responses to Excel weekly if you have no Power Automate licence. The mechanism matters far less
   than the discipline.
3. Define and publish the **intake SLA**: the register custodian triages every request within **3
   business days** and returns it, tables it for the next ARB, or fast-tracks it under the Tier 1
   pre-approval rule (Step 9).
4. Define the **return criteria** explicitly. A request is returned to the requester — not queued —
   when it lacks a named Application Owner, a business justification, or a licence position. Publish
   these three so returns are not perceived as arbitrary.

---

## Step 9 — Stand up the Application Review Board

1. Create a recurring Outlook meeting named exactly
   `Application Review Board – Enterprise – Fortnightly`.
2. Set the cadence and duration:
   - **Cadence:** every two weeks. Weekly becomes unsustainable; monthly makes IT the bottleneck and
     drives shadow procurement.
   - **Duration:** 60 minutes. If you consistently overrun, the intake gate in Step 8 is too loose.
3. Define **membership**. Invite as **required**: the register custodian (chair), one member of
   `APPGOV – Technical Owners`, one member of `APPGOV – Security Reviewers`, and a Procurement or
   SAM representative. Invite as **optional**: the requesting Application Owner for their item only.
4. Define **quorum** and record it in the standards document: the chair, plus one Technical Owner,
   plus one Security Reviewer. **Without a Security Reviewer present, no application handling
   `Confidential` or `Restricted` data may be approved** — such items are deferred, not waved
   through.
5. Define the four permitted **decisions**. The board must select exactly one per item:
   - `Approved` — proceeds to Ring 1.
   - `Approved with conditions` — proceeds, with the conditions recorded and a named owner and due
     date for each.
   - `Deferred – evidence required` — the specific missing evidence is named, along with who supplies
     it and by when.
   - `Rejected` — with a written rationale. A rejection must always state what would change the
     answer.
6. Define the **evidence pack** required before an item may be tabled. The chair refuses to table
   items lacking any of: the completed intake request; the security review determination against all
   nine criteria in Standards Section 2; the licence position; a proposed risk tier; and a named
   Technical Owner who has confirmed they will take the runbook.
7. Define the **Tier 1 pre-approval (standard change) rule** so the board is not consumed by routine
   work: a version update to an already-approved application, with no change to data handling, no new
   network egress, and no licence change, is **pre-approved** and does not require an ARB slot. It is
   recorded in the ARB Decision Record retrospectively with the reference `ARB-<YYYY>-STD-<NNN>`.
   This one rule typically removes 60–80% of the board's volume.
8. Record every decision in the `ARB Decision Record` list from Step 2 within **1 business day** of
   the meeting. Decisions not recorded within that window are treated as not made.

---

## Step 10 — Publish the change classification matrix and the CAB interface

1. Create a document named exactly `Application Change Classification – Enterprise – v1.0`.
2. Populate it with the four risk tiers:

   | Risk tier | Definition | Approval required | Ring policy | Change window | Rollback authority |
   |---|---|---|---|---|---|
   | `Tier 1 – Low` | Version update to an approved app; no change to data handling, egress, or licence. | Pre-approved (standard change). Technical Owner confirms classification. | Ring 1 → Ring 2 → Ring 3, standard dwell. | Any business day, 09:00–16:00. | Deployment Engineer, unilaterally. |
   | `Tier 2 – Moderate` | New app, Tier 1/2 data only; or a configuration change to an approved app. | ARB approval. | Full ring progression, standard dwell. | Any business day, 09:00–16:00. | Deployment Engineer, unilaterally. |
   | `Tier 3 – High` | App handling `Confidential` data; or any change affecting more than 25% of the estate; or a supersedence that removes an existing app. | ARB approval **and** Security Reviewer sign-off. | Full ring progression, **doubled** dwell times. | Outside core hours; CAB notified. | Deployment Engineer, with Technical Owner informed within 1 hour. |
   | `Tier 4 – Critical` | App handling `Restricted` data; or any change to a business-critical or clinical/regulated application; or a change requiring local admin rights. | ARB approval, Security Reviewer sign-off, **and** CAB approval. | Full ring progression with an explicit written go/no-go gate at each promotion. | Scheduled CAB window only. | Deployment Engineer executes; Technical Owner and CAB chair notified immediately. |

3. Define the **CAB interface** using your answer to R7:
   - If a CAB exists: Tier 1 and Tier 2 changes are registered as **standard/pre-approved** changes
     and consume no CAB agenda time. Tier 3 changes are **notified** to CAB. Tier 4 changes are
     **submitted** to CAB by the change submission deadline, with the ARB Decision Reference quoted
     as the technical approval evidence. Record the CAB's cadence and deadline in this document.
   - If no CAB exists: the ARB holds change authority for all four tiers. Record that explicitly so
     an auditor is not left inferring it.
4. State the **rollback principle** prominently: *a rollback never requires approval.* Any Deployment
   Engineer may roll back any application change at any time. Requiring approval to roll back
   converts a five-minute recovery into a two-hour outage, and it is the most common self-inflicted
   wound in application change management.

---

## Step 11 — Define the support model and the runbook standard

1. Create a document named exactly `Application Support Matrix – Enterprise – v1.0`.
2. Define the tier boundaries in terms of *actions*, not seniority — this is what makes escalation
   decidable at 3am:

   | Tier | Owns | May do | Escalates when |
   |---|---|---|---|
   | **L1 — Service Desk** | First contact, triage, known-error resolution. | Confirm the user is in the correct ring group; confirm the app shows as assigned in the Company Portal; trigger a device sync; walk the user through the documented known-error steps in the runbook. | The app is assigned but not installing; the runbook's known-error steps do not resolve it; or the fault affects more than 3 users. |
   | **L2 — Endpoint Engineering** | Package and deployment faults. | Read Intune install/detection state; inspect device logs; correct assignments; re-issue the package; execute an approved rollback. | The fault is in the application itself rather than its delivery; a code-level defect is suspected; or a licence/entitlement block is found. |
   | **L3 — Vendor / Application Specialist** | The application's own behaviour. | Raise and manage the vendor case; test vendor-supplied fixes in Ring 1. | Never — L3 owns to resolution, with the Technical Owner accountable for the case. |

3. Define **response and resolution targets** per severity and publish them:

   | Severity | Definition | Response | Resolution target |
   |---|---|---|---|
   | Sev 1 | A business-critical application is unavailable to a whole site or function. | 15 minutes | 4 hours (or rollback) |
   | Sev 2 | An approved application fails to install or run for more than 10 users. | 1 hour | 1 business day |
   | Sev 3 | Individual user cannot access an approved application. | 4 hours | 3 business days |
   | Sev 4 | Request, query, or cosmetic issue. | 1 business day | 10 business days |

4. Create the runbook template. Name it exactly `Application Runbook – <Application Name> – v1.0`
   and require these seven sections: (1) application identity — vendor, version, Intune App Id, and
   register link; (2) named owners for all four RACI roles; (3) install and uninstall method; (4)
   detection/verification method — how to confirm it is genuinely present and working; (5) the five
   most likely failure modes with their known-error resolutions, written for L1; (6) the rollback
   procedure with expected duration; (7) vendor support contact, contract reference, and entitlement.
5. Make the runbook a **production gate**: an application cannot move to `Approved – production`
   without a linked runbook. Enforce this in the register by requiring `Runbook Link` to be populated
   before `Lifecycle State` may be set to `Approved – production`.

---

## Step 12 — Stamp governance metadata onto the existing estate

Now make the governance visible inside Intune itself, so an engineer looking at an app can see its
governance state without opening the register.

1. Open `AppEstate-Baseline.csv` from Step 1 in Excel.
2. Add three columns: `GovernedOwner`, `ArbReference`, and `ScopeTagToApply`. For each application,
   populate the Technical Owner's user principal name, the ARB decision reference (use
   `ARB-<YYYY>-LEGACY-<NNN>` for pre-existing applications ratified in bulk), and either
   `Scope – App Management – Prod` or `Scope – App Management – Pilot`.
3. Save the file as `AppEstate-Governance.csv`.
4. **Preview** the changes — the script defaults to `-WhatIf` and writes nothing:
   ```
   powershell -ExecutionPolicy Bypass -File .\APPOPS-Remediation.ps1 -InputCsv .\AppEstate-Governance.csv
   ```
5. Read the preview output carefully. Confirm the app names and the values match your intent.
6. Apply the changes by re-running with `-Apply`:
   ```
   powershell -ExecutionPolicy Bypass -File .\APPOPS-Remediation.ps1 -InputCsv .\AppEstate-Governance.csv -Apply
   ```
   The script writes a structured governance block into each application's **Notes** field and
   applies the named scope tag. It does not change assignments, packages, or any deployment
   behaviour.
7. Spot-check in the console: navigate to **Apps → All apps**, open any application you stamped, and
   click **Properties**. The **Notes** field must show the governance block, and **Scope tags** must
   show the tag you applied.
8. Rename any application that does not conform to the Step 7 naming standard. Do this in
   **Apps → All apps → <app> → Properties → Edit** (next to **App information**) → change **Name** →
   **Review + save**. Renaming an app does not affect existing installs or assignments.

---

## Step 13 — Pilot the model for two full board cycles

Do not roll the model across the whole estate immediately. Run it narrow and prove it.

1. Choose the pilot scope: **one business function** (for example, Finance) **or one application
   family** (for example, all creative-suite applications). Record the choice.
2. Run the model exactly as documented for **two complete ARB cycles** — with a fortnightly cadence,
   four weeks.
3. During the pilot, route **every** new or changed application in scope through the intake form. No
   exceptions, including urgent ones — an urgent request is a Tier 3 or Tier 4 change, not a bypass.
4. At the end of each cycle, run the validation and reporting scripts:
   ```
   powershell -ExecutionPolicy Bypass -File .\APPOPS-Validation.ps1 -CsvPath .\Validation-Cycle1.csv
   powershell -ExecutionPolicy Bypass -File .\APPOPS-Report.ps1 -CsvPath .\Scorecard-Cycle1.csv
   ```
5. Hold a 30-minute retrospective after cycle 2 with the board members. Ask three questions: which
   gate produced the most rework, which evidence requirement was hardest to supply, and where did
   somebody attempt a bypass? Amend the standards document accordingly and increment its version.
6. Only when Section 5's gates pass, proceed to Step 14.

---

## Step 14 — Expand to the whole estate and enter steady state

1. Extend the intake form as the **only** route for new applications tenant-wide. Announce the date,
   and have the executive sponsor from R1 send the announcement — not IT.
2. Bulk-ratify the remaining legacy estate. For each application still lacking owners, the register
   custodian tables a batch at the ARB for ratification with `ARB-<YYYY>-LEGACY-<NNN>` references.
   Applications for which **no owner can be found** are moved to `Deprecated`, communicated with a
   60-day notice, and then retired. This is the step that actually shrinks the estate.
3. Establish the steady-state cadence:

   | Activity | Frequency | Owner |
   |---|---|---|
   | Application Review Board | Fortnightly | Register custodian (chair) |
   | Governance scorecard published (`APPOPS-Report.ps1`) | Monthly | Register custodian |
   | Conformance validation run (`APPOPS-Validation.ps1`) | Monthly | Deployment Engineer |
   | Discovered-apps reconciliation against the register | Quarterly | Technical Owners |
   | Overdue review sweep (`Next Review Date` in the past) | Monthly | Register custodian |
   | Standards document review | Annually | Executive sponsor + Security |

4. Add the scorecard to an existing governance forum's standing agenda — an IT operations review or
   a service management board. Metrics reported nowhere change nothing.
5. Archive the Step 1 baseline alongside the first steady-state scorecard. The delta between them is
   the business case for having done this, and it is what you present at the annual review.
