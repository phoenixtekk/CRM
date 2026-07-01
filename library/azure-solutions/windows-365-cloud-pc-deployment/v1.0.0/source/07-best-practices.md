# 7. Best Practices — Windows 365 Cloud PC Deployment & Management

- **Pilot before production, always.** Provision `W365 – Provisioning – Pilot` to a few real users,
  validate the full experience (connect, apps, compliance, Conditional Access), and only then create
  `W365 – Provisioning – Production`. The pilot catches image, network, and licensing problems before
  they hit the fleet.
- **Start on the Microsoft-hosted network.** It is the simplest, zero-Azure-footprint path. Only build
  an Azure Network Connection (`W365 – ANC – Production`) when you genuinely need **hybrid join** or
  **on-prem resource access** — it adds Azure cost and network design.
- **Gate on ANC health checks.** If you use an ANC, never assign it to a policy until every health check
  reads **Passed**; a failed check (DNS, domain join, endpoint reachability) means failed provisioning.
- **Target by group, not by user.** Assign provisioning, compliance, configuration, and Conditional
  Access to `W365 – Users – Pilot` / `W365 – Users – Production`. Adding a user to the group provisions
  a Cloud PC; removing them starts the grace-period cleanup. The group is the lifecycle switch.
- **Manage Cloud PCs like physical devices.** Reuse the same Intune compliance, configuration, and app
  policies across both fleets so there is one standard, not two.
- **Right-size, then resize.** Pick the smallest SKU that meets the workload and use **Resize** to move
  users up later — over-provisioning wastes license spend.
- **Secure the front door.** Require MFA (and ideally a compliant connecting device) via
  `W365 – CA – CloudPC-Access`. Cloud PCs are reachable from anywhere; Conditional Access is the control.
- **Keep one image standard.** If you use a custom image (`W365 – Image – Win11-M365`), patch and
  re-capture it on a schedule so reprovisioned Cloud PCs start current — otherwise prefer the
  always-updated gallery image and deliver apps/config through Intune.
- **Plan the license math per user.** Each Cloud PC needs Windows 365 Enterprise *and* the user holding
  Intune + Entra ID P1. Track utilization with `W365-Report.ps1` and keep seat headroom for new joiners.
- **Reprovision to recover, don't hand-fix.** For a broken Cloud PC, **Reprovision** rebuilds it to the
  policy image cleanly — faster and more consistent than manual repair.
- **Document the build.** Record the chosen join type, network model, image, SKU, and group targeting
  for audits and repeatability — this is what makes the deployment the repeatable way rather than a
  pile of one-offs.
