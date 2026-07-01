# 7. Best Practices — Application Control (WDAC)

- **Audit first, always.** WDAC is powerful — never deploy Enforced without a thorough audit phase. This is the #1 rule.
- **Have a recovery path ready.** Know how to unassign the policy and clear it locally before you enforce anything.
- **Prefer the managed-installer model.** Deploy apps via Intune so they're trusted automatically — far lower maintenance than custom XML rules.
- **Enable ISG reputation.** It trusts well-known good apps without per-app rules, reducing audit noise.
- **Pilot on representative devices.** Include devices that run your full app set so the audit reveals real blocks.
- **Triage audit events by publisher/path.** Trust whole trusted publishers rather than individual hashes where possible.
- **Keep new apps flowing through Intune.** That keeps them trusted automatically as your estate changes.
- **Avoid custom XML unless needed.** Reserve custom policies for genuine edge cases; they add maintenance burden.
- **Communicate to users.** Let pilot users report anything that "won't open" during audit so you catch edge cases.
- **Document the trust model.** Record what's trusted (Windows/Store/ISG/managed installer/custom) and the recovery procedure for audits.
