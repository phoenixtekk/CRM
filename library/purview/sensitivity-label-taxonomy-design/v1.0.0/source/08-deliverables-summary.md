# 8. Deliverables Summary — Sensitivity Label Taxonomy Design

## What you receive
A complete, self-guided package to **design and build a sensitivity label taxonomy** in Microsoft
Purview — the tier structure, sublabels, a stable naming convention, and the protection/marking mapping
— then configure it in the tenant, publish it to a pilot ring, and validate that it behaves as designed.
It uses only the Microsoft Purview portal and Security & Compliance PowerShell (no third-party tooling).

## Documentation
| Document | What it gives you |
|---|---|
| **Solution Overview** | The label object model, the naming convention, the sample taxonomy, the protection/marking mapping, what you control, limitations, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (licensing for labels/protection, Information Protection Admin role, S&C PowerShell, classification scheme, pilot ring, encryption/rights prerequisites, a signed-off design sheet) on top of the Purview Global Requirements. |
| **Implementation Guide** | Ordered steps: assess posture → design taxonomy + mapping → build parents/top-level (`-WhatIf`→commit) → build protected sublabels (`-WhatIf`→commit) → publish to pilot ring → validate → expand to broad publish. Each step named, gated, and reversible. |
| **Testing & Validation Guide** | 8 pass/fail tests — taxonomy built as designed, parents group-only, marking visible, encryption enforces, naming conformance, pilot scoping, tooltips, and a full health check. |
| **Best Practices** | Structure, naming, protection/marking mapping, piloting/rollout, taxonomy-health, and safety guidance. |
| **Troubleshooting Guide** | Common failure modes (labels not visible, parent selectable, encryption not enforcing, naming drift, name collisions) with resolutions. |

## PowerShell tools (5)
All run through `Connect-IPPSSession` (Security & Compliance PowerShell); read-only or `-WhatIf` by
default, writes gated behind `-Commit`. No credentials in code.

| Script | Role | Default |
|---|---|---|
| `IPTAX-Discovery.ps1` | **Posture assessment** — inventory existing sensitivity labels, their parent/sublabel structure and order, protection/marking per label, and label policies; flag naming-convention drift and internal-name collisions before you build. | Read-only |
| `IPTAX-TaxonomyConfig.ps1` | **Taxonomy + publish config helper** — create the designed parent tiers and top-level labels, create protected sublabels per the mapping, and publish the selectable set to a pilot/broad scope. | `-WhatIf` |
| `IPTAX-Validation.ps1` | **Design-conformance validator** — check the built taxonomy against the design: order, parent/sublabel structure, per-label protection/marking, and that the pilot policy is scoped correctly. | Read-only |
| `IPTAX-Reporting.ps1` | **Taxonomy + mapping report** — export the full taxonomy and protection/marking mapping (and a naming-convention conformance view) as the living record of the design. | Read-only |
| `IPTAX-ScopeHealth.ps1` | **Scope/health helper** — preview the pilot/broad publish scope and its group membership, confirm the protection service is active, and surface orphaned policies and label sprawl. | Read-only |

## Outcomes
- A **signed-off label taxonomy** built in the tenant — the right number of tiers, clear sublabels, and
  a stable naming convention that prevents sprawl.
- A **protection/marking mapping** applied per label — the correct tiers encrypt (rights by group), the
  lower tiers mark, and parents group only.
- The taxonomy **published to a pilot ring**, validated (structure, marking, encryption enforcement),
  and then broadly — with encryption proven to enforce before broad rollout.
- Repeatable read-only tooling to re-baseline, report, and health-check the taxonomy over time.

## Explicitly out of scope (deferred)
- **The classification determination** — the tier count, the final names, which tiers encrypt, and the
  rights model are owned by security/compliance/records; this solution provides the design method, the
  mapping template, and the configuration, not the sign-off.
- **Service-side auto-labeling, retention labels, and adaptive scopes** — the deeper labels
  implementation; **DLP, insider risk, communication compliance**, and **container labeling** for
  Teams/Groups/Sites; and **mandatory vs recommended (default-label) design** — each a separate Purview
  solution that a sound taxonomy is the foundation for.
- Any capability your **licensing/tenant** does not include — verify before relying on advanced label
  behaviors.
