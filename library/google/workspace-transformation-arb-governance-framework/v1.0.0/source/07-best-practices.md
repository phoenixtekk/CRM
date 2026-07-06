# 7. Best Practices — Architecture & Design Review Board (ARB) Governance Framework

Field-proven recommendations for running an ARB that has authority without becoming the program's
bottleneck. Adopt these alongside the Implementation and Testing guides.

## Authority
- **Get the mandate in writing before the first meeting.** An ARB with no sponsor backing is a
  discussion group. The written mandate (Requirement 2.1), quoted in the charter, is what makes
  "Rejected" stick.
- **Draw the vendor/enterprise boundary explicitly and early.** The enterprise owns the architecture;
  the vendor executes within it. Put this in the SOW or a governance addendum, not just the charter,
  so the party you do not manage day to day is still bound to the gates.
- **Never open a conformance gate without a ratified baseline.** A gate with no approved standard
  behind it produces opinions, not defensible decisions. Ratify the target architecture first.

## Decision rights
- **Make quorum small enough to meet and senior enough to bind.** A quorum that cannot assemble weekly
  becomes the schedule bottleneck teams route around; one too junior gets overruled later.
- **Separate voting members from advisory reviewers.** Subject-matter experts should review deeply
  without diluting the vote; keep the decision with a tight, accountable voting core.
- **Define escalation before you need it.** Write down what happens on a tie or a design the board
  blocks but delivery insists on — a named escalation to the sponsor, decided in the charter, not in
  the heat of a stalled meeting.

## Gates and cadence
- **Route each design to exactly one gate — its primary risk.** A design that touches identity and
  security goes to the gate for its dominant risk, with the other discipline as an advisory reviewer.
  One design, one gate, one decision keeps the queue legible.
- **Offer a fast-track for low-risk, standard-conformant designs.** Not everything needs a full board.
  A pre-approved pattern (a wave plan identical to an approved template) can be delegated to the chair
  with a lightweight record, reserving board time for genuine architectural choices.
- **Protect time-in-gate as a first-class KPI.** Governance earns its authority by being fast enough
  to trust. If designs pile up undecided, fix cadence or decision rights before adding more gates.

## Decision records
- **Write the ADR at the moment of decision, not later.** Record the design, the standards measured,
  the decision, the rationale, and any conditions while the discussion is fresh. A register
  reconstructed after the fact loses exactly the rationale that makes it valuable.
- **Record conditions and exceptions as first-class facts.** "Approved with conditions" is only real
  if the conditions are written and later verified. An unrecorded condition is an approval.
- **Treat the register as the program's architectural memory.** Every "why did we do it this way?" a
  year from now should be answerable from the `Decision Register - Transformation ARB - Program-Wide`.

## Drift prevention
- **Assume drift; hunt for it on a cadence.** Approved designs diverge from reality under delivery
  pressure. Run the discover-validate-report-remediate loop every cycle rather than trusting that
  what was approved is what was built.
- **Adjudicate every drift finding — do not let it sit.** A Non-Conformant finding is either brought
  back to standard or formally approved as an exception. Silent, un-adjudicated drift is the exact
  failure this framework exists to prevent.
- **Watch the exception count as a health signal.** A rising number of approved exceptions means the
  baseline no longer matches reality — either the standard is wrong (update it deliberately) or
  discipline is slipping (tighten the gate). Exceptions should be rare and deliberate.

## Scope discipline
- **Govern designs, not schedules.** The ARB owns architectural decisions; the PMO owns dates and
  budget. Blurring the two makes the board slow and resented. Stay in the architecture lane.
- **Prove it on a pilot workstream before program-wide rollout.** One workstream's full governance
  cycle exposes whether your cadence, quorum, and templates actually work — cheaper to fix on one
  workstream than across the whole program.
- **Retire the board deliberately at program end.** When the transformation closes, fold the ARB's
  standing decisions and baseline into the enterprise's steady-state architecture governance rather
  than letting the forum simply lapse — so the decisions outlive the program.
