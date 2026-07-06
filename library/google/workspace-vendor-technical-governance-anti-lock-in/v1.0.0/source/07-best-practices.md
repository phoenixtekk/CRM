# 7. Best Practices — Vendor Technical Governance & Anti-Lock-In Playbook

- Hold architectural authority; delegate execution. The single most important discipline: the
  enterprise decides *what the architecture is and whether a design conforms*; the vendor decides
  *how to build it*. Never let disposition authority drift into the "produce a design" or "build"
  rows of the RACI.
- Gate every design, without exception. A design-authority gate only works if it is mandatory. One
  design waved through on schedule pressure teaches every partner the gate is optional.
- Apply the same four criteria every time. Portability, data ownership, standards conformance, exit
  criteria — a fixed bar applied consistently is what prevents lock-in accumulating. Re-arguing the
  bar per design is the same as having no bar.
- Treat exit criteria as a first-class requirement, not an afterthought. "We'll figure out exit
  later" is a fail. A design with no articulable exit is lock-in by definition; require the exit
  path, switching cost, and data-egress story at design time.
- Validate assumptions before they harden. An unchallenged vendor assumption silently becomes a
  design constraint. Log every assumption, mark it validated / unvalidated / rejected, and never let
  an unvalidated one pass into build.
- Prefer standards over proprietary shortcuts. Where an open standard exists (SAML/OIDC/SCIM,
  documented APIs, open data formats), require it — or require a documented, accepted reason for the
  proprietary path. Undocumented proprietary choices are how estates become un-leaveable.
- Make lock-in a design-time decision, not an accident. Some coupling is a legitimate, accepted
  trade. The method's job is to make that trade *explicit and owned* — recorded, reasoned, and
  signed off — never stumbled into.
- Keep the register current. New designs arrive faster than memory tracks on a multi-partner
  program. Re-run discovery on a cadence so nothing is built ahead of the gate unseen.
- Escalate cleanly; grant exceptions explicitly. A rejected design goes up the escalation ladder,
  not around the gate. A time-boxed exception is recorded, dated, owner-accountable, and tracked to
  closure — never a silent waiver.
- Be a good client. A clear, consistent, well-communicated bar makes partners better, not
  adversarial. Vendors deliver better work when they know exactly what "good" is up front.
- Document dispositions for audit and repeatability. Record every design's criteria results,
  disposition, conditions, and exceptions so the estate's architecture and its lock-in posture can
  be explained at any time.
