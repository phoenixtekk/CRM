# Implementation — Pre-Logon VPN Connectivity with Cisco Secure Client Start Before Logon (SBL/PLAP) via Microsoft Intune

This is the ordered, click-by-click build. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Do **not** skip the pilot. Use the **exact object
names** shown — later steps, tests, troubleshooting, and scripts reference them verbatim.

> **Vendor boundary:** the Cisco head-end (ASA / FTD / ISE), the Cisco Secure Client console, and the
> **VPN Profile Editor** XML authoring (including where `<UseStartBeforeLogon>true</UseStartBeforeLogon>`
> is set) are **deferred to Cisco's official documentation**. This guide covers the Intune, Entra, and
> Windows side at full detail and *consumes* the Cisco-supplied installer modules, SBL-enabled XML
> profile, gateway FQDN, tunnel-group, and auth method as inputs.

> **Government (GCC High / DoD):** substitute the sovereign portals — `https://intune.microsoft.us`,
> `https://entra.microsoft.us`, `https://login.microsoftonline.us` — and **verify each step for GCC
> High**. Menu names below are the commercial names.

## Object naming convention (use verbatim)

| Object | Name |
|---|---|
| Pilot group (users) | `PILOT – Pre-Logon VPN (SBL) Users` |
| Production group (users) | `PROD – Pre-Logon VPN (SBL) Users` |
| Win32 app (Core + SBL modules) | `Cisco Secure Client – Pre-Logon (SBL) – Win32` |
| Windows VPN profile | `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows` |
| Trusted root CA profile | `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows` |
| SCEP device certificate profile | `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows` |
| Assignment filter (optional) | `Filter – Pre-Logon VPN – Windows` |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Gather the Cisco inputs (from your Cisco/network team, per Cisco docs):
   - **Gateway FQDN** (e.g. `vpn.your-company.com`)
   - **Tunnel-group / connection-profile name** (must accept **certificate** auth)
   - **Authentication method** — **device certificate** for silent pre-logon
   - **Tunnel mode** (split vs full)
   - The **Windows Core VPN module** and the **Start Before Logon module** installers
   - The **SBL-enabled VPN client profile XML** (contains `<UseStartBeforeLogon>true</UseStartBeforeLogon>`)
3. Confirm the **PKI path** for a **device** certificate (R8–R10): SCEP/PKCS infrastructure healthy,
   the trusted root/intermediate CA cert in hand, and the issuing CA trusted by the Cisco head-end.
4. Decide the pilot audience (3–10 Windows users).
5. Run the discovery script to baseline readiness:
   `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Discovery.ps1`
   Review its readiness table before building anything.

**Gate A (Assess):** All requirements pass, all Cisco inputs recorded (including the **SBL-enabled**
XML), the PKI path for a **device** certificate is confirmed, and discovery shows the tenant is ready.
If not, stop and remediate.

---

# Phase 2 — Configure

## 2.0 Create the target groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Set-ScopeTargeting.ps1`
  (creates `PILOT – Pre-Logon VPN (SBL) Users` and `PROD – Pre-Logon VPN (SBL) Users` and adds the
  members you supply).
- **Portal:** Entra admin center → **Groups > New group > Security** → name
  `PILOT – Pre-Logon VPN (SBL) Users` → add pilot members → **Create**. Repeat for
  `PROD – Pre-Logon VPN (SBL) Users`.

## 2.1 (Optional) Create the assignment filter

If a single group spans device types, create a Windows filter to keep this build on Windows only.

1. Intune → **Tenant administration > Filters > Create**.
2. Name it exactly `Filter – Pre-Logon VPN – Windows`; **Platform: Windows 10 and later**.
3. Set a rule (e.g. `(device.operatingSystem -eq "Windows")`); **Review + create**. Attach it to the
   app/profile assignments in the steps below where you want to scope by OS.

## 2.2 Certificate lifecycle for pre-logon VPN (device certificate via SCEP/PKCS)

**Do this before packaging the client.** Pre-logon authenticates with a **Device (machine)
certificate** because at the logon screen there is **no user context** — a user certificate is not
available. Deploy the trust chain first, then the device certificate, so the certificate exists in
`LocalMachine\My` by the time the VPN needs it.

### 2.2a Deploy the Trusted Root CA profile (trust the issuing CA first)

1. Intune → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*. **Profile type:** *Templates* → **Trusted certificate**.
3. Name it exactly `Cisco Secure Client – Pre-Logon – Trusted Root CA – Windows`.
4. Upload your **root (and intermediate, if separate) CA** `.cer` file; set the **Destination store**
   to **Computer certificate store – Root** (root) / **Intermediate** (intermediate) as appropriate.
5. **Assignments: Required** → `PILOT – Pre-Logon VPN (SBL) Users` (optionally with
   `Filter – Pre-Logon VPN – Windows`). **Review + create.**

### 2.2b Deploy the SCEP device-certificate profile

1. Intune → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*. **Profile type:** *Templates* → **SCEP certificate** (use
   **PKCS certificate** instead if your PKI uses PKCS — the field intent is the same).
3. Name it exactly `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`.
4. Set the fields:
   - **Certificate type: Device** (this is mandatory for pre-logon — see R8).
   - **Subject name format:** e.g. `CN={{DeviceName}}` (or the format your head-end matches on).
   - **Subject alternative name:** add a SAN (e.g. DNS = `{{DeviceName}}`) if the head-end matches on SAN.
   - **Certificate validity period:** per R10 (e.g. 1 year).
   - **Key storage provider (KSP):** TPM if available, else software.
   - **Key usage:** *Digital signature* and *Key encipherment*.
   - **Extended key usage:** *Client Authentication* (`1.3.6.1.5.5.7.3.2`).
   - **Renewal threshold (%):** per R10 (e.g. 20) so certs renew before expiry.
   - **SCEP server URLs:** your NDES/SCEP (or Cloud PKI) URL(s).
   - **Root CA certificate:** reference the trusted-root profile from 2.2a.
5. **Assignments: Required** → `PILOT – Pre-Logon VPN (SBL) Users`. **Review + create.**
   (The issuing CA must be trusted by the Cisco head-end — Cisco-side trust config is deferred to
   Cisco docs.)

**Certificate best-practice note:** the renewal threshold must comfortably precede expiry so devices
never lose the pre-logon tunnel; keep the certificate profile in the coverage report (Phase 5) so an
expiring or failed certificate is caught before it silently breaks pre-logon at the logon screen.

## 2.3 Package and deploy the Windows client (Win32) — Core then SBL, with the SBL-enabled XML

1. **Prepare the package.** Place into a source folder:
   - the **Core VPN module** installer,
   - the **Start Before Logon module** installer,
   - the **SBL-enabled VPN client profile XML** (from R6, containing
     `<UseStartBeforeLogon>true</UseStartBeforeLogon>`).
   Author an install script (`install.cmd` / PowerShell) that:
   1. installs the **Core VPN module first**,
   2. then installs the **Start Before Logon module** (order matters — Core before SBL), and
   3. copies the **SBL-enabled XML** into the Secure Client profile directory
      (`%ProgramData%\Cisco\Cisco Secure Client\VPN\Profile`).
   Wrap the folder into an `.intunewin` with the **Microsoft Win32 Content Prep Tool**:
   `IntuneWinAppUtil.exe -c your-source-folder -s install.cmd -o your-output-folder`
2. **Add to Intune.** Intune admin center → **Apps > Windows > Add** → App type **Windows app
   (Win32)** → upload the `.intunewin`.
3. **App information.** Name it exactly `Cisco Secure Client – Pre-Logon (SBL) – Win32`; set publisher
   = Cisco, version, and a description noting Core + Start Before Logon modules.
4. **Program.**
   - **Install command:** your `install.cmd` line that runs the Core install, then the SBL install,
     then drops the XML (silent).
   - **Uninstall command:** MSI product-code uninstall for the modules.
   - **Install behavior: System.** Device restart behavior as Cisco specifies (SBL registration may
     require a reboot to surface the PLAP option).
5. **Requirements.** OS architecture **x64**; minimum OS version per Cisco support matrix.
6. **Detection rules.** Detect that **both** the client **and the Start Before Logon component** are
   present — for example, a file-exists rule on the PLAP DLL
   `%ProgramFiles(x86)%\Cisco\Cisco Secure Client\vpnplap64.dll` (or the Cisco-documented path for your
   version), in addition to the Core client MSI product code / core binary. Detecting only Core will
   mark a device *Installed* even when SBL is missing.
7. **Assignments.** Under **Required**, add `PILOT – Pre-Logon VPN (SBL) Users` (optionally with
   `Filter – Pre-Logon VPN – Windows`). Leave production for Phase 5.
8. **Review + create.**

## 2.4 Build the Windows VPN device-configuration profile (optional, connection settings)

Use this if you deliver VPN connection settings via Intune in addition to (or instead of) the bundled
XML. Keep it consistent with the bundled SBL-enabled XML so the two never contradict.

1. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** →
   **Templates > VPN**.
2. Name it exactly `Cisco Secure Client – Pre-Logon (SBL) – Profile – Windows`.
3. **Connection type:** *Cisco AnyConnect / Cisco Secure Client*.
4. **Connection name** (what the user sees), **Servers** (the gateway FQDN from R7, mark default).
5. **Authentication:** reference the device certificate issued by
   `Cisco Secure Client – Pre-Logon – Device Cert (SCEP) – Windows`.
6. **Split tunnel / routes** per R7.
7. **Assign** to `PILOT – Pre-Logon VPN (SBL) Users`. **Review + create.**

**Gate B (Configure):** The trusted-root profile, the **device** SCEP certificate profile, the Win32
app (installing **Core then SBL** and dropping the **SBL-enabled** XML), and the Windows VPN profile
all exist, are named to convention, and are assigned to `PILOT – Pre-Logon VPN (SBL) Users`. Re-run
`SBLVPN-Discovery.ps1` — every expected object should now be found.

---

# Phase 3 — Pilot

1. Ensure the pilot Windows devices are enrolled, compliant, and their users are members of
   `PILOT – Pre-Logon VPN (SBL) Users`.
2. Trigger a sync (Company Portal → **Sync**, or Intune → device → **Sync**) to pull the certificate
   profiles, the app, and the VPN profile.
3. Allow time for the trusted root + device certificate to land, then the Win32 app to install the
   Core and Start Before Logon modules and drop the XML. **Reboot** the device if SBL registration
   requires it so the PLAP "Network sign-in" option surfaces at the logon screen.

**Gate C (Pilot):** Every pilot device shows the certificate profiles *Succeeded*, the app *Installed*
(with the SBL detection rule satisfied), and the VPN profile *Succeeded* in Intune monitoring. If any
fail, go to `06-troubleshooting.md` before proceeding.

---

# Phase 4 — Validate

1. On a pilot device, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Validation.ps1`
   It confirms the client is installed, **Start Before Logon / PLAP is present**, the VPN profile XML
   contains `<UseStartBeforeLogon>true`, and a device certificate is present in `LocalMachine\My`.
2. Perform the decisive manual pre-logon test in `05-testing.md`: **lock or sign out**, click the
   **"Network sign-in"** (PLAP) option on the Windows logon screen, connect the Cisco Secure Client
   tunnel with the device certificate, then **log on to Windows with the tunnel already up**.
3. Run the fleet report to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\SBLVPN-Report.ps1`

**Gate D (Validate):** On every pilot device the client installs, SBL/PLAP is present,
`UseStartBeforeLogon` is `true`, the device certificate is issued, and the **pre-logon tunnel
establishes at the logon screen** with a successful Windows logon over it. All Testing guide pass/fail
gates are green. Only then proceed.

---

# Phase 5 — Expand

1. For the certificate profiles, the app, and the VPN profile, **add**
   `PROD – Pre-Logon VPN (SBL) Users` to the **Required** assignment. Keep
   `PILOT – Pre-Logon VPN (SBL) Users` assigned (pilot users stay covered).
2. Expand in waves if the fleet is large (e.g. add production sub-groups over several days) and watch
   the report between waves.
3. Monitor with `SBLVPN-Report.ps1` for coverage (app + profiles + certificate) and with Intune
   **Apps > Monitor** / **Devices > Configuration** for install/profile success.
4. Remediate stragglers with `SBLVPN-Remediation.ps1` (defaults to **-WhatIf** preview — review, then
   re-run with `-WhatIf:$false` to act).

**Rollback (any phase):** Remove/exclude the target group from the app, VPN profile, and certificate
assignments; to remove the installed client and the SBL/PLAP component, flip the Win32 app assignment
to **Uninstall** for the group.

**Gate E (Expand):** Fleet coverage meets your target (e.g. ≥ 95% of assigned devices with the app
*Installed* + SBL present, VPN profile *Succeeded*, and a valid device certificate); remaining failures
are triaged. Deployment is complete.
