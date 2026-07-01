# 1. Solution Overview — Epic Go-Live & Command Center Endpoint Readiness Playbook

## What this solution is

This playbook turns the clinical endpoint fleet into a **go-live-ready state** for an Epic activation — whether a brand-new Epic install, a major upgrade, or a new-site / new-facility activation — and then **runs the command center** through hypercare until the environment stabilizes into normal operations. It is a repeatable operational playbook, not a one-time runbook: every artifact it defines is reusable for the next wave, the next hospital, or the next upgrade.

The solution covers the full arc an endpoint team owns around an Epic go-live:

- **Pre-go-live device readiness** — a concrete, measurable readiness standard for every clinical workstation, WOW (workstation-on-wheels), exam-room PC, shared kiosk, and clinical peripheral, plus a **validation sweep** that proves each device meets it (correct Epic client version, working printing, attached/working peripherals, Imprivata tap-and-go, acceptable login times, current compliance posture).
- **A go/no-go decision gate** — an evidence-backed checklist that converts thousands of individual device results into a single defensible go/no-go recommendation for the Epic program leadership.
- **Command-center operations** — the structure, roles, tiers, dispatch model, and at-the-elbow support pattern that staffs the activation and triages issues at the speed a live clinical floor demands.
- **A rapid-fix triage runbook** — step-by-step fixes for the handful of endpoint problems that cause the overwhelming majority of day-1 tickets: login/SSO failures, printing failures, not-enrolled / non-compliant devices, and slow performance.
- **Comms and escalation** — who is told what, when, and how an endpoint issue escalates from at-the-elbow to command center to the Epic application or infrastructure teams.
- **Hypercare-to-steady-state handover** — the criteria and the handoff that retire the command center and move ownership to the standing service desk.

> This playbook is **endpoint-focused**. It deliberately does not re-document deep Epic client configuration, Imprivata appliance setup, or workstation image standardization — those live in their own dedicated solutions (see *Related solutions* below) and are referenced wherever a deep dive is needed.

## The problem it solves

An Epic go-live is one of the highest-stakes events a healthcare organization runs. Clinical staff are simultaneously learning new software *and* depending on the device in front of them to do their jobs at the bedside. When the endpoint fails — the printer won't print a wristband, the badge tap won't log the nurse in, the workstation is too slow to chart, or the device was never enrolled and can't reach Epic — the failure lands at the worst possible moment, on the busiest possible day, in front of a patient.

Endpoint problems are also the **most common and most visible** category of go-live tickets, yet they are frequently the **least prepared-for**. Application training gets months; the devices often get a rushed, undocumented check the week before. Without a defined readiness standard, a validation sweep that proves it, and a command center built to triage at clinical speed, the endpoint layer becomes the bottleneck that drags down an otherwise well-run activation.

This solution closes that gap. It gives the endpoint team a defensible standard, the tooling to prove the fleet meets it, a command-center operating model staffed for the floor, and a triage runbook that resolves the predictable day-1 failures in minutes instead of hours.

## Who this is for

- **Endpoint / EUC (end-user computing) and desktop engineering teams** who own the clinical device fleet and are accountable for its readiness at go-live.
- **Epic go-live / activation program leadership** who need an evidence-backed go/no-go recommendation for the endpoint domain.
- **Command-center leads and dispatchers** who run the activation floor and need a defined structure, roster, and triage runbook.
- **At-the-elbow (ATE) support staff and floor walkers** who need a fast, consistent way to fix the common endpoint failures and to escalate the ones they can't.
- **Service desk and operations leadership** who will inherit the environment at hypercare exit and need a clean handover.

## Scope

**In scope**

- Defining and applying a **device readiness standard** for clinical endpoints (workstations, WOWs, exam-room PCs, shared/kiosk devices, and attached clinical peripherals).
- A **validation sweep** that proves readiness per device: Epic client version present and correct, printing functional, peripherals attached and working, Imprivata tap-and-go functional, login time within target, device enrolled and compliant.
- A **go/no-go gate** that aggregates per-device results into a readiness scorecard and a go/no-go recommendation.
- **Command-center structure**: roles, support tiers, the dispatch model, and the at-the-elbow support pattern.
- A **rapid-fix triage runbook** for the highest-volume day-1 endpoint problems.
- **Comms and escalation** paths during activation.
- **Hypercare-to-steady-state handover** criteria and handoff.
- Five PowerShell helper scripts (discovery, validation, reporting, remediation, and readiness-group management) that automate the read-only evidence-gathering and the safe remediation actions this playbook depends on.

**Out of scope (referenced, not re-documented)**

- Deep Epic Hyperdrive / Hyperspace client packaging, configuration, and deployment internals.
- Imprivata OneSign appliance, agent, and policy configuration internals.
- Master workstation image build and standardization internals.
- Epic application build, training-environment content, and clinical workflow design.
- Network, print-server, and Citrix/VDI back-end architecture (touched only where an endpoint symptom points to them).

## Approach — the phase model

This playbook follows the same five-phase model used across the Healthcare Solutions category, so teams running multiple solutions see one consistent operating rhythm:

1. **Assess** — inventory the in-scope fleet, capture a readiness snapshot of current state, and identify every gap against the readiness standard. Nothing is assumed ready.
2. **Prepare / Remediate** — close the gaps: enroll missing devices, push the correct Epic client version, fix printing and peripherals, confirm Imprivata, and bring devices into compliance. All remediation is read-only / `-WhatIf` by default and only changes state when explicitly applied.
3. **Validate (go/no-go)** — run the validation sweep to produce a PASS/FAIL per device, roll the results into the readiness scorecard, and walk the go/no-go gate to a documented recommendation.
4. **Command Center (hypercare)** — stand up the command center with its roster, tiers, dispatch, and at-the-elbow model; run the triage runbook against live day-1 issues; execute the comms and escalation plan.
5. **Stabilize / Handover** — measure against the exit criteria, retire the command center, and hand the environment to steady-state service-desk ownership with documentation intact.

## Named artifacts this playbook produces

Every artifact below is named with the convention `<Purpose> – <Scope> – <Stage>` and is referred to by that exact name throughout the playbook, so a name written in one document means the same object everywhere:

- **Endpoint Readiness Checklist – Clinical Fleet – Pre-Go-Live** — the device-level readiness standard.
- **Go/No-Go Gate – Endpoint Domain – Activation** — the aggregated decision checklist.
- **Readiness Scorecard – Clinical Fleet – Validation** — the per-device and rolled-up PASS/FAIL report (produced by `EPICGOLIVE-Report.ps1`).
- **Command Center Roster – Endpoint Support – Hypercare** — roles, tiers, dispatch, and on-call coverage.
- **Rapid-Fix Triage Runbook – Day-1 Endpoint – Hypercare** — the common-problem fix procedures.
- **Comms & Escalation Plan – Endpoint Domain – Activation** — who-tells-whom and the escalation ladder.
- **Hypercare Exit Criteria – Endpoint Domain – Handover** — the steady-state handover gate.
- **Readiness Device Group – Clinical Fleet – Validation** — the dynamic/assigned device group the sweep and remediation target (managed by `EPICGOLIVE-Set-ReadinessGroup.ps1`).

## What you get

- **8 source documents** (this overview, requirements, category-wide global requirements, implementation, testing, best practices, troubleshooting, deliverables summary) plus an executive summary.
- **5 PowerShell scripts** that automate discovery, validation, reporting, remediation, and readiness-group management against Microsoft Intune / Microsoft Entra via Microsoft Graph.
- A **hero image** for the listing.

## Related solutions (deep config lives here)

- **Epic client deployment & standardization solution** — for Hyperdrive/Hyperspace packaging, version management, and deployment rings.
- **Imprivata tap-and-go / SSO solution** — for OneSign agent, enrollment, and policy configuration.
- **Clinical workstation standardization solution** — for the master image, baseline, and hardware standards.

This playbook references those solutions wherever a step needs deep configuration; it focuses on getting the fleet **ready, validated, and supported** through the activation event itself.
