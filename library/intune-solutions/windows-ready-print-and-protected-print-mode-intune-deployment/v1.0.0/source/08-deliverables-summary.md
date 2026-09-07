# Deliverables Summary

Everything included in this solution.

## Documentation (compiled to PDF)
1. **Solution Overview** — Windows Ready Print vs. Windows Protected Print mode, the three-tier
   architecture, what enabling WPP actually does, and how it's delivered through the Intune Policy CSP.
2. **Requirements** — Windows 11 24H2+, Intune rights, the compatibility inventory, Mopria/IPP printers,
   a target print path, pilot + change approval, and PowerShell — each with why / verify / implement.
3. **Implementation — Deployment Strategy** — the Phase 1–7 runbook: assess → design the target path →
   build the Custom OMA-URI profile → pilot and validate → migrate off legacy print servers → roll out in
   rings → prevent regression.
4. **Testing & Validation** — eight objective tests, from baseline inventory to "removals match the plan"
   and a successful IPP-class-driver print.
5. **Troubleshooting Guide** — symptom→cause→verify→fix for the Custom-profile errors, removed printers,
   can't-print, scanning loss, legacy software printers, blocked Point-and-Print, reverting, and sovereign
   clouds.
6. **Best Practices** — assess before enforce, scope deliberately, modern-path-first, ring rollout, and
   regression prevention.
7. **Executive Summary** — the one-page brief for stakeholders.

## PowerShell tools (packaged as a ZIP)
1. **`WPPRINT-Get-PrintDriverInventory.ps1`** — inventories installed print drivers and printers, flagging
   third-party (V3/V4) drivers vs. the Microsoft IPP Class Driver — i.e., what WPP would remove.
2. **`WPPRINT-Test-MopriaReadiness.ps1`** — tests each printer's IPP/IPPS reachability and driverless
   (Mopria/IPP class driver) eligibility.
3. **`WPPRINT-Test-ScanCapability.ps1`** — flags multifunction scanners that may lose function under WPP
   unless they support Mopria/eSCL.
4. **`WPPRINT-Get-WPPState.ps1`** — reports OS build (24H2+ eligibility) and the current WPP state from the
   registry.
5. **`WPPRINT-Validate-Deployment.ps1`** — post-deployment validation: WPP enabled, no third-party drivers
   remaining, and a test print via the IPP class driver.

All scripts are Windows PowerShell 5.1+ compatible, run elevated (deployable via Intune platform script /
Proactive Remediation), and are parse-verified.

## Scope
- **In scope:** deploying and hardening **Windows Ready Print / WPP** through Intune on **Windows 11
  24H2+**, with compatibility assessment and legacy print-server migration.
- **Referenced, not rebuilt:** vendor-side printer configuration (enabling IPP/IPPS, Mopria
  certification) and Universal Print connector setup.
