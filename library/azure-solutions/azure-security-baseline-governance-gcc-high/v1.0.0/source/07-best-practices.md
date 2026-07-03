# Best Practices — Azure Security Baseline & Governance (Government / GCC High)

Operating guidance for running the governance baseline on an **Azure Government / GCC High** tenant over time. These practices assume the baseline from `03-implementation.md` is deployed and validated.

---

## 1. Always confirm the cloud before you act

The single most common Gov mistake is operating against the Commercial cloud by habit.

- Bookmark **`https://portal.azure.us`** (Azure) and **`https://portal.office365.us`** (M365/Entra admin). Delete or clearly label any `portal.azure.com` bookmark.
- In scripts, **fail fast** if the context is not Gov: check `(Get-AzContext).Environment.Name -eq 'AzureUSGovernment'` before any write. All five solution scripts do this.
- Standardize on `Connect-AzAccount -Environment AzureUSGovernment` and `Connect-MgGraph -Environment USGov` in every runbook. Source: [Connect to Azure Government with PowerShell](https://learn.microsoft.com/en-us/azure/azure-government/documentation-government-get-started-connect-with-ps).

## 2. Least privilege — standing scope, documented compensating controls

- Assign RBAC at the **highest management-group scope** you truly need, and let inheritance do the rest — don't sprinkle per-subscription `Owner`.
- Prefer the custom role **`Governance Operator – Landing Zones – Pilot`** over built-in `Contributor` for day-to-day governance work.
- **Gov reality:** Azure Lighthouse **PIM eligible/JIT authorization is not enabled** in Azure Government, so "just-in-time" role activation via Lighthouse is unavailable. Compensate with tight scope, Conditional Access, and periodic access reviews — and **document** that PIM-eligible access is not available in this cloud. Source: [Compare Azure Government — Azure Lighthouse](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-lighthouse).

## 3. Policy-first guardrails, audit before deny

- Roll out every new policy as **`Audit`/`AuditIfNotExists`** first, observe compliance, then promote to **`Deny`** on the pilot scope, then expand.
- Keep **Allowed Locations** pinned to Gov regions (`usgovvirginia`, `usgovtexas`, `usgovarizona`, DoD as needed). Re-check this parameter after any template import — a stray Commercial region name blocks every deployment in the Gov cloud.
- Use **Azure Policy exemptions** for legitimate exceptions. Do **not** design around **Defender recommendation exemption rules** — they are **Not Available** in Azure Government. Source: [Cloud feature availability — Microsoft Defender for Cloud](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability#microsoft-defender-for-cloud).

## 4. Enable only the Defender plans that exist in Gov

- Enable and keep on: **Servers, Storage, Key Vault, Resource Manager, Containers, DNS, Azure SQL, SQL on machines, open-source relational DBs**.
- Never build automation that assumes **App Service, Cosmos DB, Foundry/AI, adaptive network hardening, integrated legacy VA, or AWS/GCP connectors** — all Not Available in Gov.
- For VM vulnerability findings, use Defender for Servers with the **Microsoft Defender Vulnerability Management** integration rather than the legacy built-in scanner (verify plan coverage in your tenant, and flag "verify for Azure Government" if a specific sub-feature is not confirmed for your region).

## 5. Centralize audit logging in-cloud, keep it in-cloud

- Send activity and diagnostic logs to **`Governance Logs Workspace – Platform – Pilot`** in a US Gov region.
- **Data cannot be migrated** between Commercial and Gov workspaces — pick the right region once. Source: [Compare Azure Government — Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#azure-monitor).
- Store exported audit evidence only on Gov storage (`blob.core.usgovcloudapi.net`), never a Commercial account, to preserve data-residency and export-control posture.

## 6. Identity hardening the Gov way

- Enforce MFA with **Conditional Access named locations**, not **Trusted IPs** — Trusted IPs is **not supported** in Azure Government. Source: [Compare Azure Government — Microsoft Entra ID](https://learn.microsoft.com/en-us/azure/azure-government/compare-azure-government-global-azure#microsoft-entra-id-p1-and-p2).
- Be aware **B2B collaboration** has known limitations in Gov and **Azure AD B2C is not available** — do not design external-identity flows that depend on them without verifying availability in your tenant.

## 7. Change control, rollback, and evidence

- Treat every `Deny` promotion and scope expansion as a change record with a scheduled window (requirement G5) and a rehearsed rollback (requirement G6).
- Capture a fresh **discovery** snapshot before each change and a **validation + report** snapshot after — these are your before/after audit evidence.
- Rehearse rollback (policy → `Audit`, remove RBAC assignment, Defender plan → Off, MG move-back) at least once before expanding beyond the pilot.

## 8. Keep tooling current and Gov-aware

- Keep the **Az** and **Microsoft.Graph** modules current so the `AzureUSGovernment` / `USGov` environment switches resolve.
- Re-verify endpoints periodically with `Get-AzEnvironment -Name AzureUSGovernment` — Microsoft occasionally adds Gov endpoints as parity improves.
- Track Microsoft's [Cloud feature availability](https://learn.microsoft.com/en-us/azure/security/fundamentals/feature-availability) page; Gov parity gaps close over time, and a feature marked Not Available today may become GA — re-confirm before relying on it.

## 9. Naming discipline

Reuse the exact object names from `03-implementation.md` in every script, ticket, and audit artifact. Consistent `<Purpose> – <Scope> – <Stage>` naming makes validation deterministic and audit review fast.
