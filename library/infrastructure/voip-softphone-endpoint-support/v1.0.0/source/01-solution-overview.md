# Solution Overview

When a call drops, echoes, or a headset refuses to work, the ticket almost always lands on desktop
support — the team that owns the **endpoint**, not the telephony platform. This solution gives you a
repeatable, root-cause method (and five PowerShell scripts) for the **endpoint side** of enterprise
VOIP and softphone: audio-device selection, headset and driver health, network and QoS conditions on
the device, and the softphone client's own health. The goal is simple: **resolve what desktop support
controls, and escalate the rest to the telephony team with hard evidence** instead of a hunch.

This document is deliberately **vendor-neutral about the telephony platform and softphone client**.
The exact console screens, dial-plan behavior, and server-side call routing of any given platform are
that vendor's domain — defer those internals to the vendor's official documentation. What this
solution authors at precise, click-by-click detail is the **Windows / Intune / endpoint side**, which
is what you actually own.

## The softphone / VOIP endpoint stack

Think of a call on a managed Windows endpoint as a chain. A problem at any link degrades or breaks the
call, and each link has a different owner:

1. **Audio device** — the headset, speakerphone, dock, or built-in mic/speakers. This is where sound
   physically enters and leaves. Covers the physical connection (USB, Bluetooth, 3.5 mm), the device
   driver, and the firmware on the headset itself.
2. **Windows audio subsystem** — which device is selected as the **Default Communication Device**,
   per-app routing, sample rate, exclusive-mode settings, volume/mute state, and the enhancements
   (noise suppression, echo cancellation) Windows or the driver layers on.
3. **Softphone client** — the application that turns audio into VOIP packets: its version, its own
   audio-device selection (which can differ from the Windows default), its microphone/speaker
   permissions, its logs, and whether the process is healthy or crashing.
4. **Network / QoS (endpoint view)** — the local network path the call takes: Wi-Fi vs wired, adapter
   health, jitter, latency, packet loss to the media edge, VPN interference, and whether QoS/DSCP
   marking is actually being applied on the endpoint.
5. **Telephony service (platform side)** — the VOIP platform's servers, media relays, dial plan, and
   carrier trunks. **This link is owned by the telephony vendor/team, not desktop support.**

Desktop support owns links **1 through 4**. Link **5** is the escalation boundary.

## What the endpoint owns vs. what the telephony platform owns

| Concern | Endpoint owns (this solution) | Telephony platform owns (escalate) |
|---|---|---|
| Which mic/speaker is used, and its driver | Yes | — |
| Headset firmware / USB / Bluetooth pairing | Yes | — |
| Windows Default Communication Device | Yes | — |
| Client version, install health, local permissions | Yes | — |
| Local jitter/latency/packet-loss to the media edge | Yes (measure & report) | — |
| QoS/DSCP marking applied on the device | Yes (configure/verify) | Enforcement across WAN/LAN switches |
| Dial plan, call routing, number provisioning | — | Yes |
| Media-relay / SBC / carrier-trunk health | — | Yes |
| Platform-side codec negotiation and server config | — | Yes |
| Account/licensing on the platform | — | Yes |

The line to remember: **if it lives on the Windows device or the network path leaving it, it's yours;
if it lives on the platform's servers or the carrier, it escalates.**

## The root-cause tree (how to think about a call-quality ticket)

Every endpoint-side call-quality investigation follows the same top-down isolation:

```
Call-quality symptom reported
        |
        v
[1] Is the RIGHT audio device selected & healthy?
        |  (correct Default Communication Device? headset recognized? driver OK?)
        |-- NO  --> fix device selection / driver / connection  (ENDPOINT)
        |
        v  YES
[2] Is the SOFTPHONE CLIENT healthy?
        |  (current version? not crashing? using the intended device? permissions granted?)
        |-- NO  --> repair/update/reset client, grant mic permission  (ENDPOINT)
        |
        v  YES
[3] Is the NETWORK / QoS within thresholds?
        |  (jitter/latency/loss OK? wired vs Wi-Fi? VPN? DSCP marked?)
        |-- NO  --> move to wired / fix adapter / apply QoS  (ENDPOINT, partly)
        |            residual WAN/LAN QoS enforcement --> ESCALATE with data
        |
        v  YES  (device good, client good, network good)
[4] The endpoint is clean --> ESCALATE to telephony team WITH EVIDENCE
             (device report, client version, jitter/latency/loss numbers,
              timestamps, and what you already ruled out)
```

The discipline is to **walk the tree top-down and stop at the first broken link** — never guess at the
network when the wrong microphone is selected, and never bounce a ticket to telephony until links 1–4
are provably clean. The scripts in this solution automate the checks at each level: **Discovery**
inventories the audio devices and client, **Validation** tests the selected device and the local
network, **Report** produces a VOIP-readiness/quality summary, **Remediation** applies safe endpoint
fixes, and **Set-ScopeTargeting** builds the pilot group so you validate on a controlled set of
devices before fleet-wide use.

## The repeatable method

Assess → Configure → Pilot → Validate → Expand. Assess the endpoint with **Discovery**; configure the
correct device/client/QoS state and remediate safely with **Remediation**; pilot on a controlled group
built with **Set-ScopeTargeting**; validate against the pass/fail gates with **Validation** and
**Report**; then expand the same checks fleet-wide. Escalation to the telephony team is not a failure
of the method — it is the correct outcome when the endpoint is clean and the evidence points at the
platform.
