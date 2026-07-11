# 7. Best Practices & Where to Go Next — Workshop: Microsoft Defender for Identity

## Running the workshop well
- **Teach against a pilot/lab, not production privileged identities.** Do the honeytoken and response-rehearsal labs where a mistake is harmless. Expand to production only through the customer's change process.
- **Read-only by default.** The only configuration action is tagging the honeytoken (facilitator). Everything else is discovery, hunting, and reading — keep it that way so learning never disrupts detection.
- **Simulate before you enforce.** Response actions (disable, force reset) are rehearsed and queued for approval, never fired against a production identity during training.
- **Use consistent object names.** The `<Purpose> – <Scope> – <Stage>` convention (e.g. `Honeytoken – Identity Lab – Pilot`) makes the take-home artifacts findable and reusable. Keep it.
- **Save the artifacts.** The three hunting queries, the honeytoken tag, the ISPM shortlist, and the investigation doc are the take-home runbook — make sure every attendee leaves with them.

## Operating MDI well (the habits to instill)
- **Work the entity page first.** Investigation priority + timeline + lateral-movement path answers most triage questions before you open advanced hunting.
- **Treat honeytoken activity as real until disproven.** It is one of the highest-fidelity signals MDI produces — never suppress it.
- **Keep ISPM moving.** Posture recommendations drift as the directory changes; review them on a cadence and track a shortlist rather than trying to fix everything at once.
- **Hunt with saved queries.** Building a small library of saved identity queries (recon, lateral movement, honeytoken) turns ad-hoc investigation into a repeatable practice.
- **Respect the approval gate.** Disruptive response is a security-team decision. The operator's job is a clean, evidenced hand-off — not a unilateral action.
- **Mind licensing and preview.** Some detections/features are license- or preview-gated; confirm what your plan includes and *verify current availability in your tenant* before you promise a capability.

## Common anti-patterns to avoid
- Turning the workshop into an onboarding project (that is a separate solution — keep this one about *operating*).
- Using an active account as a honeytoken (false positives destroy trust in the signal).
- Enforcing ISPM changes mid-workshop without change approval.
- Executing a response action against a production identity "to see what happens."

## Where to go next (adjacent catalog areas)
- **Defender XDR Deployment / Unified Onboarding** — if sensors are not yet fully deployed, or to extend onboarding across endpoint/identity/cloud pillars.
- **Threat Hunting** — go deeper on cross-pillar hunting with KQL beyond the identity tables.
- **SOC / XDR operations** — incident queue management, automation, and SOC process design that consume MDI alerts.
- **Sibling Defender workshops** — Endpoint, Office 365, and Cloud Apps enablement workshops to round out the SOC's operating skills across the whole Defender suite.
- **Defender for Cloud CSPM / Secure Score** — posture management for cloud workloads, complementary to identity posture.

The bottom line: a team that operates MDI with confidence — reading attack paths, recognizing detections, deploying honeytokens, working posture, and running clean, approval-gated investigations — using a runbook they keep and reuse.
