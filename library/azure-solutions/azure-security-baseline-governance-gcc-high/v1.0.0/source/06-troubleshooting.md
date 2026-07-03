# Troubleshooting — Azure Security Baseline & Governance (Government / GCC High)

Gov-specific problems and their fixes. Nearly every issue on a GCC High tenant traces back to one root cause: **something is pointed at the Commercial cloud instead of Azure Government.** Check that first, always.

> First response to any weird failure: confirm the cloud. `(Get-AzContext).Environment.Name` must return `AzureUSGovernment`. In the browser, the URL must be `portal.azure.us`, not `portal.azure.com`.

---

## 1. "I signed in but see no subscriptions / resources"

- **Symptom:** `Get-AzSubscription` is empty, or the portal shows an unfamiliar/empty directory.
- **Cause:** Connected to Commercial. `Connect-AzAccount` without the environment switch defaults to `AzureCloud`, and `portal.azure.com` is the Commercial portal.
- **Fix:** `Disconnect-AzAccount`, then `Connect-AzAccount -Environment AzureUSGovernment`. In the browser, go to **`https://portal.azure.us`**. Source: [Connect to Azure Government with PowerShell](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).

## 2. Sign-in redirect / "wrong version number" / TLS or AADSTS redirect errors

- **Symptom:** `Connect-MgGraph` or a portal sign-in throws a redirect/authority error; tokens are rejected.
- **Cause:** Authenticating against the Commercial authority `login.microsoftonline.com` for a Gov tenant homed in `login.microsoftonline.us`, or a proxy that only allows Commercial endpoints.
- **Fix:**
  - Graph: `Connect-MgGraph -Environment USGov` (DoD: `-Environment USGovDoD`). Source: [Microsoft Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments).
  - Confirm firewall/proxy allows `login.microsoftonline.us`, `graph.microsoft.us`, `management.usgovcloudapi.net`. Source: [endpoint mapping](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#guidance-for-developers).

## 3. A Defender for Cloud plan won't turn on / doesn't appear

- **Symptom:** Defender for **App Service**, **Cosmos DB**, or a **Foundry/AI** plan is missing from **Environment settings → Defender plans**, or refuses to save.
- **Cause:** These plans are **Not Available in Azure Government** — this is expected, not a bug.
- **Fix:** Do not enable them. Enable only the Gov-available plans (Servers, Storage, Key Vault, Resource Manager, Containers, DNS, SQL, OSS DBs). Source: [Cloud feature availability — Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud).

## 4. "Recommendation exemption" option is missing in Defender for Cloud

- **Symptom:** You cannot exempt an individual Defender recommendation.
- **Cause:** **Recommendation exemption rules** are **Not Available** in Azure Government.
- **Fix:** Use an **Azure Policy exemption** at the appropriate scope instead, or narrow the policy scope. Source: [Cloud feature availability — Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud).

## 5. Every deployment is suddenly blocked after assigning the policy initiative

- **Symptom:** `RequestDisallowedByPolicy` on all deployments, citing the Allowed Locations policy.
- **Cause:** A **Commercial region name** (e.g. `eastus`) is in the **Allowed Locations** parameter. That region does not exist in the Gov cloud, so nothing can deploy.
- **Fix:** Edit **`Security Baseline Initiative – Governance Root – Pilot`** → Parameters → set Allowed Locations to Gov regions only: `usgovvirginia`, `usgovtexas`, `usgovarizona` (and DoD if scoped). Source: [Connect with PowerShell — regions](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).

## 6. Legitimate work is blocked by a pilot `Deny` policy

- **Symptom:** A required workload fails with a policy `Deny` during pilot.
- **Cause:** The `Deny` effect is too broad for a genuine exception.
- **Fix:** Add a scoped **Azure Policy exemption** for the specific resource/RG, or adjust the policy parameter. Do **not** reach for Defender recommendation exemptions (unavailable in Gov). Re-run `AZSECG-Validation.ps1` after the change.

## 7. Management groups option is greyed out / root not visible

- **Symptom:** Cannot create `Governance Root MG`; management groups won't load.
- **Cause:** Management groups not yet initialized, or missing root-scope access.
- **Fix:** A Global Administrator elevates access once (Entra ID → Properties → *Access management for Azure resources* → Yes) to get `User Access Administrator` at root, clicks **Start using management groups** in `portal.azure.us`, creates the hierarchy, then removes the elevation. Behaves as Commercial but done in the Gov portal. Source: [Compare Azure Government — Management and governance](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#management-and-governance).

## 8. "Just-in-time / eligible" role activation isn't available

- **Symptom:** You expected to grant PIM-eligible (JIT) access via Azure Lighthouse and the option is absent.
- **Cause:** In Azure Government, **Azure Lighthouse PIM (eligible/JIT) authorization is not enabled**, and cross-cloud Lighthouse delegation is unsupported.
- **Fix:** Use standing, tightly scoped RBAC (the custom role `Governance Operator – Landing Zones – Pilot`), add Conditional Access, and document this as a compensating control. Source: [Compare Azure Government — Azure Lighthouse](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-lighthouse).

## 9. MFA "Trusted IPs" setting is missing

- **Symptom:** You cannot configure Trusted IPs for MFA bypass on trusted networks.
- **Cause:** **Trusted IPs is not supported** in Azure Government.
- **Fix:** Use **Conditional Access named locations** to control when MFA is required. Source: [Compare Azure Government — Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#microsoft-entra-id-p1-and-p2).

## 10. Log Analytics workspace has no data / can't move Commercial data in

- **Symptom:** No rows in the workspace, or an attempt to migrate a Commercial workspace fails.
- **Cause:** Wrong endpoints allowed, wrong region, or an attempt to migrate data between clouds (not possible).
- **Fix:** Confirm the workspace `Governance Logs Workspace – Platform – Pilot` is in a **US Gov region**, diagnostic settings point to it, and firewall allows `*.opinsights.azure.us` / `oms.microsoft.us`. **Data cannot be migrated between Commercial and Gov** — start fresh in Gov. Source: [Compare Azure Government — Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-monitor).

## 11. Regulatory-compliance dashboard shows different / fewer standards than Commercial

- **Symptom:** The standards list in **Defender for Cloud → Regulatory compliance** differs from a Commercial tenant.
- **Cause:** Expected — "there may be differences in the standards offered per cloud type."
- **Fix:** Use the standards that render in your Gov subscription. Confirm coverage before relying on a specific standard (**verify for Azure Government**). Source: [Cloud feature availability — Microsoft Defender for Cloud, footnote 4](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud).

## 12. A built-in policy initiative or preview feature is missing

- **Symptom:** The exact built-in initiative or a preview capability you used in Commercial isn't present.
- **Cause:** Built-in definitions and preview features can lag in Gov (Public Preview items often show Not Available in Gov first).
- **Fix:** Pick an available initiative in `portal.azure.us`, or build a custom initiative from available definitions. Re-check the [feature availability page](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability) at deployment time. Flag anything unconfirmed as **verify for Azure Government**.

## 13. A script says it refuses to run because the cloud is wrong

- **Symptom:** `AZSECG-*.ps1` exits with an environment-guard error.
- **Cause:** By design — the scripts fail fast if `(Get-AzContext).Environment.Name` is not `AzureUSGovernment`, to prevent acting on the wrong cloud.
- **Fix:** `Connect-AzAccount -Environment AzureUSGovernment` (and `Connect-MgGraph -Environment USGov` where the script uses Graph), then re-run.

---

## Escalation checklist

Before opening a support case, capture:

1. `(Get-AzContext).Environment.Name` and `.ResourceManagerUrl` (prove you're in Gov).
2. `Get-AzEnvironment -Name AzureUSGovernment` output (endpoints).
3. The exact error text and the object name involved (use the verbatim names from `03-implementation.md`).
4. A fresh `AZSECG-Discovery.ps1` and `AZSECG-Validation.ps1` output.
5. Whether the feature is listed **Not Available** in Gov on the [feature availability page](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability) — if so, it's a parity gap, not a fault.
