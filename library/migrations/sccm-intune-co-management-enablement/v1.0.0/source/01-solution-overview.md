# 1. Solution Overview — Configuration Manager and Intune Co-Management Enablement

## What co-management is
Co-management lets a single Windows device be managed by Configuration Manager and Microsoft Intune
at the same time. Configuration Manager keeps doing what it does today; Intune is attached alongside
it. You then move management responsibilities — called workloads — from Configuration Manager to
Intune one at a time, on your schedule. The device stays fully managed throughout, so there is no
rip-and-replace and no all-or-nothing cutover.

## How it works
1. You enable a co-management configuration in the Configuration Manager console. This tells the
   Configuration Manager client to auto-enroll the device into Intune.
2. Each Windows client gets two management authorities: Configuration Manager and Intune. The
   workload slider decides, per workload, which authority is in charge.
3. You onboard a small pilot collection first, validate, then expand to the full fleet.
4. Cloud attach (tenant attach) connects your Configuration Manager site to your cloud tenant so the
   site and Intune work together and devices appear in `https://intune.microsoft.com`.
5. As each workload is moved to Intune (Pilot first, then All), Intune policies take over that
   responsibility and Configuration Manager stands down for it.
6. Status is visible in both the Configuration Manager console and the Intune admin center.

## The co-management workloads (the slider)
Each workload is moved independently — set to Pilot (only the pilot collection) or All (whole fleet):
- Compliance policies
- Device configuration
- Endpoint Protection
- Resource access policies
- Client apps
- Office Click-to-Run apps
- Windows Update policies

## Cloud attach: cloud attach and tenant attach
- Cloud attach is the umbrella for connecting Configuration Manager to the Microsoft cloud.
- Tenant attach uploads your Configuration Manager devices to the Intune admin center so you can see
  and take actions on them from the cloud console, even before any workload moves.
- Co-management is the part that enables the dual authority and the workload slider.

## Enrollment models
- Automatic enrollment via the Configuration Manager client (the default for co-management).
- Staged enrollment, where only the pilot collection auto-enrolls first, then enrollment expands —
  this is the controlled path this solution uses.

## Why co-management (and why staged)
Co-management exists because most organizations have years of Configuration Manager investment and
cannot move to the cloud in one step. It removes the risk of a big-bang migration: you keep
everything working while you shift responsibilities to Intune at a pace you control, validating each
workload on a pilot before the fleet feels it. Moving workloads one at a time means a problem with
any single workload is contained to the pilot and easy to roll back, and you end with a clear,
low-drama path to cloud-first management.

## What you can control
- Which workloads move, and whether each goes to the pilot only or to all devices.
- The pilot collection membership (who experiences each workload move first).
- Whether the Configuration Manager client auto-enrolls devices into Intune.
- The order and pace of the migration, gated by validation at each step.

## Limitations (be honest with buyers)
- Co-management requires a supported Configuration Manager current branch and healthy clients.
- Identity must be in place first: devices must be hybrid Entra joined (or Entra joined) and able to
  enroll in Intune.
- A workload set to Intune is owned by Intune — you must have an equivalent Intune policy ready
  before you move that workload, or that capability lapses.
- Moving a workload affects every device in the chosen scope; validate on the pilot before choosing
  All.

## The deployment model
> Enable co-management to onboard a pilot collection to move one workload at a time to Intune to
> validate each to expand. Pattern: Assess to Configure to Pilot to Validate to Expand.
