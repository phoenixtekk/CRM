# 7. Best Practices — iOS Lock-Down Profile for Shared & Corporate iPhones

- **Decide the model per phone, up front.** A phone is either **shared** (no user affinity, locked
  down) or **corporate** (user affinity, lighter). Set it at the ADE enrollment profile — don't try to
  convert a phone's model after the fact.
- **Two enrollment profiles, two groups, two policy sets.** Keep `iOS Shared – ADE – Pilot` /
  `iOS – Shared Devices` and `iOS Corporate – ADE – Pilot` / `iOS – Corporate Devices` cleanly
  separated so a shared lock-down can never land on a corporate phone (or vice versa).
- **Always supervise.** Kiosk and the full supervised restriction set only hold on supervised devices;
  enroll via ABM + ADE (or Apple Configurator for non-ABM phones).
- **Lock enrollment.** Set **Locked enrollment = Yes** on both profiles so users can't remove
  management — essential for the shared lock-down and good hygiene for corporate.
- **Restrictions first, kiosk only when needed.** A device-restrictions profile gives a
  locked-but-usable shared phone; add a kiosk only when the role truly needs single/multi-app pinning.
- **Keep corporate light.** Resist the urge to over-restrict assigned phones — apply a baseline and
  app-protection, not the shared appliance lock-down.
- **Protect the shared account.** A shared sign-in is a shared credential: scope it tightly, gate it
  with `CA – iOS Shared` (require compliant device), rotate it, and prefer app SSO where supported.
- **Use dynamic groups keyed on the enrollment profile name.** New phones self-sort into the right
  group the moment they enroll (`IOSLD-Set-DeviceGroupTargeting.ps1`).
- **Pilot one of each, then expand in waves.** Validate a shared and a corporate phone with the scripts
  before widening, and re-validate each wave.
- **Name every object with the convention.** `<Purpose> – <Scope> – <Stage>` keeps docs, scripts, and
  the portal consistent and auditable.
- **Set a clean hand-back habit for shared phones.** Train staff to sign out of personal app sessions;
  the restrictions handle the rest.
- **Report regularly.** Run `IOSLD-Report.ps1` to confirm every phone is in the right model, supervised,
  and compliant, and to catch a corporate phone that drifted into the shared group (or vice versa).
