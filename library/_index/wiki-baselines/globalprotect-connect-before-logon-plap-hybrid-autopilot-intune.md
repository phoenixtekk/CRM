# GlobalProtect Connect Before Logon (PLAP) for Hybrid Azure AD Join Autopilot via Microsoft Intune — Deployment, Registration & Reboot-Sequencing Troubleshooting

> **Version 1.0.0** · Category: Network · Solution code: GPPLAP

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — GlobalProtect Connect Before Logon (PLAP) for Hybrid Azure AD Join Autopilot via Microsoft Intune

## The business problem
After a security incident, the organization moved off **Always On VPN** to a **user-initiated VPN** — but
it still provisions Windows with **Hybrid Azure AD Join Windows Autopilot**, which needs the device to
reach a **domain controller before the first user signs in** (for domain join, Group Policy, and a
first-time logon with no cached credentials). A user-initiated VPN breaks that pre-logon reachability
unless the tunnel can be raised **at the sign-in screen**. In practice the base **GlobalProtect** client
deploys fine from Intune, but the **Connect Before Logon (PLAP)** registration is fragile: it
intermittently fails with an **"unzipping" error** during Autopilot, reboot orchestration compounds it,
and the **Connect Before Logon control is not reliably visible** at sign-in. Testing was on Windows 10;
production is **Windows 11**. The rollout stalls, and every failure is hard to diagnose.

## The solution
This is a complete, self-guided package that makes GlobalProtect Connect Before Logon **deployable AND
diagnosable** for the hybrid-join Autopilot scenario. It delivers Connect Before Logon as a **single,
correctly sequenced Intune Win32 app** — install the GlobalProtect MSI (5.2+), write the registry that
enables Connect Before Logon and sets the portal, wait for the GlobalProtect service, register PLAP in the
SYSTEM context, and **return exit code 3010 so the Enrollment Status Page owns the reboot** (never a
scripted reboot). It makes the app a **blocking app** in the ESP, targets an **Assigned** Autopilot device
group **owned by the Intune Provisioning Client service principal** so it populates at enrollment, and
neutralizes the **"unzipping" 0x87D30067** error with an antivirus/IMECache exclusion and a clean re-wrap.
A **log-capture runbook** turns any failed provisioning into a diagnosed cause on a Windows 11 test device.

## What you get
- **Step-by-step implementation** at click-by-click detail on the Intune/Autopilot/Entra/Windows side —
  the single Win32 app, the ESP blocking app, the enrollment-time device group, and the AV exclusion,
  with explicit Gate A–E pass/fail gates.
- **Five PowerShell tools** — readiness discovery (incl. the group's service-principal owner check),
  on-device Windows 11 validation, a **log-capture collector** (IME + Autopilot + GlobalProtect logs),
  fleet coverage reporting, and an enrollment-time device-group builder that sets the SP owner.
- **Requirements, testing, troubleshooting, and best-practice guides** — including a failure-mode matrix
  covering the unzip error, the missing sign-in tile, reboot-loop and IME-state loss, ESP hangs, the
  Win10-vs-Win11 mismatch, and hybrid first-logon failures.

## Business outcomes
- **Hybrid Autopilot works over a user-initiated VPN** — the tunnel is up before logon, so domain join,
  Group Policy, and first-time logon succeed off-network, with no Always On dependency.
- **The fragile seams are removed** — one correctly sequenced app, ESP-owned reboot, and an AV exclusion
  end the intermittent unzip failures and the missing Connect Before Logon tile.
- **Faster diagnosis** — a repeatable log-capture runbook replaces guesswork in the test window.
- **Lower risk** — piloted on Windows 11 before fleet-wide rollout, validated against explicit gates, and
  reversible at any point.

## Scope and boundary
The solution is authored at full detail on the **Microsoft Intune, Autopilot, Entra ID, and Windows**
side. The **GlobalProtect portal / gateway configuration and the GlobalProtect app internals** are the
customer's existing Palo Alto environment and follow **Palo Alto Networks' official documentation** — this
package consumes those artifacts (the MSI, portal FQDN, and authentication method) and delivers Connect
Before Logon reliably during enrollment.

## Bottom line
GlobalProtect Connect Before Logon, installed and registered during Hybrid-Join Autopilot, with the sign-in
tile present at first logon — delivered as a single sequenced app that lets ESP own the reboot, made
diagnosable with a log-capture runbook, and proven on a Windows 11 pilot before you scale.


---


# Solution Overview — GlobalProtect Connect Before Logon (PLAP) for Hybrid Azure AD Join Autopilot via Microsoft Intune

## What this solution is

This solution deploys the **Palo Alto Networks GlobalProtect** app with its **Connect Before Logon
(CBL)** capability to your **Windows 11** fleet using **Microsoft Intune**, so the VPN tunnel comes up
**at the Windows sign-in screen — before the user signs in to Windows.** It is built for the specific,
hard case: a **Hybrid Azure AD Join Windows Autopilot** provisioning where the device must reach a
**domain controller before first user logon**, but the organization has moved to **user-initiated
VPN** and can no longer rely on Always On VPN. The goal is a consistent, tested, hands-off build: the
GlobalProtect app, the Connect Before Logon registration, and the portal configuration all land during
Autopilot enrollment, are validated on a small pilot first, and are then expanded fleet-wide with a
documented rollback path — and, critically, are **diagnosable** when the enrollment sequence misbehaves.

The work is authored at click-by-click detail on the **Intune, Autopilot, Entra ID, and Windows** side.
The **GlobalProtect portal / gateway configuration and the GlobalProtect app internals are deferred to
Palo Alto Networks' official documentation** — this solution tells you *what* Palo Alto artifacts you
need (the MSI, the portal FQDN, the authentication method) and *where* they plug into Intune, not how to
click through Palo Alto's own consoles.

## The real-world scenario this solves

The situation this package is built around is a live deployment blocker, not a hypothetical:

- The organization **abandoned Always On VPN after a security incident** and now requires
  **user-initiated VPN** — a tunnel the user (or the sign-in screen) brings up, not one that is always
  established by the machine.
- The organization provisions Windows with **Hybrid Azure AD Join Windows Autopilot (user-driven)**.
  Hybrid join and first interactive logon need **line-of-sight to a domain controller before the user
  signs in** — for domain join completion, Group Policy, and a first-time (no cached credential) logon.
- User-initiated VPN breaks that pre-logon reachability **unless** the tunnel can be raised *at the
  sign-in screen*. **GlobalProtect Connect Before Logon (PLAP)** is exactly that capability — it adds a
  network sign-in tile to the Windows lock screen so the tunnel comes up before Windows logon.
- In practice the base GlobalProtect client deploys fine from Intune, but the **PLAP registration** step
  is fragile: it **intermittently fails with an "unzipping" error** during Autopilot, reboot
  orchestration is suspected of compounding the failure, and the **"Connect Before Logon" control is not
  reliably visible** at the sign-in screen. Early testing was on **Windows 10**, while production targets
  **Windows 11**.

This solution makes that scenario **deployable** (a single, correctly sequenced Intune app that installs,
enables, and registers Connect Before Logon and lets the Enrollment Status Page own the reboot) **and
diagnosable** (a log-capture runbook and validation tooling for a Windows 11 test device), so the
"unzip" failure, the reboot fragility, and the missing sign-in tile are each turned into a known cause
with a known fix.

## What GlobalProtect Connect Before Logon (CBL / PLAP) is

**Connect Before Logon (CBL)** is implemented on Windows as a **Pre-Login Access Provider (PLAP)** — a
*connectable credential provider* that adds a **network sign-in / Connect Before Logon** tile to the
Windows sign-in screen, so a user can establish the GlobalProtect tunnel **before** authenticating to
Windows. It was introduced in the GlobalProtect app **5.2**, so this solution requires **GlobalProtect
app 5.2 or later** and targets **Windows 11**. CBL supports basic credentials, certificates, and SAML
authentication (the head-end decides which — deferred to Palo Alto docs).

For that tile to appear and work, **three things** must be true on the device, in order:

1. **The GlobalProtect app (5.2+) is installed.**
2. **Connect Before Logon is enabled and pointed at a portal.** This is a registry setting under
   `HKEY_LOCAL_MACHINE\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\` — the value **`Prelogon`**
   set to **`1`**, and the default **`Portal`** address set under the same `PanSetup` key. Both must
   exist **before** registration and before the sign-in screen is reached.
3. **The PLAP credential provider is registered.** Registration is performed by running
   **`PanGPS.exe -registerplap`** (from `C:\Program Files\Palo Alto Networks\GlobalProtect`) in the
   **SYSTEM** context. (The reverse is `PanGPS.exe -unregisterplap`.) The GlobalProtect service
   (**PanGPS**) must be ready before registration runs.

Miss any one of the three — app below 5.2, `Prelogon` not set, or `-registerplap` never run (or run
before the service is ready) — and the Connect Before Logon tile silently never appears. This solution
delivers **all three together** so a device is either fully Connect-Before-Logon-ready or clearly not —
never half-configured.

## How it is delivered through Intune (the recommended single Win32 app)

Everything is delivered from the cloud to Autopilot-provisioning Windows 11 devices. Palo Alto ships a
wrapper-script pattern (**`InstallGlobalProtect_PLAP.ps1`**) that installs GlobalProtect, sets the
portal, and registers PLAP; this solution **recommends consolidating install + registry + registration
into ONE Win32 app** so the ordering and reboot cannot fragment across separate deployments:

- **The single Win32 app.** One **Win32 app** (`.intunewin`) that:
  1. installs the **GlobalProtect MSI (5.2+)** with `Start-Process … -Wait` so the installer fully
     completes before the script returns,
  2. writes the **`PanSetup` registry** values — `Prelogon = 1` and the default `Portal` address,
  3. **waits for the GlobalProtect service (PanGPS) to be ready**, then runs
     **`PanGPS.exe -registerplap`** in the **SYSTEM** context, and
  4. **returns exit code `3010`** (soft reboot) so **Intune / the Enrollment Status Page manages the
     reboot** — the script never calls a forced `Restart-Computer` itself.
  - **App name:** `GlobalProtect – Connect Before Logon (PLAP) – Win32`
- **The Enrollment Status Page (ESP) blocking app.** The Win32 app is made a **blocking app** in the
  Autopilot ESP so provisioning **waits** for Connect Before Logon to be installed and registered before
  the user reaches the desktop.
  - **ESP reference:** `ESP – Autopilot – GlobalProtect PLAP Blocking`
- **(Optional) the device certificate** (only if the portal uses certificate authentication). A SCEP
  certificate profile issuing a device certificate the portal trusts.
  - **Certificate profile:** `GlobalProtect – PLAP – Device Cert (SCEP) – Windows`

### The two-app alternative (documented, not recommended)

You *can* split the work into a base app plus a registration app —
`GlobalProtect – VPN Client – Win32` (installs GlobalProtect + sets the `PanSetup` registry) and
`GlobalProtect – PLAP Registration – Win32` (runs `PanGPS.exe -registerplap`), with the registration app
declared **dependent** on the base app. This works, but it introduces an ordering/reboot seam between two
deployments during Autopilot — the exact seam where the "unzip" and sequencing failures cluster. Prefer
the **single-app** path; the two-app model is documented for environments that already separate them.

## Why exit code 3010 and not a scripted reboot (the reboot-sequencing rule)

The most damaging mistake in this scenario is calling a **forced `Restart-Computer`** inside the install
script during the Autopilot ESP. That interrupts the Intune Management Extension (IME) agent mid-state
and causes install failures or lost app state — which is what makes reboot orchestration *look* like the
cause of the "unzip" error. The correct pattern is:

- **Never** reboot from inside the script. **Return `3010`** (soft reboot) and let **Intune/ESP** own the
  reboot at the right moment in the sequence.
- **Map the return codes** in the Win32 app: `0` and `1707` = success, `3010` = soft reboot, `1618` =
  retry (another install in progress).
- **Use `Start-Process … -Wait`** for the MSI so the app never reports complete before the installer
  actually finishes (a missing `-Wait` makes the app "succeed" early, before PLAP can register).

## The "unzipping" error, in one paragraph

The intermittent **"unzipping"** failure is Intune Win32 error **`0x87D30067`**: the IME downloaded the
`.intunewin` but **failed to unzip it** into the IME content/cache path
(`C:\Program Files (x86)\Microsoft Intune Management Extension\Content\…` / IMECache). The usual causes
are **antivirus (Microsoft Defender or third-party) locking or scanning the IMECache during extraction**,
**low disk space**, a **corrupt or improperly re-wrapped `.intunewin`** (for example nesting an
already-wrapped payload), or path/permission tampering. The fixes: **exclude the IME content/IMECache
paths from AV during provisioning**, free disk space, **re-wrap the package cleanly** with the current
**Microsoft Win32 Content Prep Tool**, and verify the source folder. The Troubleshooting guide turns each
cause into a concrete step.

## Autopilot enrollment-time targeting (why an Assigned device group with an SP owner)

Because the app must install **during** Autopilot (before a user is on the device), it is targeted at an
Entra **device** group that is populated **at enrollment**. Enrollment-time device grouping requires an
**Assigned** (not Dynamic) security group whose **Owner** is the **Intune Provisioning Client** first-party
service principal (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**, shown in many tenants as *Intune
Autopilot ConfidentialClient*). Without that service principal as an owner, the assigned group stays
**empty at enrollment** and nothing deploys. This solution names those groups and sets the owner
explicitly:

- **Pilot device group:** `PILOT – GlobalProtect PLAP – Autopilot Devices`
- **Production device group:** `PROD – GlobalProtect PLAP – Autopilot Devices`

## Benefits

- **The tunnel is up before Windows logon.** Hybrid Autopilot devices reach a domain controller for
  domain join, Group Policy, and first-time (no cached credential) logon — over a **user-initiated** VPN,
  with no Always On dependency.
- **One correctly sequenced app.** Install, registry, service-readiness wait, and PLAP registration in a
  single Win32 app that returns `3010` and lets ESP own the reboot — the fragile seams are removed.
- **Diagnosable, not just deployable.** A log-capture runbook and validation tooling for a Windows 11
  test device turn the "unzip" error, the reboot fragility, and the missing sign-in tile into known
  causes with known fixes.
- **Pilot-first and rollback-ready.** App, ESP blocking, and any certificate profile are assigned to a
  named pilot device group, validated against explicit gates, and only then expanded. Uninstall/exclude
  is a one-click reversal.
- **Traceable and reportable.** Every object is named to a convention, so the discovery, validation,
  log-capture, and reporting scripts find and check them deterministically — including whether the
  Connect Before Logon registration is actually present.

## Limitations and boundaries

- **Windows only, Windows 11 target.** Connect Before Logon is a Windows credential-provider (PLAP)
  feature; this solution targets **Windows 11** (production) with GlobalProtect **5.2+**. Windows 10 may
  work but early "works on Win10, not Win11" reports mean you must **re-test on Windows 11** — see
  Troubleshooting.
- **GlobalProtect portal / gateway and app internals are out of scope.** The GlobalProtect **portal and
  gateway** configuration, the authentication method the portal enforces, and the GlobalProtect **app**
  internals are done per **Palo Alto Networks' official documentation**. This solution consumes those
  artifacts (the MSI, the portal FQDN, the auth method) and delivers them via Intune.
- **Autopilot Hybrid Azure AD Join is a prerequisite, not a deliverable.** The Autopilot profile, the
  Enrollment Status Page, and the Domain Join configuration profile / on-prem Domain Join (ODJ) connector
  must already be configured (Requirements guide). Hybrid join also needs the device to reach a DC — which
  is exactly what Connect Before Logon provides at the sign-in screen.
- **A working PKI is assumed only if the portal uses certificate auth.** The optional device certificate
  depends on a SCEP path (on-prem NDES, Intune Cloud PKI, or a supported third-party CA connector).

## The standard deployment model

This solution follows the category-standard model, with explicit pass/fail gates at each step:

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess.** Confirm prerequisites (Requirements guide), gather the Palo Alto inputs (the GlobalProtect
   5.2+ MSI, the portal FQDN, the auth method), and confirm the Autopilot Hybrid-Join profile, the ESP,
   and the Domain Join config / ODJ connector are in place. **Gate A.**
2. **Configure.** Build the single Win32 app (install + `PanSetup` registry + service-readiness wait +
   `PanGPS.exe -registerplap` in SYSTEM + return `3010`), set install context System, detection and
   return-code mapping, add it as an **ESP blocking app**, and assign to
   `PILOT – GlobalProtect PLAP – Autopilot Devices`; add the AV/IMECache exclusion. **Gate B.**
3. **Pilot.** Run an Autopilot Hybrid-Join provisioning on a **Windows 11** test device. **Gate C.**
4. **Validate.** Confirm the Connect Before Logon tile appears at the sign-in screen, the pre-logon
   tunnel comes up, the DC is reachable, and a first interactive **hybrid domain** logon succeeds
   off-network; collect logs with the toolkit. **Gate D.**
5. **Expand.** Widen assignment to `PROD – GlobalProtect PLAP – Autopilot Devices`, monitor coverage, and
   keep the rollback ready. **Gate E.**

Proceed to the **Requirements guide** (`02-requirements.md`) to confirm you are ready to build.


---


# Requirements — GlobalProtect Connect Before Logon (PLAP) for Hybrid Azure AD Join Autopilot via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying **GlobalProtect Connect
Before Logon (PLAP)** during a **Hybrid Azure AD Join Windows Autopilot** provisioning.

> **Vendor boundary:** the **GlobalProtect portal / gateway configuration and the GlobalProtect app
> internals are deferred to Palo Alto Networks' official documentation.** Below, "obtain from Palo Alto"
> means *get the artifact/value from your Palo Alto admin or Palo Alto docs* — this guide does not
> fabricate GlobalProtect portal menu paths.

> **Government note (GCC High / DoD):** the steps below name the commercial portals
> (`https://intune.microsoft.com`, `https://entra.microsoft.com`, `https://login.microsoftonline.com`).
> In a US-Gov (GCC High / DoD) tenant use the sovereign portals instead —
> `https://intune.microsoft.us` / `https://endpoint.microsoft.us`, `https://entra.microsoft.us`, and
> `https://login.microsoftonline.us` — and **verify each step for GCC High**, as feature availability
> and rollout can differ. This guide does not invent GCC-specific menus.

---

## R1. Windows 11 scope confirmed
**Description:** The target devices are **Windows 11** devices provisioned by Windows Autopilot; Connect
Before Logon is a Windows-only feature and production here is Windows 11.
**Why required:** Connect Before Logon is implemented as a Windows credential provider (PLAP). Early
testing on Windows 10 can behave differently from Windows 11 (see Troubleshooting), so the pilot and the
log-capture runbook must run on **Windows 11**.
**How to verify:** Your in-scope device list is Windows 11; the pilot test device is Windows 11.
**How to implement if missing:** Scope the pilot and production device groups to Windows 11. If a Windows
10 estate remains, re-test the whole build separately on Windows 10 rather than assuming parity.

## R2. Microsoft Intune licensing and Autopilot-enrolled devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone) and
the target Windows 11 devices registered for Windows Autopilot.
**Why required:** Intune is the delivery plane for the Win32 app, the Enrollment Status Page, and any
certificate profile. Nothing deploys to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > Enrollment > Windows > Windows Autopilot devices** and confirm the target devices are
registered; under **Tenant administration > Licenses**, confirm Intune licenses are assigned.
**How to implement if missing:** Assign an Intune-bearing license; register the devices for Autopilot
(hardware hash import or OEM/CSP registration).

## R3. Windows Autopilot Hybrid Azure AD Join deployment profile
**Description:** A **Windows Autopilot deployment profile** configured for **Hybrid Azure AD Join**
(user-driven), assigned to the Autopilot device group.
**Why required:** This solution exists to make hybrid-join Autopilot work over a user-initiated VPN.
Without the hybrid-join Autopilot profile there is no provisioning sequence for Connect Before Logon to
support.
**How to verify:** Intune → **Devices > Enrollment > Windows > Deployment Profiles**; a profile exists
with **Join type = Hybrid Azure AD joined**, assigned to the Autopilot device group.
**How to implement if missing:** Create the deployment profile (Intune → **Devices > Enrollment >
Windows > Deployment Profiles > Create profile > Windows PC**), set **Join to Azure AD as = Hybrid Azure
AD joined**, and assign it to the Autopilot device group.

## R4. Domain Join configuration profile and on-prem Domain Join (ODJ) connector
**Description:** An Intune **Domain Join** device-configuration profile (target domain, OU) and a healthy
**Intune Connector for Active Directory** (the on-prem Domain Join / ODJ connector).
**Why required:** Hybrid Azure AD Join Autopilot completes the on-prem domain join through the ODJ
connector; the device must reach a domain controller to finish join and first logon — the reachability
that Connect Before Logon provides at the sign-in screen.
**How to verify:** Intune → **Devices > Configuration**; a **Domain Join** profile exists and is assigned.
Intune → **Devices > Enrollment > Windows > Intune Connector for Active Directory**; the connector shows
**Active**.
**How to implement if missing:** Install/repair the Intune Connector for Active Directory on a domain-joined
server, create the **Domain Join** profile (domain, OU), and assign it to the Autopilot device group.

## R5. Enrollment Status Page (ESP) configured
**Description:** A Windows **Enrollment Status Page** profile assigned to the Autopilot devices, into
which the GlobalProtect PLAP app will be added as a **blocking app**.
**Why required:** The ESP is what makes provisioning **wait** for Connect Before Logon to install and
register before the user reaches the desktop, and it is what owns the reboot the app requests with exit
code `3010`.
**How to verify:** Intune → **Devices > Enrollment > Windows > Enrollment Status Page**; a profile (other
than the disabled default, if you use a targeted one) is enabled and assigned.
**How to implement if missing:** Create/enable an ESP profile (Intune → **Devices > Enrollment > Windows
> Enrollment Status Page > Create**), set **Show app and profile installation progress = Yes**, and
assign it. You will reference it as `ESP – Autopilot – GlobalProtect PLAP Blocking` in Implementation.

## R6. GlobalProtect app installer (5.2 or later) — the MSI
**Description:** The official **GlobalProtect** Windows **MSI** installer, version **5.2 or later** (the
first release with Connect Before Logon).
**Why required:** Connect Before Logon (the PLAP credential provider) exists only in GlobalProtect 5.2+.
The MSI is the exact binary the Win32 app installs.
**How to verify:** Obtain the MSI from your Palo Alto admin / Palo Alto support portal and confirm the
version is **≥ 5.2** for the release your portal supports.
**How to implement if missing:** Obtain the correct entitled GlobalProtect MSI (5.2+) from Palo Alto. Do
not repackage or re-sign the vendor binary; use the vendor-provided MSI.

## R7. GlobalProtect portal FQDN and authentication method
**Description:** The **portal FQDN** (e.g. `portal.your-company.com`) that Connect Before Logon points at,
and the **authentication method** the portal enforces (basic credentials, certificate, or SAML).
**Why required:** The portal FQDN is written into the `PanSetup` registry (`Portal`) and the auth method
determines whether an optional device certificate (R8) is needed. These are inputs, not things this guide
configures on the Palo Alto side.
**How to verify:** Obtain from your Palo Alto admin: the **portal FQDN** and the **pre-logon auth method**.
Confirm a manual GlobalProtect connect to that portal already succeeds with the intended method.
**How to implement if missing:** Configure the GlobalProtect **portal/gateway** and its authentication
**per Palo Alto Networks' official documentation** — Palo Alto-side work outside this solution's scope.
Record the portal FQDN and auth method for Implementation.

## R8. Certificate infrastructure (only if the portal uses certificate authentication)
**Description:** A working PKI path for Intune to deliver a **device** certificate — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — plus the trusted
root/intermediate CA.
**Why required:** If the portal authenticates Connect Before Logon with a certificate, each device needs a
machine certificate the portal trusts, delivered by Intune, present before the sign-in screen. (Skip R8
if the portal uses basic credentials or SAML at the Connect Before Logon window.)
**How to verify:** Intune → **Devices > Configuration**; a SCEP certificate profile named
`GlobalProtect – PLAP – Device Cert (SCEP) – Windows` can be created and deploys to a test device, and the
issued cert chains to a CA the GlobalProtect portal trusts.
**How to implement if missing:** Stand up the SCEP path (NDES + Intune Certificate Connector, or enable
Intune Cloud PKI), publish the trusted root/intermediate, then create the SCEP profile. Ensure the
**issuing CA is trusted by the GlobalProtect portal/gateway** (Palo Alto-side trust config is deferred to
Palo Alto docs).

## R9. Autopilot device group — Assigned, owned by the Intune Provisioning Client service principal
**Description:** A pilot Autopilot **device** group `PILOT – GlobalProtect PLAP – Autopilot Devices` and a
production device group `PROD – GlobalProtect PLAP – Autopilot Devices`, each an **Assigned** (not Dynamic)
security group whose **Owner** includes the **Intune Provisioning Client** service principal
(**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**).
**Why required:** For a device to receive the app **at enrollment**, it must be in the target group at
enrollment time. Enrollment-time device grouping works only when the group is **Assigned** and the Intune
Provisioning Client SP **owns** the group; without that owner the assigned group stays empty at
enrollment and the app never deploys.
**How to verify:** Entra → **Groups > All groups**; `PILOT – GlobalProtect PLAP – Autopilot Devices`
exists, is **Assigned**, and under **Owners** lists the service principal with
AppId `f1346770-5b25-470b-88bd-d5744ab7952c` (search by **AppId** — the display name, often *Intune
Autopilot ConfidentialClient*, varies by tenant).
**How to implement if missing:** Entra → **Groups > New group > Security** (membership type **Assigned**);
name it exactly `PILOT – GlobalProtect PLAP – Autopilot Devices`; add the Autopilot devices; then
**Owners > Add owners** and add the SP by **AppId** `f1346770-5b25-470b-88bd-d5744ab7952c`. If the SP is
absent, provision it by opening the Intune portal once as Global Administrator. The included
`GPPLAP-Set-ScopeTargeting.ps1` creates the group, adds devices, and sets the SP owner for you.

## R10. Reboot-sequencing and return-code design confirmed
**Description:** A confirmed design that the install script **never** calls a forced `Restart-Computer`
during the ESP, **returns exit code `3010`** for reboot, uses `Start-Process … -Wait` for the MSI, and
maps the Win32 return codes (`0`/`1707` success, `3010` soft reboot, `1618` retry).
**Why required:** A scripted reboot mid-ESP interrupts the Intune Management Extension and causes install
failures/lost state — the failure mode this solution is built to remove. Returning `3010` lets Intune/ESP
own the reboot; `-Wait` stops the app reporting complete before the installer finishes.
**How to verify:** Your install script has no `Restart-Computer`; it returns `3010` after registration;
the MSI is launched with `-Wait`; the app's return-code mapping is set (Implementation §2).
**How to implement if missing:** Adopt the single-app pattern in Implementation §2 (it already encodes
this). Never reboot from the script; always return `3010` and map the codes on the app.

## R11. Antivirus exclusion for the IME content/cache path (to avoid the "unzip" 0x87D30067 failure)
**Description:** During provisioning, the Intune Management Extension content/cache path is **excluded**
from real-time antivirus scanning (Microsoft Defender or third-party), and the device has adequate free
disk space.
**Why required:** The intermittent **"unzipping"** failure is Intune error **`0x87D30067`** — the IME
failed to unzip the `.intunewin` into its content/cache path, most often because AV locked or scanned the
IMECache during extraction (or the disk was low, or the package was badly re-wrapped).
**How to verify:** Your provisioning AV policy excludes
`C:\Program Files (x86)\Microsoft Intune Management Extension\Content` (and the IMECache), and the target
devices have sufficient free disk.
**How to implement if missing:** Add the IME content/IMECache path to the AV exclusion list applied during
provisioning; ensure free disk space; and always re-wrap the `.intunewin` cleanly with the current Content
Prep Tool (R12) rather than nesting an already-wrapped payload.

## R12. Microsoft Win32 Content Prep Tool (current version)
**Description:** The **Microsoft Win32 Content Prep Tool** (`IntuneWinAppUtil.exe`), current release, on
the packaging workstation, used to wrap the GlobalProtect MSI + the install/registration script into an
`.intunewin`.
**Why required:** A single Win32 app that installs the MSI, writes the registry, waits for the service, and
registers PLAP is best delivered as an `.intunewin`. A stale tool or a nested/already-wrapped payload is a
known cause of the `0x87D30067` unzip failure.
**How to verify:** `IntuneWinAppUtil.exe` runs and reports its version; you wrap a **clean** source folder
(the MSI + the script), not an already-wrapped file.
**How to implement if missing:** Download the current Win32 Content Prep Tool from Microsoft's official
`microsoft-Win32-Content-Prep-Tool` release and place it on the packaging workstation.

## R13. Administrative roles for building the deployment
**Description:** Intune admin rights to create Win32 apps, the ESP, and certificate profiles; Entra rights
to create/populate groups and set group owners (Groups Administrator or better).
**Why required:** Packaging the app, editing the ESP, creating cert profiles, and setting the service-principal
group owner all require elevated roles.
**How to verify:** In Intune you can reach **Apps > Add** and **Devices > Enrollment**; in Entra you can
create groups and add owners.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator** and **Groups
Administrator** (least-privilege) to the operator; setting the first-party SP as a group owner may require
a Global Administrator the first time.

## R14. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by the
discovery/report/scope-targeting scripts (the on-device validation and log-capture scripts run locally and
need no Graph).
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory the app, the ESP, the cert
profile, the device groups, group membership, and the group owner.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts call
`Connect-MgGraph` with the specific delegated scopes each one documents in its header.

## R15. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (exclude the group / remove the app from
the ESP blocking list / uninstall the app / unregister PLAP).
**Why required:** Adding a blocking app to the Autopilot ESP and a credential provider to the sign-in
screen changes the provisioning and logon experience for real users; changes must be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – GlobalProtect PLAP – Autopilot Devices`, remove the app from the ESP blocking list, and flip the
Win32 app to **Uninstall** (which can also run `PanGPS.exe -unregisterplap`).
**How to implement if missing:** Document the rollback (assignment exclusion, remove from ESP blocking
apps, app **Uninstall** intent incl. `-unregisterplap`, cert removal) and the comms plan before you
assign anything.

---

When all requirements pass, proceed to `03-implementation.md`.


---


# Global Requirements — Network (category-level)

These requirements apply to **every** solution in the **Network** category (SASE/SSE, secure web
gateway, Zero Trust network access, and related network-security work — Netskope-centric). They are
published once at the category level so individual listings stay small. Confirm these before deploying
*any* Network solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

> **Vendor note:** these solutions are authored at the correct architectural and procedural level.
> Exact, current **Netskope console** screens, menu paths, and tenant-specific options change over
> time and are **deferred to the official Netskope documentation and your Netskope tenant** — follow
> the named step and confirm the precise control in your console.

## G1. A Netskope tenant
**Description:** An active, licensed Netskope tenant with admin access.
**Why:** It is the control plane for SWG, ZTNA, SSL inspection, and policy.
**Verify:** Sign in to your Netskope tenant admin console as an administrator.
**Implement:** Engage your Netskope account team / reseller to provision a tenant and the required modules.

## G2. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for SSO, identity-based policy, and user/group steering.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G3. Endpoint management (Intune)
**Description:** Microsoft Intune (or an equivalent) able to deploy the client and certificates to endpoints.
**Why:** The Netskope client, root/decryption certificates, and steering config are delivered to managed devices.
**Verify:** `https://intune.microsoft.com` loads and target devices are enrolled and compliant.
**Implement:** Assign an Intune-bearing license plan and enroll the target devices.

## G4. Administrative roles
**Description:** Appropriate admin roles in Netskope, Entra ID, and Intune for the operator.
**Why:** Creating policies, app definitions, and deployments requires elevated rights in each plane.
**Verify:** Confirm an admin role in each console (Netskope admin; Entra/Intune admin).
**Implement:** Assign least-privilege admin roles; reserve Global Administrator for tenant-wide changes.

## G5. Network and identity fundamentals in place
**Description:** Working DNS, routing/egress, and an identity source (Entra ID / Active Directory) for users and groups.
**Why:** Traffic steering, SSL inspection, and identity-based policy depend on resolvable, routable, identified traffic.
**Verify:** Endpoints resolve DNS and reach the internet; users/groups are present in Entra ID.
**Implement:** Remediate DNS/egress; sync Active Directory to Entra ID if hybrid.

## G6. A pilot group
**Description:** A Microsoft Entra security group of pilot users/devices for staged rollout.
**Why:** Every solution is piloted before fleet rollout to validate steering, policy, and performance.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G7. Change control and a rollback path
**Description:** A change window and a documented rollback (disable steering / remove client / revert policy).
**Why:** Inline proxy, decryption, and ZTNA changes affect live traffic and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling inline enforcement.
**Implement:** Define the rollback (e.g. steering exception, client uninstall, policy disable) and a comms plan.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# Implementation — GlobalProtect Connect Before Logon (PLAP) for Hybrid Azure AD Join Autopilot via Microsoft Intune

This is the ordered, click-by-click build. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Do **not** skip the pilot. Use the **exact object
names** shown — later steps, tests, troubleshooting, and scripts reference them verbatim.

> **Vendor boundary:** the GlobalProtect **portal / gateway** configuration, the authentication method
> the portal enforces, and the GlobalProtect **app** internals are **deferred to Palo Alto Networks'
> official documentation**. This guide covers the Intune, Autopilot, Entra, and Windows side at full
> detail and *consumes* the Palo Alto-supplied **MSI (5.2+)**, **portal FQDN**, and **auth method** as
> inputs.

> **Government (GCC High / DoD):** substitute the sovereign portals — `https://intune.microsoft.us` /
> `https://endpoint.microsoft.us`, `https://entra.microsoft.us`, `https://login.microsoftonline.us` —
> and **verify each step for GCC High**. Menu names below are the commercial names.

## Object naming convention (use verbatim)

| Object | Name |
|---|---|
| Pilot device group (Assigned; SP owner) | `PILOT – GlobalProtect PLAP – Autopilot Devices` |
| Production device group (Assigned; SP owner) | `PROD – GlobalProtect PLAP – Autopilot Devices` |
| Win32 app (install + enable + register — recommended) | `GlobalProtect – Connect Before Logon (PLAP) – Win32` |
| Alt: base app (two-app model) | `GlobalProtect – VPN Client – Win32` |
| Alt: registration app (two-app model) | `GlobalProtect – PLAP Registration – Win32` |
| Optional device certificate profile (if cert auth) | `GlobalProtect – PLAP – Device Cert (SCEP) – Windows` |
| ESP blocking-app reference | `ESP – Autopilot – GlobalProtect PLAP Blocking` |
| Assignment filter (optional) | `Filter – GlobalProtect PLAP – Windows` |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Gather the Palo Alto inputs (from your Palo Alto admin, per Palo Alto docs):
   - The **GlobalProtect MSI**, version **5.2 or later** (R6).
   - The **portal FQDN** (e.g. `portal.your-company.com`) (R7).
   - The **authentication method** the portal enforces for Connect Before Logon (basic / certificate /
     SAML) (R7) — this decides whether the optional certificate profile (R8) is needed.
3. Confirm the Autopilot side is ready: the **Hybrid Azure AD Join** deployment profile (R3), the
   **Domain Join** profile + **ODJ connector** *Active* (R4), and the **Enrollment Status Page** (R5).
4. Confirm the **reboot-sequencing design** (R10) and the **AV/IMECache exclusion** (R11) are in place.
5. Run the discovery script to baseline readiness:
   `powershell -ExecutionPolicy Bypass -File .\scripts\GPPLAP-Discovery.ps1`
   Review its readiness table before building anything.

**Gate A (Assess):** All requirements pass; the GlobalProtect 5.2+ MSI, portal FQDN, and auth method are
recorded; the Autopilot Hybrid-Join profile, Domain Join + ODJ connector, and ESP are confirmed; and
discovery shows the tenant is ready. If not, stop and remediate.

---

# Phase 2 — Configure

## 2.0 Create the Autopilot device group(s) — Assigned, with the Provisioning Client SP as owner

Use the script (recommended) or the portal. The group **must be Assigned** and **owned by the Intune
Provisioning Client service principal** so it populates at enrollment (R9).

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\GPPLAP-Set-ScopeTargeting.ps1`
  (creates `PILOT – GlobalProtect PLAP – Autopilot Devices` and, with `-CreateProd`,
  `PROD – GlobalProtect PLAP – Autopilot Devices` as **Assigned** groups, adds the devices you supply by
  name, and sets the SP `f1346770-5b25-470b-88bd-d5744ab7952c` as an **owner**). Defaults to `-WhatIf`
  preview; re-run with `-WhatIf:$false` to apply.
- **Portal:**
  1. Entra admin center → **Groups > New group** → **Group type: Security**, **Membership type:
     Assigned** → name it exactly `PILOT – GlobalProtect PLAP – Autopilot Devices` → add the Autopilot
     **devices** as members → **Create**.
  2. Open the group → **Owners > Add owners** → search by **AppId**
     `f1346770-5b25-470b-88bd-d5744ab7952c` (the display name, often *Intune Autopilot
     ConfidentialClient*, varies) → **Select**. If the SP is not found, open the Intune portal once as a
     **Global Administrator** to provision it, then retry.
  3. Repeat for `PROD – GlobalProtect PLAP – Autopilot Devices` (production is assigned in Phase 5).

## 2.1 (Optional) Create the assignment filter

If a group spans device types, create a Windows filter to keep this build on Windows only.

1. Intune → **Tenant administration > Filters > Create**.
2. Name it exactly `Filter – GlobalProtect PLAP – Windows`; **Platform: Windows 10 and later**.
3. Set a rule (e.g. `(device.osVersion -startsWith "10.0.2")` to bias toward Windows 11, or
   `(device.operatingSystem -eq "Windows")`); **Review + create.** Attach it to the app assignment where
   you want to scope by OS.

## 2.2 (If cert auth) Create the device certificate profile

Only if R8 applies (the portal authenticates Connect Before Logon with a certificate).

1. First deploy the **Trusted Root CA** so the device trusts the issuing CA: Intune → **Devices >
   Configuration > Create > New Policy** → **Windows 10 and later** → **Templates > Trusted certificate**
   → upload your root/intermediate `.cer`, set the destination store, and assign to the pilot device
   group.
2. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** → **Templates >
   SCEP certificate** (or **PKCS certificate**).
3. Name it exactly `GlobalProtect – PLAP – Device Cert (SCEP) – Windows`.
4. Set **Certificate type: Device** (there is no user context at the sign-in screen), **Subject name
   format**, **SAN**, **Key usage**, **Extended key usage = Client Authentication**
   (`1.3.6.1.5.5.7.3.2`), a **renewal threshold** comfortably before expiry, the **SCEP server URL(s)**,
   and the **root CA** from step 1.
5. **Assign** to `PILOT – GlobalProtect PLAP – Autopilot Devices`. (The issuing CA must be trusted by the
   GlobalProtect portal/gateway — Palo Alto-side trust config is deferred to Palo Alto docs.)

## 2.3 Build the single Win32 app — install + PanSetup registry + service-readiness wait + register PLAP

This is the recommended path: **one** app that does everything, so ordering and reboot cannot fragment
across separate deployments.

### 2.3a Prepare the package (install + registry + registration in one script, returning 3010)

1. Place into a **clean** source folder (not an already-wrapped file):
   - the **GlobalProtect MSI (5.2+)** from R6, and
   - an **install script** (`Install-GlobalProtect-PLAP.ps1`) that consolidates the steps Palo Alto's
     `InstallGlobalProtect_PLAP.ps1` wrapper performs.
2. The install script must, **in order**:
   1. Install the MSI with a **blocking** call so it fully completes before the script returns —
      `Start-Process msiexec.exe -ArgumentList '/i "GlobalProtect64.msi" /qn' -Wait`. **Never** omit
      `-Wait` (the app would report complete before PLAP can register).
   2. Write the **`PanSetup` registry** values that enable Connect Before Logon and set the portal —
      under `HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup`:
      - `Prelogon` = `1` (DWORD)
      - `Portal` = the portal FQDN from R7 (String)
   3. **Wait for the GlobalProtect service (`PanGPS`) to be ready** — poll `Get-Service PanGPS` until it
      is *Running* (with a bounded timeout) so registration does not run before the service exists.
   4. Run the PLAP registration **in the SYSTEM context** (the Win32 app already runs as System, §2.3c):
      `Start-Process "C:\Program Files\Palo Alto Networks\GlobalProtect\PanGPS.exe" -ArgumentList '-registerplap' -Wait`.
   5. **`exit 3010`** to request a **soft reboot** that **Intune/ESP** manages. **Never** call
      `Restart-Computer` in the script.
3. Wrap the **clean source folder** into an `.intunewin` with the **current** Microsoft Win32 Content
   Prep Tool (R12):
   `IntuneWinAppUtil.exe -c your-source-folder -s Install-GlobalProtect-PLAP.ps1 -o your-output-folder`
   Re-wrap cleanly every time — do **not** nest an already-wrapped payload (a known cause of the unzip
   `0x87D30067` failure).

### 2.3b Add the app to Intune

1. Intune admin center → **Apps > Windows > Add** → App type **Windows app (Win32)** → upload the
   `.intunewin`.
2. **App information.** Name it exactly `GlobalProtect – Connect Before Logon (PLAP) – Win32`; set
   publisher = Palo Alto Networks, version (the MSI version), and a description noting it installs
   GlobalProtect, enables Connect Before Logon (`Prelogon=1` + portal), and registers PLAP.

### 2.3c Program, context, requirements, detection, and return codes

3. **Program.**
   - **Install command:**
     `powershell.exe -ExecutionPolicy Bypass -File Install-GlobalProtect-PLAP.ps1`
   - **Uninstall command:** MSI product-code uninstall (optionally preceded by
     `PanGPS.exe -unregisterplap`).
   - **Install behavior: System.** (PLAP registration must run as **SYSTEM**.)
   - **Device restart behavior:** *Determine behavior based on return codes* (so the `3010` mapping in
     the next step drives the reboot).
4. **Return codes (map exactly):** `0` = Success, `1707` = Success, `3010` = **Soft reboot**, `1618` =
   **Retry**. This is what lets ESP own the reboot instead of the script.
5. **Requirements.** OS architecture **x64**; minimum OS version per Palo Alto's support matrix (target
   Windows 11).
6. **Detection rules.** Detect that the app installed **and** Connect Before Logon is enabled and
   registered — combine:
   - the GlobalProtect install (MSI product code, or file/version of a GlobalProtect binary confirming
     **≥ 5.2**),
   - the registry value `HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\Prelogon` = `1`, and
   - the PLAP credential-provider registration (a Cisco/Palo-Alto-style provider key exists under
     `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`).
   Detecting only the MSI marks a device *Installed* even when Connect Before Logon is not registered.
7. **Assignments.** Under **Required**, add `PILOT – GlobalProtect PLAP – Autopilot Devices` (optionally
   with `Filter – GlobalProtect PLAP – Windows`). Leave production for Phase 5. **Review + create.**

### 2.3d (Alternative) Two-app model — documented, not recommended

If your environment already separates install from registration, build two apps instead of one:

- `GlobalProtect – VPN Client – Win32` — installs the MSI and writes the `PanSetup` registry
  (`Prelogon=1` + `Portal`), returning `3010`.
- `GlobalProtect – PLAP Registration – Win32` — waits for `PanGPS` readiness and runs
  `PanGPS.exe -registerplap` in SYSTEM, returning `3010`. Under this app's **Dependencies**, add
  `GlobalProtect – VPN Client – Win32` as a required dependency so registration cannot run before the
  client is installed.

Prefer the single app (§2.3a–c): splitting the work reintroduces the ordering/reboot seam where the
unzip and sequencing failures cluster.

## 2.4 Add the app as an ESP blocking app

1. Intune → **Devices > Enrollment > Windows > Enrollment Status Page** → open your ESP profile (you
   will reference it as `ESP – Autopilot – GlobalProtect PLAP Blocking`).
2. Set **Block device use until required apps are installed = Yes**.
3. Under **Select the apps that must be installed before the device can be used**, add
   `GlobalProtect – Connect Before Logon (PLAP) – Win32` (and, if you used the two-app model, both apps).
4. **Save.** Provisioning will now **wait** for Connect Before Logon to install and register — and honor
   the `3010` reboot — before the user reaches the desktop.

## 2.5 Apply the AV / IMECache exclusion

Ensure the provisioning-time antivirus policy **excludes**
`C:\Program Files (x86)\Microsoft Intune Management Extension\Content` (and the IMECache) from real-time
scanning, and that target devices have adequate free disk (R11). This is the single most effective step
against the intermittent **"unzipping" `0x87D30067`** failure.

**Gate B (Configure):** The device group(s) are **Assigned** and **owned by the Provisioning Client SP**;
the single Win32 app exists (install + `PanSetup` registry + service-readiness wait + `-registerplap` in
SYSTEM + **`3010`**), is **System** context with the **return codes mapped** and **detection** checking
GP≥5.2 + `Prelogon=1` + PLAP registered; the app is an **ESP blocking app**; the AV/IMECache exclusion is
applied; and (if cert auth) the certificate profile is assigned. Re-run `GPPLAP-Discovery.ps1` — every
expected object should now be found, and the group's SP owner should be confirmed.

---

# Phase 3 — Pilot

1. Take a **Windows 11** test device (physical or VM) registered for Autopilot and in
   `PILOT – GlobalProtect PLAP – Autopilot Devices` (confirm the group actually populated — with the SP
   owner it fills at enrollment).
2. Run a **Hybrid Azure AD Join Autopilot (user-driven)** provisioning from a network position that
   mimics production (off the corporate LAN, so Connect Before Logon is genuinely exercised).
3. Let the **Enrollment Status Page** run. It should **block** on
   `GlobalProtect – Connect Before Logon (PLAP) – Win32`, install GlobalProtect, apply the registry,
   register PLAP, take the **ESP-managed reboot** (from the `3010` return), and continue.
4. If ESP fails on the app, collect logs immediately with
   `powershell -ExecutionPolicy Bypass -File .\scripts\GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap`
   and go to `06-troubleshooting.md` before retrying.

**Gate C (Pilot):** The Windows 11 device completes Hybrid-Join Autopilot with the app *Installed* (the
detection rule for GP≥5.2 + `Prelogon=1` + PLAP registered satisfied) and the ESP no longer blocking. If
it fails on the unzip error, the missing tile, or a reboot loop, resolve per Troubleshooting before
proceeding.

---

# Phase 4 — Validate

1. On the pilot device, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\GPPLAP-Validation.ps1`
   It confirms GlobalProtect is installed and **≥ 5.2**, `PanSetup\Prelogon = 1` and the portal is set,
   the **PLAP credential provider is registered**, and reports the device join type via `dsregcmd`
   (DomainJoined + AzureAdJoined = hybrid).
2. Perform the **decisive** manual test in `05-testing.md`: **lock or sign out** to the Windows 11
   sign-in screen, confirm the **Connect Before Logon / network sign-in** tile is **visible**, use it to
   bring the GlobalProtect tunnel up **before** logon, then perform a **first interactive hybrid domain
   logon off-network** (a user with **no cached credentials** on this device) — it should succeed over
   the pre-logon tunnel.
3. Collect a full evidence bundle for the record:
   `powershell -ExecutionPolicy Bypass -File .\scripts\GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap`
4. Run the fleet report to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\GPPLAP-Report.ps1`

**Gate D (Validate):** On the pilot Windows 11 device: the app installs, GP is **≥ 5.2**, `Prelogon=1`
with the portal set, **PLAP is registered**, the **Connect Before Logon tile is visible** at the sign-in
screen, the **pre-logon tunnel establishes**, the **DC is reachable**, and a **first-time hybrid domain
logon off-network succeeds** over the tunnel. All Testing gates are green. Only then proceed.

---

# Phase 5 — Expand

1. **Add** `PROD – GlobalProtect PLAP – Autopilot Devices` (Assigned, SP-owned) to the **Required**
   assignment of `GlobalProtect – Connect Before Logon (PLAP) – Win32` (and the certificate profile if
   used). Keep the pilot group assigned. Ensure the production group is also added to the **ESP blocking
   app** scope as needed.
2. Expand in waves if the fleet is large (add production sub-groups over several days) and watch the
   report and Autopilot deployment success between waves.
3. Monitor with `GPPLAP-Report.ps1` for coverage and with Intune **Apps > Monitor** / **Devices >
   Enrollment > Autopilot deployments** for install and provisioning success.
4. Keep `GPPLAP-Collect-Logs.ps1` on hand for any straggler — it is the fastest path from a failed
   provisioning to a diagnosed cause.

**Rollback (any phase):** Remove/exclude the target group from the app assignment and from the ESP
blocking-app list; to remove Connect Before Logon, flip the Win32 app assignment to **Uninstall** (the
uninstall command can run `PanGPS.exe -unregisterplap` first) and remove any certificate profile.

**Gate E (Expand):** Fleet coverage meets your target (e.g. ≥ 95% of assigned devices with the app
*Installed* and Connect Before Logon registered, provisioning succeeding); remaining failures are
triaged. Deployment is complete.


---


# Testing & Validation — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

Run these tests on the **pilot Windows 11 device** before expanding, and spot-check during expansion.
Each test has an explicit **pass/fail gate**. A phase is only "done" when its gate is **PASS**. Object
names match the Implementation guide verbatim.

> **Scope note:** these tests validate that Intune **delivered and registered Connect Before Logon during
> Autopilot** and that a device **can bring the tunnel up at the sign-in screen and complete a hybrid
> domain logon over it**. Deep GlobalProtect **portal / gateway** diagnostics (why a specific portal
> rejects an auth method, gateway routing) are Palo Alto-side and deferred to Palo Alto docs.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Tenant/object readiness + group SP owner | Discovery script | Objects found & assigned; group Assigned + SP owner |
| T2 | Autopilot Hybrid-Join provisioning (Win11) | Autopilot + ESP | Provisioning completes; ESP blocks then releases on the app |
| T3 | Win32 app installed + CBL enabled + registered | Intune monitor + device | App *Installed*; GP≥5.2, `Prelogon=1`, PLAP registered |
| T4 | (If cert auth) device certificate applied | Intune monitor + device | Cert *Succeeded*, machine cert in `LocalMachine\My` |
| T5 | Connect Before Logon tile visible at sign-in | Pilot device | CBL / network sign-in tile appears at the lock screen |
| T6 | Pre-logon tunnel + first hybrid logon off-network | Pilot device | Tunnel up before logon; first-time domain logon succeeds |
| T7 | On-device validation script | Pilot device | Script reports PASS |
| T8 | Log-capture runbook | Pilot device | Evidence ZIP produced (IME + Autopilot + GP logs) |
| T9 | Fleet coverage report | Report script | Coverage ≥ target |
| T10 | Rollback / uninstall | Test device | App/PLAP/cert removed; CBL tile gone |

---

## T1 — Tenant and object readiness (including the group's SP owner)
**Steps:** Run `GPPLAP-Discovery.ps1`. Review the readiness table: the app
`GlobalProtect – Connect Before Logon (PLAP) – Win32` (or the two-app alternative), the optional cert
profile, the device groups `PILOT – / PROD – GlobalProtect PLAP – Autopilot Devices`, whether the app is
referenced as an **ESP blocking app**, and — critically — whether the **Assigned** group has the Intune
Provisioning Client SP (`f1346770-5b25-470b-88bd-d5744ab7952c`) as an **owner**.
**PASS:** Every expected object is present and assigned; the pilot group is **Assigned** and the SP owner
is present.
**FAIL:** Any object missing/unassigned, or the group missing its SP owner → fix in Requirements/
Implementation (R9 / §2.0) before piloting.

## T2 — Autopilot Hybrid-Join provisioning on Windows 11
**Steps:** Provision a **Windows 11** Autopilot device (user-driven, Hybrid Azure AD Join) from an
off-LAN network position. Watch the **Enrollment Status Page**.
**PASS:** The ESP **blocks** on `GlobalProtect – Connect Before Logon (PLAP) – Win32`, the app installs,
the ESP-managed reboot (from the `3010` return) occurs, and provisioning **completes** to the desktop.
**FAIL:** ESP hangs on the app, an "unzipping" error, or a reboot loop → run `GPPLAP-Collect-Logs.ps1`
and see Troubleshooting §"Unzipping" / 0x87D30067, §Autopilot ESP hangs on the app, and §Install fails
after reboot.

## T3 — Win32 app installed, Connect Before Logon enabled and registered
**Steps:** Intune → **Apps > Monitor > App install status** for
`GlobalProtect – Connect Before Logon (PLAP) – Win32`. On the device, confirm GlobalProtect is present
and **≥ 5.2**, `HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\Prelogon` = `1` with the portal
set, and a PLAP credential provider is registered under
`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`.
**PASS:** Status *Installed* and all three conditions (GP≥5.2, `Prelogon=1`, PLAP registered) are true.
**FAIL:** *Failed*/*Pending*, or installed but CBL not registered → see Troubleshooting §PLAP tile not
visible and §Install failures.

## T4 — Device certificate applied (cert-auth deployments only)
**Steps:** Confirm `GlobalProtect – PLAP – Device Cert (SCEP) – Windows` shows *Succeeded* in Intune and
a **machine** certificate is present in `LocalMachine\My` (`certlm.msc`), chaining to the trusted root.
**PASS:** A valid, unexpired **device** certificate is present and chains to a CA the portal trusts.
**FAIL:** *Error*/no cert / wrong store (user not machine) → see Troubleshooting §Tunnel up but hybrid
first-logon fails (cert/trust) and confirm portal trust with your Palo Alto admin.

## T5 — Connect Before Logon tile shows at the sign-in screen
**Steps:** **Lock** the Windows 11 device (or sign out) to reach the sign-in screen. Look for the
**Connect Before Logon / network sign-in** tile (a credential-provider option that launches the
GlobalProtect pre-logon window). A reboot after install may be required for it to appear.
**PASS:** The Connect Before Logon / network sign-in tile is visible at the sign-in screen.
**FAIL:** No tile → see Troubleshooting §PLAP tile not visible (GP<5.2, `Prelogon` not set,
`-registerplap` not run or not in SYSTEM, or registration ran before the GP service was ready).

## T6 — Pre-logon tunnel + first hybrid logon off-network (the decisive test)
**Steps:** From the sign-in screen, use the **Connect Before Logon** tile to establish the GlobalProtect
tunnel (portal FQDN from R7) **before** any user signs in. With the tunnel up, perform a **first
interactive logon of a hybrid domain user who has never signed in to this device** (no cached
credentials), from **off the corporate network**.
**PASS:** The tunnel establishes **before** logon; the domain controller is reachable; the first-time
hybrid domain logon **completes over the tunnel**.
**FAIL:** Tunnel won't establish, or logon fails with the tunnel up → see Troubleshooting §Tunnel up but
hybrid first-logon fails (DC/ODJ/time skew) and, for a cached-credential false pass, re-test with a truly
new user.

## T7 — On-device validation script
**Steps:** On the pilot device run `GPPLAP-Validation.ps1`.
**PASS:** Script reports GlobalProtect installed **and ≥ 5.2**, `Prelogon=1` with portal set, **and PLAP
registered** → overall **PASS** (and the join type shows DomainJoined + AzureAdJoined = hybrid).
**FAIL:** Script reports a missing component → address per its message before counting the device.

## T8 — Log-capture runbook (the Friday test-window tool)
**Steps:** On the pilot device run
`GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap`. Confirm it produces a timestamped ZIP containing the
IME logs (`IntuneManagementExtension.log`, `AgentExecutor.log`, `AppWorkload.log`), the
`MdmDiagnosticsTool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -zip` output, the GlobalProtect
`PanGPS`/`PanGPA` logs, and the relevant Event Viewer channels.
**PASS:** A single evidence ZIP is produced containing the IME, Autopilot/MDM, and GlobalProtect logs.
**FAIL:** Missing sections → re-run elevated; confirm the source paths exist on this device.

## T9 — Fleet coverage report
**Steps:** Run `GPPLAP-Report.ps1`; review app install coverage (and cert coverage if used) across the
Autopilot device groups.
**PASS (pilot):** 100% of pilot devices *Installed* with Connect Before Logon registered.
**PASS (expand):** Coverage ≥ your target (e.g. ≥ 95%) with remaining failures triaged.
**FAIL:** Coverage below target → remediate (T2/T3 failures) before widening further.

## T10 — Rollback / uninstall verification
**Steps:** On a disposable test device, exclude it from the target group (or flip the Win32 app to
**Uninstall**). Sync and reboot.
**PASS:** GlobalProtect and the PLAP registration are removed (the Connect Before Logon tile disappears),
the certificate (if used) is removed, and the device returns to its pre-deployment state.
**FAIL:** Residual app / CBL tile / cert → confirm the Uninstall command (incl. `-unregisterplap`) and
the unassignment took effect.

---

## Overall exit criteria (before Expand)
All of T1–T8 **PASS** on the pilot Windows 11 device (including the decisive pre-logon tunnel + first
hybrid logon test T6), T9 shows 100% pilot coverage, and T10 confirms a clean rollback. Record results
against each gate; only then proceed to Phase 5 (Expand).


---


# Troubleshooting — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common. On **any** failed provisioning,
run `GPPLAP-Collect-Logs.ps1 -OutFolder C:\Temp\gpplap` **before** wiping the device — a wipe destroys the
evidence you need.

> **Vendor boundary:** problems on the **GlobalProtect portal / gateway** (portal rejects the auth
> method, gateway routing, head-end CA trust) are **deferred to Palo Alto Networks' official
> documentation and your Palo Alto admin**. This guide resolves the **Intune / Autopilot / Windows
> delivery** side and tells you when a failure points at the Palo Alto side.

---

## §"Unzipping" / 0x87D30067 — the Win32 app fails to unzip during Autopilot

**Symptom:** `GlobalProtect – Connect Before Logon (PLAP) – Win32` fails during the Enrollment Status
Page with an **"unzipping"** error; the IME log shows **`0x87D30067`**. The IME downloaded the
`.intunewin` but could not extract it into its content/cache path.

1. **Antivirus is locking or scanning the IMECache during extraction.** This is the most common cause.
   Microsoft Defender or a third-party AV holds a lock on
   `C:\Program Files (x86)\Microsoft Intune Management Extension\Content` (the IMECache) while the IME
   tries to unzip. **Add that path (and the IMECache) to the AV exclusion list applied during
   provisioning** (R11) and re-provision.
2. **Low disk space.** Extraction needs room for the unzipped payload. Confirm the device has adequate
   free disk; clear space and retry.
3. **Corrupt or improperly re-wrapped `.intunewin`.** A package wrapped from an **already-wrapped**
   payload (nesting), or wrapped with a stale tool, extracts inconsistently. **Re-wrap cleanly** with the
   **current Microsoft Win32 Content Prep Tool** (R12) from a minimal source folder (the MSI + the
   script) — never nest an already-wrapped file.
4. **Path / permission tampering.** A hardened image or a GPO that alters permissions on the IME content
   path can block extraction. Confirm the IME content path exists with default permissions.
5. **Verify the source folder.** Confirm the MSI and the install script are actually present in the
   source folder you wrapped, and the install command matches the script filename.

Confirm the fix: `GPPLAP-Collect-Logs.ps1` flags `0x87D30067` in the IME log; after the AV exclusion and a
clean re-wrap, the app installs and the flag is gone.

## §PLAP tile not visible — no Connect Before Logon / network sign-in at the sign-in screen

**Symptom:** Provisioning finishes but the **Connect Before Logon / network sign-in** tile never appears
at the Windows 11 sign-in screen, so there is no way to bring the tunnel up before logon.

1. **GlobalProtect app is below 5.2.** Connect Before Logon does not exist before app **5.2**. Confirm the
   installed version with `GPPLAP-Validation.ps1`; if it is below 5.2, package the correct MSI (R6) and
   redeploy.
2. **`Prelogon` registry not set.** The PLAP provider stays dormant unless
   `HKLM:\SOFTWARE\Palo Alto Networks\GlobalProtect\PanSetup\Prelogon` = `1` (with a `Portal` value under
   the same key). Confirm with `GPPLAP-Validation.ps1`; if missing, fix the install script to write the
   `PanSetup` registry **before** registration and redeploy.
3. **`PanGPS.exe -registerplap` was never run, or not in the SYSTEM context.** Registration is what adds
   the tile. It must run as **SYSTEM** (the Win32 app runs as System). If the app ran as user, or the
   registration step was skipped, the provider is not registered — confirm the credential-provider
   registration under `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\Credential Providers`
   and set the app's **Install behavior = System**, then redeploy.
4. **Registration ran before the GlobalProtect service (PanGPS) was ready.** If `-registerplap` executed
   before `PanGPS` was *Running*, registration silently no-ops. Add the **service-readiness wait** to the
   install script (poll `Get-Service PanGPS` until *Running*, bounded) so registration always runs after
   the service exists; redeploy.
5. **No reboot after install.** The tile may only surface after a reboot. Ensure the app **returns 3010**
   so the ESP takes the reboot (see the next section) and re-check at the sign-in screen.

## §Install fails after reboot / IME state lost — a reboot loop or lost app state

**Symptom:** The app "installs" then the device reboots and the install is lost, retried, or the ESP
loops; the IME log shows the agent restarting mid-install.

1. **The install script called a forced `Restart-Computer`.** This is the root cause to eliminate. A
   scripted reboot during the ESP interrupts the Intune Management Extension and loses app state. **Remove
   any `Restart-Computer` from the script** and instead **`exit 3010`** so **Intune/ESP owns the reboot**.
2. **Return codes not mapped on the app.** If the app does not know `3010` means "soft reboot", it treats
   the reboot request as a failure. On the Win32 app, map return codes: `0`/`1707` success, **`3010` soft
   reboot**, `1618` retry.
3. **Missing `Start-Process … -Wait`.** Without `-Wait`, the MSI (or `-registerplap`) returns immediately
   and the app reports complete before the work finishes — the reboot then lands mid-install. Ensure the
   MSI and the registration are launched with `-Wait`.
4. **Device restart behavior override.** Set the app's **Device restart behavior** to *Determine behavior
   based on return codes* so the `3010` mapping actually drives the reboot.

## §Autopilot ESP hangs on the app — provisioning blocks and never releases

**Symptom:** The Enrollment Status Page sits on `GlobalProtect – Connect Before Logon (PLAP) – Win32` and
never completes.

1. **The app genuinely failed (unzip / install error).** Check the IME log via `GPPLAP-Collect-Logs.ps1`;
   resolve per §"Unzipping" / 0x87D30067 or §Install fails after reboot.
2. **Detection rule never becomes true.** If detection checks something the install never writes, the app
   never reports *Installed* and the ESP blocks forever. Detection must check **GP≥5.2 AND `Prelogon=1`
   AND the PLAP credential-provider registration** — and each of those must actually be produced by the
   install. Fix the detection rule to match what the script writes.
3. **The app returns an unmapped non-zero code.** If the script exits with a code the app treats as
   failure (and it is not `3010`/`1618`), the ESP fails. Confirm the script's exit codes and the app's
   return-code mapping.
4. **App not correctly on the ESP blocking list.** Confirm the app is listed under the ESP's blocking apps
   (`ESP – Autopilot – GlobalProtect PLAP Blocking`) and that the device's group is in the ESP's scope.

## §Enrollment-time device group empty — nothing deploys during Autopilot

**Symptom:** The device provisions but the GlobalProtect PLAP app (and any profile) never targets it; the
Autopilot **device group is empty at enrollment** even though you added devices.

1. **The group is missing the Provisioning Client SP owner.** Enrollment-time device grouping only works
   when the **Assigned** group is **owned** by the Intune Provisioning Client service principal
   (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**). Add the SP as an **owner**: Entra → **Groups >
   <group> > Owners > Add owners** → search by **AppId** (the display name, often *Intune Autopilot
   ConfidentialClient*, varies). `GPPLAP-Discovery.ps1` flags a missing SP owner;
   `GPPLAP-Set-ScopeTargeting.ps1` sets it.
2. **The group is Dynamic, not Assigned.** Enrollment-time grouping needs an **Assigned** group. If the
   group was created as Dynamic, recreate it as **Assigned** and re-add devices + the SP owner.
3. **The SP is absent from the tenant.** If the Provisioning Client SP cannot be found, provision it by
   opening the Intune portal **once as a Global Administrator**, then add it as owner.

## §Works on Windows 10 but not Windows 11 (or vice-versa)

**Symptom:** The exact same package that behaved on the Windows 10 test machine behaves differently on the
Windows 11 production target (tile missing, registration timing, or install result differs).

1. **You validated on the wrong OS.** Early testing here was on Windows 10; **production is Windows 11**.
   Do not assume parity — **re-test the full flow on Windows 11** (pilot device, `GPPLAP-Validation.ps1`,
   and the sign-in-tile check). Make Windows 11 the pilot OS.
2. **OS-version requirement mismatch on the app.** Confirm the app's **Requirements** minimum OS matches
   the Windows 11 target and Palo Alto's support matrix, so the app is *Applicable* on Windows 11.
3. **Service-readiness timing differs across OS builds.** If registration timing is marginal, the
   difference surfaces as "works on one OS, not the other." Ensure the **service-readiness wait** is
   present (not a fixed sleep) so registration reliably follows `PanGPS` becoming *Running* on either OS.
4. **If a Windows 10 estate remains,** treat it as a **separate target** and re-validate there rather than
   shipping the Windows-11-validated package blindly.

## §Tunnel up but hybrid first-logon fails — Connect Before Logon connects yet Windows sign-in doesn't work

**Symptom:** The Connect Before Logon tunnel establishes at the sign-in screen, but the subsequent
first-time **hybrid domain** logon fails ("no logon servers available", first-time logon rejected, or
password change won't complete).

1. **Domain controller not reachable over the tunnel.** The tunnel is up but the DC isn't routed. Confirm
   with your Palo Alto/network team that the **DC subnets are inside the tunnel** and reachable from the
   VPN pool. Split-tunnel routing that excludes DC subnets is a common cause (Palo Alto-side).
2. **On-prem Domain Join (ODJ) not completing.** Hybrid Azure AD Join Autopilot completes domain join via
   the **Intune Connector for Active Directory**. Confirm the connector is **Active** (R4) and the
   **Domain Join** profile targets the right domain/OU; a device that can reach the DC but has no ODJ blob
   won't finish join.
3. **DNS not resolving internal names pre-logon.** The pre-logon tunnel must hand the client internal DNS
   so the DC name resolves. Confirm DNS pushed by the portal/gateway (Palo Alto-side) is applied before
   logon.
4. **Time skew.** A large clock difference between the device and the DC breaks Kerberos/domain logon.
   Confirm the device time is correct (Autopilot devices off-network can drift before first sync).
5. **Certificate rejected by the portal (cert auth).** If Connect Before Logon uses a certificate and the
   tunnel authenticates but access is denied, the **portal must trust the issuing CA** — a **Palo
   Alto-side** trust decision, deferred to Palo Alto docs. Provide your Palo Alto admin the issuing CA
   chain; confirm the device cert is a **machine** cert in `LocalMachine\My` (T4).
6. **Cached-credential test masks the issue.** If you tested with a user who has signed in before, Windows
   may use cached credentials rather than the tunnel. **Re-test with a first-time / no-cached-credential
   logon** to truly exercise pre-logon reachability.

## §Certificate issues — device certificate missing, wrong store, or rejected (cert-auth deployments)

**Symptom:** `GlobalProtect – PLAP – Device Cert (SCEP) – Windows` fails, or the pre-logon tunnel can't
authenticate.

1. **SCEP profile not applied yet.** Confirm the profile shows *Succeeded* in Intune and the device has
   synced. `GPPLAP-Discovery.ps1` shows whether it is assigned to the pilot device group.
2. **Certificate issued to the user store, not the machine store.** Connect Before Logon needs a **Device
   (machine)** certificate in `LocalMachine\My` (there is no user context at the sign-in screen). If
   **Certificate type** was *User*, set it to **Device** and redeploy.
3. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Confirm the trusted-root profile is *Succeeded*, then the SCEP profile.
4. **Head-end doesn't trust the issuing CA (Palo Alto side).** If the cert is issued correctly but the
   portal still rejects it, the **portal/gateway must trust the issuing CA** — Palo Alto-side, deferred to
   Palo Alto docs.

## §Reporting / script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph -Scope
   CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts need only
   `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** — confirm
   the object is named to convention verbatim (including the en-dash `–` and spacing). Rename any drifted
   object to the convention.
3. **Discovery flags the group's SP owner as missing but you added it.** Confirm you added the SP by
   **AppId** `f1346770-5b25-470b-88bd-d5744ab7952c` (the display name varies) and that the group is
   **Assigned**, not Dynamic.
4. **Validation says PLAP not registered but the tile shows.** The script checks the credential-provider
   registration and the GP service/DLL; if Palo Alto changed the program path/DLL name for your version,
   note the actual path (per Palo Alto docs) — the **logon-screen tile is the ground truth**.
5. **Log collector missing sections.** Run `GPPLAP-Collect-Logs.ps1` **elevated** so the IME logs, MDM
   diagnostics, and Event channels can be read; confirm the source paths exist on this device.

---

If a failure persists after the Intune / Autopilot / Windows side is confirmed healthy (validation PASS,
app *Installed*, `Prelogon=1`, PLAP registered, the Connect Before Logon tile showing, and the tunnel
establishing) and the **hybrid logon still fails or the portal still rejects the connection**, treat it as
a **GlobalProtect portal / gateway issue** and continue with **Palo Alto Networks' official documentation**
and your Palo Alto admin.


---


# Best Practices — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

Field-proven practices for the deploy-and-diagnose model. These make the Autopilot build predictable,
reversible, and easy to troubleshoot when the enrollment sequence misbehaves.

## Naming and structure
- **Name every object to the convention and reuse it verbatim.** The app, the cert profile, the device
  groups, the ESP reference, and the filter all follow the Implementation table (`GlobalProtect –
  Connect Before Logon (PLAP) – Win32`, `PILOT – GlobalProtect PLAP – Autopilot Devices`, …). The
  discovery, validation, log-capture, and report scripts find objects **by these names** — drift breaks
  automation and reporting (including the en-dash `–` and spacing).
- **Prefer the single Win32 app.** Keep install, the `PanSetup` registry, the service-readiness wait, and
  `PanGPS.exe -registerplap` in **one** app. Splitting them into a two-app model reintroduces the
  ordering/reboot seam where the unzip and sequencing failures cluster — only split when your environment
  already does.
- **Keep pilot and production device groups separate and both assigned.**
  `PILOT – GlobalProtect PLAP – Autopilot Devices` stays assigned after expansion so you retain a fast
  Windows 11 test cohort.

## Autopilot enrollment-time targeting
- **Use an Assigned group owned by the Provisioning Client SP.** Enrollment-time device grouping only
  works when the group is **Assigned** (not Dynamic) and the Intune Provisioning Client service principal
  (**AppId `f1346770-5b25-470b-88bd-d5744ab7952c`**) is an **owner**. Without the owner the group is empty
  at enrollment and nothing deploys — verify the owner in discovery, not just the group.
- **Make the app an ESP blocking app.** So provisioning **waits** for Connect Before Logon to install and
  register before the user reaches the desktop, and honors the app's `3010` reboot at the right moment.

## Reboot sequencing (the rule that removes the biggest failure)
- **Never call `Restart-Computer` from the install script during the ESP.** It interrupts the Intune
  Management Extension and causes install failures / lost state. **Return exit code `3010`** and let
  **Intune/ESP** own the reboot.
- **Map the return codes on the app:** `0`/`1707` = success, `3010` = soft reboot, `1618` = retry.
- **Always `Start-Process … -Wait`** for the MSI (and for `-registerplap`) so the app never reports
  complete before the installer/registration actually finishes.

## Avoiding the "unzipping" 0x87D30067 failure
- **Exclude the IME content/IMECache path from AV during provisioning**
  (`C:\Program Files (x86)\Microsoft Intune Management Extension\Content` and the IMECache). AV locking
  or scanning the cache during extraction is the most common cause.
- **Re-wrap cleanly with the current Content Prep Tool.** Never nest an already-wrapped payload; keep the
  source folder minimal (MSI + script). Keep enough free disk on target devices.

## Connect Before Logon correctness
- **Require GlobalProtect ≥ 5.2.** Connect Before Logon does not exist below 5.2 — enforce it in the
  app's detection rule, not just the requirements.
- **Set the `PanSetup` registry before registration and before the sign-in screen.** `Prelogon = 1` and
  the default `Portal` must exist before `-registerplap` and before the lock screen is reached.
- **Register PLAP as SYSTEM, after the service is ready.** Run `PanGPS.exe -registerplap` in the System
  context (the Win32 app runs as System), and only after `PanGPS` is *Running* — add a bounded readiness
  wait rather than a fixed sleep.
- **Detect all three conditions.** Detection should check GP≥5.2 **and** `Prelogon=1` **and** the PLAP
  credential-provider registration — detecting only the MSI hides a device where the tile will never
  appear.

## Windows 11 vs Windows 10
- **Pilot and validate on the production OS (Windows 11).** "Works on Win10, not Win11" (or the reverse)
  is a real early-signal in this scenario — never assume parity. Re-test the full flow on Windows 11 and,
  if a Windows 10 estate remains, test it as a separate target.

## Diagnose fast
- **Keep `GPPLAP-Collect-Logs.ps1` in the test-window kit.** On any failed provisioning, capture the IME
  logs (`IntuneManagementExtension.log`, `AgentExecutor.log`, `AppWorkload.log`), the
  `MdmDiagnosticsTool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -zip` bundle, and the
  GlobalProtect `PanGPS`/`PanGPA` logs **before** wiping and retrying — a wipe destroys the evidence.
- **Read the IME log for the app exit code.** The `3010`/`1618`/error the app returned, and the unzip
  `0x87D30067` if present, are in `IntuneManagementExtension.log` / `AppWorkload.log`.

## Certificates (if cert auth)
- **Use a Device (machine) certificate.** There is no user context at the sign-in screen; issue the cert
  to `LocalMachine\My` and deploy the trusted root **first**, then the SCEP profile.
- **Ensure the portal trusts the issuing CA** (Palo Alto-side trust config per Palo Alto docs) and set a
  renewal threshold comfortably before expiry so Connect Before Logon never silently loses auth.

## Change control and rollback
- **Keep a one-click rollback ready:** exclude the group, remove the app from the ESP blocking list, or
  flip the Win32 app to **Uninstall** (running `PanGPS.exe -unregisterplap` first). Test the rollback
  (Testing T10) before you ever need it.
- **Deploy inside a change window** and announce it — this changes the provisioning and sign-in
  experience for real users.
- **Version your inputs.** Track which GlobalProtect MSI version, portal FQDN, and auth method a given
  rollout used, so you can reproduce or revert precisely.

## Security hygiene
- **Never embed VPN credentials.** Use the portal's certificate or SAML/credential prompt at the Connect
  Before Logon window; do not store secrets in the registry or the package.
- **Least-privilege admin.** Use Intune Administrator + Groups Administrator for the operator; a Global
  Administrator may be needed once to provision/own the first-party SP on the group.
- **Keep the client patched.** Update the app package when Palo Alto releases fixes; pilot the new version
  on Windows 11 before fleet-wide expansion, same as any change.


---


# Deliverables Summary — GlobalProtect Connect Before Logon (PLAP) for Hybrid Autopilot via Intune

This solution is a complete, self-guided package to deploy **GlobalProtect Connect Before Logon (PLAP)**
during a **Hybrid Azure AD Join Windows Autopilot** provisioning using Microsoft Intune — pilot-first,
rollback-ready, and built to be **diagnosed** as well as deployed. Below is everything included.

## Documentation set (source/)

| Document | What it gives you |
|---|---|
| `01-solution-overview.md` | The scenario (Always On → user-initiated VPN after a security incident; Hybrid Autopilot needs pre-logon DC reachability), what Connect Before Logon (CBL/PLAP) is, the single-Win32-app delivery model (install + `PanSetup` registry + service-readiness wait + `PanGPS.exe -registerplap` + return `3010`), the Autopilot/ESP fit, and the Assess→Configure→Pilot→Validate→Expand model. |
| `02-requirements.md` | Every prerequisite with **Description / Why / Verify / Implement-if-missing** — Intune licensing + Autopilot, the Hybrid-Join profile, Domain Join + ODJ connector, ESP, the GlobalProtect 5.2+ MSI + portal FQDN + auth method, optional PKI, the **Assigned** device group **owned by the Provisioning Client SP**, reboot-sequencing design, and the AV/IMECache exclusion. Includes the Government note. |
| `03-implementation.md` | Exact ordered build with **Gates A–E**: create the Assigned + SP-owned device group, build the single Win32 app (install + registry + readiness wait + `-registerplap` in SYSTEM + `3010`), set System context, detection (GP≥5.2 + `Prelogon=1` + PLAP registered) and return-code mapping, add the app as an **ESP blocking app**, apply the AV/IMECache exclusion, then pilot on Windows 11, validate, and expand. Documents the two-app alternative. |
| `05-testing.md` | The validation test matrix (T1–T10) with explicit **PASS/FAIL** gates, including the decisive pre-logon tunnel + first hybrid domain logon test and the log-capture runbook. |
| `06-troubleshooting.md` | The failure-mode matrix: the **"unzipping" / 0x87D30067** error, the **PLAP tile not visible**, **install fails after reboot / IME state lost**, **ESP hangs on the app**, **Win10-vs-Win11** mismatch, **tunnel up but hybrid first-logon fails**, and **enrollment-time group empty**. |
| `07-best-practices.md` | Field-proven practices for naming, enrollment-time targeting, reboot sequencing, avoiding the unzip failure, Connect Before Logon correctness, Windows 11 testing, fast diagnosis, certificates, and safe operation. |
| `executive-summary.md` | One-page business-outcome summary for stakeholders. |
| `global-requirements-network.md` | Category-level Network prerequisites (shared across Network solutions). |

## PowerShell scripts (scripts/)

Discovery/report/scope-targeting use the **Microsoft Graph PowerShell SDK**; validation and log-capture
run **locally** on the device and need no Graph. Discovery/validation/report/log-capture are **read-only
/ collection-only**; scope-targeting **defaults to `-WhatIf` (preview)** and changes nothing until you
re-run with `-WhatIf:$false`. Each script's header documents its exact purpose, run command, and required
Graph scopes.

| Script | Purpose | Mode |
|---|---|---|
| `GPPLAP-Discovery.ps1` | Readiness sweep across Entra + Intune — finds the Win32 app (and the two-app alternative names), the optional cert profile, the pilot/prod Autopilot **device** groups, flags whether the **Assigned** group has the Provisioning Client SP (`f1346770-5b25-470b-88bd-d5744ab7952c`) as **owner**, and whether the app is referenced as an **ESP blocking app**. | Read-only |
| `GPPLAP-Validation.ps1` | Confirms **on this Windows 11 device** that GlobalProtect is installed and **≥ 5.2**, `PanSetup\Prelogon = 1` with the portal set, the **PLAP credential provider is registered**, and reports join type via `dsregcmd`. Prints an overall PASS/FAIL. | Read-only (local) |
| `GPPLAP-Collect-Logs.ps1` | The test-window diagnostic collector — gathers the IME logs, runs `MdmDiagnosticsTool.exe -area Autopilot;DeviceEnrollment;DeviceProvisioning -zip`, collects GlobalProtect `PanGPS`/`PanGPA` logs and Event Viewer channels, and ZIPs everything to a timestamped folder. | Collection-only (local) |
| `GPPLAP-Report.ps1` | Fleet coverage report — per-app install counts (installed/failed/pending) and the optional cert profile across the Autopilot device groups, with coverage percentages. | Read-only |
| `GPPLAP-Set-ScopeTargeting.ps1` | Creates/populates the pilot (and optional production) Autopilot **device** groups as **Assigned** security groups, adds devices by name, **and sets the Provisioning Client SP as an owner** (required for enrollment-time targeting). | Write, **default `-WhatIf`** |

## The consistent object naming convention

Every artifact is named to a convention and reused verbatim across docs, tests, troubleshooting, and
scripts (so the scripts find objects deterministically):

- Device groups: `PILOT – GlobalProtect PLAP – Autopilot Devices`, `PROD – GlobalProtect PLAP – Autopilot Devices`
- Win32 app (recommended): `GlobalProtect – Connect Before Logon (PLAP) – Win32`
- Two-app alternative: `GlobalProtect – VPN Client – Win32` + `GlobalProtect – PLAP Registration – Win32`
- Optional certificate profile: `GlobalProtect – PLAP – Device Cert (SCEP) – Windows`
- ESP blocking-app reference: `ESP – Autopilot – GlobalProtect PLAP Blocking`

## Vendor boundary (what is deferred)

The **GlobalProtect portal / gateway configuration, the authentication method the portal enforces, and
the GlobalProtect app internals are deferred to Palo Alto Networks' official documentation.** This
solution authors the **Intune, Autopilot, Entra, and Windows** side at full click-by-click detail and
consumes the Palo Alto-supplied **MSI (5.2+)**, **portal FQDN**, and **auth method** as inputs.
