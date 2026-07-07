# 1. Solution Overview — Google Drive & Shared Drives Architecture, Permissions & Governance

Once an enterprise lands on Google Workspace, **Drive is where most of the collaboration — and most
of the risk — lives**. Left ungoverned, Drive becomes a sprawl: files owned by individuals scattered
across My Drive, "Anyone with the link" shares that outlive the person who made them, external
sharing to personal Gmail accounts, and content that no team can find because there is no taxonomy.
When the person who owns a critical file leaves, the file is **orphaned** and access breaks. This
solution designs the **steady-state Drive and Shared Drives architecture** so collaboration is easy
but data stays where it belongs — deployed **pilot-first**, with pass/fail gates and a documented
rollback for the sharing changes that are high-impact.

> **Scope boundary — architecture, not migration.** This solution is the **steady-state Drive
> architecture and governance** model. The one-time movement of SharePoint / OneDrive content *into*
> Drive is a separate migration solution and is out of scope here (it is referenced only where the
> target Shared Drive layout must be agreed **before** data lands). This document assumes the data is
> in — or is landing in — Google Drive, and designs how it is structured, shared, and governed from
> that point on.

> **Vendor boundary.** Google **Admin console** (admin.google.com) paths and the **Drive API / Admin
> SDK** used by the Python tools are authored from Google's current public documentation. Several
> controls named here are **edition-gated** — **target audiences**, **trust rules**, **DLP for Drive**,
> and the **security investigation tool** require **Enterprise / Education Plus / Enterprise Plus**
> tiers — and those gates are flagged where they apply. Where a page or toggle is evolving, it is
> flagged **"verify in your tenant."** Gemini-in-Drive behavior is flagged **"verify in your tenant."**

## The Drive model — five design decisions, one governed estate

A governed Drive estate is the product of five deliberate design decisions. The reference model
below is what the Implementation Guide stands up.

### Decision 1 — My Drive vs Shared Drives (where content lives)
The single most important architectural rule: **team and business content lives in Shared Drives,
not in individuals' My Drive.** A Shared Drive is owned by the **organization**, not a person — so
membership, not ownership, controls access, and no file is orphaned when an employee leaves. My Drive
is reserved for genuinely personal drafts and working files. The design defines a **content-placement
policy**: which categories of content belong in a Shared Drive (anything a team relies on) versus My
Drive (transient personal work), and how existing individually-owned content is relocated.

### Decision 2 — Shared Drives taxonomy & naming (structure)
Shared Drives are **flat containers**, not a deep folder tree — so the taxonomy is expressed in the
**set of Shared Drives** and a **consistent naming convention**, not in nesting. The design defines a
naming standard `<Domain> – <Team/Function> – <Purpose>` (e.g. `Shared Drive – Finance – AP Records`,
`Shared Drive – HR – Employee Files – Restricted`) and a small, governed set of top-level domains
(Corporate Functions, Business Units, Projects, Cross-Org Collaboration). The taxonomy is the map
that makes content findable and makes membership decisions obvious.

### Decision 3 — Membership & role model (who can do what)
Access to a Shared Drive is granted by **membership**, and every member holds one of the Drive
**roles**: **Manager**, **Content manager**, **Contributor**, **Commenter**, **Viewer**. The design
makes membership **group-based, not user-based** — you add a **Google Group** (e.g.
`grp-finance-ap@corp.example`) as the member, then manage people by changing group membership, so
access is auditable in one place and driven by the directory source of truth. A **role model**
assigns the least-privilege default (most business users are **Contributor** or **Viewer**;
**Manager** is reserved for a named owner group per Drive).

### Decision 4 — External & link-sharing policy (the trust boundary)
This is where data leaks or stays contained. The design sets, at the Admin-console level and per
organizational unit / Shared Drive, **who content can be shared with**: internal-only, allow-listed
partner domains (via **target audiences** and **trust rules**), or open external. It curtails
**"Anyone with the link"** to default-off or internal-only, sets **link-sharing default access**,
requires **outside-domain sharing warnings**, and controls whether Shared Drive membership can
include people **outside the organization**. The default posture is **restrictive**, opened
deliberately per audience.

### Decision 5 — DLP-aligned sharing controls & lifecycle governance (keeping it governed)
Sharing policy defines *who can share*; **DLP** defines *what can be shared* — named data-protection
rules block or warn when sensitive content (national IDs, financial data, a custom classifier) is
shared externally, so classification drives sharing, not just admin defaults. Finally,
**governance/lifecycle** keeps the estate healthy over time: a **named owner (Manager group) per
Shared Drive**, periodic **access reviews**, an **orphaned-ownership** sweep (files still owned by
departed users), a **stale/empty-Drive** review, and a **provisioning standard** so new Shared
Drives are created to the model rather than ad hoc.

## Reference design (target state)

| Layer | Target state |
| --- | --- |
| Content placement | Business content in **Shared Drives**; My Drive = personal/transient only |
| Taxonomy | Governed top-level domains + `<Domain> – <Team> – <Purpose>` naming; flat Drives |
| Membership | **Group-based** membership; least-privilege role model; a named Manager group per Drive |
| External sharing | Restrictive default; **target audiences** + **trust rules** for allow-listed partners; link-sharing curtailed |
| DLP | Data-protection rules block/warn on sensitive external sharing |
| Governance | Owner per Drive, access reviews, orphaned-owner + stale-Drive sweeps, provisioning standard |

## Benefits
- **No orphaned content** — organization-owned Shared Drives survive employee departures.
- **Collaboration stays easy** — clear taxonomy makes content findable; group membership is one place to manage access.
- **Data stays contained** — restrictive external/link-sharing defaults plus DLP keep sensitive content in-bounds.
- **Auditable** — access is expressed as group membership and named Drives, not ad-hoc per-file grants.
- **Scales** — a provisioning standard and periodic reviews keep the estate governed as it grows.

## Limitations & honest constraints
- **Edition-gated controls.** Target audiences, trust rules, and DLP for Drive require Enterprise-tier
  editions; on lower tiers the design falls back to OU-level sharing settings and manual review
  (flagged in Requirements).
- **Shared Drives are flat.** Deep hierarchy must be expressed as separate Drives + a naming
  convention, not nested folders — this is a deliberate constraint, not a workaround.
- **Existing sprawl must be remediated.** This design defines the target and the sweeps to get there;
  relocating already-scattered My Drive content and fixing existing over-shares is an execution effort,
  not a single switch.
- **Sharing changes are high-impact.** Tightening external/link-sharing can break active
  collaborations; every production sharing change is piloted, gated, and rollback-ready.

## Deployment model
This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
with explicit pass/fail gates and a **documented rollback** for every production sharing change:
1. **Assess** — inventory current sharing exposure, external shares, link-sharing, and orphaned
   ownership (read-only) with `drive_sharing_exposure_assessment.py`.
2. **Design** — agree the taxonomy, naming, role model, external-sharing policy, target audiences,
   DLP alignment, and lifecycle governance against the reference design above.
3. **Configure** — apply Admin-console sharing settings, create target audiences/trust rules, align
   DLP, and provision the pilot Shared Drives to the naming model.
4. **Pilot** — run the design against one pilot domain/OU (e.g. `Pilot OU – Drive – Finance`), with a
   defined pass/fail gate.
5. **Validate** — confirm sharing is scoped to policy, no orphaned ownership remains, and governance
   reporting is in place with the validation tools.
6. **Expand** — roll the model out domain by domain, keeping the provisioning standard and periodic
   reviews as steady-state governance.
