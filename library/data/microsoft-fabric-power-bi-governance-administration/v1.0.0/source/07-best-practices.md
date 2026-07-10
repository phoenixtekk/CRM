# 7. Best Practices — Microsoft Fabric & Power BI Governance & Administration

Guidance to keep the platform governed after go-live, and where to go next in the catalog.

## Keep tenant settings clean
- **Scope to groups, never the whole org by reflex.** "Enabled for the entire organization" is the
  setting most likely to cause a later incident. Prefer "enabled for specific security groups" or
  "enabled for the entire organization except" and manage membership, not the setting.
- **Pilot every disruptive change on `Governance Pilot Ring – Fabric – Ring1` first**, then expand under
  change control with a recorded before-value and rollback. Tenant settings affect every user.
- **Change one setting at a time** and re-validate. Batched tenant-wide changes make regressions
  impossible to attribute.
- **Review the risky exports quarterly** — Publish to web, Export to Excel/CSV, external sharing,
  guest access. These are where data leaves the platform.

## Keep the access model clean
- **Roles go to groups.** If you ever assign a workspace role to a person, treat it as debt to clean up.
- **Minimize Prod edit rights.** Production content changes through `Deployment Pipeline – Sales BI –
  DevTestProd`, not by editing `Sales BI – Content – Prod` directly.
- **Gate workspace creation** (`BI Creators – Analytics – Pilot` / your production creator group) so the
  workspace list stays intentional, and reclaim orphaned or personal-turned-shared workspaces the
  discovery script flags.
- **Use certification deliberately** — only `BI Content Certifiers – Analytics – Prod` marks content
  Certified, and only after it is genuinely production-quality, so the endorsement means something.

## Keep capacity healthy and costs visible
- **Watch the Fabric Capacity Metrics app** for throttling and overload on
  `Fabric Capacity – Analytics – Prod`; size the capacity to the measured peak, not a guess.
- **Run `FABGOV-Report.ps1` on a schedule** and review utilization and sharing/export trends at a fixed
  governance cadence. Unexplained spend or a spike in exports is a signal, not noise.
- **Assign workspaces to capacity on purpose** — keep dev/experimental content off the production
  capacity where it can starve real workloads.

## Keep monitoring honest
- **Prefer read-only discovery.** The discovery, validate, and report scripts are read-only by default;
  keep them that way and run change scripts (tenant settings, provisioning) preview-first.
- **Run unattended monitoring as a service principal** (`Fabric Admin API Apps – Platform – Prod`), not
  a person's account, so reporting survives staff changes.
- **Keep the change-control record** of every tenant-setting change; it is your audit trail and your
  rollback map.

## Defer the decisions that are not yours
- **Data classification** — which content is confidential, and the labeling/DLP policy — is the
  compliance team's decision, delivered through Microsoft Purview, not the Fabric admin surface.
- **Regulatory, records-retention, and legal determinations** belong to compliance/legal; this guide
  provides platform controls, not the policy.
- **Which capabilities to allow** (external sharing, publish to web) is a business risk decision; you
  implement and pilot it, the business owns it.

## Where to go next (adjacent catalog areas)
- **Microsoft Purview — information protection for Power BI/Fabric** (sensitivity labels + DLP) and
  **Purview reporting** — for the classification layer this solution deliberately does not cover.
- **Microsoft Entra identity & groups solutions** — to industrialize the security-group model that every
  tenant setting and workspace role depends on.
- **Data-platform reporting solutions** (for example license usage & cost dashboards in Power BI) — once
  the platform is governed, build governed content on top of it.
- **Azure monitoring / cost-management solutions** — to fold Fabric capacity spend into broader FinOps
  reporting.
