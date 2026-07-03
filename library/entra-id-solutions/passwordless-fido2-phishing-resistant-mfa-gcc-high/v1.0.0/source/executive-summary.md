# Executive Summary — Passwordless & Phishing-Resistant MFA with FIDO2 Security Keys — Government (GCC High)

**Workplace Marketplace · Entra ID Solutions · US Sovereign Cloud (GCC High / DoD)**

Passwords get phished, and even push-based MFA gets bombed until a tired user taps "Approve." For US
Government tenants this is not just a security preference — **Executive Order 14028** and **OMB
M-22-09** direct federal agencies toward **phishing-resistant MFA**, and **CMMC / NIST SP 800-171**
push the same requirement onto the defense-industrial base. This solution stands up **passwordless
and phishing-resistant MFA in Microsoft Entra ID** — FIDO2 hardware security keys, Windows Hello for
Business, and **certificate-based authentication with CAC/PIV smart cards** — enabled as
authentication methods, registered by users, and then **enforced** through a Conditional Access
authentication strength so weak, phishable methods can no longer get in.

This is the **Government (GCC High) edition**: it deploys on the **US sovereign cloud** using the
`*.us` admin portals (`entra.microsoft.us`, `portal.azure.us`, `portal.office365.us`) and **US Gov
Graph** (`-Environment USGov`), and it calls out where sovereign capabilities differ from Commercial
so the tenant is configured correctly — not with Commercial steps that silently authenticate against
the wrong cloud.

This is a complete, **deploy-it-today** package for a competent administrator with no prior
passwordless experience: every screen, every object name, every gate.

## What you get
- A plain-language **Solution Overview** of the Entra authentication-methods model, FIDO2 vs. Windows Hello vs. certificate-based (CAC/PIV), and Conditional Access authentication strengths — with an explicit **Commercial vs GCC High — what's different** section.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, on the `*.us` plane.
- An **Implementation Guide** of precise, click-by-click **sovereign** steps in the required order, with GCC-High caveats inline.
- Five **PowerShell scripts** (US Gov Graph) for auth-methods readiness discovery, per-user passwordless registration validation, a tenant credential-method coverage report, safe remediation of weak-method users, and a rollout target-group builder.
- **Testing**, **Troubleshooting**, and a cited **GCC High Parity Notes** reference with explicit pass/fail gates.

## What this delivers
A **phishing-resistant credential program** on the sovereign cloud — FIDO2 keys, Windows Hello for
Business, and CAC/PIV smart cards registered across a pilot then the staff, a named **authentication
strength** (`Phishing-Resistant`) created once, and a Conditional Access policy that **requires** that
strength so legacy password+SMS/push sign-ins are blocked. The core methods (FIDO2, Windows Hello,
certificate-based auth) and Conditional Access are all **Generally Available in US Gov**; the package
flags Authenticator-passkey, TAP, and registration-campaign features as "verify for GCC High" and
gives GA fallbacks.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate before any enforcement reaches
all staff.

## Outcome
Users signing in passwordless with phishing-resistant credentials, weak methods blocked by a
Conditional Access authentication strength, and break-glass access preserved — configured on the US
sovereign (`*.us`) cloud and proven on a pilot before you scale, deployable by a single administrator.
