# 2. Requirements Guide — Phased GPO-to-Intune Transition Program

Verify **every** requirement before running the program. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-migrations.md`.

> **Naming convention (mandatory, reused verbatim across the program):** every created artifact is
> `<Purpose> – <Scope> – <Stage>`. **Scope** = `Core OS | Firewall | App Control | All | Identity`;
> **Stage** = `Source` (GPO) | `Target` (Intune) | `Program`. Canonical artifacts introduced here are
> reused in the Implementation Guide verbatim — for example
> `Transition Wave – Core OS – Pilot`, `Coexistence Policy – MDM Wins Over GP – All Migrated`,
> `Phase Gate Checklist – Core OS – Program`.

## 2.1 Intune licensing & admin access
**Description:** An Intune-bearing license plan and the admin roles to build and assign device
configuration policies (settings catalog, imported ADMX, endpoint security).
**Why:** Every migrated setting and every coexistence/precedence policy is built and assigned in
Intune; the program cannot configure the target without it.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** active;
you hold **Intune Administrator**.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1; grant
least-privilege Intune admin roles. (See global requirements G1, G2.)

## 2.2 Devices enrolled / co-managed in Intune
**Description:** The in-scope domain-joined devices are Entra-joined or Entra-hybrid-joined and
enrolled (or co-managed) in Intune so MDM policy applies.
**Why:** Coexistence and precedence (`MDMWinsOverGP`) only take effect on devices Intune actually
manages; an un-enrolled device receives Group Policy only.
**Verify:** Intune → **Devices → All devices**; run `scripts\GPOPROG-Discovery.ps1` (reports Intune
coverage vs. the GPO-scoped population).
**Implement:** Configure Windows automatic enrollment (Entra → **Mobility (MDM and MAM)**); for
co-management, set the relevant workloads toward Intune. (See global requirement G5.)

## 2.3 A rationalized GPO backlog
**Description:** The Group Policy estate has been inventoried and **rationalized** — dead, duplicate,
and obsolete GPOs identified for retirement — *before* migration begins.
**Why:** Migrating an un-rationalized backlog migrates accumulated cruft and inflates conflict
surface; you migrate intent, not history. Rationalization is the program's first phase.
**Verify:** Run `scripts\GPOPROG-Discovery.ps1` (enumerates GPOs, scope, link/enabled state); confirm
a reviewed retire/keep/consolidate decision exists per GPO.
**Implement:** Use the **GroupPolicy** module export (`Get-GPO` / `Get-GPOReport`) and GPMC to review
every GPO; record a retire/keep/consolidate decision per GPO as the rationalization backlog.

## 2.4 Group Policy analytics access (for the mechanics phases)
**Description:** Access to Intune **Group Policy analytics** to import GPO backups and read per-GPO
migration-readiness and per-setting mapping.
**Why:** The program sequences the *mechanics* solution; readiness % drives which GPOs are
migrate-first (high readiness) vs. plan-handling (many unsupported settings).
**Verify:** Intune → **Reports → Group Policy analytics** loads and accepts a GPO backup import.
**Implement:** Ensure the role includes report access; produce GPO backups with
`scripts\GPOPROG-Discovery.ps1` or GPMC **Back Up All**.

## 2.5 Coexistence precedence decision (MDM wins over GP)
**Description:** A documented decision to run the transition with **MDM wins over GP** as the
precedence rule, deployed as a coexistence policy in the core-OS phase.
**Why:** Coexistence runs both authorities at once; without an explicit precedence rule, same-setting
conflicts produce evaluation loops. `MDMWinsOverGP` makes the Intune value the winner.
**Verify:** Run `scripts\GPOPROG-Validation.ps1` on a pilot device (reports `MDMWinsOverGP` state);
confirm `Coexistence Policy – MDM Wins Over GP – All Migrated` is planned/assigned.
**Implement:** Build the settings-catalog policy `Coexistence Policy – MDM Wins Over GP – All
Migrated` (the `MDM Wins Over GP` / `ControlPolicyConflict` setting) and assign it to the core-OS
pilot scope first. (See Implementation Step 3.)

## 2.6 Phase scope / wave groups
**Description:** Microsoft Entra security groups for each phase's pilot and broad scope, named to the
convention (for example `Transition Wave – Core OS – Pilot`).
**Why:** Each phase is piloted on a small scope, gated, then expanded; phase-scoped groups are how
policy is targeted phase-by-phase without bleed between phases.
**Verify:** Entra → **Groups**; or run `scripts\GPOPROG-Set-PhaseScopeTargeting.ps1` (creates/reuses
the phase scope groups).
**Implement:** Create the groups with `scripts\GPOPROG-Set-PhaseScopeTargeting.ps1`. (See global
requirement G6.)

## 2.7 Change control, coexistence window & per-phase rollback
**Description:** A change window per phase, a defined coexistence approach (both authorities managed
during transition), and a documented rollback per phase (re-scope the legacy GPO back / revert the
Intune assignment).
**Why:** The transition touches live, domain-joined production devices; each phase — especially the
security phases — must be reversible and coordinated.
**Verify:** A rollback procedure and coexistence plan are written and approved **per phase** before
that phase starts.
**Implement:** Define rollback per phase (legacy GPO stays present-but-unlinked until the phase is
confirmed), a comms plan, and the order of operations. (See global requirement G7.)

## 2.8 Stakeholder alignment on sequencing (security comes later)
**Description:** Documented agreement from leadership and the security owner that **core OS migrates
first and security controls come later**, gated.
**Why:** This is the governance backbone. Without it, internal pressure to rush security defeats the
program; the alignment is what the go/no-go gate enforces.
**Verify:** A signed sequencing decision exists naming the phase order and the gate owner.
**Implement:** Hold the sequencing alignment session; record the phase order, gate criteria, and the
program lead as gate owner before Phase 1.

---
## Checklist
- [ ] Intune licensing + Intune Administrator role
- [ ] In-scope devices enrolled / co-managed — `GPOPROG-Discovery.ps1`
- [ ] GPO backlog inventoried and rationalized (retire/keep/consolidate per GPO)
- [ ] Group Policy analytics access (for the mechanics phases)
- [ ] MDM-wins-over-GP precedence decided — `Coexistence Policy – MDM Wins Over GP – All Migrated`
- [ ] Phase scope/wave groups created — `GPOPROG-Set-PhaseScopeTargeting.ps1`
- [ ] Per-phase change control, coexistence window, and rollback approved
- [ ] Stakeholder sign-off: core OS first, security later, gated
