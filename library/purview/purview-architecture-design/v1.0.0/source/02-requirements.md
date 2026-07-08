# 2. Requirements Guide — Microsoft Purview Architecture & Design

Verify **every** requirement before designing. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (tenant licensing, Purview roles, the
PowerShell/Graph toolchain, in-scope data sources, compliance/privacy/legal stakeholders, and a pilot
scope with change control) are in `global-requirements-purview.md` — this guide adds the
**architecture-and-design-specific** detail. **Licensing, capability availability, role-group names,
and portal paths are plan-dependent and the portal evolves — verify each against your own licensing
and tenant.**

## 2.1 Licensing baseline and the capabilities it gates
**Description:** Confirm the tenant's compliance licensing — **E3** (baseline: manual sensitivity/
retention labels, basic DLP, core audit) versus **Microsoft 365 E5 / E5 Compliance** (advanced DLP,
auto-labeling, trainable classifiers, insider risk, communication compliance, records management,
Audit Premium, DSPM, adaptive protection) and any **add-ons** — because the licensing is what
determines which capabilities can even appear on the capability map.
**Why:** Designing a phase around a capability the plan does not license is the most common Purview
planning failure. The capability map must tie each capability to the entitlement that enables it.
**Verify:** Microsoft 365 admin center → `Billing → Licenses` for the E5 / E5 Compliance / add-on SKUs;
in the Purview portal confirm the capability's node is visible (not "upgrade required").
`PURVARCH-Discovery.ps1` reports the subscribed SKUs it can read via Graph and maps them to an
**indicative** capability-availability list. **Confirm exact entitlement with Microsoft licensing — the
script's mapping is indicative, not authoritative.**
**Implement:** Record the licensing baseline; where a needed capability is unlicensed, mark it
**deferred (not licensed)** on the map rather than designing around it, or plan the license change.

## 2.2 Purview role groups readable, and the separation model agreed
**Description:** The current Purview / compliance **role groups** and their membership are readable, and
stakeholders agree the **separation-of-duties** intent — information protection, insider risk,
communication compliance, eDiscovery, records, and audit administered by **separate** people, with
Global Administrator and Compliance Administrator reserved.
**Why:** The RBAC model is the auditable access design; it can only be built from the current state and
an agreed separation intent. Retrofitting separation after everyone holds a broad role is expensive and
audit-visible.
**Verify:** Purview portal → `Settings → Roles & scopes → Permissions` (verify path — the unified
Purview RBAC surface is evolving) or, via `Connect-IPPSSession`, `Get-RoleGroup` / `Get-RoleGroupMember`.
`PURVARCH-Discovery.ps1` prints each role group's membership and `PURVARCH-Validation.ps1` flags
separation-of-duties conflicts (e.g. one person administering both insider risk and eDiscovery) as the
`PA RBAC SoD – Conflicts` register. **Verify the exact role-group names in your tenant — they evolve.**
**Implement:** Capture the current membership and the agreed separation model before applying the RBAC
design with `PURVARCH-Configuration.ps1` (`-WhatIf` first, then `-Commit`), granting the **minimum**
role each function needs.

## 2.3 In-scope capabilities and their phase decided (the capability map)
**Description:** The **set of Purview capabilities** in scope — from the phase model (Foundation → Know
→ Protect → Prevent loss → Govern → Advanced) — with each capability assigned a **phase**, an **owner**,
and a **status** (in scope / deferred — not licensed / out of scope), driven by the organization's
compliance obligations.
**Why:** The capability map is the unit of the whole design; without agreed scope and sequencing, the
RBAC model and roadmap have nothing to key off, and phases collide.
**Verify:** The capability list, phases, owners, and statuses are agreed with the governance owners and
each in-scope capability is confirmed licensable (Requirement 2.1). `PURVARCH-Discovery.ps1` /
`PURVARCH-Report.ps1` emit the `PA Capability Map – Tenant – Design` scaffold from what it can read.
**Implement:** Run the capability-scoping workshop, confirm licensing per capability, and record the map
and `PA Phase Roadmap – Program – Design` before designing RBAC and scoping.

## 2.4 Scoping strategy inputs — adaptive vs static, admin units, workloads
**Description:** The inputs to the scoping design: whether **adaptive scopes** (query-based: user, site,
or group membership) or **static scopes** are preferred per capability, whether **administrative units**
(Entra) are used to delegate scoped administration, the **workloads / data sources** in scope
(Exchange, SharePoint, OneDrive, Teams, endpoints/devices, and — for data governance — the broader data
estate), and the named **pilot ring** to validate on first.
**Why:** Scoping is what keeps a high-impact policy contained to a defined population until it is
validated. Adaptive scopes and admin units are architectural choices that every later policy inherits —
they must be designed, not improvised.
**Verify:** The preferred scope type per capability, admin-unit use, in-scope workloads, and the pilot
population are recorded (`PA Scoping Plan – Tenant – Design`). `PURVARCH-Discovery.ps1` inventories
existing adaptive scopes (`Get-AdaptiveScope`, where available) and reports readable workloads/managed
devices via Graph.
**Implement:** Decide scope type per capability and the pilot ring; scaffold the pilot group `SG-PA-Pilot`
and (where adaptive scopes are used) the example `AS-PA-Pilot` with `PURVARCH-Set-Scope.ps1` (`-WhatIf`
first). Adaptive-scope availability is licensing-gated — **verify in your tenant**.

## 2.5 Naming standard adopted
**Description:** A **naming standard** — the `<Purpose> – <Scope> – <Stage>` convention — adopted before
any capability policy/label/scope is created, with **`Sim`** for simulation/test and **`Prod`** for
enforced (e.g. `DLP-PII-Sim`, `Label-Confidential-Prod`, `AS-Finance-Prod`).
**Why:** Names are effectively immutable once dozens of policies reference them. A standard set up front
keeps the estate legible, searchable, and auditable as it scales across phases.
**Verify:** The standard is documented (`PA Naming Standard – Tenant – Design`) and agreed with the
capability owners; `PURVARCH-Validation.ps1` reports existing objects that do **not** conform so drift
is visible.
**Implement:** Adopt the standard and record it before Phase 0 completes; apply it to every object from
Phase 1 onward.

## 2.6 Compliance, records, privacy & legal owners (the determinations)
**Description:** Named owners in **compliance, records-management, privacy, security, and legal** who
make the determinations the architecture will carry — **regulatory applicability**, **retention
schedules**, **records file plans**, the **lawful basis** for insider-risk/communication monitoring —
and who own each capability domain in the RBAC model.
**Why:** The architecture is technical; the determinations it must satisfy are not. Several capabilities
(insider risk, communication compliance) are HR/privacy-sensitive and require role separation and a
lawful basis established **before** they are built.
**Verify:** The applicable frameworks, the named approvers per capability domain, and the privacy
sensitivities are recorded and reflected in the RBAC model and roadmap.
**Implement:** Engage the governance functions during the design workshop; capture the obligations and
the domain owners before finalizing the RBAC model and phase roadmap.

## 2.7 Security & Compliance PowerShell + Microsoft Graph toolchain
**Description:** A workstation with the **ExchangeOnlineManagement** module (providing
`Connect-IPPSSession` for role-group, policy, and adaptive-scope cmdlets) and **Microsoft Graph
PowerShell** (for licensing/SKU, administrative-unit, and workload/device signals), used with a
modern-auth / MFA-capable admin holding the appropriate read roles.
**Why:** The five provided scripts assess the estate, scaffold the RBAC and scope guardrails, validate
the design, and report — through Security & Compliance PowerShell and Graph. The architecture itself is
**portal-managed**; the scripts support it, they do not replace it.
**Verify:** `Connect-IPPSSession` and `Connect-MgGraph` succeed; `Get-RoleGroup` returns the compliance
role groups and `Get-MgSubscribedSku` returns the licensing. `PURVARCH-Discovery.ps1` performs these
checks.
**Implement:** `Install-Module ExchangeOnlineManagement`; `Install-Module Microsoft.Graph`; sign in with
the read-role-holding admin and consent the **read** scopes the scripts request.

## 2.8 A pilot ring and change control
**Description:** A named **pilot ring** (`SG-PA-Pilot`, a defined set of users/sites/groups) to validate
the foundation guardrails and every subsequent capability on **before** tenant-wide expansion, plus a
**change-control** path — consistent with `global-requirements-purview.md` §6 — recognizing that most
Purview policies support a **simulation / test / disabled** mode that MUST precede enforcement.
**Why:** Every phase and every capability follows **Assess → Design → Configure → Pilot (simulate) →
Validate → Expand**; the pilot ring is the mechanism that makes "pilot" a defined population rather than
a hope. DLP, labels, retention, and insider-risk changes are high-impact.
**Verify:** A named pilot ring and its owner exist; a change window/approval path is defined; the
scoping plan references the ring.
**Implement:** Define the pilot ring and scaffold `SG-PA-Pilot` (`PURVARCH-Set-Scope.ps1 -WhatIf` first),
agree change control, and validate the foundation on the ring before executing Phase 1.
