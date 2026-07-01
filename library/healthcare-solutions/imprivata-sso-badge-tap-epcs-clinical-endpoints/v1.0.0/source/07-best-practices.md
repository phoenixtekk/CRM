# 7. Best Practices — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

These practices keep the deployment safe, fast, and compliant across the lifecycle. They complement — they do not replace — your Imprivata administrator's appliance guidance and your compliance team's EPCS/DEA requirements.

## Identity and ownership

- **Keep one source of truth for identity.** Ensure OneSign authenticates against the same directory (Entra/AD) that Intune and the endpoints use. Reconcile leavers/joiners in that directory promptly so badges always map to valid, current clinician accounts.
- **Respect the ownership boundaries.** Appliance computer policy, application profiles, and Confirm ID/EPCS configuration are owned by the Imprivata admin and compliance. Use Intune for delivery (agent, drivers, OS baseline, group, reporting) and confirm policy values with the owners rather than guessing.
- **Use least privilege.** Scope Intune roles to what the work needs and activate privileged roles only for the change window.

## Deployment hygiene

- **Pilot before fleet, always.** Validate on the representative test device and `IMPRIVATA – Clinical Endpoints – Pilot` before adding the full `IMPRIVATA – Clinical Endpoints` group. Expand in controlled waves within approved maintenance windows.
- **Sequence the driver before the agent** where your Imprivata admin requires it — use a Win32 **dependency** so the reader driver is present before the agent installs, preventing "reader not detected" on first tap.
- **Pin and record versions.** Record the exact agent version, installer/uninstaller command lines, and detection criteria from your Imprivata admin in change control, and keep the Win32 app's publisher set to `Imprivata, Inc.` (and the reader driver to the exact vendor string).
- **Use device-targeted assignments** for shared endpoints — assign apps and the baseline profile to the device group, not to users, so the experience follows the shared device.

## Shared-device behavior

- **Tune tap-out / lock for the ward.** Confirm with clinical operations and the Imprivata admin whether tap-out should lock, log off, or switch — and that idle-lock timing matches clinical workflow without leaving sessions exposed.
- **Never leave a session attributable to the wrong clinician.** Validate fast user switching so clinician A's session is always secured before clinician B is active; this is both a safety and an attribution requirement.

## EPCS and compliance

- **Treat EPCS as a regulated gate, not a feature toggle.** No prescriber signs controlled substances until identity proofing, two-factor enrollment, and supervised approval are complete. Keep these owned by compliance/pharmacy and the Imprivata admin.
- **Verify two factors are genuinely independent.** Confirm the approved factor combination meets DEA requirements (something you have + something you are/know) per compliance — do not assume badge alone satisfies EPCS.
- **Protect the audit trail.** Confirm auditing is enabled, attributed correctly, and retained per policy. Establish authorized, read-only review access before EPCS go-live.

## Operations and monitoring

- **Report coverage continuously.** Run `IMPRIVATA-Report.ps1` after each wave and on a schedule to track agent install state and group coverage; investigate any endpoint that drifts out of compliance.
- **Validate, don't assume, after changes.** Re-run the relevant `05-testing.md` checks (especially T2 reader, T4 tap, T6 SSO, T7 EPCS) after agent upgrades, OS updates, or policy changes.
- **Keep a rehearsed rollback.** Maintain and periodically rehearse the back-out (uninstall assignment, profile removal, group removal, policy revert) so a sign-on regression on a shared clinical endpoint can be reversed quickly.

## Data handling

- **No PHI in artifacts.** Keep reports, logs, and screenshots free of PHI. Use test accounts and test data for all validation, and never sign a real controlled-substance order during testing.
