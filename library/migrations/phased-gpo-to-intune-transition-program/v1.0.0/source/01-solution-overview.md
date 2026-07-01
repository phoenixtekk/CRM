# 1. Solution Overview — Phased GPO-to-Intune Transition Program & Sequencing Roadmap

## What this solution is

This is a **program** — a strategy, sequencing, and governance roadmap — for moving an organization
off **Group Policy (GPO)** and onto **Microsoft Intune** in a deliberate, gated order. It is not a
single wizard and it is not the per-setting migration mechanics. It is the **operating model** that
decides *what moves in what order*, *when each phase is safe to start*, and *how the whole transition
is governed* so it stays stable while two policy authorities (Group Policy and Intune/MDM) coexist on
the same fleet.

The program orchestrates the transition through a fixed sequence of phases:

1. **Rationalize** the GPO backlog — retire dead, duplicate, and obsolete policy before migrating
   anything, so you migrate intent, not accumulated cruft.
2. **Core OS first** — migrate the foundational, low-blast-radius OS settings (device restrictions,
   user experience, baseline configuration) and establish the coexistence/precedence guardrails.
3. **Stabilize** — let the fleet settle on the new authority, prove there are no conflicts or
   evaluation loops, and pass a stabilization gate before touching anything sensitive.
4. **Security controls — later, and in order** — only after the foundation is stable, sequence the
   higher-risk control families (for example the firewall first, then application control), each as
   its own gated phase with its own validation and rollback.
5. **Expand and decommission** — extend each validated phase from pilot to broad scope, then scope
   the legacy GPOs away from migrated devices, one authority per setting.

## Why sequencing is the whole point (the *why* lives here)

The order is not cosmetic — it is the difference between a clean transition and an outage:

- **A transition is a coexistence problem, not a copy problem.** During the move, the same device can
  receive settings from *both* Group Policy and Intune. Without a precedence rule and a clean
  sequence, the two authorities fight: one sets a value, the other overrides it, the device flips
  back and forth, and you get conflicts and evaluation **loops**.
- **Core OS settings are low blast radius; security controls are high blast radius.** A wrong device
  restriction is an annoyance. A wrong firewall rule or application-control policy applied while two
  authorities are still fighting can **lock users out of the network or block the apps they need to
  work** — and it can do it fleet-wide.
- **You cannot validate a control on an unstable foundation.** If precedence and conflict governance
  are not proven first, you cannot tell whether a security control "failed" because the control is
  wrong or because Group Policy is still overriding it. Stabilizing the foundation first makes every
  later phase *diagnosable*.

### The anti-pattern this program exists to prevent

> **"Internal pressure to migrate security too quickly."** Once a migration is underway, there is
> almost always pressure — from leadership, from security, from the team itself — to "just move the
> firewall and app control too, while we're in there." This is the single most common way a
> GPO-to-Intune transition breaks. Security controls migrated **before** the core OS is clean and
> stable land on top of unresolved precedence conflicts and produce lockouts and loops. **This
> program's job is to hold the line: security controls do not start until the core OS phase has
> passed its stabilization go/no-go gate.** The gate is the governance mechanism that converts
> "pressure to rush" into "evidence we are ready."

## Coexistence & precedence (MDM wins over GP)

The transition runs both authorities at once across the fleet, so precedence must be explicit:

- **MDM wins over GP.** Windows exposes the `MDMWinsOverGP` control (the `ControlPolicyConflict`
  policy, configured in Intune as the `MDM Wins Over GP` setting). With it enabled, where Intune and
  Group Policy set the **same** setting, the **Intune (MDM) value wins**. This is the precedence rule
  for the entire transition.
- **One authority per setting, end-state.** Coexistence is a *transitional* state, not the goal. As
  each setting area migrates and validates, the legacy GPO for that area is **scoped away** from
  migrated devices (security filter / unlink), so the end-state is exactly one authority per setting.
- **Precedence is necessary but not sufficient.** The `MDMWinsOverGP` rule resolves *same-setting* conflicts; it does
  not resolve settings that exist only in GPO, or two GPOs fighting each other, or a security control
  applied before its dependencies. Sequencing and rationalization handle those.

## Conflict and loop guardrails

The program builds in guardrails so coexistence does not degrade into churn:

- **Migrate by area, scope away the legacy GPO for that area** — never leave both authorities setting
  the same area indefinitely.
- **Set precedence before you migrate settings** — `MDMWinsOverGP` is deployed as part of the
  core-OS phase, not after, so the very first migrated settings already have a defined winner.
- **Watch for evaluation loops** — a setting that flips between a GPO value and an Intune value on
  successive policy cycles is the signature of a loop; the validation script flags it and the
  remediation script resolves precedence.
- **Never let two phases touch the same setting area at once** — the phase plan assigns each setting
  area to exactly one phase.

## Go/no-go gates per phase

Every phase boundary is a **go/no-go gate**. A phase does not start until the previous phase has
passed its gate; security phases do not start until the stabilization gate is green. Each gate is a
short, named checklist (see the Implementation and Testing guides) covering: precedence in effect, no
unresolved conflicts/loops on the in-scope scope group, parity validated for the phase's settings,
and rollback confirmed available. The gate is owned by the program lead, signed off with the
stakeholders, and recorded — it is the mechanism that keeps the transition honest under pressure.

## The program operating model (roles & KPIs)

| Role | Responsibility |
|---|---|
| Program lead | Owns the phase plan, the go/no-go gates, and the decision to advance or hold. |
| Endpoint / Intune admin | Builds and assigns the Intune policies; runs the migration mechanics per phase. |
| Group Policy / AD admin | Rationalizes the GPO backlog; scopes legacy GPOs away as areas migrate. |
| Security owner | Defines the security-control phases (firewall, app control) — and accepts they come *later*. |
| Change manager | Schedules windows, owns comms and rollback approval per phase. |

Track the transition with these KPIs (the report script feeds them):

- **Phase completion** — phases passed vs. planned.
- **Precedence coverage** — % of in-scope devices with `MDMWinsOverGP` in effect.
- **Open conflicts / loops** — count on the current in-scope scope group (target: zero before the gate).
- **GPO rationalization** — GPOs retired/consolidated vs. baseline backlog.
- **Coexistence cleanup** — setting areas with legacy GPO scoped away (one-authority-per-setting %).

## How this complements the rest of the catalog (no duplication)

- It **complements, does not duplicate**, the **Group Policy to Intune Settings Migration** solution,
  which provides the per-setting **mechanics** (export, Group Policy analytics, settings catalog,
  ADMX import, parity). This program decides the **order and governance** of those mechanics.
- It **complements, does not duplicate**, the **firewall** and **application-control** migration
  solutions — those are the per-control **products**. This program decides **when** each is safe to
  start and **how** it is gated within the overall sequence.

## Honest limitations

- **This is a program, not a same-day cutover.** A real transition runs weeks to months; the
  discipline is the value.
- **It governs the sequence; it does not replace the mechanics or per-control products.** Use it
  alongside the settings-migration and per-control solutions.
- **Coexistence is transitional.** Running both authorities indefinitely is the failure mode the
  program is designed to end, not sustain.
- **Security must wait.** The model is explicit that core OS comes first; if the organization will
  not accept sequencing, this program cannot protect the transition.

## The standard deployment model

This solution follows the standard model — **Assess → Configure → Pilot → Validate → Expand** —
applied as a phased program with named artifacts and a **go/no-go gate at every phase boundary**:

**Rationalize → Core OS (set precedence) → Stabilize (gate) → Security controls in order (gate each)
→ Expand → Decommission GPO scope.**
