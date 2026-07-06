# 6. Troubleshooting Guide — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

Use `OC2MSEC-Discovery.sh` (on-disk keystores, `config.xml`, OUAF URL) and `OC2MSEC-Validation.py`
(live server MBeans) for current state, re-run `OC2MSEC-Validation.py` to confirm a fix, and
`OC2MSEC-Remediation.py` (**dry-run first**) for safe changes. WebLogic SSL
diagnostics come from the managed server log and `-Dweblogic.ssl.Verbose=true` / `-Dssl.debug=true`
where deeper handshake tracing is needed. None of the tooling prints private keys or passphrases.

## A. Keystore / trust errors
| Symptom | Cause | Remediation |
|---|---|---|
| Server fails to start SSL: private key not found | The SSL private-key alias does not match the identity keystore entry | Set `ServerPrivateKeyAlias` to `c2msec-server` (the alias used in Step 1); confirm with `keytool -list` |
| `unable to find valid certification path` on server-to-server calls | The peer/IdP CA is not in the trust keystore | Import the missing root/intermediate CA into `C2MSEC-Trust-<env>.jks` (`c2msec-rootca` / `c2msec-intca`) and restart SSL |
| Identity alias shows as `trustedCertEntry`, not `PrivateKeyEntry` | The signed cert was imported under a new alias instead of the original key alias | Re-import the CA reply under the **same** alias `c2msec-server` so it binds to the private key |
| Keystore load fails / bad password | Wrong keystore or key passphrase | Retrieve the correct passphrase from the vault (Requirement 2.6); never hard-code it |

## B. SSL/TLS won't terminate or is untrusted
| Symptom | Cause | Remediation |
|---|---|---|
| Browser warning "not trusted" | Self-signed cert, or client missing the enterprise CA | Use a CA-signed cert in production; ensure the client trusts the issuing CA |
| Hostname mismatch error | Certificate CN/SAN omits the URL's hostname (often the load-balancer FQDN) | Reissue with the hostname in the **SAN** (Requirement 2.4) |
| Handshake fails after WebLogic/JDK patch | Patch changed default protocols/ciphers | Re-set the TLS floor to 1.2+ and the approved cipher list; re-validate with `OC2MSEC-Validation.py` |
| SSL port not listening | SSL not enabled or server not restarted | Confirm `Enabled=true` and the listen port; restart SSL (Console **Restart SSL**) or the server |

## C. C2M still using HTTP
- Links/callbacks show `http` → the OUAF advertised URL/protocol was not updated, or the change was
  made only in the generated files. Set the HTTPS endpoint via **`configureEnv`**, run **`initialSetup`**
  to regenerate `web.xml`/`weblogic.xml`/`spl.properties`, and redeploy/restart (Requirement 2.2).

## D. SSO does not sign the user in
| Symptom | Cause | Remediation |
|---|---|---|
| C2M shows its own form login instead of SSO | OUAF not on `CLIENT-CERT`, or the auth-method change was overwritten by `initialSetup` | Set `CLIENT-CERT` via `configureEnv`, re-run `initialSetup`, redeploy |
| Assertion rejected / user not asserted | `C2MSEC-SSO-Asserter` missing, mis-ordered, or the IdP signing certificate not trusted | Confirm the asserter exists and runs ahead of the default authenticator; import the IdP signing cert into trust |
| Asserted but "user not found" | The IdP username claim/header does not map to a C2M user | Align the asserted username to a valid C2M user record; correct the claim/header mapping |
| SSO works but bypass is possible | A fallback path skips the asserter | Close the fallback so the negative-path test denies access (Testing Test 7) |

## E. Two-way SSL problems
- Legitimate caller rejected → its client certificate's issuer CA is not in the trust keystore, or
  enforcement was turned on before trust was ready. Import the client/issuer CA into trust, then confirm
  `ClientCertificateEnforced=true` only on the intended servers. If two-way SSL was enabled prematurely,
  set enforcement back to `false`, restore one-way TLS, and re-stage.

## F. Certificate expiry / rotation
- TLS suddenly fails for everyone on a specific date → the server or a CA certificate **expired**.
  Check expiry with `OC2MSEC-Discovery.sh`; import the renewed certificate under `c2msec-server` (or the
  renewed CA into trust), restart SSL, and bring the rotation schedule forward (Best Practices).

## G. Change made no difference / was lost
- A `web.xml`/`weblogic.xml` edit disappeared → it was made in a **generated** file and overwritten by
  `initialSetup`. Always change through `configureEnv`/templates. A WLST change that didn't apply → the
  edit session was not activated; re-run inside `startEdit()` … `save(); activate()`.

## H. Diagnostics quick reference
```
keytool -list -v -keystore your-keystore-dir/C2MSEC-Identity-Pilot.jks   # aliases, chain, expiry
keytool -list -v -keystore your-keystore-dir/C2MSEC-Trust-Pilot.jks      # trusted CA entries
openssl s_client -connect your-hostname:7002 -servername your-hostname   # protocol, chain, cert
java weblogic.WLST OC2MSEC-Validation.py                                 # read-only full check
```
(Never pass keystore passphrases on the command line; enter them at the prompt or inject from the vault.)

## I. When to escalate
If keystores validate, the CA chain and IdP signing certificate are trusted, one-way TLS terminates on
a modern floor, OUAF is on `CLIENT-CERT`, and SSO still fails, capture the managed-server SSL/handshake
log, the asserter configuration, and the (non-secret) `OC2MSEC-Discovery.sh` output, and open a **My
Oracle Support** case for the C2M/OUAF and WebLogic versions in scope — some SSO/IdP interoperability
notes are MOS-gated.
