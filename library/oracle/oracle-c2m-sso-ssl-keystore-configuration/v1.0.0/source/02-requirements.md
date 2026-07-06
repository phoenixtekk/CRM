# 2. Requirements Guide — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (entitlement, certified stack, environments,
tooling, change control, teams) are in `global-requirements-oracle.md`.

## 2.1 WebLogic domain administrative access (Console + WLST)
**Description:** WebLogic Administration Server reachable, with the admin credentials and **WLST
(Jython)** connectivity to the domain that hosts the C2M/OUAF managed servers.
**Why:** Keystore, SSL, and Identity Assertion Provider configuration are performed through the
Administration Console and WLST against server MBeans.
**Verify:** `java weblogic.WLST` then `connect(...)` to the Administration Server succeeds; the Console
opens at the admin URL and lists the C2M managed servers.
**Implement:** Obtain the WebLogic admin account and the Administration Server URL/port from the
infrastructure team; confirm the domain home and `setDomainEnv` are sourced for WLST.

## 2.2 OS product account, product home, and OUAF tooling
**Description:** The OUAF/product OS account with access to the C2M **product home** (`$SPLEBASE`) and
the OUAF utilities **`configureEnv`** and **`initialSetup`**, plus a JDK on the `PATH` that provides
**`keytool`**.
**Why:** OUAF advertises its own URL/protocol and JEE descriptors (`web.xml`, `weblogic.xml`,
`spl.properties`) through `configureEnv`/`initialSetup`; keystores are created and inspected with
`keytool` from the JDK.
**Verify:** `echo $SPLEBASE` resolves; `configureEnv -h` runs; `keytool -help` runs and `java -version`
matches the certified JDK.
**Implement:** Log in as the product account, source the environment (`splenviron`/`configureEnv` per
your install), and confirm the certified JDK is the one on `PATH`.

## 2.3 Certificate strategy and Certificate Authority
**Description:** A decision on certificate source per environment — **enterprise CA-signed** for
production (and ideally test), **self-signed** acceptable only for lower environments — and access to
the CA (internal PKI or public CA) to sign a Certificate Signing Request (CSR).
**Why:** The identity keystore must hold a certificate that clients and integrations trust; a
self-signed or untrusted cert produces browser warnings and failed server-to-server TLS.
**Verify:** You can state which CA will sign each environment's certificate and how a CSR is submitted
and returned; the CA **root** (and any **intermediate**) certificates are available as files.
**Implement:** Engage the PKI/security team to establish the CA path and CSR submission process; obtain
the root/intermediate CA certificate files for the trust keystore.

## 2.4 Server hostnames / SAN plan and fully-qualified URLs
**Description:** The exact **hostname(s)** and any load-balancer/vanity names that clients use to reach
C2M, planned into the certificate **Common Name (CN)** and **Subject Alternative Names (SAN)**.
**Why:** TLS validates the certificate against the hostname in the URL; a mismatch (or a missing SAN
for the load-balancer name) fails validation even with a valid certificate.
**Verify:** The list of DNS names clients use is documented and each is represented in the planned
CN/SAN.
**Implement:** Collect the DNS names (including any front-end/load-balancer FQDN), and include them in
the CSR's SAN extension before requesting the certificate.

## 2.5 Identity Provider / SSO integration decision
**Description:** The enterprise SSO mechanism to integrate — **SAML**, **OIDC**, or an access-manager
agent — and the IdP-side details (SAML metadata / signing certificate, or OIDC client, or agent
configuration) that WebLogic will consume.
**Why:** WebLogic's Identity Assertion Provider validates the asserted identity; the OUAF web
application must be switched to `CLIENT-CERT` to accept it. Without the IdP side provisioned, SSO
cannot be asserted.
**Verify:** The identity team can supply the IdP metadata / signing certificate (SAML) or client
registration (OIDC) / agent details, and the header/assertion the perimeter will pass is defined.
**Implement:** Engage the identity team to register C2M as a relying party / client / protected
resource and to provide the metadata/signing certificate and the asserted username claim/header.

## 2.6 Keystore passphrase custody and secrets handling
**Description:** A secure custody process for **keystore and private-key passphrases** (a secrets
manager or sealed credential store), and agreement that passphrases are **never** committed to source,
printed, or placed in the docs/exports.
**Why:** Compromise of a private key or its passphrase compromises the server's identity; secrets must
be handled out-of-band. The automation in this solution is read-only for state and never prints key
material.
**Verify:** A vault/credential store is identified; the team agrees passphrases are entered
interactively or injected from the vault, not stored in scripts.
**Implement:** Provision passphrase storage; document who holds custody and how a passphrase is
retrieved for a change window.

## 2.7 Change control, backups, and a rollback path
**Description:** A change window and verified **backups** before any SSL/SSO change: the WebLogic
**domain config** (`config.xml` and the `security` directory), the OUAF **product/config**
(`$SPLEBASE/etc`), and the existing keystores — plus a defined rollback (revert config, restore the
previous keystore, or fall back to the prior working state).
**Why:** SSL/SSO changes affect every user and integration; a bad change can lock everyone out, so a
tested restore is mandatory (see `global-requirements-oracle.md` §5).
**Verify:** You have current copies of `config.xml`, the domain `security` folder, `$SPLEBASE/etc`, and
each keystore, and a documented restore procedure.
**Implement:** Take the backups as the first step of the change; rehearse the restore in a lower
environment.

## 2.8 A non-production pilot server / environment
**Description:** A single managed server or lower environment where keystores, SSL, and SSO are proven
**first**, before the domain is expanded.
**Why:** The model is Assess → Configure → **Pilot** → Validate → Expand; a pilot contains blast radius
and validates the exact steps against your topology.
**Verify:** The pilot server/environment is identified and you can enable an SSL port on it without
affecting production traffic.
**Implement:** Choose the pilot (e.g. Test, or one managed server), and record it as
`Security Target – Pilot – Stage1`.

---
## Checklist
- [ ] WebLogic Console + WLST access to the C2M domain confirmed
- [ ] OUAF product account, `$SPLEBASE`, `configureEnv`/`initialSetup`, and JDK `keytool` available
- [ ] Certificate source and CA path decided; root/intermediate CA files in hand
- [ ] Hostname/SAN plan and fully-qualified HTTPS URLs documented
- [ ] SSO mechanism chosen; IdP metadata/signing cert or client/agent details available
- [ ] Passphrase custody (vault) in place; secrets never in scripts/exports
- [ ] Backups taken (config.xml, domain security dir, `$SPLEBASE/etc`, keystores); rollback documented
- [ ] Pilot server/environment chosen and recorded as `Security Target – Pilot – Stage1`
