# macOS Automated Device Enrollment with SSO — v1.0.0

| | |
|---|---|
| **Category** | Intune Solutions |
| **Solution code** | ADEMAC |
| **Version** | 1.0.0 |
| **Commercial** | $1,695.00 (SKU `PTK-ADEMAC-COMM-001`) |
| **Non-Profit** | $1,017.00 (SKU `PTK-ADEMAC-NPO-001`, 40% off) |

## What it is
Zero-touch deployment for company Macs: Apple **Automated Device Enrollment (ADE)** auto-enrolls
ABM-sourced Macs into Microsoft Intune (supervised), and **Platform SSO** (Microsoft Enterprise SSO
extension) ties macOS sign-in to **Microsoft Entra ID** with a Secure Enclave key.

## What's included
**Documentation (Word + PDF):** Executive Summary · Solution Overview · Requirements (+ category
Global Requirements) · Implementation (4 phases) · Testing · Troubleshooting · Best Practices ·
Deliverables Summary.

**PowerShell scripts (`ADEMAC-Scripts.zip`):**
- `ADEMAC-Discovery.ps1` — tenant readiness (APNs/ADE token expiry, profiles, Company Portal, SSO).
- `ADEMAC-Validation.ps1` — validate one Mac against the acceptance gate.
- `ADEMAC-DeviceReport.ps1` — tenant-wide macOS fleet CSV (ADE coverage, OS, compliance).
- `ADEMAC-Remediation.ps1` — safe token re-sync + profile re-assignment (read-only by default).
- `Set-PlatformSSOProfile.ps1` — create & assign the Platform SSO profile (Secure Enclave method).

**Hero image:** `ADEMAC-hero.png` (1200×1200).

## Files
```
source/        executive-summary, 01-overview, 02-requirements, global-requirements, 03-implementation,
               05-testing, 06-troubleshooting, 07-best-practices, 08-deliverables-summary
scripts/       ADEMAC-Discovery, ADEMAC-Validation, ADEMAC-DeviceReport, ADEMAC-Remediation, Set-PlatformSSOProfile
listing/       bagisto-products.json, hero.json, sales-content.md
deliverables/  ADEMAC-Solution.docx, ADEMAC-Solution.pdf, ADEMAC-Scripts.zip, ADEMAC-hero.svg/.png
solution.meta.json
```

## Next
Build deliverables + hero, then `/publish-solution macos-ade-with-sso`.
