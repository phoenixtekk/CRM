# Deliverables Summary

This solution is a complete, reusable toolkit for the **endpoint side** of enterprise VOIP/softphone
support. It pairs a symptom-driven method with five PowerShell scripts so desktop support can resolve
the call-quality tickets it controls and escalate the rest with evidence.

## Documents

| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | The softphone/VOIP endpoint stack (audio device → client → network/QoS → service), what the endpoint owns vs. the telephony platform, and the root-cause tree. |
| **02 — Requirements** | Each prerequisite (endpoint access, audio-device inventory, network/QoS visibility, softphone client details, known-good baseline) with Description / Why / Verify / Implement-if-missing. |
| **03 — Diagnostic Playbook** | The symptom tree — no/one-way audio, echo/robotic, wrong default device, headset not recognized, jitter/latency, client crash — with exact endpoint-side checks per branch. |
| **05 — Testing** | Pass/fail gates: correct device, client healthy, network within thresholds. |
| **06 — Troubleshooting** | Fixes for the scripts and the checks themselves when they don't behave. |
| **07 — Best Practices** | Evidence-based escalation to the telephony team, including the escalation template. |
| **Global Requirements (Infrastructure)** | The category-level prerequisites shared by all Infrastructure solutions. |

## Scripts

All scripts share a standard header (PURPOSE / HOW TO RUN / EXPECTED RESULTS). Discovery, Validation,
and Report are **read-only**. Remediation and Set-ScopeTargeting **default to `-WhatIf`** — they show
planned actions until you explicitly execute.

| Script | Role | Mode |
|---|---|---|
| **VOIPSUP-Discovery.ps1** | Inventory audio input/output devices (defaults, PnP status) and the installed softphone client + version. | Read-only |
| **VOIPSUP-Validation.ps1** | Per-device audio checks plus network measurement (latency, jitter, packet loss) against thresholds. | Read-only |
| **VOIPSUP-Report.ps1** | VOIP-readiness / call-quality summary marking each gate PASS/FAIL — the escalation package. | Read-only |
| **VOIPSUP-Remediation.ps1** | Safe endpoint fixes: set the Default Communication Device, restart the audio service, rescan devices, restart the client. | `-WhatIf` default |
| **VOIPSUP-Set-ScopeTargeting.ps1** | Build/assign the pilot security group via Microsoft Graph so you validate on a controlled set first. | `-WhatIf` default |

## How they fit the method

Assess with **Discovery** → validate the endpoint and network with **Validation** → summarize gates
with **Report** → apply safe fixes with **Remediation** → pilot on a controlled group with
**Set-ScopeTargeting**, then expand. Resolve at the endpoint, or escalate with the Report output.

## Outcome

Call-quality and softphone tickets resolved at the endpoint — or escalated to the telephony team with
hard evidence — using a repeatable method and scripts your support team keeps and reuses.
