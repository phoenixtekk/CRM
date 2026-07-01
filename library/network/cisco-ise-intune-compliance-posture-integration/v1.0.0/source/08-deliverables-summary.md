# Deliverables Summary

This solution delivers everything needed to wire Cisco ISE to Microsoft Intune through the MDM
compliance connection, so ISE gates network / VPN access on real-time device compliance and
enrollment — deployed pilot-first and rollback-ready.

## Documentation

| Document | What it gives you |
|----------|-------------------|
| **Solution Overview** | How ISE-to-Intune posture works: the Entra app registration ISE uses, the MDM compliance connection, the compliance/enrollment signals ISE reads, and how they map to authorization. |
| **Requirements Guide** | Every prerequisite (Intune + enrolled devices, compliance policies, the Entra app registration with Graph permissions, ISE licensing/version, network reachability, pilot group, change control) with Description / Why / Verify / Implement-if-missing. |
| **Implementation Guide** | Ordered, click-by-click steps: register the app in Entra, grant Graph permissions, create the secret, connect ISE to Intune (architectural), author the named compliance policies, map compliance to ISE authorization (architectural), assign the pilot, validate, and expand. |
| **Testing Guide** | Explicit pass/fail gates: connector readiness, policies evaluating, compliant → granted, non-compliant → denied, unmanaged → denied, fleet coverage. |
| **Troubleshooting Guide** | Fixes for app-registration/permission errors, connector not reporting, compliant device denied, and non-compliant device allowed. |
| **Best Practices** | Grace periods, remediation paths, secret hygiene, pilot-first expansion, steady-state operations. |
| **Global Requirements (Network)** | Category-level prerequisites shared by all Network solutions. |

## PowerShell scripts

All scripts are read-only against Microsoft Graph (the remediation script defaults to
`-WhatIf`). Cisco ISE internals are deferred to Cisco's documentation.

| Script | Purpose |
|--------|---------|
| **ISEPOST-Discovery.ps1** | Connector readiness — the Entra app registration for ISE, its Graph permissions and secret state, and the Intune compliance policies. |
| **ISEPOST-Validation.ps1** | Confirms THIS device's compliance + enrollment state exactly as ISE would read it from Intune. |
| **ISEPOST-Report.ps1** | Fleet compliance-coverage report plus a conceptual access-decision (granted vs denied) breakdown. |
| **ISEPOST-Remediation.ps1** | Safely nudges non-compliant devices toward compliance (default `-WhatIf`; nothing changes until you pass `-Execute`). |
| **ISEPOST-Set-ScopeTargeting.ps1** | Creates and populates the pilot / expansion Entra group(s) used for staged rollout. |

## Named objects this solution standardizes

- **Entra app registration:** `ISE-Intune-Compliance-Connector`
- **Compliance policies:** `Compliance – Windows – Baseline`, `Compliance – iOS – Baseline`,
  `Compliance – Android – Baseline`, `Compliance – macOS – Baseline`
- **Pilot group:** `PILOT – ISE Posture Devices`
- **Expansion group:** `PROD – ISE Posture Devices`

## Outcome

Network and VPN access is granted only to devices Intune says are compliant and enrolled —
enforced by Cisco ISE, and proven on a pilot (compliant → granted, non-compliant → denied)
before you scale to the fleet.
