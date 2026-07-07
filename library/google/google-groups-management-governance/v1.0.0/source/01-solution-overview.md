# 1. Solution Overview — Google Groups Management & Governance

In a Google Workspace enterprise, **Groups are load-bearing infrastructure that almost nobody
governs**. A single Google Group is, at once, a **mailing list** (a distribution address), an
**access-control principal** (added to Shared Drives, calendars, IAM roles, target audiences, and SSO
apps), and a **collaboration space** (a Groups-for-Business forum). Because a group is so cheap to
create — any user can spin one up from groups.google.com by default — they multiply faster than any
governance catches up. The result is predictable: thousands of groups where nobody remembers the
purpose, groups whose only owner left the company (**orphaned**), groups that still hold **external
members** from a project that ended two years ago, and groups configured so **anyone on the internet
can post** or **anyone in the org can join and read** the archive. Every one of those groups is a
distribution path, an access grant, and an audit finding waiting to happen.

This solution establishes a **management and governance model for Google Groups** so groups are
**intentional, least-exposed, and auditable**: a defined set of **group types** with a **naming
convention**, a **lifecycle** (request → approve → review → retire), a **membership and ownership
model**, the right use of **dynamic groups** and **Cloud Identity security groups**, an
**external-membership and posting/access-settings policy**, and a recurring **stale/orphaned-group
hygiene** discipline. It is deployed **pilot-first**, with pass/fail gates and a documented rollback
for the changes that are high-impact (tightening posting/access settings and removing external
members can break active mail flow and collaboration).

> **Scope boundary — governance model, not a one-time migration.** This solution governs the
> **steady-state Groups estate**. Bulk *creation* of groups from a migrated distribution-list export
> (Exchange DLs → Google Groups) is a migration-execution activity and is referenced only where the
> target type/naming/policy must be agreed **before** groups are loaded. This document assumes groups
> exist (or are landing) and defines how they are typed, named, owned, scoped, reviewed, and retired
> from that point on.

> **Vendor boundary.** Google **Admin console** (admin.google.com) paths, the **Groups settings**
> surface, **Cloud Identity dynamic/security groups**, and the **Admin SDK Directory (Groups)** +
> **Cloud Identity Groups** APIs used by the Python tools are authored from Google's current public
> documentation. Several capabilities are **edition-gated** — **dynamic groups** and **Cloud Identity
> security groups** require **Cloud Identity Premium** (bundled with Enterprise Workspace tiers) —
> and those gates are flagged where they apply. Where a console page or toggle is evolving it is
> flagged **"verify in your tenant."** Compliance *interpretation* (what an auditor will accept as
> evidence, which regime applies) is deferred to the organization's compliance/legal owners; this
> solution provides the technical control, configuration method, and evidence.

## The Groups model — six design decisions, one governed estate

A governed Groups estate is the product of six deliberate design decisions. The reference model below
is what the Implementation Guide stands up.

### Decision 1 — Group types (what a group is *for*)
Not all groups are the same object, and conflating them is the root of most sprawl. The design
defines a small, fixed set of **types**, each with its own default policy:
- **Distribution group** — a mail address for one-to-many email (e.g. `all-finance@`). Members
  receive mail; the group is rarely an access principal.
- **Access/security group** — a principal used to *grant access* (Shared Drives, calendars, IAM,
  target audiences, SSO app assignment). Mail delivery is secondary or off. Best implemented as a
  **Cloud Identity security group** so it carries the immutable security label.
- **Collaboration group** — a Groups-for-Business forum/inbox (shared inbox, team discussion,
  Collaborative Inbox) where members read and post to a shared archive.
- **Dynamic group** — membership is computed from a **CEL query** over directory attributes (e.g. all
  users in `department=Finance`) rather than managed by hand.
- **External/partner group** — deliberately contains members outside the organization; governed under
  the strictest external policy.
The type drives every downstream default (who can join, who can post, external allowed, review
cadence).

### Decision 2 — Naming convention (make the type and owner obvious)
A group's name should announce its type, scope, and purpose so an admin never has to guess. The design
adopts `<Type> – <Scope> – <Purpose>` for the display name and a matching **email prefix convention**
(e.g. `dl-`, `grp-`/`sec-`, `collab-`, `dyn-`, `ext-`). Examples: `Distribution – Finance – All Staff`
at `dl-finance-all@corp.example`; `Security – Finance – AP Drive Access` at `sec-finance-ap@corp.example`;
`Dynamic – Sales – All Sales` at `dyn-sales-all@corp.example`; `External – ProjectX – Partner Collab`
at `ext-projectx-partner@corp.example`. The prefix makes type-based policy validation and reporting
trivial (a script can assert every `sec-*` group is a security group with no external members).

### Decision 3 — Membership & ownership model (who is in, who is accountable)
Every group must have a **named, accountable owner** — and never a single point of failure. The design
requires **at least two owners per group** (ideally an **owner *group***, not two individuals, so
ownership survives departures), assigns the **`OWNER` / `MANAGER` / `MEMBER`** roles deliberately, and
prefers **group-based (nested) membership** over long lists of individual users so access is auditable
in one place and driven by the directory source of truth. An **orphaned group** — zero live owners —
is a defect the lifecycle must catch and fix.

### Decision 4 — Dynamic vs. static, and Cloud Identity security groups
For membership that maps cleanly to a directory attribute (department, location, cost centre), a
**dynamic group** (Cloud Identity Premium) keeps membership correct automatically and eliminates the
"someone forgot to remove them" class of error — the tradeoff is that membership is only as good as the
attribute source of truth (HR/IGA feeding the directory). For any group used to **grant access**, make
it a **Cloud Identity security group** so it carries the immutable **security label**: security groups
can be used in **IAM and access contexts** where plain Groups-for-Business groups cannot, and the label
prevents the group from being silently repurposed. The design decides, per group, static-vs-dynamic and
whether it must be a security group.

### Decision 5 — External-membership + posting/access-settings policy (the trust boundary)
This is where a group leaks. Every group carries **Groups settings** that determine **who can join**,
**who can post/message**, **who can view the archive/members**, and **whether members outside the
organization are allowed**. Left at permissive defaults, a group can be **public** (anyone can post,
external senders accepted, archive world-readable). The design sets a **restrictive baseline at the
Admin-console level** (org-wide default access, "who can create groups", and whether external members
are allowed at all) and a **per-type policy** applied to each group's settings — internal-only posting,
owner-approved joins, members-only archive, external members only on explicitly `ext-*` groups. The
default posture is **restrictive**, opened deliberately per type.

### Decision 6 — Lifecycle & hygiene (keeping it governed over time)
Groups decay. The design stands up a **lifecycle** — **request → approve → review → retire** — so
groups are created to the model rather than ad hoc, reviewed on a cadence, and retired when their
purpose ends. Hygiene sweeps run continuously: an **orphaned-group** finder (no live owner), a
**stale-group** finder (no posts / no membership change / empty for N days), an
**external-exposure** finder (external members or public settings outside policy), and an
**over-permissioned** finder (security-type groups whose settings are too open). Retirement is
**staged** (suspend delivery / archive → hold → delete) with a rollback window, because deleting a
group that still routes mail is destructive.

## Reference design (target state)

| Layer | Target state |
| --- | --- |
| Types | Fixed set: Distribution, Security/Access, Collaboration, Dynamic, External — each with a default policy |
| Naming | `<Type> – <Scope> – <Purpose>` display + email prefix (`dl-`/`sec-`/`collab-`/`dyn-`/`ext-`) |
| Ownership | ≥2 owners, ideally an **owner group**; no orphaned groups; group-based nested membership |
| Dynamic/Security | Dynamic groups for attribute-driven membership; **Cloud Identity security groups** for anything granting access |
| External / posting | Restrictive Admin baseline; per-type settings; external members only on `ext-*` groups; internal-only posting default |
| Lifecycle | Request → approve → review → retire; owner-attested access reviews; staged retirement with rollback |
| Hygiene | Continuous orphaned / stale / external-exposed / over-permissioned sweeps |

## Benefits
- **No orphaned or ownerless groups** — every group has ≥2 accountable owners; the lifecycle catches
  and fixes any that lose them.
- **Least exposure** — restrictive posting/access defaults and a hard external boundary keep groups
  from becoming open relays or world-readable archives.
- **Membership stays correct** — dynamic groups track directory attributes; group-based membership is
  auditable in one place.
- **Access is trustworthy** — Cloud Identity security groups carry an immutable label, so access
  grants can't be silently repurposed.
- **Auditable & scales** — a naming convention plus type policy makes the whole estate machine-checkable;
  lifecycle and hygiene sweeps keep it governed as it grows.

## Limitations & honest constraints
- **Edition-gated controls.** Dynamic groups and Cloud Identity security groups require **Cloud
  Identity Premium**; on lower tiers the design falls back to static groups + manual review (flagged
  in Requirements).
- **Dynamic membership is only as good as its source.** A dynamic group is correct only if the
  directory attribute it queries is correct — garbage attributes yield wrong membership; the HR/IGA →
  directory feed is a prerequisite, not an afterthought.
- **Tightening settings can break things.** Restricting posting, removing external members, or changing
  who can post to a distribution address can break active mail flow and collaboration; every
  production settings change is piloted, gated, and rollback-ready.
- **Existing sprawl must be remediated.** This design defines the target and the sweeps to reach it;
  re-typing, re-naming, re-owning, and cleaning up thousands of existing groups is an execution effort,
  not a single switch.
- **Retirement is destructive.** Deleting a group that still routes mail or grants access breaks both;
  retirement is staged (suspend → hold → delete) with a rollback window.

## Deployment model
This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
with explicit pass/fail gates and a **documented rollback** for every production settings change:
1. **Assess** — inventory the current Groups estate and its risk posture (orphaned, stale, external-exposed,
   over-permissioned) read-only with `groups_inventory_hygiene_assessment.py`.
2. **Design** — agree the type set, naming convention, ownership model, dynamic/security-group decisions,
   external/posting policy, and lifecycle against the reference design above.
3. **Configure** — set the Admin-console Groups baseline, define the named policies, and prepare the
   pilot groups to the naming/type model (dry-run first with the config/settings helpers).
4. **Pilot** — apply the model to one pilot scope (e.g. `Pilot OU – Groups – Finance`) with a defined
   pass/fail gate.
5. **Validate** — confirm naming/type policy is enforced, no orphaned/stale groups remain in scope, and
   external exposure is scoped, using the validator + policy-checker tools.
6. **Expand** — roll the model out scope by scope, keeping the lifecycle and hygiene sweeps as
   steady-state governance.
