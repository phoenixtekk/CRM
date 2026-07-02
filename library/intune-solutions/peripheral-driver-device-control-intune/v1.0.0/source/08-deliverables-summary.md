# Deliverables Summary

This solution is a complete, self-guided package for managing **drivers, peripherals/printers, and removable-device control** on enterprise desktops with Microsoft Intune — deployed pilot-first and rollback-ready.

## Documents

| Document | Purpose |
| --- | --- |
| **Solution Overview** | How Intune manages drivers (Windows driver update management), peripherals/printers, and device control (removable-storage access); the standard deployment model and object naming convention. |
| **Global Requirements — Intune Solutions** | Category-level prerequisites (tenant, licensing, roles, enrollment, Windows baseline, network) shared by all Intune solutions. |
| **Requirements** | Solution-specific prerequisites (R1–R8), each with Description / Why / Verify / Implement-if-missing. |
| **Implementation Guide** | Exact, ordered Intune steps: assess, create groups, configure driver update management, peripheral device-installation, printer delivery, and device-control (USB/removable) policy; assign to the pilot; validate; expand. |
| **Testing** | Pass/fail gates — driver current, printer mapped, USB policy enforced — plus coverage and post-expansion checks. |
| **Troubleshooting** | Symptom → cause → fix for the common failure modes across all three areas. |
| **Best Practices** | Staged driver rollout, device-control exceptions, peripheral/printer hygiene, and operating the solution over time. |

## PowerShell scripts

All scripts use the Microsoft Graph PowerShell SDK. Discovery, Validation, and Report are **read-only**. Remediation and Set-ScopeTargeting default to **`-WhatIf`** and must be re-run to apply.

| Script | Function | Mode |
| --- | --- | --- |
| `PERIDEV-Discovery.ps1` | Inventory driver update policies, printer/peripheral configuration profiles, and removable-storage / device-control policies with assignments. | Read-only |
| `PERIDEV-Validation.ps1` | Per-device applied state for the three gates (driver current, printer mapped, USB policy enforced). | Read-only |
| `PERIDEV-Report.ps1` | Coverage report across a target group — which devices are covered by each policy area and any error states. | Read-only |
| `PERIDEV-Remediation.ps1` | Safely fix missing/blocked coverage (re-assign policy, trigger sync) for devices out of coverage. | `-WhatIf` default |
| `PERIDEV-Set-ScopeTargeting.ps1` | Create/populate the pilot (and related) security groups for targeting. | `-WhatIf` default |

## Object naming convention (reused everywhere)

| Object | Name |
| --- | --- |
| Pilot security group | `SG-PERIDEV-Pilot` |
| Production security group | `SG-PERIDEV-Production` |
| USB exception group | `SG-PERIDEV-USB-Exception` |
| Driver update policy — pilot | `PERIDEV-DriverUpdates-Pilot` |
| Driver update policy — production | `PERIDEV-DriverUpdates-Prod` |
| Printer/peripheral profile — pilot | `PERIDEV-Printers-Pilot` |
| Peripheral device-installation profile | `PERIDEV-Peripherals-DeviceInstall` |
| Device-control (USB) policy — pilot | `PERIDEV-DeviceControl-USB-Pilot` |
| Device-control (USB) policy — production | `PERIDEV-DeviceControl-USB-Prod` |

## Outcome

Drivers current, peripherals working, and removable devices controlled across the fleet — managed from Intune, piloted before production, validated against explicit pass/fail gates, and reversible at every step, with scripts you keep and reuse.
