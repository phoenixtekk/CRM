# 7. Best Practices — Attack Surface Reduction (ASR) Rules

- **Always Audit first.** Deploy every rule in Audit, review events for 1–2 weeks, then move to Block. This is the single best way to avoid breaking business apps.
- **Start with the high-value rules.** Office child processes, LSASS credential theft, executable content from email, obfuscated scripts, and ransomware protection give the most security per unit of risk.
- **Exclude precisely.** Use per-rule exclusions scoped to the verified file/path — avoid broad global exclusions that weaken protection.
- **Manage ASR in one place.** Use this dedicated solution OR the security baseline for ASR — never both — to prevent conflicts.
- **Keep Defender AV active.** ASR does nothing in passive mode; ensure real-time protection is on.
- **Onboard to Defender for Endpoint.** It gives centralized ASR reporting and advanced hunting across the fleet.
- **Roll out by waves.** Move from pilot to production gradually, re-auditing any newly added rule before blocking fleet-wide.
- **Review events regularly.** `ASR-AuditReport.ps1` (and the Defender ASR report) catch both attacks and false positives.
- **Document exclusions.** Record each exclusion, the rule, and the business justification for audits.
- **Re-audit after major app changes.** New line-of-business software can trip rules; audit before enforcing on it.
