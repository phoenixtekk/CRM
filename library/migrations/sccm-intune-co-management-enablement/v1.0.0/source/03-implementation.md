# 3. Implementation Guide — Configuration Manager and Intune Co-Management Enablement

Follow these steps in order. Some steps are in the Configuration Manager console (Administration to
Cloud Services to Co-management) and some are in the Microsoft Intune admin center
(`https://intune.microsoft.com`).

> Model: Onboard a small pilot collection first, move one workload at a time to the pilot, validate
> each, then expand each workload to All. Never move a workload to All before its pilot passes.

Reuse these exact object names verbatim throughout (convention: `<Purpose> – <Scope> – <Stage>`):
- Co-management configuration: `Co-Management – Configuration – Production`
- Pilot device collection (Configuration Manager): `Co-Management – Pilot Collection – Stage 1`
- Pilot device group (Intune/Entra): `Co-Management – Pilot Devices – Stage 1`

## Step 1 — Create the pilot collection (Configuration Manager)
1. Console to Assets and Compliance to Device Collections to Create Device Collection.
2. Name: `Co-Management – Pilot Collection – Stage 1`. Limiting collection: All Systems.
3. Add a membership rule selecting a few representative, healthy devices (direct or query rule).
   Run `COMGMT-Set-CoMgmtPilotTargeting.ps1` to build the membership safely. Next to Create.

## Step 2 — Confirm cloud attach (tenant attach) is connected
1. Console to Administration to Cloud Services to Cloud Attach (or Co-management).
2. Confirm the tenant shows Connected. If not, run the Cloud Attach configuration and sign in with a
   tenant administrator.
3. Validate with `COMGMT-Validation.ps1` before continuing.

## Step 3 — Enable co-management with staged enrollment
1. Console to Administration to Cloud Services to Co-management to Configure co-management (or
   Properties if already created).
2. Name the configuration `Co-Management – Configuration – Production`.
3. On the Enablement page, set Automatic enrollment in Intune to Pilot.
4. For the pilot collection, choose `Co-Management – Pilot Collection – Stage 1`. This is the staged
   enrollment scope — only these devices auto-enroll first. Next.

## Step 4 — Leave all workloads on Configuration Manager (start state)
1. On the Workloads page, leave every slider on Configuration Manager for now:
   Compliance policies, Device configuration, Endpoint Protection, Resource access policies, Client
   apps, Office Click-to-Run apps, and Windows Update policies.
2. Finish the wizard. Co-management is now enabled; the pilot collection will auto-enroll into Intune
   while Configuration Manager still owns every workload.

## Step 5 — Onboard and verify the pilot enrolls
1. On a pilot device, trigger client policy: Configuration Manager control panel applet to Actions
   to Machine Policy Retrieval and Evaluation Cycle.
2. Confirm the device enrolls: it appears in `https://intune.microsoft.com` to Devices to All
   devices, and `dsregcmd /status` shows the MDM URL.
3. Run `COMGMT-Validation.ps1` on the pilot device to confirm co-management state and dual authority.

## Step 6 — Create the pilot device group (Intune/Entra)
1. Intune to Groups to New group to Security. Name: `Co-Management – Pilot Devices – Stage 1`.
2. Add the same pilot devices (this group targets the Intune policies for moved workloads).
   Create.

## Step 7 — Move the first workload to the pilot
1. Before moving any workload, ensure its equivalent Intune policy exists and is assigned to
   `Co-Management – Pilot Devices – Stage 1` (Requirement 2.9). Run `COMGMT-Report.ps1` to confirm.
2. Console to Administration to Cloud Services to Co-management to Properties to Workloads.
3. Move one slider — start with Compliance policies — to Pilot Intune. Apply.
4. The slider options are Configuration Manager, Pilot Intune (pilot collection only), and Intune
   (all). Use Pilot Intune for every first move.

## Step 8 — Validate the moved workload on the pilot
1. Sync the pilot device and run `COMGMT-Validation.ps1` to confirm Intune now owns that workload.
2. Confirm the Intune policy is applying (for Compliance, the device shows a compliance state in
   Intune). Complete the Testing Guide for this workload.
3. Pilot gate: do not proceed until this workload passes on the pilot.

## Step 9 — Repeat one workload at a time
1. Move the next workload to Pilot Intune, in this suggested order, validating each before the next:
   Device configuration, Endpoint Protection, Resource access policies, Client apps, Office
   Click-to-Run apps, Windows Update policies.
2. Validate each with `COMGMT-Validation.ps1` and the Testing Guide before moving on.

## Step 10 — Expand each validated workload to All
1. Once a workload has passed on the pilot, return to Workloads and move that slider from Pilot
   Intune to Intune (all). Apply.
2. Ensure the equivalent Intune policy is assigned to the broad device scope, not just the pilot
   group, before expanding.
3. Re-validate with `COMGMT-Report.ps1` across the fleet, then proceed to the next workload.

---
### Order of operations
`Pilot collection to Cloud attach to Enable co-management (Pilot) to Verify enrollment to Pilot
device group to Move workload (Pilot Intune) to Validate to Repeat per workload to Expand to Intune
(all)`
