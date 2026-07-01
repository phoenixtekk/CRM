# 1. Solution Overview — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys

## What phishing-resistant, passwordless authentication is
Passwordless means a user signs in **without typing a password** — proving identity with a
hardware-backed credential bound to the device or a security key. Phishing-resistant means the
credential **cannot be replayed against an attacker's fake site**: it is cryptographically bound to
the real sign-in origin, so a phished code or an approved push can't be reused. In Microsoft Entra
ID, the phishing-resistant, passwordless methods are **FIDO2 security keys**, **Windows Hello for
Business**, and **certificate-based authentication** (smart cards / PIV-CIV). This solution turns
those on, gets users registered, and then enforces them.

## How it works
1. Entra ID's **Authentication methods** policy enables each method (FIDO2, Windows Hello for Business, certificate-based auth) and scopes *who* can register it.
2. Users **register** a credential — tapping/plugging a FIDO2 key, enrolling Windows Hello, or being issued a certificate — at the security-info portal or during a **registration campaign** that nudges them at sign-in.
3. A Conditional Access **authentication strength** defines the set of acceptable methods (here, the built-in *Phishing-resistant MFA* strength, or a custom one).
4. A Conditional Access **policy** requires that strength for the targeted users, so a password+SMS or password+push sign-in is **blocked** — only a phishing-resistant credential satisfies the grant.
5. Coverage and registration are reported from Entra (registration details) so you can see who is ready before you enforce.

## FIDO2 keys vs. Windows Hello for Business vs. certificate-based auth
- **FIDO2 security keys** — a portable hardware key (USB/NFC) the user taps. Best for shared workstations, kiosks, frontline, and admins who roam between machines. Phishing-resistant by design.
- **Windows Hello for Business** — a credential bound to a specific Windows PC, unlocked by PIN or biometric. Best for assigned, single-user devices. (A standalone Windows Hello product covers enrollment depth; this program *includes* Windows Hello but centers on the broader passwordless + FIDO2 rollout and enforcement.)
- **Certificate-based authentication** — X.509 certificates / smart cards. Best where a PKI or PIV/CIV cards already exist (often federal).

## Conditional Access authentication strengths (the enforcement layer)
An **authentication strength** is a named, reusable set of allowed authentication-method
combinations. Entra ships a built-in **Phishing-resistant MFA** strength (FIDO2, Windows Hello for
Business, certificate-based auth). You reference it from a Conditional Access grant to *require* a
phishing-resistant sign-in. This is what makes the program real — without it, weak methods still
work.

## What you can control
- Which methods are enabled and **who may register** each (per-group scoping).
- A **registration campaign** that prompts users to add a phishing-resistant method at sign-in.
- The **authentication strength** required (built-in phishing-resistant, or a custom strength).
- The Conditional Access **scope** (pilot group first, then all staff), with break-glass exclusions.

## Benefits
- **Phishing-resistant** — credentials can't be replayed against fake sites; push-bombing stops working.
- **Passwordless** — no password to phish, spray, or reuse; better user experience.
- **Mandate-ready** — meets executive/federal requirements for phishing-resistant MFA.
- **Enforceable** — Conditional Access authentication strengths block weak methods, not just recommend strong ones.
- **Measurable** — registration and method-coverage reporting before and after enforcement.

## Limitations (be honest with buyers)
- FIDO2 keys and certificate-based auth need **hardware** (keys, or a PKI/smart-card stack) — a procurement and distribution step.
- Enforcing a phishing-resistant strength **before** users are registered will lock them out — registration must lead enforcement (hence the pilot gate).
- Certificate-based authentication requires a configured certificate authority and trust chain in Entra.
- Some legacy/line-of-business apps and protocols don't honor modern auth; inventory them before tenant-wide enforcement.

## The standard deployment model
> **Enable methods → register users (campaign) → create the phishing-resistant authentication
> strength → require it via Conditional Access on the pilot → validate → expand to all staff.**
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**
