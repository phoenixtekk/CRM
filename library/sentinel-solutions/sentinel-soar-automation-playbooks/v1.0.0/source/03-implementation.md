# 3. Implementation Guide — Microsoft Sentinel SOAR: Automation Rules & Playbooks (Logic Apps)

Follow these steps **in order**. They use the Azure portal (`https://portal.azure.com`) for Microsoft Sentinel, Logic Apps, and role assignments. Build the playbooks first, secure them with a managed identity, keep the response playbook in **simulate mode**, then wire an automation rule to run them on a small pilot slice before expanding.

> Model: build enrichment → notify → ticketing → response (simulate-first, approval-gated) → automation rule → validate on a pilot (the gate) → expand. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):

- Resource group (host for playbooks): `rg-sentinel-soar`
- Enrichment playbook (Logic App): `Enrichment - Incident - Pilot`
- Notification playbook: `Notify - Teams-Email - Pilot`
- Ticketing playbook: `Ticketing - Incident - Pilot`
- Response playbook (approval-gated, simulate-first): `Response - Contain - Pilot`
- Automation rule: `Auto-Triage - New Incidents - Pilot`
- Managed-identity role assignment: `Sentinel Responder - Playbook MI - Pilot`

## Step 1 — Confirm Sentinel and prepare the SOAR resource group

1. `portal.azure.com` → search `Microsoft Sentinel` → confirm your workspace is listed and `Incidents` shows recent incidents. If none exist, enable an analytics rule first (Requirement 2.1).
2. `portal.azure.com` → `Resource groups` → `Create` → name it `rg-sentinel-soar`, same region as the workspace → `Review + create` → `Create`. This keeps all playbooks in one place for permissions and cost tracking.
3. Run `SENTSOAR-Discovery.ps1` to confirm Sentinel onboarding, existing automation rules/playbooks, and your permissions.

## Step 2 — Build the enrichment playbook (`Enrichment - Incident - Pilot`)

1. `Create a resource` → search `Logic App` → `Logic App (Consumption)` → `Create`. Resource group `rg-sentinel-soar`; name `Enrichment - Incident - Pilot`; same region → `Review + create` → `Create`.
2. Open it → `Logic app designer` → start with a blank Logic App → add trigger **`Microsoft Sentinel incident`** (`When a Microsoft Sentinel incident creation rule is triggered`).
3. Add action **`Microsoft Sentinel` → `Entities - Get Accounts`** and **`Entities - Get IPs`** to pull the user and IP entities from the incident.
4. Add enrichment lookups (use only the ones you have): for each IP, a **threat-intel** or **VirusTotal** connector action (or an `HTTP` GET to your TI source); for each account, an **Entra ID (`HTTP` to Microsoft Graph or the Azure AD connector)** lookup for account status/risk.
5. Add **`Microsoft Sentinel` → `Add comment to incident`** and post the collected context (IP reputation, account risk/status) back onto the incident as a formatted comment.
6. `Save`. In Step 6 you will enable its managed identity and grant it Sentinel Responder.

## Step 3 — Build the notification playbook (`Notify - Teams-Email - Pilot`)

1. Create another `Logic App (Consumption)` in `rg-sentinel-soar` named `Notify - Teams-Email - Pilot`.
2. Designer → trigger **`Microsoft Sentinel incident`**.
3. Add **`Microsoft Teams` → `Post adaptive card in a chat or channel`** targeting the `SOC Approvals`/SOC channel (Requirement 2.7). Build a card with the incident title, severity, owner, and a deep link (`Microsoft Sentinel` → dynamic `Incident URL`).
4. Add **`Office 365 Outlook` → `Send an email (V2)`** to the SOC distribution list with the same summary (belt-and-braces so a missed Teams post is still emailed).
5. `Save`. Authorize the Teams and Outlook connections with the low-privilege service account (Requirement 2.5).

## Step 4 — Build the ticketing playbook (`Ticketing - Incident - Pilot`)

1. Create a `Logic App (Consumption)` in `rg-sentinel-soar` named `Ticketing - Incident - Pilot`.
2. Designer → trigger **`Microsoft Sentinel incident`**.
3. Add your ITSM action: **`ServiceNow` → `Create Record`**, **`Jira` → `Create issue`**, or an **`HTTP` POST** to your ITSM's inbound API/webhook if no first-party connector exists. Map incident title → summary, severity → priority, incident URL → description.
4. Add **`Microsoft Sentinel` → `Add comment to incident`** writing the ticket number/URL back onto the incident so the two systems are linked.
5. `Save`. Authorize the ticketing connection (Requirement 2.5).

## Step 5 — Build the response playbook (`Response - Contain - Pilot`) — approval-gated and simulate-first

1. Create a `Logic App (Consumption)` in `rg-sentinel-soar` named `Response - Contain - Pilot`.
2. Designer → trigger **`Microsoft Sentinel incident`** (this playbook is intended to be run **manually** by an analyst from the incident, or by the automation rule only in Expand).
3. Add a parameter/variable **`SimulateMode`** (boolean) initialized to **`true`**. Every action below is wrapped in a condition on `SimulateMode`.
4. Add **`Microsoft Teams` → `Post an Adaptive Card and wait for a response`** (an approval card) to the `SOC Approvals` channel: "Approve containment for incident *[title]* — action: *[disable user / isolate device / block IP]*?" This is the human-in-the-loop **approval gate**; the playbook pauses here until an approver responds.
5. Add a **`Condition`**: proceed only if the approval response is `Approve`.
6. Inside the approved branch, add a nested **`Condition` on `SimulateMode`**:
   - **If `SimulateMode` is `true` (default):** do **not** call any platform. Instead `Add comment to incident`: "SIMULATE: would disable user *[UPN]* / isolate device *[id]* / block IP *[ip]* — no change made." This is the dry run.
   - **If `SimulateMode` is `false` (enforced, Expand only):** call the real action for the specific containment you are enabling:
     - **Disable user** — `Azure AD`/`HTTP to Microsoft Graph` `PATCH /users/{id}` `accountEnabled=false`, or the `Microsoft Entra ID` connector's disable action.
     - **Isolate device** — `Microsoft Defender for Endpoint` → `Isolate machine` (requires Defender for Endpoint onboarded — Requirement 2.6).
     - **Block IP** — your firewall/NSG connector action, or `Microsoft Sentinel` → add a threat-intel indicator to block on downstream, per your architecture.
7. After the action (real or simulated), `Add comment to incident` recording what was done, by whom (the approver), and when. Optionally `Change incident status` to `Active`/`Closed` per your process.
8. `Save`. **Leave `SimulateMode = true` for the entire pilot.** It stays simulate-first until an explicit change approval flips it for one specific action in Expand.

## Step 6 — Secure the playbooks with managed identities (least privilege)

1. For **each** playbook: open it → `Identity` → `System assigned` → `On` → `Save`. Note the object (principal) ID.
2. Grant each identity only what it needs, at the narrowest scope:
   - **All four playbooks** need to update incidents: on the workspace/resource group, `Access control (IAM)` → `Add role assignment` → **Microsoft Sentinel Responder** → assign to the playbook's managed identity. Record this assignment as `Sentinel Responder - Playbook MI - Pilot`.
   - **`Response - Contain - Pilot`** additionally needs the permission for the *enforced* action you will eventually enable — e.g. the Microsoft Defender for Endpoint machine-isolation permission, or a Graph/Entra role that can disable a user. **Grant these only when you move that action to enforced in Expand**, not during the simulate-only pilot.
3. Run `SENTSOAR-Set-PlaybookIdentity.ps1` to report each playbook's identity and its role assignments and confirm least privilege.

## Step 7 — Grant Sentinel permission to run the playbooks

1. `Microsoft Sentinel` → (workspace) → `Configuration` → `Automation` → `Active playbooks` (or `Settings`).
2. Use **`Configure permissions`** → select `rg-sentinel-soar` → `Apply`. This grants the Microsoft Sentinel service the rights to run playbooks in that resource group from automation rules (Requirement 2.3).

## Step 8 — Create the automation rule (`Auto-Triage - New Incidents - Pilot`)

1. `Microsoft Sentinel` → `Configuration` → `Automation` → `Create` → `Automation rule`.
2. Name: `Auto-Triage - New Incidents - Pilot`.
3. **Trigger:** `When incident is created`.
4. **Conditions (scope the pilot narrowly):** add a condition such as `Analytics rule name` `Contains` your one pilot rule, **or** `Severity` `Equals` `Medium` — a small, safe slice (Requirement 2.8).
5. **Actions (in order):**
   - `Assign owner` → the pilot analyst or SOC group.
   - `Add tags` → `soar-pilot`, `auto-triaged`.
   - `Run playbook` → `Enrichment - Incident - Pilot`.
   - `Run playbook` → `Notify - Teams-Email - Pilot`.
   - `Run playbook` → `Ticketing - Incident - Pilot`.
   - **Do not** add `Response - Contain - Pilot` here during the pilot — it stays analyst-triggered and simulate-only.
6. Set `Order` (priority) and `Save`.

## Step 9 — Validate the pilot (the gate)

1. Run `SENTSOAR-Validate.ps1` → confirms the automation rule is enabled, each playbook is enabled with a managed identity, and Sentinel has run permission on `rg-sentinel-soar`.
2. Trigger a real (or test) incident in the pilot scope. Confirm within a few minutes:
   - The incident is auto-assigned and tagged (`soar-pilot`, `auto-triaged`).
   - `Enrichment - Incident - Pilot` added an enrichment comment.
   - `Notify - Teams-Email - Pilot` posted to Teams and emailed the SOC.
   - `Ticketing - Incident - Pilot` opened a ticket and wrote the ticket number back.
3. Manually run `Response - Contain - Pilot` from the incident (`Actions` → `Run playbook`). Approve the card. Confirm it posted a **SIMULATE** comment and made **no** platform change (`SimulateMode = true`).
4. Run `SENTSOAR-Report.ps1` → review run history, success/failure counts, and confirm **no enforced response action** ran during the pilot.
5. Complete the Testing Guide. **Pilot gate:** do not expand until enrichment/notify/ticketing run cleanly and the response playbook is proven approval-gated and simulate-only.

## Step 10 — Expand

1. Once the gate passes, widen `Auto-Triage - New Incidents - Pilot` (or clone it to `Auto-Triage - New Incidents - Production`) to cover more analytics rules/severities.
2. If — and only if — your change-control process approves enforcing a specific containment for a specific scenario: grant `Response - Contain - Pilot`'s managed identity the exact platform permission (Step 6.2), set that action's branch to `SimulateMode = false` for that one action, keep the approval gate, and test on a single controlled case first. Rename to `Response - Contain - Production`.
3. Re-run `SENTSOAR-Report.ps1` each cycle to track run volume, success rate, and Logic App cost.

---

### Order of operations

`Sentinel + SOAR resource group -> enrichment playbook -> notify playbook -> ticketing playbook -> response playbook (simulate-first, approval-gated) -> managed identities + least-privilege roles -> Sentinel run permission -> automation rule (narrow pilot) -> validate on a pilot (gate) -> expand`
