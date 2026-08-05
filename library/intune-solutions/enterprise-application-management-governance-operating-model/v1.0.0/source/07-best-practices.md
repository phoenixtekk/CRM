# Best Practices

These are the disciplines that keep the operating model alive after the initial build. Governance
programmes rarely fail at launch — they fail six months later when the board stops meeting and the
register stops being maintained. Each practice below counters a specific way that happens.

## Secure the sponsor before the process, not after

The most common cause of failure is standing up the board before securing R1's executive sponsor. The
first time the board rejects a director's preferred application, an unsponsored board folds and
becomes advisory. Get the sponsorship email in hand, and make sure the sponsor understands that their
job is precisely to absorb that one uncomfortable escalation. One backed rejection in the first
quarter is worth more to the model's credibility than a hundred approvals.

## Make the front door the only door

An intake form that people can route around is theatre. The moment a "just this once, it's urgent"
application bypasses intake, every subsequent requester learns that urgency is the bypass. Handle
urgency **inside** the model — an urgent application is a Tier 3 or Tier 4 change with compressed
dwell times and immediate Security involvement, not an exemption from governance. Have the executive
sponsor, not IT, announce that intake is mandatory; it lands differently.

## Pre-approve the routine so the board can judge the exceptional

The Tier 1 standard-change rule (Step 9, item 7) is not a convenience — it is what keeps the board
viable. If every Chrome version bump needs an ARB slot, the board drowns, meetings overrun, and
people start bypassing it out of sheer friction. Pre-approving low-risk version updates typically
removes 60–80% of the volume and lets the board spend its attention on the decisions that actually
carry risk. Review the standard-change definition quarterly; it should be as wide as is safe.

## Name individuals, never teams

A RACI that says "Endpoint Team" for Technical Owner has no owner. When something breaks, "the team"
is nobody. Every application in the register carries a **named person** in each accountability. When
that person leaves, the register custodian's leaver process reassigns their applications explicitly —
this is the single most valuable maintenance task the custodian performs, because unreassigned
leavers are exactly how applications become orphaned.

## Treat the Security Reviewer as non-negotiable for classified data

The role most often quietly dropped is Security Reviewer, because IT can approve without them and
usually wants to move faster. Resist this. The whole point of the model is that an application
handling `Confidential` or `Restricted` data does not reach production without a security
determination. Build the quorum rule (no Security Reviewer present → such items are deferred) into the
board's standing behaviour so it is automatic, not a judgement call in the moment.

## Ring everything; assign nothing to All Users

Direct assignment to *All Users* or *All Devices* is the single behaviour that makes a bad change
catastrophic. Ringed deployment turns a broken package into a Ring 1 incident affecting a handful of
validators instead of a fleet-wide outage. Enforce it structurally: the deployment engineers'
muscle memory should be "which ring", never "everyone". The validation script flags broad targeting
specifically because it is the highest-leverage risk to eliminate.

## Make rollback approval-free and cheap

The most expensive change-management mistake is requiring approval to roll back. A rollback is always
a safe action — it returns to a known-good state. Requiring a meeting to authorise it converts a
five-minute recovery into a two-hour outage while people are found and convened. State the principle
loudly and repeatedly: **any deployment engineer may roll back any change at any time.** The dwell
times exist precisely so that a rollback is still cheap when you need it.

## Reconcile against reality, not against your own deployment records

Intune tells you what you *deployed*. It does not tell you what is *installed*. Users install
software, legacy images carry software, and departed processes left software behind. The quarterly
reconciliation of Intune Discovered apps (and Defender for Endpoint software inventory where
available) against the register is how you find the ungoverned estate. The "shadow application" count
is uncomfortable precisely because it is honest; track it as a first-class risk metric and drive it
down.

## Publish the scorecard where decisions are made

Metrics reported nowhere change nothing. The governance scorecard (`APPOPS-Report.ps1`) belongs on
the standing agenda of a forum with authority — an IT operations review or a service-management
board — so that a declining ownership-coverage trend prompts action rather than sitting in a folder.
Show the trend, not just the snapshot; the month-over-month direction is what tells you whether the
model is winning or slowly decaying.

## Let the standards document be a living test, not a monument

The standards document (Step 7) is only useful while it reflects reality. After each pilot
retrospective, and at least annually, revise it: tighten a criterion that let a bad app through,
loosen one that generated rework for no risk reduction, and widen the standard-change definition as
your confidence grows. Version it, and record who approved each version. A standards document that
has not changed in two years is either perfect or ignored — and it is not perfect.

## Retire deliberately; a smaller estate is the goal

The model's success is not a bigger, tidier register — it is a **smaller** estate. Every application
carries licence cost, security surface, support load, and review effort. Applications no owner will
claim are applications the organisation does not need; move them to `Deprecated`, communicate a
60-day notice, and retire them. The delta between your Step 1 baseline and your steady-state
scorecard — fewer apps, all owned, all reviewed, all ringed — is the entire business case, so
measure it and report it at the annual review.
