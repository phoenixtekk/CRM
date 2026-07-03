# 7. Best Practices — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

- **Confirm GCC High before anything else.** GCC and GCC High are different clouds. If your admin and
  end-user endpoints are on `.com`, you are on **GCC** — use the Commercial edition. This package is
  for **GCC High**, where everything is on the sovereign `.us` domain. Signing in to a Commercial URL
  against a GCC High tenant is the most common "it looks broken" failure.
- **Use the `.us` portals and endpoints everywhere.** Admin: `intune.microsoft.us`,
  `entra.microsoft.us`, `admin.microsoft.us`, `portal.azure.us`. End-user: `windows365.microsoft.us`.
  Scripts: Graph `graph.microsoft.us` via `-Environment USGov`. Keep this map (in
  `gcc-high-parity-notes.md`) next to the runbook.
- **Design without the GCC High parity gaps.** Do **not** build the deployment on features that are
  unavailable in GCC High: the **Windows 365 Security baseline**, **GPU Cloud PCs**, **Windows 365
  Boot/Switch/Reserve**, the **W365 monitoring dashboard / system alerts**, **Cloud PC audit logs in
  Log Analytics**, **Copilot in Intune**, **cross-region DR**, or Intune **Autopilot / Remote Help /
  Autopatch / update rings / Windows Backup for Organizations**. Harden with a **Settings catalog**
  profile, monitor with `W365G-Report.ps1` + Intune device views, and keep user data in OneDrive so
  reprovision is your recovery path.
- **Pilot before production, always.** Provision `W365G – Provisioning – Pilot` to a few real users,
  validate the full sovereign experience (connect via `windows365.microsoft.us`, apps, compliance,
  Conditional Access), and only then create `W365G – Provisioning – Production`.
- **Start on the Microsoft-hosted network with the US Government region group.** It is the simplest,
  zero-Azure-footprint path and gives multi-region resiliency. Only build an **Azure Government**
  Network Connection (`W365G – ANC – Production`) when you genuinely need **hybrid join** or
  **on-prem reach** — and **verify the current GCC-High-specific ANC/custom-image procedure** first,
  because the published GCC Setup Tool / tenant-mapping flow does **not** apply to GCC High.
- **Gate on ANC health checks.** If you use an ANC, never assign it to a policy until every health
  check reads **Passed**; a failed check (DNS, domain join, endpoint reachability) means failed
  provisioning.
- **Target by group, not by user.** Assign provisioning, compliance, configuration, and Conditional
  Access to `W365G – Users – Pilot` / `W365G – Users – Production`. Adding a user provisions a Cloud
  PC; removing them starts grace-period cleanup. The group is the lifecycle switch.
- **Manage Cloud PCs like physical devices.** Reuse the same government Intune compliance,
  configuration, and app policies across both fleets so there is one standard, not two.
- **Right-size, then resize — CPU/RAM only.** Pick the smallest SKU that meets the workload and use
  **Resize** to move users up later. **GPU SKUs are unavailable in GCC High**, so plan GPU-dependent
  workloads elsewhere.
- **Secure the front door.** Require MFA (and ideally a compliant connecting device) via
  `W365G – CA – CloudPC-Access`. Cloud PCs are reachable from anywhere; Conditional Access is the
  control.
- **Keep one image standard.** If you use a custom image (`W365G – Image – Win11-M365`), patch and
  re-capture it on a schedule so reprovisioned Cloud PCs start current — otherwise prefer the
  always-updated gallery image and deliver apps/config through Intune.
- **Plan the license math per user.** Each Cloud PC needs Windows 365 Enterprise (Government) *and*
  the user holding Intune + Entra ID P1 (typically M365 G3/G5 Government). Track utilization with
  `W365G-Report.ps1` and keep seat headroom for new joiners.
- **Reprovision to recover, don't hand-fix.** For a broken Cloud PC, **Reprovision** rebuilds it to
  the policy image cleanly — and it is your DR substitute given cross-region DR is unavailable in GCC
  High. Keep user data in OneDrive / redirected folders.
- **Document the build and the sovereign specifics.** Record the chosen join type, network model,
  image, SKU, group targeting, **and the `.us` endpoints / parity-gap decisions** for audits and
  repeatability — this is what makes the GCC High deployment repeatable rather than a pile of one-offs.
