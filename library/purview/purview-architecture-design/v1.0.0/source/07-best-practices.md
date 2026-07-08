# Best Practices — Microsoft Purview Architecture & Design

Field-tested guidance for designing Purview before you scale it. It follows the same order the solution
is built: get the **capability map and licensing** right, then the **RBAC and scoping guardrails**, then
let the **phased roadmap** drive the build — deliberate, least-privilege, and defensible.

## 1. Map to licensing before you design a phase
- The most common Purview planning failure is designing a phase around a capability the plan does not
  license. **Confirm each capability is licensable first** (E3 vs E5 / E5 Compliance vs add-on vs
  preview), and mark the rest **deferred (not licensed)** on the map — do not design around them.
- Treat the script's capability-availability output as **indicative**; confirm exact entitlement with
  Microsoft licensing and by checking the capability appears in the portal.

## 2. Architect separation of duties from day one
- Separate the administration of **information protection, insider risk, communication compliance,
  eDiscovery, and records** into distinct role groups with distinct people. Retrofitting separation
  after everyone is a Compliance Administrator is expensive and audit-visible.
- Reserve **Global Administrator** and **Compliance Administrator**; prefer the **narrow,
  function-specific** role group. Keep readers/auditors read-only. Record and review SoD conflicts.

## 3. Design scoping as a first-class decision
- Choose **adaptive vs static** scope **per capability** deliberately. Adaptive scopes (query-based on
  user/site/group attributes) re-evaluate automatically and scale; static scopes are explicit and
  simple. Decide once, at design time, because every later policy inherits it.
- Use **administrative units** where scoped delegation matters (e.g. a region or business unit
  administers its own labels). Availability is licensing-gated — verify.

## 4. A pilot ring is what makes "pilot" real
- Define a named **pilot ring** (`SG-PA-Pilot`) before any capability is built. "Pilot" without a
  defined population is a hope; with a ring it is a contained, reversible test on known users/sites.
- Expand **ring by ring**, re-running the gates after each expansion — never flip a high-impact policy
  to enforce, tenant-wide, in one move.

## 5. Make simulation-first a designed pattern, not a habit
- Bake the pattern into the architecture: every high-impact policy (DLP, labels, retention, insider
  risk) is created in **simulation/test/disabled** mode, named with the **`Sim`** suffix, scoped to the
  pilot ring, validated, then promoted to **`Prod`**. The naming standard and pilot ring make this
  **enforceable**, not just advisory.

## 6. Set the naming standard before the first object
- Names are effectively immutable once dozens of policies reference them. Adopt `<Purpose> – <Scope> –
  <Stage>` (with `Sim`/`Prod`) **before** Phase 1, and apply it to every object. Report drift so
  nonconforming legacy objects are visible and planned for renaming.

## 7. Sequence phases — never run them all at once
- Follow **Foundation → Know → Protect → Prevent loss → Govern → Advanced**. Each phase depends on the
  guardrails and classification the earlier phases establish; DLP without classification, or protection
  without roles, produces sprawl. Respect the entry/exit gate on each phase.

## 8. Keep the architecture a living document
- Re-baseline periodically and at every plan change. Review the RBAC model on **joiners/leavers**,
  re-check **licensing** when subscriptions change, and watch for the ongoing **portal / unified Purview
  RBAC** evolution Microsoft ships — verify names and paths against your tenant rather than assuming.

## 9. Design carries determinations — it does not make them
- The architecture is the technical vessel for **regulatory applicability, retention schedules, records
  file plans, and the lawful basis** for insider-risk/communication monitoring. Those remain
  **compliance / records / privacy / legal** determinations. Capture the owner per capability domain and
  route determinations to them.

## 10. Protect the privacy-sensitive domains in the design itself
- Insider Risk and Communication Compliance are HR/privacy-sensitive. Design **strict role separation**,
  **anonymization/pseudonymization** where the capability supports it, and a recorded **lawful basis**
  into the architecture **before** those phases — not as a later add-on.

## 11. Verify against your tenant — the surfaces evolve
- Purview capability availability, role-group names, adaptive-scope support, and portal paths are
  **licensing-dependent** and **actively changing**. Confirm capability availability and exact paths
  **against your licensing/tenant**; where a capability is in preview, treat it as such.

## 12. Keep the design artifacts and evidence intact
- The capability map, RBAC model, scoping plan, naming standard, and roadmap are the **defensible record**
  of what Purview deploys and why. Version them, keep them current as phases complete, and treat the
  posture report as a point-in-time snapshot — the **authoritative** state is always the portal.
