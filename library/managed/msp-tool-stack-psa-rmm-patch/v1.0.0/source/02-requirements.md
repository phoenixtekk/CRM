# 2. Requirements — MSP Tool Stack Design & Standup — PSA, RMM & Patch Management

Do not assume any prerequisite is already in place. Work through each requirement below. For each item, confirm the **Description**, understand **Why it is required**, run the **How to verify** check, and if the check fails, follow **How to implement if missing** before proceeding to implementation. Requirements R1–R12 are specific to this solution; the category-wide requirements common to every Managed solution are in `global-requirements-managed.md` and must also be satisfied.

---

## R1 — PSA platform selected, provisioned, and licensed

- **Description:** A Professional Services Automation platform (for example ConnectWise PSA, Datto Autotask, or HaloPSA) provisioned with a tenant/instance and enough licensed seats for the technical and administrative staff who will use it.
- **Why required:** The PSA is the system of record for tickets, companies, agreements, time, and billing. Without it there is no single source of truth and no place for RMM alerts to land as tickets.
- **How to verify:** Sign in to the PSA admin console as an administrator and confirm the instance is active and the licensed seat count covers all named users (console → System/Admin → Licensing or Members).
- **How to implement if missing:** Run the platform selection criteria in `03-implementation.md` (Stage Assess), procure the platform, and request the tenant/instance from the vendor. Record the chosen platform in the documentation home (R12).

## R2 — RMM platform selected, provisioned, and licensed

- **Description:** A Remote Monitoring & Management platform (for example NinjaOne, Datto RMM, or ConnectWise Automate) provisioned with a tenant and licensed endpoint capacity.
- **Why required:** The RMM is the system of action — it deploys agents, monitors endpoints, alerts, and runs scripted automation across every managed device.
- **How to verify:** Sign in to the RMM admin console and confirm the tenant is active and the licensed endpoint count covers the expected device population (console → Administration → Licensing).
- **How to implement if missing:** Select against the criteria in `03-implementation.md`, procure, and provision the tenant. Confirm the licensing model (per-endpoint vs per-technician) matches the practice's growth plan.

## R3 — Agent deployment method confirmed

- **Description:** A confirmed, repeatable method to deploy the RMM agent to managed endpoints (group policy / Intune app deployment / deployment script / network-installer URL).
- **Why required:** Endpoints are invisible to the stack until the agent is installed; the onboarding workflow depends on a reliable bulk-deployment path.
- **How to verify:** Confirm the RMM provides an agent installer and a deployment package, and that at least one deployment channel (Intune, GPO, or RMM network discovery) is available in the target environment.
- **How to implement if missing:** Generate the agent installer from the RMM (console → Administration → Agents/Downloads), and prepare a deployment package for the chosen channel (for Intune: package as a Win32 app; for GPO: an MSI assigned via a software-installation policy).

## R4 — Patch engine selected (RMM module or Intune / WUfB)

- **Description:** A decision on which engine governs operating-system and third-party patching: the RMM's native patch module, or Microsoft Intune with Windows Update for Business (WUfB).
- **Why required:** Patching is the system of compliance; the engine choice determines where rings, schedules, and compliance reporting live and must be settled before ring design.
- **How to verify:** Confirm the selected engine is available — for the RMM module, that the license includes patch management; for Intune/WUfB, that you have a Microsoft Entra tenant with Intune licensing and devices that are Entra-joined or hybrid-joined and enrolled in Intune.
- **How to implement if missing:** If using the RMM module, enable it in the RMM license. If using Intune/WUfB, ensure Intune licensing (Microsoft Intune Plan 1 or a bundle that includes it) and device enrollment. See `03-implementation.md` Stage Design for the selection criteria.

## R5 — Administrative accounts and a role model

- **Description:** Dedicated administrator accounts for the PSA, RMM, and patch engine, plus a defined set of roles (administrator, technician, dispatcher, read-only/reporting).
- **Why required:** Least-privilege role separation prevents accidental or malicious damage and is required for the onboarding workflow to assign technicians correctly.
- **How to verify:** In each console confirm at least one named administrator account exists (not a shared generic login) and that role definitions exist (PSA → Security Roles; RMM → Roles/Permissions).
- **How to implement if missing:** Create named admin accounts; define the four roles above; assign existing users to the least-privilege role that lets them do their job.

## R6 — API keys / credentials for PSA↔RMM integration

- **Description:** API keys, OAuth client credentials, or integration service accounts in both the PSA and the RMM, scoped to the integration's needs.
- **Why required:** The PSA↔RMM ticket sync, asset/CMDB feed, and alert→ticket flow all authenticate via these credentials; without them the seams cannot be built.
- **How to verify:** Confirm an API/integration section exists in each console and that you can generate a key/credential there (PSA → System → API/Integrations; RMM → Administration → API).
- **How to implement if missing:** Generate a dedicated integration credential in each tool, named for the integration (`Integration – PSA-RMM – Bi-Directional`), scoped to least privilege, and store both in the secrets store (see global requirements). Never embed keys in scripts.

## R7 — Naming and site taxonomy standard agreed

- **Description:** An agreed `<Purpose> – <Scope> – <Stage>` naming convention and a site taxonomy mapping each managed client to one RMM site and one PSA company.
- **Why required:** A consistent taxonomy makes the stack self-documenting, prevents duplicate/ambiguous objects, and is the backbone of the onboarding template.
- **How to verify:** Confirm the convention from `01-solution-overview.md` is documented and approved, and that no conflicting legacy naming exists in either tool.
- **How to implement if missing:** Adopt the convention as written; if legacy objects exist, plan a rename/migration during Stage Design.

## R8 — Security and MFA on the tools

- **Description:** Multi-factor authentication enforced on the PSA, RMM, and patch engine for all human accounts, and SSO configured where supported.
- **Why required:** These tools have privileged, cross-client reach; a compromised admin login can affect every managed client. MFA is non-negotiable.
- **How to verify:** In each console confirm MFA is enforced for all users (PSA → Security → MFA/SSO; RMM → Administration → Security/2FA; Intune via Entra Conditional Access).
- **How to implement if missing:** Enforce MFA for all users in each tool. Where the tool supports SSO via Entra ID, configure it and apply a Conditional Access policy requiring MFA.

## R9 — A pilot client identified

- **Description:** One real (or representative test) managed client designated as the pilot for the onboarding workflow and validation.
- **Why required:** The onboarding workflow and integrations must be validated against a real client before the model is expanded to the full base.
- **How to verify:** Confirm a pilot client is named, has consented to (or is a safe test stand-in for) being onboarded, and has at least a few endpoints available.
- **How to implement if missing:** Select a low-risk, cooperative client or stand up an internal test company/site with a handful of test devices.

## R10 — Network and agent connectivity

- **Description:** Outbound connectivity from managed endpoints to the RMM and patch sources (HTTPS to vendor cloud endpoints; Windows Update / WSUS / Delivery Optimization for patches).
- **Why required:** Agents must reach the RMM cloud to report and be managed; patch engines must reach update sources to download and report compliance.
- **How to verify:** From a representative endpoint, confirm it can reach the RMM's documented hostnames/ports and Microsoft Update endpoints (and any required allow-list URLs).
- **How to implement if missing:** Allow-list the RMM vendor's documented URLs/IPs on perimeter firewalls and proxies; ensure Windows Update endpoints are reachable. Use the discovery script to flag blocked endpoints.

## R11 — Documentation / runbook home

- **Description:** A documentation location (IT documentation platform or wiki) where the operating standards, integration details, and onboarding runbook live.
- **Why required:** The stack is only repeatable if its standards and runbooks are written down where the whole team can find them.
- **How to verify:** Confirm a documentation home exists and the team has access.
- **How to implement if missing:** Stand up or designate a documentation home and create a section for the MSP operating standard.

## R12 — Secure secrets storage

- **Description:** A secure secrets store (password manager / secrets vault) for the integration API keys, admin credentials, and service accounts.
- **Why required:** The integration credentials are highly privileged; storing them in scripts, spreadsheets, or chat is an immediate, fleet-wide risk.
- **How to verify:** Confirm a secrets store is in use and that the integration credentials are stored there, not in code.
- **How to implement if missing:** Adopt a secrets store; migrate all credentials into it; rotate any credential that was previously stored insecurely.

---

## Requirements checklist

| # | Requirement | Verified |
|---|-------------|----------|
| R1 | PSA platform selected, provisioned, licensed | ☐ |
| R2 | RMM platform selected, provisioned, licensed | ☐ |
| R3 | Agent deployment method confirmed | ☐ |
| R4 | Patch engine selected (RMM or Intune/WUfB) | ☐ |
| R5 | Admin accounts + role model | ☐ |
| R6 | API keys for PSA↔RMM integration | ☐ |
| R7 | Naming / site taxonomy standard | ☐ |
| R8 | Security + MFA on the tools | ☐ |
| R9 | Pilot client identified | ☐ |
| R10 | Network / agent connectivity | ☐ |
| R11 | Documentation / runbook home | ☐ |
| R12 | Secure secrets storage | ☐ |
