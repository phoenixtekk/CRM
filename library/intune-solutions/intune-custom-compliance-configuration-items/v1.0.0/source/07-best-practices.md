# 7. Best Practices — Intune Custom Compliance & Configuration Items (Scripted)

- **Pilot every check.** Assign a new detection script + rule to a small pilot group first — a bad
  rule or a script error can turn devices noncompliant fleet-wide. This is the single most important practice.
- **Keep the script and rule in lockstep.** Every setting name in the JSON rule must be emitted by
  the detection script. Validate the pairing with `CUSTCOMP-Validation.ps1` before every upload.
- **Emit compact, valid JSON.** Have the detection script return one JSON object with the correct
  data types (int, string, version); a malformed payload reads as an error, not a pass.
- **Measure and set together.** Pair a scripted configuration item that sets the state with a custom
  rule that verifies it — so devices are made correct, then proven correct.
- **Write clear remediation messages.** The user-facing title/description in the rule is what drives
  self-remediation; make it specific and actionable (what to fix, then sync).
- **Sign your scripts.** Treat detection scripts as reviewed, controlled code; sign them or scope
  execution per your standard.
- **Enforce through Conditional Access — carefully.** Require a compliant device, but start in
  Report-only and confirm the effect before turning it On, so a rule mistake can't lock users out.
- **Name artifacts consistently.** Use `<Purpose> – <Scope> – <Stage>` for the script, rule, policy,
  config item, and group, and reuse the names verbatim for auditability.
- **Version your rules.** Record the detection script and JSON rule content per revision so you can
  roll back a change that misfires.
- **Watch the report.** Track custom-compliance status with `CUSTCOMP-Report.ps1` and chase devices
  stuck in error before they age into a Conditional Access block.
