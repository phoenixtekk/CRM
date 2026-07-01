# 2. Requirements — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

Each requirement is structured as **Description / Why / Verify / Implement-if-missing**. **Never assume a prerequisite exists** — verify each one before the program proceeds past the Plan gate. Requirements are numbered R1–R15. R1–R3 are **hard gating prerequisites**: no GCC High provisioning starts until they are satisfied.

> Naming convention used throughout the program (reused verbatim in implementation): every created object is named `<Purpose> – <Scope> – <Stage>`, e.g. `Migration SvcAcct – Exchange – Target`.

---

## R1. GCC High eligibility + Microsoft validation/sponsorship  *(GATING)*

- **Description:** The organization is formally validated by Microsoft as eligible for GCC High (US Gov / DoD / DIB / ITAR / EAR / CMMC / FedRAMP-High driver) and has Microsoft sponsorship for tenant provisioning.
- **Why:** GCC High is eligibility-restricted; without Microsoft validation, no GCC High tenant can be provisioned at all. This is the program's first gate.
- **Verify:** Confirm a completed Microsoft validation / eligibility attestation and a sponsorship/onboarding case reference. Confirm a documented compliance driver (e.g. CMMC level + DFARS 252.204-7012, or ITAR registration).
- **Implement-if-missing:** Engage the AOS-G reseller (R2) to initiate the Microsoft eligibility validation; assemble the eligibility evidence (contracts/clauses citing the driver). Do not proceed until validated.

## R2. Authorized GCC High reseller / AOS-G partner  *(GATING)*

- **Description:** A signed relationship with an **authorized GCC High reseller** under the **AOS-G** (Agreement for Online Services – Government) program.
- **Why:** GCC High licensing and tenant provisioning are **not** available through standard commercial channels. An AOS-G partner is mandatory to procure licenses and stand up the tenant.
- **Verify:** Confirm an executed AOS-G agreement and a named reseller contact. Confirm the reseller can transact the required GCC High SKUs.
- **Implement-if-missing:** Select and contract an authorized AOS-G reseller before any licensing or provisioning. Most eligibility validation (R1) is driven through this partner.

## R3. Provisioned GCC High tenant + licensing  *(GATING)*

- **Description:** A live GCC High tenant (`<org>.onmicrosoft.us`) with the required **Microsoft 365 GCC High** and **Microsoft 365 Government** license SKUs assigned-capacity available for all in-scope users.
- **Why:** The target tenant and licenses must exist before identity, mail, content, or Azure workloads can land. GCC High SKUs are distinct from commercial SKUs.
- **Verify:** Sign in at `https://admin.microsoft.com` for GCC High (resolves to the government admin portal) using a target Global Administrator; confirm tenant exists and the license counts under **Billing → Licenses** cover the user count from Discovery.
- **Implement-if-missing:** Have the AOS-G reseller provision the tenant and allocate licenses sized to the Discovery inventory (add ~10% headroom for shared/resource accounts).

## R4. Azure Government subscription(s)

- **Description:** One or more **Azure Government** subscriptions to host the landing zone (servers, PaaS, AVD).
- **Why:** Azure IaaS/PaaS/AVD workloads must land in **Azure Government** (`portal.azure.us`), which is separate from commercial Azure and from the M365 GCC High tenant billing.
- **Verify:** Sign in at `https://portal.azure.us`; under **Subscriptions** confirm at least one active Azure Government subscription bound to the GCC High Entra tenant.
- **Implement-if-missing:** Procure Azure Government subscription(s) via the AOS-G reseller / Microsoft; associate them to the GCC High Entra directory.

## R5. Global Administrator in source (commercial) AND target (GCC High)

- **Description:** A break-glass-capable Global Administrator account in the **commercial** tenant and one in the **GCC High** tenant.
- **Why:** Cross-cloud migration tooling, consent grants, and DNS/identity cutover all require elevated admin on **both** clouds.
- **Verify:** Source: sign in at `https://entra.microsoft.com` (commercial) → **Roles & admins → Global Administrator** lists the account. Target: sign in at the GCC High Entra portal (`https://entra.microsoft.us`) → same blade.
- **Implement-if-missing:** Create/assign Global Administrator in whichever cloud is missing one; store credentials in the program's privileged-access vault.

## R6. Cross-cloud mail/content migration tooling — Quest On Demand (commercial → GCC High)

- **Description:** A **Quest On Demand Migration** subscription/edition that supports **commercial-source → GCC High-target** for Exchange, SharePoint, OneDrive, and Teams.
- **Why:** Native cross-cloud (commercial → GCC High) mailbox/content moves are not available; a tool that explicitly speaks both clouds' endpoints is required.
- **Verify:** In the Quest On Demand console, confirm the project type / region supports GCC High targets and that the commercial-source connector authenticates. Confirm the license covers the object counts from Discovery.
- **Implement-if-missing:** License Quest On Demand with GCC High target capability sized to Discovery; create the migration project `Cross-Cloud Migration Project – M365 – Target`.

## R7. SharePoint/OneDrive/Teams tooling — ShareGate (GCC High edition)

- **Description:** **ShareGate** licensed with GCC High endpoint support for SharePoint/OneDrive/Teams content fidelity (permissions, versions, metadata).
- **Why:** Provides high-fidelity content migration and an alternative/complement to Quest for large or permission-heavy site sets; must target the `.us` SharePoint endpoints.
- **Verify:** In ShareGate, connect a source commercial site and a target GCC High site (`https://<org>.sharepoint.us`); confirm both connect and a test copy preserves permissions.
- **Implement-if-missing:** License ShareGate (GCC High-capable) and validate both connections before pilot.

## R8. Azure Migrate + Azure Site Recovery (ASR) for servers

- **Description:** **Azure Migrate** project and **Azure Site Recovery** (Recovery Services vault) in Azure Government for VM assessment and replication.
- **Why:** Servers are replicated and failed over (not file-copied); ASR provides block-level replication and test failover into Azure Gov.
- **Verify:** At `https://portal.azure.us` → **Azure Migrate** confirm a project exists; → **Recovery Services vaults** confirm a vault in the target Gov region.
- **Implement-if-missing:** Create migration project `Server Migration Project – IaaS – Target` and vault `Recovery Vault – ASR – Target` in the chosen Azure Gov region/resource group.

## R9. Network connectivity / bandwidth (ExpressRoute or sized internet)

- **Description:** Adequate, sized network egress from the source environment plus, where required, **ExpressRoute (Azure Government)** for server replication.
- **Why:** Multi-TB mailbox/content/VM replication is bandwidth-bound; under-provisioned links cause throttling and missed cutover windows. ASR replication for large estates often needs ExpressRoute.
- **Verify:** Measure available sustained egress; compare against total GB from Discovery and the target window. Confirm any ExpressRoute circuit is provisioned to an **Azure Government** peering location.
- **Implement-if-missing:** Provision/scale bandwidth; order **ExpressRoute for Azure Government** (note: commercial ExpressRoute peering does **not** reach Gov regions).

## R10. Identity plan — Entra in GCC High

- **Description:** A documented plan for re-establishing identity in the GCC High Entra directory: user/group re-creation, authentication method (cloud-only vs. new on-prem AD Connect to GCC High), conditional access, MFA re-registration, and licensing assignment.
- **Why:** Identity does **not** sync from commercial to GCC High. The plan determines how users authenticate on day one and is foundational to every other workstream.
- **Verify:** Confirm a written identity design naming the auth model and the group `All Migrated Users – Identity – Target`. Confirm whether a **new** Entra Connect/Cloud Sync to the GCC High tenant is required (a fresh sync agent, separate from any commercial sync).
- **Implement-if-missing:** Author the identity design; if hybrid is required, install a **new** provisioning agent targeting GCC High; otherwise plan cloud-only accounts.

## R11. DNS control for domain moves

- **Description:** Administrative control of all public DNS zones for the organization's email/SharePoint domains.
- **Why:** Domain verification in GCC High and MX/autodiscover/SPF/DKIM/DMARC cutover require editing authoritative DNS. A domain can only be verified in one tenant at a time, so the source must release it.
- **Verify:** Confirm registrar/DNS-host admin access for each in-scope domain (`nslookup -type=MX <domain>` shows the current host you control).
- **Implement-if-missing:** Obtain DNS administrative access (or a documented change path with the DNS owner) before cutover planning.

## R12. Migration service accounts (both clouds)

- **Description:** Dedicated, least-privilege **migration service accounts** in source and target, plus any required application consents for the tools.
- **Why:** Tools should authenticate as named service principals (not personal admin accounts) for auditability and throttling isolation; CMMC evidence requires named accounts.
- **Verify:** Confirm accounts `Migration SvcAcct – M365 – Source` and `Migration SvcAcct – M365 – Target` exist with the documented roles (e.g. application impersonation / SharePoint admin) and that tool consent is granted in both tenants.
- **Implement-if-missing:** Create the service accounts, assign scoped roles, grant tool admin consent in each tenant.

## R13. Compliance / ITAR data-handling controls

- **Description:** Documented controls ensuring regulated data (ITAR/EAR/CUI) stays within authorized boundaries **during transit**, including tool data-residency, US-person access, and staging-storage controls.
- **Why:** Moving export-controlled data through a non-authorized region or exposing it to non-US persons is a compliance violation, independent of the destination being GCC High.
- **Verify:** Confirm the migration tool's data path/region is US-sovereign and personnel with access are authorized (US persons where required). Confirm any staging storage is in an authorized boundary.
- **Implement-if-missing:** Configure tools for US-sovereign data handling; restrict migration-team access; document the data-flow for the CMMC/ITAR evidence package.

## R14. Estate inventory (Discovery baseline)

- **Description:** A complete, current inventory of the commercial estate: mailboxes (+ sizes/types), SharePoint sites, OneDrive accounts, Teams, Azure subscriptions, VMs, and App Services.
- **Why:** Sizing licenses (R3), bandwidth (R9), waves, and acceptance gates all derive from this baseline. You cannot plan what you have not inventoried.
- **Verify:** Confirm a Discovery CSV exists (output of `GCCHIGH-Discovery.ps1`) with per-object sizing.
- **Implement-if-missing:** Run `scripts\GCCHIGH-Discovery.ps1` (read-only) against the commercial tenant and Azure to produce `Estate-Inventory – Discovery – Source.csv`.

## R15. Change-control & rollback posture (program-wide)

- **Description:** An approved change-management process with maintenance windows, communications plan, and per-workstream rollback procedures.
- **Why:** Cutovers are outward-facing and disruptive; CMMC and operational safety require approved windows and a defined back-out.
- **Verify:** Confirm an approved change record per planned cutover and a documented rollback for each workstream.
- **Implement-if-missing:** Establish the change/comms process; author rollback runbooks (covered in Best Practices §07). See also the shared `global-requirements-azure-solutions.md`.
