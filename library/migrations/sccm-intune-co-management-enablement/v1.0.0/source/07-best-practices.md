# 7. Best Practices — Configuration Manager and Intune Co-Management Enablement

- Pilot first, always. Onboard `Co-Management – Pilot Collection – Stage 1` and use the Pilot Intune
  slider setting so a problem with any workload is contained to a few devices, never the fleet.
- Move one workload at a time. Shift a single slider, validate it, then move the next — never move
  several workloads in one change. It keeps every failure easy to diagnose and roll back.
- Have the Intune policy ready before you move the workload. A workload set to Intune is owned by
  Intune; if no equivalent policy is assigned, that capability lapses. Build and assign first.
- Fix client health before onboarding. Co-management auto-enrollment depends on a healthy
  Configuration Manager client and a working Entra identity — clean these up first.
- Confirm identity is in place. Devices must be hybrid Entra joined (or Entra joined) with Entra
  Connect syncing before enrollment will succeed.
- Use tenant attach early. Tenant attach gives you cloud visibility of devices before any workload
  moves, so you can watch enrollment and act from the Intune console.
- Validate, then expand. Only move a slider from Pilot Intune to Intune (all) after the workload
  passes on the pilot and the Intune policy is assigned to the broad scope.
- Keep names consistent. Reuse `<Purpose> – <Scope> – <Stage>` names verbatim so the configuration,
  collection, and device group stay traceable across both consoles.
- Watch both consoles. Check co-management status in the Configuration Manager console and device
  state in Intune; run `COMGMT-Report.ps1` to confirm authority per workload.
- Document the workload order and gate. Record which workloads moved, in what order, and the pilot
  result for each — for audits and repeatability.
