# 7. Best Practices — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

- **Separate identity and trust keystores, always.** Keep the private key and server certificate in the
  **identity** keystore (`C2MSEC-Identity-<env>.jks`) and CA certificates in the **trust** keystore
  (`C2MSEC-Trust-<env>.jks`). Mixing them makes rotation and least-privilege custody harder.
- **Never run production on demo keystores.** `DemoIdentity.jks` / `DemoTrust.jks` are for illustration
  only; retire them as part of Step 4 and confirm via `OC2MSEC-Discovery.sh` that no production server
  still references them.
- **CA-signed in production; self-signed only in lower environments.** A self-signed cert produces
  warnings and breaks server-to-server trust — acceptable in Dev/Test, never in Prod.
- **Plan CN and SAN for every client-facing name.** Include the load-balancer/vanity FQDN in the SAN
  before requesting the certificate; a missing SAN fails hostname validation even with a valid cert.
- **Configure in the safe order.** Build keystores → one-way TLS → align C2M to HTTPS → SSO →
  (only if required) two-way SSL. Never enable `CLIENT-CERT` or client-cert enforcement before plain
  one-way TLS is confirmed working.
- **Enforce a modern TLS floor.** Set minimum TLS to **1.2+** and a curated cipher list; refuse
  TLS 1.0/1.1. Re-check after WebLogic/JDK patching, which can shift defaults.
- **Own the certificate lifecycle — rotation is scheduled, not hoped for.** Record every certificate's
  **expiry** from `OC2MSEC-Discovery.sh`, alert well ahead (e.g. 60/30 days), and rotate on a calendar.
  Rotate by generating a new key/CSR, importing the new signed cert under the **same alias**
  `c2msec-server` (or a versioned alias with a cutover), and restarting SSL — in a change window with a
  backup of the previous keystore for rollback.
- **Refresh trust before it lapses.** Import renewed root/intermediate CA certs into trust ahead of the
  old ones expiring; keep IdP signing certificates current in trust so SSO assertions keep validating.
- **Protect passphrases and private keys.** Keep keystore/key passphrases in a vault, inject them at
  change time, and restrict OS permissions on keystore files to the product account. Never place
  passphrases or keys in scripts, docs, exports, or `config.xml` in clear form.
- **Persist changes through OUAF templates.** Set the HTTPS URL/protocol and the `CLIENT-CERT`
  auth-method via `configureEnv`, then `initialSetup`; changes made only to generated
  `web.xml`/`weblogic.xml` are lost on the next regeneration.
- **Keep the SSO fallback closed.** Ensure there is no path that silently bypasses the asserter; the
  negative-path test (untrusted/absent assertion) must deny access.
- **Pilot, then expand — with rollback ready.** Prove the whole chain on one server/environment, keep
  backups of `config.xml`, the domain `security` directory, `$SPLEBASE/etc`, and each keystore, and
  only then apply the same named artifacts across the domain.
- **Make security state auditable.** Run the read-only `Discovery → Validation → Report` chain on a
  schedule so drift (a demo keystore reappearing, SSL turned off, a cert nearing expiry, TLS floor
  lowered) is caught before it becomes an outage or an audit finding.
