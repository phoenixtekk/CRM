# 8. Deliverables Summary — Oracle C2M SSO, SSL & Certificate/Keystore Configuration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | The C2M security model — SSO, SSL/TLS termination, and the identity/trust keystore chain on WebLogic — with the naming convention and limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Oracle) | Category-wide prerequisites (entitlement, certified stack, environments, tooling, change control, teams), published once |
| 3. Implementation Guide | Exact, ordered `keytool` + WLST/Console + `configureEnv`/`initialSetup` steps (assess → keystores → one-way SSL → HTTPS for C2M → SSO asserter → OUAF `CLIENT-CERT` → two-way SSL → validate → expand) |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Certificate lifecycle, key rotation, and safe-order recommendations |

## Automation scripts (WLST / shell / SQL — never PowerShell)
| Script | What it does |
|---|---|
| `OC2MSEC-Discovery.sh` | **Read-only** shell discovery: `keytool -list` inventory of keystore files (aliases, entry types, certificate expiry), each server's SSL/keystore attributes read from the domain `config.xml`, and the OUAF advertised URL/protocol from `$SPLEBASE/etc`. Writes `Security Baseline – C2M – Discovery`. Never prints private keys or passphrases |
| `OC2MSEC-Validation.py` | **Read-only** WLST checks against the live server MBeans: keystore rule Custom (not Demo), SSL enabled on the expected port, TLS floor correct, identity chain valid and not near expiry, trust holds the expected CAs, `C2MSEC-SSO-Asserter` present and ordered, OUAF on `CLIENT-CERT`. Writes `Security Validation – C2M – Validation` |
| `OC2MSEC-Report.py` | **Read-only** WLST per-server coverage report (Custom vs Demo, SSL on/off, TLS floor, certificate expiry, SSO wired). Writes `Security Coverage – C2M – Report` |
| `OC2MSEC-Remediation.py` | Safe WLST remediation (point servers at Custom Identity/Trust, enable SSL, set TLS floor, set client-cert enforcement, add/order the asserter). **DRY-RUN by default**; `-execute` to apply. Reads passphrases from the vault/prompt at runtime; never prints or stores secrets |
| `OC2MSEC-ScopeHelper.py` | Enumerates in-scope servers and stages the pilot (`Security Target – Pilot – Stage1`) vs domain (`Security Target – Domain – Stage2`) target sets so keystore/SSL/SSO settings are applied consistently per server |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All **automation scripts** (WLST/Jython, shell) in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
C2M secured end to end — **SSO** working through the enterprise IdP, **SSL/TLS** valid on the WebLogic
domain and C2M, and the **identity/trust keystores** correct, trusted, and on a rotation schedule —
proven on a pilot server before the domain is expanded, with secrets never exposed by the tooling.
