# Self-Deploy — Identity Modernization with Entra

> **Version 1.0.0** · Category: Entra · Solution code: EKIDMOD

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Self-Deploy: Identity Modernization with Entra

Entra ID Solutions · Self-Deploy (self-guided training)

Modernizing identity — moving from legacy Active Directory / AD FS and per-user MFA to a Zero Trust
Microsoft Entra estate — fails most often not because the technology is hard, but because the team
driving it never internalized the target state. This Self-Deploy teaches identity modernization
on Microsoft Entra: the legacy-to-modern journey, the target-state architecture, and the building
blocks (Conditional Access, Identity Protection, passwordless, identity governance, Global Secure
Access). It is a self-guided training deliverable — concepts, guided hands-on labs, a take-home
runbook, and a knowledge-check — so a competent admin team finishes able to plan and drive the
modernization confidently.

## What this is (and is not)
This is a **training / enablement** package, not an implementation engagement. It teaches the team
how modern Entra identity fits together and rehearses each building block in a safe, pilot-scoped
lab. The labs are deliberately non-destructive: every Conditional Access policy is built in
**report-only**, every change script defaults to a **preview / -WhatIf**, and everything is scoped to
a small **pilot lab group** you create. When the team is ready to implement for real, the kit points
to the dedicated implementation solutions for each building block (see cross-references throughout).

## What you get
- A plain-language **Solution Overview** of the modernization journey and the Entra target-state
  architecture, mapped to the standard deployment model (Assess → Configure → Pilot → Validate → Expand).
- A **Requirements** guide covering the enablement-specific prerequisites (a lab pilot group, sample
  identities, the right modules) — the category-level prerequisites live in the separate global
  requirements file.
- A guided **Implementation** guide: ordered, click-by-click labs across Conditional Access,
  Identity Protection, passwordless, governance, and Global Secure Access, plus migration and
  coexistence patterns (AD FS / hybrid → cloud).
- **Testing** (a knowledge-check and lab-validation procedures) and **Troubleshooting** guides.
- Five lab helpers: read-only discovery, prerequisite validation, a modernization scorecard report,
  a safe pilot lab-setup helper, and a KQL signal pack for sign-in / Identity Protection analysis.
- A take-home **modernization runbook** distilled from the labs.

## The outcome
A team that understands the modern Entra identity target state, has rehearsed each building block
hands-on in a pilot lab, and holds a runbook and knowledge-check to carry the real modernization
forward — with clear pointers to the implementation solutions that execute each step in production.

## Effort
Self-paced. Plan roughly two to four focused days for a small admin team to work through the
concepts and all guided labs in a non-production or pilot-scoped tenant. No production change is
required to complete the kit.


---


# 1. Solution Overview — Self-Deploy: Identity Modernization with Entra

## What this kit is
This is a self-guided **self-deploy**: a training deliverable that teaches an admin team how to
modernize identity on Microsoft Entra. It combines concepts, guided hands-on labs, a take-home
runbook, and a knowledge-check. It is not a production implementation project — it builds the
understanding and muscle memory the team needs before (and while) they drive the real modernization,
and it points to the dedicated implementation solutions for each building block.

## What "identity modernization" means
Identity modernization is the move from a legacy, perimeter-and-password model to a cloud-first Zero
Trust model on Microsoft Entra ID:

- **From** on-premises Active Directory as the center of gravity, AD FS federation, per-user MFA,
  legacy authentication protocols (POP/IMAP/SMTP/older Office), passwords as the primary factor, and
  static group-based access.
- **To** Entra ID as the identity control plane: **Conditional Access** as the policy engine,
  **Identity Protection** feeding risk into those policies, **passwordless / phishing-resistant MFA**
  (FIDO2 passkeys, Windows Hello for Business, certificate-based auth), **identity governance**
  (access packages, access reviews, PIM) for least privilege and lifecycle, and **Global Secure
  Access (GSA)** extending Zero Trust to network access.

The legacy world is not switched off overnight — most organizations run a **coexistence** period
where hybrid sync and modern controls operate side by side. Teaching that coexistence, and the safe
order of moves, is a core purpose of this kit.

## The Entra target-state architecture (the building blocks)
1. **Entra ID directory** — the cloud identity source; users and groups (cloud-only or synchronized
   from AD during coexistence).
2. **Conditional Access (CA)** — the policy engine. Every access decision (who, what app, what
   device, what risk) is evaluated here. Requires Entra ID P1. *Verify current licensing in your tenant.*
3. **Identity Protection** — risk detection (risky users, risky sign-ins) that CA consumes as signal.
   Risk-based CA and the full risk experience require **Entra ID P2**. *Verify in your tenant.*
4. **Passwordless & phishing-resistant authentication** — FIDO2 security keys / passkeys, Windows
   Hello for Business, certificate-based authentication, and Microsoft Authenticator, managed through
   the **Authentication methods** policy.
5. **Identity governance** — entitlement management (access packages), access reviews, and Privileged
   Identity Management (PIM). Governance features (access reviews, entitlement management, PIM)
   require **Entra ID P2 / Entra ID Governance**. *Verify in your tenant.*
6. **Global Secure Access (GSA)** — identity-centric Secure Web Gateway / private access, extending
   Conditional Access to network traffic. Licensing and some capabilities are evolving — *verify
   current availability and licensing in your tenant.*
7. **Break-glass and monitoring** — emergency access accounts excluded from policy, plus sign-in and
   audit logs (optionally streamed to Log Analytics / Microsoft Sentinel) for the KQL analysis in
   this kit.

## The legacy → modern journey (what the team learns to sequence)
1. **Baseline** the current estate — where identities live, what authenticates them, what legacy
   protocols are still in use, MFA registration coverage, and federated domains.
2. **Establish safety** — break-glass accounts, report-only Conditional Access, and pilot scoping.
3. **Introduce modern controls in report-only / pilot** — CA baseline, Identity Protection signals,
   MFA registration campaigns.
4. **Move authentication forward** — from per-user MFA to CA-driven MFA; from passwords toward
   passwordless / phishing-resistant methods.
5. **Layer governance** — access reviews, access packages, and PIM for privileged roles.
6. **Extend Zero Trust to the network** — Global Secure Access.
7. **Retire legacy** — decommission AD FS / legacy auth once coexistence is proven.

## The standard deployment model
Every solution in this catalog follows the same shape, and this kit teaches the team to apply it to
each building block:

> **Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — run the read-only discovery and score the current posture.
- **Configure** — build the control in report-only / preview, scoped to the lab pilot group.
- **Pilot** — apply it to the small pilot lab group only.
- **Validate** — confirm the intended effect (What-If, sign-in logs, the knowledge-check) with
  explicit pass/fail gates.
- **Expand** — only after validation, widen scope in staged rings.

## Scope of this kit
- **In scope:** teaching the modernization journey and target-state architecture; guided, pilot-scoped
  labs for CA, Identity Protection, passwordless, governance, and GSA; migration/coexistence patterns
  (AD FS / hybrid → cloud); a take-home runbook and a knowledge-check; read-only discovery, validation,
  reporting, and KQL analysis helpers.
- **Out of scope (by design — use the dedicated implementation solutions):** production rollout of any
  single building block at scale. This kit deliberately does **not** duplicate the deep
  implementation guides. For production work, cross-reference:
  - **Zero Trust Conditional Access baseline** (ENTZTCA) — the full CA baseline rollout.
  - **Entra Passwordless / FIDO2 passkey rollout** (ENTPASSKEY) — production passwordless.
  - **Entra ID Governance — PIM & Access Reviews / Entitlement** (ENTPIM / ENTIGA) — governance at scale.
  - **Hybrid Identity with AD & Entra Connect** (HYBID) and the **Hybrid Identity Self-Deploy**
    (EKHYBID) — the sync / coexistence layer.
  - **Enterprise App & Service Principal Governance** and the **SAML App Factory** — app modernization.
  - **Global Secure Access** solution — production GSA.
- **Not covered / deferred to the customer:** regulatory, records, and legal determinations;
  data-classification decisions; and production change-approval sign-off. This kit provides the
  technical understanding and controls, not those decisions.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) and **Microsoft 365 admin center**
  for portal labs.
- **Microsoft Graph PowerShell SDK** (`Microsoft.Graph`) for read-only discovery, validation, and the
  safe lab-setup helper — using delegated, least-privilege scopes.
- **Az PowerShell** (optional) where Azure / Log Analytics context is used.
- **Log Analytics / Microsoft Sentinel** (optional) for running the KQL signal pack against
  `SigninLogs` and related tables — *requires diagnostic settings to export Entra logs; verify in your
  tenant.*


---


# 2. Requirements — Self-Deploy: Identity Modernization with Entra

The **category-level** prerequisites (an Entra ID tenant, P1/P2 licensing, administrative roles,
break-glass accounts, healthy AD, UPN/domain hygiene, network access) are documented once in
**`global-requirements-entra-id-solutions.md`** — confirm those first; they are not repeated here.

Below are the prerequisites specific to running this **self-deploy** and its labs. Because this is
training, the strong recommendation is to run the labs in a **non-production tenant** or, if you must
use production, strictly against the small **pilot lab group** you create, with every control in
**report-only / preview**.

Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. A lab pilot group
Description: A dedicated Entra security group named **`Identity Modernization – Pilot – Lab`** holding
only a handful of lab / test identities.
Why required: Every guided lab targets this group so no policy or method change can affect real users.
It is the "Pilot" scope in the deployment model.
How to verify: Entra admin center → **Groups → All groups**; confirm the group exists and contains
only lab members. Or run `EKIDMOD-Validate.ps1`, which checks for it.
How to implement if missing: Create it with `EKIDMOD-LabSetup.ps1` (preview-first, `-WhatIf` by
default), or manually: **Groups → New group** → Security → name `Identity Modernization – Pilot – Lab`.

## R2. Sample / test identities
Description: Two to five non-privileged **cloud-only** test users (for example
`labuser1@contoso.onmicrosoft.com`) to exercise the labs.
Why required: Labs assign policies, methods, and access packages to real principals; using disposable
test users keeps live users untouched and lets you safely observe enforcement.
How to verify: Entra → **Users**; confirm the test users exist and are members of the pilot group.
How to implement if missing: Create them with `EKIDMOD-LabSetup.ps1` (preview-first), or **Users →
New user → Create new user**. Do not use real employee accounts.

## R3. Microsoft Graph PowerShell SDK
Description: The `Microsoft.Graph` PowerShell module (v2+) installed on the operator workstation.
Why required: The discovery, validation, reporting, and lab-setup helpers use Graph cmdlets.
How to verify: `Get-Module Microsoft.Graph -ListAvailable` returns a v2+ module; `EKIDMOD-Validate.ps1`
also reports this.
How to implement if missing: `Install-Module Microsoft.Graph -Scope CurrentUser`. Consent to the
least-privilege read scopes when prompted (for example `Directory.Read.All`, `Policy.Read.All`,
`AuditLog.Read.All`, `UserAuthenticationMethod.Read.All`).

## R4. Feature licensing awareness (P1 / P2 / Governance / GSA / Verified ID)
Description: Awareness of which building blocks need which license, before the corresponding lab.
Why required: Several labs use features that require **Entra ID P1** (Conditional Access), **Entra ID
P2** (risk-based CA, Identity Protection, PIM), **Entra ID Governance** (access reviews, entitlement
management), **Global Secure Access**, or **Verified ID**. Some capabilities are in preview. *Do not
assume availability — verify current licensing and preview status in your own tenant.*
How to verify: M365 admin center → **Billing → Licenses**; and the feature blade will indicate if a
capability is unavailable or preview. `EKIDMOD-Validate.ps1` reports detected service plans.
How to implement if missing: Assign the required license to your lab users, or skip that lab and read
its concept section. Trial licenses are acceptable for training — *verify eligibility in your tenant.*

## R5. (Optional) Log Analytics / Microsoft Sentinel with Entra diagnostic settings
Description: An Entra **Diagnostic setting** streaming `SignInLogs` / `AuditLogs` to a Log Analytics
workspace (optionally onboarded to Microsoft Sentinel).
Why required: Only for the **KQL analysis lab** and `EKIDMOD-Signals.kql`. The rest of the kit works
without it.
How to verify: Entra → **Monitoring → Diagnostic settings** shows a setting sending logs to a
workspace; the workspace has recent `SigninLogs`.
How to implement if missing: Entra → **Diagnostic settings → Add** → select `SignInLogs`,
`AuditLogs` → send to a Log Analytics workspace. *A workspace and log retention may incur Azure cost —
verify in your subscription.* If unavailable, read the KQL lab as concept only.

## R6. (Optional) A coexistence / hybrid reference
Description: Read access to any existing hybrid sync configuration (Entra Connect / Cloud Sync) or
federated (AD FS) domains.
Why required: Only for the **migration & coexistence** lab, so the team can inspect the real starting
point (federated domains, sync engine) without changing it.
How to verify: Entra → **Identity → Settings → Domain names** shows domain authentication type
(Managed vs Federated); `EKIDMOD-Discovery.ps1` reports federated domains.
How to implement if missing: Not required — the coexistence lab can be completed conceptually with
the provided patterns if no hybrid environment exists.


---


# Global Requirements — Entra ID Solutions (category-level)

These requirements apply to every solution in the Entra ID Solutions category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying any identity solution. Each entry: Description / Why / Verify / Implement-if-missing.

> The identity plane is high risk. A mistake here breaks sign-in for everyone, so every change is
> staged and a break-glass account is kept ready before you touch anything.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID tenant.
Why: It is the cloud identity backbone every other identity service builds on.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 or Azure subscription, which provisions a tenant.

## G2. Entra ID licensing (P1, P2 where noted)
Description: Microsoft Entra ID P1 (or P2 for risk-based and PIM features).
Why: Hybrid features such as seamless sign-in, password writeback, and Conditional Access require P1+.
Verify: M365 admin center -> `Billing -> Licenses`; confirm Entra ID P1/P2 (often bundled in M365 E3/E5 or EMS).
Implement: Assign M365 E3/E5, EMS E3/E5, or standalone Entra ID P1/P2.

## G3. Administrative roles
Description: Hybrid Identity Administrator and Global Administrator for the operator.
Why: Configuring directory synchronization and authentication methods needs these elevated roles.
Verify: Entra -> `Roles and administrators`; confirm `Hybrid Identity Administrator` (and a Global Administrator for the one-time first-sync consent).
Implement: Assign `Hybrid Identity Administrator`; reserve `Global Administrator` for tenant-wide and first-sync changes.

## G4. Break-glass (emergency access) accounts
Description: At least two cloud-only emergency access accounts, excluded from Conditional Access and MFA-broad policies.
Why: If sync, federation, or an auth-method change locks out admins, break-glass accounts get you back in.
Verify: Entra -> `Users`; confirm two cloud-only accounts (`@onmicrosoft.com`) with strong stored credentials and documented use.
Implement: Create two cloud-only Global Administrator accounts; exclude them from policies; store credentials securely and monitor sign-ins.

## G5. Healthy on-premises Active Directory
Description: A functional AD forest/domain with healthy replication and DNS.
Why: Synchronization reads from AD; replication or DNS faults corrupt or stall the sync.
Verify: Run `dcdiag` and `repadmin /replsummary` on a domain controller with no errors; run `HYBID-Discovery.ps1`.
Implement: Resolve AD replication, DNS, and time-sync issues before synchronizing.

## G6. An Entra Connect host server
Description: A domain-joined Windows Server (2016+), patched, for Microsoft Entra Connect Sync (or a lightweight host with the Cloud Sync agent).
Why: Connect Sync runs as a service on this host and must reach both AD and Entra ID.
Verify: A supported, domain-joined server with TLS 1.2, .NET, and PowerShell available; run `HYBID-Discovery.ps1`.
Implement: Provision a dedicated server (not a domain controller for production), patch it, and enable TLS 1.2.

## G7. UPN / domain hygiene
Description: User principal names use a public, verified, routable domain (not `.local`).
Why: A non-routable UPN suffix produces sign-in problems and `onmicrosoft.com` fallbacks in the cloud.
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; AD UPN suffixes match it; run `HYBID-Discovery.ps1`.
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD and update user UPNs.

## G8. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS (443) from the Connect host to Entra ID, plus required Microsoft 365 service URLs.
Why: Synchronization, authentication-agent traffic, and tokens depend on these endpoints.
Verify: From the Connect host, reach `https://login.microsoftonline.com` and the Microsoft 365 published URL/IP ranges.
Implement: Allow the Microsoft 365 / Entra service URLs and IP ranges through the proxy/firewall.

---
The deployment model (all solutions): Assess -> Configure -> Pilot -> Validate -> Expand.


---


# 3. Implementation (Guided Labs) — Self-Deploy: Identity Modernization with Entra

This is the hands-on core of the kit. Work through the labs **in order**; each maps to a stage of the
deployment model (**Assess → Configure → Pilot → Validate → Expand**). Every object you create uses
the naming convention **`<Purpose> – <Scope> – <Stage>`** and is reused by name in later labs, the
testing guide, and the scripts. All labs are **pilot-scoped and non-destructive** — Conditional
Access is report-only, change scripts default to `-WhatIf`, and everything targets the pilot lab
group. **Do not enforce any policy against real users during the kit.**

Portal paths below are current at authoring time; Microsoft may relabel blades — *verify the current
navigation in your tenant.*

---

## Lab 0 — Set up the lab (Assess + safety)

**Goal:** create the pilot scope and confirm safety before touching any control.

1. Confirm two **break-glass** accounts exist and are excluded from broad policies (see global
   requirements G4). Never scope a lab policy to include them.
2. Open PowerShell and run the read-only assessment:
   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser   # if not already installed
   .\EKIDMOD-Discovery.ps1
   ```
   Read the output: legacy authentication usage, per-user MFA vs Conditional Access state,
   authentication methods registered, and federated domains. This is your **baseline**.
3. Create the pilot group and sample users (preview first, then commit):
   ```powershell
   .\EKIDMOD-LabSetup.ps1               # -WhatIf preview by default: shows what it would create
   .\EKIDMOD-LabSetup.ps1 -Commit       # actually creates the group + sample users
   ```
   This creates the security group **`Identity Modernization – Pilot – Lab`** and sample cloud users
   (`labuser1…`), and adds the users to the group.
4. Validate the lab prerequisites:
   ```powershell
   .\EKIDMOD-Validate.ps1
   ```
   Confirm it reports: pilot group present, sample users present, Graph module OK, and detected
   licensing (P1/P2/Governance/GSA). Resolve any FAIL before continuing.

**Gate:** discovery baseline captured, pilot group + sample users exist, validation passes.

---

## Lab 1 — Conditional Access as the policy engine (report-only)

**Goal:** understand and build the first modern access policy without enforcing it.

*Concept recap:* CA replaces per-user MFA and legacy rules with signal-driven policy. In modernization
you always introduce CA in **Report-only** first, read the impact in sign-in logs, then enforce in
rings. Requires Entra ID P1 — *verify.*

1. Entra admin center → **Protection → Conditional Access → Policies → + New policy**.
2. Name it exactly: **`CA – Pilot – Require MFA (Report-only)`**.
3. **Users**: Include → **Select users and groups** → the group `Identity Modernization – Pilot – Lab`.
   Exclude your break-glass accounts.
4. **Target resources**: Include → **All cloud apps** (for the lab).
5. **Grant**: **Grant access** → check **Require multifactor authentication**.
6. **Enable policy**: set to **Report-only** (not On).
7. **Create**.
8. Build a second policy to teach legacy-auth blocking, also report-only:
   **`CA – Pilot – Block Legacy Auth (Report-only)`** → Users = pilot group → Conditions → **Client
   apps** → select **Exchange ActiveSync clients** and **Other clients** → Grant = **Block** →
   **Report-only** → **Create**.

**Gate:** two report-only policies exist, scoped only to the pilot group, break-glass excluded.
(Validate in the Testing guide via the What-If tool and the report-only sign-in workbook.)
For production rollout, hand off to **Zero Trust Conditional Access baseline (ENTZTCA)**.

---

## Lab 2 — Identity Protection as risk signal

**Goal:** see how risk becomes a Conditional Access signal. Requires Entra ID P2 — *verify.*

1. Entra → **Protection → Identity Protection → Overview**. Review **Risky users** and **Risky
   sign-ins** reports (these are read-only investigations).
2. Understand the two risk-based policy shapes (do **not** enable them against real users in the lab):
   - **Sign-in risk** → require MFA.
   - **User risk** → require secure password change.
3. Build a **report-only** risk-based CA policy to observe the pattern:
   Entra → **Protection → Conditional Access → + New policy** → name
   **`CA – Pilot – Sign-in Risk MFA (Report-only)`** → Users = pilot group (exclude break-glass) →
   Conditions → **Sign-in risk** → select **High, Medium** → Grant = **Require multifactor
   authentication** → **Report-only** → **Create**.
4. If P2 is not present, read this lab as concept only and note it in the runbook.

**Gate:** the risk-based report-only policy exists; the team can explain how Identity Protection risk
feeds CA. Production work → **Entra Identity Protection / Advanced Conditional Access** solution.

---

## Lab 3 — Passwordless & phishing-resistant authentication

**Goal:** enable a modern authentication method for the pilot group and register it.

*Concept recap:* the modernization endgame is phishing-resistant, passwordless sign-in (FIDO2
passkeys, Windows Hello for Business, certificate-based auth). You enable methods centrally and scope
them to the pilot group first.

1. Entra → **Protection → Authentication methods → Policies**.
2. Select **FIDO2 security key** (passkey) → **Enable** = Yes → **Target** = **Select groups** → add
   `Identity Modernization – Pilot – Lab` → **Save**. (Optionally also enable **Microsoft
   Authenticator** passkeys / passwordless for the same group.)
3. Have a pilot lab user register a passkey at **`https://aka.ms/mysecurityinfo`** (or Windows Hello
   for Business on a test device).
4. Note: FIDO2 / passkey capabilities and platform support evolve and some options are in preview —
   *verify current availability in your tenant.*

**Gate:** a phishing-resistant method is enabled and scoped to the pilot group, and at least one lab
user has registered it. Production rollout → **Entra Passwordless / FIDO2 passkey rollout (ENTPASSKEY)**.

---

## Lab 4 — Identity governance (least privilege & lifecycle)

**Goal:** rehearse access reviews, an access package, and PIM at pilot scope. Governance features
require **Entra ID P2 / Entra ID Governance** — *verify.*

1. **Access review (lab):** Entra → **Identity governance → Access reviews → + New access review** →
   name **`Access Review – Pilot – Lab`** → review membership of the group
   `Identity Modernization – Pilot – Lab` → reviewer = yourself → duration a few days → set decisions
   to **manual** (no auto-apply in the lab) → **Create**.
2. **Access package (lab):** Entra → **Identity governance → Entitlement management → Access
   packages → + New access package** → name **`Access Package – Pilot Apps – Lab`** → add a resource
   the pilot group can request (for example a test group or app) → policy: who can request = the
   pilot group → **Create**. Have a lab user request it to see the request/approval flow.
3. **PIM (lab):** Entra → **Identity governance → Privileged Identity Management → Microsoft Entra
   roles → Assignments**. Inspect an existing eligible assignment and the activation experience
   (read-only exploration). Do **not** change production role assignments in the lab.

**Gate:** an access review and an access package exist at pilot scope; the team can explain
eligible-vs-active roles in PIM. Production work → **Entra ID Governance — PIM & Access Reviews /
Entitlement (ENTPIM / ENTIGA)**.

---

## Lab 5 — Global Secure Access (extend Zero Trust to the network)

**Goal:** understand identity-centric network access. GSA licensing/capabilities are evolving — *verify
availability in your tenant; treat as concept-only if not licensed.*

1. Entra → **Global Secure Access**. Review **Get started** and the two pillars: **Internet access**
   (Secure Web Gateway) and **Private access** (Zero Trust Network Access to internal apps).
2. If enabled in your tenant, create a lab traffic-forwarding profile named **`GSA – Pilot – Lab`**
   and observe how Conditional Access can now apply to network traffic (do not enforce for real users).
3. If not enabled, read the concept and record in the runbook where GSA fits (after CA + Identity
   Protection are established).

**Gate:** the team can explain how GSA extends Conditional Access to network access. Production work →
the **Global Secure Access** solution.

---

## Lab 6 — Migration & coexistence patterns (AD FS / hybrid → cloud)

**Goal:** learn the safe order to retire legacy without breaking sign-in. Read-only inspection only.

1. Inspect domain authentication types: Entra → **Identity → Settings → Domain names**. Note any
   **Federated** domains (AD FS) vs **Managed** (cloud-authenticated). `EKIDMOD-Discovery.ps1` also
   lists federated domains.
2. Learn the coexistence sequence (do not execute against production here):
   - Ensure **hybrid sync** is healthy (cross-reference the **Hybrid Identity Self-Deploy —
     EKHYBID** and **HYBID** implementation solution).
   - Move authentication from **federation → cloud auth** (Password Hash Sync / Pass-through Auth)
     using **staged rollout** to a pilot group before converting the domain.
   - Convert the domain from **Federated → Managed** only after staged rollout validates.
   - Retire the AD FS farm once no reliance remains.
3. Record the customer-specific coexistence plan in the take-home runbook (see the Testing guide).

**Gate:** the team can sequence a federation-to-cloud migration and name the safe rollback points.

---

## Lab 7 — Score and report the modernization posture

**Goal:** turn discovery into a shareable scorecard and (optionally) analyze sign-in signals.

1. Generate the scorecard:
   ```powershell
   .\EKIDMOD-Report.ps1 -OutputPath .\EKIDMOD-Scorecard
   ```
   This writes a CSV and an HTML summary scoring the estate across the building blocks (legacy auth,
   MFA/passwordless coverage, CA posture, governance, federated domains).
2. (Optional) If Log Analytics / Sentinel is available, open **Logs** and run queries from
   **`EKIDMOD-Signals.kql`** — legacy-auth sign-ins, risky sign-ins, CA gaps, passwordless adoption.

**Gate:** a scorecard is produced; the team can read it and prioritize the next real modernization step.

---

## Wrap-up
- Complete the **knowledge-check** and finalize the **take-home runbook** (both in `05-testing.md`).
- Optionally tear down lab objects: re-run `EKIDMOD-LabSetup.ps1 -Remove` (preview first) to delete
  the pilot group and sample users you created.


---


# 5. Testing, Knowledge-Check & Take-Home Runbook — Self-Deploy: Identity Modernization with Entra

Because this is an self-deploy, "testing" means two things: **validating the labs worked** and
**confirming the team learned** (a knowledge-check). This guide also assembles the **take-home
runbook** the team keeps after the kit. Reference the scripts by name throughout.

## Part A — Lab validation procedures

### V1. Lab environment (Lab 0)
- Run `EKIDMOD-Validate.ps1`. **Pass:** pilot group `Identity Modernization – Pilot – Lab` present,
  sample users present and in the group, Graph module OK, licensing detected.
- Run `EKIDMOD-Discovery.ps1`. **Pass:** a baseline is printed (legacy auth, MFA state, methods,
  federated domains) with no script errors.

### V2. Conditional Access report-only (Labs 1–2)
- Entra → **Protection → Conditional Access → Policies**; confirm `CA – Pilot – Require MFA
  (Report-only)`, `CA – Pilot – Block Legacy Auth (Report-only)`, and `CA – Pilot – Sign-in Risk MFA
  (Report-only)` all show state **Report-only** and are scoped to the pilot group with break-glass
  excluded. **Pass:** all three present and report-only.
- Use the **What-If** tool: Entra → **Conditional Access → Policies → What If** → select a pilot lab
  user → evaluate. **Pass:** the report-only policies show as "would apply".
- Sign in as a pilot lab user, then review **Conditional Access → Insights and reporting (report-only
  workbook)**. **Pass:** the sign-in appears with the report-only result — proving impact is visible
  *before* enforcement.

### V3. Passwordless (Lab 3)
- Entra → **Authentication methods → Policies**; confirm FIDO2/passkey enabled and targeted at the
  pilot group. Have a lab user complete registration at `https://aka.ms/mysecurityinfo`. **Pass:** the
  method is registered for at least one lab user (visible under the user's **Authentication methods**).

### V4. Governance (Lab 4)
- Confirm `Access Review – Pilot – Lab` exists and is in progress, and `Access Package – Pilot Apps –
  Lab` exists with a request policy. **Pass:** both present; a lab user can request the access package.

### V5. Scorecard (Lab 7)
- Run `EKIDMOD-Report.ps1 -OutputPath .\EKIDMOD-Scorecard`. **Pass:** CSV + HTML produced and open
  cleanly, showing per-building-block scores.
- (Optional) Run two or three queries from `EKIDMOD-Signals.kql` in Log Analytics. **Pass:** queries
  return rows (or a clean empty result) without syntax errors.

## Part B — Knowledge-check (the team should be able to answer)
1. Name the seven building blocks of the Entra target-state architecture and which license each needs.
2. Why is every Conditional Access policy introduced in **report-only** first? Where do you read the
   impact before enforcing?
3. What is the difference between **sign-in risk** and **user risk** in Identity Protection, and how
   does each map to a Conditional Access grant?
4. Order the safe steps to migrate a **federated** domain to **cloud authentication**. What is the
   rollback point, and what role does **staged rollout** play?
5. In governance, explain **eligible vs active** role assignments in PIM, and when you would use an
   **access package** instead of direct group membership.
6. Where does **Global Secure Access** fit in the modernization sequence, and why after CA + Identity
   Protection?
7. Why must **break-glass** accounts be excluded from the policies you build, and how are they
   monitored?

*(Suggested pass mark: the team answers 6 of 7 without notes.)*

## Part C — Take-home runbook (fill in during the kit)
Assemble a one-page-per-section runbook the team keeps. Capture, for your tenant:

- **Baseline** — the `EKIDMOD-Discovery.ps1` output and `EKIDMOD-Report.ps1` scorecard (dated).
- **Break-glass** — the two accounts, where credentials are stored, and who monitors sign-ins.
- **CA rollout plan** — the report-only policies built, and the ring plan to enforce them
  (pilot → dept → all), with each exclusion.
- **Identity Protection** — the risk policies to enforce and thresholds chosen.
- **Passwordless plan** — methods to enable and the registration campaign approach.
- **Governance plan** — which roles go into PIM, which access is packaged, review cadence.
- **GSA plan** — when and where GSA is introduced.
- **Coexistence / legacy retirement** — the federation-to-cloud sequence and AD FS decommission
  criteria.
- **Hand-offs** — which implementation solution executes each production step (ENTZTCA, ENTPASSKEY,
  ENTPIM/ENTIGA, HYBID/EKHYBID, GSA, app-governance).

A completed runbook + a passed knowledge-check = the kit's success criteria.


---


# 6. Troubleshooting — Self-Deploy: Identity Modernization with Entra

Common failures while working the labs, as **symptom → cause → fix**. These are lab-scoped issues;
production troubleshooting for each building block lives in that block's implementation solution.

## Scripts

### `Connect-MgGraph` fails or prompts endlessly
- **Symptom:** the discovery/validation/report scripts cannot connect to Graph.
- **Cause:** the `Microsoft.Graph` module is missing/old, or consent to the read scopes was declined.
- **Fix:** `Install-Module Microsoft.Graph -Scope CurrentUser`; re-run and **accept** the requested
  read scopes (e.g. `Directory.Read.All`, `Policy.Read.All`, `AuditLog.Read.All`,
  `UserAuthenticationMethod.Read.All`). Confirm with `Get-MgContext`.

### "Insufficient privileges" running a read script
- **Symptom:** cmdlets return authorization errors.
- **Cause:** the signed-in operator lacks a directory-read role, or admin consent is required for a scope.
- **Fix:** sign in with an account holding at least a reader role (e.g. Global Reader / Security
  Reader). For scopes needing admin consent, have a Global Administrator consent once.

### `EKIDMOD-LabSetup.ps1` "made no changes"
- **Symptom:** the script reports what it *would* do but nothing is created.
- **Cause:** this is expected — it defaults to `-WhatIf` preview.
- **Fix:** re-run with `-Commit` to create the pilot group + sample users (or `-Remove` to tear down).

### `EKIDMOD-Validate.ps1` reports the pilot group missing after setup
- **Symptom:** validation FAILs on the pilot group right after creating it.
- **Cause:** directory replication / caching delay, or the group name does not match exactly.
- **Fix:** wait 1–2 minutes and re-run; confirm the group is named exactly
  `Identity Modernization – Pilot – Lab` (en dash, not hyphen, matters for name matching).

## Conditional Access labs

### A report-only policy is not showing any impact in logs
- **Symptom:** the report-only workbook shows nothing for the policy.
- **Cause:** no pilot user has signed in since the policy was created, or the scope excludes them.
- **Fix:** sign in as a pilot lab user, wait a few minutes for sign-in logs, then re-check
  **Conditional Access → Insights and reporting**. Confirm the pilot group is *included*.

### Legacy-auth block policy seems to do nothing
- **Symptom:** the "Block Legacy Auth (Report-only)" policy never matches.
- **Cause:** no legacy-auth sign-ins occurred, or the client-app conditions were not selected.
- **Fix:** confirm **Conditions → Client apps** has *Exchange ActiveSync* and *Other clients* checked.
  Legacy auth only matches when a legacy client actually connects; use `EKIDMOD-Signals.kql` to find
  real legacy-auth sign-ins.

### Accidentally set a lab policy to "On"
- **Symptom:** a pilot user is unexpectedly prompted/blocked.
- **Cause:** the policy was enabled instead of left report-only.
- **Fix:** set it back to **Report-only** immediately. This is why labs are pilot-scoped and
  break-glass is excluded — a mistake affects only lab users, and break-glass restores admin access.

## Identity Protection / licensing

### Risk reports or risk-based CA are unavailable / greyed out
- **Symptom:** Identity Protection blades or the sign-in/user-risk conditions are not selectable.
- **Cause:** the tenant/lab users lack **Entra ID P2**. Some features are preview.
- **Fix:** assign P2 to the lab users, or complete the lab as concept-only and note it in the runbook.
  *Verify current licensing and preview status in your tenant.*

## Passwordless

### A lab user cannot register a passkey / FIDO2 key
- **Symptom:** the method is missing from the security-info page.
- **Cause:** the method is not enabled for the pilot group, or the platform/browser is unsupported, or
  the capability is in preview.
- **Fix:** confirm **Authentication methods → Policies → FIDO2** is Enabled and targeted at the pilot
  group; use a supported browser/OS. *Verify current passkey availability in your tenant.*

## Governance

### Access review or access package options are missing
- **Symptom:** Identity Governance blades are unavailable.
- **Cause:** governance features require **Entra ID P2 / Entra ID Governance**.
- **Fix:** assign the governance license to lab users, or read the lab as concept-only. *Verify.*

## Global Secure Access / KQL

### Global Secure Access is not available
- **Symptom:** the GSA blade shows onboarding only, or capabilities are locked.
- **Cause:** GSA is not enabled/licensed in the tenant; some capabilities are preview.
- **Fix:** treat Lab 5 as concept-only and record where GSA fits in the runbook. *Verify availability.*

### KQL queries return nothing or error on table not found
- **Symptom:** `SigninLogs` (or similar) is unknown, or queries are empty.
- **Cause:** Entra diagnostic settings are not exporting logs to the Log Analytics workspace, or the
  time range predates log collection.
- **Fix:** configure Entra → **Diagnostic settings** to send `SignInLogs`/`AuditLogs` to the
  workspace; widen the query time range; confirm you are querying the right workspace.


---


# 7. Best Practices & Where to Go Next — Self-Deploy: Identity Modernization with Entra

## Running the kit cleanly
- **Train in a lab, not in production.** Use a non-production tenant if you have one. If you must use
  production, keep every control **report-only / preview** and scoped only to
  `Identity Modernization – Pilot – Lab`. Never scope a lab policy to all users.
- **Break-glass first, always.** Confirm two excluded emergency-access accounts before building any
  policy, and re-confirm they are excluded from every lab policy.
- **Preview before commit.** The change helper (`EKIDMOD-LabSetup.ps1`) defaults to `-WhatIf`; read
  the preview, then run with `-Commit`. Tear down with `-Remove` (preview first) when finished.
- **One building block at a time.** Work the labs in order; do not stack multiple new controls on the
  pilot group at once, or you cannot attribute an effect to a cause.
- **Least-privilege Graph scopes.** Consent only to the read scopes the scripts request; use a
  non-privileged operator identity for discovery/reporting.

## Modernization principles the team should carry forward
- **Report-only → pilot → rings → all.** Every real change follows the same staged path with pass/fail
  gates; this is the deployment model (**Assess → Configure → Pilot → Validate → Expand**) applied to
  each building block.
- **Signal-driven, not rule-sprawl.** Prefer a small number of well-scoped Conditional Access policies
  driven by risk and device signals over many overlapping legacy rules.
- **Phishing-resistant is the destination.** Treat passwordless / FIDO2 / Windows Hello for Business as
  the target, with legacy MFA as a stepping stone, not the finish line.
- **Least privilege by default.** Put privileged roles behind PIM (eligible, time-bound, approved) and
  govern access with reviews and access packages, not standing membership.
- **Coexist deliberately, retire legacy on evidence.** Keep hybrid sync healthy through the transition;
  convert federated domains to cloud auth via staged rollout; decommission AD FS only once nothing
  depends on it.
- **Measure.** Re-run the discovery and scorecard on a cadence so modernization progress is visible and
  defensible.
- **Defer the decisions that are not yours.** Regulatory, records, legal, data-classification, and
  production change-approval calls belong to the customer's compliance / security / operations
  functions — the kit supplies the technical controls, not those determinations.

## Where to go next (adjacent catalog areas)
When the team is ready to implement in production, hand each building block to its dedicated solution:

- **Conditional Access baseline** → *Zero Trust Conditional Access baseline* (ENTZTCA).
- **Identity Protection / risk-based CA** → *Entra Identity Protection & Advanced Conditional Access*.
- **Passwordless** → *Entra Passwordless / FIDO2 passkey rollout* (ENTPASSKEY).
- **Governance** → *Entra ID Governance — PIM & Access Reviews / Entitlement* (ENTPIM / ENTIGA).
- **Hybrid / coexistence** → *Hybrid Identity with AD & Entra Connect* (HYBID) and the
  *Self-Deploy — Hybrid Identity* (EKHYBID).
- **Application modernization** → *Enterprise App & Service Principal Governance* and the
  *SAML App Factory*.
- **Network Zero Trust** → the *Global Secure Access* solution.
- **Verifiable credentials** → the *Entra Verified ID* solution.

Continue the enablement track with the other Entra self-deploys (Identity Fundamentals, MFA &
Conditional Access, Hybrid Identity) to round out the team's coverage.


---


# 8. Deliverables Summary — Self-Deploy: Identity Modernization with Entra

## Documentation (source guides)
1. **executive-summary.md** — what the kit is, the training outcome, the boundary, and the effort.
2. **01-solution-overview.md** — concepts: the legacy→modern journey, the Entra target-state
   architecture (the building blocks), scope, out-of-scope, and the deployment model.
3. **02-requirements.md** — enablement-specific prerequisites (lab pilot group, sample identities,
   Graph SDK, licensing awareness, optional Log Analytics) with verify / implement-if-missing. The
   category-level prerequisites are in `global-requirements-entra-id-solutions.md`.
4. **03-implementation.md** — the guided hands-on labs (0–7): CA report-only, Identity Protection,
   passwordless, governance, Global Secure Access, migration & coexistence, and scoring — every object
   named and reused.
5. **05-testing.md** — lab-validation procedures, the knowledge-check, and the take-home runbook.
6. **06-troubleshooting.md** — symptom → cause → fix for the common lab failures.
7. **07-best-practices.md** — clean-lab guidance, modernization principles, and where to go next.
8. **08-deliverables-summary.md** — this file.

Plus the category file **global-requirements-entra-id-solutions.md** (shared prerequisites).

## Scripts / lab helpers (5)
1. **EKIDMOD-Discovery.ps1** — read-only baseline of the modernization posture (legacy auth usage,
   per-user MFA vs Conditional Access, registered authentication methods, federated domains).
2. **EKIDMOD-Validate.ps1** — read-only check that the lab prerequisites are met (pilot group, sample
   users, Graph module, detected licensing).
3. **EKIDMOD-Report.ps1** — modernization scorecard exported to CSV + HTML across the building blocks.
4. **EKIDMOD-LabSetup.ps1** — safe lab-setup helper that creates/removes the pilot group and sample
   users; **preview / -WhatIf by default**, `-Commit` to apply, `-Remove` to tear down.
5. **EKIDMOD-Signals.kql** — KQL query pack for Log Analytics / Microsoft Sentinel (legacy-auth
   sign-ins, risky sign-ins, Conditional Access gaps, passwordless adoption).

All scripts are white-label and read-only except the clearly gated, preview-first `EKIDMOD-LabSetup.ps1`.

## How it is delivered
Delivered as a **Complete Solution Package (PDF + Word + scripts)** — the guides as a Word document
and PDF, plus all five lab helpers, in a single ZIP the team keeps and reuses.
