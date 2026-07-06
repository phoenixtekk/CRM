# 1. Solution Overview — Vendor Technical Governance & Anti-Lock-In Playbook

## Why this exists
On a large Google Workspace and Gemini transformation, the people doing the work are usually not
you. Google's own delivery teams and one or more systems integrators drive the design, the
migration, and the integration build. That is fine — it is what they are good at — but it creates a
quiet, structural risk: the enterprise can lose architectural control. Decisions get made inside
vendor design documents, defaults get accepted because challenging them slows the schedule, and
proprietary shortcuts get baked in because they are the fastest path for the party being paid to
finish. Six months later the enterprise owns an estate it did not really design, cannot easily
change, and cannot leave.

This playbook makes the enterprise architect the **primary technical counterpart** to those
partners. It is a repeatable operating model: validate vendor assumptions before they harden,
review vendor designs against the target architecture, apply an explicit anti-lock-in bar to every
design, and keep a clean separation between **vendor execution responsibility** and **enterprise
architectural authority**. Partners still deliver the work — but they deliver work that aligns to
the architecture the enterprise owns.

## The operating model — where authority sits
The relationship has two distinct roles, and the whole method depends on not blurring them.

- **Vendor execution responsibility.** Google and the systems integrators are responsible for
  *how the work is built and delivered* — the migration runbooks, the integration code, the
  configuration effort, the schedule. They are accountable for delivering to specification, on
  time, and to quality.
- **Enterprise architectural authority.** The enterprise architect is responsible for *what the
  target architecture is and whether a proposed design conforms to it* — the standards a design
  must meet, the anti-lock-in criteria it must satisfy, and the sign-off that lets a design proceed
  to build. This authority is **not** delegable to a vendor. A vendor may propose; the enterprise
  disposes.

The mechanism that keeps this clean is a **design-authority gate**: no vendor design proceeds to
build until it has been reviewed against the target architecture and the anti-lock-in criteria and
has been dispositioned (Approved / Approved-with-conditions / Rejected) by the enterprise. The
gate is the point where architectural authority is actually exercised, not just asserted.

## The artifacts this method names and reuses
The playbook works because it names a small set of durable artifacts and uses them on every design:

- **Target Architecture Baseline** — the enterprise's own statement of the intended end state
  (identity model, data ownership, integration patterns, standards, exit posture). Every vendor
  design is judged against this, not against the vendor's convenience.
- **Anti-Lock-In Criteria** — the fixed checklist every design must pass: **portability**,
  **data ownership**, **standards conformance**, and **exit criteria** (see §3). These are the
  non-negotiable bar.
- **Vendor Assumption Log** — the running list of assumptions a vendor design depends on, each
  marked validated / unvalidated / rejected, so an unchallenged assumption cannot silently become a
  design constraint.
- **Design Review Record** — the per-design finding sheet: what was reviewed, which criteria passed
  or failed, the disposition, and the conditions attached.
- **Governance RACI** — the one-page map of who is Responsible, Accountable, Consulted, and
  Informed for each decision type, drawing the execution-vs-authority line explicitly (see §3).
- **Vendor-Governance Runbook** — the repeatable procedure the enterprise runs for each incoming
  design (see §8).

## What "good" looks like
- Every vendor design is reviewed against the same criteria, by the same method, with a recorded
  disposition — not approved by schedule pressure or by whoever was in the room.
- Assumptions are surfaced and validated *before* they harden into the build.
- Lock-in is caught at design time, when it is cheap to change, instead of discovered at exit, when
  it is expensive or impossible.
- The enterprise can always answer three questions about any part of the estate: *who owns the
  data, how would we move it, and what standard does it conform to.*

## Benefits
- **Held architectural control** — authority stays with the enterprise; vendors execute against a
  design the enterprise owns and signed off.
- **Anti-lock-in by default** — portability, data ownership, standards, and exit are checked on
  every design, so proprietary dependencies do not accumulate unnoticed.
- **Fewer surprises** — validated assumptions and reviewed designs mean fewer late reversals and
  less rework.
- **Durable partner relationships** — a clear, consistent bar makes the enterprise a better client:
  vendors know exactly what "good" is and can deliver to it.
- **Repeatability** — a governance method you run on every design and every partner, not a one-off
  architecture review.

## Limitations (be honest with buyers)
- This is a **governance and review method**, not a replacement for the vendor's delivery
  capability or for a full architecture practice. It makes vendor work conform; it does not do the
  vendor's work.
- Applying the anti-lock-in bar can slow an individual design or require a partner to rework a
  proposal — that friction is the point, but it is real and must be managed through the escalation
  path (§3), not by waiving the gate.
- The included scripts inventory and validate the *artifacts* of vendor delivery (design register,
  and vendor-created objects readable in the Microsoft 365 / Entra source environment); they do not
  audit the internal correctness of a partner's proprietary build — that stays a human review
  against the criteria.
- Anti-lock-in reduces switching cost; it does not make any enterprise platform costlessly
  portable. Some coupling is a deliberate, accepted trade — the method makes that trade *explicit
  and owned* rather than accidental.

## The standard deployment model
> Assess the current partner operating model and target architecture -> Configure the governance
> gate, RACI, and anti-lock-in criteria -> Pilot the review method on a first vendor design ->
> Validate that designs are dispositioned and conform -> Expand the gate across all partners and
> workstreams. Repeatable pattern: **Assess -> Configure -> Pilot -> Validate -> Expand.**
