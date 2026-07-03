# GCC High Parity Notes — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

This reference maps the **Commercial (Worldwide)** version of this solution to the **Microsoft 365 GCC High** (US Government L4) sovereign cloud. Every item is either **cited** to Microsoft's US Government documentation or explicitly flagged **"verify for GCC High"** where Microsoft has not published a definitive, current statement. Nothing here is invented — where the sovereign-cloud behavior is not authoritatively documented, that is stated plainly.

> **GCC High is not "Commercial with a different sign-in."** The sovereign cloud uses different admin portal URLs, different service and identity endpoints, and some capabilities lag, are limited, or are absent versus Commercial. Steps copied verbatim from a Commercial runbook can silently fail or connect to the wrong cloud.

---

## 1. The headline caveat — cross-cloud native migration is NOT supported

**Native (Microsoft-provided) cross-tenant mailbox migration cannot move mail across cloud boundaries.** Microsoft states this explicitly:

> "Cross cloud tenant to tenant migration isn't supported. An example scenario would be moving from Office 365 Worldwide to Office 365 Government Cloud."
> — Microsoft Learn, *Cross-tenant mailbox migration* (`learn.microsoft.com/microsoft-365/enterprise/cross-tenant-mailbox-migration`)

Consequences:

| Migration direction | Native cross-tenant mailbox move? | Path |
|---|---|---|
| Commercial → GCC High | **Not supported** (cross-cloud) | Third-party tool or PST |
| GCC High → Commercial | **Not supported** (cross-cloud) | Third-party tool or PST |
| GCC High → GCC High (same cloud) | **Public Preview** — verify tenant eligibility | Native (preview) or third-party tool |
| DoD → DoD (same cloud) | **Public Preview** — verify tenant eligibility | Native (preview) or third-party tool |
| Commercial → Commercial | Generally available | Native |

- Microsoft maintains a **Public Preview** of native cross-tenant mailbox migration (`https://aka.ms/CrossTenantMailboxMigration`, cited on Microsoft Learn *migrate-mailboxes-across-tenants*). Public reporting and vendor documentation indicate the native capability reaches GCC High / DoD **later than Commercial and via preview**; **treat native same-cloud GCC High↔GCC High migration as preview-gated and confirm current availability with Microsoft support / your account team before relying on it. (verify for GCC High.)**
- Because of the above, this solution is authored **tool-agnostic**: it prepares both tenants (identity, licensing, endpoints, DNS, validation) so that **either** a supported native same-cloud move **or** a third-party migration tool (Quest On Demand, BitTitan MigrationWiz, CloudM, Cloudiway, etc. — all of which document GCC High support paths) **or** a PST-based move can execute the mailbox data transfer. **Third-party tool internals are deferred to that vendor's own GCC High documentation.**

---

## 2. Admin portal URL map (Commercial → GCC High)

All portal navigation in the Implementation Guide uses the **GCC High** URLs below. Source: Microsoft Learn *Microsoft 365 U.S. Government GCC High endpoints* (`learn.microsoft.com/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints`) and Microsoft US Government portal references.

| Purpose | Commercial | **GCC High** |
|---|---|---|
| Microsoft 365 admin center | admin.microsoft.com | **portal.office365.us** (Microsoft 365 admin center) |
| Exchange admin center (EAC) | admin.exchange.microsoft.com | **admin.exchange.office365.us** |
| Microsoft Entra admin center | entra.microsoft.com | **entra.microsoft.us** |
| Azure portal | portal.azure.com | **portal.azure.us** |
| Microsoft Defender portal | security.microsoft.com | **security.microsoft.us** |
| Microsoft Purview / compliance | purview.microsoft.com / compliance.microsoft.com | **compliance.microsoft.us** |
| Teams admin center | admin.teams.microsoft.com | **admin.gov.teams.microsoft.us** |
| SharePoint / OneDrive admin | *tenant*-admin.sharepoint.com | **admin.onedrive.us** (and *tenant*-admin.sharepoint.us) |

> **verify for GCC High:** Microsoft occasionally renames or consolidates portals (e.g., the Purview rebrand). Confirm the live URL from the Microsoft 365 U.S. Government endpoints article before each engagement.

---

## 3. Identity & service endpoints (for scripts and firewall allow-listing)

Source: Microsoft Graph *national cloud deployments* (`learn.microsoft.com/graph/deployments`) and Microsoft Learn *Connect to Exchange Online PowerShell*.

| Endpoint | Commercial | **GCC High (US Gov L4)** |
|---|---|---|
| Microsoft Entra ID / login authority | login.microsoftonline.com | **login.microsoftonline.us** |
| Microsoft Graph service root | graph.microsoft.com | **graph.microsoft.us** |
| Exchange Online PowerShell ConnectionUri | outlook.office365.com/powershell-liveID | **outlook.office365.us/powershell-liveID** |
| Azure AD Authorization endpoint (EXO) | login.microsoftonline.com/organizations | **login.microsoftonline.us/organizations** |

Module connection parameters used by every script in this solution:

- **Microsoft Graph PowerShell:** `Connect-MgGraph -Environment USGov` (do **not** omit `-Environment`; without it the SDK authenticates against the Commercial cloud and fails for a GCC High tenant).
- **Exchange Online PowerShell:** `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` (this selects the `outlook.office365.us` connection and `login.microsoftonline.us/organizations` authority automatically; you do **not** also pass `-ConnectionUri`/`-AzureADAuthorizationEndpointUri` when using `-ExchangeEnvironmentName`).

> DoD (L5) equivalents differ (`dod-graph.microsoft.us`, `-ExchangeEnvironmentName O365USGovDoD`). This solution targets **GCC High (L4)**; a DoD engagement must swap these values. (Cited: Microsoft Graph deployments; Connect-ExchangeOnline reference.)

---

## 4. Licensing parity

- The **Cross-Tenant User Data Migration** per-user add-on license is **required** for a native cross-tenant mailbox move and is enforced — "Migrations fail if this step isn't completed. Microsoft doesn't offer exceptions for this licensing requirement." (Cited: Microsoft Learn *Cross-tenant mailbox migration*.)
- In GCC High, base mailbox licensing is via **US Government plans** (e.g., **Office 365 G1/G3/G5 GCC High**, **Microsoft 365 G3/G5 GCC High**), purchased through an **authorized US Government cloud reseller/AOS-G partner**, not the Commercial storefront.
- **verify for GCC High:** Confirm the Cross-Tenant User Data Migration add-on is orderable on your GCC High agreement **before** committing to a native same-cloud move. If it is not available for your contract vehicle, plan on a **third-party tool or PST** path (which does not require this add-on). Do not assume Commercial add-on availability carries over.

---

## 5. Admin roles parity

Roles are the same *names* as Commercial but are assigned in the **GCC High** portals (`entra.microsoft.us`, `admin.exchange.office365.us`):

- **Organization Management / Organization Administrator (Exchange)** — one-time setup of the cross-tenant `OrganizationRelationship` and its `-MailboxMoveCapability`. "Only the organization administrator can alter the `-MailboxMoveCapability` setting." (Cited: Microsoft Learn *Cross-tenant mailbox migration*.)
- **Move Mailboxes** management role — executing the actual `New-MigrationBatch` / `New-MoveRequest` moves; can be delegated to a lower-privilege operator. (Cited: same.)
- **Global Administrator** (Entra) — consenting the migration application and cross-tenant configuration in each tenant.

---

## 6. Feature-parity gaps to expect (general GCC High posture)

These are general, documented GCC High characteristics that affect a migration project. Where a specific behavior is not authoritatively published, it is flagged.

- **Feature lag / absence:** Microsoft states that "certain services and features that are in specific regions of the global service might not be available in all national clouds." (Cited: Microsoft Graph *national cloud deployments*.) Newer migration conveniences (e.g., **Cross-Tenant Identity Mapping**, itself a Commercial preview) should be assumed **unavailable in GCC High until Microsoft documents otherwise. (verify for GCC High.)**
- **No Graph Explorer:** the interactive Graph Explorer tool is "Not supported" for GCC High — validate Graph calls with PowerShell, not the web explorer. (Cited: Microsoft Graph *national cloud deployments*.)
- **Guest / B2B collaboration** across sovereign boundaries is constrained; cross-cloud B2B differs from Commercial. Any cross-tenant trust used by a native move must be within the **same** cloud. (verify for GCC High for your specific B2B configuration.)
- **Endpoint allow-listing:** GCC High publishes a **separate** "Office 365 U.S. Government GCC High endpoints" list from the Commercial "Office 365 URLs and IP address ranges." Firewalls must allow the **`.us`** endpoints. (Cited: Microsoft Learn GCC High endpoints article.)
- **Third-party tool onboarding differs:** migration vendors require you to register their app against **login.microsoftonline.us** and select their **GCC High / US Gov** service instance, not the Commercial one. Follow the vendor's GCC High guide. (Deferred to vendor docs.)

---

## 7. What is identical to Commercial

To keep scope honest — these do **not** change between Commercial and GCC High:

- The **overall migration method and sequence** (assess → prepare identity/licensing → prepare DNS → pilot → validate → expand → cutover) is the same.
- Exchange **object model** (MailUser, ExchangeGUID, proxy addresses, `Set-User -PermanentlyClearPreviousMailboxInfo`) and the licensing/scrubbing behavior are the same.
- Cmdlet **names** (`New-MigrationBatch`, `New-MoveRequest`, `Get-Mailbox`, `Get-MgUser`) are identical; only the **connection endpoints** differ.

---

## Sources

- Microsoft Learn — *Cross-tenant mailbox migration*: `https://learn.microsoft.com/en-us/microsoft-365/enterprise/cross-tenant-mailbox-migration` (cross-cloud not supported; licensing; roles).
- Microsoft Learn — *How to migrate mailboxes from one Microsoft 365 or Office 365 organization to another*: `https://learn.microsoft.com/en-us/exchange/mailbox-migration/migrate-mailboxes-across-tenants` (native cross-tenant Public Preview; third-party/PST method; GCC High `Connect-ExchangeOnline` note).
- Microsoft Learn — *Microsoft Graph national cloud deployments*: `https://learn.microsoft.com/en-us/graph/deployments` (graph.microsoft.us, login.microsoftonline.us, feature availability, no Graph Explorer).
- Microsoft Learn — *Connect to Exchange Online PowerShell*: `https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-online-powershell` (`-ExchangeEnvironmentName O365USGovGCCHigh`, `outlook.office365.us/powershell-liveID`, `login.microsoftonline.us/organizations`).
- Microsoft Learn — *Microsoft 365 U.S. Government GCC High endpoints*: `https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints` (portal URLs and endpoint allow-listing).
