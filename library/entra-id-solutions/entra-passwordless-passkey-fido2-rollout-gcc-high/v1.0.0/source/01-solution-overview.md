# 1. Solution Overview — Passwordless & Passkey (FIDO2) Rollout for Microsoft Entra — Government (GCC High)

> **Government (GCC High) edition.** This is the US-public-sector / defense-industrial-base edition,
> built for Microsoft's US Government national cloud (Azure Government / GCC High). It mirrors the
> commercial passwordless method exactly, adapted for the sovereign cloud: the GCC High Entra admin
> center (`entra.microsoft.us`), the GCC High security-info portal (`mysignins.microsoft.us`), and US
> Gov script endpoints (`Connect-MgGraph -Environment USGov`; DoD/IL5 uses `USGovDoD` /
> `dod-graph.microsoft.us`).
>
> **Why this is a strong government driver:** phishing-resistant MFA is a **federal Zero Trust
> requirement**. OMB Memorandum **M-22-09** (*Moving the U.S. Government Toward Zero Trust Cybersecurity
> Principles*) directs agencies to enforce phishing-resistant MFA (explicitly citing FIDO2 / WebAuthn and
> PIV) for staff, contractors, and partners — exactly the FIDO2 security keys and passkeys this rollout
> deploys. For **defense-industrial-base** contractors, **CMMC 2.0** Identification & Authentication (IA)
> practices likewise push toward phishing-resistant authentication. This edition delivers the technical
> rollout that satisfies those mandates in the government cloud.
>
> Because GCC High and DoD can **lag commercial in feature availability** — particularly for newer
> **passkey / FIDO2 method** capabilities — treat every capability below as **"verify against current
> Microsoft Government documentation."** See `gcc-high-parity-notes.md` for endpoints, parity, and the
> FedRAMP / DoD / CMMC / M-22-09 context.

## Why passwordless, and why phishing-resistant
A password is a shared secret: the user knows it, the service stores a verifier for it, and anything
that can trick the user into typing it — a fake sign-in page, a proxy in the middle — captures it.
Adding a one-time code or a push approval helps, but most of it is still phishable: an attacker who
relays your login in real time (adversary-in-the-middle) collects the code or triggers the push and
walks in. Phishing-resistant authentication removes the shared secret. The credential is a private
key that never leaves the user's device or security key, and it is cryptographically bound to the
real sign-in domain — so a look-alike site gets nothing it can replay.

## FIDO2 and WebAuthn — the standard underneath
FIDO2 (with the WebAuthn browser standard) is the open standard Entra uses for phishing-resistant
sign-in. At registration the device generates a public/private key pair for a specific relying party
(here, Microsoft Entra); the private key stays in secure hardware and the public key is stored
against the user in the directory. At sign-in the device proves possession of the private key with a
local gesture (PIN, fingerprint, face), and the browser only completes the ceremony for the genuine
origin. There is no secret to phish, spray, or reuse.

## The two shapes: FIDO2 security keys and passkeys
This rollout uses two forms of the same technology:

- **FIDO2 security keys** — a physical hardware key (USB, NFC, or Lightning) the user taps or
  inserts. Ideal for admins, shared/kiosk workstations, and anyone who needs a portable credential
  not tied to one phone. Managed under the **FIDO2 security key** authentication method.
- **Passkeys in Microsoft Authenticator** — a **device-bound passkey** stored in the Authenticator
  app on the user's phone; the phone becomes the phishing-resistant credential. Managed under the
  **Passkey (FIDO2)** / Microsoft Authenticator passwordless method. This is the lowest-friction
  option for the general workforce because most users already carry a phone.

> Passkey behavior in Authenticator (device-bound passkeys, and how synced consumer passkeys are
> treated) has shipped and evolved on Microsoft's timeline, **and passkey / FIDO2 method availability in
> GCC High and DoD can lag the commercial cloud.** *Verify current availability and any preview status
> for your GCC High (or DoD) tenant against current Microsoft Government documentation* under the
> authentication methods policy before committing a wave to a specific passkey type — do not assume
> commercial parity.

## The authentication methods policy
Entra decides which methods a user may register and use through the **authentication methods policy**
(`Entra -> Identity -> Protection -> Authentication methods -> Policies`). Each method — FIDO2
security key, Passkey (Authenticator), Microsoft Authenticator, SMS, Voice call, Temporary Access
Pass, etc. — is enabled or disabled and can be **targeted at specific groups**. This is what lets you
turn passwordless on for a pilot group first, and — later — retire weak, phishable methods (SMS text
and voice call) by scoping them out. A **Temporary Access Pass (TAP)** is a time-limited passcode an
admin issues so a user can bootstrap their first passwordless credential (or recover) without a
password.

## The registration campaign
Enabling a method does not register users — they have to enroll. A **registration campaign** nudges
users to set up a stronger method (passkey / Authenticator) during sign-in, so adoption happens by
itself instead of one help-desk ticket at a time. You scope the campaign to a group, so each rollout
wave gets nudged when its turn comes.

## Conditional Access — where enforcement lives
Enabling and registering passwordless is only half the job; you still have to **require** it for the
people who matter. Conditional Access can grant access only when the sign-in used a
**phishing-resistant** method, using the built-in **Authentication Strengths** control (the
`Phishing-resistant MFA` strength). You apply that first to administrators and sensitive apps, so
privileged access is passwordless-only, then widen the scope as adoption grows. Everything is piloted
in **report-only** first so you can see who a policy *would* have blocked before it actually blocks
anyone.

## Fallback and recovery
Hardware gets lost and phones get replaced, so a passwordless rollout must include a recovery path or
it will lock people out. The standard fallback is a **Temporary Access Pass** issued by the help desk
(or an admin) to let a user register a new key/passkey, plus a documented lost-key runbook: revoke
the lost credential, verify identity, issue a TAP, re-register. Break-glass accounts stay excluded
from the enforcement policies at all times (global requirement G4).

## What you can control
- Which methods are enabled, and for which groups — FIDO2 security key, Passkey (Authenticator),
  Authenticator, TAP, and the weak methods you will retire (SMS, Voice).
- Who is driven to register, and when — through the registration campaign scoped per wave.
- Who is *required* to be phishing-resistant — through Conditional Access authentication strength,
  admins and sensitive apps first.
- The recovery path — TAP issuance and the lost-key runbook.

## Benefits
- Security — the number-one payoff: the phishable shared secret is gone; adversary-in-the-middle and
  password attacks stop working against enrolled users.
- Lower friction — a tap or a glance instead of a password plus a code; fewer reset tickets.
- Least-privilege first — admins and sensitive apps become passwordless-only before the rest.
- Repeatability — a wave-based pattern you re-run for each group, not a one-time flag flip.

## Limitations (be honest with buyers)
- Requiring a phishing-resistant method through Conditional Access, and using device-based grant
  controls, needs Entra ID P1 (risk-based conditions need P2). *Verify your licensing* (requirements).
- Retiring SMS/voice before users have registered a stronger method will lock them out — retirement
  is the last step, gated on adoption, and always staged behind report-only and a pilot.
- Some passkey capabilities may be in preview or gated per tenant, **and may be delayed or unavailable
  in GCC High / DoD relative to commercial** — *verify current availability against current Microsoft
  Government documentation* before committing a wave.
- This delivers the technical rollout; the decision about which apps count as "sensitive" and which
  users are "privileged" belongs to your security and business owners.

## The standard deployment model
> Assess the current methods and adoption -> Configure the authentication methods policy and
> Conditional Access (report-only) on a pilot group -> Pilot passwordless registration and sign-in ->
> Validate against pass/fail gates -> Expand in waves, then retire weak methods. repeatable pattern:
> Assess -> Configure -> Pilot -> Validate -> Expand.

## Authentication and connections used
- GCC High Microsoft Entra admin center (`https://entra.microsoft.us`) for the authentication methods
  policy, registration campaign, Temporary Access Pass, and Conditional Access. *Verify the current GCC
  High portal URL against Microsoft Government documentation.*
- The GCC High security-info / My Sign-Ins portal (`https://mysignins.microsoft.us/security-info`) for
  end-user credential registration. *Verify the current GCC High URL.*
- Microsoft Graph PowerShell SDK targeting the US Government cloud (`Connect-MgGraph -Environment USGov`;
  DoD/IL5 uses `-Environment USGovDoD` / `dod-graph.microsoft.us`) for read-only
  discovery/validation/reporting and the safe, preview-by-default methods-policy change (scopes named in
  each script header).
