# 1. Solution Overview — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

## What this solution is
Oracle Utilities Customer to Meter (C2M) runs on the Oracle Utilities Application Framework (OUAF)
deployed as JEE web applications on **Oracle WebLogic Server 14c** (14.1.1). Three things have to be
configured correctly, in the right order, for the system to be secure and for users and integrations
to trust it: **Single Sign-On (SSO)** so people sign in once through the enterprise Identity Provider;
**SSL/TLS** so every connection to the WebLogic domain and to C2M is encrypted; and the
**certificate keystores** — the WebLogic *identity* keystore (the server's private key and
certificate) and the *trust* keystore (the CA certificates the server trusts) — that make the TLS
handshake and SSO trust actually work. This solution is a repeatable, production-safe way to configure
all three using the WebLogic Administration Console, **WLST (Jython)**, **`keytool`**, and OUAF's
template-driven configuration (`configureEnv` / `initialSetup`) — no third-party tooling.

> **Version context.** Authored for **C2M 25.4 (minimum OUAF v2.9 lineage)** on **WebLogic Server
> 14.1.1**. WebLogic keystore/SSL steps follow Oracle's *Administering Security for Oracle WebLogic
> Server 14.1.1* guide; OUAF web-application security follows the *OUAF Server Administration Guide*.
> Version-specific object names and paths are flagged **"verify for your version"** where they drift
> between releases. Certain SSO/IdP integration notes and patches are entitlement-gated on **My Oracle
> Support (MOS)** and are pointed to, not reproduced. See `global-requirements-oracle.md`.

## The C2M security model (what fits together)
1. **Identity keystore** — a keystore (JKS or PKCS12) holding the WebLogic server's **private key** and
   its signed **server certificate** (plus the CA chain). This is what the server presents during the
   TLS handshake. Configured per server as **Custom Identity**.
2. **Trust keystore** — a separate keystore holding the **CA certificates** WebLogic trusts (root and
   intermediate). This is what the server uses to validate certificates presented to it (e.g. a client
   certificate in two-way SSL, or an IdP/back-end certificate). Configured as **Custom Trust**.
3. **SSL/TLS on the domain** — each WebLogic server has its **SSL listen port** enabled, points at the
   identity keystore via a **private key alias**, sets **minimum TLS protocol** and cipher policy, and
   sets **client-certificate enforcement** (one-way vs two-way SSL).
4. **SSL/TLS reaching C2M** — the OUAF web applications are addressed over HTTPS. OUAF's own
   configuration (the URL/protocol/port it advertises, set through `configureEnv` and materialized by
   `initialSetup` into `web.xml` / `weblogic.xml` / `spl.properties`) is aligned with the WebLogic SSL
   endpoint so links, callbacks, and inbound web services all use `https`.
5. **SSO** — user authentication is delegated to the enterprise Identity Provider. The perimeter
   (SAML/OIDC or an access-manager agent) authenticates the user and asserts identity to WebLogic; a
   WebLogic **Identity Assertion Provider** consumes the assertion/header, and the OUAF web application
   is set to the **`CLIENT-CERT`** authentication method so it accepts the asserted identity instead of
   prompting with its own form login.

## How it works (end to end)
1. A user hits the C2M URL. The connection is TLS-encrypted using the WebLogic **identity** certificate.
2. The perimeter/IdP authenticates the user (SSO) and asserts identity to WebLogic.
3. WebLogic's **Identity Assertion Provider** validates the assertion (using the **trust** keystore for
   the signing certificate where applicable) and establishes the WebLogic subject.
4. OUAF, configured for **`CLIENT-CERT`**, accepts the asserted user, maps them to a C2M user, and the
   session proceeds — no separate C2M password prompt.
5. Server-to-server calls (inbound web services, integrations, batch) use the same TLS endpoints and
   the same trust chain, so every hop is encrypted and mutually validated.

## What you configure (the levers)
- **Which keystore strategy:** Custom Identity + Custom Trust (recommended) versus demo keystores
  (never in production). Separate identity and trust keystores are the standard.
- **Certificate source:** enterprise CA-signed (production) vs self-signed (lower environments only),
  and the CA chain imported into trust.
- **SSL posture:** SSL listen port, minimum TLS version (TLS 1.2+), cipher policy, and
  **client-cert enforcement** (`none` / `want` / `need`).
- **SSO integration type:** SAML, OIDC, or an access-manager agent, and the Identity Assertion Provider
  that consumes it; plus the OUAF `CLIENT-CERT` auth-method switch.
- **Scope order:** which single server/environment is piloted first before the domain is expanded.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, WebLogic console, and `keytool` aliases. The standard set:

| Artifact | Name |
|---|---|
| Identity keystore file | `C2MSEC-Identity-<env>.jks` (e.g. `C2MSEC-Identity-Pilot.jks`) |
| Trust keystore file | `C2MSEC-Trust-<env>.jks` |
| Server private-key / certificate alias | `c2msec-server` |
| Root CA alias in trust | `c2msec-rootca` |
| Intermediate CA alias in trust | `c2msec-intca` |
| WebLogic Identity Assertion Provider | `C2MSEC-SSO-Asserter` |
| Discovery export | `Security Baseline – C2M – Discovery` |
| Validation result | `Security Validation – C2M – Validation` |
| Coverage/health report | `Security Coverage – C2M – Report` |
| Pilot scope target | `Security Target – Pilot – Stage1` |
| Domain scope target | `Security Target – Domain – Stage2` |

> Keystore **passphrases and private keys are never written into docs, scripts, or exports.** Scripts
> read state and print aliases, file names, ports, expiry, and enforcement — never key material or
> passwords.

## Limitations (be honest with buyers)
- **SSO depends on an external IdP.** This solution configures the WebLogic/OUAF side (asserter +
  `CLIENT-CERT`); the IdP/access-manager side (SAML metadata, OIDC client, agent) is owned by the
  identity team and must be provisioned in parallel.
- **Certificate lifecycle is ongoing.** Certificates expire; a keystore that is correct today fails on
  the expiry date. This solution includes discovery of expiry and a rotation practice, but rotation
  must be scheduled, not assumed.
- **Two-way SSL raises the bar.** Requiring client certificates (`need`) protects endpoints but breaks
  any caller that lacks a trusted client cert — pilot it before enforcing domain-wide.
- **Template overwrite risk.** OUAF regenerates `web.xml` / `weblogic.xml` from templates on
  `initialSetup`; changes made only to the generated files are lost. Persist changes through
  `configureEnv`/templates (see Requirements and Implementation).

## The standard deployment model
> Assess the current security state → configure keystores, SSL, then SSO → prove it on a **pilot**
> server/environment → validate secure sign-in and endpoints → expand across the domain.
> Pattern: **Assess → Configure → Pilot → Validate → Expand**, with explicit gates and a documented
> rollback (config backup + demo-keystore/previous-keystore fallback) for production changes.
