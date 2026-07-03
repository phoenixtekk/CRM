# Device Compliance Policies — Government (GCC High)

> **Version 1.0.0** · Category: Intune · Solution code: DCPG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Device Compliance Policies (Government / GCC High edition)

## The problem

Device compliance policies are the control that decides whether a device is healthy enough to
reach corporate email, files, and collaboration — and, paired with Conditional Access, the gate
that blocks the ones that aren't. On a **GCC High** tenant, deploying them is **not** the
Commercial experience with a different sign-in. GCC High is a **physically separate US
sovereign cloud** (Azure Government, Impact Level 4/5) with **different admin portals**,
**different service endpoints**, and a **feature set that lags, limits, or omits** parts of
Commercial. Following Commercial instructions on a government tenant produces policies that
target the wrong hosts, depend on features that may not exist there, and silently fail an audit.

## The solution

This **Government (GCC High) edition** deploys Intune device compliance policies **correctly on
the sovereign cloud**. It uses the right portals (`intune.microsoft.us`,
`portal.azure.us`, `portal.office365.us`), the right US Gov Microsoft Graph endpoints
(`-Environment USGov`), and it **calls out every Commercial-vs-GCC-High parity gap** — with
Microsoft citations — at the exact step where it matters. A novice administrator can follow it
click-by-click.

## What's inside

- A **solution overview** with an explicit *Commercial vs GCC High — what's different* map.
- A **requirements guide** (verify/implement per prerequisite) in sovereign-cloud form.
- A **step-by-step implementation guide** in the GCC High portals, with parity caveats inline.
- **Five PowerShell scripts** — discovery, validation, reporting, safe remediation
  (default `-WhatIf`), and scope-targeting — all on **US Gov Graph**.
- **Testing** with pass/fail gates and a **troubleshooting** guide of GCC-High-specific gotchas.
- A **cited GCC High parity reference** so nothing is assumed.

## Why it matters

- **Correct on the sovereign cloud.** Right portals, right endpoints — no Commercial steps that
  quietly fail on a government tenant.
- **Parity gaps handled, not discovered in production.** The single most dangerous item —
  **Device Health Attestation**, which Microsoft's own docs disagree about for GCC High — is
  flagged with a concrete verification step and a documented fallback, so BitLocker/Secure
  Boot/code-integrity compliance never silently breaks.
- **Audit-ready.** Settings map to NIST SP 800-171 / CMMC control families, and the read-only
  scripts produce point-in-time evidence on demand.
- **Safe to scale.** The **Assess → Configure → Pilot → Validate → Expand** model with gates,
  a reused pilot group, and a break-glass-excluded Conditional Access policy means a single
  mistake can't take the tenant offline.

## The bottom line

**Device Compliance Policies deployed correctly on GCC High** — right portals, right endpoints,
parity gaps handled — proven on a pilot before you scale. A fraction of the cost of a
consulting engagement, and repeatable every time.


---


# Solution Overview — Device Compliance Policies (Government / GCC High edition)

## What this solution does

Microsoft Intune **device compliance policies** define the health and security rules a
device must meet — encryption, minimum OS build, firewall, antivirus, a maximum risk
score, and more — and mark each device **compliant** or **noncompliant**. Paired with a
Conditional Access policy, that compliant/noncompliant signal becomes the gate that lets a
trusted device reach email, SharePoint, and Teams while a noncompliant device is blocked.

This is the **Government (GCC High) edition** of that solution. It deploys device
compliance policies on a **US sovereign-cloud** Intune tenant — Government Community Cloud
High (GCC High) — using the correct sovereign portals and endpoints, and it calls out every
place where GCC High differs from the Commercial cloud so a government tenant is configured
correctly rather than with Commercial steps that silently fail.

> **Who this is for.** Defense-industrial-base contractors, federal agencies, and any
> organization on a **GCC High** (Impact Level 4/5) tenant subject to **DFARS 7012,
> NIST SP 800-171, or CMMC**. If your Intune admin center is `intune.microsoft.us` and you
> sign in at `login.microsoftonline.us`, this is your edition. If your admin center is
> `intune.microsoft.com`, use the **Commercial** edition instead.

## Commercial vs GCC High — what's different

GCC High is **not** the Commercial portal behind a different sign-in. It is a **physically
separate datacenter** built on Microsoft Azure Government, shared by GCC High and DoD
tenants, and locked down for government customers only.
[[MS-GOV-SVC]](gcc-high-parity-notes.md) The differences that matter for device compliance:

| Area | Commercial | GCC High (this edition) |
| --- | --- | --- |
| Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Sign-in / identity (Entra) | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft 365 admin | `admin.microsoft.com` | **`portal.office365.us`** |
| Company Portal service | `portal.manage.microsoft.com` | **`portal.manage.microsoft.us`** |
| Microsoft Graph (PowerShell/API) | `graph.microsoft.com` (Global) | **`graph.microsoft.us`** via **`-Environment USGov`** |
| Service backbone | Commercial Azure | **Azure Government (IL4/IL5)** |
| Feature availability | Full, first | **Some features absent, limited, or delayed** — see parity notes |

> **Verify for GCC High — the portal URL.** Microsoft's published US Government designated
> endpoints list the Intune admin center as **`https://intune.microsoft.us/`**. Some older
> material (and the Commercial `endpoint.microsoft.com` redirect) references an
> `endpoint.microsoft.us` host; treat **`intune.microsoft.us`** as the authoritative admin
> URL and confirm it loads for your tenant before relying on any other host.
> [[MS-GOV-EP]](gcc-high-parity-notes.md)

The **compliance-relevant parity gaps** — features that change how you author or validate
compliance on GCC High — are collected, with sources, in
**`gcc-high-parity-notes.md`**. The headline ones:

- **Windows Device Health Attestation (DHA)** — the attestation service behind
  *Require BitLocker*, *Require Secure Boot*, and *Require code integrity* — is listed by
  Microsoft's Government Service overview among features **planned but not yet available** in
  GCC High and DoD, while the Windows compliance-settings reference states DHA runs across
  Commercial, GCC High, and DoD. **This is a contradiction in Microsoft's own docs — verify
  for your GCC High tenant before you depend on these three settings.**
  [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
- **Mobile Threat Defense (MTD)** compliance signals work **only if your MTD vendor also
  supports GCC High** — fewer partners are available than on Commercial.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md)
- **Chrome Enterprise Connector** (ChromeOS compliance) is **not available** in GCC High/DoD.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md)

## The deployment model

This solution follows the standard, repeatable model used across every solution in this
library:

**Assess → Configure → Pilot → Validate → Expand**, with a **gate** between each stage — you
do not advance until the current stage's exit criteria are met.

1. **Assess** — confirm you are on a GCC High tenant, licensing, roles, sovereign portal
   access, and network endpoints (see `02-requirements.md`).
2. **Configure** — author the baseline compliance policies in `intune.microsoft.us`
   (see `03-implementation.md`), naming objects to a convention and reusing the pilot group.
3. **Pilot** — assign to a small pilot group and observe, changing nothing else.
4. **Validate** — confirm devices evaluate correctly and Conditional Access behaves as
   intended (see `05-testing.md`).
5. **Expand** — widen assignment in waves to the full fleet.

## Object naming and reuse

Author objects once and reuse them everywhere so the deployment stays legible and auditable:

- **Pilot group:** `SG-Compliance-Pilot` (Entra security group — from Global Requirement G5).
- **Windows baseline policy:** `CP-Win-Baseline-GovHigh`.
- **Windows Firewall/AV policy (optional split):** `CP-Win-Defender-GovHigh`.
- **Noncompliance notification:** `MT-Compliance-Noncompliant-GovHigh`.
- **Conditional Access gate:** `CA-Require-Compliant-GovHigh`.

Every script and later document refers back to these exact names. Adjust the suffix if your
tenant uses a different naming standard — but pick one convention and hold to it.

## What you get

- This overview and the **Commercial vs GCC High** map above.
- A **requirements guide** with verify/implement steps per prerequisite (`02-requirements.md`).
- A **step-by-step implementation guide** using the GCC High portals, with parity caveats
  inline (`03-implementation.md`).
- **Five PowerShell scripts** that connect to **US Gov Graph** (`-Environment USGov`):
  discovery, validation, reporting, safe remediation, and scope-targeting.
- A **testing guide** with pass/fail gates (`05-testing.md`) and a **troubleshooting guide**
  with GCC-High-specific gotchas (`06-troubleshooting.md`).
- A **GCC High parity reference** with citations (`gcc-high-parity-notes.md`).

> **The repeatable way.** Nothing here is one-off. Name objects to the convention, pilot
> before you expand, gate each stage, and re-run the discovery and validation scripts any
> time you need proof the tenant still matches the design.


---


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


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation — Device Compliance Policies (Government / GCC High edition)

This guide is written for a **novice administrator** to follow click-by-click in the **GCC
High** portals. Every path uses the sovereign admin center **`intune.microsoft.us`** — if you
find yourself on `intune.microsoft.com`, stop: you are in the wrong cloud.

Follow the stages in order and honor the **gates**. Objects are named to the convention from
`01-solution-overview.md` and reused; do not rename them between stages.

> **Before you start**, complete the Assess exit gate in `02-requirements.md`. Run
> `DCPG-Discovery.ps1` first (read-only) to capture a baseline of what already exists — you
> will compare against it later.

---

## Stage 1 — Configure the Windows baseline compliance policy

### 1.1 Open Device compliance in the sovereign portal

1. Sign in to **`https://intune.microsoft.us/`** with your Intune Administrator account
   (you will be redirected to `login.microsoftonline.us` to authenticate).
2. In the left menu select **Devices**.
3. Select **Compliance** (Devices → **Compliance**), then the **Policies** tab.
4. Select **+ Create policy**.

### 1.2 Create the policy shell

1. **Platform:** select **Windows 10 and later**.
2. Select **Create**.
3. **Name:** `CP-Win-Baseline-GovHigh`
4. **Description:** `Windows baseline device compliance — GCC High. Owned by IT Security.`
5. Select **Next**.

### 1.3 Configure compliance settings

On the **Compliance settings** page, expand each category and set the following baseline.
These settings are the sovereign-cloud equivalents of the Commercial baseline; the
**parity caveats** are called out inline where GCC High behaves differently.

**Device Health**

| Setting | Value | GCC High caveat |
| --- | --- | --- |
| Require BitLocker | **Require** | ⚠️ **Verify for GCC High.** This depends on **Device Health Attestation (DHA)**, which Microsoft's Government Service overview lists as *planned / not yet available* in GCC High/DoD, while the Windows compliance-settings reference says DHA runs in GCC High. **Confirm on a pilot device before you rely on it** (see below). [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md) |
| Require Secure Boot to be enabled on the device | **Require** | Same DHA dependency and caveat as BitLocker. |
| Require code integrity | **Require** | Same DHA dependency and caveat as BitLocker. |

> **DHA verification step (do this in Pilot).** Because the two Microsoft docs disagree on
> DHA availability in GCC High, treat the three Device Health settings as **unverified until
> proven on your tenant.** Assign the policy to one pilot device, wait for a sync, and check
> whether these settings report a real **Compliant/Not compliant** result rather than
> **Not applicable / Error**. If they never resolve, fall back to the **encryption** and
> **TPM** settings below (which do not require DHA) and leave the three Device Health
> settings **Not configured**. Record the outcome in your validation notes.

**Device Properties**

| Setting | Value |
| --- | --- |
| Minimum OS version | `10.0.19044.0` (Windows 10 21H2) or your organization's floor |

**System Security → Encryption**

| Setting | Value | Note |
| --- | --- | --- |
| Encryption of data storage on a device | **Require** | Checks OS-drive encryption (BitLocker) **without** the DHA attestation dependency — a safe baseline if DHA is unavailable. [[MS-WIN-COMPL]](gcc-high-parity-notes.md) |

**System Security → Device Security**

| Setting | Value |
| --- | --- |
| Firewall | **Require** |
| Trusted Platform Module (TPM) | **Require** |
| Antivirus | **Require** |
| Antispyware | **Require** |

**System Security → Defender**

| Setting | Value |
| --- | --- |
| Microsoft Defender Antimalware | **Require** |
| Real-time protection | **Require** |

**Microsoft Defender for Endpoint** *(only if MDE is onboarded in your GCC High tenant)*

| Setting | Value | GCC High note |
| --- | --- | --- |
| Require the device to be at or under the machine risk score | **Medium** | MDE **security settings management is supported in GCC High/DoD.** If MDE is not onboarded, leave this **Not configured**. [[MS-GOV-SVC]](gcc-high-parity-notes.md) |

Select **Next**.

### 1.4 Actions for noncompliance

1. The default action **Mark device noncompliant** is present with a schedule of
   **0 days** (immediate). Keep it, or set a short grace period (for example **1 day**) so
   users have time to remediate before they lose access.
2. Select **+ Add** → **Send email to end user**.
3. Select **Create a notification** (this becomes `MT-Compliance-Noncompliant-GovHigh`):
   - **Name:** `MT-Compliance-Noncompliant-GovHigh`
   - **Subject:** `Action required: your device is not compliant`
   - **Message:** a short note telling the user to open **Company Portal** and follow the
     remediation steps. Avoid any Commercial `*.com` links — Company Portal on GCC High is
     `portal.manage.microsoft.us`.
   - Save the notification, then select it as the action's template.
4. Schedule the email (for example, send **1 day** after noncompliance).
5. Select **Next**.

### 1.5 Assignments — pilot only

1. Under **Included groups**, select **Add groups** and choose **`SG-Compliance-Pilot`**
   (from R6). **Do not** assign to All devices/All users yet.
2. Leave **Excluded groups** empty for now.
3. Select **Next**.

### 1.6 Review and create

1. Review every setting on the **Review + create** page.
2. Select **Create**. The policy `CP-Win-Baseline-GovHigh` now appears in the list.

> **Gate — Configure complete when:** `CP-Win-Baseline-GovHigh` exists, targets only
> `SG-Compliance-Pilot`, and `MT-Compliance-Noncompliant-GovHigh` is attached as a
> noncompliance action. Run `DCPG-Validation.ps1` to confirm the policy exists and is
> pilot-scoped before moving on.

---

## Stage 2 — Pilot

1. Ensure at least one enrolled Windows device belongs to a user in `SG-Compliance-Pilot`.
2. On that device, force a sync: **Settings → Accounts → Access work or school →** your
   account **→ Info → Sync**; or run the Intune device action **Sync** from
   `intune.microsoft.us` → **Devices → All devices →** the device → **Sync**.
3. Wait for evaluation (allow up to a few hours for first evaluation; DHA-based settings only
   settle **after a reboot** because they are measured at boot time).
   [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
4. **Perform the DHA verification step from 1.3** and record whether the three Device Health
   settings resolve to a real result on your GCC High tenant.

> **Gate — Pilot complete when:** the pilot device shows an explicit **Compliant** or
> **Not compliant** result for the policy (not perpetually *In progress*), and you have a
> recorded answer on DHA behavior. Change nothing else during pilot.

---

## Stage 3 — Add the Conditional Access gate

A compliance policy only labels devices; **Conditional Access** enforces the label. Create
the gate scoped to the **same pilot group** first.

1. Go to **`entra.microsoft.us`** (or `portal.azure.us` → Microsoft Entra ID) →
   **Protection → Conditional Access → Policies → + New policy**.
2. **Name:** `CA-Require-Compliant-GovHigh`
3. **Users:** include **`SG-Compliance-Pilot`** only. **Exclude** at least one
   break-glass/emergency-access admin account.
4. **Target resources:** start with a single test app (for example **Office 365 SharePoint
   Online**), not "All cloud apps", during pilot.
5. **Grant:** **Grant access → Require device to be marked as compliant.**
6. **Enable policy:** set to **Report-only** first, review sign-in logs, then switch to
   **On** once the pilot behaves as expected.
7. Select **Create**.

> **Gate — CA validated when:** a compliant pilot device reaches the test app and a
> deliberately noncompliant pilot device is blocked, verified in **Entra → Sign-in logs**.
> See `05-testing.md`. Keep a break-glass account excluded at all times.

---

## Stage 4 — Expand in waves

1. Build or grow target groups with `DCPG-Set-ScopeTargeting.ps1` (defaults to **-WhatIf** —
   review the plan, then re-run with `-Commit` to apply).
2. Widen the **assignment** of `CP-Win-Baseline-GovHigh` from `SG-Compliance-Pilot` to the
   next wave group, then the next, watching the compliance report between waves.
3. Widen `CA-Require-Compliant-GovHigh` in step with the compliance policy — never enforce
   Conditional Access on a population the compliance policy has not yet reached.
4. Only after the fleet is stable, broaden the CA target resources toward **All cloud apps**
   (still excluding break-glass accounts).

> **Gate — Expand safely when:** each wave's compliance rate is acceptable before the next
> wave begins, and CA enforcement never leads the compliance rollout.

---

## Re-runnable proof

At any point, run the read-only scripts to prove the tenant matches this design:

- `DCPG-Discovery.ps1` — inventory of compliance policies, assignments, and actions.
- `DCPG-Validation.ps1` — pass/fail check that the named objects exist and are scoped right.
- `DCPG-Report.ps1` — per-device compliance rollup for a status report.

All three connect with **`-Environment USGov`** and make **no changes**.


---


# Testing & Validation — Device Compliance Policies (Government / GCC High edition)

Validation proves the compliance policy **evaluates correctly** and the Conditional Access
gate **enforces** it — on the sovereign cloud, using the sovereign portals. Work through each
test, record **PASS/FAIL**, and only advance a stage when its gate passes.

Run the read-only scripts (`-Environment USGov`) alongside the manual checks so you have
machine-verifiable evidence, not just screenshots.

---

## Test 1 — You are on the GCC High tenant (not Commercial)

**Goal:** Confirm the whole exercise is happening in the government cloud.

| Step | Expected (PASS) |
| --- | --- |
| Admin center URL in the browser | `intune.microsoft.us` (not `.com`) |
| Sign-in redirects to | `login.microsoftonline.us` |
| `DCPG-Validation.ps1` output | Reports `Environment: USGov` and a Government Graph host |

**FAIL if** any URL is a `.com` Commercial host — stop and switch to the sovereign portals.

---

## Test 2 — The named objects exist and are pilot-scoped

**Goal:** Confirm Configure produced exactly the intended objects.

Run `DCPG-Validation.ps1`. It should report:

- `CP-Win-Baseline-GovHigh` **exists**.
- It is assigned to **`SG-Compliance-Pilot`** and **not** to All devices/All users.
- `MT-Compliance-Noncompliant-GovHigh` is attached as a noncompliance action.

**PASS:** all three true. **FAIL:** any missing or the policy is fleet-wide before pilot.

---

## Test 3 — A healthy device evaluates as Compliant

**Goal:** A well-configured pilot device is marked compliant.

1. Pick a pilot device that has BitLocker on, Firewall on, Defender on, TPM present.
2. Sync it (`intune.microsoft.us` → Devices → the device → **Sync**), then **reboot** (needed
   for any boot-time / DHA-measured settings). [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
3. `intune.microsoft.us` → **Devices → Compliance** → the device → per-setting results.

**PASS:** device shows **Compliant** and each configured setting shows **Compliant**.
**FAIL:** device stuck **In progress** for hours, or an expected setting shows **Error**.

---

## Test 4 — DHA behavior on GCC High (the parity check)

**Goal:** Resolve, for **your** tenant, whether the DHA-dependent Device Health settings work
— because Microsoft's docs disagree. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
[[MS-WIN-COMPL]](gcc-high-parity-notes.md)

1. On the pilot device, inspect the results for **Require BitLocker**, **Require Secure
   Boot**, and **Require code integrity**.

| Result | Meaning | Action |
| --- | --- | --- |
| Real **Compliant / Not compliant** | DHA is working in your GCC High tenant | Keep the three settings |
| Perpetual **Not applicable / Error / no result** | DHA appears unavailable here | Set the three to **Not configured**; rely on **Encryption of data storage** + **TPM** instead |

**Record the outcome** in your deployment notes — it determines the supported baseline for
this tenant.

---

## Test 5 — A noncompliant device is caught

**Goal:** The policy correctly flags a device that violates a rule.

1. On a **spare** pilot device (never a production machine), disable a required control —
   e.g. turn **Windows Firewall off** (a non-destructive, easily reversible violation).
2. Sync the device.
3. Confirm `intune.microsoft.us` → **Devices → Compliance** shows the device **Not compliant**
   with the **Firewall** setting failing.
4. Re-enable the firewall, sync, and confirm it returns to **Compliant**.

**PASS:** device flips to Not compliant on violation and back to Compliant on remediation.

---

## Test 6 — The noncompliance action fires

**Goal:** The email notification reaches the user.

1. With a device noncompliant past the scheduled delay, confirm the user receives the
   `MT-Compliance-Noncompliant-GovHigh` email.
2. Confirm the email contains **no Commercial `*.com` remediation links** (Company Portal on
   GCC High is `portal.manage.microsoft.us`).

**PASS:** email received, sovereign links only.

---

## Test 7 — Conditional Access enforces the label

**Goal:** The compliant/noncompliant label actually gates access.

1. With `CA-Require-Compliant-GovHigh` set to **On** and scoped to `SG-Compliance-Pilot`:
   - From a **compliant** pilot device, open the test app (e.g. SharePoint Online) → **access
     granted**.
   - From a **noncompliant** pilot device, attempt the same → **access blocked**.
2. Verify both outcomes in **`entra.microsoft.us` → Sign-in logs** (the Conditional Access
   tab of each sign-in shows the policy result).
3. Confirm the **break-glass** account is excluded and still able to sign in.

**PASS:** compliant allowed, noncompliant blocked, break-glass unaffected.

---

## Validation summary gate

| # | Test | PASS/FAIL |
| --- | --- | --- |
| 1 | On GCC High tenant | |
| 2 | Named objects exist, pilot-scoped | |
| 3 | Healthy device = Compliant | |
| 4 | DHA behavior recorded | |
| 5 | Noncompliant device caught | |
| 6 | Noncompliance email fires | |
| 7 | Conditional Access enforces | |

Do not begin **Expand** until Tests 1–7 pass on the pilot. Re-run `DCPG-Validation.ps1` and
`DCPG-Report.ps1` after each expansion wave to keep the evidence current.


---


# Troubleshooting — Device Compliance Policies (Government / GCC High edition)

GCC-High-specific symptoms first, then the general compliance issues that also apply here. For
each: **Symptom → Likely cause → Fix.** Cross-references point to the cited parity reference.

---

## GCC High / sovereign-cloud issues

### The admin center looks empty, or "your changes didn't save"

- **Cause:** You're signed into the **Commercial** portal (`intune.microsoft.com`), not the
  sovereign one. Your GCC High objects live in a physically separate datacenter and don't
  appear there.
- **Fix:** Open **`https://intune.microsoft.us/`** and sign in at `login.microsoftonline.us`.
  Confirm the URL bar shows `.us`. Re-do the change in the correct cloud.
  [[MS-GOV-EP]](gcc-high-parity-notes.md)

### PowerShell returns no policies / "Insufficient privileges" / connects to the wrong tenant

- **Cause:** `Connect-MgGraph` defaulted to **Global** (Commercial `graph.microsoft.com`)
  instead of US Gov, so it's querying the wrong cloud.
- **Fix:** Reconnect with **`Connect-MgGraph -Environment USGov`** (DoD: `USGovDoD`). Verify
  with `(Get-MgContext).Environment` → should read `USGov`. Set
  `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` so it never happens
  again. All five scripts already pass `-Environment USGov`.
  [[MS-GRAPH-ENV]](gcc-high-parity-notes.md)

### Enrollment or compliance check-in fails intermittently behind the proxy

- **Cause:** SSL/TLS inspection on `*.manage.microsoft.us` (or the Defender/EPM
  `*.dm.microsoft.us` endpoints), or only the Commercial `.com` endpoints are allowed.
- **Fix:** **Exempt `*.manage.microsoft.us` from SSL inspection** — Microsoft does not support
  inspecting it — and allow the full sovereign endpoint list in `02-requirements.md` R4
  (including `login.microsoftonline.us`, `graph.microsoft.us`,
  `enterpriseregistration.microsoftonline.us`, `*.events.data.microsoft.com`).
  [[MS-GOV-EP]](gcc-high-parity-notes.md)

### Require BitLocker / Secure Boot / code integrity never resolves (stuck Not applicable / Error)

- **Cause:** These three settings depend on **Device Health Attestation (DHA)**, whose GCC High
  availability Microsoft's own docs **contradict** — one lists it as *planned/not yet
  available*, the other says it runs in GCC High. On some GCC High tenants they may not
  evaluate. [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
- **Fix:**
  1. First rule out the boot-time delay: DHA settings only settle **after a reboot**, even when
     BitLocker is already fully encrypted. Reboot the device and re-sync.
  2. If they still never resolve, DHA appears unavailable on your tenant — set the three to
     **Not configured** and use **System Security → Encryption → Encryption of data storage**
     (BitLocker check without DHA) plus **TPM** instead. Record the decision.

### A Mobile Threat Defense connector I use on Commercial isn't listed

- **Cause:** MTD connectors appear in GCC High **only if the vendor supports GCC High**; fewer
  partners do than on Commercial. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
  [[MS-MTD-COMPL]](gcc-high-parity-notes.md)
- **Fix:** Confirm your MTD vendor's GCC High support and onboard the GCC-High-capable connector,
  or leave the mobile **Device Threat Level** setting **Not configured** and rely on the Windows
  baseline.

### The Device Threat Level rule won't apply to a device group

- **Cause:** The MTD *Require the device to be at or under the Device Threat Level* setting
  supports **user groups only** — targeting device groups is unsupported.
  [[MS-MTD-COMPL]](gcc-high-parity-notes.md)
- **Fix:** Assign that policy to **user** groups.

### I can't find Autopilot / Chrome Enterprise / Store for Business to complete a step

- **Cause:** These are **not available** in GCC High/DoD. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
- **Fix:** Enroll Windows via **automatic enrollment / Entra join** (not Autopilot). Don't
  design ChromeOS compliance (no Chrome Enterprise Connector). See the not-available list in
  `gcc-high-parity-notes.md` §6 before treating any Commercial feature as available.

---

## General compliance issues (also apply in GCC High)

### A device is stuck "In progress" and never returns a compliance result

- **Cause:** The device hasn't synced or checked in since the policy was assigned; first
  evaluation can take hours.
- **Fix:** Force a **Sync** from `intune.microsoft.us` → the device → **Sync**, or from the
  device's work-account settings. Confirm the device is enrolled and online. Reboot if
  DHA-measured settings are involved. [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### Firewall shows "Error" or unexpectedly "Not compliant"

- **Cause:** A sync right after reboot/wake can transiently error; or a **Group Policy Object**
  configured the firewall to allow all inbound / turn it off, which **overrides** the Intune
  setting.
- **Fix:** Manually sync and re-evaluate. Remove conflicting GPO firewall settings, or migrate
  firewall configuration into Intune device-configuration policy so the two don't fight.
  [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### BitLocker is on, but the device still reports non-compliant for Require BitLocker

- **Cause:** DHA measures this at **boot time**; the device hasn't rebooted since encryption
  completed.
- **Fix:** **Reboot** the device, then sync. (If it still never resolves, see the DHA section
  above.) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### The machine risk score setting won't populate

- **Cause:** **Microsoft Defender for Endpoint** isn't onboarded/connected in the tenant.
- **Fix:** Onboard MDE (its security settings management **is** supported in GCC High/DoD), then
  the *Require the device to be at or under the machine risk score* setting will evaluate. If
  MDE isn't in use, leave it **Not configured**.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)

### Users are unexpectedly blocked from resources

- **Cause:** Conditional Access (`CA-Require-Compliant-GovHigh`) is enforcing "require
  compliant" on a population the compliance policy hasn't finished evaluating, or a user's
  device is genuinely noncompliant.
- **Fix:** Check **`entra.microsoft.us` → Sign-in logs** → the Conditional Access result for the
  user. Keep CA in **Report-only** until the compliance rollout has reached that population;
  ensure the compliance policy leads and CA follows. Confirm a **break-glass** account is
  excluded from CA.

### The noncompliance email never arrives

- **Cause:** No notification template attached, the schedule delay hasn't elapsed, or the
  device isn't actually noncompliant yet.
- **Fix:** Confirm `MT-Compliance-Noncompliant-GovHigh` is attached as a **Send email to end
  user** action with a reached schedule, and that the device shows **Not compliant**. Verify the
  email body uses `portal.manage.microsoft.us` links, not Commercial `.com` links.

---

## When to re-run the scripts

- After **any** portal change → `DCPG-Validation.ps1` to confirm named objects and pilot
  scoping.
- Investigating fleet status → `DCPG-Report.ps1` for the per-device rollup.
- Suspected drift (e.g. a policy widened to All devices) → `DCPG-Discovery.ps1`, then
  `DCPG-Remediation.ps1 -WhatIf` to preview a fix before applying with `-Commit`.

All read-only scripts are safe to run any time and connect with `-Environment USGov`.


---


# Best Practices — Device Compliance Policies (Government / GCC High edition)

These practices keep a GCC High compliance deployment correct, auditable, and safe to expand.
They assume the objects and stages defined in `01-solution-overview.md` and
`03-implementation.md`.

## Sovereign-cloud hygiene

- **Bookmark the `.us` portals and use only those.** `intune.microsoft.us`,
  `entra.microsoft.us` / `portal.azure.us`, `portal.office365.us`. A Commercial `.com`
  bookmark opened by habit is the most common way a change lands in the wrong place — or
  appears to "not save" because you were never in your tenant.
- **Never SSL-inspect `*.manage.microsoft.us` or `*.dm.microsoft.us`.** Microsoft does not
  support TLS inspection on these; inspecting them breaks enrollment and compliance check-in.
  [[MS-GOV-EP]](gcc-high-parity-notes.md)
- **Always pass `-Environment USGov`** (or `USGovDoD`) on every `Connect-MgGraph`. Set it as a
  PowerShell default so no script can silently hit Commercial Graph. [[MS-GRAPH-ENV]](gcc-high-parity-notes.md)

## Design and naming

- **One naming convention, reused everywhere.** `CP-…-GovHigh`, `SG-…`, `MT-…-GovHigh`,
  `CA-…-GovHigh`. Consistent names make the discovery/validation scripts, audits, and
  handovers trivial.
- **Keep compliance policy and Conditional Access in lockstep.** The compliance policy is the
  *label*; Conditional Access is the *enforcement*. Never enforce CA on a population the
  compliance policy has not yet reached, or you will lock users out of resources they can't
  remediate.
- **Prefer platform-specific policies over one giant policy.** A Windows baseline
  (`CP-Win-Baseline-GovHigh`) plus separate mobile policies is easier to reason about and to
  target than a single sprawling policy.

## Handling the parity gaps

- **Treat DHA-dependent settings as unverified until proven** on your tenant (Require
  BitLocker / Secure Boot / code integrity). Microsoft's own docs disagree on GCC High
  availability — validate on a pilot device and, if they don't resolve, fall back to
  **Encryption of data storage** + **TPM**, which don't need attestation.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
- **Confirm MTD vendor GCC High support before designing a mobile threat-level rule.** If no
  GCC-High-capable MTD partner is connected, leave the device-threat-level setting **Not
  configured** rather than assuming it will populate. [[MS-GOV-SVC]](gcc-high-parity-notes.md)
- **Don't design around Commercial-only features.** Chrome Enterprise Connector, Windows
  Autopilot, Microsoft Store for Business, TeamViewer/ServiceNow connectors, and several
  Windows update-reporting features are **not available** in GCC High/DoD. Verify a feature's
  GCC High status before it becomes a dependency. [[MS-GOV-SVC]](gcc-high-parity-notes.md)

## Safe rollout

- **Pilot first, always.** `SG-Compliance-Pilot` → wave groups → fleet. Gate each stage.
- **Start Conditional Access in Report-only.** Review Entra sign-in logs before switching to
  **On**. Broaden target resources toward "All cloud apps" only after the pilot is clean.
- **Keep a break-glass account excluded** from every Conditional Access policy, and test that
  it still works. A locked-out tenant with no exclusion is a self-inflicted outage.
- **Give users a grace period.** A short "mark noncompliant after 1 day" schedule plus the
  notification email lets users self-remediate before losing access, cutting help-desk load.

## Change control and evidence

- **Remediate with intent, not by hand.** Use `DCPG-Remediation.ps1` (defaults to **-WhatIf**)
  so every change is previewed and logged before it applies.
- **Re-run discovery/validation/report on a schedule.** These read-only scripts give you
  point-in-time proof the tenant still matches this design — useful for CMMC/NIST evidence and
  for catching drift.
- **Document the DHA decision.** Record whether the three Device Health settings work on your
  tenant; it is the single most tenant-specific choice in this deployment.

## Compliance-program alignment

- **Map settings to your controls.** BitLocker/encryption → media protection; firewall,
  antivirus, real-time protection → system/communications protection; minimum OS → flaw
  remediation. Keeping the mapping written down turns your compliance report into audit
  evidence for NIST SP 800-171 / CMMC. [[MS-GOV-SVC]](gcc-high-parity-notes.md)


---


# Deliverables Summary — Device Compliance Policies (Government / GCC High edition)

Everything included in this solution and how the pieces fit together. All scripts connect to
**US Gov Microsoft Graph** with **`-Environment USGov`** (use `USGovDoD` for DoD).

## Documents

| File | Purpose |
| --- | --- |
| `executive-summary.md` | One-page business case for the GCC High edition. |
| `01-solution-overview.md` | What the solution does, the **Commercial vs GCC High** map, deployment model, object naming. |
| `02-requirements.md` | Prerequisites in sovereign-cloud form (verify/implement) + Assess exit gate. |
| `03-implementation.md` | Click-by-click build in `intune.microsoft.us`, with parity caveats inline and stage gates. |
| `05-testing.md` | Seven pass/fail validation tests, including the DHA parity check. |
| `06-troubleshooting.md` | GCC-High-specific symptoms, causes, and fixes. |
| `07-best-practices.md` | Hygiene, design, parity handling, safe rollout, evidence. |
| `gcc-high-parity-notes.md` | **Cited** Commercial-vs-GCC-High reference (the source of truth for parity claims). |
| `08-deliverables-summary.md` | This file. |
| `global-requirements-intune-solutions.md` | Category-level prerequisites (G1–G7) shared by all Intune solutions. |

## Scripts (`scripts/`)

| Script | Type | What it does |
| --- | --- | --- |
| `DCPG-Discovery.ps1` | Read-only | Inventories device compliance policies, their assignments, and noncompliance actions in the GCC High tenant. Baseline before you build. |
| `DCPG-Validation.ps1` | Read-only | Pass/fail checks that the named objects (`CP-Win-Baseline-GovHigh`, `SG-Compliance-Pilot`, `MT-Compliance-Noncompliant-GovHigh`) exist and are pilot-scoped, and that you're on `USGov`. |
| `DCPG-Report.ps1` | Read-only | Per-device compliance rollup (compliant / noncompliant / counts) for status reporting and audit evidence. |
| `DCPG-Remediation.ps1` | **Default `-WhatIf`** | Previews and (with `-Commit`) applies safe corrective actions — e.g. re-scoping a policy off All-devices back to the pilot group, or attaching the noncompliance notification. |
| `DCPG-Set-ScopeTargeting.ps1` | **Default `-WhatIf`** | Builds/grows the pilot and wave security groups and previews assignment changes; applies only with `-Commit`. |

## How the deliverables map to the deployment stages

| Stage | Documents | Scripts |
| --- | --- | --- |
| **Assess** | `02-requirements.md`, `gcc-high-parity-notes.md` | `DCPG-Discovery.ps1` |
| **Configure** | `03-implementation.md` §1 | `DCPG-Validation.ps1` |
| **Pilot** | `03-implementation.md` §2, `05-testing.md` | `DCPG-Set-ScopeTargeting.ps1` |
| **Validate** | `05-testing.md`, `06-troubleshooting.md` | `DCPG-Validation.ps1`, `DCPG-Report.ps1` |
| **Expand** | `03-implementation.md` §4, `07-best-practices.md` | `DCPG-Set-ScopeTargeting.ps1`, `DCPG-Remediation.ps1` |

## Named objects (reused throughout)

- `SG-Compliance-Pilot` — Entra pilot security group.
- `CP-Win-Baseline-GovHigh` — Windows baseline compliance policy.
- `MT-Compliance-Noncompliant-GovHigh` — noncompliance email notification.
- `CA-Require-Compliant-GovHigh` — Conditional Access gate (require compliant device).

## Running the scripts

```
powershell -ExecutionPolicy Bypass -File .\DCPG-Discovery.ps1
```

Each script connects with `-Environment USGov`, prompts for the Graph scopes it needs, and
(for Discovery/Validation/Report) makes **no changes**. `DCPG-Remediation.ps1` and
`DCPG-Set-ScopeTargeting.ps1` default to **`-WhatIf`** — review the previewed plan, then re-run
with **`-Commit`** to apply.
