# Requirements Guide — Egress Filtering for M365/Intune Endpoints (Government / GCC High)

These are the prerequisites specific to **this** solution. They sit **on top of** the category-level
**Global Requirements — Network** (`global-requirements-network.md`); confirm those first. Each entry
below gives **Description · Why · Verify · Implement-if-missing**, written for the **GCC High** cloud.

> **Sovereign-cloud reminder:** every portal and service URL in this edition is the **`*.us` /
> `*.microsoft.us`** sovereign endpoint. If a Verify step sends you to a `.com` portal, you are in the
> wrong cloud. Where GCC High parity could not be confirmed, the step is flagged **"verify for GCC
> High."**

## R1. A confirmed GCC High tenant (not GCC / not Commercial)

**Description:** Your Microsoft 365 tenant is a **US Government GCC High** tenant.
**Why:** GCC High has its **own published endpoint set** (`USGovGCCHigh` instance) and its own portal
URLs. GCC (moderate) uses the **Worldwide** instance; Commercial uses **Worldwide**. Getting this
wrong means you allow-list the wrong cloud.
**Verify:** Sign in at **`https://portal.office365.us`** and **`https://portal.azure.us`**. In the
Microsoft Intune admin center **`https://intune.microsoft.us`**, confirm the portal loads under the
`.us` domain. Your sign-in should redirect through **`login.microsoftonline.us`**.
**Implement:** If you sign in at `.com` portals, you are **not** on GCC High — stop and confirm your
tenant type with your licensing/onboarding contact before proceeding. Do not apply this solution to a
Commercial tenant.

## R2. US Government licensing (G3/G5 Gov or equivalent)

**Description:** Microsoft 365 US Government plans (e.g. **G3/G5 Government**) with Intune and, for the
Defender steps, Microsoft Defender for Endpoint for US Government.
**Why:** The service areas you allow-list (Exchange, SharePoint, Teams, Common, Intune, Defender) must
actually be licensed and provisioned in your tenant.
**Verify:** `https://portal.office365.us` → **Billing → Licenses**; confirm Gov SKUs are assigned.
Confirm Intune is provisioned at `https://intune.microsoft.us`.
**Implement:** Assign the appropriate US Government license plans to users/devices in scope.

## R3. Administrative roles in the sovereign portals

**Description:** Least-privilege admin roles to read tenant configuration and (for remediation)
configure the egress device.
**Why:** Discovery and validation are read-only, but building the allow-list requires rights on your
firewall/SWG, and scoping requires Entra group management.
**Verify:** Confirm you can open `https://intune.microsoft.us`, `https://security.microsoft.us`, and
`https://entra.microsoft.com` (Entra portal is shared) with at least reader access, and that you have
admin rights on the egress device.
**Implement:** Assign least-privilege roles (e.g. **Global Reader** for discovery; the specific
network-device role for allow-list changes). Reserve Global Administrator for tenant-wide changes only.

## R4. Access to the GCC High endpoints web service

**Description:** The machine that runs the scripts must be able to reach
**`https://endpoints.office.com`** and query the **`USGOVGCCHigh`** instance.
**Why:** The entire required set is **derived** from this web service. No hardcoded Microsoft IPs are
used anywhere in this solution.
**Verify:** From the script host, in a browser or PowerShell, open
`https://endpoints.office.com/version/USGOVGCCHigh?clientrequestid=<generate-a-guid>` and confirm a
JSON version record for instance `USGOVGCCHigh` is returned. (Generate your own GUID — see
`03-implementation.md`; do not reuse example GUIDs.)
**Implement:** Allow `endpoints.office.com` outbound (TCP 443) from the script host. This host is
typically a management/jump box, **not** a filtered user endpoint.

## R5. PowerShell 5.1+ and the Microsoft Graph module (USGov environment)

**Description:** Windows PowerShell 5.1 or PowerShell 7+, plus the **Microsoft.Graph** module for the
scope-targeting script.
**Why:** Scripts call the web service via `Invoke-RestMethod` and (for Set-ScopeTargeting) manage the
pilot group via Graph using **`-Environment USGov`**.
**Verify:** `$PSVersionTable.PSVersion` shows 5.1+; `Get-Module Microsoft.Graph -ListAvailable`
returns the module; `Connect-MgGraph -Environment USGov` connects to the Gov endpoint.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`. Always pass **`-Environment
USGov`** — the default targets Commercial Graph and will fail on a GCC High tenant.

## R6. An egress device you can allow-list on (firewall / SWG / proxy / SASE)

**Description:** The filtering device or service that controls outbound traffic (Netskope SWG per the
Network category, or a firewall/proxy) with the ability to create **address groups**, **URL
categories**, and **SSL-inspection bypass** rules.
**Why:** The derived set is only useful if you can express it as named objects on the device.
**Verify:** Confirm you can create an address object/group and a URL category, and that you can add
FQDNs to an SSL-inspection **bypass** list.
**Implement:** If your device cannot bypass SSL inspection per-FQDN, treat that as a blocker for the
**no-inspect** endpoints below (Microsoft does **not** support inspecting them).

## R7. Endpoints that must NOT be SSL-inspected (GCC High)

**Description:** Microsoft explicitly states SSL/TLS inspection is **not supported** on certain Gov
endpoints; these must be on an inspection **bypass** list.
**Why:** Inspecting them breaks Intune check-in, Defender/EPM device management, and enrollment.
**Verify:** Confirm your bypass list includes at least the following Microsoft-documented Gov
no-inspect endpoints:

- `*.manage.microsoft.us` (Intune) — SSL inspection **not supported**.
- `has.spserv.microsoft.com` — SSL inspection **not supported**.
- `*.dm.microsoft.us` (Defender for Endpoint **and** Endpoint Privilege Management device channel) —
  SSL inspection **not supported**.

**Implement:** Add these to `EGRESSG-NoInspect-GCCHigh` before enabling inspection anywhere near M365
traffic. (Cited — see `gcc-high-parity-notes.md`.)

## R8. GCC High service/portal FQDNs to allow (the fixed facts)

**Description:** The published Gov portal and partner-service FQDNs that identity, Intune, and Defender
depend on. Unlike Microsoft's rotating IP ranges, these FQDNs are **stable and documented**, so they
are safe to reference by name.
**Why:** Even a perfect IP allow-list fails if these named endpoints are blocked or misrouted.
**Verify:** Confirm the following resolve and are allowed outbound (TCP 443, and 80 where noted):

- **Identity:** `login.microsoftonline.us`, `*.auth.microsoft.us`, `*.gov.us.microsoftonline.com`
- **Intune service/portals:** `*.manage.microsoft.us`, `portal.manage.microsoft.us`,
  `intune.microsoft.us`, `enterpriseregistration.microsoftonline.us`
- **Graph:** `graph.microsoft.us`, `graph.microsoftazure.us`, `directory.microsoftazure.us`
- **Defender / security / compliance:** `*.security.microsoft.us`, `security.microsoft.us`,
  `compliance.microsoft.us`, `purview.microsoft.us`, `*.dm.microsoft.us`
- **Core workloads:** `outlook.office365.us`, `*.sharepoint.us`, `*.gov.teams.microsoft.us`,
  `*.gov.online.office365.us`, `www.office365.us`
- **Unified domains:** `*.usgovcloud.microsoft`, `*.usgovcloud-static.microsoft`,
  `*.usgovcloud-usercontent.microsoft`

**Implement:** Add any missing FQDNs to `EGRESSG-M365-GCCHigh-URLs`. Ports and the authoritative,
current list are **derived** by the Discovery script from the `USGovGCCHigh` instance — this list is
the human-readable cross-check, not a substitute for the derived data. (Cited — see
`gcc-high-parity-notes.md`.)

## R9. A pilot group and rollback path (from Global Requirements)

**Description:** An Entra security group `EGRESSG-Pilot` and a documented rollback (revert the
allow-list / disable inspection changes).
**Why:** Egress changes affect live traffic; every rollout is piloted and reversible (Global
Requirements **G6**, **G7**).
**Verify:** `EGRESSG-Pilot` exists in Entra Groups; a written rollback is approved.
**Implement:** Create the group (`Set-ScopeTargeting` can create/populate it) and write the rollback
before enabling enforcement.

---

**Requirement gate:** Do not proceed to Implementation until R1 (confirmed GCC High), R4 (web-service
reachable, `USGOVGCCHigh` returns a version), and R7 (no-inspect list understood) all pass.
