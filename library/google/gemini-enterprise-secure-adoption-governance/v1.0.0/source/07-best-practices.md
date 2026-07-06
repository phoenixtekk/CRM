# 7. Best Practices — Gemini Enterprise: Secure Adoption, Guardrails & Data-Access Boundaries

Field-proven recommendations for safe, compliant AI adoption.

- **Fix oversharing first, then turn on Gemini.** Gemini exposure equals what the user can access —
  remediating broad Drive sharing is the single most important thing you do, and it must come before
  enablement, not after.
- **Assess with data, not assumptions.** Run `GEMGOV-Discovery.ps1` and `GEMGOV-Report.ps1` to get a
  real baseline of broad, external, and unprotected content before you touch anything, and cross-check
  with the security investigation tool.
- **Remediate with owners, safely.** Preview every change with `-WhatIf`, review broad grants with the
  content owners, and remove public/domain-wide links — but don't silently strip access people depend on.
- **Protect the crown jewels with DLP + IRM.** DLP rules that apply IRM (prevent download/print/copy)
  stop Gemini from retrieving your most sensitive files; use **Client-Side Encryption** where content
  must be indecipherable to any assistant, including Google's.
- **Bound the grounding surface.** Use the **"Allow Gemini Enterprise to access Google Workspace
  data"** control and **Trust rules in Drive** so Gemini grounds only in the right data — scoped to the
  pilot first.
- **Always pilot with a curated OU/group.** A small `Gemini Adoption – Pilot Users – Pilot` scope with
  service and data-access targeting catches exposure problems before the whole org can hit them.
- **Prove it with exposure probes.** The pilot gate is not "Gemini works" — it is "Gemini cannot
  surface what it shouldn't." Test that explicitly, including IRM- and CSE-protected content.
- **Align use cases to policy.** Map each approved use case to the data it may ground in and the policy
  that permits it — so "what Gemini is used for" and "what governance allows" are the same list.
- **Govern the humans, not just the data.** Publish an acceptable-use policy, require review of
  AI-generated output, and name owners for governance, DLP/IRM, and AI use.
- **Partner with security and legal early.** Confirm data handling, retention, and how Google
  processes Gemini data (no training on your data without permission; interactions stay in your org)
  before pilot users get access — get sign-off, not surprises at audit.
- **Verify every Gemini specific in your tenant.** Gemini Enterprise editions, admin pages, and
  connectors are evolving / partly preview — confirm each toggle for your edition and defer volatile
  specifics to Google's documentation rather than assuming.
- **Stop the drift.** Stand up recurring access reviews, re-run discovery on a schedule, and monitor
  the security investigation tool so oversharing does not creep back after Gemini is live.
- **Document the cadence.** Record the remediated scope, DLP/IRM rules, the data-access boundary, the
  use-case-to-policy map, and the pilot → expansion waves for audits and repeatability.
