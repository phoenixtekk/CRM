# 2. Requirements Guide — Intune Wi-Fi Profile Remediation

Confirm **every** requirement before you diagnose. A missing prerequisite (for example, an absent
certificate dependency, or no access to an affected device) is itself a common reason a Wi-Fi change
"isn't applying." Each entry follows **Description · Why required · How to verify · How to implement
if missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> **Naming convention (used verbatim throughout this toolkit).** Create and reuse these exact names so
> the steps, scripts, testing, and troubleshooting all line up. The core remediation pattern is a
> **new replacement profile** — never an in-place edit — so the names below are for the corrected
> objects you will build:
> - Pilot device group (Assigned): **`WIFIDX - Pilot Devices`**
> - Corrected Windows profile: **`WIFIDX - WiFi - Corrected - Windows - Pilot`**
> - Corrected iOS/iPadOS profile: **`WIFIDX - WiFi - Corrected - iOS - Pilot`**
> - Corrected Android profile: **`WIFIDX - WiFi - Corrected - Android - Pilot`**
> - Production rename (after pilot passes): the same names with **`- Prod`** in place of **`- Pilot`**
>
> Worked example values used in the playbook (replace with your own): SSID **`CORP-WIFI`**; manual
> proxy host **`proxy.corp.example`** port **`8080`**; PAC URL **`http://wpad.corp.example/proxy.pac`**.

## 2.1 Intune administrator role (or Policy & Profile Manager)
**Description:** An Entra/Intune role able to **read and create** device configuration profiles and
their assignments — **Intune Administrator**, or the built-in **Policy and Profile Manager** role.
**Why required:** The remediation creates a **new** Wi-Fi profile and assigns it; read-only roles can
diagnose but not remediate.
**How to verify:** `https://entra.microsoft.com` → **Roles and administrators** → confirm your account
holds **Intune Administrator** (or **Policy and Profile Manager**).
**How to implement if missing:** Entra → **Roles and administrators** → assign **Intune Administrator**.
Reserve Global Administrator for tenant-wide changes only.

## 2.2 Microsoft Graph read access (for the scripts)
**Description:** Delegated Microsoft Graph read scopes so the discovery/validation/report scripts can
enumerate Wi-Fi configuration profiles, their assignments, and per-device state.
**Why required:** The read-only scripts call Graph to export every Wi-Fi profile and detect duplicates
and conflicts — the picture the console only shows one profile at a time. Without these scopes the
scripts cannot sign in.
**How to verify:** Run **`WIFIDX-Preflight.ps1`** — on first run it prompts for consent to
`DeviceManagementConfiguration.Read.All`. Successful sign-in confirms access.
**How to implement if missing:** Sign in as an admin who can consent, or have a Global Administrator
grant admin consent for `DeviceManagementConfiguration.Read.All`,
`DeviceManagementManagedDevices.Read.All`, and `Group.Read.All`. Install the SDK with
`Install-Module Microsoft.Graph -Scope CurrentUser`.

## 2.3 Graph scopes for the remediation helper
**Description:** Write scope needed **only** when `WIFIDX-Remediation.ps1` creates the corrected
replacement profile or pilot group for you (`DeviceManagementConfiguration.ReadWrite.All`,
`Group.ReadWrite.All`).
**Why required:** Creating a profile or group writes to Intune/Entra; the diagnostic scripts never
need this.
**How to verify:** The helper previews all actions under `-WhatIf` (its default) without needing write
consent; the write scope is requested only when you re-run with `-WhatIf:$false`.
**How to implement if missing:** Have a Global Administrator grant admin consent for the ReadWrite
scopes before running the helper without `-WhatIf`. You can always build the profile by hand in the
console instead (document 3).

## 2.4 Access to at least one affected device (per platform)
**Description:** Administrative (or Remote Help) access to a reproducing device on **each platform you
manage** — Windows, iOS/iPadOS, and/or Android.
**Why required:** The whole point of this product is to prove the change **applied on the device**, not
just that Intune reported Succeeded. That requires reading the live saved network on the device:
`netsh wlan show profiles` / effective proxy on Windows; the installed Wi-Fi payload on iOS/iPadOS; the
saved network on Android.
**How to verify:** On a Windows device you can run **`WIFIDX-Validate-Device.ps1`** locally; on Apple
you can open **Settings → General → VPN & Device Management** to see the installed profile; on Android
you can open the saved-network details.
**How to implement if missing:** Arrange local admin, Intune **Remote Help**, or Intune → device →
**Collect diagnostics** for Windows to package the MDM logs for offline reading.

## 2.5 Certificate dependency present (enterprise/802.1X profiles only)
**Description:** For an **Enterprise** (EAP / 802.1X) Wi-Fi profile, the **Trusted Root** and
**SCEP/PKCS** certificate profiles the Wi-Fi profile references must already be deployed and healthy on
the device.
**Why required:** If the certificate the Wi-Fi profile expects is missing, the device **skips the
Wi-Fi profile as pending certificates** — which looks exactly like "the change isn't applying." This
toolkit checks for that dependency but **defers certificate deployment** itself to the
certificate-Wi-Fi product.
**How to verify:** On Android, the Company Portal `Omadmlog` shows *"Skipping Wifi profile … because it
is pending certificates"* when the cert is absent. On Windows, confirm the Trusted Root and SCEP/PKCS
profiles show **Succeeded** on the device before blaming the Wi-Fi profile.
**How to implement if missing:** Deploy/repair the certificate chain using the certificate-Wi-Fi
solution, then return here. Do not proceed with Wi-Fi remediation until the certificates are healthy.

## 2.6 A reproducing device and a known-good device
**Description:** One device that shows the stale/old Wi-Fi setting **and** one comparable device where
the change did apply (or a freshly-enrolled device that never had the old network).
**Why required:** Comparing a device that already knew the SSID against one that did not is the fastest
way to confirm the in-place-update crux (Branch A).
**How to verify:** Intune → the Wi-Fi profile → **Device status** lists both; on the devices, the
saved-network details differ.
**How to implement if missing:** Enroll or reset one test device so it has **never** joined the SSID,
and keep one device that already had the old network.

## 2.7 Clarity on whether Cisco Meraki is in scope
**Description:** Know whether the environment uses the **Meraki dashboard** (wireless infrastructure)
and/or **Meraki Systems Manager** (Meraki's MDM), and have read access to whichever is present.
**Why required:** If Meraki SM is co-managing the device, or the Meraki dashboard enforces the setting
at the SSID, Intune is not authoritative and no Intune change will reflect (Branch D).
**How to verify:** Ask whether devices were ever enrolled in Meraki SM; on an Apple device, **Settings
→ General → VPN & Device Management** shows **which MDM** owns the device. In the Meraki dashboard,
**Wireless → Configure** shows SSID/group-policy settings.
**How to implement if missing:** Obtain read access to the Meraki dashboard and/or SM console for the
affected site. Where a Meraki step is version-specific, **verify against current Cisco Meraki
documentation.**

---
## Checklist
- [ ] Intune Administrator / Policy & Profile Manager role — Entra Roles
- [ ] Graph read scopes consented — `WIFIDX-Preflight.ps1` signs in
- [ ] Graph write scope available for the remediation helper (optional)
- [ ] Access to one affected device **per platform** you manage
- [ ] Certificate dependency confirmed healthy (enterprise/802.1X profiles only)
- [ ] One affected device **and** one known-good / never-joined device identified
- [ ] Meraki footprint understood (dashboard vs Systems Manager) and read access obtained
- [ ] Naming convention adopted (corrected profiles + pilot group named exactly as above)
