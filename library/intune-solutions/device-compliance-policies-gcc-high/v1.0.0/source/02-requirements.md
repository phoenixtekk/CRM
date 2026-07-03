# Requirements — Device Compliance Policies (Government / GCC High edition)

Confirm every prerequisite below **before** you configure anything. The category-level
prerequisites common to all Intune solutions are in
`global-requirements-intune-solutions.md` (G1–G7) — this document adds the **GCC-High-specific**
requirements and re-states the shared ones in their sovereign-cloud form.

Each entry follows the same shape: **Description · Why · Verify · Implement-if-missing.**

---

## R1. GCC High (not Commercial, not GCC) Intune tenant

**Description:** An Intune tenant provisioned in the **US Government cloud** (GCC High / DoD,
Impact Level 4/5), not Commercial and not GCC.
**Why:** GCC High is a physically separate datacenter with different portals, endpoints, and
feature availability. Commercial steps do not apply and can silently fail here.
**Verify:** The Intune admin center loads at **`https://intune.microsoft.us/`** and you sign
in at **`login.microsoftonline.us`**. In the Microsoft 365 admin center
(`portal.office365.us`), your tenant's domain shows a `.gov`/government context.
**Implement:** GCC High tenancy is a **purchase-and-onboarding** decision (eligibility is
validated by Microsoft/an authorized partner). If your admin center is `intune.microsoft.com`,
you are on Commercial — use the Commercial edition of this solution instead. There is **no
in-place migration** between Commercial and the government cloud; devices must unenroll and
re-enroll. [[MS-GOV-SVC]](gcc-high-parity-notes.md)

## R2. US Government Intune licensing

**Description:** An Intune-bearing **US Government** license (for example Microsoft 365 **G3
or G5 Government**, or a standalone Intune Plan 1 for Government).
**Why:** Compliance, configuration, and Conditional Access all require an Intune license, and
the government SKUs are what entitle service in the sovereign cloud.
**Verify:** `portal.office365.us` → **Billing → Licenses**; confirm a Government SKU with
Intune. In `intune.microsoft.us` → **Tenant administration → Tenant status**, service is
active.
**Implement:** Assign a G3/G5 Government (or Intune for Government) license to each targeted
user. Conditional Access additionally requires **Microsoft Entra ID P1** (included in G3/G5).

## R3. Administrative roles (sovereign portal)

**Description:** **Intune Administrator** (and, for the Conditional Access gate, **Conditional
Access Administrator** or **Security Administrator**) held by the operator in the GCC High
tenant.
**Why:** Creating compliance policies, actions, and the Conditional Access gate requires these
elevated roles.
**Verify:** In `entra.microsoft.us` (or `portal.azure.us` → Microsoft Entra ID) →
**Roles and administrators**, confirm your account holds **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve **Global Administrator** for
tenant-wide changes only. Prefer **Privileged Identity Management** eligible assignments where
your tenant uses it.

## R4. Sovereign portal and endpoint access (through filtering)

**Description:** Outbound HTTPS to the **`.us` sovereign endpoints** — not the Commercial
`.com` hosts — allowed through your proxy/firewall for both admins and managed devices.
**Why:** In GCC High, enrollment, policy sync, authentication, and reporting use dedicated
Government endpoints. Allowing only the Commercial hosts breaks compliance evaluation.
**Verify:** From an admin workstation, reach `https://intune.microsoft.us`,
`https://login.microsoftonline.us`, and `https://portal.azure.us`. From a managed device,
reach `https://portal.manage.microsoft.us`.
**Implement:** Allow at minimum the following Government endpoints (see
`gcc-high-parity-notes.md` for the cited full list): [[MS-GOV-EP]](gcc-high-parity-notes.md)

| Purpose | Endpoint |
| --- | --- |
| Intune admin center | `https://intune.microsoft.us/` |
| Company Portal service | `https://portal.manage.microsoft.us/` |
| Azure portal | `https://portal.azure.us/` |
| Microsoft 365 admin | `https://portal.office365.us/` |
| Client ↔ service (enrollment, check-in, reporting) | `*.manage.microsoft.us` |
| Identity / sign-in (Evo STS) | `https://login.microsoftonline.us` |
| Microsoft Graph (GCC High) | `https://graph.microsoft.us` |
| Device registration (ADRS) | `https://enterpriseregistration.microsoftonline.us` |
| Client health telemetry | `*.events.data.microsoft.com` |

> **Do not SSL-inspect `*.manage.microsoft.us`.** Microsoft states SSL/TLS inspection is
> **not supported** on `*.manage.microsoft.us` (or on the Defender/EPM `*.dm.microsoft.us`
> endpoints). Inspecting them breaks enrollment and compliance check-in.
> [[MS-GOV-EP]](gcc-high-parity-notes.md)

## R5. Microsoft Graph PowerShell configured for US Gov

**Description:** The **Microsoft.Graph** PowerShell SDK installed and able to connect with
**`-Environment USGov`** (GCC High) or **`-Environment USGovDoD`** (DoD).
**Why:** The five scripts in this solution talk to **US Gov Graph** (`graph.microsoft.us`),
not Commercial Graph. Omitting `-Environment USGov` silently connects to the wrong cloud and
returns no data (or errors).
**Verify:** In PowerShell, `Connect-MgGraph -Environment USGov -Scopes
"DeviceManagementConfiguration.Read.All"` succeeds and `(Get-MgContext).Environment` returns
`USGov`.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Optionally set a default
so no call forgets the environment:
`$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'`.
[[MS-GRAPH-ENV]](gcc-high-parity-notes.md)

## R6. Pilot security group (reused everywhere)

**Description:** An Entra security group **`SG-Compliance-Pilot`** for the pilot cohort
(Global Requirement G5, sovereign form).
**Why:** Every stage pilots before it expands; the same group is reused by the policy
assignment and the Conditional Access gate so the blast radius is controlled and identical.
**Verify:** In `entra.microsoft.us` → **Groups**, `SG-Compliance-Pilot` exists with a few test
users/devices.
**Implement:** **Groups → New group → Security**, name it `SG-Compliance-Pilot`, add pilot
members. The scripts can build this for you — see `DCPG-Set-ScopeTargeting.ps1`.

## R7. Enrolled, supported target devices

**Description:** Targeted devices are **enrolled in the GCC High Intune tenant** and run a
supported OS (Windows 10 21H2+ / Windows 11 for the Windows baseline in this edition).
**Why:** Compliance policies only reach and evaluate enrolled devices; unsupported builds
report incorrectly.
**Verify:** `intune.microsoft.us` → **Devices → All devices**; a pilot device appears and
shows a management state.
**Implement:** Enable **Windows automatic enrollment** in the sovereign tenant and Entra-join
the devices. Note that **Windows Autopilot is not available in GCC High/DoD** — enroll via
automatic enrollment / Entra join rather than Autopilot.
[[MS-GOV-SVC]](gcc-high-parity-notes.md)

## R8. (If used) A GCC-High-capable Mobile Threat Defense vendor

**Description:** If you intend to use a **device-threat-level** compliance signal on mobile,
an MTD partner that **supports GCC High** and is connected to Intune.
**Why:** MTD compliance signals only appear when the vendor supports the government cloud;
Commercial-only MTD partners will not show in a GCC High tenant.
**Verify:** In `intune.microsoft.us` → **Tenant administration → Connectors and tokens →
Mobile Threat Defense**, the connectors shown are the ones available for GCC High.
**Implement:** Onboard a GCC-High-supported MTD partner and enable its connector. If none is
in place, leave the mobile threat-level setting **Not configured** and rely on the Windows
baseline. [[MS-GOV-SVC]](gcc-high-parity-notes.md)

---

## Exit gate for Assess

Do not proceed to **Configure** until **all** of the following are true:

- [ ] Admin center confirmed at `intune.microsoft.us` (R1).
- [ ] Government Intune licensing assigned to pilot users (R2).
- [ ] Operator holds **Intune Administrator** in the sovereign tenant (R3).
- [ ] `.us` endpoints reachable; `*.manage.microsoft.us` is **not** SSL-inspected (R4).
- [ ] `Connect-MgGraph -Environment USGov` succeeds (R5).
- [ ] `SG-Compliance-Pilot` exists with test members (R6).
- [ ] At least one pilot device is enrolled and visible (R7).
