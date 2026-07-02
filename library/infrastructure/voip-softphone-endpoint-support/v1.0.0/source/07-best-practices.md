# Best Practices

The point of this solution is not just to fix calls — it is to fix what the endpoint controls and to
**escalate everything else with evidence**, so tickets stop ping-ponging between desktop support and the
telephony team. These practices keep the method repeatable and make your escalations impossible to
bounce back.

## Work the tree top-down, every time

Resist the urge to "try things." Walk the root-cause tree in order — **audio device → client →
network/QoS → escalate** — and stop at the first broken link. Most call-quality tickets die at the
device or client link; you never reach the network. Guessing at the network while the wrong microphone
is selected wastes everyone's time and produces a weak escalation.

## Define "correct" before you judge "wrong"

You cannot call a device, version, or network condition "wrong" without a documented "right." Keep a
baseline (R2/R4/R5): the intended default communication device per role, the minimum supported client
version, and the latency/jitter/loss thresholds. Pass/fail gates are only meaningful against thresholds.

## Measure the network; never assume it

"It's the network" is the most common — and most often wrong — escalation. Always attach numbers:
latency, jitter, and packet loss from **VOIPSUP-Validation.ps1**, with timestamps and connection type
(wired/Wi-Fi/VPN). A network claim without measurements is a hunch; a network claim with data is an
escalation the network/telephony team can act on immediately.

## Keep the three surfaces coherent

The endpoint has three settings that must agree: the **Windows Default Communication Device**, the
**client's audio device**, and the **physical headset that's actually connected**. Many "wrong device"
and "no audio" tickets are simply these three disagreeing. Set the client to follow the system default
where the client supports it, so there's one source of truth.

## Prefer wired; treat Wi-Fi and VPN as suspects

For call quality, wired beats Wi-Fi, and direct beats VPN. When quality is poor, moving to wired is the
highest-yield single change. Document VPN routing and Wi-Fi conditions when you can't change them — that
context belongs in the escalation.

## Remediate safely: -WhatIf first, then execute

Every change script (**VOIPSUP-Remediation.ps1**, **VOIPSUP-Set-ScopeTargeting.ps1**) defaults to
`-WhatIf`. Read the planned actions, confirm they match your intent, then re-run to execute. Never
push firmware or driver changes from the field ad hoc — flag them for controlled Intune deployment and
pilot them first. On live user devices, prefer the least-disruptive fix that resolves the gate.

## Pilot before fleet-wide

Build a pilot group with **VOIPSUP-Set-ScopeTargeting.ps1** and validate the gates across representative
hardware (different headsets, docked/undocked, wired/Wi-Fi) before expanding. Tune thresholds on the
pilot so fleet-wide PASS/FAIL results are trustworthy.

## Respect the escalation boundary

Desktop support owns the device, the client install, and the local network path. The **dial plan, call
routing, media relays/SBC, carrier trunks, server-side codec negotiation, and account/licensing** are
the telephony platform's domain. For client-internal crashes and platform console behavior, defer to
the vendor's official documentation. Escalating a clean endpoint is the *correct* outcome — not a
failure.

---

## Evidence-based escalation to the telephony team

When links 1–4 are provably clean, escalate — but never empty-handed. Attach the **VOIPSUP-Report.ps1**
output and a short summary using this template:

**Escalation summary — VOIP/softphone endpoint verified clean**

- **User / device / date-time of tests:** who, which endpoint, when (with time zone).
- **Symptom:** exact user-reported behavior (no/one-way audio, echo/robotic, jitter, drops, crash) and
  whether it's every call or intermittent.
- **Gate 1 — Audio device:** PASS. Intended device present, enabled, set as Default Communication Device,
  capturing/playing. (Attach Discovery output.)
- **Gate 2 — Client:** PASS. Client version (≥ minimum supported), process stable, mic permission granted,
  client using the correct device.
- **Gate 3 — Network:** measured latency / jitter / packet loss with the values and thresholds, connection
  type (wired/Wi-Fi/VPN), and whether DSCP marking is present. (Attach Validation/Report output.)
- **Ruled out at the endpoint:** the specific endpoint causes you eliminated (device, driver, permission,
  client version, local congestion, Wi-Fi, QoS marking).
- **Ask:** what you need the telephony team to check (e.g., media-relay/SBC health, dial-plan routing,
  WAN/LAN QoS enforcement, server-side codec), given the endpoint is clean.

This turns "please look at this" into "the endpoint is verified clean; here is the data; the problem is
on your side of the boundary" — which is what gets call-quality issues actually resolved.
