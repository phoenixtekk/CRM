# 1. Solution Overview — Container Labeling (Teams, Groups & Sites)

## What this solution is
Most organizations classify the **file** and forget the **container**. A sensitivity label on a document
controls that document — but the Microsoft Team, Microsoft 365 Group, or SharePoint site it lives in was
created with whatever defaults the creator clicked: public or private, guests allowed or not, external
sharing wide open, and downloadable to any personal laptop. That is the gap this solution closes. It uses
**container sensitivity labels** — sensitivity labels scoped to **Groups & sites** in Microsoft Purview —
to govern the container itself:

- **Privacy** — whether a Team/Group is **Public** or **Private** by label.
- **Guest (external user) access** — whether owners may add people outside your organization as guests.
- **External sharing** — how broadly a labeled SharePoint site may be shared (anyone / new-and-existing
  guests / existing guests only / only people in your organization).
- **Unmanaged-device access** — whether a labeled site is reachable at **full access**, **limited
  web-only access** (no download/print/sync), or **blocked** from devices that aren't
  compliant/domain-joined, via Microsoft Entra Conditional Access.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com), the **Microsoft 365 /
Entra admin centers**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), **Microsoft Graph**,
and **SharePoint Online Management Shell** — no third-party tooling. Container labels are configured,
**piloted on a small ring first**, validated against pass/fail gates, and then expanded.

> **Container labels govern the container, not the files inside it.** A container label sets privacy,
> guest, sharing, and device-access behavior for the Team/Group/Site. It does **not** encrypt or classify
> the individual files — that is the job of **file/email sensitivity labels** (a separate Purview
> solution). The two are complementary and are commonly deployed together; this solution delivers the
> container half.

## Why this matters
- **The container is the perimeter.** Guest access, external sharing, and unmanaged-device download are
  decided at the container level. An unlabeled container inherits tenant defaults — which are frequently
  more permissive than the data inside warrants.
- **Creation-time defaults are sticky.** A Team created "Public with guests allowed" tends to stay that
  way for years. Labeling at (and after) creation replaces ad-hoc choices with a governed, named posture.
- **Unmanaged-device access is invisible until it's a breach.** Without a container label driving
  Conditional Access, confidential-site content is downloadable to any personal device. The label makes
  "web-only, no download" or "blocked" a property of the site, enforced automatically.
- **It is defensible and auditable.** "Every site holding sensitive project data is Private, guest-free,
  and web-only from unmanaged devices" is a statement you can evidence with a report — not a hope.

## How it works
1. **Assess.** Read the tenant's enablement state (are container labels even turned on?), the
   container-scoped labels that exist, the SharePoint external-sharing baseline, and an inventory of
   existing Teams/Groups/Sites with their current privacy, guest, sharing, and label state — read-only.
2. **Design.** Define a **container label taxonomy** (below) mapping each tier to concrete privacy,
   guest, external-sharing, and unmanaged-device settings, aligned to the data-classification intent your
   stakeholders set.
3. **Configure.** Enable container labeling for the tenant (a one-time directory setting + label sync),
   author the container labels in the Purview portal, and publish them to users via a label policy.
4. **Pilot.** Apply the labels to a **pilot ring** of a few named Teams/Groups/Sites first, and publish
   the label policy to a **pilot user group** — never tenant-wide on day one. Container settings that
   affect guest access and device access are **high-impact**; prove them on the ring.
5. **Validate.** Confirm each piloted container carries the intended label and that privacy, guest,
   sharing, and unmanaged-device posture actually match the label's definition. Run the pass/fail gates.
6. **Expand.** Broaden the label policy to all intended users, apply labels to the wider container
   estate, optionally set a **default container label** for new containers, and hand ongoing coverage to
   operations.

## The container label taxonomy (design used throughout)
Three tiers are used consistently across the docs, scripts, and portal. Adjust names/settings to your
classification scheme — the **determination** of which data warrants which tier belongs to your
compliance/data-owner stakeholders; this solution provides the technical mapping.

| Label | Privacy | Guest access | External sharing (SharePoint) | Unmanaged-device access |
|---|---|---|---|---|
| **`Container – General`** | Private | Allowed | New and existing guests | Allow full access |
| **`Container – Confidential`** | Private | Existing guests only | Existing guests only | Allow limited, web-only access |
| **`Container – Highly Confidential`** | Private | Not allowed | Only people in your organization | Block access |

> **Unmanaged-device access (limited / blocked) requires Microsoft Entra ID P1 and SharePoint
> Conditional Access**, and is enforced through the label's SharePoint site setting. Availability is
> **licensing-dependent — verify against your own tenant and plan.** Where P1/Conditional Access is not
> available, the label still governs privacy, guest, and external-sharing settings.

## What you can control
- Whether container labeling is enabled for the tenant at all.
- The container label taxonomy: privacy, guest access, external sharing, and unmanaged-device access per
  tier.
- Which users the label policy publishes to, and whether a **default** container label applies to new
  containers.
- Which existing Teams/Groups/Sites get which label, and in what order (pilot ring → expand).

## Limitations (be honest with buyers)
- **Container labels govern the container, not the files.** No file-level encryption or classification —
  see the file/email sensitivity-labeling solution for that.
- **Enablement is a one-time, tenant-level action.** Turning on container labels sets the Entra
  `Group.Unified` directory setting (`EnableMIPLabels = True`) and syncs labels; it changes how labels
  behave org-wide, so it is piloted and change-controlled like any tenant setting.
- **Unmanaged-device and external-sharing controls are licensing-gated.** The Conditional Access
  (limited/blocked device access) settings require **Entra ID P1** and SharePoint; some behaviors depend
  on your SharePoint tenant baseline. **Verify availability against your licensing and tenant.**
- **Label creation is done in the portal.** The provided scripts **apply existing labels** to containers,
  read state, validate, and report — they do **not** author labels via `New-Label` (label authoring with
  container parameters is done in the Purview portal, per the Implementation Guide) to avoid fragile,
  hard-to-review label definitions in code.
- **The Purview portal is evolving.** Portal paths and the exact protection-settings page names change;
  they are cited as of authoring and flagged **"verify in your tenant."**
- **Classification determinations are deferred.** Which data is "Confidential" vs "Highly Confidential,"
  and who may be a guest, are decided by your compliance, data-owner, privacy, and security stakeholders —
  this solution provides the technical method and the evidence, not the determination.

## Naming convention (used in every doc and script)
| Artifact | Name |
|---|---|
| Enablement-state / container inventory export | `Container Inventory – Assess` |
| Container label taxonomy | `Container Labels – Taxonomy – Design` |
| Container label policy (publishes labels to users) | `Container Labels – Groups & Sites – Policy` |
| One-time tenant enablement record | `Container Labeling – Enablement` |
| Pilot ring (containers + users) | `Container Labels – Pilot Ring – Stage1` |
| Coverage / posture report | `Container Inventory – Report` |
| Prerequisite / health check output | `Container Scope – Map` |

## The standard deployment model
> Assess the tenant and container estate → design the label taxonomy → enable container labeling, author
> and publish the labels → apply to a pilot ring → validate every gate → expand to the estate.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**
