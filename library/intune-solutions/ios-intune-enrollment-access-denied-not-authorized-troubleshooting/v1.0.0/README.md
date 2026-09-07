# iOS/iPadOS Intune Enrollment "Access Denied / Not Authorized" — Root-Cause & Remediation Troubleshooting Guide

- **Category:** Intune (intune-solutions) · **Code:** ENRLDX · **Version:** 1.0.0 · **Status:** generated · **Branding:** off

## Pricing (new model, T3 DX)
| Audience | SKU | Price |
|---|---|---|
| Commercial | PTK-ENRLDX-COMM-001 | $749.00 |
| Non-Profit | PTK-ENRLDX-NPO-001 | $449.40 |
| Government | PTK-ENRLDX-GOV-001 | $636.65 |

## What it solves
A user enrolling an iPhone/iPad into Intune hits **"Access Denied — you are not authorized to view this
page"** with a Diagnostic block (Activity Id, Session Id, Timestamp). It's a **tenant-side authorization
gate**, not a device fault. Uses the on-screen IDs to read the failed enrollment sign-in and pin the gate
— **license, MDM user scope, enrollment restriction, or Conditional Access** — then remediate, re-enroll,
and validate. The 03 implementation IS the root-cause/remediation runbook (Phase 1–4).

## Included
- Docs: 01 Overview · 02 Requirements (+ intune global) · 03 Root-Cause & Remediation Guide (Phase 1–4)
  · 05 Testing · 06 Troubleshooting/FAQ · 07 Best Practices · 08 Deliverables · Exec Summary.
- 5 Graph scripts: ENRLDX-Get-EnrollmentSignin, ENRLDX-Get-UserIntuneLicense, ENRLDX-Get-MdmUserScope,
  ENRLDX-Get-EnrollmentRestrictions, ENRLDX-Get-EnrollmentCA.

## Scope note
Gates + method identical Commercial + GCC/GCC High/DoD (portals entra.microsoft.us / intune.microsoft.us,
`-Environment USGov`) — no Government variant.

## Next
`/publish-solution ios-intune-enrollment-access-denied-not-authorized-troubleshooting`
