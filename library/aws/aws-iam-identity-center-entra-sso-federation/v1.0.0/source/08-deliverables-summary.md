# 8. Deliverables Summary — AWS IAM Identity Center + Microsoft Entra SSO Federation

## Documentation

| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | How federation works (SAML auth, SCIM provisioning, permission sets + assignments), the named objects, scope, and the deployment model |
| 2. Requirements Guide | Solution-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (AWS) | Category-wide AWS prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps across the AWS and Entra consoles — enable IAM Identity Center, delegated admin, SAML + SCIM, permission sets, pilot, expand, decommission |
| 5. Testing Guide | Seven pass/fail validation gates (sign-in, provisioning, least-privilege, deprovisioning, sessions, break-glass, assignment matrix) |
| 6. Troubleshooting Guide | Symptom -> cause -> fix for the common federation failures |
| 7. Best Practices | Keep-it-clean guidance and where to go next |

## Automation artifacts

| Script | What it does |
|---|---|
| `AWSSSO-Discovery.sh` | AWS CLI, read-only. Reports whether IAM Identity Center is enabled, lists standalone IAM users + access keys (the decommission baseline), and lists existing permission sets/assignments |
| `AWSSSO-Validate.ps1` | PowerShell (Microsoft.Graph), read-only. Validates the `AWS IAM Identity Center – Federation – SSO` enterprise app: SAML config present, provisioning On, connection healthy, scope = assigned only, and the five `AWS-SSO-*` groups in scope |
| `AWSSSO-Report.sh` | AWS CLI, read-only. Produces the *group -> permission set -> account* assignment matrix for comparison against the entitlement decision |
| `AWSSSO-permission-sets.tf` | Terraform (AWS provider). Defines the five named permission sets, managed-policy attachments, and account assignments. Run **plan-first**; apply sandbox scope for the pilot, production waves after approval |
| `AWSSSO-Entra-Provisioning.ps1` | PowerShell (Microsoft.Graph). Optional, **gated helper** that can create the enterprise app and the five Entra groups. Defaults to **`-WhatIf` (preview only)**; makes changes only when explicitly confirmed |

All apply/change artifacts are plan/what-if-first and pilot-first: Terraform runs `plan` before `apply`, the provisioning helper previews by default, and every discovery/validation/report script is read-only.

## What the buyer receives

- This implementation guide as a Word document and PDF.
- All five automation artifacts (AWS CLI `.sh`, Terraform `.tf`, PowerShell `.ps1`) in a single ZIP — delivered as a Complete Solution Package (PDF + Word + scripts).
- A repeatable process following the standard model: `Assess -> Configure -> Pilot -> Validate -> Expand`.

## Outcome

Corporate Entra ID identities federated into AWS IAM Identity Center with least-privilege, auto-provisioned access across the organization — proven on a sandbox pilot with break-glass in place before production expansion and legacy IAM-user decommissioning.
