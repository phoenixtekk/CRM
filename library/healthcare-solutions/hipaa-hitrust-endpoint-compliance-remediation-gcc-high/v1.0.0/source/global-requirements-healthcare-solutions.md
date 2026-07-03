# Global Requirements — Healthcare Solutions

These category-wide requirements apply to **every** solution in the **Healthcare Solutions** category. They establish the tenant, identity, administrative, network, and data-handling baseline that solution-specific requirements build on. Each follows the house pattern: **Description / Why / Verify / Implement-if-missing**. Never assume a prerequisite exists — verify it, and provision it if it does not.

> **Framework, not certification.** Solutions in this category provide **technical enforcement and evidence** to support HIPAA, HITRUST, and similar healthcare regulatory programs. They do **not** constitute legal advice, a compliance attestation, or a certification. Formal compliance and certification require organizational policy, risk analysis, workforce training, business associate agreements, physical safeguards, and authorized third-party assessment.

---

## GR1 — Microsoft 365 / Entra ID tenant

- **Description:** An active Microsoft 365 tenant with Microsoft Entra ID as the identity provider.
- **Why:** Every Healthcare Solution is delivered through Microsoft cloud services bound to a tenant; all identities, devices, and policies live here.
- **Verify:** Sign in to the **Microsoft Entra admin center** (`https://entra.microsoft.com`) > **Identity** > **Overview** and confirm the tenant name and a verified domain.
- **Implement if missing:** Provision a Microsoft 365 tenant, verify a custom domain, and confirm directory sync (if hybrid) is healthy.

## GR2 — Administrative roles with least privilege

- **Description:** Operators hold only the roles needed — e.g. **Intune Administrator**, **Security Administrator**, **Conditional Access Administrator** — rather than Global Administrator for day-to-day work.
- **Why:** HIPAA and HITRUST expect least-privilege access and separation of duties; over-privileged admin accounts are a top audit finding and breach vector.
- **Verify:** **Entra admin center** > **Roles & admins** — review role assignments; confirm Global Administrator is limited and ideally PIM-eligible rather than permanent.
- **Implement if missing:** Assign scoped roles; where Entra ID P2 is available, make privileged roles **eligible** via Privileged Identity Management with approval and time limits.

## GR3 — Multi-factor authentication for administrators

- **Description:** MFA enforced for all administrative accounts (and, ideally, all users).
- **Why:** Credential theft is the leading cause of healthcare breaches; MFA is a baseline HIPAA-aligned access control and HITRUST expectation.
- **Verify:** **Entra admin center** > **Protection** > **Conditional Access** (or security defaults) and confirm MFA applies to admin roles.
- **Implement if missing:** Enforce MFA via a Conditional Access policy targeting admin roles (or enable security defaults for smaller tenants).

## GR4 — Device enrollment / management foundation

- **Description:** A working device management foundation (Intune MDM authority, enrollment configured) for the platforms in scope.
- **Why:** Endpoint controls and evidence depend on managed, enrolled devices; unmanaged devices are outside enforcement and invisible to evidence.
- **Verify:** **Intune admin center** > **Devices** > **Overview** and confirm enrolled devices report in.
- **Implement if missing:** Configure enrollment (automatic enrollment, Autopilot, or platform-appropriate methods) and confirm a pilot device enrolls and checks in.

## GR5 — Network and connectivity to Microsoft cloud services

- **Description:** Clinical sites can reach Microsoft 365, Intune, and Defender service endpoints (required URLs/ports not blocked by proxies/firewalls).
- **Why:** Policy delivery, device check-in, Defender sensor telemetry, and onboarding all require connectivity; blocked endpoints cause silent non-reporting that looks like non-compliance.
- **Verify:** Confirm the Microsoft 365 and Defender for Endpoint required endpoints are reachable from a clinical subnet; check device check-in/sensor health.
- **Implement if missing:** Allow the documented Microsoft service URLs/IP ranges through proxies/firewalls; validate from a representative clinical endpoint.

## GR6 — Data handling, minimization, and no-ePHI-in-evidence rule

- **Description:** Generated documentation, scripts, and evidence avoid storing electronic protected health information (ePHI); evidence captures **configuration and compliance metadata**, not patient data.
- **Why:** Compliance tooling must not itself become an ePHI repository or a new breach surface; minimization is a core HIPAA and HITRUST principle.
- **Verify:** Review evidence outputs and scripts to confirm they contain device/compliance/exposure metadata only — never patient records.
- **Implement if missing:** Scope reports to metadata; restrict the evidence store (GR7); redact any incidental sensitive values.

## GR7 — Secured, retained evidence repository

- **Description:** An access-controlled repository for compliance evidence with retention aligned to regulatory look-back (HIPAA: six years).
- **Why:** Audits cover past periods; evidence must be retained and protected to be admissible and to avoid becoming an exposure itself.
- **Verify:** Confirm a restricted repository with retention applied and access limited to owner/assessors.
- **Implement if missing:** Provision a restricted SharePoint/document library or secured share, apply a retention policy, and limit access.

## GR8 — Named control owner and change/exception governance

- **Description:** A designated owner accountable for the control set and a lightweight process for changes and risk-accepted exceptions.
- **Why:** HIPAA requires assigned security responsibility; HITRUST grades defined accountability and governed change. Unowned controls drift.
- **Verify:** Confirm the owner is named and that changes/exceptions route through an approval with justification and expiry.
- **Implement if missing:** Assign the role, adopt a simple approval workflow, and record exceptions with owner approval and review dates.

## GR9 — Optional: Microsoft Purview Compliance Manager

- **Description:** Microsoft Purview **Compliance Manager** used as an optional assessment aid (HIPAA/HITRUST assessment templates, improvement actions, score).
- **Why:** Compliance Manager maps Microsoft controls to regulatory templates and tracks improvement actions, complementing the enforcement/evidence this category delivers. It is an **aid**, not a certification.
- **Verify:** **Microsoft Purview portal** (`https://purview.microsoft.com`) > **Compliance Manager** and confirm access; check for a HIPAA/HITRUST assessment template.
- **Implement if missing:** Enable Compliance Manager (licensing-dependent) and add the relevant assessment template to track improvement actions alongside the technical controls.

---

> Solution-specific requirements (licensing tiers, named groups, named objects, device hardware) are listed in each solution's `02-requirements.md`.
