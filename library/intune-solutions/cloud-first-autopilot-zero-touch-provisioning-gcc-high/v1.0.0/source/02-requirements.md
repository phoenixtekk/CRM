# Requirements — Cloud-First Autopilot Zero-Touch Provisioning (Government / GCC High)

Confirm **every** requirement below before you configure anything (the **Assess** gate).
Category-level prerequisites common to all Intune solutions live in
`global-requirements-intune-solutions.md`; the items here are the ones **specific to this
solution and to GCC High**. Each entry follows: **Description · Why · Verify · Implement.**

> **GCC High portal reminder.** Everywhere the global requirements say
> `entra.microsoft.com` / `intune.microsoft.com`, on GCC High you use
> **`https://entra.microsoft.us`** *(verify for GCC High)* and
> **`https://intune.microsoft.us`** and sign in at **`https://login.microsoftonline.us`**.

---

## R1. A GCC High (or DoD) tenant on the US sovereign cloud
**Description:** An active Microsoft 365 / Microsoft Entra tenant provisioned in the
**Government Community Cloud High (GCC High)** or **DoD** environment (built on Azure
Government / IL4–IL5), **not** a Commercial or GCC tenant.

> **Note (doc-confirmed):** For Intune, **GCC is the *commercial* instance**; only **GCC
> High** and **DoD** are the separate government cloud. If your tenant is "GCC," you are on
> the Commercial Intune service and should use the Commercial edition of this solution.
> (Microsoft, *Intune Government Service overview*.)

**Why:** Autopilot device preparation and the `*.us` portals only exist on the government
cloud; a Commercial tenant will not expose them and cannot be migrated in place (devices
must unenroll/re-enroll to move clouds).
**Verify:** Sign in to **`https://intune.microsoft.us`**. It loads and shows your tenant.
Signing in at `intune.microsoft.com` with the same account should **not** show your
government tenant's Intune data.
**Implement:** Purchase the appropriate GCC High / DoD licensing through an authorized
government-cloud channel and complete tenant onboarding. There is no in-place move from
Commercial.

## R2. US Government licensing that carries Intune + Entra ID P1/P2
**Description:** A US Gov subscription that includes Intune and Microsoft Entra ID P1 or P2,
e.g. **Microsoft 365 G3 / G5 (Government)**, **EMS E3/E5 (Gov)**, or **Entra ID P1/P2 +
Intune Plan 1 (Gov)**.
**Why:** Autopilot device preparation needs automatic MDM enrollment and company-branding
capabilities (Entra ID) plus Intune as the MDM. (Microsoft, *Autopilot device preparation
requirements → Licensing*.)
**Verify:** `https://portal.office365.us` → **Billing → Licenses**; confirm a Gov SKU that
lists Intune and Entra ID P1/P2.
**Implement:** Assign a qualifying Gov license **to each provisioning user** (a Microsoft
365 subscription still requires per-user license assignment so the user can enroll the
device in Intune).

## R3. Administrative roles in the GCC High tenant
**Description:** The operator holds **Intune Administrator** (and, for the one-time tenant
setup steps, an account with **Global Administrator**).
**Why:** Creating the device preparation profile, enrollment settings, ESP, and the RBAC
role requires elevated Intune rights; enabling automatic enrollment and consenting the
provisioning service principal are tenant-wide.
**Verify:** `https://entra.microsoft.us` *(verify for GCC High)* → **Roles and
administrators** → confirm **Intune Administrator** on the operator account.
**Implement:** Assign **Intune Administrator**; reserve **Global Administrator** for the
tenant-wide steps only. Later, hand day-to-day work to the least-privilege custom role
`CFAPG Device Preparation Administrator` (built in `03-implementation.md`).

## R4. Supported Windows 11 build on target devices
**Description:** Target devices run **Windows 11, version 24H2 or later**, **or** Windows
11 22H2/23H2 **with KB5035942 or later** included in the OEM/installation media. Supported
editions: Pro, Pro Education, Pro for Workstations, Enterprise, Education, Enterprise LTSC.
**Why:** Autopilot device preparation depends on client features present only in these
builds. Windows 10 is **not** supported for device preparation. (Microsoft, *Autopilot
device preparation requirements → Software*.)
**Verify:** On a sample device run `winver`; confirm Windows 11 with a build that includes
KB5035942 (April 2024 media or later), or 24H2+.
**Implement:** Order OEM devices with 24H2 (or 22H2/23H2 media dated April 2024+). Do not
attempt device preparation on Windows 10.

## R5. Microsoft Entra join is the only supported join type
**Description:** Devices provision as **Microsoft Entra joined** (cloud-first). Hybrid
Entra join is **not** supported by Autopilot device preparation.
**Why:** Device preparation supports **Entra join only**; this is also why the "optional
later domain join" in the title means *adding on-prem resource access after the fact*
(e.g. via Entra hybrid access / cloud Kerberos trust), **not** provisioning as
hybrid-joined. (Microsoft, *Autopilot device preparation overview → Requirements*.)
**Verify:** `https://entra.microsoft.us` *(verify for GCC High)* → **Devices → Device
settings** → confirm users are allowed to Entra-join devices (set precisely in R7).
**Implement:** Plan a cloud-first Entra-join deployment. If on-prem resource access is
needed, plan it as a **post-provisioning** add-on (out of scope for the zero-touch
provisioning itself).

## R6. The "Intune Provisioning Client" service principal exists and can own a group
**Description:** The service principal **Intune Provisioning Client** — AppId
**`f1346770-5b25-470b-88bd-d5744ab7952c`** — is present in the tenant (it may appear as
**Intune Autopilot ConfidentialClient**; match by **AppId**).
**Why:** Autopilot device preparation uses **Enrollment Time Grouping** — Intune adds each
newly enrolled device to the assigned device group **only** if this service principal is an
**owner** of that group. Without the owner, the group stays empty and **nothing deploys
during OOBE**. (Microsoft, *Create an assigned device group*; device preparation
troubleshooting.)
**Verify:** `https://entra.microsoft.us` *(verify for GCC High)* → **Enterprise
applications** → search the AppId `f1346770-5b25-470b-88bd-d5744ab7952c`.
**Implement:** If missing, it is created when you first configure Autopilot device
preparation / automatic enrollment; open the Intune admin center once as Global Admin to
trigger provisioning, then re-check. `CFAPG-Validation.ps1` checks for this principal.

## R7. Users are allowed to join devices to Microsoft Entra ID
**Description:** The first user who signs in during OOBE must have **Entra join
permission**.
**Why:** The device Entra-joins under that user; if joining is blocked, provisioning fails
at OOBE. (Microsoft, *Autopilot device preparation requirements → Configuration*.)
**Verify:** `https://entra.microsoft.us` *(verify for GCC High)* → **Devices → Device
settings → Users may join devices to Microsoft Entra** → set to **Selected** with the group
`CFAPG-Provisioning-Users`, or **All**.
**Implement:** Set the value and add pilot users to `CFAPG-Provisioning-Users` (created in
`03-implementation.md`).

## R8. Automatic (MDM) enrollment is enabled for Windows
**Description:** Windows **automatic enrollment** is turned on so an Entra-joined device
auto-enrolls into Intune.
**Why:** Device preparation relies on Entra join triggering Intune MDM enrollment.
**Verify:** `https://intune.microsoft.us` → **Devices → Enrollment → Automatic Enrollment**
(or **Windows enrollment**); confirm **MDM user scope** includes your provisioning users.
**Implement:** Set **MDM user scope** to **Some** (`CFAPG-Provisioning-Users`) or **All**.

## R9. Sovereign network endpoints allowed through filtering
**Description:** Devices and admins can reach the **US Gov** service endpoints outbound
(HTTP 80, HTTPS 443, and UDP 123 for time), with **no SSL inspection** on the Intune/MDM
endpoints.
**Why:** Enrollment, policy sync, app delivery, activation, and diagnostics all depend on
these URLs; SSL inspection on `*.manage.microsoft.us` breaks management. (Microsoft,
*Network endpoints for US government deployments*.)
**Why (allow-list, minimum):**
- `*.manage.microsoft.us` (unauthenticated proxy access required; **no SSL inspection**)
- `enterpriseregistration.microsoftonline.us`
- `login.microsoftonline.us`
- `graph.microsoft.us`
- `portal.manage.microsoft.us`
- `login.live.com` (Autopilot deployment service contact)
- `time.windows.com` (UDP 123, NTP)
- `*.msftconnecttest.com` (NCSI), `*.events.data.microsoft.com` (diagnostics),
  `lgmsapeweu.blob.core.windows.net` (device-prep diagnostics upload)
- Office 365 **US Gov** URL/IP ranges (via the Office 365 IP/URL service, worldwide feed
  includes Gov)

**Verify:** From a target network, resolve and reach `https://login.microsoftonline.us` and
`https://portal.manage.microsoft.us`. `CFAPG-Discovery.ps1` records the endpoints in scope.
**Implement:** Allow the URLs above through proxy/firewall; **exempt** `*.manage.microsoft.us`
and Defender endpoints from SSL/TLS inspection.

## R10. Understand the GCC High servicing model (no Autopatch / update policies)
**Description:** Windows servicing is delivered via **Update rings for Windows 10 and
later** — **not** Windows Autopatch, feature/quality/expedite/driver update policies (all
**not available** in GCC High).
**Why:** Building the rollout around Autopatch or the newer update policies will fail
because those blades/policies do not function in GCC High. (Microsoft, *Intune Government
Service overview → features not available / planned*.)
**Verify:** `https://intune.microsoft.us` → **Devices → Windows → Update rings**; confirm
Update rings are available (they are). Note that **Feature updates**/**Quality updates**
policy types are absent or non-functional.
**Implement:** Plan `CFAPG-UpdateRing-Pilot` as the servicing mechanism
(built in `03-implementation.md`).

---

## Assess gate (pass/fail)

Do **not** proceed to Configure until **all** are TRUE:

- [ ] R1 — Tenant confirmed **GCC High or DoD** (not Commercial, not GCC).
- [ ] R2 — Qualifying **Gov** license with Intune + Entra ID P1/P2 assigned to pilot users.
- [ ] R3 — Operator has **Intune Administrator**; a Global Admin is available for setup.
- [ ] R4 — Target devices run **supported Windows 11** (24H2+, or 22H2/23H2 + KB5035942).
- [ ] R5 — Deployment planned as **Entra join** (not hybrid).
- [ ] R6 — **Intune Provisioning Client** (`f1346770-…`) present and can own a group.
- [ ] R7 — Users may **join devices to Entra** (`CFAPG-Provisioning-Users` or All).
- [ ] R8 — **Automatic enrollment** enabled for the provisioning users.
- [ ] R9 — Sovereign **endpoints allowed**, **no SSL inspection** on `*.manage.microsoft.us`.
- [ ] R10 — Servicing planned via **Update rings** (no Autopatch/update-policy dependency).

Any FALSE → fix before configuring. `CFAPG-Validation.ps1` automates R6–R8 checks against
US Gov Graph.

## Sources

- Microsoft, *Microsoft Intune Government Service overview.*
- Microsoft, *Overview of Windows Autopilot device preparation.*
- Microsoft, *Windows Autopilot device preparation requirements.*
- Microsoft, *Network endpoints for US government deployments.*
- Microsoft, *Windows Autopilot device preparation — create an assigned device group.*
