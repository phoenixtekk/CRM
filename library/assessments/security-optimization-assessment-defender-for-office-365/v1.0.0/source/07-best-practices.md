# 7. Best Practices — Security Optimization Assessment: Defender for Office 365

Field-proven guidance for running this assessment cleanly, keeping it honest, and turning the output into action.

## Keep it strictly read-only
- **Assess with Global Reader / View-Only Configuration, never an admin role.** If the identity can edit a policy or remove an allow-list entry, the assessment is no longer provably non-disruptive. `SOAMDO-Validate.ps1` fails if a write capability is present — keep it that way.
- **Never remove a bypass mid-assessment.** Pulling a transport rule or allow-list entry the moment you spot it breaks the point-in-time snapshot and can break legitimate mail flow. Record it as a finding; fix it pilot-first in the Remediation Playbook.

## Hunt the bypasses — they are the highest-value findings
- **Transport rules are where protection quietly dies.** A single rule setting **SCL -1** or skipping filtering for a domain can neutralize MDO for whole populations. Always enumerate and rank them.
- **The Tenant Allow/Block List and per-policy allow lists accumulate.** Vendors get allow-listed "temporarily" and never removed. Treat broad or stale allow entries as findings.
- **Connection-filter IP allow lists bypass spam filtering entirely** — check them explicitly.
- **A disabled protection is worse than a weak one** — surface any protection turned off.

## Score the effective policy, not the intent
- **Resolve priority and recipient scope.** "A Strict anti-phish policy exists" is meaningless if it is outranked or does not cover the right recipients. Always compute the **effective** policy per recipient.
- **Prefer preset Standard/Strict as the reference.** Presets are Microsoft-maintained and drift-resistant; a sprawl of custom policies is a hygiene finding in itself. *Preset behavior evolves — re-confirm each run.*
- **Safe Attachments in Monitor is not protection** — it detonates but delivers. Flag Monitor where Block is expected.
- **Score MDO-only features as N-A on EOP-only tenants**, but list them as coverage findings — it is a licensing decision, not a misconfiguration.

## Make the numbers defensible
- **Supply the expected mailbox count** so coverage has a real denominator and "covered by nothing" is visible.
- **Name the baseline and date in the report.** A percentage without its reference is not defensible.
- **Reconcile the top findings against the portal every run** — one wrong finding (especially a bypass) undermines the report's credibility.

## Hand off well
- **Lead the review with the bypass findings** — they are the fastest, highest-impact fixes and the ones owners most often did not know existed.
- **Let the customer own risk-acceptance.** Some allow-list entries are deliberate; annotate them as accepted exceptions so they are not re-flagged each run.
- **Re-run on a cadence** and show the bypass list shrinking — that is the clearest proof the program is working.

## Protect the output
- The report names exactly who is under-protected and every bypass — store it in the restricted location (R7), share on a need-to-know basis, and never email it broadly.

## Where to go next (adjacent catalog areas)
- **Remediation Playbook (SOAREM)** — the paired, pilot-first solution that *closes* these findings (tighten policies, remove stale bypasses), then you re-score.
- **DEFMDOP2** — EOP/MDO build and hardening if the assessment shows the protection design itself is weak.
- **THREATHUNT** — proactive hunting over `EmailEvents` once posture is solid.
- **SOCXDR** — SOC onboarding for the alerts MDO generates. *IR determinations belong to the SOC.*
- **Security Optimization Assessment — Defender for Endpoint / Identity / Cloud Apps / Cloud / Defender Suite** — the sibling assessments; run the **Defender Suite** assessment for a single cross-workload posture score.
