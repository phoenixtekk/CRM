# 3. Implementation Guide — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Follow these steps in order. Every object you create is named with the convention `<Purpose> – <Scope> – <Stage>` and reused verbatim in later steps, in **Testing**, and in the scripts. Portal paths are current as of authoring; Microsoft renames blades occasionally — *verify the exact label in your portal*. **Pilot first**: build one image, one pilot host pool, prove it, then expand.

> Before you start, run **`AVDDEP-Discovery.ps1`** to capture what already exists (galleries, host pools, session hosts, storage, scaling plans). This is your baseline and your rollback reference (global requirement G6).

---

## Step 1 — Create the resource groups and the Compute Gallery

1. In the Azure portal, go to **Resource groups → + Create** and create two groups in your target region:
   - `AVD – Resource Group – Core` — holds the host pool, workspace, application group, and scaling plan.
   - `AVD – Resource Group – Imaging` — holds the build VM and the Compute Gallery, so build artifacts stay isolated.
2. Go to **Azure Compute Gallery → + Create**, in `AVD – Resource Group – Imaging`. Give it the technical name **`avd_compute_gallery_core`** (galleries forbid spaces and hyphens; this is the logical `AVD – Compute Gallery – Core`). Create.
3. Open the gallery → **Definitions → + Add / Create a VM image definition**:
   - **Name:** `avd-win11-m365-multisession`
   - **OS type:** Windows · **OS state:** Generalized · **VM generation:** **Gen2**
   - Publisher/Offer/SKU: your own identifiers (e.g. `contoso / avd / win11-multisession`).
   - Create. You now have a definition ready to receive versions.

## Step 2 — Deploy the build VM

1. Go to **Virtual machines → + Create**. Under **Image**, choose **See all images → Marketplace** and select **Windows 11 Enterprise multi-session + Microsoft 365 Apps** (Gen2). *Verify the exact SKU name in Marketplace — Microsoft revises image names.*
2. Name it `AVD – Image Build VM – Staging`, place it in `AVD – Resource Group – Imaging`, size it modestly (e.g. a D4s-class VM — this is a build box, not a session host), and place it on your build subnet.
3. Leave it **not** joined to your production identity during build (a workgroup build VM is cleanest for generalizing). Create and connect over RDP/Bastion.

## Step 3 — Build the golden image (customize the source)

On `AVD – Image Build VM – Staging`, apply your standard build. Keep a written checklist so every future rebuild is identical:
1. Run **Windows Update** fully; reboot until clean.
2. Install the **FSLogix agent** (latest) — configuration comes later via policy/registry, not baked-in secrets.
3. Install line-of-business apps and runtimes that belong on every host.
4. Apply the **Microsoft AVD image optimizations** (the Virtual Desktop Optimization Tool / recommended settings) to trim background tasks.
5. Do **not** run Sysprep manually yet if you will capture through the portal (the capture flow generalizes for you). Remove any per-user or secret material.

> Everything disruptive here is on a disposable build VM, so there is no production impact. This is the only place app contents are decided — *which* apps belong in the image is a customer decision (Overview, "Scope — out").

## Step 4 — Capture the image as a gallery version

1. On the build VM's blade, click **Capture** (top toolbar).
2. Choose **Yes, share it to a gallery as a VM image version.**
3. Target gallery **`avd_compute_gallery_core`**, image definition **`avd-win11-m365-multisession`**.
4. **Version number:** `1.0.0` (use semantic versions; a monthly patch becomes `1.1.0`, a rebuild-from-scratch `2.0.0`).
5. Set **replica count** and **target regions** to match where you will deploy hosts (replicate to each region you run host pools in).
6. Tick **Automatically delete this virtual machine after capture** so the build VM is cleaned up.
7. Create. When the version shows **Succeeded**, you have an immutable, versioned golden image. Confirm with `AVDDEP-Report.ps1` (image inventory).

## Step 5 — Prepare FSLogix profile storage

1. Provision the profile share `AVD – Profile Share – Core` — either an **Azure Files** premium file share or an **Azure NetApp Files** volume — in the host-pool region (co-locate with hosts for low latency).
2. Join the storage to your identity source (AD DS, Entra Domain Services, or Entra Kerberos for Azure Files — *verify current availability in your cloud/region*).
3. Set permissions: **Users → Modify** on the share (so each user can create their own container), **Admins → Full**. Remove broad inherited rights.
4. Record the UNC path (e.g. `\\avdprofilescore.file.core.windows.net\profiles`). You will point FSLogix at it in Step 8.

## Step 6 — Deploy the pilot host pool and session hosts with Bicep

1. Open the provided **`AVDDEP-SessionHosts.bicep`** and set its parameters:
   - `hostPoolName`: `AVD – Host Pool – Pilot`
   - `hostPoolType`: `Pooled`, `loadBalancerType`: `BreadthFirst`
   - `galleryImageId`: the resource ID of version `1.0.0` of `avd-win11-m365-multisession`
   - `sessionHostCount`: **2** (pilot), `vmSize`: your standard multi-session size
   - `subnetId`, `resourceGroup`: `AVD – Resource Group – Core`, `location`: your region
2. **Preview first (never apply blind):**
   ```
   az deployment group what-if \
     --resource-group "AVD – Resource Group – Core" \
     --template-file AVDDEP-SessionHosts.bicep \
     --parameters @avddep.pilot.parameters.json
   ```
   Review the what-if output — it must show the host pool, 2 VMs/NICs, and the scaling-plan association being **created**, nothing being deleted.
3. Deploy (swap `what-if` for `create`). The template mints a **fresh host-pool registration token** at deploy time (requirement R6) so the new hosts join `AVD – Host Pool – Pilot` automatically.
4. Confirm the two hosts appear under **Host pool → Session hosts** as **Available**. Run `AVDDEP-Validate.ps1` to confirm agent health and image provenance.

> The host pool, workspace, and application-group *plumbing* is created here; **publishing to end users and validating the Windows/macOS client** is the companion *AVD Remote Access* solution — do not duplicate that work here.

## Step 7 — Assign RBAC on the AVD objects

1. On `AVD – Host Pool – Pilot` → **Access control (IAM) → + Add role assignment**, assign **Desktop Virtualization Host Pool Contributor** to the operators group `AVD – Operators – Group`.
2. On `AVD – Resource Group – Core`, assign **Desktop Virtualization Contributor** to the same group for day-to-day operation, and keep **Owner** limited to the platform team.
3. Prefer eligible (PIM) activation over standing access where your licensing allows (global requirement G2). Confirm with `AVDDEP-Validate.ps1` (RBAC section).

## Step 8 — Configure FSLogix on the session hosts

1. FSLogix is installed in the image (Step 3); now point it at the share. Apply the FSLogix settings by **Group Policy** or the registry values under `HKLM\SOFTWARE\FSLogix\Profiles`:
   - `Enabled = 1`
   - `VHDLocations = \\avdprofilescore.file.core.windows.net\profiles` (the Step 5 UNC path)
   - `DeleteLocalProfileWhenVHDShouldApply = 1`, `FlipFlopProfileDirectoryName = 1`
2. Sign a pilot user in twice on different hosts and confirm a `Profile_<username>.vhdx` appears on the share and the profile roams. `AVDDEP-Validate.ps1` reports the FSLogix registry state per host.

## Step 9 — Create and assign the autoscale scaling plan

1. Go to **Azure Virtual Desktop → Scaling plans → + Create**. Name it `AVD – Scaling Plan – Pilot`, region matching the host pool, **host pool type: Pooled**.
2. Add a schedule (e.g. `Weekdays`): ramp-up before business hours, peak during the day, ramp-down and off-peak after hours, with a **capacity threshold** (e.g. 75–80%) and **minimum percent of hosts** during ramp-down.
3. Under **Host pool assignments**, tick **`AVD – Host Pool – Pilot`** and **Enable autoscale**.
4. Grant the AVD service principal the **Power On/Off** rights it needs (the portal prompts for the required custom role assignment). Confirm the plan and schedule with `AVDDEP-Report.ps1` (scaling section).

## Step 10 — Establish the drain-and-patch workflow

1. When a new image version (e.g. `1.1.0`) is ready, you patch by **replacing hosts**, not editing live ones: put existing hosts into **drain mode**, let sessions finish, then deploy replacement hosts from the new version and remove the old.
2. Preview the drain safely with **`AVDDEP-Maintenance.ps1`** — it **defaults to `-WhatIf`**, listing which hosts *would* be drained and their active session counts. Only with an explicit `-Apply` does it set drain mode.
3. Re-run `AVDDEP-SessionHosts.bicep` with `galleryImageId` pointed at `1.1.0` to add fresh hosts, confirm health, then remove the drained old hosts. This is a **change-controlled** action (global requirements G5/G6) — do it in a window with a rollback (redeploy the prior image version) ready.

## Step 11 — Validate the pilot, then expand

1. Run the full **Testing** guide (`05-testing.md`) against `AVD – Host Pool – Pilot`. All gates must pass before expanding.
2. To expand, reuse the same artifacts: bump `sessionHostCount` and deploy a `AVD – Host Pool – Production` from the **same** image version and Bicep template, attach a `AVD – Scaling Plan – Production`, and assign RBAC. No hand-building — every wave is the same reviewable deployment.

### Order of operations (summary)
Resource groups + gallery → build VM → customize → capture version `1.0.0` → FSLogix storage → **what-if** then deploy pilot hosts (Bicep) → RBAC → FSLogix config → scaling plan → drain/patch workflow → validate → expand to production from the same image and template.
