# 7. Best Practices — Conditional Access Integration (Government / GCC High)

- **Confirm you are on the sovereign cloud first.** Every session, verify the portal is a `*.us`
  URL and the tenant is `.onmicrosoft.us`. In PowerShell, always
  `Connect-MgGraph -Environment USGov` — a missing `-Environment USGov` targets the Commercial cloud
  and reports the wrong tenant.
- **Create break-glass accounts first.** Two cloud-only `.onmicrosoft.us` Global Admins, excluded
  from every policy, passwords stored offline. This is the single most important safeguard against
  lockout.
- **Always pilot in Report-only.** Never enable a new policy straight to On — review the would-be
  impact in the GCC High sign-in logs first.
- **Exclude break-glass from every policy.** Make it a checklist item on each policy; verify with
  `CAIG-Validation.ps1` before every enforcement change.
- **Block legacy authentication.** It's the channel attackers use to bypass MFA — high value, low
  risk to enable.
- **Layer the controls.** Require MFA + require compliant device + block legacy auth together form a
  strong baseline.
- **Use named locations, not legacy MFA Trusted IPs.** Named locations are the supported,
  forward-compatible way to express trusted networks and are available in GCC High.
- **Do not architect around Global Secure Access.** GSA / network-based CA is **not available in
  GCC High**; plan network trust with IP-based named locations instead. [Microsoft — GSA
  limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)
- **Plan for feature lag.** GCC High typically receives new CA/Entra features **2–6 weeks after
  Commercial**. Don't design a rollout around a capability you saw demoed on Commercial until you've
  confirmed it in your GCC High tenant. When in doubt, **verify for GCC High**.
- **Use the What If tool.** Simulate a user/app/condition before enabling to predict the outcome
  (the What If tool works in GCC High; the PowerPoint export does not).
- **Roll out by waves.** Move from `CA-Pilot-Gov` to all users gradually, watching sign-in logs; use
  `CAIG-Set-ScopeTargeting.ps1 -WhatIf` to preview each scope change.
- **Name policies clearly.** `CA - <control> - <scope> (Gov)` so intent is obvious and audits are
  easy.
- **Pair with compliance.** "Require compliant device" is only as strong as your Device Compliance
  (GCC High) policy — deploy that solution alongside.
