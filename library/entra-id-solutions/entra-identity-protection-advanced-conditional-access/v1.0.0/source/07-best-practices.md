# 7. Best Practices — Entra Identity Protection & Advanced Conditional Access

- Always start report-only. Every risk, step-up, and token-protection policy goes to production through report-only first. Read the "would apply / would block" data in the sign-in logs and confirm the blast radius before you set a policy On.
- Keep break-glass out of every policy. Exclude `CA Break-Glass Exclusion` from all four policies, always. A risk policy or a bad enforcement flip must never be able to lock out every administrator. Protect break-glass accounts with strong stored credentials and sign-in alerts.
- Enforce in stages, least-disruptive first. Flip sign-in risk, then user risk, then step-up, then token protection — one at a time, watching the logs after each, so a problem is isolated to one change.
- Tune the risk engine, do not just enable it. Triage risky users and risky sign-ins routinely: dismiss false positives, confirm real compromises, and let confirmations improve Microsoft's scoring. Risk policy is an operating loop, not a switch.
- Step up only where it matters. Use authentication contexts so sensitive apps and actions demand a fresh, strong proof, while routine sign-ins stay low-friction. Over-broad step-up trains users to click through prompts.
- Demand phishing-resistant where the value justifies it. Use authentication strengths to require FIDO2/passkey/WHfB on the highest-value access, but confirm those methods are registered first so you do not lock users out.
- Respect the token-protection and CAE constraints. These have platform, client, and preview limits — scope policies to the supported clients and verify current availability in your tenant before enforcing, so unsupported clients are not caught unexpectedly.
- Name every object consistently. Use `<Purpose> – <Scope> – <Stage>` for groups, contexts, strengths, and policies so audits, rollbacks, and expansion stay repeatable. Drop the `(Report-Only)` suffix only when a policy is actually enforced.
- Keep a rollback path. Know how to set any policy back to report-only instantly (`ENTIDP-Set-PolicyState.ps1` reverts by name); keep the before-state from `ENTIDP-Discovery.ps1`.
- Verify licensing and preview facts. P2 is required for risk-based policies; token protection and some contexts/CAE behaviours may be in preview or client-limited — verify current availability in your tenant rather than assuming.

## Where to go next (adjacent catalog areas)
- **Conditional Access baseline** — the require-MFA / block-legacy-auth / device-compliance foundation this layer sits on. If you do not have it, deploy it first.
- **Privileged Identity Management (PIM)** — make admin roles just-in-time and require the authentication context defined here on activation.
- **Privileged Access Workstation (PAW) for Cloud Administration** — pair risk/step-up with a clean, hardened admin device required by Conditional Access device filters.
- **Passwordless / passkey (FIDO2) rollout** — register the phishing-resistant methods your authentication strengths demand.
- **Enterprise app & service-principal governance**, **Hybrid identity (Entra Connect)**, and **Entra ID Governance** — the surrounding identity program this risk layer protects.
