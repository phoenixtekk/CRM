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
