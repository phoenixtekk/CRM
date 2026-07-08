# 7. Best Practices — CJIS DLP Pack (Microsoft Purview)

Field-proven guidance for running CJI Data Loss Prevention in Microsoft Purview so it protects criminal
justice information without breaking case work — and so it holds up in a CJIS audit.

## Simulate first, always
- **Never create a CJI DLP policy straight to enforce.** Start in `TestWithNotifications` /
  `TestWithoutNotifications`, watch what it matches, tune, and promote only after a clean pilot. In a
  law-enforcement tenant an over-broad block on day one blocks live case work.
- **Pilot on a ring, not the tenant.** Scope the pilot to `CJIS Pilot Ring – Stage1` first; expand scope
  only after the ring is clean.
- **`-WhatIf` before `-Commit`, every time.** Preview the change, then apply it in a change window with a
  recorded rollback.

## Detection is 80% of the work
- **Tune for precision, then recall.** CJI-specific classification (custom SIT + keyword evidence, or EDM
  where licensed) beats generic PII SITs. An SSN alone is not CJI — require CJI context so routine HR/admin
  files don't match.
- **Use confidence and instance count as your primary knobs.** Start Medium confidence / low instance
  count in simulation, then tighten until false positives are acceptable.
- **Prefer EDM for known record sets (E5).** Exact Data Match against a controlled CJI identifier export
  gives high precision for specific records — far fewer false positives than pattern matching alone.
- **Re-test detection whenever you change it.** Every SIT/threshold edit is a new simulation cycle with the
  synthetic-CJI and routine-document test sets.

## Cover the channels CJI actually uses
- **Don't stop at email.** CJI leaks through SharePoint/OneDrive sharing, Teams, and endpoints (USB,
  print, cloud upload). Scope the policy to all in-scope workloads; add **Endpoint DLP** once devices are
  onboarded and E5 is confirmed.
- **Make coverage gaps explicit.** If a surface is unlicensed or un-onboarded, record it as a known gap —
  never let "we have DLP" imply coverage you don't have.
- **Watch external sharing specifically.** "Anyone with the link" and external guest access are common CJI
  egress paths; align the DLP action with your sharing controls.

## Enforcement that people can live with
- **Consider block-with-override + justification before hard block.** For borderline scenarios, an
  override with a captured business justification protects data while preserving the audit trail and case
  work; reserve hard block for the highest-risk actions (external send of confirmed CJI).
- **Write policy tips your users understand.** Reference the CJI handling rule in plain language so a match
  educates rather than just frustrates.
- **Tune down false positives fast.** A noisy CJI policy trains users to click through tips; keep the
  false-positive rate low so alerts stay meaningful.

## Separation of duties & privacy
- **Separate who administers DLP from who reviews matched CJI content.** Matched-content review exposes
  the very data you're protecting — restrict it to the least-privilege reviewer role, distinct from the
  policy author.
- **Minimize who can see matched CJI.** Use the Information Protection review roles narrowly; log access.

## Evidence and audit-readiness
- **Produce evidence continuously, not at audit time.** Run `DLPCJIS-Report.ps1` on a cadence so the CJI
  evidence artifact (policy in force, what it detects, matches, actions) is always current.
- **Baseline and watch for drift.** Keep `Policy Baseline – CJIS DLP – <date>` current and run
  `-CompareBaseline` regularly; an unexplained mode change on the CJI policy is a control failure to
  investigate.
- **Record every change.** `Change Record – CJIS DLP – ChangeControl` — who/when/what/from/to — is part of
  the evidence an assessor expects.

## Stay in your lane (defer determinations)
- **DLP is one CJIS control, not the whole program.** FIPS-validated encryption, physical media
  protection, personnel screening/access authorization, and the CJIS audit conclusions live elsewhere in
  the CJIS Security Policy — this pack implements and evidences the DLP control and defers the rest.
- **CJIS/records/legal determinations are not yours to make.** Whether data *is* CJI, the CJI retention
  schedule, and regulatory applicability belong to your CSO/TAC, compliance, records, and legal owners.
  Provide the technical method and evidence; let them make the call.

## Licensing discipline
- **Confirm the plan before you rely on a feature.** Endpoint DLP, EDM, and trainable classifiers are
  E5 / E5 Compliance; some capabilities are preview and the portal evolves. Verify capability and portal
  paths for *your* tenant, and scope the program to what you can actually enforce.
