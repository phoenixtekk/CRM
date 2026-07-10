# 2. Requirements Guide — SOC Onboarding: Microsoft Sentinel + Defender XDR Unified Incidents

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC baseline, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first. For this solution the workspace is named `Security Telemetry - SOC - Workspace`.

## 2.1 Microsoft Defender XDR deployed and generating incidents

- **Description:** At least one Microsoft Defender XDR workload (Defender for Endpoint, Office 365, Identity, or Cloud Apps) onboarded and producing incidents in the Defender portal (`https://security.microsoft.com`).
- **Why:** The connector streams Defender XDR incidents into Sentinel; if Defender XDR raises no incidents there is nothing to unify.
- **Verify:** `security.microsoft.com` → `Incidents & alerts` → `Incidents` shows recent incidents. Run `SOCXDR-Discovery.ps1` to confirm the connected workloads.
- **Implement:** Onboard the relevant Defender workloads (licensing per Microsoft 365 E5 / E5 Security or the standalone plans — *verify current licensing in your tenant*) and confirm incidents are being raised.

## 2.2 The Microsoft Defender XDR data connector available in Sentinel

- **Description:** The Microsoft Defender XDR connector (and its solution package) present in the Sentinel Content hub for `Security Telemetry - SOC - Workspace`.
- **Why:** This connector is the supported way to bring Defender XDR incidents/alerts into Sentinel and enable synchronization.
- **Verify:** `portal.azure.com` → `Microsoft Sentinel` → (workspace) → `Configuration` → `Data connectors` → search `Microsoft Defender XDR`. Run `SOCXDR-Validate.ps1`.
- **Implement:** Install the **Microsoft Defender XDR** solution from `Content hub` if the connector is not listed.

## 2.3 Permission to configure the connector and incident sync

- **Description:** A role that can configure the Defender XDR connector in Sentinel and read incidents in the Defender portal — typically Microsoft Sentinel Contributor on the workspace plus a Defender role (for example Security Reader/Administrator) with global (tenant-level) Sentinel rights required by this connector.
- **Why:** Enabling incident sync writes connector configuration in Sentinel and reads from Defender XDR; both scopes are needed.
- **Verify:** On the workspace, `Access control (IAM)` shows Microsoft Sentinel Contributor; in `security.microsoft.com` → `Permissions` the account holds a Defender role. Run `SOCXDR-Discovery.ps1`.
- **Implement:** Assign Microsoft Sentinel Contributor at the workspace (or resource-group) scope and the least-privilege Defender role needed; prefer eligible (PIM) activation. *The Defender XDR connector requires tenant-scoped Sentinel permissions — verify the exact role in your tenant.*

## 2.4 Existing Microsoft incident-creation rules identified (de-duplication plan)

- **Description:** A list of any active **Microsoft incident-creation rules** in Sentinel that create incidents from the same Defender products (for example "Create incidents based on Microsoft Defender for Endpoint alerts").
- **Why:** If these stay on while the Defender XDR connector also creates synced incidents, every incident appears twice; the de-duplication step turns them off.
- **Verify:** `Microsoft Sentinel` → `Analytics` → `Active rules` → filter by rule type `Microsoft incident creation rule`. Run `SOCXDR-Report.ps1` to list them.
- **Implement:** Record which are active so Step 4 of the Implementation Guide can disable them cleanly (and so rollback is possible).

## 2.5 A severity / priority alignment scheme

- **Description:** An agreed mapping of how Defender XDR severities (High/Medium/Low/Informational) map to the SOC's working priority, and who owns each severity band.
- **Why:** A single, agreed scheme is what lets analysts work one prioritized list; the automation rule encodes it.
- **Verify:** A written severity→priority→owner map exists (even a one-page table).
- **Implement:** Agree the mapping with SOC leadership before building the automation rule `Incident Alignment - SOC - Pilot`.

## 2.6 SOC roles and an analyst group defined

- **Description:** An Entra ID security group for the SOC analysts/responders (for example `SOC-Analysts`) and a definition of who is Tier 1 (triage), Tier 2 (investigate), and lead.
- **Why:** RBAC is assigned to a group, and the triage/hand-off runbook assigns work by tier; both need the roster defined.
- **Verify:** `entra.microsoft.com` → `Groups` → the SOC group exists with the analysts as members.
- **Implement:** Create the group and populate it; map members to tiers for the runbook.

## 2.7 A pilot scope and success criteria

- **Description:** A named pilot — typically one or two Defender workloads and a small analyst cohort — with pass criteria: incidents sync, no duplicates appear, and severity/ownership is applied automatically.
- **Why:** The standard model validates the unified queue on a pilot before the whole SOC moves off the two-console workflow.
- **Verify:** The pilot workloads, cohort, and pass criteria are written down. Run `SOCXDR-Validate.ps1` to confirm sync during the pilot.
- **Implement:** Choose the minimum useful scope for the pilot; record the gate (sync confirmed, duplicates gone) before expanding.

---

## Checklist

- [ ] Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, change control — see global requirements
- [ ] Defender XDR deployed and raising incidents — `SOCXDR-Discovery.ps1`
- [ ] Microsoft Defender XDR connector available in Content hub — `SOCXDR-Validate.ps1`
- [ ] Permission to configure the connector + incident sync
- [ ] Active Microsoft incident-creation rules listed — `SOCXDR-Report.ps1`
- [ ] Severity→priority→owner mapping agreed
- [ ] SOC analyst group and tier definitions in place
- [ ] Pilot scope and pass criteria (sync + no duplicates) defined
