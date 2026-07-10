# 3. Implementation Guide — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents — Government (GCC High)

Follow these steps **in order**. This is the **US Government (GCC High)** edition — every portal path uses
the Azure Government national cloud. They use two portals: the **Azure Government portal**
(`https://portal.azure.us`) for Microsoft Sentinel, the connector, analytics, automation, and RBAC; and
the **Microsoft Defender portal for US Gov** (`https://security.microsoft.us`) for Defender XDR incidents
and the optional unified experience.

> **National-cloud endpoints.** Use the US Gov hosts throughout: `portal.azure.us`,
> `security.microsoft.us`, `entra.microsoft.us`, token `login.microsoftonline.us`, Graph
> `graph.microsoft.us` (**DoD/IL5 `dod-graph.microsoft.us`**). PowerShell uses `Connect-AzAccount
> -Environment AzureUSGovernment`. The Defender XDR connector, incident-sync behavior, and the unified
> Sentinel + Defender experience **can lag or differ in GCC High/DoD** — if a page, toggle, or URL
> differs, **verify against current Microsoft Government documentation** (see `gcc-high-parity-notes.md`).

> Model: connect Defender XDR, turn on incident sync, remove duplicate incident creation, align severity/ownership, adopt the triage/hand-off runbook, validate on a pilot, then expand. Every object created is named `<Purpose> - <Scope> - <Stage>` and reused verbatim.

Objects this guide creates (name them exactly):
- Workspace (destination): `Security Telemetry - SOC - Workspace`
- Defender XDR connector instance: `Microsoft Defender XDR - SOC - Pilot`
- Automation rule: `Incident Alignment - SOC - Pilot`
- RBAC scope / assignment: `Microsoft Sentinel Responder - SOC - Pilot`

## Step 1 — Confirm the workspace and Sentinel

1. `portal.azure.us` → search `Log Analytics workspaces` → confirm `Security Telemetry - SOC - Workspace` exists (create it if not; see global requirements G2). Note its region and resource group.
2. `portal.azure.us` → search `Microsoft Sentinel` → confirm the workspace is listed. If not: `Create` → select the workspace → `Add`.

## Step 2 — Install and open the Microsoft Defender XDR connector

1. `Microsoft Sentinel` → select `Security Telemetry - SOC - Workspace` → `Content management` → `Content hub`.
2. Search `Microsoft Defender XDR` → select the solution → `Install` (skip if already installed).
3. `Configuration` → `Data connectors` → search `Microsoft Defender XDR` → `Open connector page`.

## Step 3 — Connect Defender XDR and enable incident synchronization

1. On the Microsoft Defender XDR connector page, click `Connect incidents & alerts`. This creates the connector instance; record it as `Microsoft Defender XDR - SOC - Pilot`.
2. Leave **`Turn off all Microsoft incident creation rules for these products`** available for Step 4 — the connector page offers this toggle; you can use it here to disable the duplicate rules in one click, or do it manually in Step 4.
3. Under the connected data types, select the Defender workloads in your pilot scope (for example Defender for Endpoint and Defender for Office 365) so their alerts also stream into the workspace tables.
4. Click `Apply Changes` / `Connect`. Incident sync begins; new Defender XDR incidents now appear in Sentinel, and status/owner/classification sync both ways.

## Step 4 — Remove duplicate incidents (de-duplication)

1. `Microsoft Sentinel` → `Configuration` → `Analytics` → `Active rules`.
2. Filter `Rule type` = `Microsoft incident creation rule`. These are the older rules that make a *second* Sentinel incident from each Defender alert.
3. For every such rule covering a product now synced by the Defender XDR connector, select it → `Disable` (do not delete — disabling keeps rollback trivial). Use the list captured in Requirement 2.4 / `SOCXDRG-Report.ps1` so none are missed.
4. Result: each threat now produces exactly one synced incident from the connector, not a duplicate pair.

## Step 5 — Align severity, priority, and ownership (automation rule)

1. `Microsoft Sentinel` → `Configuration` → `Automation` → `Create` → `Automation rule`.
2. Name: `Incident Alignment - SOC - Pilot`.
3. `Trigger`: `When incident is created`.
4. `Conditions`: scope to the pilot — for example `Alert product names` `Contains` the Defender products in scope (leave broad for a full-SOC rollout later).
5. `Actions`, added in order to encode your Requirement 2.5 scheme:
   - `Change severity` — only if your scheme overrides the incoming severity for a band (otherwise omit and keep Defender's severity).
   - `Assign owner` → the Tier 1 triage queue owner or the `SOC-Analysts` group, so every incident lands owned.
   - `Add tags` → for example `SOC-Triage`, plus a priority tag such as `P1`/`P2` derived from severity, so the queue can be sorted and filtered by one scheme.
6. `Order`: `1`. `Apply`. New incidents now arrive already prioritized, owned, and tagged.

## Step 6 — Scope RBAC for the SOC

1. `portal.azure.us` → `Log Analytics workspaces` → `Security Telemetry - SOC - Workspace` → `Access control (IAM)` → `Add role assignment`.
2. Assign to the `SOC-Analysts` group:
   - `Microsoft Sentinel Responder` — triage/investigate/respond on incidents (Tier 1/Tier 2). Record as `Microsoft Sentinel Responder - SOC - Pilot`.
   - `Microsoft Sentinel Contributor` — for SOC leads who also manage rules/automation.
3. Keep read-only stakeholders on `Microsoft Sentinel Reader`. Prefer eligible (PIM) activation for the higher roles.
4. `SOCXDRG-Set-SocRbacScope.ps1` reports current assignments and can apply the scoped Responder role.

## Step 7 — Adopt the triage and shift hand-off runbook

Give analysts one queue and one routine (this is the operational core — see the Testing Guide for the drill that proves it):

1. **The single queue.** `Microsoft Sentinel` → `Threat management` → `Incidents`. Sort by the priority tag from Step 5 (or by severity). This — not the two separate consoles — is now the SOC's working list.
2. **Tier 1 triage (per incident, top of queue first):** open the incident → review the correlated alerts, entities (user, device, IP, mailbox), and the incident graph → set `Status` = `Active`, confirm/adjust `Owner`, and either resolve (with classification) or escalate to Tier 2 by re-assigning owner and adding the `Tier2` tag.
3. **Tier 2 investigation:** work the escalated incidents; use the entity pages and, where present, the unified Defender investigation. Record findings in the incident `Comments`.
4. **Shift hand-off (end of every shift):** filter the queue to `Status != Closed` and `Owner = <this shift>`; for each open incident add a hand-off comment (state, next action, blockers); re-assign owner to the incoming shift group; confirm no `New`/untriaged incident is older than the agreed SLA. `SOCXDRG-Report.ps1` prints the open-incident hand-off list.
5. **Bi-directional close:** closing the incident in Sentinel closes it in the Defender portal (and vice versa) — so analysts never need to reconcile the two.

## Step 8 — Validate the pilot (the gate)

1. Run `SOCXDRG-Validate.ps1` → confirms the Defender XDR connector is connected and incidents/alerts are arriving.
2. Run `SOCXDRG-Report.ps1` → confirms the Microsoft incident-creation rules are disabled (no duplicate source), lists open incidents, and shows the hand-off view.
3. Trigger a benign Defender test detection (for example the Defender for Endpoint EICAR/test alert per Microsoft's guidance) and confirm it appears **once** in the Sentinel queue, already owned and tagged.
4. Pilot gate: do not cut the whole SOC over until sync is confirmed, no duplicate incident appears for the test, and the automation rule applied severity/owner/tag.

## Step 9 — Expand to the full SOC

1. Once the gate passes, broaden the automation rule scope (or clone it to `Incident Alignment - SOC - Production`) to cover all Defender products and Sentinel analytics incidents.
2. Add the remaining Defender workloads to the connector's streamed data types; disable any remaining Microsoft incident-creation rules for them.
3. Onboard the whole analyst roster to `Microsoft Sentinel Responder`; retire the old two-console triage habit.
4. Optionally onboard Sentinel into the **unified security operations experience** in the US Gov Defender portal (`security.microsoft.us`) so both live behind one pane of glass. **This experience may lag or differ in GCC High/DoD** — *verify current availability against current Microsoft Government documentation for your cloud* (see `gcc-high-parity-notes.md`).
5. Re-run `SOCXDRG-Report.ps1` each cycle to confirm no duplicate rules creep back and the hand-off list stays clean.

---

### Order of operations

`Workspace + Sentinel -> install & connect Defender XDR (incident sync) -> disable Microsoft incident-creation rules (de-dup) -> severity/owner automation rule -> RBAC -> triage & hand-off runbook -> validate pilot (gate) -> expand`
