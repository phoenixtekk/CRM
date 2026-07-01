# Global Requirements — Infrastructure (category-level)

These requirements apply to **every** solution in the **Infrastructure** category — Microsoft 365 /
Entra ID / Intune / Configuration Manager infrastructure work. They are published once at the category
level so individual listings stay small. Confirm these before deploying *any* Infrastructure solution.
Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every Microsoft 365, Intune, and Configuration Manager
cloud-attached resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers the management and reporting data this category builds on.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator (least privilege for the task).
**Why:** Creating app registrations, groups, and policies — or reading reports — requires the right
roles; reporting needs only read.
**Verify:** Entra → **Roles and administrators**; confirm the role the task needs (e.g. **Intune
Administrator** for config, a read role for reporting).
**Implement:** Assign the least-privilege role required; reserve Global Administrator for tenant-wide
changes such as granting admin consent.

## G4. Devices managed and reporting in
**Description:** Targeted devices are enrolled/managed (Intune and/or Configuration Manager) and
checking in.
**Why:** Configuration and reporting only reach and count managed, checked-in devices.
**Verify:** Intune → **Devices → All devices** (and/or Configuration Manager console device
collections); the devices appear.
**Implement:** Enable **Automatic Enrollment** / join devices to Entra ID, or confirm Configuration
Manager client health.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted scope.
**Why:** Every solution in this category is piloted and validated before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G6. Supported, current baseline
**Description:** Supported, currently-updated Microsoft platforms (Windows 10 21H2+ / Windows 11;
supported Configuration Manager current branch where used).
**Why:** Modern Intune and reporting features assume a supported, patched estate.
**Verify:** `winver`, Intune device **Hardware**, or Configuration Manager site/version.
**Implement:** Update/upgrade to a supported build or Configuration Manager current branch.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, Intune, and Microsoft Graph service URLs.
**Why:** Enrollment, policy sync, authentication, and Graph reporting/exports depend on these
endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com`,
`https://graph.microsoft.com`, and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Microsoft 365 / Intune / Graph URL & IP ranges through
proxy/firewall.

---
**The repeatable deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
