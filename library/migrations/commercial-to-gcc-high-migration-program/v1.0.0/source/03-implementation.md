# 3. Implementation — Commercial-to-GCC High Microsoft 365 & Azure Migration Program (Exchange, SharePoint, Teams, AVD)

This is the **program runbook**. It follows the standard program model — **Discover → Assess → Plan → Provision → Pilot → Migrate (per workstream) → Cutover → Validate → Decommission** — and contains a phase-by-phase methodology plus a self-contained runbook for each of the seven workstreams.

> **Endpoint reminder (read first):** GCC High and Azure Government use the **`.us` sovereign endpoints**. Wherever a portal/URL appears below, the **target** uses the government endpoint and the **source (commercial)** uses the standard one:
> - Azure Government portal: `https://portal.azure.us`
> - M365 Government admin: `https://admin.microsoft.com` (resolves to the government admin center when signed in with a GCC High account)
> - Entra (Gov): `https://entra.microsoft.us`
> - Exchange admin (Gov): `https://admin.exchange.microsoft.us`
> - SharePoint admin (Gov): `https://<org>-admin.sharepoint.us`
> - Teams admin (Gov): `https://admin.teams.microsoft.us`
> - Sign-in authority (Gov): `https://login.microsoftonline.us`
> - SharePoint content (Gov): `https://<org>.sharepoint.us`
> - Exchange mail (Gov): `https://outlook.office365.us`

> **Naming convention (mandatory, reused verbatim):** every created object is `<Purpose> – <Scope> – <Stage>`. The canonical object names introduced in each phase are reused later. Stage is `Source` (commercial), `Target` (GCC High), or `Program` (cross-cutting).

---

## Phase 1 — Discover

**Goal:** produce the authoritative estate baseline.

1. Run the read-only discovery script from an admin workstation:
   - `scripts\GCCHIGH-Discovery.ps1` connects to the **commercial** M365 (Exchange Online, SharePoint, Teams) and **commercial** Azure, and exports `Estate-Inventory – Discovery – Source.csv`.
2. Capture, per object: mailbox sizes/types (user/shared/room/resource), SharePoint site count + storage, OneDrive accounts + storage, Teams (with membership and channel counts), Azure subscriptions, VMs (OS, size, disks), and App Services / PaaS resources.
3. Record total **GB per workstream** — this drives bandwidth (R9) and licensing (R3) sizing.
4. Inventory dependencies that do **not** migrate cleanly cross-cloud: app registrations, Power Platform environments, third-party SaaS integrations, conditional-access/Intune config, mail connectors, and public folders.

**Exit gate:** signed-off `Estate-Inventory – Discovery – Source.csv` covering 100% of in-scope objects.

---

## Phase 2 — Assess

**Goal:** turn the inventory into a sized, risk-rated plan input.

1. **Compliance scoping:** confirm the driver (CMMC level, ITAR/EAR, FedRAMP High) and identify export-controlled data sets (R13).
2. **Sizing:** map total GB and object counts to license counts (R3), tool licensing (R6/R7), and bandwidth/ExpressRoute (R9).
3. **Server assessment:** in Azure Migrate (commercial discovery appliance or imported inventory), generate readiness + right-sizing for Azure Government targets.
4. **Complexity rating:** rate each mailbox/site/team/server/app High/Med/Low based on size, permissions complexity, integrations, and compliance sensitivity.

**Exit gate:** an assessment summary with sized targets and a risk rating per object.

---

## Phase 3 — Plan

**Goal:** wave plan + workstream sequencing + named objects.

1. Generate the wave plan from Discovery:
   - `scripts\GCCHIGH-Set-WavePlan.ps1 -InputCsv "Estate-Inventory – Discovery – Source.csv" -OutputCsv "Wave-Plan – Program – Program.csv"` groups users/sites/servers into waves (`Wave 01 … Wave NN`), keeping departments/teams together to limit cross-cloud coexistence pain.
2. **Workstream sequencing (recommended order within each wave):**
   1. **Identity** (must lead — everything authenticates against it),
   2. **Exchange**, **SharePoint/OneDrive**, **Teams** (content workstreams, parallelizable),
   3. **Azure IaaS servers**, **Azure apps/PaaS**, **AVD** (infrastructure, can run in parallel program tracks).
3. **Pilot wave:** designate `Wave 00 – Pilot – Program` (5–25 representative users + 1–2 sites/teams + 1 non-critical server) ahead of production waves.
4. Name every object that will be created (see each workstream below) and record them in the program register.
5. Schedule cutover windows and rollback owners per wave (R15).

**Exit gate:** approved `Wave-Plan – Program – Program.csv`, sequenced workstreams, named objects, scheduled windows.

---

## Phase 4 — Provision (GCC High tenant + Azure Gov landing zone)

**Goal:** stand up the empty target so workloads have somewhere to land. **Prerequisites R1–R4 must be satisfied (eligibility validated, AOS-G reseller, tenant + licenses, Azure Gov subscription).**

### 4.1 Confirm the GCC High tenant
1. Sign in to the GCC High admin center at `https://admin.microsoft.com` with `Migration SvcAcct – M365 – Target` (or a target Global Admin).
2. **Billing → Licenses:** confirm GCC High SKUs cover the Discovery user count.

### 4.2 Build the Azure Government landing zone
At `https://portal.azure.us`, signed in to the GCC High Entra tenant:
1. **Subscriptions:** confirm/assign the Gov subscription `Azure Gov Subscription – Platform – Target`.
2. **Resource groups → Create** the landing-zone resource groups (one per workstream/scope), e.g.:
   - `RG – Networking – Target`
   - `RG – Servers – Target`
   - `RG – PaaS – Target`
   - `RG – AVD – Target`
   - `RG – ASR-Recovery – Target`
3. **Virtual networks → Create** `VNet – LandingZone – Target` with subnets `snet-servers`, `snet-avd`, `snet-paas`, plus a gateway subnet if ExpressRoute is used (R9).
4. **Network security groups:** create `NSG – Servers – Target`, `NSG – AVD – Target`; attach to subnets.
5. If ExpressRoute (Gov) is in scope: **ExpressRoute circuits** → provision to a **Government** peering location and create `VNet Gateway – ExpressRoute – Target`.

**Exit gate:** target tenant confirmed with licenses; landing-zone resource groups, VNet/subnets, NSGs (and ExpressRoute if applicable) created and named.

---

## Phase 5 — Establish Identity (Entra in GCC High)

**Goal:** users can authenticate in the target before any content lands. Per R10, identity is **re-established**, not synced from commercial.

1. **Verify a routing domain first:** in the GCC High admin center → **Settings → Domains**, the tenant has `<org>.onmicrosoft.us`. (The primary email domain is verified later at cutover — a domain can only live in one tenant at a time.)
2. **Choose the auth model** (per R10): cloud-only accounts, or a **new** Entra Connect / Cloud Sync agent pointed at the GCC High tenant (separate install from any commercial sync).
3. **Create the master group** `All Migrated Users – Identity – Target` (security group) — every migrated account is added here for licensing and conditional access.
4. **Provision users/groups:**
   - Cloud-only: bulk-create from the Discovery CSV (Graph USGov — see `GCCHIGH-Remediation.ps1` helpers) and assign licenses via group-based licensing on `All Migrated Users – Identity – Target`.
   - Hybrid: scope the new sync agent's OUs and let it provision into GCC High.
5. **Conditional access:** create baseline policies `CA – Require MFA – Target` and `CA – Block Legacy Auth – Target` (Entra Gov → **Protection → Conditional Access**). Note: commercial CA policies are **re-created**, not migrated.
6. **MFA:** users re-register MFA in the target (registrations do not transfer).
7. **Create migration service accounts** `Migration SvcAcct – M365 – Source` and `Migration SvcAcct – M365 – Target` (R12) and grant tool consent in both tenants.

**Exit gate:** pilot users can sign in to `https://login.microsoftonline.us`, hold licenses, and satisfy conditional access.

---

## Phase 6 — Pilot

Run **every** in-scope workstream against `Wave 00 – Pilot – Program` end-to-end before any production wave. Each workstream's pilot must pass its acceptance gate (see `05-testing.md`) before production migration of that workstream begins. Capture timings to refine the wave schedule.

---

## Workstream Runbooks (Phase 7 — Migrate)

Each runbook is its own phase, executed per wave. Name every object; use the `.us` endpoints for all target operations.

### WS-A — Exchange Online (Quest cross-cloud)

1. **In Quest On Demand Migration** (R6), create/confirm project `Cross-Cloud Migration Project – M365 – Target`.
2. **Connect endpoints:** add the **commercial** source connector (auth as `Migration SvcAcct – M365 – Source`) and the **GCC High** target connector (auth as `Migration SvcAcct – M365 – Target`). Confirm the project region/edition supports the GCC High target.
3. **Match objects:** map source mailboxes to target users created in Phase 5 (match on UPN/alias). Create the migration collection `Mailbox Wave – Exchange – <Wave NN>`.
4. **Pre-stage (pass 1):** run a full mailbox sync (mail, calendar, contacts) ahead of cutover. Schedule incremental deltas.
5. **Coexistence note:** cross-cloud free/busy and unified GAL are limited — set expectations that full interoperability arrives at wave cutover.
6. **Cutover (per wave):** run the final delta; switch the user's primary mail endpoint; have users reconfigure Outlook/mobile against `https://outlook.office365.us`. MX cutover is handled in Phase 8 (domain cutover).
7. **Re-stamp addresses** if any proxy addresses need fixing post-move (`GCCHIGH-Remediation.ps1 -Mode ReStampAddresses`).

**Named objects:** `Cross-Cloud Migration Project – M365 – Target`, `Mailbox Wave – Exchange – <Wave NN>`.

### WS-B — SharePoint Online / OneDrive (ShareGate / Quest)

1. **Pre-create target sites:** in the GCC High SharePoint admin center (`https://<org>-admin.sharepoint.us`) → **Active sites → Create**, provision target sites mirroring source URLs as `Site – <SourceName> – Target`. Pre-provision OneDrive for target users (Phase 5).
2. **In ShareGate** (R7) or Quest, connect commercial source site and GCC High target site (`https://<org>.sharepoint.us`).
3. **Copy (pass 1):** copy structure, libraries, lists, versions, and **permissions** (map source principals to target Entra principals). Create migration set `Content Wave – SPO/OneDrive – <Wave NN>`.
4. **Incremental:** run delta copies until cutover.
5. **Cutover (per wave):** final delta; set source sites read-only; update any bookmarks/links to the `.us` URLs; re-point Teams files (WS-C) to migrated sites.
6. **Re-permission** any broken inheritance post-move (`GCCHIGH-Remediation.ps1 -Mode RePermission`).

**Named objects:** `Site – <SourceName> – Target`, `Content Wave – SPO/OneDrive – <Wave NN>`.

### WS-C — Microsoft Teams (Quest / ShareGate)

1. **Pre-create teams** in the GCC High Teams admin center (`https://admin.teams.microsoft.us`) or let the tool create them; name `Team – <SourceName> – Target`.
2. **Migrate** team membership, channels, tabs, and the underlying SharePoint files (the team's site is migrated by WS-B). Create set `Teams Wave – Teams – <Wave NN>`.
3. **Chat caveat:** 1:1 and some channel chat history support varies by tool/edition — confirm scope; document what is and isn't carried. Migrate what the edition supports; otherwise treat chat as a fresh start at cutover.
4. **Cutover (per wave):** finalize membership; validate channel files resolve to the migrated `.us` SharePoint site; users sign in to Teams against the GCC High tenant.

**Named objects:** `Team – <SourceName> – Target`, `Teams Wave – Teams – <Wave NN>`.

### WS-D — Azure IaaS servers (Azure Migrate + ASR → failover into Azure Gov)

1. **Assess:** in Azure Migrate (`Server Migration Project – IaaS – Target` per R8), confirm readiness/right-sizing for Azure Gov.
2. **Recovery vault:** confirm `Recovery Vault – ASR – Target` in `RG – ASR-Recovery – Target`.
3. **Enable replication:** in the vault → **Site Recovery → Enable replication**, select source VMs, target = Azure Gov region, target RG `RG – Servers – Target`, target VNet `VNet – LandingZone – Target` / `snet-servers`. Create replication group `Replication Group – Servers – <Wave NN>`.
4. **Monitor** replication to 100% synchronized; keep deltas flowing.
5. **Test failover (mandatory):** run an **isolated** test failover into an isolated test subnet; confirm the VM **boots**, the OS is healthy, and apps start. Tear down the test VM. (See `05-testing.md` server gate.)
6. **Planned failover (cutover):** during the window, run a final sync then **planned failover**; commit; attach NICs/NSGs; update internal DNS to the new IPs.
7. **Re-trigger replication** for any failed item with `GCCHIGH-Remediation.ps1 -Mode RetriggerASR`.

**Named objects:** `Server Migration Project – IaaS – Target`, `Recovery Vault – ASR – Target`, `Replication Group – Servers – <Wave NN>`.

### WS-E — Azure apps / PaaS (redeploy / IaC)

1. PaaS is **redeployed**, not block-replicated. Export source IaC or generate it; parameterize for Gov endpoints.
2. **Deploy** into `RG – PaaS – Target` via Bicep/ARM/Terraform (point provider/cloud to **AzureUSGovernment**).
3. **Migrate data** inside PaaS separately: database export/import (e.g. Azure SQL bacpac), storage account copy (AzCopy to `*.blob.core.usgovcloudapi.net`), Key Vault secrets re-created in `KeyVault – AppSecrets – Target` (secrets are re-created, never exported in clear).
4. **Re-point configuration:** connection strings, app settings, and any endpoint URLs to `.us`/Gov equivalents.
5. **Re-create app registrations** in GCC High Entra (registrations and secrets do not migrate); update redirect URIs to `.us`.

**Named objects:** `RG – PaaS – Target`, `KeyVault – AppSecrets – Target`.

### WS-F — AVD / VDI (rebuild host pools in Azure Gov + FSLogix profile migration)

1. **Rebuild host pools natively** in Azure Gov — AVD is not lifted-and-shifted. At `https://portal.azure.us` → **Azure Virtual Desktop → Host pools → Create** `Host Pool – AVD – Target` in `RG – AVD – Target`, with `Workspace – AVD – Target` and `App Group – Desktop – Target`.
2. **Session hosts:** deploy session host VMs from the approved image into `snet-avd`; join to the GCC High identity (Entra-joined or to a Gov-hosted AD).
3. **FSLogix profiles:** provision the profile share `FSLogix Share – Profiles – Target` (Azure Files in Gov or a file server VM). **Migrate FSLogix profile containers** (`.vhdx`) from the source profile share via AzCopy/Robocopy; re-point the FSLogix `VHDLocations` GPO/registry to the target share.
4. **Assign users** from `All Migrated Users – Identity – Target` to `App Group – Desktop – Target`.
5. **Validate** a real user login loads the migrated profile (see `05-testing.md` AVD gate).

**Named objects:** `Host Pool – AVD – Target`, `Workspace – AVD – Target`, `App Group – Desktop – Target`, `FSLogix Share – Profiles – Target`.

---

## Phase 8 — Domain Cutover

**Goal:** point the organization's real domains at the GCC High tenant. Do this per the change window (R15); a domain can only be verified in one tenant at a time.

1. **Release the domain** from the commercial tenant (remove the domain after its users' mail is migrated, or coordinate a same-window release).
2. **Verify the domain** in the GCC High admin center → **Settings → Domains → Add domain** (add the verification TXT to public DNS, R11).
3. **Cut over DNS records** to the GCC High service values:
   - **MX** → GCC High mail routing (`*.mail.protection.office365.us`).
   - **Autodiscover** CNAME → `autodiscover.<region>.outlook.office365.us` equivalent.
   - **SPF/DKIM/DMARC** → re-publish for the GCC High tenant (enable DKIM in the Gov Defender/Exchange portal and publish the CNAMEs).
   - SharePoint/Teams vanity URLs as applicable.
4. **Lower TTLs** ahead of the window; confirm propagation with `nslookup`.

**Exit gate:** mail flows to the GCC High tenant; autodiscover resolves; SPF/DKIM/DMARC pass.

---

## Phase 9 — Validate (per workstream)

Run `scripts\GCCHIGH-Validation.ps1` and the manual gates in `05-testing.md` for each workstream/wave: mail flow, content parity, Teams functionality, server failover boot + app validation, AVD login + profile, identity/DNS. **No commercial resource is decommissioned until its target counterpart passes.** Track progress with `GCCHIGH-Report.ps1`.

**Exit gate:** all workstream acceptance gates PASS for the wave.

---

## Phase 10 — Decommission

**Goal:** retire the commercial estate under change control, only after validation.

1. **Confirm** all waves validated (`GCCHIGH-Report.ps1` shows 100% per workstream).
2. **Soft-retire first:** set commercial mailboxes/sites read-only; disable sign-in for migrated accounts; keep a defined **retention/grace period** for rollback.
3. **Data retention/compliance:** export any legal-hold/retention data per policy before deletion; retain CMMC/ITAR evidence.
4. **Tear down** commercial Azure resources (VMs, PaaS) after their Gov counterparts pass and the grace period elapses.
5. **Decommission the commercial tenant/licenses** last; reclaim/cancel commercial SKUs via the original channel.
6. **Document** the final state and archive the program register for assessment evidence.

**Exit gate:** commercial estate retired; evidence archived; program closed.
