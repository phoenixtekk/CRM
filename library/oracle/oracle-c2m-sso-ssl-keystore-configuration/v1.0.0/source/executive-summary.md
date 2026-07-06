# Executive Summary — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

Oracle Utilities Customer to Meter (C2M) runs on the Oracle Utilities Application Framework (OUAF)
deployed on Oracle WebLogic Server 14c. For the system to be secure and trusted, three things have to
be configured correctly and in the right order: **Single Sign-On (SSO)** so users authenticate once
through the enterprise Identity Provider, **SSL/TLS** so every connection to the WebLogic domain and to
C2M is encrypted, and the **certificate keystores** — the WebLogic identity keystore (the server's
private key and certificate) and the trust keystore (the CA certificates it trusts) — that make the TLS
handshake and SSO trust actually work. Get any one wrong and you get broken logins, browser warnings,
untrusted server-to-server calls, or audit findings.

This solution is a complete, production-safe, deploy-it-on-a-pilot-first package for configuring the
C2M security plumbing using only the WebLogic Administration Console, **WLST (Jython)**, **`keytool`**,
and OUAF's own template-driven configuration (`configureEnv` / `initialSetup`) — no third-party tooling.
It is written for an experienced C2M/WebLogic administrator and is grounded in Oracle's official
WebLogic 14.1.1 security and OUAF Server Administration documentation; version-specific object names are
flagged to verify for your release, and My-Oracle-Support-gated notes are pointed to rather than copied.

## What you get
- A plain-language Solution Overview of the C2M security model — SSO, SSL/TLS termination, and the
  identity/trust keystore chain — with a reused naming convention.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of exact, ordered steps: build keystores with `keytool`, enable SSL/TLS on the
  domain via WLST/Console, align C2M to HTTPS through `configureEnv`/`initialSetup`, wire the SSO
  Identity Assertion Provider, switch OUAF to `CLIENT-CERT`, and (where required) enforce two-way SSL.
- Five automation scripts (WLST/Jython and shell) for read-only discovery, validation, a coverage
  report, safe remediation (dry-run by default), and a pilot-vs-domain scope helper — none of which ever
  print private keys or passphrases.
- Testing and Troubleshooting guides plus Best Practices for certificate lifecycle and key rotation.

## What this delivers
A measured security baseline of every WebLogic server, correctly built identity and trust keystores, a
domain encrypted with a modern TLS floor, C2M advertising HTTPS end to end, SSO sign-in through the
enterprise IdP with a safe negative path, and a coverage report proving it — all validated on a pilot
before the domain is expanded, with certificate expiry tracked and rotation scheduled.

## The deployment model
Assess → Configure → Pilot → Validate → Expand.

## Outcome
C2M secured end to end — SSO working, SSL/TLS valid, keystores trusted and managed — proven on a pilot
server before you scale, with a documented rollback and no secrets exposed by the tooling.
