# 2. Requirements Guide — Entra ID & Intune Audit Telemetry to Microsoft Sentinel

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (Azure subscription, Log Analytics workspace, Microsoft Sentinel enabled, RBAC, ingestion/retention cost plan, diagnostic-settings capability, change control) are in `global-requirements-sentinel-solutions.md`; do not repeat them — confirm them there first.

## 2.1 Entra ID licensing for the sign-in categories in scope

- **Description:** An Entra ID plan that exposes the sign-in log categories you intend to route. Basic sign-in/audit logs are broadly available; some categories (for example risky-sign-in detail) require Entra ID P1/P2.
- **Why:** A diagnostic setting can only forward categories the tenant's license exposes; missing license means missing data.
- **Verify:** `entra.microsoft.com` → `Identity` → `Overview` (license shown), or M365 admin center → `Billing` → `Licenses`.
- **Implement:** Assign the required Entra ID plan (often included in M365 E3/E5) for the categories you need.

## 2.2 Entra ID diagnostic-settings access

- **Description:** A role that can create an Entra ID diagnostic setting that forwards logs to the workspace.
- **Why:** Routing Entra ID `SignInLogs` and `AuditLogs` is done through `Monitoring & health` → `Diagnostic settings`; editing it requires the right role.
- **Verify:** `entra.microsoft.com` → `Monitoring & health` → `Diagnostic settings` loads and `Add diagnostic setting` is available; run `SENTLOG-Discovery.ps1`.
- **Implement:** Hold a role that can edit Entra ID diagnostic settings (for example Security Administrator or Global Administrator), scoped per least privilege.

## 2.3 Microsoft Intune in the tenant

- **Description:** Microsoft Intune licensed and in use, generating device/compliance/enrollment audit telemetry.
- **Why:** This solution routes Intune audit telemetry; there must be Intune activity to route.
- **Verify:** `intune.microsoft.com` loads with managed devices present; `Tenant administration` → `Audit logs` shows events.
- **Implement:** License Intune (M365 E3/E5 or Business Premium) and confirm devices are enrolled.

## 2.4 The Entra ID data connector available in Sentinel

- **Description:** The Microsoft Entra ID data connector present in the Sentinel content/connectors gallery on the in-scope workspace.
- **Why:** The connector is the supported, point-and-click way to bring Entra ID logs into Sentinel and surface the matching baseline analytics rule templates.
- **Verify:** `portal.azure.com` → `Microsoft Sentinel` → (workspace) → `Configuration` → `Data connectors` → search `Microsoft Entra ID`; run `SENTLOG-Validation.ps1`.
- **Implement:** Install the Microsoft Entra ID connector/solution from `Content hub` if it is not already present.

## 2.5 A retention and ingestion budget decision

- **Description:** An agreed retention period (and any long-term/archive tier) and a daily-ingestion estimate for the categories in scope.
- **Why:** Identity sign-in logs can be high-volume; retention drives a large share of cost. This must be decided before connectors are enabled.
- **Verify:** A written estimate and retention decision exist; run `SENTLOG-Report.ps1` after pilot to confirm actual volume against the estimate.
- **Implement:** Estimate GB/day from the source categories, choose a pricing/commitment tier, and set workspace/table retention.

## 2.6 A pilot scope defined

- **Description:** A named, limited pilot scope — typically Entra ID `SignInLogs` and `AuditLogs` plus Intune audit telemetry into the workspace — with success criteria (data is arriving and at least one baseline rule is live).
- **Why:** The standard model validates ingestion on a pilot before enabling higher-volume categories or a wider rule set.
- **Verify:** The pilot categories and pass criteria are written down; run `SENTLOG-Validation.ps1` to confirm the pilot tables are receiving data.
- **Implement:** Choose the minimum useful category set as the pilot; record the gate (ingestion confirmed) before expanding.

---

## Checklist

- [ ] Azure subscription, Log Analytics workspace, and Microsoft Sentinel enabled — see global requirements
- [ ] RBAC on the workspace and Entra ID diagnostic-settings access — `SENTLOG-Discovery.ps1`
- [ ] Entra ID plan exposes the sign-in categories in scope
- [ ] Intune in use and generating audit telemetry
- [ ] Microsoft Entra ID data connector available in Sentinel — `SENTLOG-Validation.ps1`
- [ ] Retention period and ingestion budget agreed
- [ ] Pilot scope and ingestion-confirmed gate defined
