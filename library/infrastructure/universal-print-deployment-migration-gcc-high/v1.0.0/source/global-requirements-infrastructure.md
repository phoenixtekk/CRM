# Global Requirements — Infrastructure Solutions (category-level)

These requirements apply to **every** solution in the **Infrastructure** category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying *any* Infrastructure solution. Each entry: Description · Why · Verify · Implement-if-missing.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID (Azure AD) tenant.
Why: It is the identity backbone for Microsoft 365, Entra ID, and Intune-managed infrastructure — including device sign-in, group targeting, and shared cloud resources.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft 365 / Intune subscription
Description: A Microsoft 365 plan that includes Microsoft Intune and the cloud service the solution relies on.
Why: Intune delivers configuration, deployment, and policy targeting; the bundled Microsoft 365 services back the cloud capability being deployed.
Verify: `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
Description: Appropriate Entra / Intune admin roles for the operator.
Why: Creating cloud service settings, policies, and deployments requires elevated rights.
Verify: Entra → **Roles and administrators**; confirm **Intune Administrator** (plus any service-specific admin role the solution calls out).
Implement: Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
Description: Targeted Windows devices are enrolled and manageable.
Why: Deployments and policies only reach enrolled, Entra-joined devices.
Verify: Intune → **Devices → All devices**; the device appears and is **compliant**.
Implement: Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
Description: A Microsoft Entra security group for the pilot population (users or devices).
Why: Every solution is piloted before fleet rollout — the pilot is the gate.
Verify: Entra → **Groups**; the pilot group exists.
Implement: Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
Description: Windows 10 21H2+ or Windows 11 with current updates.
Why: Modern Intune and Microsoft 365 cloud features assume a patched, supported OS.
Verify: `winver`, or Intune → device → **Hardware**.
Implement: Deploy update rings or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
Why: Enrollment, policy sync, authentication, and the cloud service traffic depend on these endpoints.
Verify: From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through the proxy/firewall.

---
The repeatable deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.
