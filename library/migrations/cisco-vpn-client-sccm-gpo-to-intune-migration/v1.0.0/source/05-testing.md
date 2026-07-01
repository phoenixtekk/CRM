# 5. Testing Guide — Migrating Cisco VPN Client Deployment from SCCM/GPO to Intune

Run per wave after the Intune objects apply (Implementation Step 9) and **before** removing that wave
from the legacy path. Each wave must clear the parity gate before cutover, and the final tests confirm
the legacy path is gone with no conflict.

> The VPN **tunnel-establishment** test exercises the Cisco head-end, which is out of scope to
> configure here; the test confirms the **Intune-delivered** client + profile + cert produce a working
> connection with parity to the legacy path.

## Test 1 — Client delivered by Intune (version parity)
Do: On a wave device, run `CVPNMIG-Validation.ps1`; confirm `Cisco Secure Client – Win32` installed and
the version matches the standardized version from inventory.
Expected: Client present at the expected version; Intune → app → `Device install status` = `Installed`.

## Test 2 — VPN profile delivered by Intune (profile parity)
Do: Confirm the profile XML is present in the client profile directory and matches the authoritative
source (`CVPNMIG-Validation.ps1` reports the profile and head-end list).
Expected: The Intune-delivered profile is byte-identical to the legacy profile; head-end list correct.

## Test 3 — Certificate delivered by Intune (cert parity)
Do: Confirm the SCEP-issued VPN client certificate is present with the right template intent (subject/
SAN, EKUs) and the trusted root is installed.
Expected: Certificate present from `Cisco VPN – Client Cert (SCEP)`; EKUs/subject match legacy; root
trusted.

## Test 4 — Tunnel establishes (functional parity)
Do: Initiate a VPN connection on the wave device using only the Intune-delivered client/profile/cert.
Expected: The tunnel connects and passes traffic exactly as it did under SCCM/GPO delivery.

## Test 5 — No double-deployment conflict
Do: On a **cut-over** device, run `CVPNMIG-Discovery.ps1`.
Expected: The client/profile/cert show **Intune** as the only source — **no** SCCM deployment targeting
the device and **no** GPO applying (`gpresult` clean); no reinstall loop in the IME log.

## Test 6 — Wave targeting parity
Do: Run `CVPNMIG-Set-ScopeTargeting.ps1` (or check `Assignments`) — the current wave group is targeted
and cut-over waves have left the SCCM collection / GPO scope.
Expected: The same devices that had the legacy VPN are in the Intune wave; legacy scope shrinks each
wave.

## Test 7 — Fleet progress / coexistence report
Do: Run `CVPNMIG-Report.ps1`.
Expected: A legacy-vs-Intune count per wave; the Intune-managed share rises each cycle; laggards flagged.

## Test 8 — Legacy retired (final)
Do: After the last wave, confirm the SCCM deployment/package is removed and the GPO(s) are unlinked;
run `CVPNMIG-Report.ps1` and `CVPNMIG-Discovery.ps1` across a sample.
Expected: 100% Intune-managed; **zero** legacy SCCM/GPO artifacts remain.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Per-wave parity pass** | Tests 1–4 pass on the wave (client + profile + cert present, tunnel connects) before removing the wave from legacy |
| **No-conflict pass** | Test 5 passes on every cut-over device — exactly one delivery authority, no reinstall loop |
| **Migration-complete pass** | Test 8 passes — all waves Intune-managed and the SCCM package + GPO(s) retired with no residue |
