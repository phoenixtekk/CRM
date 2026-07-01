# Executive Summary — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys (Microsoft Entra ID)

**Workplace Marketplace · Entra ID Solutions**

Passwords get phished, and even push-based MFA gets bombed until a tired user taps "Approve."
Security-conscious and federal organizations are now expected to move to **phishing-resistant**,
passwordless authentication. This solution stands up **passwordless and phishing-resistant MFA in
Microsoft Entra ID** — FIDO2 hardware security keys, Windows Hello for Business, and (where
applicable) certificate-based authentication — enabled as authentication methods, registered by
users through a campaign, and then **enforced** through a Conditional Access authentication strength
so weak, phishable methods can no longer get in.

This is a complete, **deploy-it-today** package for a competent administrator with no prior
passwordless experience: every screen, every object name, every gate.

## What you get
- A plain-language **Solution Overview** of the Entra ID authentication methods model, FIDO2 keys vs. Windows Hello for Business vs. certificate-based auth, and Conditional Access authentication strengths — including *why* each is used.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click steps in the required order.
- Five **PowerShell scripts** for auth-methods readiness discovery, per-user passwordless registration validation, a tenant credential-method coverage report, safe remediation of weak-method users, and a rollout target-group builder.
- **Testing** and **Troubleshooting** guides with explicit pass/fail gates.

## What this delivers
A **phishing-resistant credential program** — FIDO2 security keys and Windows Hello for Business
registered across a pilot then the staff, a named **authentication strength** (`Phishing-Resistant`)
created once, and a Conditional Access policy that **requires** that strength so legacy
password+SMS/push sign-ins are blocked. This is broader than a single Windows Hello deployment: it
is the whole passwordless and phishing-resistant enforcement program.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate before any enforcement
reaches all staff.

## Outcome
Users signing in passwordless with phishing-resistant credentials, weak methods blocked by a
Conditional Access authentication strength, and break-glass access preserved — proven on a pilot
before you scale, deployable by a single administrator.
