# Testing — Confirming the Toolkit and the Fix

Two things get tested here. First, that the **toolkit itself runs correctly** — it must report a
known-good device as healthy and a known-bad device as failing, so you can trust its verdicts.
Second, that a **fix actually cleared** the failing precondition. Each check has an explicit
**pass/fail gate**. All checks here are **read-only** — you observe; you never force a state.

> Reuse names verbatim: **`Pre-Logon VPN – Device Tunnel – Profile`**,
> **`Pre-Logon VPN – SBL Module – Win32`**, **`Pre-Logon VPN – SBL – Profile`**,
> **`Pre-Logon VPN – Trusted Root`**, **`Pre-Logon VPN – Device Cert (SCEP)`**,
> **`PILOT – Pre-Logon VPN Devices`**.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Collector runs and writes a report | Any device | Report written; mechanism + symptom named |
| T2 | Known-good device reports healthy | Reference device (R6) | Intended mechanism all PASS |
| T3 | Known-bad device reports the fault | Failing device | The tool FAILs on the true missing precondition |
| T4 | SBL/PLAP checks are accurate | SBL device | Tile-present ⇔ all SBL preconditions PASS |
| T5 | Device-tunnel checks are accurate | Device-tunnel device | Tunnel-up ⇔ all device-tunnel preconditions PASS |
| T6 | Certificate deep-check is accurate | Any device | Verdict matches the actual cert state |
| T7 | Intune check finds + scopes objects | Operator workstation | Objects found, assigned, correctly scoped |
| T8 | Post-fix re-run comes back clean | Fixed device | Failing precondition now PASS; tile/tunnel works |

---

## T1 — Collector runs and writes a report
**Steps:** On any Windows device, run `PLAPDX-Collect-Diagnostics.ps1 -OutFile .\plapdx-report.txt`
elevated.
**PASS:** The console shows the per-area summary and `plapdx-report.txt` is written, ending with a
flagged mechanism and symptom.
**FAIL:** The script errors or can't read `LocalMachine\My` / the Credential Providers key → run
elevated (R2) and re-test.

## T2 — Known-good device reports healthy (no false positives)
**Steps:** Run the focused tool for the **working** reference device's mechanism
(`PLAPDX-Check-PlapSbl.ps1` or `PLAPDX-Check-DeviceTunnel.ps1`).
**PASS:** Every precondition for the intended mechanism reports **PASS**, matching the fact that the
device brings up pre-logon connectivity.
**FAIL:** A precondition reports FAIL on a device that demonstrably works → the check's expectation is
mis-set (e.g. wrong expected issuer); reconcile before trusting it on the failing device.

## T3 — Known-bad device reports the true fault (no false negatives)
**Steps:** On the failing device, run the tool the symptom points to (see the `03-implementation.md`
symptom→tool map).
**PASS:** The tool FAILs on the **actual** missing precondition (confirmed against `06-troubleshooting.md`).
**FAIL:** The tool reports all PASS on a device that clearly doesn't work → the fault is beyond the
device (gateway CA trust / service, R7) or a check gap; escalate with evidence.

## T4 — SBL/PLAP checks are accurate
**Steps:** On an SBL device, run `PLAPDX-Check-PlapSbl.ps1` and compare to the logon screen.
**PASS:** All four SBL preconditions PASS **iff** the **Network sign-in** tile actually appears; any
FAIL corresponds to a genuinely missing module / flag / registration.
**FAIL:** Tile present but a precondition FAILs (or vice-versa) → investigate the discrepancy per
`06-troubleshooting.md §SBL/PLAP`.

## T5 — Device-tunnel checks are accurate
**Steps:** On a device-tunnel device, run `PLAPDX-Check-DeviceTunnel.ps1` and compare to
`Get-VpnConnection -AllUserConnection` and boot behavior.
**PASS:** SKU/join, single-tunnel, IKEv2, machine cert, and AlwaysOn all PASS **iff** the device tunnel
connects before logon.
**FAIL:** Tunnel up but a precondition FAILs (or the reverse) → investigate per
`06-troubleshooting.md §Device tunnel`.

## T6 — Certificate deep-check is accurate
**Steps:** Run `PLAPDX-Check-Certificate.ps1` (optionally `-CaThumbprint <expected>`) and compare to
`certlm.msc` (Local Computer → Personal → Certificates).
**PASS:** The tool's present / expiry / EKU / chain / private-key / issuer verdicts match what
`certlm.msc` shows.
**FAIL:** Any verdict disagrees with the store → confirm you ran elevated (private-key visibility needs
it) and re-test.

## T7 — Intune check finds and correctly scopes objects
**Steps:** Run `PLAPDX-Check-Intune.ps1` against the tenant.
**PASS:** Each expected object (`Pre-Logon VPN – SBL Module – Win32`, `Pre-Logon VPN – SBL – Profile`,
`Pre-Logon VPN – Device Tunnel – Profile`, `Pre-Logon VPN – Trusted Root`,
`Pre-Logon VPN – Device Cert (SCEP)`) is found, shows its assignment, and the device-tunnel profile is
flagged **OK (device group)** — or flagged **MIS-SCOPED** if assigned to a user group.
**FAIL:** An object shows MISSING that exists in the portal → confirm it is named to convention
verbatim (including the en-dash `–`).

## T8 — Post-fix re-run comes back clean
**Steps:** After remediating (Phase 3), re-run the focused tool and the collector, then reboot and
watch the logon screen / boot.
**PASS:** The previously-failing precondition now PASSes, the collector shows no other FAIL, and the
device shows the **Network sign-in** tile (SBL) or connects the **device tunnel** before logon.
**FAIL:** Still failing → return to the matching branch in `03-implementation.md` /
`06-troubleshooting.md`.

---

## Overall exit criteria
The toolkit passes T1–T7 (it reports a known-good device healthy and a known-bad device's true fault),
and for a closed incident T8 confirms the failing precondition now PASSes and the device demonstrably
brings up pre-logon connectivity. Record results against each gate before closing.
