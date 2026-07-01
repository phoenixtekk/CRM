# 3. Implementation — MSP Tool Stack Design & Standup — PSA, RMM & Patch Management

This is the build guide for the full program. Work the phases in order: **Assess → Design → Stand up → Integrate → Onboard a client → Validate → Operate** (Validate and Operate are detailed in `05-testing.md` and `07-best-practices.md`; the core build is Assess through Onboard here). Where a concrete console is named, full navigation paths are given. Where the platform is vendor-specific, the step names the **vendor admin console → section → tab** to open and directs you to that vendor's documentation for product-specific clicks. Every object you create reuses the `<Purpose> – <Scope> – <Stage>` names defined in `01-solution-overview.md` verbatim.

Do not start until the requirements in `02-requirements.md` and `global-requirements-managed.md` are verified.

---

## Stage A — Assess

### Step 1 — Inventory the current tooling and integration readiness

Run `MSPSTACK-Discovery.ps1` (see `scripts/`) to capture what exists today: any PSA/RMM/patch tooling, installed agents, reachable update sources, and integration-credential readiness. Save the output as the baseline. If the practice has no tooling yet, the script confirms a greenfield start.

### Step 2 — Select the PSA platform against criteria

Score candidate PSA platforms (for example ConnectWise PSA, Datto Autotask, HaloPSA) against:

- **Ticketing depth:** boards/queues, SLAs, dispatch, time entry against tickets.
- **Contracts & billing:** agreement types (managed, block-hours, per-device), time→invoice flow.
- **Integration breadth:** native or documented API integration with the candidate RMM and patch engine.
- **CMDB / configurations:** ability to hold per-client configuration items fed from the RMM.
- **Total cost & growth model:** per-seat vs per-endpoint pricing aligned to the growth plan.

Record the decision and rationale in the documentation home. Confirm R1.

### Step 3 — Select the RMM platform against criteria

Score candidate RMM platforms (for example NinjaOne, Datto RMM, ConnectWise Automate) against:

- **Agent footprint & OS coverage:** Windows/macOS/Linux/server support, agent reliability.
- **Monitoring & alerting:** built-in monitors, alert thresholds, escalation, alert→ticket capability.
- **Scripting & automation:** scripting engine, scheduled automation, software deployment.
- **Patch capability:** native OS + third-party patch module (if RMM is the chosen patch engine).
- **PSA integration:** native bi-directional integration with the chosen PSA.

Record the decision. Confirm R2.

### Step 4 — Select the patch engine

Decide between the **RMM patch module** and **Intune / Windows Update for Business (WUfB)**:

- Choose the **RMM module** when you want a single pane for monitoring and patching, mixed-OS coverage, and third-party app patching driven by the RMM.
- Choose **Intune / WUfB** when devices are Entra-joined/enrolled and you want Microsoft-native update rings, Conditional Access integration, and Update Compliance reporting.

Record the decision. Confirm R4.

---

## Stage B — Design

### Step 5 — Lock the naming and site taxonomy

Adopt the `<Purpose> – <Scope> – <Stage>` convention from `01-solution-overview.md`. Map every managed client to **one RMM site** (`Client Site – {ClientName} – Production`) and **one PSA company** of the same client name. Document the mapping in the documentation home. Confirm R7.

### Step 6 — Design the PSA board/queue model

Plan these boards/queues (created in Stage C):

- `Service Desk – Reactive – Triage` — entry point for all inbound and alert-generated tickets.
- `Service Desk – Reactive – Dispatch` — triaged tickets assigned to technicians.
- `Projects – Onboarding – Delivery` — onboarding and project work.
- `NOC – Alerts – Automated` — RMM alert tickets that auto-resolve when the alert clears.

### Step 7 — Design the RMM policy model

Plan these policies (created in Stage C):

- `Monitoring Policy – Workstation – Standard` — baseline workstation monitors (disk, CPU, services, AV health).
- `Monitoring Policy – Server – Standard` — server monitors (services, event logs, disk, backup status).
- `Automation Policy – Maintenance – Nightly` — scheduled nightly maintenance (temp cleanup, health checks, reboots where permitted).

### Step 8 — Design the patch rings

Plan a ring-based deployment model (created in Stage C against the chosen engine):

- `Patch Ring – Pilot – Stage0` — small canary set; updates land first, 0-day deferral.
- `Patch Ring – Early – Stage1` — early adopters; ~3-day deferral.
- `Patch Ring – Broad – Stage2` — the bulk of workstations; ~7-day deferral.
- `Patch Ring – Critical Servers – Stage3` — servers; longest deferral, scheduled maintenance windows only.

### Step 9 — Design the role model

Define the roles from R5 in each tool: administrator, technician, dispatcher, read-only/reporting. Map staff to least-privilege roles.

---

## Stage C — Stand up

### Step 10 — Provision and baseline the PSA

In the **PSA admin console**, sign in as administrator and create the boards/queues from Step 6. (In ConnectWise PSA: *System → Setup Tables → Service Board* to create each board; in Autotask: *Admin → Features & Settings → Service Desk (Tickets) → Queues*; in HaloPSA: *Configuration → Tickets → Ticket Types / Teams*.) Refer to the chosen vendor's documentation for the exact field-by-field setup. Then:

- Create the SLA(s) and attach them to `Service Desk – Reactive – Triage`.
- Create agreement types for managed, block-hours, and per-device contracts.
- Enable time entry against tickets so technician time can flow to billing.

### Step 11 — Provision and baseline the RMM

In the **RMM admin console**, sign in as administrator and:

- Create the monitoring and automation policies from Step 7 (NinjaOne: *Administration → Policies*; Datto RMM: *Account → Policies*; ConnectWise Automate: *Automation → Templates/Scripts and Monitors*). Refer to the vendor docs for monitor-by-monitor setup.
- Confirm the agent installer and the deployment package from R3 are ready.
- Create the role definitions from Step 9 (RMM → Administration → Roles/Permissions) and enforce MFA (R8).

### Step 12 — Stand up the patch engine

**If the RMM is the patch engine:** in the RMM patch section, create the four patch rings from Step 8 as patch policies, each with its deferral/approval rules and maintenance window. Bind rings to device groups (created per client during onboarding).

**If Intune / WUfB is the patch engine:** in the **Microsoft Intune admin center** (`https://intune.microsoft.com`):

1. Create quality-update rings at **Devices → Manage updates → Windows updates → Update rings → Create profile**. Create one profile per ring: `Patch Ring – Pilot – Stage0`, `Patch Ring – Early – Stage1`, `Patch Ring – Broad – Stage2`, `Patch Ring – Critical Servers – Stage3`. Set the **Quality update deferral period (days)** to 0 / 3 / 7 / 7 respectively and configure deadline/grace settings, then assign each profile to its corresponding device group.
2. Create the assignment groups at **Microsoft Entra admin center → Groups → New group** (or in Intune at **Groups → New group**) named to match each ring's scope, then return to each update ring profile's **Assignments** tab and assign the matching group.
3. (Optional) Configure **feature-update** profiles at **Devices → Manage updates → Windows updates → Feature updates → Create profile** to pin the target Windows feature version per ring.

---

## Stage D — Integrate

### Step 13 — Create the PSA↔RMM integration

Using the API credentials from R6 (retrieved from the secrets store), configure the bi-directional integration named `Integration – PSA-RMM – Bi-Directional`:

1. In the **RMM admin console → Administration → Integrations** (or the PSA's integration marketplace), select the native PSA integration and authenticate with the integration credential. Refer to the vendor's integration setup guide for the exact field mapping screens.
2. Configure **alert→ticket flow:** map RMM alerts to create tickets on `NOC – Alerts – Automated`, and configure auto-close so a ticket resolves when its alert clears.
3. Configure **asset/CMDB feed:** map RMM devices to PSA configuration items so the RMM populates the PSA CMDB (R-aligned with GM3).
4. Configure **ticket sync:** ensure ticket status/notes sync between the tools where the vendor supports it.

### Step 14 — Map sites to companies

In the integration's mapping screen, link each `Client Site – {ClientName} – Production` RMM site to its matching PSA company so alerts, assets, and tickets attribute to the correct client.

---

## Stage E — Onboard a client (pilot)

### Step 15 — Run the onboarding template against the pilot client

Use `MSPSTACK-Set-ClientOnboarding.ps1` (run with `-WhatIf` first) to scaffold the pilot client (R9) per `Onboarding Template – Managed Client – Standard`:

1. Create the PSA company and the RMM site `Client Site – {ClientName} – Production`.
2. Create the client's device groups and bind the monitoring/automation policies and patch rings.
3. Deploy the RMM agent via the method from R3 to the client's endpoints.
4. Confirm assets flow into the PSA CMDB and that a test alert creates a ticket on `NOC – Alerts – Automated`.
5. Record the onboarding in the documentation home and the PSA configurations module.

Re-run with `-Apply` (script default is read-only/`-WhatIf`) once the dry-run output is correct.

After onboarding the pilot, proceed to `05-testing.md` for Stage Validate, then `07-best-practices.md` for Stage Operate.
