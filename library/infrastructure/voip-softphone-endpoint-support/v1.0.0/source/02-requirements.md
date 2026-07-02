# Requirements

Before you troubleshoot the endpoint side of a VOIP/softphone issue, confirm the prerequisites below.
The category-level prerequisites (Entra tenant, Intune subscription, admin roles, enrollment, pilot
group, Windows baseline, network access) are covered once in **global-requirements-infrastructure.md**
— confirm those first. The items here are **specific to VOIP/softphone endpoint support**. Each entry
follows the same pattern: **Description / Why / Verify / Implement if missing.**

## R1. Endpoint access (local + remote)
**Description:** The ability to run PowerShell on the affected Windows device — either signed in
locally with local-administrator rights, or via a remote-support/Intune remote channel.

**Why:** Every endpoint check (audio-device state, driver status, client version, network path)
executes on the device. Read-only discovery works as a standard user; driver and device remediation
needs local admin.

**Verify:** On the device, open **Windows PowerShell** and run `whoami /groups` — confirm the session
shows an administrators membership for remediation, or confirm your remote-support tool can reach the
device and open a PowerShell session.

**Implement if missing:** Grant the technician account local-admin (or use an Intune/LAPS-managed local
admin), or configure your remote-support tooling to reach enrolled devices. Read-only discovery and
validation can proceed without admin; only remediation requires it.

## R2. Audio-device inventory
**Description:** A known, current list of the audio input and output devices on the endpoint — the
built-in mic/speakers plus any headset, speakerphone, dock, or Bluetooth device — and which one is
**supposed** to be the default communication device.

**Why:** The single most common endpoint cause of "no audio," "one-way audio," or "wrong device" is
that the softphone (or Windows) is using an unexpected device. You cannot judge "wrong device" without
knowing which device is correct.

**Verify:** Settings → **System → Sound** shows the current input and output devices; **Sound Control
Panel → Recording / Playback** shows every device and which is marked **Default Communication Device**.
The **VOIPSUP-Discovery.ps1** script enumerates all audio endpoints and flags the current defaults.

**Implement if missing:** Run **VOIPSUP-Discovery.ps1** to build the inventory automatically, and record
the intended headset model per role/user so "correct device" is defined for each endpoint.

## R3. Network / QoS visibility
**Description:** The ability to measure the local network path from the endpoint — connection type
(wired vs Wi-Fi), adapter health, and jitter/latency/packet-loss toward the media edge — and to see
whether QoS/DSCP marking is applied on the device.

**Why:** Echo, robotic/choppy audio, and drop-outs are frequently network conditions (jitter, latency,
loss), not device faults. You must measure the endpoint's network path to know whether to fix it
locally, apply QoS, or escalate WAN/LAN QoS enforcement to the network/telephony team.

**Verify:** `Get-NetAdapter` shows adapter link speed and status; `Test-Connection`/`ping` and the
**VOIPSUP-Validation.ps1** script report latency and jitter to a target; QoS policy presence is visible
under **Local Group Policy → Policy-based QoS** or via `Get-NetQosPolicy`.

**Implement if missing:** Establish a known good media-edge target to test against, ensure ICMP or an
approved probe is permitted for measurement, and (if QoS is expected) deploy the QoS policy via Intune
or Group Policy so DSCP marking is present on the endpoint.

## R4. Softphone client details
**Description:** Which softphone/VOIP client is deployed, its **expected/minimum supported version**,
its install location, its log location, and how it is deployed/updated (Intune app, MSI, per-user).

**Why:** Client crashes, no-audio-in-client, and codec/quality issues are often stale versions,
corrupt installs, missing microphone permission, or the client using a different audio device than
Windows. You need the expected version and log path to judge client health and to reset it safely.

**Verify:** The **VOIPSUP-Discovery.ps1** script reports installed VOIP/softphone client(s) and their
versions from the installed-programs inventory; Settings → **Privacy & security → Microphone** shows
whether the client (and desktop apps generally) may use the mic.

**Implement if missing:** Document the sanctioned client and its minimum supported version, package it
for Intune deployment/update, and confirm microphone privacy permission is allowed for the client. For
platform-internal client behavior (in-client call settings, server sign-in), defer to the client
vendor's official documentation.

## R5. Baseline "known-good" call state
**Description:** A documented definition of what a healthy call looks like on your endpoints: the
correct default communication device per role, the minimum client version, and the network thresholds
you consider acceptable (e.g., latency and jitter ceilings, packet-loss ceiling).

**Why:** Pass/fail gates (see the Testing guide) require thresholds. Without a baseline you cannot say a
device "passed" — you can only say it "seems fine," which does not survive escalation.

**Verify:** The thresholds are written down and used by **VOIPSUP-Validation.ps1** and
**VOIPSUP-Report.ps1** (they accept threshold parameters and mark PASS/FAIL against them).

**Implement if missing:** Set initial thresholds from your platform vendor's published endpoint network
guidance (latency, jitter, and loss ceilings), record them, and tune after piloting.
