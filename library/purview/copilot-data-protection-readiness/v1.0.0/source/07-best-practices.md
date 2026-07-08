# 7. Best Practices — Microsoft 365 Copilot Data-Protection Readiness (Microsoft Purview)

## Sequence and safety
- **Remediate before you enable.** The whole point is to shrink oversharing *before* broad Copilot
  rollout. Treat "enable Copilot" as the reward for passing the readiness gates, not the starting point.
  Where Copilot is already live, use interim containment (RSS/RCD) to buy time while you clean up.
- **Pilot every high-impact control in simulation/test/disabled first.** Auto-labeling in **simulation**,
  DLP-for-Copilot in **test**, access changes on the **pilot ring** — validate, then enforce. Never
  enforce a new label/DLP/access change blind across the tenant.
- **One before-state, always.** Capture `Oversharing – Estate – Discovery` and the go/no-go baseline
  before changing anything; it is both your evidence and your rollback target.

## Labels are the primary Copilot control
- **Protect with encryption/usage rights, not just a name.** Copilot honors label **encryption and usage
  rights** — a label that only classifies (no protection) does not stop Copilot from summarizing the
  content for anyone who can open it. For "keep out of Copilot" content, the label must deny the usage
  rights that would let Copilot extract it.
- **Get coverage up with a default label + auto-labeling.** A default label classifies new work;
  simulation-mode auto-labeling catches sensitive content at rest. Together they close the
  unlabeled-sensitive gap that is the root of most Copilot exposure.
- **Mind label inheritance on citations.** Copilot-generated content that cites sources inherits the
  **highest-priority** sensitivity label of those sources — design the taxonomy priority order so this
  produces sensible, not surprising, outcomes.
- **Container-label the collaboration surface.** Labeling SharePoint sites, Teams, and Groups controls
  privacy, external sharing, and the default sharing link — reducing how oversharing gets created in the
  first place. *(Container labeling availability is licensing-dependent — verify.)*

## Fix access, don't just hide it
- **RSS and RCD are stopgaps, not the fix.** Restricted SharePoint Search and Restricted Content
  Discovery keep not-yet-cleaned sites out of Copilot/search **temporarily**. They mask the exposure;
  they do not reduce the underlying access. Track every RSS/RCD-fenced site as remediation debt and
  remove the containment once access is actually fixed.
- **Kill "Everyone Except External Users" broad grants.** EEEU and org-wide sharing are the classic
  Copilot oversharing source. Prioritize sites where broad access overlaps unlabeled sensitive content.
- **Prefer least-privilege groups over ad-hoc links.** Where SAM is licensed, Restricted Access Control
  (limit a site to a named group) and site access reviews drive durable, owner-maintained cleanup.

## Roles, separation of duties, and change control
- **Least-privilege, separated.** Information Protection Admin for labels, the DLP role for DLP,
  SharePoint Administrator for access — reserve Global/Compliance Admin for initial enablement. Reading
  posture and changing policy are different rights.
- **Everything through change control.** Enforcing a policy or restricting a site is a change-controlled
  step with an approver and a recorded rollback.

## Governance boundary
- **You configure and evidence; governance decides.** What counts as "sensitive," what acceptable
  Copilot exposure is, what must be restricted or retained, and the final **go/no-go** are
  compliance/records/privacy/legal determinations. Keep those determinations with their owners and keep
  your role to method + evidence.

## Operate it as a program, not a project
- **Re-measure on a cadence.** Oversharing regrows: new sites, new broad shares, new unlabeled content.
  Run the recurring read-only chain and treat a rising oversharing signal or falling label coverage as a
  trigger to re-remediate before it becomes Copilot exposure.
- **Keep artifact names verbatim.** Reusing the `<Purpose> – <Scope> – <Stage>` names across portal,
  scripts, and reports keeps one artifact traceable end to end and makes the go/no-go auditable.
- **Verify availability every cycle.** DLP-for-Copilot, RSS, RCD, SAM reports, and container/mandatory
  labeling are evolving and licensing-gated — re-confirm they exist and behave as documented in *your*
  tenant rather than assuming last cycle's map still holds.
