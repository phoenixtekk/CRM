# Testing

Testing turns "seems fine" into a defensible **PASS/FAIL** result. A VOIP/softphone endpoint is
considered healthy only when all three gates pass: the **correct audio device** is active, the
**softphone client is healthy**, and the **network is within thresholds**. Run these gates after any
remediation and before closing a ticket — and run them again to build the escalation package when the
endpoint is clean but calls still fail.

Use the read-only scripts to gather evidence: **VOIPSUP-Validation.ps1** (per-device audio + network)
and **VOIPSUP-Report.ps1** (VOIP-readiness/quality summary with PASS/FAIL against thresholds).

## Gate 1 — Correct audio device

| Check | How to verify | PASS | FAIL |
|---|---|---|---|
| Intended device is present | `VOIPSUP-Discovery.ps1`; Device Manager → Audio inputs/outputs | The intended headset (from R2) appears and is enabled | Missing, disabled, or in an error state |
| Set as Default Communication Device | `VOIPSUP-Discovery.ps1`; Sound Control Panel (`mmsys.cpl`) | Intended headset is the **Default Communication Device** for both playback and recording | Laptop mic/speaker or another device is the comm default |
| Mic captures, speaker plays | Recording tab level meter moves on speech; a test tone is audible | Meter moves; tone heard | No meter movement or no output |
| Not muted / non-zero levels | Recording/Playback → Properties → Levels | Levels above 0 and not muted | Muted or at 0 |

**Gate 1 passes** when the intended device is present, enabled, set as the communication default, and
actively capturing/playing.

## Gate 2 — Softphone client healthy

| Check | How to verify | PASS | FAIL |
|---|---|---|---|
| Client version | `VOIPSUP-Discovery.ps1` vs minimum from R4 | Installed version ≥ minimum supported | Below minimum / not installed |
| Process runs cleanly | `Get-Process`; launch and place a test call | Launches and stays running; no crash | Crashes, hangs, or won't launch |
| Microphone permission | Settings → Privacy & security → Microphone | Client / desktop apps allowed | Blocked |
| Client uses correct device | Client audio settings | Matches Windows comm default (or "system default") | Pinned to a stale/wrong device |

**Gate 2 passes** when the client is current, stable, permitted to use the mic, and pointed at the
correct device.

## Gate 3 — Network within thresholds

Run **VOIPSUP-Validation.ps1** against the media-edge target from R3/R5. Compare to your baseline
thresholds (set from your platform vendor's endpoint network guidance; defaults below are typical
targets — tune to your platform).

| Metric | Typical PASS target | FAIL indication |
|---|---|---|
| Latency (one-way / round-trip) | Within your platform's published ceiling | Above ceiling → talk-over/echo |
| Jitter | Below your platform's jitter ceiling | Above ceiling → robotic/choppy audio |
| Packet loss | Below your platform's loss ceiling | Above ceiling → drop-outs/gaps |
| Connection type | Wired, or Wi-Fi with strong signal | Weak/congested Wi-Fi |
| QoS/DSCP marking | Present when required (`Get-NetQosPolicy`) | Absent when platform expects marking |

**Gate 3 passes** when latency, jitter, and loss are all within your documented thresholds and QoS
marking is present where required. If Gate 3 fails on WAN/LAN enforcement (endpoint is marked and local
path is clean), that is an **escalation to the network/telephony team**, not an endpoint fix.

## Overall result

- **PASS (all three gates):** the endpoint is healthy. If calls still fail, escalate to the telephony
  team with the **VOIPSUP-Report.ps1** output — the endpoint is provably clean.
- **FAIL (any gate):** remediate that gate (see the Diagnostic Playbook), then re-run all three gates.
  Do not close the ticket on a partial pass.

## Pilot validation

Before fleet-wide use, run the gates on the pilot group built with **VOIPSUP-Set-ScopeTargeting.ps1**.
Confirm the scripts produce consistent PASS/FAIL results across representative hardware (different
headsets, docked/undocked, wired/Wi-Fi) and that thresholds are tuned before you expand.
