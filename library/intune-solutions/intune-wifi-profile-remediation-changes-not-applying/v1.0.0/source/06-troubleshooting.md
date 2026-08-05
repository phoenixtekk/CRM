# 6. Troubleshooting

This guide covers getting the **method, scripts, and access** working. To diagnose an actual Wi-Fi
change that isn't applying, use the **Diagnostic Playbook** (`03-implementation.md`) — that is the
symptom tree. This file is about the tooling and the process itself.

---

## Connecting to Microsoft Graph

**`Connect-MgGraph` fails or the module is missing.**
- Install the SDK: `Install-Module Microsoft.Graph -Scope CurrentUser`.
- Confirm it is present: `Get-Module Microsoft.Graph -ListAvailable`.
- Run PowerShell as your admin account and re-run; consent to the requested scopes at the prompt.

**Wrong cloud / "no profiles found" in a Government tenant.**
- Pass the matching environment: `-Environment USGov` (GCC High) or `-Environment USGovDoD` (DoD).
  The SDK then targets `graph.microsoft.us` instead of `graph.microsoft.com`. The **admin portal** for
  US Gov is `intune.microsoft.us`. If a script returns nothing, first confirm you connected to the
  correct environment and tenant.

**"Insufficient privileges" or consent required.**
- Read-only scripts need `DeviceManagementConfiguration.Read.All`,
  `DeviceManagementManagedDevices.Read.All`, and `Group.Read.All`. The remediation helper's
  group-create needs `Group.ReadWrite.All`.
- If your tenant blocks user consent, have a Global Administrator grant admin consent for the
  Microsoft Graph Command Line Tools app once (Entra → **Enterprise applications**).

**Scripts return no Wi-Fi profiles even though they exist.**
- Confirm your account can read configuration profiles and that you signed in to the correct tenant
  and environment. Settings-catalog Wi-Fi policies are reported separately from legacy Wi-Fi
  templates — open a settings-catalog policy in the console to read its SSID if the export shows
  "(settings-catalog — open policy for SSID)".

---

## Reading applied state on the device

**`WIFIDX-Validate-Device.ps1` shows no saved profiles.**
- The device may have no WLAN adapter (Windows error `0x87d1fde8` also indicates a Wi-Fi profile
  pushed to non-Wi-Fi hardware), or it genuinely never joined the SSID. A never-joined device is your
  **control** for Branch A — it should show the new settings once the corrected profile applies.

**I can't get onto the affected device.**
- Windows: Intune → **Devices → the device → Collect diagnostics** packages the MDM logs (including
  DeviceManagement-Enterprise-Diagnostic-Provider) for offline reading.
- Apple/Android: use Intune **Remote Help** or have the user read **Settings → Wi-Fi → (i)** /
  saved-network details to you.

**Windows Event Viewer has no Wi-Fi entries.**
- Enable **Show Analytic and Debug Logs** (View menu), then look under **Applications and Services
  Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostic-Provider → Admin** for the
  **WiFiConfigurationServiceProvider** node-set-value result.

---

## Interpreting states

**Intune says Succeeded but the device is unchanged.**
- That is the core symptom, not a tooling bug. **Succeeded = delivered**, not applied. Go to Branch A
  (in-place edit of a known network) or Branch E (delivery-vs-application), and prove applied state on
  a **previously-joined** device.

**Android: the profile shows Failed but Wi-Fi works.**
- Known reporting bug — update the **Intune app to 2021.05.02 or later**. Also, on Android Enterprise
  fully managed/dedicated/COBO, **one** failing Wi-Fi profile makes **all** report failing (Branch C)
  — reduce to one Wi-Fi profile per device.

**Android: "Skipping Wifi profile … because it is pending certificates."**
- The enterprise/802.1X Wi-Fi profile depends on a Trusted Root + SCEP/PKCS certificate that isn't on
  the device yet. Fix the certificate chain first (certificate-Wi-Fi product), then the Wi-Fi profile.

---

## Remediation helper

**The helper made no change.**
- By design: `WIFIDX-Remediation.ps1` defaults to `-WhatIf` and only previews. Re-run with
  `-WhatIf:$false` after reviewing the planned action.

**`-RemoveStaleOnDevice` deleted the network and the device is now offline.**
- Expected transient state: the corrected Intune profile re-adds the network on the next sync. Trigger
  a sync (**Settings → Accounts → Access work or school → Info → Sync**). Keep a **guest Wi-Fi**
  fallback profile deployed so devices stay online during the swap.
- **Always confirm the corrected replacement profile exists and is assigned before removing the stale
  saved network** — otherwise there is nothing to re-add it.

**The helper won't create the pilot group.**
- Group creation needs `Group.ReadWrite.All`. Have a Global Administrator consent, or create
  **`WIFIDX - Pilot Devices`** (Security, **Assigned**) by hand in Entra.

---

## When the method stalls

- **You "fixed" it in place and it still won't update.** Editing the live profile is the trap. Build a
  **new** corrected profile, scope it to the pilot group, retire the old one, and re-test on a
  previously-joined device.
- **It applies on new devices but never on old ones.** Textbook Branch A — the stale saved network is
  not being overwritten. Remove-and-re-add (or unassign/reassign) is the fix.
- **Nothing in Intune ever reflects and Meraki is present.** Determine authority (Branch D): on Apple
  a device has exactly **one** MDM of record; the Meraki **dashboard** may own the SSID at the
  infrastructure level. Change it where it's actually owned. **Verify Meraki-side steps against current
  Cisco Meraki documentation.**
- **Government tenant specifics.** Behavior matches Commercial; only endpoints differ. Where a GCC High
  detail is uncertain, **verify for GCC High** rather than assume parity.
