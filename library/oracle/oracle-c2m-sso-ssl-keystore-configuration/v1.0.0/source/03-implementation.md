# 3. Implementation Guide — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

Follow these steps **in order**. Keystores are created with **`keytool`**; WebLogic SSL and the
Identity Assertion Provider are set through the **Administration Console** or **WLST**; OUAF's advertised
URL/protocol is set through **`configureEnv`** and materialized by **`initialSetup`**. Artifact names
follow the `<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim. Do
everything on the **pilot** first (`Security Target – Pilot – Stage1`), pass the gate, then expand.

> **Model:** Assess the current state → build keystores → enable SSL/TLS on the domain → align C2M to
> HTTPS → wire SSO → validate secure sign-in and endpoints on the pilot → expand across the domain.
> Pattern: **Assess → Configure → Pilot → Validate → Expand.**

> **Order matters.** Keystores (trust chain + identity) must exist and be valid **before** SSL can point
> at them; SSL/TLS must terminate correctly **before** SSO is layered on; SSO is proven **last** because
> it depends on both. Never enable two-way SSL or `CLIENT-CERT` before one-way TLS is confirmed working.

> **Placeholders are literal names, not fill-ins:** where a value is site-specific it is written as a
> plain token such as `your-hostname`, `your-keystore-dir`, or `your-idp-metadata` — substitute your
> real value; do not type angle brackets.

## Step 0 — Assess the current state (Assess)
1. Run `OC2MSEC-Discovery.sh` (read-only shell) to capture the baseline `Security Baseline – C2M –
   Discovery`: it inventories the keystore **files** on disk with `keytool -list` — aliases, entry
   types, and certificate **expiry** dates — reads each server's SSL/keystore attributes from the domain
   `config.xml`, and shows the OUAF advertised URL/protocol from `$SPLEBASE/etc`.
2. Run `OC2MSEC-Validation.py` (read-only WLST) once connected to confirm the live server MBean view of
   the **KeyStores** rule (Demo vs Custom), SSL enabled/port, client-cert enforcement, min TLS, and the
   configured authentication providers.
3. Confirm what must change: demo keystores present, SSL off, HTTP-only URLs, or no SSO asserter.

## Step 1 — Create the identity keystore and CSR (Configure)
1. Generate the server key pair into the identity keystore (alias `c2msec-server`), with CN/SAN covering
   every client-facing hostname (Requirement 2.4):
   ```
   keytool -genkeypair -alias c2msec-server -keyalg RSA -keysize 2048 \
     -dname "CN=your-hostname,OU=Utilities,O=your-org,C=US" \
     -ext "SAN=dns:your-hostname,dns:your-lb-hostname" \
     -keystore your-keystore-dir/C2MSEC-Identity-Pilot.jks -storetype JKS
   ```
   Enter the keystore and key passphrases at the prompt (Requirement 2.6) — never on the command line.
2. Produce a CSR and submit it to your CA (Requirement 2.3):
   ```
   keytool -certreq -alias c2msec-server -file your-keystore-dir/c2msec-server.csr \
     -keystore your-keystore-dir/C2MSEC-Identity-Pilot.jks
   ```
3. For a **lower** environment only, a self-signed certificate from Step 1.1 is acceptable and no CSR is
   needed; production must use a CA-signed certificate.

## Step 2 — Build the trust keystore and complete the chain (Configure)
1. Create the trust keystore and import the CA chain — **root first, then intermediate** — with the
   standard aliases:
   ```
   keytool -importcert -trustcacerts -alias c2msec-rootca -file your-rootCA.pem \
     -keystore your-keystore-dir/C2MSEC-Trust-Pilot.jks -storetype JKS
   keytool -importcert -trustcacerts -alias c2msec-intca -file your-intCA.pem \
     -keystore your-keystore-dir/C2MSEC-Trust-Pilot.jks
   ```
2. Import the **signed server certificate** back into the *identity* keystore under the **same alias**
   `c2msec-server` (the reply must chain to the CA certs already trusted):
   ```
   keytool -importcert -alias c2msec-server -file your-signed-server.pem \
     -keystore your-keystore-dir/C2MSEC-Identity-Pilot.jks
   ```
3. Verify both keystores: `keytool -list -v` shows the identity alias as a **PrivateKeyEntry** with a
   full chain, and the trust store shows the CA **trustedCertEntry** entries.

## Step 3 — Point WebLogic at the keystores (Configure)
Do this via WLST (repeatable) or the Console (`Environment → Servers → your-server → Configuration →
Keystores`). WLST, against the pilot server MBean:
```python
edit(); startEdit()
cd('/Servers/your-server')
cmo.setKeyStores('CustomIdentityAndCustomTrust')
cmo.setCustomIdentityKeyStoreFileName('your-keystore-dir/C2MSEC-Identity-Pilot.jks')
cmo.setCustomIdentityKeyStoreType('JKS')
cmo.setCustomIdentityKeyStorePassPhrase('from-your-vault')   # injected, never hard-coded
cmo.setCustomTrustKeyStoreFileName('your-keystore-dir/C2MSEC-Trust-Pilot.jks')
cmo.setCustomTrustKeyStoreType('JKS')
cmo.setCustomTrustKeyStorePassPhrase('from-your-vault')
save(); activate()
```
The passphrase is retrieved from the vault at runtime (Requirement 2.6), never written into a stored
script.

## Step 4 — Enable SSL/TLS on the domain (Configure)
1. Enable the SSL listen port and bind the private key, on the pilot server's SSL MBean:
   ```python
   edit(); startEdit()
   cd('/Servers/your-server/SSL/your-server')
   cmo.setEnabled(true)
   cmo.setListenPort(7002)                       # your chosen SSL port
   cmo.setServerPrivateKeyAlias('c2msec-server')
   cmo.setServerPrivateKeyPassPhrase('from-your-vault')
   cmo.setClientCertificateEnforced(false)       # one-way TLS first; two-way is Step 8
   cmo.setMinimumTLSProtocolVersion('TLSv1.2')   # verify attribute name for your version
   save(); activate()
   ```
2. Restart SSL (Console **Control → Restart SSL**, or restart the managed server) and confirm the SSL
   port is listening. Do **not** enable client-cert enforcement yet.
3. Retire the demo keystores from any server still using them — demo certs are never valid for
   production trust.

## Step 5 — Align C2M/OUAF to HTTPS (Configure)
1. As the product account, run **`configureEnv`** and set the web application server URL/protocol and
   port to the **HTTPS** endpoint (the SSL port from Step 4), so OUAF advertises `https` in links,
   callbacks, and inbound web-service URLs.
2. Run **`initialSetup`** to regenerate `web.xml`, `weblogic.xml`, and `spl.properties` from the
   templates with the new values. (Editing the generated files directly is overwritten on the next
   `initialSetup` — always change through `configureEnv`/templates; see Requirement 2.2.)
3. Redeploy/restart the OUAF applications as your install requires, and confirm C2M loads over `https`
   with the new certificate (no browser warning when CA-signed).

## Step 6 — Configure the SSO Identity Assertion Provider (Configure)
1. In the WebLogic security realm, add the Identity Assertion Provider that matches your SSO mechanism
   (Requirement 2.5) and name it **`C2MSEC-SSO-Asserter`** (`Security Realms → myrealm → Providers →
   Authentication → New`). For SAML, configure the SAML2 Identity Asserter and import the IdP **signing
   certificate** into the **trust** keystore (alias e.g. `c2msec-idpsign`); for an access-manager agent,
   configure the corresponding asserter for the asserted header/token.
2. Set the provider's active token/header type to the one the perimeter passes, and order the providers
   so the asserter runs ahead of the default authenticator. Restart the Administration Server if
   required for the new provider to take effect.

## Step 7 — Switch OUAF to accept the asserted identity (Configure)
1. Through **`configureEnv`**, set the OUAF web authentication method to **`CLIENT-CERT`** (so the
   application accepts the WebLogic-asserted user instead of showing its own form login), then run
   **`initialSetup`** to regenerate `web.xml`/`weblogic.xml` with that auth-method.
2. Confirm the asserted username maps to a valid **C2M user** (the username claim/header the IdP sends
   must resolve to a C2M user record). Redeploy/restart the OUAF applications.

## Step 8 — Pilot two-way SSL where required (Pilot)
1. If integrations require **mutual TLS**, first import each trusted client/issuer CA into
   `C2MSEC-Trust-Pilot.jks`, then set enforcement on the pilot server:
   ```python
   cd('/Servers/your-server/SSL/your-server')
   cmo.setClientCertificateEnforced(true)        # 'need'; use two-way SSL host verification as required
   save(); activate()
   ```
2. Restart SSL and confirm a caller **with** a trusted client cert connects and one **without** is
   correctly rejected. Enforce two-way SSL only where it is actually required — it breaks callers that
   lack a trusted client certificate.

## Step 9 — Validate the pilot (Validate)
1. Run `OC2MSEC-Validation.py` (read-only) to produce `Security Validation –
   C2M – Validation`: SSL port up, min TLS/cipher policy correct, identity chain valid and not near
   expiry, trust contains the expected CAs, asserter present, and OUAF on `CLIENT-CERT`.
2. Run `OC2MSEC-Report.py` to produce `Security Coverage – C2M – Report` — a per-server coverage sheet
   (Custom vs Demo, SSL on/off, TLS floor, cert expiry, SSO wired).
3. Complete the **Testing Guide** and pass the gate: SSO sign-in works, HTTPS endpoints are trusted,
   keystores validate, and no user or integration is broken.

## Step 10 — Expand across the domain (Expand)
1. Run `OC2MSEC-ScopeHelper.py` to enumerate the remaining in-scope servers as `Security Target – Domain
   – Stage2` and to stage the same keystore/SSL/SSO settings per server (each server presents its own
   identity certificate; trust and asserter are consistent).
2. Apply Steps 3–7 to each domain server (reusing the same aliases and provider name), re-run
   `OC2MSEC-Validation.*` and `OC2MSEC-Report.py`, and confirm domain-wide coverage.
3. Record certificate **expiry** dates and schedule rotation (see Best Practices) so trust never lapses.

---
### Order of operations
`Assess → Identity keystore + CSR → Trust chain → Point WebLogic at keystores → Enable one-way SSL →
Align C2M to HTTPS → SSO asserter → OUAF CLIENT-CERT → (optional) two-way SSL → Validate pilot → Expand domain`
