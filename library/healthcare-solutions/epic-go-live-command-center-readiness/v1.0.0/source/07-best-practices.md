# 7. Best Practices — Epic Go-Live & Command Center Endpoint Readiness Playbook

These practices are the accumulated discipline that separates a smooth endpoint activation from a chaotic one. They reinforce the phase model and the named artifacts; apply them across Assess → Prepare/Remediate → Validate → Command Center → Stabilize.

---

## Readiness standard and validation

- **Make "ready" measurable, then automate the check.** Every readiness criterion should be a concrete threshold (exact client version string, login-time in seconds, named compliance policy) so a script can test it and two people get the same answer. Subjective readiness is unprovable readiness.
- **Validate against a denominator you trust.** Reconcile the in-scope inventory three ways (Intune/Entra, asset/CMDB, physical floor walk) before validation. A wrong denominator makes a 98%-ready report a lie.
- **Re-run the sweep, don't patch the report.** When a device is fixed, re-run `EPICGOLIVE-Validation.ps1`; never hand-edit a PASS into the scorecard. The scorecard's credibility at the go/no-go gate depends on it being machine-generated.
- **Separate read-only from state-changing, always.** Discovery, validation, and reporting are safe any time. Remediation defaults to `-WhatIf` and only acts with `-Apply`, in a window, after a test-device run. Keep that line bright.
- **Weight safety-critical failures differently.** A 99% PASS rate with one broken wristband printer on the affected unit is not a go. Track safety-critical checks (wristband/label print, med-admin tap) as a separate gate item, not blended into the percentage.

## Targeting and change safety

- **Target everything through the readiness device group.** Validation, remediation, and deployments all scope to **Readiness Device Group – Clinical Fleet – Validation**. Never run an ad-hoc scope at go-live — group targeting is what stops a fix from sweeping unrelated production devices.
- **Keep the group in sync with reality.** Devices get added and swapped during prep; re-preview membership with `EPICGOLIVE-Set-ReadinessGroup.ps1 -WhatIf` and reconcile to the inventory regularly.
- **Snapshot before you change.** The discovery/report scripts produce the before-state that is also your rollback baseline (GR7). Capture it before any `-Apply`.
- **Respect the freeze.** Around go-live there is usually a change freeze. Default to read-only, schedule any change into an approved window, and clear it with the Epic program.

## Command center

- **Staff for the floor, including nights and weekends.** The most common command-center failure is an unstaffed night shift on day 1. The roster covers every unit and every shift or it isn't done.
- **Put bodies on the units (at-the-elbow).** A nurse who can turn and ask a walker resolves an issue in seconds that would otherwise become a ticket. ATE coverage is the highest-leverage staffing decision.
- **Dispatch, don't swarm.** One dispatcher classifies and routes; engineers don't self-assign or cluster on the loud issue. A clear dispatch model keeps response times predictable.
- **Fix now, repair later.** At the bedside, restore the clinician's ability to work *immediately* — manual-login fallback, swap in a ready spare — then remediate the failed device off the floor. Don't make a clinician wait while you root-cause.
- **Watch for patterns, not just tickets.** Many identical failures on one unit at one time is a back-end event (Imprivata, network, print server), not N device problems. Escalate the pattern; don't fix it device-by-device.
- **Feed the runbook forward.** When a new fix is found, write it into the **Rapid-Fix Triage Runbook – Day-1 Endpoint – Hypercare** so the next shift inherits it. The runbook should be smarter at the end of hypercare than at the start.

## Comms and escalation

- **Define safety-critical up front.** Everyone — dispatcher, ATE, lead — must know which issues jump straight to the top of the ladder (anything blocking medication administration, patient ID, or wristband printing). Ambiguity here costs minutes that matter.
- **One voice to the program.** The command-center lead is the single endpoint-domain contact for the Epic program. Many channels into the program create conflicting status.
- **Report trends on a cadence.** A short, scheduled huddle (shift change) reporting volume, top issues, and direction beats a flood of one-off updates and gives leadership a real picture.
- **Escalate cleanly across teams.** Pre-establish the Tier-3 contacts (Epic application, Imprivata, network, print) so a cross-team escalation reaches the right person on the first hop, not after three transfers.

## Compliance and governance

- **No ePHI in any export.** Reports carry device and posture metadata only. Verify every CSV before it leaves the team (GR3).
- **Change-record every state change.** Even at go-live speed, remediations and deployments go through change control with a recorded rollback. Speed and auditability are not in tension if the runbook is prepared.
- **Least privilege, even under pressure.** Use the minimum role/scope needed; don't reach for Global Admin to move faster. Keep a break-glass account for genuine emergencies.

## Handover and reuse

- **Exit on criteria, not on exhaustion.** Retire the command center when the **Hypercare Exit Criteria – Endpoint Domain – Handover** are met — not when the team is tired and not "two weeks, because that's what we said." Measure, then decide.
- **Hand over a package, not a hallway conversation.** Open items with owners, known issues with workarounds, the updated runbook, the final scorecard. The service desk should be able to run day-N without the command-center team in the room.
- **Treat every artifact as reusable.** The checklist, gate, roster, runbook, and scorecard are assets for the next wave, site, or upgrade. Update them with what you learned so the next activation starts ahead of where this one did.
- **Run the retrospective while it's fresh.** Capture what to change immediately after stand-down; memory of a go-live fades fast and the lessons are the most valuable output.
