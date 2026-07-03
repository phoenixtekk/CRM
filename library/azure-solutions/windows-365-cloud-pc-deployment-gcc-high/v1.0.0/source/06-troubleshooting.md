# 6. Troubleshooting Guide — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

Use **`W365G-Discovery.ps1`** / **`W365G-Validation.ps1`** for tenant and Cloud PC state,
**`W365G-Report.ps1`** for the fleet/license view, and **`W365G-Remediation.ps1`** (defaults to
-WhatIf) for safe reprovision/resize fixes. All scripts connect to **Graph US Gov**
(`-Environment USGov`); all portal steps use the **`.us`** sovereign URLs.

## A. "The portal looks empty / broken / I can't see my tenant" (most common GCC High issue)
| Symptom | Cause | Remediation |
|---|---|---|
| Signed in but tenant/objects don't appear | Signed in to a **Commercial `.com`** portal against a GCC High tenant | Use the sovereign URLs: `admin.microsoft.us`, `intune.microsoft.us`, `entra.microsoft.us`, `portal.azure.us`, end-user `windows365.microsoft.us` |
| Script returns no data / auth errors | Graph connected to the **global** cloud, not US Gov | Connect with `-Environment USGov` (Graph root `graph.microsoft.us`); the scripts do this by default |
| "This applies to GCC, not GCC High" while following a Microsoft article | You're on a **GCC** (commercial-endpoint) procedure | Confirm your edition (Step 0 of Implementation). If endpoints are `.com`, you are on **GCC** — use the Commercial edition of this solution |
| MFA/redirect loops on Cloud PC sign-in | Auth pointed at `login.microsoftonline.com` | Ensure clients/policies use `login.microsoftonline.us` for the government tenant |

## B. Provisioning failed or stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC never appears for a user | User missing a required license | Confirm **Windows 365 Enterprise (Government) + Intune + Entra ID P1** on the user (`W365G-Validation.ps1`); assign the missing seat |
| "Provisioning failed" on an ANC policy | Azure (Government) Network Connection health check failing | Intune (`intune.microsoft.us`) → **Windows 365 → Azure network connection → `W365G – ANC – Production`**; fix the failed check (DNS, domain-join account, subnet endpoint reachability) and retry |
| ANC / custom image won't set up at all | GCC High requires a **different** setup than the GCC Setup Tool / tenant-mapping flow | The published GCC Setup Tool procedure **does not apply to GCC High** — **verify the current GCC-High-specific ANC/custom-image procedure** for your tenant before retrying [Set up tenants for Windows 365 Government, Microsoft Learn] |
| Provisioning hangs / errors with hybrid join | Domain join / OU / line-of-sight problem | Verify the domain-join account, OU path, and DC line-of-sight from the ANC subnet (in **Azure Government**); re-run the ANC health check |
| User not provisioned despite a license | User not in the assigned group | Confirm membership of `W365G – Users – Pilot` / `W365G – Users – Production`; the policy assignment is the trigger |
| No GPU SKU available when sizing | **GPU Cloud PCs are not available in GCC High** | Choose a CPU/RAM SKU; move GPU-dependent workloads off Cloud PC [What is Windows 365 Government, Microsoft Learn] |

## C. User cannot connect
- Confirm the user opens **`https://windows365.microsoft.us`** (the sovereign end-user portal) or the
  Windows App, and the Cloud PC shows **Provisioned**, not **In grace period** (which follows license
  removal).
- Check `W365G – CA – CloudPC-Access`: a misscoped Conditional Access policy (e.g. block from
  non-compliant device) can stop a legitimate connection. Review Entra **Sign-in logs**
  (`entra.microsoft.us`) for the Windows 365 app to see which policy applied.
- Confirm the connecting client can reach the **government** Windows 365 / RDP gateway endpoints (no
  proxy/firewall block of the `.us` sovereign endpoint set — the `.com` allow-list is not sufficient).

## D. Image / app issues
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC missing baseline apps | Using a gallery image but apps not assigned | Assign the apps as **Required** to the Cloud PC user group (Implementation Step 5) |
| Custom-image Cloud PCs are out of date | `W365G – Image – Win11-M365` not re-captured | Patch + re-capture the source VM in **Azure Government**, re-upload the image, and reprovision affected Cloud PCs |
| Reprovision reverts user changes | Expected — reprovision rebuilds to the policy image | Store user data in OneDrive / redirected folders; reprovision is a clean rebuild by design (and your DR substitute — cross-region DR is unavailable in GCC High) |

## E. Compliance / hardening not applying
- Confirm the Cloud PC is enrolled in the **government** Intune instance (**Devices → All devices**)
  and the user is in the group the compliance/configuration profiles are assigned to.
- Remember hardening comes from your **Settings catalog** profile, not the Windows 365 Security
  baseline (which is **unavailable in GCC High**). If you were looking for the W365 baseline option,
  it will not appear — that is expected.
- Force a sync from the Cloud PC (**Settings → Accounts → Access work or school → Info → Sync**) and
  re-check after a policy cycle.

## F. "Feature X is missing" — GCC High parity gaps (expected, not a bug)
Several Commercial features simply do not exist in GCC High. If you can't find one of these, it's a
parity gap, not a misconfiguration — see `gcc-high-parity-notes.md` for the full cited list:
- **Windows 365:** Security baseline, GPU Cloud PCs, Windows 365 Boot (GCC only)/Switch/Reserve, new
  Teams client, multimedia redirection, W365 monitoring dashboard / system alerts / email
  notifications, Cloud PC audit logs in Log Analytics, Copilot in Intune, cross-region DR.
- **Intune:** Windows Autopilot, Remote Help, Windows Autopatch and Feature/Quality/Expedite/Driver
  update rings, Windows Backup for Organizations, Security Copilot, Device Health Attestation.

## G. Licensing / capacity
- "No licenses available" on assignment → buy more Windows 365 Enterprise (Government) seats of the
  chosen size; track utilization with `W365G-Report.ps1`.
- Wrong SKU for the workload → use **Resize** (Devices → Windows 365 → All Cloud PCs → device action;
  CPU/RAM SKUs only) rather than reprovisioning.

## H. Diagnostics quick reference
```powershell
# Tenant-side (Microsoft Graph US Gov — see scripts; all connect with -Environment USGov):
#   W365G-Discovery.ps1   readiness: licenses, ANC, images, provisioning policies
#   W365G-Validation.ps1  Cloud PC health + licensing prerequisites + parity notes
#   W365G-Report.ps1      fleet inventory + license utilization

# On a connected Cloud PC:
winver                                                    # OS build / image version
Get-ComputerInfo | Select-Object WindowsProductName, OsBuildNumber, WindowsVersion
dsregcmd /status                                          # join state (AzureAdJoined / DomainJoined)
```

## I. When to escalate
If the user holds all required licenses, is in the assigned group, the ANC health checks pass, you are
confirmed on GCC High with `.us` endpoints, and the Cloud PC still fails to provision or connect after
a reprovision, capture the provisioning error from **Devices → Windows 365 → All Cloud PCs** (device
detail) and the Entra sign-in log entry, and open a Microsoft support case for **Windows 365
Government**.

---
### Sources
- What is Windows 365 Government? — https://learn.microsoft.com/en-us/windows-365/enterprise/introduction-windows-365-government
- Set up tenants for Windows 365 Government — https://learn.microsoft.com/en-us/windows-365/enterprise/set-up-tenants-windows-365-gcc
- Microsoft Intune Government Service overview — https://learn.microsoft.com/en-us/intune/fundamentals/government-service
- Microsoft Graph national cloud deployments — https://learn.microsoft.com/en-us/graph/deployments
