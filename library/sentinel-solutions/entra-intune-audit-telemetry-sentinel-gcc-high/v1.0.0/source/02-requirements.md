# 2. Requirements Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel (Government / GCC High)

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first, **using the Azure Government portal (`portal.azure.us`) rather than `portal.azure.com`.**

> GCC High note: every portal below is the `.us` sovereign portal. PowerShell must target US Gov endpoints — `Connect-MgGraph -Environment USGov` and `Connect-AzAccount -Environment AzureUSGovernment`. A Commercial sign-in will fail against a Gov tenant (it points at `login.microsoftonline.com`, the wrong cloud).

## 2.0 GCC High tenant and Azure Government subscription

- **Description:** The workload is a Microsoft 365 GCC High tenant paired with Microsoft Entra ID in Azure Government, and the Log Analytics workspace / Sentinel live in an **Azure Government** subscription.
- **Why:** Data residency and the sovereign boundary depend on everything staying in Azure Government; a Commercial Azure subscription would put the SIEM outside the Gov boundary.
- **Verify:** Sign in at `portal.azure.us` (not `.com`) and confirm the subscription resolves; the URL bar stays on `.us`. `Connect-AzAccount -Environment AzureUSGovernment` succeeds and lists the Gov subscription.
- **Implement:** Provision an Azure Government subscription for the workspace/Sentinel; confirm the tenant is GCC High (sign-in at `login.microsoftonline.us`).

## 2.1 Entra ID (Government) licensing for the sign-in categories in scope

- **Description:** An Entra ID Government plan that exposes the sign-in log categories you intend to route. Basic sign-in/audit logs are broadly available; some categories (for example risky-sign-in detail from Identity Protection) require a premium Entra plan (the Gov equivalent of P1/P2, commonly delivered via G5).
- **Why:** A diagnostic setting can only forward categories the tenant's license exposes; missing license means missing data. The **Microsoft Entra ID connector in Azure Government supports sign-in logs and audit logs** (per Microsoft's Sentinel feature-availability doc); confirm your Gov SKU exposes the specific categories you want beyond those.
- **Verify:** `entra.microsoft.us` → `Identity` → `Overview` (license shown), or the M365 Gov admin center (`portal.office365.us`) → `Billing` → `Licenses`.
- **Implement:** Assign the required Entra ID Government plan (G3/G5 Gov as applicable) for the categories you need.

## 2.2 Entra ID diagnostic-settings access (Government)

- **Description:** A role that can create an Entra ID diagnostic setting that forwards logs to the workspace.
- **Why:** Routing Entra ID `SignInLogs` and `AuditLogs` is done through `Monitoring & health` → `Diagnostic settings` in `entra.microsoft.us`; editing it requires the right role.
- **Verify:** `entra.microsoft.us` → `Monitoring & health` → `Diagnostic settings` loads and `Add diagnostic setting` is available; run `SENTLOGG-Discovery.ps1` (which connects with `-Environment AzureUSGovernment`).
- **Implement:** Hold a role that can edit Entra ID diagnostic settings (for example Security Administrator or Global Administrator), scoped per least privilege.

## 2.3 Microsoft Intune (Government) in the tenant

- **Description:** Microsoft Intune licensed and in use on the Gov tenant, generating device/compliance/enrollment audit telemetry.
- **Why:** This solution routes Intune audit telemetry; there must be Intune activity to route. Intune audit logs are routed via **Reports → Diagnostics settings** to Log Analytics (per Microsoft's "Route logs to Azure Monitor using Microsoft Intune").
- **Verify:** `intune.microsoft.us` loads with managed devices present; `Tenant administration` → `Audit logs` shows events.
- **Implement:** License Intune (Gov M365 G3/G5) and confirm devices are enrolled. Routing requires the **Intune Service Administrator** Entra role plus **Log Analytics Contributor** on the workspace.

## 2.4 The Entra ID data connector available in Sentinel (Azure Government)

- **Description:** The Microsoft Entra ID data connector present in the Sentinel content/connectors gallery on the in-scope Azure Government workspace.
- **Why:** The connector is the supported, point-and-click way to bring Entra ID logs into Sentinel and surface the matching baseline analytics rule templates. It is **GA in Azure Government.**
- **Verify:** `portal.azure.us` → `Microsoft Sentinel` → (workspace) → `Configuration` → `Data connectors` → search `Microsoft Entra ID`; run `SENTLOGG-Validation.ps1`.
- **Implement:** Install the Microsoft Entra ID connector/solution from `Content hub` if it is not already present. (Note: `Repositories`/CI-CD deployment is **not** available in Gov — install from Content hub directly.)

## 2.5 A retention and ingestion budget decision

- **Description:** An agreed retention period (and any long-term/archive tier) and a daily-ingestion estimate for the categories in scope.
- **Why:** Identity sign-in logs can be high-volume; retention drives a large share of cost. This must be decided before connectors are enabled, and retention often maps to a compliance mandate (CMMC / DFARS 7012 / FedRAMP audit-log retention).
- **Verify:** A written estimate and retention decision exist; run `SENTLOGG-Report.ps1` after pilot to confirm actual volume against the estimate.
- **Implement:** Estimate GB/day from the source categories, choose a pricing/commitment tier, and set workspace/table retention.

## 2.6 A pilot scope defined

- **Description:** A named, limited pilot scope — typically Entra ID `SignInLogs` and `AuditLogs` plus Intune `IntuneAuditLogs` into the Azure Government workspace — with success criteria (data is arriving and at least one baseline rule is live).
- **Why:** The standard model validates ingestion on a pilot before enabling higher-volume categories or a wider rule set.
- **Verify:** The pilot categories and pass criteria are written down; run `SENTLOGG-Validation.ps1` to confirm the pilot tables are receiving data.
- **Implement:** Choose the minimum useful category set as the pilot; record the gate (ingestion confirmed) before expanding.

---

## Checklist

- [ ] GCC High tenant + **Azure Government** subscription (`portal.azure.us`) — Requirement 2.0
- [ ] Azure subscription, Log Analytics workspace, and Microsoft Sentinel enabled — see global requirements (verified in the `.us` portal)
- [ ] RBAC on the workspace and Entra ID diagnostic-settings access — `SENTLOGG-Discovery.ps1`
- [ ] Entra ID Government plan exposes the sign-in categories in scope
- [ ] Intune (Gov) in use and generating audit telemetry (`intune.microsoft.us`)
- [ ] Microsoft Entra ID data connector available in Sentinel (Azure Government) — `SENTLOGG-Validation.ps1`
- [ ] Retention period and ingestion budget agreed (mapped to the compliance mandate)
- [ ] Pilot scope and ingestion-confirmed gate defined
- [ ] All tooling targets US Gov endpoints (`-Environment USGov` / `AzureUSGovernment`)
