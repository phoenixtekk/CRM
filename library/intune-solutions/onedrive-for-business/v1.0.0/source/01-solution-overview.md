# 1. Solution Overview — OneDrive for Business

## What OneDrive for Business is
OneDrive for Business is Microsoft 365's per-user cloud file storage, paired with the **OneDrive
sync client** built into Windows 10 and Windows 11. Configured through Microsoft Intune, it
silently backs up each user's files to the cloud and keeps them synchronized across devices —
with no manual setup by the user.

## How it works
1. Intune delivers OneDrive **configuration policy** to the device (via the Settings Catalog).
2. **Silent Account Configuration** signs the OneDrive sync client in automatically using the
   user's existing Windows (Microsoft Entra) credentials — no sign-in prompt.
3. **Known Folder Move (KFM)** redirects the user's **Desktop, Documents, and Pictures** into
   their OneDrive folder. Existing content is moved up to the cloud and continues to sync.
4. **Files On-Demand** shows every file in File Explorer but downloads content only when a file
   is opened, so the cloud library never fills the local disk.
5. Changes sync continuously. Files are versioned in the cloud, so prior versions can be restored.

The user simply works as normal in Desktop/Documents/Pictures; everything is backed up behind the scenes.

## Capabilities delivered
- **Silent Sign-In** (`SilentAccountConfig`) — zero-touch account setup.
- **Known Folder Move** (`KFMSilentOptIn`) — automatic backup of Desktop/Documents/Pictures.
- **Files On-Demand** (`FilesOnDemandEnabled`) — disk-space-efficient sync.
- **Optional hardening** — block syncing of personal OneDrive accounts; restrict by file type; cap upload bandwidth.

## Benefits
- **Ransomware & device-loss resilience** — files live in the cloud, versioned and restorable.
- **Zero-touch for users** — no prompts, no manual folder setup.
- **Roaming** — the same Desktop/Documents/Pictures on any signed-in device.
- **Lower help-desk load** — fewer "I lost my files" and reimage-data-loss tickets.
- **Disk efficiency** — Files On-Demand keeps local storage lean.

## Limitations (be honest with buyers)
- Requires Microsoft 365 licensing that includes OneDrive for Business.
- KFM requires your **Microsoft Entra Tenant ID** in the policy (a script in this package retrieves it).
- Very large existing folders take time for the first upload; plan pilot timing accordingly.
- Known Folder Move covers Desktop/Documents/Pictures — not arbitrary custom folders.
- Some line-of-business apps that hardcode local paths may need testing against redirected folders.

## The standard Phoenixtekk deployment model
This solution uses **one** model so the process is repeatable across our catalog:

> **Windows devices, Intune-managed, OneDrive configured via the Settings Catalog**
> (Silent Sign-In + Known Folder Move + Files On-Demand), assigned to a pilot group first.

Every step follows the Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
