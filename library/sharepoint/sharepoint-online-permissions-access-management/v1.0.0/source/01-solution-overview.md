# 1. Solution Overview — SharePoint Online Permissions & Access Management

## What this solution is
SharePoint permissions rot. What starts as a clean, inheriting site collection turns — over months of
"just give Jane access to this one folder" — into a tangle of **broken inheritance**, thousands of
**unique permissions**, **direct user grants** nobody can trace, and sites shared so widely that no one
can answer "who can see this?". This solution establishes a durable **permissions and access model** for
SharePoint Online and remediates the existing mess: it standardizes on **group-based access** (SharePoint
groups and Entra ID / Microsoft 365 groups instead of direct user grants), defines a **standard
permission-level model**, **controls unique permissions and broken inheritance** (resetting them to
inherit where they should, keeping them only where genuinely required), stands up **site-access reviews**,
and delivers **access reporting** so who-can-see-what is intentional and auditable.

The work is done through the **SharePoint admin center**, the **Microsoft 365 admin center**, the
**Microsoft Entra admin center** (for M365/Entra groups and Access Reviews), and **PowerShell** — the
**SharePoint Online Management Shell**, **PnP PowerShell**, and **Microsoft Graph** — with everything
**pilot-first** and safe-by-default.

## Scope — what this is, and what it deliberately is NOT
This solution is **scoped to the SharePoint Online permissions and access model**: SharePoint groups vs
Entra/M365 groups, standard permission levels, inheritance vs unique permissions, **Limited Access**
sprawl, direct-grant remediation, site-access reviews, and access reporting.

It is **not**:
- **External / guest sharing governance** — anonymous "Anyone" links, guest access, and tenant/site
  sharing controls are a **separate concern covered by a different product**. This solution governs the
  *internal* permission model (who inside the org has what level, via which group); it references the
  sharing boundary but does not configure external-sharing policy.
- **Information architecture / site provisioning** — the hub/site structure and the *provisioning*
  templates that create sites with the right groups are a separate product. This solution assumes the IA
  exists (see Requirements) and governs permissions *within* it.
- **Records, retention, or sensitivity labels** — Purview retention/records and sensitivity labels are a
  separate data-governance concern. Permissions control *access*; labels/retention control *lifecycle*.
- **A compliance or legal determination.** Which business roles *should* have access to which content is
  an information-owner/compliance decision. This solution provides the **technical model, the remediation
  method, and the evidence** (audit + reports); the org's information owners decide who belongs in each
  group.

## Why this matters
- **Unauditable access is a risk and an audit finding.** When access is granted directly to individual
  users on individual items, there is no single place to answer "who can see the board deck?" Group-based
  access makes access legible: membership of a named group *is* the answer.
- **Broken inheritance is unmaintainable.** Every place inheritance is broken becomes a permission
  boundary that must be maintained by hand forever. Thousands of them across a tenant means access drifts,
  removals get missed, and offboarded users retain access on scoped items.
- **Limited Access sprawl hides real exposure.** Granting a user access to one document silently gives
  them **Limited Access** at the parent list and site — a real permission level SharePoint adds
  automatically. Enough of these and the site's permissions page becomes noise, masking who actually has
  meaningful access.
- **Direct grants outlive people and roles.** A user added directly to a site stays there after they
  change teams; a user added to the **`SPO Group – Finance Members – Prod`** group is removed the moment
  they leave the group. Group-based access is self-cleaning; direct grants are not.

## How it works
1. **Assess first (read-only).** Run the discovery audit across the in-scope sites to inventory
   **broken inheritance**, **unique permissions**, **direct user grants**, **Limited Access** entries,
   and **over-shared** scopes (e.g. "Everyone except external users" on a whole site). This produces the
   evidence baseline **`Permission Audit – SPO – Discovery`** — no changes are made.
2. **Design the model.** Define the **`Access Model – SPO – Design`**: which **SharePoint groups** and
   **Entra/M365 groups** back each site, the **standard permission-level model** (below), and the rule
   for when unique permissions are *allowed* (rare, documented, owner-approved) vs *removed* (the default).
3. **Configure the group-based model.** For each in-scope site, ensure access flows through the site's
   SharePoint groups (Owners/Members/Visitors) whose membership is, wherever possible, an **Entra/M365
   group** — not a list of individual users. Assign the standard permission levels to those groups.
4. **Remediate (pilot-first, `-WhatIf` by default).** Convert **direct user grants** into group
   membership, then **reset broken inheritance** back to inherit where the design says it should — keeping
   unique permissions only on the documented exceptions. Every reset and conversion is a named change:
   **`Inheritance Reset – <Site> – Remediation`**, **`Group Access Remediation – <Site> – Remediation`**.
5. **Stand up access reviews.** Wire **recurring site-access reviews** so site owners (or an approver)
   periodically re-attest who should keep access — via **Microsoft Entra ID Access Reviews** (P2-licensed)
   for group membership, and/or SharePoint's **site access review** where **SharePoint Advanced
   Management (SAM)** is licensed. Named **`Access Review – <Site> – Prod`**.
6. **Report continuously.** Deliver the **`Access Report – SPO – Report`** — a repeatable who-has-access
   export per site — plus the SharePoint admin center **Data Access Governance (DAG)** reports where SAM
   is licensed, so drift is caught between reviews.

## The standard permission-level model
This solution standardizes on SharePoint's **built-in permission levels** and adds custom levels only when
a real need exists. The built-in levels used:

| Level | Grants (built-in) | Typical group |
|---|---|---|
| **Full Control** | Everything, incl. permissions management | Site **Owners** group only |
| **Edit** | Add/edit/delete lists; add/edit/delete list items & documents | Site **Members** (contributors) |
| **Contribute** | Add/edit/delete list items & documents (not lists themselves) | Restricted contributors |
| **Read** | View pages, list items, and documents; download | Site **Visitors** (read-only) |
| **Limited Access** | *Special/automatic* — access to a specific item, not the site. **Not assigned by hand**; SharePoint adds it when unique permissions are granted below the site | *(system-managed)* |

> **Custom levels are real but used sparingly.** A common custom level is a view-only level that removes
> the *download / copy* permission (**`Perm Level – Read No Download – Prod`**). Custom permission levels
> are legitimate, but each one is another thing to maintain — define them only when the built-ins can't
> express the requirement, and never edit the **built-in** levels in place. **View Only** (as used by
> Office Online / library "Open in browser only") behaves differently from Read; verify the exact effect
> in your tenant before relying on it.

## The reference model (artifacts this solution creates)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused verbatim across the docs, scripts,
admin center, and reports:

| Artifact | Name |
|---|---|
| Read-only permission audit / baseline | `Permission Audit – SPO – Discovery` |
| The group + permission-level model doc | `Access Model – SPO – Design` |
| Entra/M365 group backing a site's members | `M365 Group – Finance – Prod` |
| SharePoint group (Members) for a site | `SPO Group – Finance Members – Prod` |
| SharePoint group (Owners) for a site | `SPO Group – Finance Owners – Prod` |
| SharePoint group (Visitors) for a site | `SPO Group – Finance Visitors – Prod` |
| Optional custom view-only level | `Perm Level – Read No Download – Prod` |
| Pilot remediation scope | `Permission Scope – Pilot – Stage1` |
| Broad remediation scope | `Permission Scope – Broad – Stage2` |
| A broken-inheritance reset (per site/scope) | `Inheritance Reset – <Site> – Remediation` |
| A direct-grant→group conversion | `Group Access Remediation – <Site> – Remediation` |
| A recurring site/group access review | `Access Review – <Site> – Prod` |
| The repeatable access report | `Access Report – SPO – Report` |

> Replace `Finance` / `<Site>` with your real site name and keep the pattern. Never invent a site or
> owner name.

## Benefits
- **Access becomes legible.** "Who can see this site?" is answered by naming a group's membership, not by
  reading thousands of item-level ACLs.
- **Permissions become self-maintaining.** Membership changes (joins/leaves/transfers) flow through
  Entra/M365 groups; access follows automatically. No orphaned direct grants.
- **The existing mess is remediated safely.** Broken inheritance and Limited Access sprawl are reset back
  to inherit — pilot-first, dry-run-first, with a rollback — so nothing breaks.
- **Access is continuously attested.** Recurring reviews force periodic re-confirmation; DAG/report exports
  catch drift in between.

## Limitations (be honest with buyers)
- **Some review/reporting features are license-gated.** **Entra ID Access Reviews** require **Entra ID
  P2** (or an equivalent suite). SharePoint's **Data Access Governance reports** and **site access
  review** require **SharePoint Advanced Management (SAM)**. Where those aren't licensed, this solution
  falls back to the included PowerShell reporting — **verify in your tenant/plan**.
- **Resetting inheritance is a real, visible change.** Resetting a scope to inherit *removes* the unique
  permissions there — which is the point, but if a unique grant was load-bearing and undocumented,
  someone loses access. That is why remediation is **pilot-first, `-WhatIf` first**, with the audit as the
  before-state and a documented rollback.
- **Limited Access cannot be assigned or removed directly.** It is system-managed. You remove it by
  removing the *underlying* unique grant that caused it, not by editing Limited Access itself.
- **Group-based access needs a group source of truth.** If the org has no coherent Entra/M365 group model,
  the group-based model rests on SharePoint groups alone (still an improvement) until the group model is
  established (often the Architecture product).
- **Who belongs in each group is an information-owner decision.** This solution builds the model and the
  evidence; it does not decide business entitlement.
- **Commercial vs Government clouds differ.** Admin-center URLs and some capability availability differ on
  **GCC / GCC High / DoD** (`*.sharepoint.us`, `*.office365.us`, `portal.azure.us`) — noted where it
  matters; verify on your cloud.

## The standard deployment model
> Assess the current permission posture (audit) → design the group + permission-level model → configure
> group-based access → remediate direct grants and broken inheritance on a **pilot** scope first →
> validate (access is group-based, inheritance intact where intended, over-share reduced, reviews running)
> → expand to the broad scope.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand**, with explicit pass/fail gates and
> a documented rollback.
