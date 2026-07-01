# 6. Troubleshooting — Imprivata SSO, Badge-Tap & EPCS Integration for Clinical Endpoints

Symptom-driven fixes for the most common issues across the deployment. Work top-down within each symptom. Object names match `03-implementation.md`: Win32 apps `Imprivata Agent – Clinical Endpoints – Deploy` and `Proximity Reader Driver – Clinical Endpoints – Deploy`, device group `IMPRIVATA – Clinical Endpoints` (pilot subset `IMPRIVATA – Clinical Endpoints – Pilot`), profile `Imprivata Endpoint – Clinical Endpoints – Baseline`. Appliance-side policy values and EPCS/DEA specifics are owned by your **Imprivata administrator** and **compliance team** — escalate to them where indicated rather than guessing.

---

## Reader not detected

- **Confirm the driver deployed.** In `Apps > All apps > Proximity Reader Driver – Clinical Endpoints – Deploy > Monitor`, confirm **Installed** for the device. If **Failed/Pending**, see "Agent or driver app won't install" below.
- **Check Device Manager.** On the endpoint, open **Device Manager** and look for the reader. If it shows a warning/error icon, the driver is missing or mismatched — confirm the reader make/model matches the deployed driver (R3) and that the model is one your Imprivata admin supports.
- **Check install order.** If the agent installed before the driver, the reader may not bind on first tap. Set the reader-driver app as a **dependency** of the agent (Intune `Apps > Imprivata Agent – Clinical Endpoints – Deploy > Dependencies`) and re-sync, or reinstall the driver then the agent.
- **HID-class readers.** For driverless HID readers, no driver app is expected; confirm the reader enumerates as an HID device and is enabled.
- **Physical.** Reseat/replace the USB reader; test on the representative test device to isolate hardware vs. software.

## Badge not enrolling

- **Confirm directory mapping.** Badge enrollment binds a badge to a directory identity (R5). Confirm the clinician's account exists and is enabled in the directory OneSign authenticates against, and that it is the same directory used by Intune/Entra.
- **Confirm appliance reachability.** Enrollment requires the agent to reach the appliance. From the endpoint, confirm reachability to the appliance host/port your Imprivata admin specified (R1, G5). A blocked path causes enrollment to hang or fail.
- **Confirm enrollment policy.** With your Imprivata admin, confirm the endpoint inherits a computer policy that permits self-enrollment / first-tap binding. Escalate the policy value to the admin — do not change appliance policy yourself.
- **Badge format.** Confirm the badge technology/format is one the reader and OneSign deployment support.

## Slow tap (latency on tap-in)

- **Check appliance reachability/latency.** Slow tap-in is often network latency to the appliance or to the directory during the auth/broker step. Test reachability and round-trip from the endpoint; involve networking if latency is high.
- **Check directory responsiveness.** If OneSign authenticates against a remote DC/Entra, slow directory responses slow tap-in. Confirm the endpoint uses a responsive directory path.
- **Check SSO scope at tap.** If many application profiles fire at tap-in, sign-on can feel slow. With your Imprivata admin, review which application profiles launch on tap vs. on demand.
- **Endpoint health.** Confirm the endpoint meets the supported OS/build (R6) and isn't resource-starved; reboot to clear transient agent state.

## SSO fails to Epic (or clinical web apps)

- **Confirm the application profile.** SSO into Epic is driven by an Imprivata **application profile** owned by your Imprivata admin and coordinated with the Epic/EHR team. Confirm the profile is assigned to the endpoint/user and is current with the Epic client version.
- **Confirm Epic-side configuration.** Epic credential vaulting / launch settings are owned by the Epic team. If only Epic SSO fails (badge tap and other apps work), escalate to Epic + Imprivata admin.
- **Confirm reachability to Epic.** From the endpoint, confirm the Epic/clinical web app URLs supplied by the EHR team are reachable (G5).
- **Confirm credentials are vaulted.** First-time SSO often requires the clinician to authenticate once so OneSign can vault the credential; confirm that one-time step completed for the clinician.

## Fast-user-switch issues

- **Confirm OS profile applied.** In `Devices > Configuration > Imprivata Endpoint – Clinical Endpoints – Baseline`, confirm the profile shows **Succeeded** on the device and that fast user switching is enabled at the OS level.
- **Confirm appliance computer policy.** The switch/tap-out behavior (lock vs. log off vs. switch) is set by the appliance computer policy. If the OS profile and appliance policy conflict, behavior is inconsistent — reconcile values with your Imprivata admin so they agree.
- **Confirm shared-device model.** Ensure the device is treated as shared (R7) and assignments are device-targeted, not user-targeted, so the experience follows the device.
- **Session security.** If clinician A's session is briefly exposed during a switch, treat as a safety defect — escalate the policy timing to the Imprivata admin and re-run test T5.

## EPCS two-factor failures

- **Confirm enrollment + approval.** EPCS signing requires the prescriber to be identity-proofed, enrolled in **Confirm ID** with the approved two factors, and granted access via the supervised approval (R8, R2). Confirm all three with compliance/pharmacy and the Imprivata admin before debugging anything technical.
- **Confirm both factors are valid.** A rejected signing usually means one factor failed (wrong PIN, unenrolled/failed biometric, wrong badge). Confirm the prescriber is using the **approved** factor combination — defer the approved factors to compliance.
- **Confirm Confirm ID reachability.** The two-factor prompt depends on the agent reaching the appliance/Confirm ID; confirm reachability (R1, G5).
- **Confirm the Epic EPCS workflow.** If signing never triggers a prompt, the Epic EPCS signing workflow may not be wired to Confirm ID — escalate to the Epic team + Imprivata admin.
- **Do not work around EPCS.** Never disable or bypass two-factor to "unblock" signing — that breaks DEA compliance. Escalate to compliance.

## Audit gaps (missing or wrong-attribution entries)

- **Confirm auditing enabled.** With your Imprivata admin, confirm auditing is enabled on the appliance and capturing sign-on, switch, SSO, and EPCS events (R9).
- **Confirm attribution.** If events attribute to the wrong clinician, suspect a badge mapped to the wrong identity or a session not secured on switch — re-verify enrollment (R5) and fast user switching (T5).
- **Confirm retention.** Confirm the retention period meets DEA/organizational policy with compliance; gaps in retention are a compliance issue, not just a technical one.
- **Confirm reviewer access.** Ensure an authorized reviewer can access the audit records; lack of access is often mistaken for "missing" audit.

## Agent or driver app won't install (Intune)

- **Check detection rules.** A "failed" install with the app actually present usually means wrong detection criteria. Confirm the detection rule matches the admin-supplied installed file/version or registry key.
- **Check command lines.** Confirm the silent install/uninstall command lines are exactly those supplied by your Imprivata admin / the driver vendor (do not invent switches).
- **Check requirements.** Confirm the device meets the app's OS architecture/minimum OS (R6); a requirement mismatch leaves the app **Not applicable**.
- **Check assignment and sync.** Confirm the app is assigned **Required** to the device's group (`IMPRIVATA – Clinical Endpoints – Pilot` during pilot) and force an Intune sync; review the Intune install logs on the endpoint.
- **Remediate.** Use `IMPRIVATA-Remediation.ps1 -Apply` to safely re-deploy the named app to the device after the root cause is addressed.

---

## Escalation map

| Issue domain | Escalate to |
|--------------|-------------|
| Appliance policy, application profiles, agent installer specifics, enrollment policy | Imprivata administrator |
| Epic credential vaulting / launch / EPCS signing workflow | Epic / EHR team (with Imprivata admin) |
| EPCS identity proofing, approved factors, supervised approval, DEA requirements, audit retention | Compliance / pharmacy leadership |
| Intune app/profile/group delivery, device enrollment, reporting | Intune administrator |
| Network reachability to Microsoft / Imprivata / Epic | Networking team |
