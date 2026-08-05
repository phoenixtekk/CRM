# Best Practices

## Stay read-only for governance reporting

Inventory and sharing export never need to change an agent. Use **`CopilotPackages.Read.All`**, not the
`ReadWrite` scope. Reserve any change action (block, reassign owner) for the Microsoft 365 admin center,
where it is audited, rather than baking writes into the export.

## Prefer `v1.0` over `beta`, and record the version you used

Both `v1.0` and `beta` expose `/copilot/admin/catalog/packages`. Use **`v1.0`** in the scripts and the
scheduled task for production stability; keep `beta` only for testing a newly documented property. Record
the API version and the run date in the register header so a later reader knows exactly what produced it —
this API is still settling, so provenance matters.

## Make the export recurring — schedule the monthly run

Agent Builder agents are created and shared continuously, so a one-time inventory is stale within weeks.
Schedule **`AGBINV – Monthly Agent Inventory Export`** to run the inventory → sharing → register
sequence app-only (R3), writing a dated register each month into `C:\AgentGovernance\Exports`. Keep the
last 12 months so you can diff month-over-month and see new org-wide shares appear.

- Windows Task Scheduler: create task **`AGBINV – Monthly Agent Inventory Export`**, run whether or not
  the user is logged on, action = `pwsh.exe -File AGBINV-Report-GovernanceRegister.ps1 ...` wrapped in a
  runner that first calls the inventory and sharing scripts with the app-only certificate.

## Triage by sharing scope, not alphabetically

When reviewing the register, sort by **sharing scope** and work the riskiest first:
1. **Org-wide shared** (`availableTo = all` / "Anyone in your organization") — broadest exposure; confirm
   the agent and its knowledge sources are appropriate for everyone.
2. **Shared to large groups** — a single group share can reach hundreds of people.
3. **Ownerless agents** — no accountable owner; decide reassign vs block vs delete.
4. **Specific-user shares** — lowest exposure; spot-check.

## Keep the register access-controlled — it names people

The register lists users and groups by name. Treat it as sensitive: store it in a location restricted to
the governance team (R9), do not email it around, and apply your normal retention policy. Never publish
it to a broadly-shared site.

## Distinguish "can reach" from "has used"

The register records the **allowed audience** (`allowedUsersAndGroups`), not runtime usage. Do not
present it as a usage report. If leadership needs adoption/usage, source that separately from Copilot
usage reporting or the audit log — and label it as a different metric.

## Keep Agent Builder and Copilot Studio governance separate

This register is deliberately scoped to Agent Builder. Your Copilot Studio approval gates govern the
Copilot Studio population; do not merge the two into one list or you lose the meaning of each control.
Keep the platform filter in place on every run.

## Least privilege and time-bound admin

Run governance with **AI Administrator** (read-oriented) rather than Global Administrator, and make the
role assignment **eligible/time-bound** via Privileged Identity Management. The unattended app
(`AGBINV – Agent Governance – Graph Reader`) should hold only `CopilotPackages.Read.All` plus the
minimal directory read needed to resolve names — nothing more.

## Government cloud: use the supported path and re-test the rest

In GCC High/DoD, the Package Management API is not available today — build the register from the admin
center export (Path A) and re-test Path B only after Microsoft documents its availability for your cloud.
Verify Agent Builder availability itself in your Government cloud. **Verify for GCC High** rather than
assuming Commercial behavior.
