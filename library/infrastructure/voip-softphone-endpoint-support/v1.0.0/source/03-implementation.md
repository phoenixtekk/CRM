# Diagnostic Playbook

This is the working guide desktop support follows when a VOIP/softphone call-quality ticket arrives. It
is **symptom-driven**: find the reported symptom, follow that branch, run the exact endpoint-side checks
in order, and **stop at the first broken link**. Walk every branch top-down through the root-cause tree
(audio device → client → network/QoS → escalate). The Windows/Intune steps are precise; anything that
lives on the telephony platform's servers is called out as an escalation, not something you fix here.

**Before any branch — set the frame:**
1. Run **VOIPSUP-Discovery.ps1** to capture the audio-device inventory and the softphone client version.
2. Ask the user: *when* did it start, *is it every call or some calls*, *which headset*, *wired or Wi-Fi*.
3. Reproduce if you can. A ticket you can reproduce is a ticket you can prove fixed.

---

## Symptom A — No audio (can't hear, can't be heard) or one-way audio

**Most likely: wrong device selected, muted/zeroed level, or missing mic permission — not the network.**

1. **Check the selected devices.** Settings → **System → Sound**. Confirm the correct output (speaker)
   and input (microphone) are chosen. Then open **Sound Control Panel** (`mmsys.cpl`) →
   **Playback** and **Recording** tabs and confirm the headset is set as **Default Communication
   Device** (the green phone icon), not just Default Device. `VOIPSUP-Discovery.ps1` reports the current
   defaults so you can compare against the intended device from your inventory (R2).
2. **Check levels and mute.** In **Recording → [mic] → Properties → Levels**, confirm the mic is not
   muted and the level is not at 0. In **Playback → [speaker] → Properties → Levels**, same. Watch the
   green level meter on the Recording tab while the user speaks — no movement means the mic isn't
   capturing.
3. **Check microphone privacy permission.** Settings → **Privacy & security → Microphone** — confirm
   **Microphone access** is On and that **desktop apps** (and the specific client, if listed) may use
   the mic. A blocked mic permission is a classic "one-way audio" cause.
4. **Check the client's own device selection.** The softphone client can select a *different* device
   than Windows. Open the client's audio/device settings and confirm it uses the same headset. (This is
   client UI — follow the vendor's docs for the exact menu; the point is that the client device must
   match the Windows default communication device.)
5. **Check the physical connection.** For USB: try a different port (avoid unpowered hubs). For
   Bluetooth: confirm paired and connected, and that it's in the correct profile (a headset stuck in
   music/A2DP mode instead of hands-free/HFP gives you output but no working mic — reconnect or
   re-select the hands-free device).
6. **Isolate one-way audio.** If the user can hear but not be heard → the **input** side (mic device,
   mic level, mic permission, mic mute). If they can be heard but not hear → the **output** side (wrong
   speaker device, output level/mute). One-way audio is almost always a one-sided endpoint fault.
7. **Still broken with the right device, level, permission, and client selection?** Run
   **VOIPSUP-Validation.ps1** to confirm the device tests healthy, then escalate: if the endpoint proves
   the correct device is active and capturing but the platform reports no media, that's a
   **platform/media-path issue → escalate with the device report.**

**Remediation shortcut:** `VOIPSUP-Remediation.ps1` can set the correct Default Communication Device and
restart the Windows audio service. It defaults to `-WhatIf` — review the planned action, then re-run
with `-Execute` (or `-WhatIf:$false`) to apply.

---

## Symptom B — Echo, robotic, choppy, or garbled audio

**Most likely: network jitter/latency/loss, or a device-enhancement/sample-rate conflict.**

1. **Wired vs Wi-Fi first.** `Get-NetAdapter` (or Settings → **Network & internet**) — is the call on
   Wi-Fi? Moving to a wired connection is the single highest-yield fix for robotic/choppy audio. If
   only Wi-Fi is possible, note signal strength and channel congestion.
2. **Measure the network path.** Run **VOIPSUP-Validation.ps1** to report **latency, jitter, and packet
   loss** to the media-edge target from R3/R5. Compare against your thresholds. High jitter or loss →
   robotic/choppy audio; high latency → talk-over/echo perception.
3. **Rule out local congestion.** Check for a large upload/download or backup running during the call
   (`Get-Process`, Task Manager → Network). Saturated uplink starves call media.
4. **Check audio enhancements.** **Sound Control Panel → Recording/Playback → [device] → Properties →
   Advanced / Enhancements** — a mismatched **sample rate** or aggressive **signal enhancements** can
   cause robotic audio. Try the default format and, if enhancements are on, test with them off.
5. **Echo specifically.** Echo is usually the *far* end hearing themselves via *your* speaker feeding
   *your* mic. Confirm the user is on a headset (not open speakers + mic), and that echo cancellation is
   not disabled in the device/client settings. If a headset is in use and it still echoes across
   multiple calls/parties, that points at platform-side media handling → **escalate**.
6. **VPN interference.** If the endpoint is on VPN, media may be tromboning through a distant gateway —
   note it; split-tunnel for VOIP media is a network-team change → **escalate the QoS/VPN routing** with
   the latency numbers.
7. **Verify QoS marking.** `Get-NetQosPolicy` — confirm DSCP marking exists for the client's media. If
   the endpoint isn't marking traffic, deploy the QoS policy (see Remediation); if it *is* marked but
   quality is still poor, WAN/LAN QoS **enforcement** is the network/telephony team's domain →
   **escalate with the measured jitter/latency/loss.**

---

## Symptom C — Wrong default device (calls keep using the laptop mic/speaker)

**Most likely: Default Communication Device not set to the headset, or Windows switching on reconnect.**

1. **Confirm the intended device.** From R2, know which device *should* be default for this user/role.
2. **Set the Default Communication Device.** **Sound Control Panel** → **Playback** and **Recording** →
   right-click the correct headset → **Set as Default Communication Device**. Note that Windows tracks
   *Default Device* and *Default Communication Device* separately — calls use the communication default.
3. **Handle reconnect churn.** USB/Bluetooth headsets that disconnect (sleep, undock) can lose the
   default when they return. `VOIPSUP-Remediation.ps1` can re-assert the correct default communication
   device (default `-WhatIf`); for persistent churn, standardize on one connection method and keep the
   headset firmware/driver current (Symptom D).
4. **Client override.** Even with Windows correct, the client may pin a stale device. Set the client's
   device to match, or set it to "use system default" so it follows Windows.

---

## Symptom D — Headset not recognized / not appearing as a device

**Most likely: driver, connection, or firmware — a pure endpoint problem.**

1. **Enumerate what Windows sees.** Run **VOIPSUP-Discovery.ps1** — it lists audio endpoints and the
   PnP audio devices, including any that are **disabled**, **not present**, or in an **error** state.
   Also open **Device Manager** (`devmgmt.msc`) → **Audio inputs and outputs** and **Sound, video and
   game controllers**.
2. **Check for disabled / hidden.** In **Sound Control Panel → Recording/Playback**, right-click → **Show
   Disabled Devices** / **Show Disconnected Devices**. Re-enable the headset if it's disabled.
3. **Check the driver state.** In Device Manager, a yellow bang or "Device cannot start (Code 10/43)"
   means a driver/firmware fault. `VOIPSUP-Discovery.ps1` reports PnP device status/error codes so you
   can spot this without clicking through.
4. **Physical connection.** USB: different port, avoid unpowered hubs, try the headset on another
   machine to isolate cable/device vs port. Bluetooth: remove and re-pair; confirm the **Hands-Free**
   profile is present (not only Stereo/A2DP).
5. **Remediate the driver safely.** `VOIPSUP-Remediation.ps1` can trigger a PnP device rescan and restart
   the audio service (default `-WhatIf`). For a corrupt driver, uninstall the device in Device Manager
   and rescan to reinstall, or deploy the vendor's current headset driver via Intune. **Do not**
   force-install beta firmware from the field — flag firmware updates for controlled deployment.
6. **Still absent after driver rescan and known-good port/cable?** That's a hardware failure → replace
   the headset. Not an escalation to telephony — an endpoint hardware swap.

---

## Symptom E — Jitter / latency / dropped calls (quality degrades or calls drop)

**Most likely: network path — measure it, fix what's local, escalate the rest with data.**

1. **Measure first.** Run **VOIPSUP-Validation.ps1** to capture **latency, jitter, and packet loss** to
   the media-edge target, and **VOIPSUP-Report.ps1** for a readiness summary marked against thresholds.
2. **Connection type.** Move Wi-Fi → wired if at all possible (see Symptom B). On Wi-Fi, check signal,
   band (prefer 5 GHz for calls), and roaming between APs mid-call.
3. **Adapter health.** `Get-NetAdapter` for link speed, errors, and driver state; a flapping or
   half-duplex NIC causes drops. Update the NIC/Wi-Fi driver via Intune if faulty.
4. **Local saturation and power.** Check background bandwidth use and, on laptops, whether aggressive
   **power management** is throttling the Wi-Fi/USB (Device Manager → adapter → Power Management, or the
   power plan). Power-saving on the network/USB radios is a real call-drop cause.
5. **VPN / QoS.** As in Symptom B: confirm DSCP marking on the endpoint (`Get-NetQosPolicy`); deploy the
   QoS policy if absent. If the endpoint is clean and marked but calls still jitter/drop, the problem is
   in the **WAN/LAN QoS enforcement or the platform media path → escalate with the numbers.**
6. **Escalation package.** When links 1–4 are clean, attach the **VOIPSUP-Report.ps1** output (device
   OK, client version current, latency/jitter/loss with timestamps) to the telephony ticket. That's the
   difference between a bounced ticket and a solved one.

---

## Symptom F — Softphone client crashes, hangs, or won't launch / no audio in client

**Most likely: stale/corrupt client, missing permission, or client using the wrong device.**

1. **Version check.** `VOIPSUP-Discovery.ps1` reports the installed client version. Compare against the
   **minimum supported version** from R4. Out-of-date → update via Intune (or the sanctioned installer).
2. **Process health.** `Get-Process` for the client; if it's hung, close it fully (confirm no orphaned
   background process remains) and relaunch. Repeated crashes on launch → likely corrupt install or
   profile.
3. **Microphone permission.** Settings → **Privacy & security → Microphone** — the client (and desktop
   apps) must be allowed. A denied mic permission presents as "no audio in client" even when the device
   is perfect.
4. **Device selection inside the client.** Confirm the client's audio device matches the Windows default
   communication device (or is set to "system default"). A stale pinned device = no/wrong audio only in
   the client.
5. **Repair / reset.** `VOIPSUP-Remediation.ps1` can restart the client and the audio service (default
   `-WhatIf`). For a corrupt install, reinstall via the sanctioned Intune package. Preserve the client's
   **log files** (path from R4) before resetting — they're your escalation evidence.
6. **Crash logs & escalation.** If the client crashes with a clean device, current version, granted
   permission, and correct device selection, capture the client logs and **escalate to the client
   vendor / telephony team** — in-client crash internals are the vendor's domain, not desktop support's.

---

## Closing every ticket

For any branch, the outcome is one of two clean states:
- **Resolved at the endpoint** — you fixed the device, client, or local network; re-test against the
  gates in the Testing guide and confirm with the user on a live call.
- **Escalated with evidence** — links 1–4 are provably clean; you hand the telephony team the
  **VOIPSUP-Report.ps1** output plus what you ruled out. See Best Practices for the escalation template.
