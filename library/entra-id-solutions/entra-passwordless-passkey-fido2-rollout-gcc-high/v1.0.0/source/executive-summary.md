# Executive Summary — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra — Government (GCC High)

White-label · Entra ID Solutions · **US Government (GCC High) edition**

This is the **Government (GCC High)** edition for US public-sector and defense-industrial-base tenants
running in Microsoft's US Government national cloud (Azure Government / GCC High). It mirrors the
commercial passwordless method, adapted for the sovereign cloud — GCC High portals
(`entra.microsoft.us` / `mysignins.microsoft.us`) and US Gov script endpoints (`Connect-MgGraph
-Environment USGov`; DoD/IL5 uses `USGovDoD`). **Phishing-resistant MFA is a federal Zero Trust
requirement:** OMB Memorandum **M-22-09** directs agencies to enforce phishing-resistant MFA (FIDO2 /
WebAuthn), and **CMMC 2.0** drives the same for the defense-industrial-base — making this rollout a
direct mandate-satisfying control. Because passkey / FIDO2 method availability in GCC High/DoD can lag
commercial, every capability is flagged *"verify against current Microsoft Government documentation"* —
see `gcc-high-parity-notes.md` for endpoints, parity, and the FedRAMP High / DoD IL4-IL5 / CMMC / M-22-09 context.

Passwords are the single largest attack surface in your tenant. They get phished, reused, sprayed,
and reset — and even most "MFA" is still phishable, because a code typed into a fake sign-in page
works just as well for the attacker. The fix is to remove the shared secret entirely: move users to
**phishing-resistant, passwordless sign-in** using FIDO2 security keys and device-bound passkeys in
Microsoft Authenticator, where the credential never leaves the device and cannot be replayed against
a look-alike site.

This is a complete, deploy-it-today package for rolling out passwordless authentication in Microsoft
Entra, written for an administrator with no prior passwordless experience. It gives you a repeatable
way to enable the right authentication methods, drive users to register through a registration
campaign and clear comms, require phishing-resistant MFA for the people who matter most through
Conditional Access, and keep a fallback and lost-key runbook so nobody is ever locked out.

## What you get
- A plain-language Solution Overview of how passwordless works in Entra — FIDO2 / WebAuthn, passkeys
  (device-bound vs. synced), the authentication methods policy, the registration campaign, and how
  Conditional Access enforces phishing-resistant MFA.
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite.
- An Implementation Guide of precise, click-by-click Entra steps in the required order, pilot-first.
- Five PowerShell scripts for authentication-method discovery, adoption reporting, a safe
  methods-policy change (preview by default), rollout-group targeting, and a validation check.
- Testing, Troubleshooting, and Best-Practices guides for a confident, staged rollout.

## What this delivers
A tenant where the users who matter most sign in without a password at all — a hardware-backed FIDO2
key or a device-bound passkey they cannot be phished out of — with weak, phishable methods retired,
a registration campaign moving the rest of the organization across, and a documented recovery path
for a lost or broken key, proven on a pilot group before you touch everyone.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Phishing-resistant, passwordless sign-in across the tenant — the password attack surface removed for
admins and sensitive apps first, then expanded organization-wide, with a fallback and lost-key
runbook so the rollout never locks anyone out.

> Some passkey capabilities (device-bound passkeys in Authenticator, synced-passkey handling) have
> shipped and changed on Microsoft's schedule, **and passkey / FIDO2 method availability in GCC High and
> DoD can lag the commercial cloud.** Where a feature may be in preview, gated by tenant configuration,
> or delayed/unavailable in the government cloud this package flags it — *verify current availability for
> your GCC High (or DoD) tenant against current Microsoft Government documentation* before you rely on it.
