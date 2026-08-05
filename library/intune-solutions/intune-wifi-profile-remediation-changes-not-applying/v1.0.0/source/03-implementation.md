# 3. Diagnostic Playbook — Wi-Fi Changes Not Applying

This is the core of the solution: a **symptom-driven tree** for an Intune **Wi-Fi configuration
profile** that will not update or reflect a change. Start from what you observe, follow the branch,
run the exact checks, and land on the one cause that owns the failure. Then apply the fix and re-run
the validation gates in `05-testing.md`.

**Golden rule:** a Wi-Fi change travels **Assignment → Sync/delivery → (certificate dependency) →
application to the saved network → report**. Intune's **Succeeded** proves *delivery*, not that the
live saved network on the device was rewritten. The **first** layer that fails is the root cause. For
a *changed* profile, application-to-the-saved-network (Branch A) is where it silently stalls most
often — check it before you touch anything else.

> **Deferral, so you don't chase the wrong thing.** General "assigned but not applying" diagnosis
> (group/filter scope, sync health, generic CSP errors, policy conflicts) is owned by the **Intune
> Device Configuration & Policy Troubleshooting Toolkit** — this playbook assumes assignment and sync
> are healthy and focuses on the **Wi-Fi-specific** causes. First-time 802.1X **certificate**
> deployment is owned by the certificate-Wi-Fi product. If Step 0 shows the profile isn't even
> assigned or the device isn't syncing, fix that there first.

---

## Step 0 — Establish the facts (always do this first)

Do not change anything until you can answer all six. `WIFIDX-Preflight.ps1` and
`WIFIDX-Get-WifiProfiles.ps1` collect most of this for you.

1. **Which platform?** Windows, iOS/iPadOS, or Android — the saved-network behavior and the proxy
   fields differ per platform (Branch F). Diagnose one platform at a time.
2. **Which profile, and what exactly changed?** Identify the exact Intune Wi-Fi profile and the field
   you edited — **PSK/password**, **proxy**, **SSID**, **security type**, or **auto-connect**. The
   change type points to the branch: any in-place edit → Branch A; a proxy edit → also Branch B.
3. **Is it an in-place edit of an SSID the device already knows?** Confirm whether the affected
   devices had **already joined** this SSID before the change. If yes, you are almost certainly in
   **Branch A** — Intune does not reliably overwrite a known network.
4. **What is the reported state vs the applied state?** In Intune, open the profile → **Device
   status** and note **Succeeded / Error / Not applicable** for the affected device. Then read the
   **actual** live setting on the device (Windows: `WIFIDX-Validate-Device.ps1`; Apple/Android: the
   saved-network details). **Succeeded + wrong-on-device = Branch A or E**, not a delivery failure.
5. **Are there duplicate or conflicting Wi-Fi profiles?** Run `WIFIDX-Get-WifiProfiles.ps1` — more
   than one Intune Wi-Fi profile targeting the same devices for the **same SSID** is Branch C.
6. **Is Cisco Meraki in play?** Was the device ever enrolled in **Meraki Systems Manager**? Does the
   **Meraki dashboard** enforce anything at the SSID (proxy, splash, auth)? If either is true, Intune
   may not be authoritative — Branch D.

Now pick the branch that matches your symptom.

---

## Branch A — Modified profile does not update the existing SSID in place

**Symptom:** You changed a field (password, proxy, security type, auto-connect) on an existing Wi-Fi
profile and saved it. Intune shows **Succeeded**, but devices that had **already joined** the SSID
keep the **old** settings. New / never-joined devices may pick up the change fine — which is the
tell.

**Owner layer:** Application to the saved network. **This is the crux of this product.**

**Why it happens:** A device that has joined an SSID keeps it as a **known / saved network**. When
Intune re-delivers the edited payload, the device does **not** reliably overwrite the network it
already has. Microsoft documents the canonical case (a changed password): after you change the
password on an existing profile, *"some users may not get the new profile."* The same is observed for
proxy, security-type, and auto-connect edits. The payload is delivered (hence **Succeeded**) but the
live saved network is not rewritten.

**How to confirm:**

1. **Compare a joined device to a never-joined device.** On the reproducing device (already knew
   `CORP-WIFI`), read the live setting:
   - **Windows:** `WIFIDX-Validate-Device.ps1` (wraps `netsh wlan show profile name="CORP-WIFI"
     key=clear` and the effective proxy). The old value is still there.
   - **iOS/iPadOS:** **Settings → General → VPN & Device Management** → the management profile →
     confirm the Wi-Fi payload; and **Settings → Wi-Fi → (i) next to CORP-WIFI** for the live proxy.
   - **Android:** long-press the saved **CORP-WIFI** network → view details / proxy.
   On a freshly-enrolled device that **never** joined `CORP-WIFI`, the **new** value is present. If
   new devices are correct and only previously-joined devices are wrong, that difference **is** the
   confirmation.
2. **Confirm delivery actually happened.** Intune → profile → **Device status** = Succeeded, and
   `WIFIDX-Report-ProfileState.ps1` flags the device as **reported-Succeeded but applied-mismatch**.

**Fix — deploy a corrected replacement profile, do not edit in place:**

1. **Create a NEW Wi-Fi profile** with the corrected settings rather than editing the old one:
   - **Windows:** **Devices → Configuration → Create → New policy** → Platform **Windows 10 and
     later** → Profile type **Templates → Wi-Fi** (or **Settings catalog → Wi-Fi**) → **Create**.
     Name it **`WIFIDX - WiFi - Corrected - Windows - Pilot`**. Enter SSID **`CORP-WIFI`** and the
     corrected settings.
   - **iOS/iPadOS:** **Devices → Configuration → Create** → Platform **iOS/iPadOS** → **Templates →
     Wi-Fi** → **Create**. Name it **`WIFIDX - WiFi - Corrected - iOS - Pilot`**.
   - **Android:** **Devices → Configuration → Create** → the matching **Android Enterprise** profile
     type → **Wi-Fi** → **Create**. Name it **`WIFIDX - WiFi - Corrected - Android - Pilot`**.
2. **Assign it to `WIFIDX - Pilot Devices`** only (the Assigned pilot group from §2.6).
3. **Retire the old profile from the same devices.** To force the device to drop the stale saved
   network, **unassign the old profile from the pilot group** (or delete it once the replacement is
   proven). Removing the old Wi-Fi profile removes its saved network from enrolled devices, so the
   replacement installs cleanly instead of colliding with a known network.
4. **Where the SSID/security itself changed (not just a password):** the most reliable pattern is
   **remove-and-re-add** — remove the old saved network, then let the corrected profile create it
   fresh. `WIFIDX-Remediation.ps1 -WhatIf:$false` can remove the stale Windows saved network
   (`netsh wlan delete profile name="CORP-WIFI"`) as part of this, so the corrected profile re-adds
   it on the next sync. On Apple/Android, unassign/reassign the profile achieves the equivalent.
5. **If you must keep users online during the change:** deploy a **guest Wi-Fi** profile
   (**`WIFIDX - WiFi - Guest - Fallback`**) with auto-connect enabled to all users, as Microsoft
   recommends, so a device that briefly loses the corporate network can still reach the internet
   while the corrected profile lands.

**Re-validate:** run the Branch A gate in `05-testing.md` — the live saved network on a
previously-joined device must now show the **new** value, not just Succeeded in Intune.

---

## Branch B — Proxy set wrong, in the wrong field, or as URL-vs-hostname

**Symptom:** The device connects to `CORP-WIFI` but **all traffic breaks** (no browsing, auth
failures), or the proxy simply never takes effect. Often paired with Branch A after a proxy edit.

**Owner layer:** The proxy sub-settings inside the Wi-Fi payload.

**Why it happens:** A Wi-Fi profile offers **two mutually-exclusive** proxy modes, and the fields
mean different things. Putting a value in the wrong shape is the single most common proxy mistake.

**The rule — memorize this:**
- **Manual proxy = a host + a separate port.** It is a **hostname or IP address**, **never a URL** —
  no `http://`, no `/path`. A slash or scheme in this field is sent verbatim and fails.
- **Automatic proxy = a PAC URL.** It is a **full URL** to a `.pac` script, **with** scheme —
  e.g. `http://wpad.corp.example/proxy.pac`. A bare hostname here is wrong.

**Exact fields per platform (verified against Microsoft Learn):**
- **Windows** — profile → **Company proxy settings**:
  - **None**
  - **Manually configure** → **Proxy server IP address** + **Port number** (host/IP + port).
  - **Automatically configure** → the **URL** pointing to a PAC script,
    e.g. `http://wpad.corp.example/proxy.pac`.
- **iOS/iPadOS & macOS** — profile → **Proxy settings**:
  - **None**
  - **Manual** → **Proxy server address** (as an IP/host) + **Port number**.
  - **Automatic** → **Proxy server URL** that contains the configuration file, e.g.
    `http://wpad.corp.example/proxy.pac`.
- **Android Enterprise** — proxy support depends on the profile type; where a manual proxy is offered
  it is a **host + port**, and automatic is a **PAC URL**. Some Android profile types do not expose a
  Wi-Fi proxy at all — **verify against current Microsoft documentation** for the specific Android
  enrollment type before assuming the field exists.

**How to confirm:**

1. **Read what you actually entered.** `WIFIDX-Get-WifiProfiles.ps1` exports each profile's proxy
   mode and value. Look for a manual field containing `http://` or a `/` (wrong), or an automatic
   field with a bare host and no `.pac` (wrong).
2. **Read the effective proxy on the device.** Windows: `WIFIDX-Validate-Device.ps1` reports the
   effective connection proxy. Apple: **Settings → Wi-Fi → (i) → HTTP Proxy**. Confirm it matches
   intent.
3. **If it's a PAC:** confirm the device can actually **reach** the PAC URL host (it must resolve and
   serve the `.pac`). A PAC URL the device can't reach = no proxy applied.

**Fix:** Set the **correct mode** and put the value in the **correct shape** — manual = host + port
(no scheme/path); automatic = full PAC URL. Because this is an edit to an existing profile, apply it
via the **corrected replacement profile** from Branch A (not an in-place edit), then re-validate the
effective proxy on the device.

---

## Branch C — Duplicate or conflicting Wi-Fi profiles

**Symptom:** Settings flip between values, the profile intermittently shows **failing**, or your
change is overwritten by "another" profile. On **Android Enterprise** fully managed / dedicated /
corporate-owned work profile devices, **all** Wi-Fi profiles may report **failing** at once.

**Owner layer:** Multiple Wi-Fi payloads competing for the same SSID.

**Why it happens:** Two (or more) Intune Wi-Fi profiles targeting the same devices for the **same
SSID** each try to own the saved network; the effective value becomes last-writer/undefined. And per
Microsoft: for Android Enterprise fully managed/dedicated/COBO, **when you deploy more than one Wi-Fi
profile and one fails, they all report as failing** — even the ones still working — which masks which
profile is really the problem.

**How to confirm:**

1. **List every Wi-Fi profile and its targets.** `WIFIDX-Get-WifiProfiles.ps1` groups profiles by
   **SSID** and flags any SSID targeted by more than one profile at the same devices. That list is
   your duplicate/conflict set.
2. **Check for a leftover old profile.** The pre-change profile you thought you replaced may still be
   assigned to the same group — it re-asserts the old value every sync.

**Fix:** Establish **one profile per SSID per device**. Keep the **`WIFIDX - WiFi - Corrected -
<platform> - Pilot`** profile and **unassign/delete** every other profile targeting `CORP-WIFI` on
those devices. On Android, reduce to a single Wi-Fi profile per device so a single failure stops
poisoning the report. Re-validate the aggregate report is clean.

---

## Branch D — Cisco Meraki is overriding the client settings

**Symptom:** Nothing you do in Intune reflects on the device, and the environment uses Cisco Meraki.
The setting (proxy, auth, SSID behavior) appears to come from "somewhere else."

**Owner layer:** A Meraki system — **not** Intune — is authoritative for the setting.

**Why it happens — two different Meraki products, commonly confused:**

- **Meraki dashboard (wireless infrastructure).** APs, broadcast SSIDs, RADIUS, VLANs, and per-SSID
  **group policies**. This is the **network side**. If the proxy/auth/splash is enforced here at the
  SSID, it is not a device saved-network setting at all, and **no Intune Wi-Fi profile edit will ever
  change it** — the dashboard owns it.
- **Meraki Systems Manager (SM) — Meraki's own MDM/UEM.** SM pushes its **own Wi-Fi Settings
  payload** (SSID, auto-join, and — **proxying is only supported on Apple devices** — a proxy that is
  **None / Manual (hostname or IP + port) / Automatic (a URL, WPAD if blank)**). If a device is
  enrolled in SM, it can carry a **second managed Wi-Fi payload for the same SSID**, masking your
  Intune change.

**How to tell which system is authoritative:**

1. **On Apple, check which MDM owns the device.** **Settings → General → VPN & Device Management** →
   read the management profile's **name/organization**. An Apple device can be **MDM-enrolled to only
   one server** — if it says **Meraki**, it is **not** taking Intune Wi-Fi profiles at all (and vice
   versa). This alone resolves many "Intune isn't applying" cases.
2. **Look for a second Wi-Fi payload.** On the device, is there a Meraki-authored Wi-Fi profile for
   `CORP-WIFI` alongside (or instead of) Intune's? On Windows, `WIFIDX-Validate-Device.ps1` shows the
   saved profile; a Meraki-managed one indicates SM co-management.
3. **Check the Meraki dashboard for SSID-level enforcement.** In the dashboard, **Wireless →
   Configure** → the SSID → group policy / proxy / splash settings. If the behavior is set here, the
   dashboard is authoritative. **Verify against current Cisco Meraki documentation** — dashboard
   navigation changes over time.

**Fix (decide authority first, then act):**

- **If the setting is enforced at the Meraki dashboard SSID:** change it **in the Meraki dashboard**,
  not in Intune. Intune should not also push a conflicting client-side value for that SSID.
- **If the device is enrolled in Meraki SM:** decide the **single** MDM of record. If Intune is to
  own Wi-Fi, **unenroll from Meraki SM** (or remove SM's Wi-Fi payload) so the Intune profile is the
  only Wi-Fi authority; on Apple this may require re-enrollment because only one MDM can own the
  device. If Meraki SM is to own Wi-Fi, make the change **in SM** and stop pushing the Intune Wi-Fi
  profile to those devices.
- **Never leave two MDMs pushing the same SSID.** One system owns Wi-Fi; the other must not target
  it. Flag any SM-side step as **verify against current Cisco Meraki documentation**.

**Re-validate:** confirm the device now has exactly one managed Wi-Fi payload for `CORP-WIFI`, from
the authoritative system, showing the intended value.

---

## Branch E — Profile reports Succeeded, device is unchanged (delivery vs application)

**Symptom:** Intune says **Succeeded** everywhere, but the live setting on the device is wrong — and
you have already ruled out an obvious in-place-known-network case, or you want to confirm it's a
reporting/application gap rather than a real failure.

**Owner layer:** The gap between **reported** state (delivery) and **applied** state (the live saved
network).

**Why it happens:** **Succeeded** in Intune means the payload was **delivered and accepted** — not
that the OS rewrote a network it already had (Branch A), and not that reporting is even current. Two
specific reporting traps per Microsoft:
- **Android reporting error:** a Wi-Fi profile can **report as failing while actually working** — a
  known reporting bug fixed by updating the **Intune app to version 2021.05.02 or later**.
- **Android aggregate failure:** one failing Wi-Fi profile makes **all** report failing (see Branch
  C) — the report is lying about the working ones.

**How to confirm:**

1. **Trust the device, not the console.** `WIFIDX-Report-ProfileState.ps1` lists, per device, the
   **reported** state next to the **applied** state and flags mismatches. A row that is
   *Succeeded / applied-mismatch* is the delivery-vs-application gap.
2. **Read the platform log** to see the actual application result:
   - **Windows:** Event Viewer → **Applications and Services Logs → Microsoft → Windows →
     DeviceManagement-Enterprise-Diagnostic-Provider → Admin**. Look for the
     **WiFiConfigurationServiceProvider** node-set-value result.
   - **Android:** Company Portal **`Omadmlog`** (read with CMTrace, filter `wifimgr`) — look for
     *"Applied profile"* vs *"Skipping Wifi profile … because it is pending certificates."*
   - **iOS/iPadOS:** the device Console log — *"Profile … installed."*
3. **Check the Intune app version on Android** if the profile "fails but works."

**Fix:** If it's the known Android reporting bug, **update the Intune app to 2021.05.02+**. If the log
shows the payload was accepted but the live network is stale, it's the Branch A application gap →
apply the corrected replacement profile. If the log shows *pending certificates*, it's the dependency
in §2.5 → repair certificates first. Then re-validate applied state on the device.

---

## Branch F — Platform-specific quirks (Windows vs iOS vs Android)

**Symptom:** The change reflects on one platform but not another, or the same steps behave
differently across your fleet.

**Owner layer:** Per-platform Wi-Fi handling.

**Key differences to check:**

- **Windows.** Saved networks are visible with `netsh wlan show profiles`; a stale one can be removed
  with `netsh wlan delete profile name="CORP-WIFI"` (what `WIFIDX-Remediation.ps1` does under
  `-WhatIf:$false`). Applied state is logged under **DeviceManagement-Enterprise-Diagnostic-Provider
  → Admin**. Error **`0x87d1fde8`** appears when a Wi-Fi profile targets a device with **no Wi-Fi
  hardware** — scope the profile to Wi-Fi-capable devices with an assignment filter.
- **iOS/iPadOS.** Wi-Fi lives **inside the MDM profile**; a device is **MDM-enrolled to only one
  server** (critical for Branch D). Proxy = **None / Manual (address + port) / Automatic (Proxy
  server URL)**. To force a changed network to reinstall, unassign then reassign the corrected
  profile.
- **Android Enterprise.** Behavior differs by enrollment type (fully managed / dedicated / work
  profile); one failing Wi-Fi profile makes **all** report failing; the "fails but works" reporting
  bug needs Intune app **2021.05.02+**. Proxy support varies by profile type — **verify against
  current Microsoft documentation** for your Android enrollment type. Certificate dependency (§2.5)
  is the top cause of a skipped Wi-Fi profile on Android.

**Fix:** Apply the platform-appropriate remediation from the branch that matches the symptom, using
the corrected replacement-profile pattern, and validate on a device **of that platform** — never
assume a fix on one platform proves the others.

---

## After any fix — re-validate that it applied on a device

Do not stop at "Intune shows Succeeded." Force a sync, allow a check-in cycle, then run
`WIFIDX-Validate-Device.ps1` (Windows) or read the live saved-network setting (Apple/Android) and
confirm the **new** value is actually present on a **previously-joined** device. Use the gates in
`05-testing.md`. Only promote the corrected profile from **`- Pilot`** to **`- Prod`** once a
previously-joined device passes.
