# 5. Testing Guide — Epic Hyperdrive & Hyperspace Client Deployment & Lifecycle Management with Microsoft Intune

Run these validations after the pilot is deployed (Implementation Phase D) and again after the broad
deployment and after every lifecycle change (upgrade / retire). Each test states **what to do** and
the **expected (PASS) result**. **Do not expand the rollout until every pilot test passes.**

> Run on a device in **`Epic Hyperdrive – Pilot Ring`** first. Use the scripts where named; capture
> results in your change log for the clinical change record.

## Test 1 — The Epic client installed
**Do:** On a pilot device run **`EPICCLIENT-Discovery.ps1`**, or check `<EPIC_INSTALL_DIR>` for
`<EPIC_EXE>`.
**PASS:** The Epic client is present in `<EPIC_INSTALL_DIR>`; Discovery reports an installed version.
**FAIL:** Not installed — see Troubleshooting §6 (install failures) and `EPICCLIENT-Remediation.ps1`.

## Test 2 — The installed version is the target version
**Do:** Run **`EPICCLIENT-Validation.ps1`** (compares the installed version to the target), or read
the file version of `<EPIC_EXE>`.
**PASS:** Installed version **equals** `<EPIC_VERSION>` (the value pinned in the detection rule).
**FAIL:** Version mismatch — detection rule or supersedence issue (Troubleshooting §6, version drift).

## Test 3 — Intune reports the app Installed (no errors)
**Do:** Intune → **Apps → Windows → `Epic Hyperdrive – <EPIC_VERSION>` → Device install status**.
**PASS:** Pilot devices show **Installed**; no **Failed** or detection-mismatch states.
**FAIL:** Failed / "Not installed" despite the binary present → detection-rule mismatch
(Troubleshooting §6).

## Test 4 — The client launches and loads
**Do:** On the pilot device, launch the Epic client (Hyperdrive or Hyperspace) as a clinical user.
**PASS:** The client opens, renders fully, and connects to the **correct Epic environment**. For
**Hyperdrive**, the WebView2 surface renders (no blank / white window).
**FAIL:** Crash, blank window, or wrong environment → Troubleshooting §6 (WebView2 / launch issues).

## Test 5 — WebView2 runtime present (Hyperdrive)
**Do:** Run **`EPICCLIENT-Validation.ps1`** (checks the WebView2 runtime).
**PASS:** The **Microsoft Edge WebView2 Runtime** is present and reported.
**FAIL:** Missing → deploy/repair WebView2 (Requirements §R5, Implementation Step 6).
*(N/A for Hyperspace-only deployments.)*

## Test 6 — Imprivata badge-tap into Epic still works (if integrating)
**Do:** On the pilot device, perform a **badge tap** and confirm tap-to-launch / SSO into the Epic
client.
**PASS:** The tap launches and authenticates into Epic as before the client change.
**FAIL:** Tap no longer launches Epic → confirm the Imprivata agent is healthy and engage the
separate Imprivata solution / administrators (this solution does not configure Imprivata).
*(N/A if you do not use Imprivata — Requirements §R11.)*

## Test 7 — No leftover old version after an upgrade / retire
**Do:** After a supersedence upgrade (Step 15) or a retire (Step 16), run
**`EPICCLIENT-Discovery.ps1`** / **`EPICCLIENT-Validation.ps1`**.
**PASS:** Only the **intended** version is present (or, for a retire, **no** Epic client remains); no
second/old version coexists in `Apps & features` or `<EPIC_INSTALL_DIR>`.
**FAIL:** Old version still present → Troubleshooting §6 (supersedence not upgrading / retire
leftovers).

## Test 8 — Ring rollout is healthy
**Do:** Run **`EPICCLIENT-Report.ps1`** and review Intune **Device install status** per ring.
**PASS:** `Epic Hyperdrive – Pilot Ring` is fully Installed at the target version **before** broad;
after broad, `Epic Hyperdrive – Broad Ring` converges to the target version with an acceptable
failure rate.
**FAIL:** Stuck installs / mixed versions in a ring → Troubleshooting §6 (ring / assignment
problems).

## Test 9 — Device compliance and clinical function intact
**Do:** Intune → **Devices → Compliance** for the pilot/broad devices; confirm clinical peripherals
relied on at launch (badge reader, etc.) still function.
**PASS:** Devices remain **Compliant**; no new failures introduced by the client change.
**FAIL:** New compliance failures or broken clinical function → roll back per Requirements §R10.

---

## Acceptance gate

| Gate | Requirement |
|---|---|
| **Pilot pass (required before broad deploy)** | Tests **1, 2, 3, 4, 8, 9** pass for **100%** of `Epic Hyperdrive – Pilot Ring`; **Test 5** passes for Hyperdrive; **Test 6** passes if Imprivata is integrated |
| **Broad pass** | Tests **1, 2, 3, 4, 8** pass across `Epic Hyperdrive – Broad Ring` at an agreed success threshold; **Test 9** shows no new compliance failures |
| **Lifecycle pass (after upgrade / retire)** | **Test 7** passes (no leftover old version), plus Tests 2, 4, 8 for the new state |

Record results in the clinical change log. If any test fails, use the **Troubleshooting Guide
(Section 6)** and **`EPICCLIENT-Remediation.ps1`** before proceeding, and trigger the rollback plan
if the failure affects patient-care devices.
