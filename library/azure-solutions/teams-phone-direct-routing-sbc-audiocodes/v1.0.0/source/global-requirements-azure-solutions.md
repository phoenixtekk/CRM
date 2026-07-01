# Global Requirements — Azure Solutions

These are the category-wide prerequisites shared by every solution in the **Azure Solutions** catalog. They are generic and apply regardless of the specific technology being deployed. Each solution's own `02-requirements.md` adds the requirements specific to that product; this document covers the baseline that must be true for any Azure/Microsoft 365 cloud engagement. Apply the same discipline to each: **Description / Why / Verify / Implement if missing** — never assume a baseline is already in place.

---

## G1 — A Microsoft 365 / Azure tenant

- **Description.** An active Microsoft 365 (and/or Azure) tenant that will host the workload.
- **Why.** All configuration objects (users, policies, services) live in the tenant; without it there is nothing to configure.
- **Verify.** Sign in to the Microsoft 365 admin center (admin.microsoft.com) and confirm the tenant is active and the organization name/initial domain are correct.
- **Implement if missing.** Provision a Microsoft 365 tenant (or Azure subscription) and complete initial tenant setup.

## G2 — Administrative roles (least privilege)

- **Description.** Accounts holding the specific administrative roles the work requires (for example Teams Administrator, User Administrator), scoped to least privilege rather than blanket Global Administrator where possible.
- **Why.** Each configuration action requires an appropriate role; over-privileged accounts increase risk.
- **Verify.** Microsoft Entra admin center → **Roles and administrators** lists the role holders; confirm the executing account has exactly the roles needed.
- **Implement if missing.** Assign the required roles in Entra (consider Privileged Identity Management for just-in-time elevation), and use a dedicated admin account, not a daily-driver identity.

## G3 — Licensing baseline

- **Description.** The base Microsoft 365 / Azure licensing that the solution's specific SKUs build upon (for example user licenses that the workload's add-ons attach to).
- **Why.** Most workloads require a base license plus feature-specific entitlements; missing base licensing blocks assignment of the workload's capabilities.
- **Verify.** Microsoft 365 admin center → **Billing → Licenses** shows owned and available SKUs and assignment counts.
- **Implement if missing.** Acquire the base licenses and assign them (directly or via group-based licensing) before assigning workload-specific entitlements.

## G4 — Network reachability to Microsoft / Azure endpoints

- **Description.** Network egress (and any required inbound rules) permitting traffic to the Microsoft 365 / Azure service endpoints the workload depends on, per Microsoft's published URL/IP ranges.
- **Why.** Cloud workloads fail silently or intermittently when required endpoints are blocked, proxied incorrectly, or TLS-inspected.
- **Verify.** Confirm firewall/proxy policy allows the workload's documented endpoints and that TLS inspection is excluded where Microsoft requires it.
- **Implement if missing.** Update firewall/proxy rules to permit Microsoft's published endpoint ranges for the workload and exclude them from break-and-inspect where directed.

## G5 — Administration tooling (PowerShell / portals)

- **Description.** The management surfaces the solution uses — the relevant admin center(s) and any required PowerShell modules at a supported version.
- **Why.** Configuration steps reference specific portals and cmdlets; outdated or missing modules cause command failures.
- **Verify.** Confirm portal access for the admin account and that the required modules import successfully at a current version.
- **Implement if missing.** Install/update the required PowerShell modules and confirm portal access before starting implementation.

## G6 — Change control

- **Description.** An approved change process — scheduled window, documented steps, named approvers, and a communication plan for affected users.
- **Why.** Tenant-wide changes can affect production services; controlled change limits risk and provides an audit trail.
- **Verify.** A change ticket exists with scope, schedule, approvers, and back-out criteria.
- **Implement if missing.** Create the change record and obtain approvals before making production changes.

## G7 — Test users and pilot scope

- **Description.** Non-critical test users (and a defined pilot group) used to validate configuration before broad rollout.
- **Why.** Testing on real-but-low-impact accounts catches issues without affecting the whole organization.
- **Verify.** A named set of test/pilot users exists with appropriate licensing.
- **Implement if missing.** Designate test users, license them, and document the pilot membership.

## G8 — Rollback plan

- **Description.** A documented way to reverse each change (the inverse operation for every forward step) and restore the prior state.
- **Why.** Any production change must be reversible to recover quickly from unexpected impact.
- **Verify.** Each forward step in the implementation has a recorded reverse operation and the team has rehearsed/confirmed it.
- **Implement if missing.** Document the reverse of each step (and any export/backup of current configuration) before applying changes.

## G9 — Documentation and audit trail

- **Description.** A record of what was configured (object names, values, dates, executing admin) and where it lives.
- **Why.** Operability, troubleshooting, and audits all depend on knowing the as-built state.
- **Verify.** Configuration is captured (for example via the solution's discovery/report scripts) and stored with the change record.
- **Implement if missing.** Run the solution's discovery/report tooling and retain the output as the as-built baseline.
