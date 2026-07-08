# 2. Requirements Guide — Snowflake Data Governance (Microsoft Purview)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-purview.md` (the six
shared requirements: compliance licensing, least-privilege Purview roles, the S&C PowerShell + Graph
toolchain, in-scope data sources, compliance/records/privacy/legal stakeholders, and a pilot scope with
change control) — those are referenced here, not repeated.

## 2.1 A Microsoft Purview account with Data Governance (Data Map/Catalog) enabled
**Description:** A **Microsoft Purview account** with the **Data Map / Data Catalog (Data Governance)**
capability, and the associated **consumption/capacity** model understood — this is distinct from the M365
E5 compliance licensing used by DLP/labels. (Global Requirement 1.)
**Why:** Registering, scanning, and cataloging Snowflake happens in the Purview Data Map, which has its own
account/consumption model.
**Verify:** In the Purview portal confirm the Data Map / catalog experience is available;
`DGSNOW-Check-Prereqs.ps1` reports the Purview-account signal. **Verify the current licensing/consumption
model and connector support for your account** — the Data Governance experience is evolving.
**Implement:** Provision/enable the Purview account and its Data Governance capability; confirm the pricing
model with the owner before running scans (scans consume capacity).

## 2.2 Least-privilege Purview data-governance roles
**Description:** Least-privilege **Data Map / catalog roles** — **Collection admin** (to manage the
collection), **Data source admin** (to register sources and manage scans), and **Data curator** (to
curate assets/classifications) — scoped to `Snowflake – Collection`. Reserve broad roles for one-time
setup. (Global Requirement 2.)
**Why:** The Data Map uses collection-scoped roles distinct from the compliance roles; registration/scan
requires Data source admin, curation requires Data curator.
**Verify:** In the Purview portal → the collection → **Role assignments** confirm the roles;
`DGSNOW-Check-Prereqs.ps1` reports whether the signed-in identity can read the Data Map.
**Implement:** Assign the least-privilege collection roles under change control before configuring.

## 2.3 Azure/Purview PowerShell + REST toolchain
**Description:** A workstation with **Az.Accounts** (and, where used, **Az.Purview**) for authenticating to
Azure/Purview and calling the **Purview Data Map REST API** (`Invoke-RestMethod` with a bearer token from
`Get-AzAccessToken`), with a modern-auth / MFA admin. (Global Requirement 3.)
**Why:** Data Map registration/scan operations are driven through the Purview REST API and Az modules; the
provided scripts use them read-only or with `-WhatIf` gating.
**Verify:** `Get-Module -ListAvailable Az.Accounts`; `Connect-AzAccount` succeeds and a token for the
Purview endpoint can be acquired. `DGSNOW-Check-Prereqs.ps1` reports module/connection state.
**Implement:** `Install-Module Az.Accounts -Scope CurrentUser` (add `Az.Purview` if used); confirm
modern-auth sign-in before running steps.

## 2.4 Network path to Snowflake and integration runtime
**Description:** A working **network path** from the scanning runtime to the Snowflake account, and — where
Snowflake is not reachable from the Purview managed runtime — a **self-hosted integration runtime (SHIR)**
installed and registered to the Purview account. (Global Requirement 4.)
**Why:** The scan connects to Snowflake to read metadata; if the network requires it, a SHIR provides the
reachable, secure connection.
**Verify:** Confirm the runtime can reach the Snowflake host/port; `DGSNOW-Discover.ps1` reports registered
integration runtimes. **Verify the current Snowflake connector's runtime requirements against Microsoft's
docs.**
**Implement:** Install/register a SHIR on a host with Snowflake connectivity where the managed runtime
can't reach it; open the required network path under change control.

## 2.5 A Snowflake scanning credential stored in Azure Key Vault (no secrets in code)
**Description:** A **Snowflake login** (user/role with least-privilege read access to the in-scope
databases' metadata) whose **secret is stored in Azure Key Vault**, with the Key Vault **linked to the
Purview account** and the credential referenced by the scan — **never** a secret in a script or document.
(Global Requirement 3 — no hardcoded secrets.)
**Why:** The scan authenticates to Snowflake; Purview reads the secret from Key Vault at scan time so no
credential is embedded anywhere.
**Verify:** The Snowflake login exists with least-privilege read; the Key Vault holds the secret and is
linked in the Purview account (Management → Credentials / Key Vault); `DGSNOW-Check-Prereqs.ps1` reminds
you to confirm the Key Vault linkage.
**Implement:** Create the least-privilege Snowflake login, store its secret in Key Vault, link the Key
Vault to Purview, and create the Purview credential referencing it — before creating the scan.

## 2.6 The in-scope Snowflake databases and a pilot scope
**Description:** The **Snowflake databases/schemas in scope** for cataloging, and a **pilot scope**
(`Snowflake – Pilot Scope – Stage1`: one database/schema) to validate on before scanning the account.
(Global Requirements 4 & 6.)
**Why:** Scans key off scope; a first full-account scan is expensive and surfaces more findings than you
can curate. Prove on a bounded pilot first.
**Verify:** The in-scope databases and the pilot scope are agreed with the data-governance/Snowflake
owners; `DGSNOW-Discover.ps1` reports existing sources/scans.
**Implement:** Enumerate the in-scope databases and define the pilot scope before creating the scan.

## 2.7 Classification scheme, data owners, and stakeholders (governance owned)
**Description:** The **classifications / sensitive information types** to apply (built-in + custom), the
**data owners/stewards** and **glossary** approach, and engagement with **data-governance, compliance, and
privacy** stakeholders. (Global Requirements 4 & 5.)
**Why:** The scan rule set applies classifications; which classifications matter, who owns the data, and
the glossary are **determinations** owned by data-governance, not technical defaults.
**Verify:** The classification scheme and ownership approach are documented and approved; named stewards
recorded in `Snowflake Governance – Map`.
**Implement:** Confirm the classification scheme and ownership before curating; where incomplete, scan with
the default rule set and defer curation determinations to the owners.

---
## Checklist
- [ ] Microsoft Purview account with Data Governance (Data Map/Catalog) available; consumption model confirmed
- [ ] Least-privilege collection roles (Collection admin / Data source admin / Data curator) on `Snowflake – Collection`
- [ ] Az.Accounts (+ Az.Purview where used) installed; `Connect-AzAccount` + Purview token succeed
- [ ] Network path to Snowflake confirmed; SHIR installed/registered where required
- [ ] Least-privilege Snowflake login; secret in **Azure Key Vault** linked to Purview (no secrets in code)
- [ ] In-scope Snowflake databases enumerated; `Snowflake – Pilot Scope – Stage1` (one db/schema) defined
- [ ] Classification scheme + data owners/glossary approach agreed; stewards named
