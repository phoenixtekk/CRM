# 3. Implementation Guide — Windows 365 Cloud PC Deployment & Management

Follow these steps **in order**. Most work is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`); identity work is in the **Microsoft Entra admin center**
(`https://entra.microsoft.com`); the optional Azure Network Connection and custom image use the
**Azure portal** (`https://portal.azure.com`).

> **Model:** Stand up a **Pilot** provisioning policy for a few users, validate the full experience,
> then create the **Production** policy and expand. The pilot gate comes before production.
>
> **Named objects (reuse verbatim):** groups `W365 – Users – Pilot` / `W365 – Users – Production`;
> network connection `W365 – ANC – Production`; image `W365 – Image – Win11-M365`; provisioning
> policies `W365 – Provisioning – Pilot` / `W365 – Provisioning – Production`; Conditional Access
> policy `W365 – CA – CloudPC-Access`.

## Step 1 — Create the user groups and confirm licensing
1. In Entra admin center go to **Identity → Groups → All groups → New group**.
2. **Group type:** Security. **Group name:** `W365 – Users – Pilot`. Add a few representative users as
   members. Click **Create**.
3. Repeat **New group** to create `W365 – Users – Production` (the broader population). Click **Create**.
4. In the Microsoft 365 admin center go to **Billing → Licenses** and confirm each member of
   `W365 – Users – Pilot` holds **Windows 365 Enterprise** + **Intune** + **Entra ID P1**. Assign any
   missing licenses (directly, or via group-based licensing on the group).

## Step 2 — (Only if hybrid join / on-prem reach is needed) Create the Azure Network Connection
> Skip this entire step if you are deploying cloud-only Cloud PCs (Microsoft Entra join, no on-prem
> reach). In that case you will choose the **Microsoft-hosted network** in Step 4 and build nothing here.
1. In the **Azure portal**, confirm (or create) a **Virtual network** and **subnet** in the region
   closest to your users, with outbound internet and — for hybrid join — line-of-sight to a domain
   controller. Note the subnet.
2. In the Intune admin center go to **Devices → Windows 365 → Azure network connection → Create**.
3. Choose the join type:
   - **Microsoft Entra join** — pick the subscription, resource group, virtual network, and subnet.
   - **Microsoft Entra hybrid join** — additionally supply the on-prem AD domain, an OU, and a
     domain-join account.
4. **Name:** `W365 – ANC – Production`. Click **Review + create**.
5. Wait for the connection's **health checks** to run and show **Checks passed** (DNS, domain join,
   endpoint reachability). Do not proceed until every check is green.

## Step 3 — (Only if using a custom image) Prepare and upload the image
> Skip this step to use a Microsoft **gallery image** (Windows 11 Enterprise + Microsoft 365 Apps),
> which needs no preparation. You will select the gallery image in Step 4.
1. In the **Azure portal**, build a VM from a supported Windows image, install your standard apps and
   baseline configuration, then **generalize** it (run `sysprep /generalize /oobe /shutdown`).
2. **Capture** the VM to an **Azure Compute Gallery** image version.
3. In the Intune admin center go to **Devices → Windows 365 → Custom images → Add**.
4. Select the captured image version. **Image name:** `W365 – Image – Win11-M365`. Click **Add**.
5. Wait for the status to read **Upload successful** before using it in a provisioning policy.

## Step 4 — Create the Pilot provisioning policy
1. In the Intune admin center go to **Devices → Windows 365 → Provisioning policies → Create policy**.
2. **General → Name:** `W365 – Provisioning – Pilot`.
3. **Join type:** choose **Microsoft Entra join** (cloud-only) or **Microsoft Entra hybrid join**.
4. **Network:**
   - For cloud-only with no on-prem reach, select **Microsoft hosted network** and pick the **region**
     (or "Automatic") and a geography.
   - For hybrid / on-prem reach, select **Azure network connection** and choose `W365 – ANC – Production`.
5. Click **Next** to **Image**. Select either a **Gallery image** (e.g. *Windows 11 Enterprise + Microsoft
   365 Apps*) or **Custom image → `W365 – Image – Win11-M365`**.
6. Click **Next** to **Configuration**. Set the **language & region**; leave the rest at defaults for
   the pilot. Click **Next**.
7. **Assignments → Add groups →** select `W365 – Users – Pilot`. Click **Next**.
8. **Review + create.** Provisioning begins automatically for every licensed member of the group;
   a Cloud PC appears under **Devices → Windows 365 → All Cloud PCs** within roughly 30–60 minutes.

## Step 5 — Apply Intune management to Cloud PCs
Cloud PCs enroll in Intune automatically; now apply your management policies to them via the user
groups (so they cover both Cloud PCs and physical devices the same way).
1. **Compliance:** **Devices → Compliance → Policies → Create policy → Windows 10 and later.** Name it
   `W365 – Compliance – Baseline`, set your rules (e.g. BitLocker, minimum OS, Defender), and under
   **Assignments** add `W365 – Users – Pilot` (later `W365 – Users – Production`). **Create**.
2. **Configuration:** **Devices → Configuration → Create → New policy → Windows 10 and later → Settings
   catalog.** Apply your standard device settings; assign to the same groups. **Create**.
3. **Apps:** **Apps → Windows → Add** the apps your users need and assign them to the Cloud PC user
   groups as **Required** so they install on the Cloud PCs.

## Step 6 — Verify the pilot Cloud PC experience
1. As a pilot user, browse to **`https://windows365.microsoft.com`** (or open the **Windows App**),
   confirm the Cloud PC tile appears, and **Connect**.
2. Confirm the desktop loads, sign-in succeeds, and the assigned apps are present.
3. In Intune, open **Devices → Windows 365 → All Cloud PCs** and confirm the device shows
   **Provisioned**. Run **`W365-Validation.ps1`** to confirm health, and **`W365-Report.ps1`** for the
   fleet/license view.

## Step 7 — Secure Cloud PC access with Conditional Access
1. In Entra admin center go to **Protection → Conditional Access → Policies → New policy**.
2. **Name:** `W365 – CA – CloudPC-Access`.
3. **Assignments → Users:** select `W365 – Users – Pilot` (add `W365 – Users – Production` later).
4. **Target resources → Cloud apps → Select apps:** add **Windows 365** and **Azure Virtual Desktop**
   (these cover the Cloud PC connection/gateway sign-in).
5. **Grant:** **Require multifactor authentication** (and, if desired, **Require device to be marked as
   compliant** for the connecting endpoint). 
6. Set **Enable policy** to **On** and click **Create**. Verify a pilot user is prompted for MFA on the
   next Cloud PC sign-in.

## Step 8 — Validate the pilot (gate)
1. Run **`W365-Validation.ps1`** → confirms Cloud PCs are provisioned and healthy and that licensing
   prerequisites are met.
2. Run **`W365-Report.ps1`** → confirms the Cloud PC inventory, status, sizes, and license utilization.
3. Complete the **Testing Guide**. Do not expand to production until every pilot gate passes.

## Step 9 — Expand to production
1. Create the production provisioning policy: repeat Step 4 with **Name:** `W365 – Provisioning –
   Production` and assign it to `W365 – Users – Production`. Use the same network and image as the
   validated pilot.
2. Add `W365 – Users – Production` to the compliance, configuration, app, and `W365 – CA – CloudPC-Access`
   assignments from Steps 5 and 7.
3. Add the production population to `W365 – Users – Production` (in waves if large). Cloud PCs provision
   automatically as users join the group.
4. Re-run **`W365-Report.ps1`** each wave to confirm provisioning success and license headroom; use
   **`W365-Remediation.ps1`** (defaults to -WhatIf) for any reprovision/resize fixes.

---
### Order of operations
`User groups + licensing → (ANC if needed) → (custom image if used) → Pilot provisioning policy →
Intune management → verify experience → Conditional Access → validate (gate) → expand to production`
