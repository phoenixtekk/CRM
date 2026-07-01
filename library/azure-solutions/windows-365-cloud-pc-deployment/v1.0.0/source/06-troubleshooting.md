# 6. Troubleshooting Guide — Windows 365 Cloud PC Deployment & Management

Use **`W365-Discovery.ps1`** / **`W365-Validation.ps1`** for tenant and Cloud PC state,
**`W365-Report.ps1`** for the fleet/license view, and **`W365-Remediation.ps1`** (defaults to
-WhatIf) for safe reprovision/resize fixes.

## A. Provisioning failed or stuck
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC never appears for a user | User missing a required license | Confirm **Windows 365 Enterprise + Intune + Entra ID P1** on the user (`W365-Validation.ps1`); assign the missing seat |
| "Provisioning failed" on an ANC policy | Azure Network Connection health check failing | Intune → **Windows 365 → Azure network connection → `W365 – ANC – Production`**; fix the failed check (DNS, domain-join account, subnet endpoint reachability) and retry |
| Provisioning hangs / errors with hybrid join | Domain join / OU / line-of-sight problem | Verify the domain-join account, OU path, and DC line-of-sight from the ANC subnet; re-run the ANC health check |
| User not provisioned despite a license | User not in the assigned group | Confirm membership of `W365 – Users – Pilot` / `W365 – Users – Production`; the policy assignment is the trigger |

## B. User cannot connect
- Confirm the user opens **`https://windows365.microsoft.com`** (or the Windows App) and the Cloud PC
  shows **Provisioned**, not **In grace period** (which follows license removal).
- Check `W365 – CA – CloudPC-Access`: a misscoped Conditional Access policy (e.g. block from
  non-compliant device) can stop a legitimate connection. Review Entra **Sign-in logs** for the
  Windows 365 app to see which policy applied.
- Confirm the connecting client can reach the Cloud PC gateway endpoints (no proxy/firewall block of
  the Windows 365 / RDP gateway URLs).

## C. Image / app issues
| Symptom | Cause | Remediation |
|---|---|---|
| Cloud PC missing baseline apps | Using a gallery image but apps not assigned | Assign the apps as **Required** to the Cloud PC user group (Implementation Step 5) |
| Custom-image Cloud PCs are out of date | `W365 – Image – Win11-M365` not re-captured | Patch + re-capture the source VM, re-upload the image, and reprovision affected Cloud PCs |
| Reprovision reverts user changes | Expected — reprovision rebuilds to the policy image | Store user data in OneDrive / redirected folders; reprovision is a clean rebuild by design |

## D. Compliance / management not applying
- Confirm the Cloud PC is Intune-enrolled (**Devices → All devices**) and the user is in the group the
  compliance/configuration profiles are assigned to.
- Force a sync from the Cloud PC (**Settings → Accounts → Access work or school → Info → Sync**) and
  re-check after a policy cycle.

## E. Licensing / capacity
- "No licenses available" on assignment → buy more Windows 365 Enterprise seats of the chosen size;
  track utilization with `W365-Report.ps1`.
- Wrong SKU for the workload → use **Resize** (Devices → Windows 365 → All Cloud PCs → device action)
  rather than reprovisioning.

## F. Diagnostics quick reference
```powershell
# Tenant-side (Microsoft Graph — see scripts):
#   W365-Discovery.ps1   readiness: licenses, ANC, images, provisioning policies
#   W365-Validation.ps1  Cloud PC health + licensing prerequisites
#   W365-Report.ps1      fleet inventory + license utilization

# On a connected Cloud PC:
winver                                                    # OS build / image version
Get-ComputerInfo | Select WindowsProductName, OsBuildNumber, WindowsVersion
dsregcmd /status                                          # join state (AzureAdJoined / DomainJoined)
```

## G. When to escalate
If the user holds all required licenses, is in the assigned group, the ANC health checks pass, and the
Cloud PC still fails to provision or connect after a reprovision, capture the provisioning error from
**Devices → Windows 365 → All Cloud PCs** (device detail) and the Entra sign-in log entry, and open a
Microsoft support case for Windows 365.
