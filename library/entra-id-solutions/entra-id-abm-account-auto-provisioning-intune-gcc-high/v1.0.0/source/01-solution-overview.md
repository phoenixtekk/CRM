# Solution Overview — Entra ID + Apple Business Manager Managed Apple ID Auto-Provisioning (Government / GCC High)

This is the **Government (GCC High)** edition of the solution that integrates Microsoft Entra ID with
Apple Business Manager (ABM) so that Managed Apple IDs and Apple device enrollment are driven from
your directory. It is written for an administrator working in the **US sovereign cloud**, using the
`*.us` admin portals and the US Gov Microsoft Graph endpoint. It follows the standard deployment
model — **Assess → Configure → Pilot → Validate → Expand** — with a gate at the end of each phase.

## Read this first — the most important GCC High difference

Before anything else: **the Entra ID ⇄ Apple Business Manager _federation_ and _SCIM
auto-provisioning_ link does not currently support national clouds (GCC High / DoD).** Apple's own
documentation states, verbatim, "Integration with national clouds isn't currently supported," and the
integration is built for the Commercial global sign-in service `login.microsoftonline.com`, not the
sovereign `login.microsoftonline.us`. On the Microsoft side, the gallery provisioning app for ABM is
not offered for provisioning in the US Government cloud.

What that means in plain terms:

- A **pure GCC High tenant cannot complete the "sign in to Apple with your Entra work account,
  auto-created and kept in sync by SCIM" flow** the way a Commercial tenant can. This is a **feature
  parity gap**, not a portal-URL change.
- What **is** fully supported in GCC High is **Apple device management through Intune Government** —
  linking ABM to Intune for **Automated Device Enrollment (ADE)** and **User Enrollment**, with
  Managed Apple IDs created by ABM's own tooling (manual, SFTP, or ABM API) rather than by the Entra
  federation/SCIM connector.

This solution therefore guides you to **implement the supported GCC High path** and **explicitly
call out the federation/SCIM step as a Commercial-only capability** to evaluate separately with your
security and compliance team. Full citations are in `gcc-high-parity-notes.md`; do not skip it.

## What this solution delivers

- A clear **decision gate** up front: confirm whether your requirement can be met in GCC High today,
  or whether it depends on the unsupported federation/SCIM link.
- The **supported GCC High deployment**: ABM linked to **Intune Government** (`endpoint.microsoft.us`)
  for Apple ADE/User Enrollment, with Managed Apple ID lifecycle handled through ABM.
- **Five PowerShell scripts** that connect to the **US Gov** Graph endpoint
  (`Connect-MgGraph -Environment USGov`) to discover readiness, validate configuration, report state,
  safely remediate, and build the pilot scope group.
- A **parity reference**, **testing gates**, and **troubleshooting** tuned to GCC-High-specific
  behaviour.

## Commercial vs GCC High — what's different

This section is the orientation every government administrator needs. The differences are not
cosmetic — one of them changes what is achievable at all.

### 1. Feature parity — the federation/SCIM link (the big one)

| | Commercial | GCC High |
| --- | --- | --- |
| Sign in to Apple devices with Entra **work credentials** (federation) | Supported via `login.microsoftonline.com` | **Not supported** — Apple excludes national clouds |
| **SCIM auto-provisioning** of Managed Apple IDs from Entra | Supported (gallery provisioning app) | **Not supported / verify** — gallery app not offered for US Gov provisioning |
| ABM ⇄ **Intune** device enrollment (ADE, User Enrollment) | Supported | **Supported** via Intune Government |
| Managed Apple ID creation via **ABM** (manual / SFTP / ABM API) | Supported | Supported (ABM is a single global service, not cloud-bound) |

Because the top two rows are the literal title of this solution ("Entra ID integration with ABM for
account auto-provisioning"), a government reader must understand up front that the **Entra-driven**
auto-provisioning is the gated capability, while the **device-management outcome** is achievable
through the supported Intune path.

### 2. Admin portals — every URL changes to `*.us`

You do all supported configuration in the sovereign portals, never the Commercial ones:

- Entra admin center → **entra.microsoft.us**
- Intune / Endpoint admin → **endpoint.microsoft.us**
- Microsoft 365 admin → **portal.office365.us**
- Azure portal → **portal.azure.us**
- Sign-in authority → **login.microsoftonline.us**
- Microsoft Graph → **graph.microsoft.us**

Using a Commercial URL either fails to authenticate your GCC High credentials or silently targets the
wrong tenant.

### 3. Tooling — Graph must be told it is US Gov

Every script and any manual Graph call must specify the sovereign environment. In the Microsoft Graph
PowerShell SDK that is `Connect-MgGraph -Environment USGov` (which targets `graph.microsoft.us`).
Omitting it authenticates against the Commercial endpoint and fails.

### 4. Licensing — Government SKUs

Licensing uses **Government** SKUs (for example Microsoft 365 **G3/G5 Gov** and **Intune for
Government**) rather than the Commercial E3/E5 line. Confirm your tenant carries the Government
licensing that includes Entra ID P1/P2 and Intune Government.

### 5. ABM itself is unchanged

Apple Business Manager has **no sovereign variant** — there is one global `business.apple.com`. The
sovereign constraint lives entirely on the **Entra-side federation/SCIM link into ABM**. So Managed
Apple IDs, MDM server tokens, and device sync tokens are configured in the same ABM you would use for
Commercial; only the **identity link into it** is subject to the national-cloud limitation.

## The deployment model (Assess → Configure → Pilot → Validate → Expand)

- **Assess** — inventory the tenant, licensing, roles, ABM account, and — critically — decide whether
  your requirement can be met on the supported GCC High path or depends on the unsupported
  federation/SCIM link. Gate: no configuration until the decision is recorded.
- **Configure** — link ABM to **Intune Government**, establish the MDM push certificate and ADE/User
  Enrollment tokens, and define the Managed Apple ID approach ABM will use. Gate: tokens valid, no
  errors in `endpoint.microsoft.us`.
- **Pilot** — enrol a small, named group of Apple devices/users (built by
  `ABMPROVG-Set-ScopeTargeting.ps1`). Gate: pilot devices enrol and receive policy.
- **Validate** — run the validation and report scripts; confirm enrollment, Managed Apple ID sign-in
  behaviour, and policy delivery against pass/fail criteria. Gate: all checks pass.
- **Expand** — widen the scope group in controlled waves. Gate: each wave green before the next.

## Named objects you will create and reuse

To keep the deployment repeatable, create these once and reuse them by name throughout:

- **`ABM-Apple-Pilot-Devices`** — the pilot scope group (built by the scope-targeting script).
- **`ABM-Apple-Enroll-Users`** — the user group scoped for Apple enrollment.
- **`ABM-ADE-Profile-Gov`** — the Automated Device Enrollment profile in Intune Government.
- **`ABM-Managed-AppleID-Standard`** — your documented standard for how Managed Apple IDs are named
  and created in ABM.

## Who this is for and what "done" looks like

For a novice-friendly government administrator with the required roles. You are done when: the
GCC-High-vs-Commercial decision is recorded; ABM is linked to Intune Government with valid tokens;
a named pilot group of Apple devices enrols and receives policy; the validation script reports all
checks green; and the federation/SCIM parity gap is documented for stakeholders so no one expects a
capability the sovereign cloud does not offer today.

_Sovereign-cloud capabilities change. Re-verify the cited Apple and Microsoft pages (see
`gcc-high-parity-notes.md`) before implementation._
