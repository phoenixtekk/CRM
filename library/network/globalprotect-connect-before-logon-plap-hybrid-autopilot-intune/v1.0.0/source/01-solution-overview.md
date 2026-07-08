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
