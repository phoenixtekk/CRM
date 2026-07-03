# Solution Overview — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains) — Government (GCC High)

This is the **Government (GCC High)** edition of the Exchange Online tenant-to-tenant migration solution. It moves Exchange Online mailboxes and the primary email domain from one Microsoft 365 organization to another **within the US sovereign cloud**, using the correct **`*.us` admin portals and endpoints**, with every Commercial-vs-GCC-High difference called out at the point it matters.

If you are running the Commercial edition steps against a GCC High tenant, some of them **silently connect to the wrong cloud or fail outright**. This edition fixes that.

---

## Read this first — the cross-cloud caveat (do not skip)

> **Native (Microsoft-built) cross-tenant mailbox migration cannot cross cloud boundaries.** Microsoft states plainly: *"Cross cloud tenant to tenant migration isn't supported. An example scenario would be moving from Office 365 Worldwide to Office 365 Government Cloud."* (Microsoft Learn, *Cross-tenant mailbox migration*.)

What this means for your project **before you plan anything**:

- **Commercial ↔ GCC High** (either direction): the native cross-tenant mailbox move is **not available**. You must use a **third-party migration tool** (Quest On Demand, BitTitan MigrationWiz, CloudM, Cloudiway, etc.) or a **PST export/import** for the actual mail data.
- **GCC High → GCC High** (both tenants in the same sovereign cloud): Microsoft's **native** cross-tenant mailbox migration exists but reaches government clouds via **Public Preview** and **later than Commercial** — **confirm current eligibility with Microsoft / your account team before relying on it.** (verify for GCC High.) A third-party tool remains a fully supported alternative.
- This solution is therefore authored **tool-agnostic**: it prepares *both* tenants correctly so that **whichever** mail-transfer engine you use — supported native same-cloud move, a third-party tool, or PST — will succeed. **The internals of any third-party migration tool are deferred to that vendor's own GCC High documentation.**

The full support matrix, endpoints, and licensing detail live in **`gcc-high-parity-notes.md`** (all cited).

---

## What this solution delivers

A repeatable, novice-admin-friendly, click-to-implement runbook to:

1. **Assess** both the source and target GCC High tenants (mailbox inventory, licensing, DNS, endpoints, readiness gates) using read-only PowerShell against the **US Gov Graph and EXO endpoints**.
2. **Configure** identity, licensing, admin roles, endpoint allow-listing, and (for a supported native same-cloud move) the cross-tenant `OrganizationRelationship` — all in the **GCC High portals**.
3. **Pilot** a small named batch of mailboxes and prove the method end-to-end before scaling.
4. **Validate** mail flow, mailbox content, permissions, and the DNS/MX cutover with explicit pass/fail gates.
5. **Expand** to the full population in controlled waves, then cut over the primary domain.

Every step names the object it creates or reuses (a pilot group, a migration batch, an org relationship) so later steps build on earlier ones rather than starting over.

---

## The deployment model (Assess → Configure → Pilot → Validate → Expand, with gates)

| Phase | Goal | Exit gate (must pass before next phase) |
|---|---|---|
| **Assess** | Know both tenants: what mailboxes, what licenses, what DNS, what endpoints, what blockers | Discovery report clean; readiness checklist all green or waived in writing |
| **Configure** | Identity, licensing, roles, endpoints, and (if native) org relationship in place | Validation script passes on both tenants; migration engine can authenticate |
| **Pilot** | Move a small named batch and prove the method | Pilot mailboxes fully validated; no unresolved errors |
| **Validate** | Confirm content, mail flow, permissions, and cutover mechanics | All validation checks green; rollback rehearsed |
| **Expand** | Move remaining mailboxes in waves; cut over primary domain | Each wave validated; final MX/Autodiscover cutover confirmed |

Gates are **hard stops**. Do not begin Configure until Assess is clean; do not Expand until the Pilot is validated.

---

## Commercial vs GCC High — what's different

A concise orientation; the fully cited detail is in `gcc-high-parity-notes.md`.

1. **Cross-cloud native migration is unsupported** (see the caveat above). This is the single biggest planning difference — a Commercial↔GCC High move **cannot** use the native cross-tenant feature at all, and same-cloud GCC High native moves are **preview-gated**.
2. **Different admin portals.** You administer in **`portal.office365.us`** (M365 admin), **`admin.exchange.office365.us`** (Exchange), **`entra.microsoft.us`** (Entra), **`security.microsoft.us`**, **`compliance.microsoft.us`**, **`portal.azure.us`** — never the Commercial `admin.microsoft.com` / `entra.microsoft.com`.
3. **Different endpoints for tooling.** Graph is **`graph.microsoft.us`** (`Connect-MgGraph -Environment USGov`); Exchange Online PowerShell is **`outlook.office365.us`** (`Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh`); the login authority is **`login.microsoftonline.us`**. Omitting these makes tools authenticate against Commercial and fail.
4. **Different licensing channel.** Base mailbox licenses are **US Government plans (G3/G5 GCC High)** bought through an **authorized US Gov reseller / AOS-G partner**; the **Cross-Tenant User Data Migration** add-on availability on your Gov agreement must be **verified** before relying on a native move. (verify for GCC High.)
5. **Feature lag / gaps.** Some Commercial conveniences (e.g., Cross-Tenant Identity Mapping, Graph Explorer) are **not available** in GCC High. Assume newer features are absent until Microsoft documents them for US Gov. (verify for GCC High.)
6. **Separate firewall allow-list.** GCC High publishes its **own** endpoint list; you must allow the **`.us`** URLs/IPs, not the Commercial ranges.

**What is the same:** the migration *method and sequence*, the Exchange object model (MailUser/ExchangeGUID/proxy scrubbing), and the cmdlet *names*. Only the *endpoints, portals, licensing channel, and cross-cloud support* change.

---

## What's inside this solution

- **This Solution Overview** and the cited **GCC High Parity Notes**.
- **Requirements Guide** (`02-requirements.md`) — every prerequisite with verify/implement steps, GCC High-specific.
- **Implementation Guide** (`03-implementation.md`) — ordered GCC High steps with inline caveats.
- **Testing** (`05-testing.md`) and **Troubleshooting** (`06-troubleshooting.md`) with pass/fail gates and GCC High gotchas.
- **Best Practices** (`07-best-practices.md`) and **Deliverables Summary** (`08-deliverables-summary.md`).
- **5 PowerShell scripts** — Discovery, Validation, Report (read-only), and Remediation + Set-ScopeTargeting (default `-WhatIf`) — all connecting to **US Gov Graph / EXO** endpoints.

---

## Who this is for

Government tenant administrators, MSPs serving the Defense Industrial Base, and IT teams performing a 1:1-domain Exchange Online consolidation **within GCC High** — who need the sovereign-cloud-correct steps rather than Commercial steps that fail quietly.
