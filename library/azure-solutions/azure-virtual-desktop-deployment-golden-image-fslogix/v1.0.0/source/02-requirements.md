# 2. Requirements — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

The **category-level platform prerequisites** (an Entra tenant, admin roles, licensing baseline, network connectivity, change control, and backup/rollback posture) are covered once in **`global-requirements-azure-solutions.md`** — read that first. This document adds only the requirements **specific to building and operating AVD**: the image pipeline, IaC deployment, FSLogix storage, and scaling. Each item is structured **Description / Why required / How to verify / How to implement if missing**.

> Naming convention (reused verbatim throughout): every object is named `<Purpose> – <Scope> – <Stage>`, for example `AVD – Host Pool – Pilot` and `AVD – Session Host – Production`. Azure resource types that forbid spaces/hyphens (notably the Compute Gallery) use the technical form noted at each object.

---

## R1. An AVD-eligible Windows license per user

- **Description:** Each user connecting to AVD holds an eligible license — Microsoft 365 E3/E5/A3/A5/F3/Business Premium, or Windows E3/E5, or a per-user access license for external users.
- **Why required:** Windows 11 Enterprise multi-session session hosts require an eligible license per connecting user; without it the deployment is out of compliance.
- **How to verify:** In the Microsoft 365 admin center → **Billing → Licenses**, confirm the in-scope users carry an eligible SKU. Cross-check the current eligible-license list in Microsoft's AVD documentation — *verify current availability, entitlements change.*
- **How to implement if missing:** Assign an eligible SKU to each in-scope user, or procure per-user access licensing for external users, before publishing the pilot.

## R2. Azure Compute Gallery for image versioning

- **Description:** An Azure Compute Gallery (formerly Shared Image Gallery) with an **image definition** for the AVD image, into which numbered **image versions** are published. Logical name `AVD – Compute Gallery – Core`; because galleries forbid spaces and hyphens, the technical resource name is `avd_compute_gallery_core`, with image definition `avd-win11-m365-multisession`.
- **Why required:** The gallery is what makes the image *versioned, immutable, replicable, and roll-back-able*. Deploying from a Marketplace image directly gives you no version history and no rollback.
- **How to verify:** In the portal, open **Azure Compute Gallery** and confirm the gallery, the image definition (OS: Windows, generation: **Gen2**, security type matching your VMs), and at least one version exist. Or run `AVDDEP-Discovery.ps1`, which lists galleries, definitions, and versions.
- **How to implement if missing:** Create the gallery and an image definition (Section 3, Step 2). Set the image definition's OS state to **Generalized** and generation to **Gen2** to match modern AVD VM sizes.

## R3. A build/source VM for the golden image

- **Description:** A temporary "build" VM — `AVD – Image Build VM – Staging` — from the correct base (Windows 11 Enterprise **multi-session** + Microsoft 365 Apps, Gen2) used to install and configure everything before capture.
- **Why required:** The golden image is produced by customizing a live VM and then generalizing/capturing it. A dedicated, disposable build VM keeps the process repeatable and keeps production hosts untouched during builds.
- **How to verify:** Confirm you can create a VM from the intended base image SKU in the target region (**Marketplace → Windows 11 Enterprise multi-session + Microsoft 365 Apps**), and that its size supports **Gen2 / Trusted Launch** if you use those.
- **How to implement if missing:** Deploy the build VM from the base image (Section 3, Step 3). Keep it in a dedicated `AVD – Resource Group – Imaging` resource group so build artifacts are isolated.

## R4. FSLogix profile-container storage (Azure Files or Azure NetApp Files)

- **Description:** A file share for FSLogix profile containers — either an **Azure Files** premium (SMB) share or an **Azure NetApp Files** volume — sized for the user population, with an identity source (AD DS, Entra Domain Services, or Entra Kerberos) the session hosts can authenticate to. Logical name `AVD – Profile Share – Core`.
- **Why required:** On pooled multi-session hosts, profiles must live off-host so they roam. An undersized or high-latency share is the single most common cause of slow logons and profile corruption.
- **How to verify:** Confirm the share/volume exists, its tier (premium Azure Files or the correct ANF service level) and size match the plan (allow ~5–30 GB per profile depending on Outlook/Teams cache), and that session hosts can mount it with the chosen identity. `AVDDEP-Validate.ps1` checks that hosts have the FSLogix registry pointing at the share.
- **How to implement if missing:** Provision the share/volume, set NTFS and share-level permissions (users: modify; admins: full), join the storage to your identity source, and record the UNC path for the FSLogix configuration (Section 3, Step 6). *Entra Kerberos for Azure Files may be in preview in some clouds/regions — verify current availability.*

## R5. Bicep / IaC tooling and deployment rights

- **Description:** The **Azure CLI** (or Az PowerShell) with **Bicep** installed, and RBAC rights to deploy resources into the target resource group (Contributor plus *Desktop Virtualization Contributor*).
- **Why required:** Session hosts are deployed from the provided `AVDDEP-SessionHosts.bicep` template. Deploying requires Bicep tooling and the rights to create VMs, NICs, and AVD host-pool resources.
- **How to verify:** Run `az bicep version` (or `Get-Command bicep`), and confirm your account holds Contributor + Desktop Virtualization Contributor on the target scope in **Subscriptions → Access control (IAM)**.
- **How to implement if missing:** Install Bicep (`az bicep install`), and have an Owner assign the required roles (least privilege — scope to the resource group, not the subscription, where possible).

## R6. Host-pool registration path and networking

- **Description:** A virtual network/subnet in the target region for the session hosts, with line-of-sight to the FSLogix storage and to the identity source, and a **host-pool registration token** issued at deploy time so new hosts join the pool.
- **Why required:** Session-host VMs need a subnet, DNS that resolves your identity source, and a valid (unexpired) registration token to join the AVD host pool. An expired token is the classic cause of "VM deployed but not showing as a session host."
- **How to verify:** Confirm the subnet exists and resolves internal DNS; the Bicep deployment generates a fresh registration token, so verify the host pool's token expiry in **Host pool → Registration key** if you register hosts manually.
- **How to implement if missing:** Create/select the subnet, ensure DNS points at the identity source, and let the Bicep template mint a fresh token at deploy time (tokens are short-lived — generate at deploy, do not reuse old ones).

## R7. Azure Monitor / Log Analytics workspace (recommended)

- **Description:** A Log Analytics workspace connected to the host pool and session hosts to surface connection, performance, and FSLogix diagnostics (AVD Insights).
- **Why required:** Validating "is the estate healthy and are logons fast?" depends on host and FSLogix telemetry. Without it, troubleshooting is blind.
- **How to verify:** In **Azure Virtual Desktop → Insights**, confirm a workspace is configured and hosts report data.
- **How to implement if missing:** Create a Log Analytics workspace and enable AVD Insights (diagnostic settings on the host pool + the AVD Insights workbook). This is recommended, not blocking, for the pilot.
