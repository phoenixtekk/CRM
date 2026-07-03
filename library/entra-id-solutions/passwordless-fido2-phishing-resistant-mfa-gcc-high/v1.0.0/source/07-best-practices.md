# 7. Best Practices — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

Field-proven recommendations for deploying phishing-resistant, passwordless authentication on a US
sovereign (GCC High / DoD) tenant.

## Sovereign-cloud discipline
- **Administer only on the `*.us` plane.** Bookmark `entra.microsoft.us`, `portal.azure.us`, `portal.office365.us`, and `endpoint.microsoft.us`. A GCC High account will not authenticate against the Commercial `*.com` portals.
- **Always pass `-Environment USGov`** (or `USGovDoD`) in every Graph script. Without it the SDK silently targets `graph.microsoft.com` and fails against your tenant. All five scripts in this package default to `USGov`.
- **Use PowerShell, not Graph Explorer.** Graph Explorer is not supported for `graph.microsoft.us` / `dod-graph.microsoft.us`. This package's read-only scripts are the sovereign-safe equivalent.
- **Never assume Commercial parity.** Anything Authenticator-based, cross-cloud, or marked Preview in Commercial is "verify for GCC High." Default to the GA path.

## Choose the right method for government
- **Lead with CAC/PIV (certificate-based auth) where cards already exist.** For DoD (CAC) and federal-civilian (PIV) tenants, CBA is usually the primary phishing-resistant method — the credential is already on the badge, and it authenticates direct to Entra ID (no AD FS). It is **GA in US Gov**.
- **Use hardware FIDO2 keys for roaming users, admins, shared workstations, and frontline** who have no assigned PC or smart card. Prefer **FIPS 140-validated** keys.
- **Use Windows Hello for Business for assigned, single-user PCs.**
- **Do not build on synced/phone/Authenticator passkeys** for the sovereign rollout — they are *verify for GCC High*. If a pilot confirms they exist, treat them as a convenience tier, not the compliance path.

## Registration always leads enforcement
- **Never require a phishing-resistant strength before users are registered** — it locks them out. Confirm coverage with `FIDO2G-Report.ps1` first.
- **Decide the onboarding bootstrap up front.** TAP is *verify for GCC High*; have **supervised in-person enrollment** (or CAC/PIV issuance) as the guaranteed fallback so a missing TAP never blocks the program.
- **Pilot with real roles** — include a roaming admin, a frontline/shared-workstation user, and a CAC/PIV holder so every method path is exercised before broad rollout.

## Conditional Access safety
- **Start every enforcement policy in Report-only**, review sign-in logs, then flip to On.
- **Exclude two break-glass accounts from every policy** and monitor their sign-ins. On GCC High, support-assisted recovery is slower — break-glass matters more.
- **Inventory legacy apps/protocols** that don't honor modern auth before tenant-wide enforcement; scope exclusions deliberately.
- **Reuse one named authentication strength** (`Phishing-Resistant – All Staff – Standard`) across policies rather than creating ad-hoc strengths.

## Key/credential lifecycle
- **Restrict FIDO2 by AAGUID** to allow-list only approved, certified key models.
- **Track key inventory** (serial ↔ user) for CAC/PIV-adjacent accountability; plan for lost-key recovery before rollout, not after.
- **Set a reissuance/recertification cadence** consistent with your NIST 800-171 / CMMC controls.

## Naming, reuse, and auditability
- Use the `<Purpose> – <Scope> – <Stage>` convention verbatim (`Phishing-Resistant – Pilot – Users`, `… – All Staff – Enforce`) so every object is self-documenting for auditors.
- Keep the pilot and rollout groups authoritative (build/populate with `FIDO2G-Set-ScopeTargeting.ps1`) rather than hand-editing membership.
- Retain `FIDO2G-Report.ps1` output as coverage evidence for compliance reviews (phishing-resistant-MFA posture over time).

## Compliance framing
- Map the deployment to **EO 14028 / OMB M-22-09** phishing-resistant-MFA direction and **CMMC / NIST SP 800-171** authentication and access-control objectives. The named strength + Conditional Access policy + coverage report together form the provable control.
