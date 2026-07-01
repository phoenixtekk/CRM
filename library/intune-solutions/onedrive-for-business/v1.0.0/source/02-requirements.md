# 2. Requirements Guide — OneDrive for Business

Verify **every** requirement below before you configure anything. Each entry follows the same
pattern: **Description · Why required · How to verify · How to implement if missing.** Do not
assume any prerequisite already exists.

> Category-wide prerequisites (a tenant, an Intune subscription, MDM enrollment, admin roles, a
> pilot group) are documented once in **`global-requirements-intune-solutions.md`**. This guide
> lists only what is specific to OneDrive for Business.

---

## 2.1 Microsoft licensing
**Description:** Licenses that include OneDrive for Business plus Intune management.
**Why required:** OneDrive for Business provides the cloud storage; Intune delivers the policy.
**How to verify:** Microsoft 365 admin center → **Billing → Licenses**. Confirm a plan that
includes OneDrive (Microsoft 365 Business Basic/Standard/Premium, or E3/E5, or Office 365) and an
Intune-bearing plan, assigned to every targeted user.
**How to implement if missing:** Assign Microsoft 365 Business Premium or E3/E5 (both include
OneDrive + Intune), or add the appropriate OneDrive and Intune Plan 1 licenses.

## 2.2 Microsoft Entra ID
**Description:** Devices are **Microsoft Entra joined** (or hybrid joined).
**Why required:** Silent Account Configuration uses the device's Entra identity to sign OneDrive in.
**How to verify:** On a device run `dsregcmd /status` → `AzureAdJoined : YES`.
**How to implement if missing:** Join during OOBE, or **Settings → Accounts → Access work or
school → Connect → Join this device to Microsoft Entra**.

## 2.3 Microsoft Intune (MDM)
**Description:** Targeted devices are enrolled in Intune.
**Why required:** Intune is how the OneDrive configuration reaches the device.
**How to verify:** Intune admin center → **Devices → All devices**; the device is listed and compliant.
**How to implement if missing:** Enable **Automatic Enrollment** (Intune → Devices → Enrollment) and join devices to Entra ID.

## 2.4 Microsoft Entra Tenant ID
**Description:** Your tenant's directory (tenant) GUID.
**Why required:** **Known Folder Move** policy (`KFMSilentOptIn`) requires the Tenant ID as its value.
**How to verify:** Entra admin center → **Overview → Tenant ID**, or run **`Get-TenantId.ps1`** (in this package).
**How to implement if missing:** It always exists — retrieve it with **`Get-TenantId.ps1`** and record it for Step-by-step configuration.

## 2.5 Windows operating system
**Description:** Windows 10 or Windows 11 with the built-in OneDrive sync client.
**Why required:** The sync client applies the policy and performs Silent Sign-In, KFM, and Files On-Demand.
**How to verify:** `winver` for the OS; the OneDrive client is at `%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe`.
**How to implement if missing:** Windows 10/11 ship with OneDrive. If removed, deploy the current OneDrive sync client (machine-wide install) as an Intune app.

## 2.6 OneDrive sync client version
**Description:** A current OneDrive sync client build.
**Why required:** Silent Account Configuration and KFM require a recent client.
**How to verify:** Run **`ODFB-Discovery.ps1`**, or check **Settings → About** in the OneDrive client.
**How to implement if missing:** Configure OneDrive to auto-update (default), or deploy the latest client via Intune.

## 2.7 Disk space (Files On-Demand)
**Description:** Sufficient free disk for at least the "always available" content.
**Why required:** Files On-Demand minimizes usage, but pinned/always-available files consume local space.
**How to verify:** **`ODFB-Discovery.ps1`** reports free space.
**How to implement if missing:** Free space or enable Files On-Demand (this solution does) so files stay cloud-only until opened.

## 2.8 Network
**Description:** Outbound HTTPS to OneDrive/SharePoint and Microsoft 365 endpoints.
**Why required:** Sync, sign-in, and KFM upload all call cloud endpoints.
**How to verify:** From a device, browse to `https://<yourtenant>-my.sharepoint.com`.
**How to implement if missing:** Allow Microsoft 365 (OneDrive/SharePoint) URLs/IPs through proxy/firewall;
do **not** SSL-inspect OneDrive traffic (Microsoft does not support it and it breaks sync).

## 2.9 Certificates
**Description:** None required.
**Why required (not):** OneDrive configuration uses Entra identity and Intune policy — no PKI or certificates.
**How to verify:** N/A.
**How to implement if missing:** N/A.

---

## Requirements checklist (use before configuring)
- [ ] M365 (OneDrive) + Intune licensing assigned to pilot users
- [ ] Devices Microsoft Entra joined — `dsregcmd /status`
- [ ] Devices enrolled in Intune and compliant
- [ ] **Tenant ID recorded** — `Get-TenantId.ps1`
- [ ] Windows 10/11 with current OneDrive sync client — `ODFB-Discovery.ps1`
- [ ] Network/proxy allows OneDrive/SharePoint endpoints (no SSL inspection)
- [ ] Pilot Entra security group created
