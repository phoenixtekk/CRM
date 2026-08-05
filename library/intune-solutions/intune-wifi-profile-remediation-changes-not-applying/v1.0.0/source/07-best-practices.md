# 7. Best Practices

Practices that prevent "Wi-Fi change not applying" from recurring, drawn from the crux behaviors this
toolkit diagnoses.

## Treat a Wi-Fi change as a new profile, not an edit
- **Never edit a live Wi-Fi profile's SSID, security type, or PSK in place** and expect
  previously-joined devices to update — they often will not. Build a **new** profile
  (**`WIFIDX - WiFi - Corrected - <platform> - Pilot`**), pilot it, then retire the old one.
- Editing a **non-network** attribute (e.g. auto-connect) in place is lower-risk, but still validate
  applied state on a previously-joined device before trusting it.

## One profile — and one authority — per SSID per device
- Keep exactly **one** Intune Wi-Fi profile per SSID targeting a given device. Duplicates produce
  last-writer/undefined values and, on Android, make **all** Wi-Fi profiles report failing.
- If Cisco Meraki is present, decide **one** system of record for Wi-Fi. Let the **Meraki dashboard**
  own SSID/infrastructure enforcement, or let an MDM (Intune **or** Meraki Systems Manager, not both)
  own the client Wi-Fi payload — never two MDMs pushing the same SSID. On Apple, remember only **one**
  MDM can own the device.

## Get the proxy shape right, every time
- **Manual proxy = host/IP + port.** No scheme, no path — a hostname, not a URL.
- **Automatic proxy = a PAC URL** (`http://host/….pac`) the device can actually reach.
- Document which mode your network uses so admins stop pasting URLs into the manual field.

## Name objects so they audit and clean up cleanly
- Use the convention **`WIFIDX - WiFi - Corrected - <platform> - <stage>`** and the **`WIFIDX - Pilot
  Devices`** Assigned group. Reuse the exact names in scripts, testing, and troubleshooting so the old
  profile is obvious when it's time to retire it.

## Scope Wi-Fi profiles to devices that can use them
- Target Wi-Fi profiles with an **assignment filter for Wi-Fi-capable hardware** to avoid the Windows
  **`0x87d1fde8`** error on devices with no Wi-Fi adapter (which otherwise pollutes your failure
  report).
- Match the profile platform and Android enrollment type to the device — proxy and payload support
  vary by type.

## Keep a fallback so a change never strands users
- Deploy a **guest Wi-Fi** profile with auto-connect to all users, per Microsoft's guidance, so a
  device that briefly drops the corporate network during a change can still reach the internet and
  re-sync.

## Validate on the device, not in the console
- Make **applied-state on a previously-joined device** the definition of done. Use
  `WIFIDX-Report-ProfileState.ps1` to catch **Succeeded / applied-mismatch** rows before users report
  them.
- Keep Android's **Intune app updated (2021.05.02+)** so the "fails but works" reporting bug doesn't
  send you chasing phantom failures.

## Keep vendor-specific and certificate steps in their lane
- For 802.1X **certificate** health, use the certificate-Wi-Fi product; a missing cert makes a Wi-Fi
  profile skip as *pending certificates*, which mimics "not applying."
- For **Meraki** console internals, **verify against current Cisco Meraki documentation** — dashboards
  and SM change over time.

## Government / sovereign-cloud note
- In **GCC / GCC High / DoD**, the Wi-Fi profile behavior and the remediation pattern are the same;
  only the portals/endpoints differ (`intune.microsoft.us`, Graph `graph.microsoft.us`,
  `Connect-MgGraph -Environment USGov`/`USGovDoD`). The **FIPS** toggle on a Windows Wi-Fi profile is
  the one setting more likely to matter for federal buyers. Where a GCC High specific is uncertain,
  **verify for GCC High** rather than assume parity.
