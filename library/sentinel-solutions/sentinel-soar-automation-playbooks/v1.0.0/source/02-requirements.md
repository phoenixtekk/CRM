# 2. Requirements Guide — Microsoft Sentinel SOAR: Automation Rules & Playbooks (Logic Apps)

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first. The requirements below are specific to automation rules and playbooks.

## 2.1 Incidents are being created in Sentinel

- **Description:** At least one active analytics rule (scheduled, Microsoft-security, or NRT) that produces incidents in the workspace.
- **Why:** Automation rules and playbooks trigger on incidents; with no incidents there is nothing to automate against. The pilot needs a steady, low-volume source of real incidents to test on.
- **Verify:** `portal.azure.com` → `Microsoft Sentinel` → (workspace) → `Incidents` shows recent incidents; `Configuration` → `Analytics` → `Active rules` lists at least one enabled rule. Run `SENTSOAR-Discovery.ps1`.
- **Implement-if-missing:** Enable at least one analytics rule from a template (or deploy the *Sentinel Analytics Rules & MITRE ATT&CK Coverage* solution) so incidents are generated.

## 2.2 Rights to create Azure Logic Apps

- **Description:** Permission to create Logic App (Consumption) resources in the resource group that will host the playbooks.
- **Why:** A playbook is a Logic App; you cannot create one without Contributor (or Logic App Contributor) on the target resource group.
- **Verify:** On the target resource group, `Access control (IAM)` → confirm your account holds Contributor or Logic App Contributor. Try `Create a resource` → `Logic App (Consumption)` and confirm you can reach the create blade.
- **Implement-if-missing:** Have an owner assign Logic App Contributor (or Contributor) on a dedicated resource group for the playbooks (for example `rg-sentinel-soar`), scoped per least privilege.

## 2.3 Microsoft Sentinel automation permissions

- **Description:** The **Microsoft Sentinel Contributor** role to create automation rules, and the **Microsoft Sentinel Playbook Operator** / **Microsoft Sentinel Responder** roles so automation rules can run playbooks and so the playbooks' identity can update incidents.
- **Why:** Creating automation rules, allowing them to run Logic Apps, and letting a playbook modify an incident are each distinct permissions. Sentinel also requires that the **Azure Security Insights** service principal (or the automation rule's permission) be granted rights on the playbook's resource group so a rule may run it.
- **Verify:** On the workspace, `Access control (IAM)` → confirm Sentinel Contributor. In `Configuration` → `Automation` → `Settings`, confirm Sentinel has permission to run playbooks in the SOAR resource group. Run `SENTSOAR-Discovery.ps1`.
- **Implement-if-missing:** Assign Sentinel Contributor on the workspace; in `Automation` → `Active playbooks`, use `Configure permissions` to grant Sentinel run rights on the SOAR resource group.

## 2.4 A managed identity strategy for the playbooks

- **Description:** A decision to use a **system-assigned managed identity** on each playbook (preferred), with least-privilege role assignments, rather than storing credentials in connectors.
- **Why:** A managed identity removes stored secrets from the workflow and lets you grant exactly the roles each playbook needs (Sentinel Responder to update incidents; the specific permission for each response action). This is the secure default and the audit-friendly one.
- **Verify:** Confirm you can enable a system-assigned identity on a Logic App (`Identity` blade) and assign it roles. Run `SENTSOAR-Set-PlaybookIdentity.ps1` to report current identity/role state.
- **Implement-if-missing:** Plan a system-assigned identity per playbook; document the exact roles each needs (see the Implementation Guide) so an owner can assign them at the narrowest scope.

## 2.5 Connector authorizations (Teams, email, ticketing)

- **Description:** The ability to authorize the API connections the notification and ticketing playbooks use — Microsoft Teams, Office 365 Outlook (email), and your ticketing system's connector (for example ServiceNow, Jira, or a generic HTTP/webhook to an ITSM).
- **Why:** Each connector needs a one-time authorization (an account or a managed identity) before a playbook can post to Teams, send email, or open a ticket.
- **Why version/license matters:** some ticketing connectors are premium or in preview and may require a specific plan — *verify current availability in your tenant*.
- **Verify:** In `Logic Apps` → an existing or scratch playbook → add a Teams / Outlook action and confirm the connection authorizes. Confirm which ticketing connector your organization uses and that an account exists to authorize it.
- **Implement-if-missing:** Provision a low-privilege service account (or managed identity) to own the Teams/Outlook/ticketing connections; authorize each once. If no ITSM connector is available, use an HTTP action to the ITSM's inbound webhook/API.

## 2.6 Target platforms for response actions (only what you will use)

- **Description:** The platforms that the response actions act on must be present and licensed: **Entra ID** to disable a user; **Microsoft Defender for Endpoint** onboarded to isolate a device; a **firewall/NSG or Sentinel threat-intel indicator** path to block an IP.
- **Why:** A response action cannot run against a platform you do not have. You only need the ones you intend to use — the response playbook is modular.
- **Why license matters:** device isolation requires Microsoft Defender for Endpoint (P1/P2 as applicable); some block-IP paths require a specific firewall connector or premium tier — *verify current availability in your tenant*.
- **Verify:** For device isolation: `security.microsoft.com` → devices are onboarded. For user-disable: an Entra ID role/Graph permission that can disable an account. For block-IP: confirm the firewall connector or the threat-intel indicators path is available. Run `SENTSOAR-Validate.ps1`.
- **Implement-if-missing:** Only implement the platforms for the response actions you will pilot; leave the rest out of scope until needed.

## 2.7 An approval channel for gated actions

- **Description:** A Microsoft Teams channel or an email distribution list that receives the approval prompt before any disruptive response action runs, with the named approvers who may approve.
- **Why:** The response playbook pauses and posts an approval request; someone with authority must approve before it proceeds. This is the human-in-the-loop control.
- **Verify:** Confirm a Teams channel or shared mailbox exists and that the approvers are identified and agree to the process.
- **Implement-if-missing:** Create a dedicated `SOC Approvals` Teams channel (or mailbox); document who may approve which action.

## 2.8 A pilot scope and simulate-first policy defined

- **Description:** A named, limited pilot scope (for example, incidents from one analytics rule or one severity) with success criteria, and a written policy that **all response actions run in simulate mode first** and never enforce during the pilot.
- **Why:** The standard model validates the automation on a safe slice, and containment must be proven harmless (simulate) before it is ever allowed to enforce.
- **Verify:** The pilot scope, pass criteria, and simulate-first policy are written down. Run `SENTSOAR-Report.ps1` to confirm run history and that no enforced response ran during the pilot.
- **Implement-if-missing:** Choose the smallest useful incident slice as the pilot; record the gate (enrichment + notify + ticketing clean, response simulate-only) before expanding.

---

## Checklist

- [ ] Azure subscription, Log Analytics workspace, and Microsoft Sentinel enabled — see global requirements
- [ ] Incidents are being created by at least one analytics rule — `SENTSOAR-Discovery.ps1`
- [ ] Rights to create Logic Apps in a dedicated SOAR resource group
- [ ] Sentinel automation/playbook permissions in place (rule can run playbooks) — `SENTSOAR-Discovery.ps1`
- [ ] Managed-identity strategy with least-privilege roles — `SENTSOAR-Set-PlaybookIdentity.ps1`
- [ ] Teams / email / ticketing connectors can be authorized
- [ ] Target platforms present for the response actions you will use — `SENTSOAR-Validate.ps1`
- [ ] Approval channel and named approvers agreed
- [ ] Pilot scope and simulate-first policy defined — `SENTSOAR-Report.ps1`
