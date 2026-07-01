# 7. Best Practices — Device Compliance Policies

- **Always pilot first.** Apply to a small group and confirm healthy devices report Compliant before fleet rollout.
- **Set the no-policy default to Not compliant.** Otherwise unmanaged devices are treated as compliant — the opposite of what you want.
- **Use a grace period.** Mark noncompliant after ~1 day so a transient failure doesn't instantly block a user; notify the user immediately.
- **One authoritative policy per scope.** Avoid overlapping compliance policies with conflicting settings; consolidate.
- **Pair with Conditional Access in Report-only first.** See who *would* be blocked before enforcing, to avoid lockouts.
- **Match rules to reality.** Don't require BitLocker/Secure Boot on hardware that can't support it; segment by capability.
- **Notify users.** A clear email on noncompliance ("your device needs an update / encryption on") drives self-remediation.
- **Layer with the encryption/Defender solutions.** Compliance *checks* health; BitLocker and Defender solutions *deliver* it.
- **Review the tenant report regularly.** Track compliance percentage and chase persistent failures with `DCP-TenantReport.ps1`.
- **Document the baseline.** Record the required rules and rationale for audits and repeatability.
