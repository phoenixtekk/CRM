# Implementation Guide — Azure Security Baseline & Governance (Government / GCC High)

This guide gives the exact, ordered steps to deploy the governance baseline on an **Azure Government / GCC High** tenant using the sovereign portal **`https://portal.azure.us`**. Gov-specific caveats appear inline at the step where they matter.

**Before you start:** complete every requirement in `02-requirements.md`. Sign in at **`https://portal.azure.us`** — if the URL bar shows `portal.azure.com`, stop; you are in Commercial Azure and these steps do not apply.

**Object names (created once, reused verbatim):**

| Object | Name |
| --- | --- |
| Governance root management group | `Governance Root MG` |
| Platform management group | `Platform MG` |
| Landing zones management group | `Landing Zones MG` |
| Custom RBAC role | `Governance Operator – Landing Zones – Pilot` |
| Policy initiative assignment | `Security Baseline Initiative – Governance Root – Pilot` |
| Log Analytics workspace | `Governance Logs Workspace – Platform – Pilot` |
| Pilot subscription tag | `governance-stage = pilot` |

Follow the stages in order. Do not skip the pass/fail gate at the end of each stage.

---

## Stage A — Assess (read-only baseline)

**A1.** Open PowerShell and connect to Azure Government:

```powershell
Connect-AzAccount -Environment AzureUSGovernment
Get-AzEnvironment -Name AzureUSGovernment   # confirm endpoints resolve to *.usgovcloudapi.net
Get-AzSubscription                          # note the pilot subscription id
```

> **Gov caveat:** The `-Environment AzureUSGovernment` switch is mandatory. Without it, `Connect-AzAccount` targets Commercial endpoints and will not see your Gov subscriptions. Source: [Connect to Azure Government with PowerShell](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).

**A2.** Run the discovery script (read-only) to capture the current state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Discovery.ps1 -SubscriptionId your-subscription-id
```

Review the output: current management groups, standing role assignments, policy assignments, Defender for Cloud plan status, and Secure Score. This is your rollback reference (requirement G6).

**Gate A (pass/fail):** Discovery completes without error, lists your Gov subscription(s), and reports no blocking prerequisite gaps. **Fail** = fix prerequisites in `02-requirements.md` before continuing.

---

## Stage B — Configure (build objects, audit mode)

### B1. Enable and build the management-group hierarchy

1. In **`portal.azure.us`**, search **Management groups**. If prompted, click **Start using management groups**.
2. On the `Tenant Root Group`, click **+ Create** → Name/ID: **`Governance Root MG`** → **Submit**.
3. Inside `Governance Root MG`, **+ Create** → **`Platform MG`**. Repeat for **`Landing Zones MG`**.
4. Move your pilot subscription under `Landing Zones MG` (select the subscription → **Details** → **Move**).

> **Gov caveat:** Management groups behave as in Commercial but are managed only through `portal.azure.us`. Source: [Compare Azure Government — Management and governance](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#management-and-governance).

### B2. Create the Log Analytics workspace

1. Search **Log Analytics workspaces** → **+ Create**.
2. Resource group: create or select one in a **US Gov region**. Region: **`USGov Virginia`** (or your target Gov region). Name: **`Governance Logs Workspace – Platform – Pilot`** → **Review + Create** → **Create**.

> **Gov caveat:** The workspace lives on `*.opinsights.azure.us` / `oms.microsoft.us` endpoints and **cannot** be migrated to/from Commercial. Choose the correct Gov region now. Source: [Compare Azure Government — Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-monitor).

### B3. Create the least-privilege custom RBAC role

1. Go to **`Landing Zones MG`** → **Access control (IAM)** → **+ Add** → **Add custom role**.
2. Name: **`Governance Operator – Landing Zones – Pilot`**. Baseline permissions: read all resources, manage policy assignments and diagnostic settings, but **not** role assignments or resource deletion. Assignable scope: `Landing Zones MG`.
3. **Review + create**.
4. Assign it to your governance operators (IAM → **+ Add role assignment** → select the custom role → assign to the operating group).

> **Gov caveat:** In Azure Government, **Azure Lighthouse PIM (eligible/JIT) authorization is not enabled** — this assignment is standing, not "eligible." If your Commercial design used PIM-eligible activation, document a compensating control (e.g. tight scope + Conditional Access). Source: [Compare Azure Government — Azure Lighthouse](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-lighthouse).

### B4. Assign the Azure Policy security-baseline initiative (AUDIT effect first)

1. Search **Policy** → **Assignments** → **Assign initiative**.
2. Scope: **`Governance Root MG`**. Initiative: choose a secure-configuration initiative (e.g. the built-in **Microsoft cloud security benchmark**, or a custom initiative bundling: deny/audit public blob access, require storage encryption, **allowed locations = US Gov regions only**, audit missing diagnostic settings).
3. Assignment name: **`Security Baseline Initiative – Governance Root – Pilot`**.
4. **Parameters:** set **Allowed locations** to `usgovvirginia`, `usgovtexas`, `usgovarizona` (and DoD regions if in scope) — **never** Commercial regions like `eastus`.
5. **Set the effect to `Audit` / `AuditIfNotExists`** for this stage (not `Deny`). **Review + create**.

> **Gov caveat:** Azure Policy is available in Azure Government and works the same, but the **Allowed Locations** values must be Gov region names. Using Commercial region names would silently block all deployments. Source: [Connect to Azure Government with PowerShell — regions](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).

### B5. Enable Microsoft Defender for Cloud (Gov-available plans only)

1. Search **Microsoft Defender for Cloud** → **Environment settings** → select your pilot subscription → **Defender plans**.
2. Turn **On** only the plans available in Azure Government: **Servers, Storage, Key Vault, Resource Manager, Containers, DNS, Azure SQL, SQL servers on machines, open-source relational databases**.
3. **Do NOT** attempt to enable **App Service, Cosmos DB, or Foundry/AI** plans — they are **Not Available** in Azure Government and will not appear or will not save. Source: [Cloud feature availability — Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud).
4. Under **Settings & monitoring**, point continuous export / workspace to **`Governance Logs Workspace – Platform – Pilot`**.

> **Gov caveat:** **Recommendation exemption rules**, **Adaptive network hardening**, **Integrated VA for machines (legacy)**, and **AWS/GCP connectors** are Not Available in Gov. Do not build runbooks that depend on them. For VM vulnerability findings, rely on Defender for Servers' Microsoft Defender Vulnerability Management integration (verify plan coverage in your tenant).

**Gate B (pass/fail):** All objects exist with the **exact** names above; the policy initiative is assigned in `Audit`/`AuditIfNotExists`; only Gov-available Defender plans are on. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Validation.ps1 -SubscriptionId your-subscription-id
```

**Fail** = a named object is missing, an unavailable plan was attempted, or a Commercial region slipped into Allowed Locations. Correct before piloting.

---

## Stage C — Pilot (one subscription, guardrails live)

**C1.** Tag the pilot subscription: **Subscriptions → (pilot) → Tags** → add `governance-stage = pilot`. Or use the targeting script:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Set-ScopeTargeting.ps1 -SubscriptionId your-subscription-id -Stage pilot   # runs -WhatIf by default
```

Review the `-WhatIf` output, then re-run with `-Apply` to commit.

**C2.** For the pilot scope only, change the highest-impact policies from `Audit` to **`Deny`** (e.g. deny public blob storage, deny non-Gov locations). Edit the assignment **`Security Baseline Initiative – Governance Root – Pilot`** parameters, or create a pilot-scoped override at the pilot subscription.

**Gate C (pass/fail):** Validation passes on the pilot scope and no legitimate deployment is unexpectedly blocked. **Fail** = a `Deny` blocks a required workload → adjust the policy parameter or add a scoped exemption (note: use **policy exemptions**, not Defender recommendation exemptions, which are unavailable in Gov).

---

## Stage D — Validate (evidence)

**D1.** Confirm compliance and Secure Score movement:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Validation.ps1 -SubscriptionId your-subscription-id
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Report.ps1 -SubscriptionId your-subscription-id -OutputPath .\AZSECG-report.html
```

**D2.** In **`portal.azure.us`** → **Defender for Cloud → Regulatory compliance**, confirm the compliance dashboard renders (available in Gov; standards offered may differ from Commercial — Source: [Cloud feature availability — footnote 4](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud)).

**D3.** Confirm logs are flowing to **`Governance Logs Workspace – Platform – Pilot`** (workspace → **Logs** → query `AzureActivity | take 10`).

**Gate D (pass/fail):** Validation + Report show target compliance, Secure Score is tracked, and logs are arriving. Record sign-off. **Fail** = remediate the flagged items (see `05-testing.md`) and re-run.

---

## Stage E — Expand (remaining subscriptions)

**E1.** For each additional subscription, move it under `Landing Zones MG` and tag it, or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Set-ScopeTargeting.ps1 -SubscriptionId next-subscription-id -Stage expand   # -WhatIf by default; add -Apply to commit
```

**E2.** Promote the validated policy effects (`Deny`) from pilot to the expanded scope by adjusting the assignment scope/parameters. If broad remediation is needed, run the remediation helper (defaults to `-WhatIf`):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Remediation.ps1 -SubscriptionId next-subscription-id           # preview
powershell -ExecutionPolicy Bypass -File .\scripts\AZSECG-Remediation.ps1 -SubscriptionId next-subscription-id -Apply    # commit
```

**Gate E (pass/fail):** Each expanded subscription passes `AZSECG-Validation.ps1`; rollback is rehearsed (requirement G6). **Fail** = roll the subscription back to `Audit` effect, fix, and re-expand.

---

## Rollback (any stage)

- **Policy:** set the assignment effect back to `Audit`/`Disabled` or delete the assignment `Security Baseline Initiative – Governance Root – Pilot`.
- **RBAC:** remove the assignment of `Governance Operator – Landing Zones – Pilot`; the custom role definition can remain.
- **Defender plans:** set the changed plans back to **Off** on the subscription.
- **Management groups:** move subscriptions back to `Tenant Root Group` and delete the empty MGs.

All rollback actions are performed in `portal.azure.us` or via Az PowerShell connected with `-Environment AzureUSGovernment`.
