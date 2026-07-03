# Best Practices — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Operating guidance for running AVD well on the US sovereign cloud. These complement the ordered steps in `03-implementation.md` and the checks in `05-testing.md`.

> Admin at **`portal.azure.us`**; clients subscribe to **`rdweb.wvd.azure.us`**; PowerShell/CLI use **`AzureUSGovernment`** / Graph **`USGov`**.

---

## Sovereign-cloud discipline
- **Bookmark the `.us` portals** and remove Commercial bookmarks from the admin workstation to avoid muscle-memory mistakes: `portal.azure.us`, `portal.office365.us`, `entra.microsoft.us`, sign-in `login.microsoftonline.us`.
- **Standardize the Gov feed URL** in every piece of user documentation and onboarding: `https://rdweb.wvd.azure.us`. Treat any appearance of `rdweb.wvd.microsoft.com` as a bug.
- **Assume parity lag.** Before designing around any AVD feature, confirm it is GA in Azure Government — features ship to Commercial first. Keep `gcc-high-parity-notes.md` next to your design and re-verify at build time. Flag anything unconfirmed as **"verify for Azure Government."**

## Naming & reuse
- Name every object `<Purpose> – <Scope> – <Stage>` and reuse verbatim: `AVD Host Pool – Finance – Pilot`, `AVD Workspace – Finance – Prod`, `AVD App Group – Finance – Pilot`, `AVD Users – Finance – Pilot`. Consistent names make the scripts, the report, and the rollback unambiguous.

## Identity & access
- Prefer the **simplest identity model that meets policy** — Entra-only removes domain controllers from the critical path; use hybrid (AD DS) only where line-of-business apps require it.
- The **domain-join account must not have MFA** (it breaks the automated join) — scope it tightly and monitor it.
- Use **least privilege** for admins (Desktop Virtualization Contributor over Owner where possible) and PIM-eligible activation if available in your Gov tenant.
- **Never open inbound 3389.** AVD uses an outbound reverse connection. For host troubleshooting use just-in-time VM access, not a standing RDP port; don't assign public IPs to hosts.

## Networking & endpoints
- Allow the **US Gov endpoint set** (R7) via **service tags** (`WindowsVirtualDesktop`, `AzureActiveDirectory`, `AzureMonitor`, `AzureCloud`) rather than hand-maintained IPs.
- **Never proxy or redirect** the Azure fabric IPs `169.254.169.254` and `168.63.129.16` — doing so breaks provisioning and health.
- Keep session hosts in the Gov region **closest to users** (RTT < 150 ms); enable RDP Shortpath where the network supports UDP for a better experience.
- Use **Azure Firewall's AVD protection** / FQDN tags to lock down outbound traffic without breaking the service.

## Profiles & images
- Use **FSLogix** for pooled multi-session profiles; store containers on Azure Files/NetApp Files, and match the identity prerequisites for your model (hybrid identities for Entra-join + Azure Files). **Verify for Azure Government** that the specific Azure Files Entra Kerberos/cloud-only path you intend is GA in Gov before committing.
- Build a **golden image** in an Azure Compute Gallery for repeatable, patched hosts; avoid unsupported editions (N/KN/LTSC), 32-bit, Arm64, Ultra/Ephemeral OS disks, and VM Scale Sets.

## Management & operations
- Use **Intune** for session-host policy where supported in your Gov tenant (Entra-joined / hybrid-joined hosts). Remember: **Entra Domain Services-joined** and **Windows Server** hosts can't enroll in Intune.
- Turn on **AVD Insights / diagnostics** to the Gov Log Analytics endpoints (`*.usgovcloudapi.net`) from day one — it's your evidence for T4/T9 troubleshooting.
- **Pilot small, expand in waves** with `AVDG-Set-ScopeTargeting.ps1` (default `-WhatIf`), re-validating after each wave. Scale host capacity to keep pace with assigned users.

## Change control & safety
- Every deployment and expansion wave runs inside an **approved change window** with a **written rollback** (R10). Capture pre-change state with Discovery/Report first.
- Keep **Remediation and Set-ScopeTargeting on `-WhatIf` by default**; require an explicit confirmation to make changes.
- Rehearse the rollback (remove/re-add assignment) before the first real expansion.

## Security & compliance posture
- Keep everything **inside the Azure Government boundary** — GCC High/DoD identity, data residency, and service dependencies are designed to stay in Azure Government; do not reach back to Commercial services for AVD dependencies.
- Enforce **Conditional Access / MFA for users** (not the domain-join service account) using the Gov Entra endpoints.
- Never store tokens, keys, or credentials in scripts or docs; the provided scripts are read-only or `-WhatIf` by default and hold no secrets.
