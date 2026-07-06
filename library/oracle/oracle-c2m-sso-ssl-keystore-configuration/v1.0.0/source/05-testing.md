# 5. Testing Guide — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

Run after each configuration stage. Every test is **read-only or non-destructive**; the pilot is the
gate before the domain is expanded. Use the read-only scripts for state and standard client tools
(browser, `openssl s_client`, `keytool -list`) to confirm from the outside.

## Test 1 — Baseline captured
**Do:** Run `OC2MSEC-Discovery.sh` (on-disk keystores + config.xml + OUAF URL) and `OC2MSEC-Validation.py`
(live server MBeans).
**Expected:** `Security Baseline – C2M – Discovery` lists every server's KeyStores rule, identity/trust
files, private-key alias, SSL port/state, client-cert enforcement, TLS floor, and auth providers; the
on-disk keystore inventory shows aliases and expiry. No demo keystore remains flagged for a production
server after Step 4.

## Test 2 — Keystores are valid and chained
**Do:** `keytool -list -v` on the identity and trust keystores (or read the `OC2MSEC-Discovery.sh` output).
**Expected:** Identity alias `c2msec-server` is a **PrivateKeyEntry** with a full chain to the CA; trust
holds `c2msec-rootca` (and `c2msec-intca`) as **trustedCertEntry**; no entry is expired or within the
rotation threshold.

## Test 3 — One-way SSL/TLS terminates correctly
**Do:** From a client, `openssl s_client -connect your-hostname:7002` (or load the C2M HTTPS URL in a
browser).
**Expected:** The server presents `c2msec-server`, the chain validates against the enterprise CA
(no warning when CA-signed), and the negotiated protocol is **TLS 1.2+**. HTTP-only access is gone or
redirected.

## Test 4 — Minimum TLS and cipher policy enforced
**Do:** Attempt a TLS 1.0/1.1 handshake (`openssl s_client -tls1_1 ...`) and inspect negotiated ciphers.
**Expected:** Legacy protocols are refused; only the approved TLS 1.2+ ciphers negotiate — matching
`Security Validation – C2M – Validation`.

## Test 5 — C2M advertises HTTPS
**Do:** Open C2M and inspect generated links/callbacks; check `$SPLEBASE/etc` values via
`OC2MSEC-Discovery.sh`.
**Expected:** OUAF advertises the `https` endpoint (from `configureEnv`/`initialSetup`); inbound
web-service URLs and in-app links use `https`, not `http`.

## Test 6 — SSO sign-in works
**Do:** Access C2M through the enterprise SSO path with a test user.
**Expected:** The IdP authenticates the user, WebLogic's `C2MSEC-SSO-Asserter` asserts identity, OUAF
(on `CLIENT-CERT`) accepts it and maps to the correct C2M user — **no** separate C2M form-login prompt.

## Test 7 — SSO negative path is safe
**Do:** Attempt access without a valid SSO assertion / with an untrusted assertion.
**Expected:** Access is denied cleanly (no fallback that bypasses SSO); the asserter rejects an
assertion whose signing certificate is not in the trust keystore.

## Test 8 — Two-way SSL enforcement (only where configured)
**Do:** On a server with `ClientCertificateEnforced=true`, connect once **with** a trusted client cert
and once **without**.
**Expected:** The trusted client connects; the untrusted/absent-cert client is rejected — mutual TLS is
actually enforced, and only on the intended servers.

## Test 9 — Validation and coverage are clean
**Do:** Run `OC2MSEC-Validation.py` and `OC2MSEC-Report.py`.
**Expected:** `Security Validation – C2M – Validation` shows all checks pass for the pilot;
`Security Coverage – C2M – Report` shows the pilot server Custom+SSL+SSO with a valid, non-expiring
certificate.

## Test 10 — Domain expansion is consistent
**Do:** After Step 10, re-run `OC2MSEC-Report.py` across `Security Target – Domain – Stage2`.
**Expected:** Every in-scope server reports Custom Identity/Trust, SSL on, TLS 1.2+ floor, SSO asserter
present, OUAF on `CLIENT-CERT`, and each server presents its own valid certificate.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–9 pass on `Security Target – Pilot – Stage1`: keystores valid, one-way TLS 1.2+ terminating, C2M on HTTPS, SSO sign-in working and negative path safe, (if used) two-way SSL enforced — with zero broken users/integrations |
| **Domain pass** | Test 10 passes for `Security Target – Domain – Stage2`; every server reports Custom keystores, SSL on, SSO wired, and valid non-expiring certificates before rotation is scheduled and change control is closed |
