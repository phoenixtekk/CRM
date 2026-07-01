# Executive Summary — Epic Go-Live & Command Center Endpoint Readiness Playbook

## The challenge

An Epic go-live — a new install, a major upgrade, or a new-site activation — is one of the highest-stakes events a healthcare organization undertakes. On day 1, clinical staff are learning new software while depending entirely on the device in front of them to deliver care. The endpoint layer — workstations, workstations-on-wheels, exam-room PCs, shared kiosks, and the printers, scanners, and badge readers attached to them — is simultaneously the **most common source of go-live problems** and frequently the **least prepared-for**. When a wristband won't print, a badge tap won't log a nurse in, a device was never enrolled, or a workstation is too slow to chart, the failure lands at the bedside, at the busiest moment, in front of a patient.

## The solution

This playbook makes the clinical endpoint fleet **provably ready** for the activation and **runs the command center** through hypercare until the environment stabilizes. It delivers a complete operating model in five phases:

- **Assess** — build a trusted inventory of every in-scope device and snapshot its current readiness.
- **Prepare / Remediate** — close every gap: enrollment, compliance, the correct Epic client version, printing, peripherals, Imprivata tap-and-go, and login times.
- **Validate (go/no-go)** — a per-device PASS/FAIL sweep rolled into a readiness scorecard that turns thousands of device results into a single, defensible go/no-go recommendation.
- **Command Center (hypercare)** — a defined structure (roles, tiers, dispatch, at-the-elbow support), a rapid-fix triage runbook for the predictable day-1 failures, and clear comms and escalation.
- **Stabilize / Handover** — measurable exit criteria that retire the command center and hand a documented environment to the steady-state service desk.

## What makes it different

- **Readiness is measurable and machine-proven.** Every criterion is a concrete threshold tested by automation, so "ready" means the same thing to everyone and the go/no-go recommendation is backed by evidence, not opinion.
- **Built for clinical speed and safety.** The command-center model puts support at-the-elbow on the units, fixes the clinician's problem *now* (manual fallback, ready spares) and repairs the device later, and treats safety-critical failures (wristband print, medication-administration tap) as a separate, non-negotiable gate.
- **Safe by default.** Discovery, validation, and reporting are read-only; all remediation defaults to a preview mode and changes nothing until explicitly applied, inside an approved window, after a test-device run — fully aligned with HIPAA/HITRUST change control.
- **Reusable.** Every artifact — readiness checklist, go/no-go gate, command-center roster, triage runbook, scorecard — is white-label and carries forward to the next wave, site, or upgrade, so each activation starts ahead of the last.

## What's included

Eight documents plus an executive summary, **five PowerShell automation scripts** (discovery, validation, reporting, remediation, and readiness-group management via Microsoft Intune / Entra and Microsoft Graph), and a hero image — a turnkey package an endpoint team can run end-to-end.

## Business outcome

Fewer day-1 endpoint failures, faster resolution of the ones that occur, a defensible go/no-go decision for leadership, and a clean transition to steady state — protecting clinician productivity and, ultimately, patient care during the most disruptive week in the organization's IT calendar.
