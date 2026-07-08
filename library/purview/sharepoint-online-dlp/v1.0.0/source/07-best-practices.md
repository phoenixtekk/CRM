# 7. Best Practices — SharePoint Online DLP (Microsoft Purview)

- **Test mode first; enforce deliberately.** The single most important discipline: create every DLP policy
  in **test mode**, review what it *would* match and block on real content, tune it, and enforce only
  after approval. Enforcing an untuned policy blocks legitimate collaboration and fills the help desk.
- **Match on content, not just location.** DLP's value is inspecting what a document *contains* — sensitive
  information types, labels, keywords. Lead with content conditions so a customer-PII document is protected
  wherever it lands, not just in one locked-down site.
- **Which content is sensitive is a compliance determination.** The sensitive info types, labels, and
  sharing conditions come from compliance/security/privacy. Configure the rules they specify; capture the
  determinations and approvers in `DLP Scope – Map`.
- **Use policy tips to teach, not just block.** A tip at the moment of sharing ("this document contains
  regulated data — external sharing is restricted") prevents mistakes and trains users. Design the tip
  text deliberately; it's the most visible part of the policy.
- **Tune false positives before enforcing.** Every false positive that blocks legitimate work erodes trust
  in DLP. Use the test-mode pilot to find and except them (or tighten conditions) so enforcement lands on
  real sensitive content only.
- **Right-size the sharing conditions.** "Block all external sharing everywhere" is rarely the intent; the
  intent is usually "don't let *sensitive* content be shared externally." Combine the content condition
  with the sharing condition so the block is targeted.
- **Pilot on a limited scope first.** Prove the policy on `SPO DLP – Pilot Sites – Stage1` before scoping
  to the estate. Match behavior and false-positive rates are easier to reason about on a bounded scope.
- **Coordinate with sensitivity labels and lifecycle.** DLP can *use* a sensitivity label as a condition,
  and it complements — but doesn't replace — retention/cleanup and item labeling. Deploy them together and
  keep each doing its own job.
- **Design notifications and alerts, not just blocks.** User notifications, admin alerts, and incident
  reports are what make DLP operable. Decide recipients and thresholds up front so a match produces a
  response, not just a log line.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write behind `-WhatIf` → `-Commit`; enforcement behind its own explicit `-Action Enforce`.
  Sign in interactively; no credentials or secrets in a script or a document.
- **Re-report and re-tune on a schedule.** New sensitive content and sharing patterns appear constantly.
  Re-run `DLPSPO-Report.ps1` and review matches periodically so `SPO DLP – Coverage Report` stays a live
  evidence artifact and the policy stays accurate.
- **Keep determinations with their owners.** The solution configures and evidences DLP; which content is
  sensitive, which sharing is acceptable, and any regulatory obligation are determinations for compliance,
  security, and privacy. Keep that separation explicit.
