# 5. Testing & Validation — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

Test **on the pilot OU (`Security Baseline - Pilot`) first**, using synthetic test data only. Each
test states what to do, the **expected (pass)** result, and the **fail** signal. Re-run after every
promotion (audit→block, monitor→enforce) and after each expansion wave.

> Use **synthetic** sensitive values for DLP tests (e.g. the standard `4111 1111 1111 1111` test
> card number, a fake national-ID pattern). Never test with real regulated data.

## A. Hardening baseline (Layer 1)

| # | Test | Pass | Fail |
|---|---|---|---|
| A1 | Sign in as a pilot user | Prompted for 2SV (phone prompt / security key / passkey) | No second factor requested — enforcement not applied to the OU |
| A2 | Leave a web session idle past the configured window | Reauthentication (password / key) required on return | Session persists indefinitely — session control not set for the OU |
| A3 | Share a Drive doc to an outside-domain address | Warning shown / sharing constrained per policy | Silent external share with no warning — sharing setting not applied |
| A4 | Attempt legacy/basic-auth mail client sign-in | Refused | Legacy client connects — less-secure surface still open |
| A5 | Count super-admins (Admin roles) | Minimal, all 2SV-enrolled with backup codes | Excess or un-enrolled super-admins |

Run **`GWSEC-Validation.ps1 -OrgUnitPath '/Security Baseline - Pilot'`** — baseline checks report
**PASS** for the OU.

## B. DLP for Drive & Gmail (Layer 2) — *edition-gated*

| # | Test | Pass | Fail |
|---|---|---|---|
| B1 | (Audit phase) Externally share a Drive file containing a synthetic card/ID string | Incident logged in **Data protection** / security investigation tool; share allowed | No incident — rule scope/detector/trigger wrong |
| B2 | (Audit phase) Send outbound Gmail with the same synthetic string | Incident logged | No incident — Gmail rule not matching |
| B3 | (Block phase) Repeat B1 after graduating to **Block external sharing** | External share **blocked** with user notice | Share still succeeds — action not promoted / OU not in scope |
| B4 | (Block phase) Repeat B2 after **Block delivery / Quarantine** | Message blocked / quarantined | Message delivered — action not promoted |
| B5 | Negative test — share/send a benign file with no sensitive data | No incident, no block (no false positive) | Benign content blocked — detector too broad, tune threshold |

## C. Context-Aware Access (Layer 3) — *edition-gated*

| # | Test | Pass | Fail |
|---|---|---|---|
| C1 | (Monitor phase) Access Drive/Gmail from **off-network / non-compliant** context | Access allowed but **would-block** logged in monitor | Nothing logged — access level not assigned / signals missing |
| C2 | (Enforce phase) Access from a **compliant** context (corp IP / managed device) | Access granted | Compliant user blocked — access-level signal wrong (IP range, device attribute) |
| C3 | (Enforce phase) Access from a **non-compliant** context | Access **blocked** by CAA | Access granted — assignment still in monitor, not enforce |
| C4 | Admin-console access from off-network (privileged OU) | Blocked per `Access - Corp Network` assignment | Admin console reachable off-network |

Run **`GWSEC-Validation.ps1`** — CAA assignment state (monitor vs enforce) and access-level presence
report as expected for the OU.

## D. Coverage & exceptions (fleet)
- Run **`GWSEC-Report.ps1`** — confirm the coverage view shows the baseline, DLP rules, and CAA
  assignments applied to each in-scope OU, with any exceptions explicitly listed and owned.
- Confirm the **rollback** for each control has been rehearsed at least once on the pilot OU (relax
  session, re-widen sharing, DLP→audit, CAA→monitor) and returns the OU to the pre-change state.

## Exit criteria (before expanding past the pilot)
- All Section A tests **PASS** on the pilot OU.
- DLP fires in audit **and** blocks after promotion (B1–B4), with no false positives (B5).
- CAA logs in monitor, grants compliant and blocks non-compliant after enforce (C1–C4).
- `GWSEC-Validation.ps1` passes for the pilot OU and `GWSEC-Report.ps1` shows clean coverage.
- Rollback verified. Only then proceed to Implementation Step 7 (expand).
