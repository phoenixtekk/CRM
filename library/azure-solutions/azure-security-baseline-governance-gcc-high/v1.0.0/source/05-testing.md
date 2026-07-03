# Testing & Validation — Azure Security Baseline & Governance (Government / GCC High)

This section defines the pass/fail tests that prove the governance baseline is correctly deployed on your **Azure Government / GCC High** tenant. Every check is performed against **US Gov endpoints** (`portal.azure.us`, `management.usgovcloudapi.net`, `graph.microsoft.us`). The `AZSECG-Validation.ps1` and `AZSECG-Report.ps1` scripts automate most of these; the portal checks are the manual confirmation.

> Connect first: `Connect-AzAccount -Environment AzureUSGovernment` (Az) and, where directory checks are needed, `Connect-MgGraph -Environment USGov`. If either connects to a Commercial endpoint, every test below is invalid.

---

## Test matrix

| # | Test | How to run | Pass criteria |
| --- | --- | --- | --- |
| T1 | Correct cloud | `(Get-AzContext).Environment.Name` | Returns **`AzureUSGovernment`** |
| T2 | Management-group hierarchy exists | `Get-AzManagementGroup` | `Governance Root MG`, `Platform MG`, `Landing Zones MG` all present |
| T3 | Custom RBAC role exists & scoped | `Get-AzRoleDefinition "Governance Operator – Landing Zones – Pilot"` | Role exists; assignable scope = `Landing Zones MG`; no `*/delete` or `Microsoft.Authorization/roleAssignments/write` |
| T4 | Policy initiative assigned | `Get-AzPolicyAssignment -Name "Security Baseline Initiative – Governance Root – Pilot"` | Assignment present at `Governance Root MG` |
| T5 | Allowed Locations = Gov regions only | Inspect initiative parameters | Only `usgovvirginia`, `usgovtexas`, `usgovarizona` (+DoD if scoped); **no** Commercial regions |
| T6 | Defender plans = Gov-available only | `Get-AzSecurityPricing` | Servers/Storage/KeyVault/ARM/Containers/DNS/SQL/OSS-DB = `Standard`; App Service/CosmosDB/AI **not** attempted |
| T7 | Log workspace receiving data | Workspace → Logs → `AzureActivity | take 10` | Rows returned within the last 24h |
| T8 | Secure Score tracked | Defender for Cloud → Secure Score | Score renders; baseline recorded |
| T9 | Compliance dashboard renders | Defender for Cloud → Regulatory compliance | Dashboard loads (standards may differ from Commercial) |
| T10 | Pilot Deny works | Attempt a public blob or non-Gov-region deploy on pilot | Deployment is **denied** by policy |

Run the automated pass:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Validation.ps1 -SubscriptionId your-subscription-id
```

A green result requires every applicable row above to pass.

---

## Detailed procedures

### T1 — Confirm you are in Azure Government (do this first)
```powershell
(Get-AzContext).Environment.Name    # must be AzureUSGovernment
(Get-AzContext).Environment.ResourceManagerUrl   # must be https://management.usgovcloudapi.net/
```
**Fail** (returns `AzureCloud` / `management.azure.com`): disconnect (`Disconnect-AzAccount`) and reconnect with `-Environment AzureUSGovernment`. Do not proceed on a wrong-cloud context.

### T5 — Allowed Locations must be Gov regions
In `portal.azure.us` → **Policy → Assignments → `Security Baseline Initiative – Governance Root – Pilot` → Parameters**, confirm the allowed-locations list. A single Commercial region name here will block **all** deployments in a Gov subscription (the region does not exist in the Gov cloud). **Fail** = remove any non-Gov region and re-save.

### T6 — Only Gov-available Defender plans enabled
```powershell
Get-AzSecurityPricing | Select-Object Name, PricingTier
```
Confirm the enabled (`Standard`) plans are within the Gov-available set. If you find `AppServices`, `CosmosDbs`, or an AI/Foundry plan attempted, that is a configuration error — those are Not Available in Azure Government. Source: [Cloud feature availability — Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud). **Fail** = disable the unavailable plan attempt.

### T10 — Confirm the pilot Deny actually blocks
On the **pilot** subscription (`governance-stage = pilot`), attempt to create a storage account with public blob access enabled, or deploy a resource to a Commercial region. Expect a `RequestDisallowedByPolicy` error citing `Security Baseline Initiative – Governance Root – Pilot`. **Fail** (deployment succeeds) = the effect is still `Audit`; switch the relevant policy to `Deny` for the pilot scope and retry.

---

## Regression / re-test cadence

- Re-run `AZSECG-Validation.ps1` after every expansion step (Stage E) and after any policy edit.
- Regenerate the report for audit evidence:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Report.ps1 -SubscriptionId your-subscription-id -OutputPath .\AZSECG-report.html
  ```
- Keep each dated report as FedRAMP High audit evidence; store it in the Gov-region Log Analytics workspace or an approved Gov storage account (`blob.core.usgovcloudapi.net`), never a Commercial store.

**Exit criteria for "baseline validated":** T1–T9 pass on every in-scope subscription, T10 passes on the pilot, the report is generated, and rollback has been rehearsed at least once.
