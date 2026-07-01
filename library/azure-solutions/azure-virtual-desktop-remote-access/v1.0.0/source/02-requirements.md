# 2. Requirements Guide — Azure Virtual Desktop Remote Access

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-azure-solutions.md`. Named objects use the `<Purpose> – <Scope> – <Stage>` convention and are reused verbatim in `03-implementation.md`.

## 2.1 Azure subscription and resource group
- **Description:** An Azure subscription with Contributor (or Owner) rights and a resource group to hold the AVD objects, named `AVD – Resource Group – Core`.
- **Why:** Host pools, session-host VMs, the workspace, and application groups are Azure resources that live in a subscription/resource group.
- **Verify:** `portal.azure.com` → **Subscriptions** confirms an active subscription; **Resource groups** confirms (or lets you create) `AVD – Resource Group – Core`. Run `AVD-Discovery.ps1`.
- **Implement-if-missing:** Create the resource group in a supported AVD region; ensure the operating account has Contributor on it.

## 2.2 AVD licensing entitlement
- **Description:** A per-user eligible license — Microsoft 365 E3/E5/A3/A5/F3/Business Premium, or Windows E3/E5 — for every AVD user.
- **Why:** Access to Windows 10/11 multi-session and single-session in AVD is gated by these license SKUs; unlicensed use is not permitted.
- **Verify:** M365 admin center → **Billing → Licenses**; confirm each AVD user holds an eligible SKU.
- **Implement-if-missing:** Assign an eligible license to every AVD user (or to the `AVD – Users – Pilot` / `AVD – Users – Production` groups).

## 2.3 Identity — Entra ID (or hybrid) for users and hosts
- **Description:** User accounts in Microsoft Entra ID, and a join model for the session hosts — Microsoft Entra join, or Microsoft Entra hybrid join with Entra Connect syncing from Active Directory.
- **Why:** Users authenticate with Entra ID; the session hosts must be joined so users can sign in and so policy applies. Hybrid is required when sessions need line-of-sight to on-premises file/app servers using Kerberos.
- **Verify:** Entra → **Users** lists the AVD users; decide and record the host join model. If hybrid, confirm Entra Connect sync health. Run `AVD-Discovery.ps1`.
- **Implement-if-missing:** Ensure users exist in Entra ID; choose Entra join (cloud-only) or stand up Entra Connect + line-of-sight to a domain controller for hybrid join.

## 2.4 Virtual network and connectivity
- **Description:** An Azure virtual network named `AVD – VNet – Core` (with a session-host subnet) in the AVD region, with DNS that resolves the chosen identity provider, and any required route to on-premises.
- **Why:** Session hosts live on this VNet; they must resolve and reach the domain (for hybrid) and any internal resources users need.
- **Verify:** `portal.azure.com` → **Virtual networks** confirms the VNet/subnet; test name resolution and connectivity from a test VM on the subnet.
- **Implement-if-missing:** Create the VNet/subnet; set DNS to your domain controllers (hybrid) or default Azure DNS (cloud-only); add VPN/ExpressRoute peering if on-premises access is needed.

## 2.5 Session-host VM image
- **Description:** A Windows image for the session hosts — Windows 11 Enterprise multi-session (pooled) or Windows 11 Enterprise (personal), from the Azure Marketplace or a custom image; session-host names use the prefix `avdsh-`.
- **Why:** The image determines the OS and the apps baked into every host; multi-session is required for pooled cost-sharing.
- **Verify:** In the host-pool creation blade, confirm the gallery image is selectable; for custom images confirm the image version exists in a compute gallery.
- **Implement-if-missing:** Select a Marketplace image, or build and publish a custom image (with your line-of-business apps and FSLogix agent) to an Azure Compute Gallery.

## 2.6 FSLogix profile storage
- **Description:** A highly available SMB file share for FSLogix profile containers, named `AVD – FSLogix Share – Core` (Azure Files with Entra Kerberos/AD authentication, or Azure NetApp Files).
- **Why:** Pooled hosts are interchangeable; FSLogix roams the user profile so the desktop is consistent on whichever host the user lands. This is mandatory for pooled host pools.
- **Verify:** `portal.azure.com` → **Storage accounts** (or **Azure NetApp Files**) confirms the share and that the session hosts can authenticate to it.
- **Implement-if-missing:** Create the share, enable identity-based (Kerberos) authentication, set NTFS + share permissions so users can create their own container, and record the UNC path.

## 2.7 Conditional Access readiness
- **Description:** Microsoft Entra ID P1 (or higher) so a Conditional Access policy named `AVD – Conditional Access – MFA` can govern AVD sign-in.
- **Why:** Remote access to a full desktop must be protected; Conditional Access enforces MFA and device/location conditions on the AVD and Azure cloud apps.
- **Verify:** Entra → **Conditional Access** is available (indicates P1); confirm a break-glass account is excluded from any new policy.
- **Implement-if-missing:** Acquire Entra ID P1 (included in M365 E3/E5/Business Premium); plan the policy targeting the AVD users and the AVD cloud apps.

## 2.8 The AVD client on Windows and macOS
- **Description:** The Windows Desktop client (or the new Windows App) on Windows endpoints, and the macOS AVD client from the Mac App Store on Mac endpoints.
- **Why:** The published desktop/apps are reached through the AVD client; both platforms must be covered for cross-OS access.
- **Verify:** On a Windows test device the Windows App / Remote Desktop client is installed; on a Mac the Windows App (or Microsoft Remote Desktop) is installed from the App Store.
- **Implement-if-missing:** Deploy the Windows App to Windows endpoints (Intune/winget); install the macOS client from the Mac App Store on Mac endpoints.

## 2.9 Assignment groups
- **Description:** Entra ID security groups for assignment — `AVD – Users – Pilot` and `AVD – Users – Production`.
- **Why:** Application-group assignment, licensing, and Conditional Access all target groups, so a user is granted access by group membership alone.
- **Verify:** Entra → **Groups** lists both groups. Run `AVD-Set-UserAssignmentTargeting.ps1` to create them if absent.
- **Implement-if-missing:** Create the two security groups; start `AVD – Users – Pilot` with a few representative users.

---
## Checklist
- [ ] Azure subscription + resource group `AVD – Resource Group – Core`
- [ ] Eligible AVD license per user
- [ ] Entra ID users + host join model (Entra join or hybrid) decided
- [ ] VNet `AVD – VNet – Core` with DNS/connectivity
- [ ] Session-host image chosen (`avdsh-` prefix)
- [ ] FSLogix share `AVD – FSLogix Share – Core` ready
- [ ] Entra ID P1 for `AVD – Conditional Access – MFA`
- [ ] AVD client installed on Windows and macOS test devices
- [ ] Groups `AVD – Users – Pilot` and `AVD – Users – Production` created
