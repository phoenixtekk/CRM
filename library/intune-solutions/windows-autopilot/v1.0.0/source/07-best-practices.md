# 7. Best Practices — Windows Autopilot

- **Always pilot first.** Provision 2–3 devices end-to-end before fleet rollout.
- **Use a dynamic Autopilot device group.** Devices self-join on registration — no manual group management.
- **Keep the ESP minimal.** Only block on truly essential apps; large required-app sets cause timeouts and poor first-run experience.
- **Register at the source.** Have OEMs/resellers register devices at purchase so they're Autopilot-ready out of the box; use `Get-AutopilotHash.ps1` only for existing/one-off devices.
- **Configure company branding.** It reassures users they're joining the right tenant and looks professional.
- **Standard user accounts.** Set the OOBE user account type to Standard unless a role genuinely needs local admin.
- **Test the OOBE network.** Ensure the provisioning network has open internet and no pre-logon 802.1X that blocks Autopilot.
- **Use pre-provisioning for staging.** For IT-staged devices, "white glove" pre-provisioning front-loads app/policy install before handoff.
- **Document the process.** Record the registration method, profile settings, and ESP apps for repeatability and audits.
