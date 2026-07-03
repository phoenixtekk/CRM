# 3. Implementation Guide — Windows 365 Cloud PC Deployment & Management (Government / GCC High)

Follow these steps **in order**. Most work is in the **government Microsoft Intune admin center**
(`https://intune.microsoft.us`); identity work is in the **government Microsoft Entra admin center**
(`https://entra.microsoft.us`); the optional Azure Network Connection and custom image use the
**Azure Government portal** (`https://portal.azure.us`); licensing is in the **government Microsoft
365 admin center** (`https://admin.microsoft.us`).

> **Sovereign portals only.** If any of these open a Commercial `.com` experience, stop — you are
> signed in to the wrong cloud. Sign in with your **`.us`** government credentials. The full
> Commercial→GCC-High URL map is in `gcc-high-parity-notes.md`.

> **Model:** Stand up a **Pilot** provisioning policy for a few users, validate the full experience,
> then create the **Production** policy and expand. The pilot gate comes before production.
>
> **Named objects (reuse verbatim):** groups `W365G – Users – Pilot` / `W365G – Users – Production`;
> network connection `W365G – ANC – Production`; image `W365G – Image – Win11-M365`; provisioning
> policies `W365G – Provisioning – Pilot` / `W365G – Provisioning – Production`; compliance policy
> `W365G – Compliance – Baseline`; Conditional Access policy `W365G – CA – CloudPC-Access`.

## Step 0 — Confirm you are on GCC High (not GCC)
1. Sign in at **`https://admin.microsoft.us`** and confirm the tenant resolves with your government
   (`.onmicrosoft.us`) identity.
2. Open **`https://intune.microsoft.us`** and confirm **Devices** loads.
3. If your admin/end-user endpoints are on the **`.com`** domain, you are on **GCC**, not GCC High —
   stop and use the Commercial edition of this solution instead. [Set up tenants for Windows 365
   Government, Microsoft Learn — GCC uses commercial endpoints; GCC High uses `.us`.]

## Step 1 — Create the user groups and confirm licensing
1. In the Entra admin center (`https://entra.microsoft.us`) go to **Identity → Groups → All groups →
   New group**.
2. **Group type:** Security. **Group name:** `W365G – Users – Pilot`. Add a few representative users
   as members. Click **Create**.
3. Repeat **New group** to create `W365G – Users – Production` (the broader population). Click **Create**.
4. In the Microsoft 365 admin center (`https://admin.microsoft.us`) go to **Billing → Licenses** and
   confirm each member of `W365G – Users – Pilot` holds **Windows 365 Enterprise (Government)** +
   **Intune** + **Entra ID P1** (typically via **M365 G3/G5 Government**). Assign any missing licenses
   (directly, or via group-based licensing on the group). Remember **GPU SKUs are unavailable in GCC
   High** — pick a CPU/RAM SKU.

## Step 2 — (Only if hybrid join / on-prem reach is needed) Create the Azure Government Network Connection
> Skip this entire step if you are deploying cloud-only Cloud PCs (Microsoft Entra join, no on-prem
> reach). In that case you will choose the **Microsoft-hosted network** in Step 4 and build nothing here.
>
> **GCC High caveat — verify first.** Microsoft's published **Windows 365 GCC Setup Tool /
> tenant-mapping** procedure (mapping the `.com` tenant to an Azure Government `.us` tenant and
> granting the Windows 365 service principal) is documented **for GCC** and Microsoft states it
> **does not apply to GCC High**. Before building an ANC in GCC High, **verify the current
> GCC-High-specific ANC procedure** for your tenant. [Set up tenants for Windows 365 Government,
> Microsoft Learn.]
1. In the **Azure Government portal** (`https://portal.azure.us`), confirm (or create) a **Virtual
   network** and **subnet** in the **US Government region** closest to your users, with outbound
   internet and — for hybrid join — line-of-sight to a domain controller. Note the subnet.
2. In the Intune admin center (`https://intune.microsoft.us`) go to **Devices → Windows 365 → Azure
   network connection → Create**.
3. Choose the join type:
   - **Microsoft Entra join** — pick the Azure Government subscription, resource group, virtual
     network, and subnet.
   - **Microsoft Entra hybrid join** — additionally supply the on-prem AD domain, an OU, and a
     domain-join account.
4. **Name:** `W365G – ANC – Production`. Click **Review + create**.
5. Wait for the connection's **health checks** to run and show **Checks passed** (DNS, domain join,
   endpoint reachability). Do not proceed until every check is green.

## Step 3 — (Only if using a custom image) Prepare and upload the image
> Skip this step to use a Microsoft **gallery image** (Windows 11 Enterprise + Microsoft 365 Apps),
> which needs no preparation. You will select the gallery image in Step 4. **This is the recommended
> GCC High fast path.**
>
> **GCC High caveat — verify first.** Custom-image support depends on the same GCC-High-specific
> setup as the ANC (above). **Verify the current GCC-High procedure** before capturing/uploading —
> the GCC Setup Tool flow does not apply to GCC High.
1. In the **Azure Government portal** (`https://portal.azure.us`), build a VM from a supported Windows
   image, install your standard apps and baseline, then **generalize** it
   (`sysprep /generalize /oobe /shutdown`).
2. **Capture** the VM to an **Azure Compute Gallery** image version (in Azure Government).
3. In the Intune admin center go to **Devices → Windows 365 → Custom images → Add**.
4. Select the captured image version. **Image name:** `W365G – Image – Win11-M365`. Click **Add**.
5. Wait for the status to read **Upload successful** before using it in a provisioning policy.

## Step 4 — Create the Pilot provisioning policy
1. In the Intune admin center (`https://intune.microsoft.us`) go to **Devices → Windows 365 →
   Provisioning policies → Create policy**.
2. **General → Name:** `W365G – Provisioning – Pilot`.
3. **Join type:** choose **Microsoft Entra join** (cloud-only) or **Microsoft Entra hybrid join**.
4. **Network:**
   - For cloud-only with no on-prem reach, select **Microsoft hosted network** and pick the **US
     Government region group** (or specific US Gov regions) for placement/resiliency. [Announcing
     Multi-Region Selection for Windows 365 in Government Community Cloud, Microsoft.]
   - For hybrid / on-prem reach, select **Azure network connection** and choose `W365G – ANC – Production`.
5. Click **Next** to **Image**. Select either a **Gallery image** (e.g. *Windows 11 Enterprise +
   Microsoft 365 Apps*) or **Custom image → `W365G – Image – Win11-M365`**.
6. Click **Next** to **Configuration**. Set the **language & region**; leave the rest at defaults for
   the pilot. (Do **not** expect the *Windows 365 Security baseline* option — it is unavailable in GCC
   High; hardening is applied in Step 5.) Click **Next**.
7. **Assignments → Add groups →** select `W365G – Users – Pilot`. Click **Next**.
8. **Review + create.** Provisioning begins automatically for every licensed member of the group; a
   Cloud PC appears under **Devices → Windows 365 → All Cloud PCs** within roughly 30–60 minutes.

## Step 5 — Apply Intune management and hardening to Cloud PCs
Cloud PCs enroll in the government Intune instance automatically; now apply management via the user
groups (so they cover both Cloud PCs and physical devices the same way). **Because the Windows 365
Security baseline is unavailable in GCC High, harden with a Settings catalog profile instead.**
1. **Compliance:** **Devices → Compliance → Policies → Create policy → Windows 10 and later.** Name it
   `W365G – Compliance – Baseline`, set your rules (e.g. BitLocker, minimum OS, Defender), and under
   **Assignments** add `W365G – Users – Pilot` (later `W365G – Users – Production`). **Create**.
2. **Configuration (hardening):** **Devices → Configuration → Create → New policy → Windows 10 and
   later → Settings catalog.** Apply your standard hardening/device settings (the replacement for the
   W365 baseline); assign to the same groups. **Create**.
3. **Apps:** **Apps → Windows → Add** the apps your users need and assign them to the Cloud PC user
   groups as **Required** so they install on the Cloud PCs.

## Step 6 — Verify the pilot Cloud PC experience
1. As a pilot user, browse to **`https://windows365.microsoft.us`** (or open the **Windows App**),
   confirm the Cloud PC tile appears, and **Connect**.
2. Confirm the desktop loads, sign-in succeeds, and the assigned apps are present.
3. In Intune, open **Devices → Windows 365 → All Cloud PCs** and confirm the device shows
   **Provisioned**. Run **`W365G-Validation.ps1`** to confirm health, and **`W365G-Report.ps1`** for
   the fleet/license view (both use Graph US Gov, `-Environment USGov`).

## Step 7 — Secure Cloud PC access with Conditional Access
1. In the Entra admin center (`https://entra.microsoft.us`) go to **Protection → Conditional Access →
   Policies → New policy**.
2. **Name:** `W365G – CA – CloudPC-Access`.
3. **Assignments → Users:** select `W365G – Users – Pilot` (add `W365G – Users – Production` later).
4. **Target resources → Cloud apps → Select apps:** add **Windows 365** and **Azure Virtual Desktop**
   (these cover the Cloud PC connection/gateway sign-in).
5. **Grant:** **Require multifactor authentication** (and, if desired, **Require device to be marked
   as compliant** for the connecting endpoint).
6. Set **Enable policy** to **On** and click **Create**. Verify a pilot user is prompted for MFA on
   the next Cloud PC sign-in via `windows365.microsoft.us`.

## Step 8 — Validate the pilot (gate)
1. Run **`W365G-Validation.ps1`** → confirms Cloud PCs are provisioned and healthy and that licensing
   prerequisites are met.
2. Run **`W365G-Report.ps1`** → confirms the Cloud PC inventory, status, sizes, and license utilization.
3. Complete the **Testing Guide**. Do not expand to production until every pilot gate passes.

## Step 9 — Expand to production
1. Create the production provisioning policy: repeat Step 4 with **Name:** `W365G – Provisioning –
   Production` and assign it to `W365G – Users – Production`. Use the same network and image as the
   validated pilot.
2. Add `W365G – Users – Production` to the compliance, configuration/hardening, app, and
   `W365G – CA – CloudPC-Access` assignments from Steps 5 and 7.
3. Add the production population to `W365G – Users – Production` (in waves if large). Cloud PCs
   provision automatically as users join the group.
4. Re-run **`W365G-Report.ps1`** each wave to confirm provisioning success and license headroom; use
   **`W365G-Remediation.ps1`** (defaults to -WhatIf) for any reprovision/resize fixes.

---
### Order of operations
`Confirm GCC High → user groups + licensing → (Azure-Gov ANC if needed, verify GCC-High procedure) →
(custom image if used, verify GCC-High procedure) → Pilot provisioning policy → Intune management +
Settings-catalog hardening → verify experience (windows365.microsoft.us) → Conditional Access →
validate (gate) → expand to production`
