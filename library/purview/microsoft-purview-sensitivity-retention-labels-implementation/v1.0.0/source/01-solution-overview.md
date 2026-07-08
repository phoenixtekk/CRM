# 1. Solution Overview — Microsoft Purview Sensitivity & Retention Labels (Implementation)

## What this solution is
Sensitivity and retention labels are how Microsoft Purview **classifies, protects, and governs**
content across Microsoft 365. A **sensitivity label** marks how sensitive an item is and can apply
*protection* — encryption, content marking (header/footer/watermark), and access control. A
**retention label** marks how long an item must be kept (and what happens at the end) so content is
retained or disposed by policy rather than by accident. This solution is a repeatable way to design a
workable **label taxonomy**, build and publish sensitivity labels with protection, turn on
**auto-labeling** (client-side and service-side) **in simulation first**, and stand up **retention
labels** and label policies scoped with **adaptive scopes** — all piloted in simulation/test before
enforcement, using only the Microsoft Purview portal and Security & Compliance PowerShell (no
third-party tooling).

This is the **deep implementation** build for labels specifically — the detailed taxonomy,
protection, publishing, auto-labeling, and retention-label configuration — distinct from a broad
Purview foundation baseline.

## Why this matters
- Labels are the backbone of information protection: DLP, encryption, and data lifecycle all key off them. A weak or inconsistent taxonomy undermines every downstream control.
- Protection applied through a sensitivity label (encryption + rights) **travels with the file** — it stays enforced when content leaves the tenant, unlike a location-only control.
- A careless auto-labeling rollout — mislabeling, surprise encryption, or unexpected deletion from a retention label — breaks user trust fast and generates a flood of tickets. Simulation-first is what makes it safe.
- Retention labels with **adaptive scopes** target the *right* content by attribute (department, location, site property) and re-evaluate membership automatically, so governance keeps pace with the organization instead of drifting.

## The two label types (and where they apply)
| | **Sensitivity label** | **Retention label** |
|---|---|---|
| Answers | *How sensitive is this?* | *How long must we keep this?* |
| Can apply | Encryption, content marking, access control, container settings | Retain, then delete / trigger disposition review / mark as record |
| Applied by | User, client-side auto-label, service-side auto-label | User, service-side auto-apply, or auto-applied by policy |
| Published via | **Sensitivity label policy** (`New-LabelPolicy`) | **Retention label policy** (`New-RetentionCompliancePolicy` + rule) |
| Scoping | Users/groups (label policy) | Static locations **or adaptive scopes** |

## Auto-labeling: client-side vs service-side
- **Client-side auto-labeling** runs in the Office apps (Word/Excel/PowerPoint/Outlook) as the user works. It *recommends* or *automatically applies* a sensitivity label based on conditions configured on the label and surfaced through the label policy. It only affects newly edited content on that client.
- **Service-side auto-labeling** runs in the service across **data at rest** (SharePoint, OneDrive) and **data in transit** (Exchange email). It is configured as an **auto-labeling policy** and, critically, is **run in *simulation* first** — it scans and reports what *would* be labeled without applying anything, so you validate accuracy before enforcing.
- Service-side auto-labeling is **licensing-dependent** (typically Microsoft 365 E5 / E5 Compliance) — **verify your licensing/tenant** before relying on it.

## Adaptive scopes (for retention)
An **adaptive scope** is a dynamic membership query (User, Group, or Site) — e.g. "all users where
Department = Finance" or "all sites where a custom property = Records". A retention policy bound to an
adaptive scope automatically re-evaluates membership on a schedule, so newly matching users/sites are
covered without editing the policy. Adaptive scopes are the recommended alternative to static scopes
for anything that changes over time. Availability/behavior is **licensing- and tenant-dependent** —
**verify your licensing/tenant.**

## Sample label taxonomy (starting point — confirm with your governance owners)
> The taxonomy below is a **technical starting point**; the final label names, protection settings,
> and retention periods are a **records/legal/compliance determination** (see §2 and the deferral
> note). Names here are reused verbatim across the docs and scripts.

**Sensitivity labels (ordered least → most sensitive):**

| Label | Protection |
|---|---|
| `Public` | None — marking only |
| `General` | None — internal marking (footer) |
| `Confidential` (parent) | — grouping only |
| `Confidential \ All Employees` | Encrypt, all internal users, content marking |
| `Confidential \ Trusted People` | Encrypt, specified people, Do-Not-Forward-style rights |
| `Highly Confidential` (parent) | — grouping only |
| `Highly Confidential \ All Employees` | Encrypt + watermark, all internal users |
| `Highly Confidential \ Specified People` | Encrypt, named recipients only, no export |

**Retention labels (periods are placeholders — set by records/legal):**

| Label | Action (to confirm) |
|---|---|
| `Business-General-3yr` | Keep 3 years from modification, then start disposition review |
| `Financial-Records-7yr` | Keep 7 years from creation |
| `Transitory-1yr` | Delete 1 year after creation |
| `Legal-Reference` | Retain, no automatic deletion |

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Type> <Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal:

| Artifact | Name |
|---|---|
| Sensitivity label policy (pilot) | `SL Policy – Pilot – Ring1` |
| Sensitivity label policy (broad) | `SL Policy – Broad – AllUsers` |
| Service-side auto-labeling policy (simulation) | `AL Sim – Financial – SPO+ODB` |
| Service-side auto-labeling policy (email, simulation) | `AL Sim – Financial – Exchange` |
| Retention label policy (pilot) | `RL Publish – Pilot – Ring1` |
| Retention label policy (adaptive) | `RL Publish – Adaptive – FinanceUsers` |
| Adaptive scope (users) | `Scope – Users – Finance` |
| Adaptive scope (sites) | `Scope – Sites – Records` |

## What you can control
- The label taxonomy — names, order, parent/sublabel structure, tooltips.
- Which labels carry protection, and the exact encryption/marking/rights on each.
- Who each sensitivity label policy targets (pilot ring first, then broad).
- Auto-labeling conditions (sensitive info types, keywords, trainable classifiers) — run in simulation, tuned, then enforced.
- Retention label periods and actions (subject to records/legal sign-off) and the adaptive scopes that target them.

## Limitations (be honest with buyers)
- **Licensing gates capability.** Service-side auto-labeling, some adaptive-scope behavior, and certain classifier features require **E5 / E5 Compliance** — **verify your licensing/tenant**; the solution flags each gate rather than assuming.
- **Records, retention schedules, and legal holds are determinations, not technical defaults** — the specific retention periods, records declarations, and hold decisions come from records/legal (see the deferral note in §2). This solution provides the configuration method and evidence.
- **Encryption is high-impact.** A published label that encrypts can block co-authoring, third-party tools, and downstream automation if applied carelessly — always pilot in a small ring first.
- **Auto-labeling has latency and quotas.** Simulation and enforcement scan large volumes over time; results are not instantaneous, and item/throughput limits apply — **verify current limits for your tenant.**
- **The portal is evolving.** Portal paths and some cmdlet parameters change; where a path is version-sensitive it is flagged "verify in your tenant."

## The standard deployment model
> Assess the current label posture → design the taxonomy → build + publish sensitivity labels to a
> **pilot ring** → configure auto-labeling in **simulation** → validate accuracy → build retention
> labels + adaptive scopes → validate → **expand and enforce** tenant-wide.
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).**
