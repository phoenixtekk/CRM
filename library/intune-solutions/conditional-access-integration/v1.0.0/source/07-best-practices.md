# 7. Best Practices — Conditional Access Integration

- **Create break-glass accounts first.** Two cloud-only Global Admins, excluded from every policy, passwords stored offline. This is the single most important safeguard against lockout.
- **Always pilot in Report-only.** Never enable a new policy straight to On — review the would-be impact in sign-in logs first.
- **Exclude break-glass from every policy.** Make it a checklist item on each policy you create.
- **Block legacy authentication.** It's the channel attackers use to bypass MFA — high value, low risk to enable.
- **Layer the controls.** Require MFA + require compliant device + block legacy auth together form a strong baseline.
- **Use the What If tool.** Simulate a user/app/condition before enabling to predict the outcome.
- **Roll out by waves.** Move from pilot group to all users gradually, watching sign-in logs.
- **Name policies clearly.** `CA - <control> - <scope>` so intent is obvious and audits are easy.
- **Monitor continuously.** Review sign-in logs and `CAI-SignInReport.ps1` for unexpected blocks after each change.
- **Pair with compliance.** "Require compliant device" is only as strong as your Device Compliance policy — deploy that solution alongside.
