# 7. Best Practices — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys

- **Register before you enforce.** Get users onto a phishing-resistant method *first*; turning on the authentication strength ahead of registration locks people out. This is the single most important rule.
- **Always keep break-glass accounts excluded.** Two cloud-only emergency accounts, excluded from every Conditional Access policy, monitored for sign-ins — your insurance against a bad policy.
- **Pilot, then expand.** Validate the full flow on `Phishing-Resistant – Pilot – Users` before widening to `Phishing-Resistant – All Staff – Users`.
- **Use Report-only first.** Every Conditional Access policy starts in **Report-only** so you see impact before anything is blocked.
- **Run the registration campaign.** A sign-in nudge drives adoption far faster than email asks; pair it with FIDO2-key handout sessions.
- **Match the method to the user.** FIDO2 keys for roaming/shared/admin users, Windows Hello for assigned PCs, certificate-based auth where a PKI/PIV already exists.
- **Use the built-in phishing-resistant strength when you can.** It tracks Microsoft's definition; build a custom strength only for a specific need, and name it `<Purpose> – <Scope> – <Stage>`.
- **Inventory legacy apps.** Find protocols/apps that can't honor modern auth before tenant-wide enforcement; scope or remediate them rather than poking permanent holes.
- **Measure coverage continuously.** Track registered phishing-resistant methods with `FIDO2-Report.ps1` and chase laggards with `FIDO2-Remediation.ps1` (default `-WhatIf`).
- **Name every object consistently.** Reuse `<Purpose> – <Scope> – <Stage>` for groups, strengths, and policies so the program is auditable and repeatable.
