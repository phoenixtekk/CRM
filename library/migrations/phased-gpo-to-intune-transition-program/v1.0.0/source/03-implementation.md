# 3. Implementation Guide — Phased GPO-to-Intune Transition Program

This is the **program runbook**. It follows the standard model — **Assess → Configure → Pilot →
Validate → Expand** — applied as a sequenced, gated program. GPO inventory/export is done in the
**Group Policy Management Console (GPMC)** on a domain-joined admin workstation; everything else is in
the **Microsoft Intune admin center** (`https://intune.microsoft.com`) and **Microsoft Entra**
(`https://entra.microsoft.com`).

> **Scope boundary (read first):** this program governs the **sequence and the gates**. The per-setting
> migration **mechanics** (Group Policy analytics, settings catalog, ADMX import, per-setting parity)
> live in the **Group Policy to Intune Settings Migration** solution; the per-control build-outs live
> in the **firewall** and **application-control** migration solutions. This runbook says *what order*
> they run in and *when each is safe to start* — it does not re-document those mechanics.

> **Naming convention (mandatory, reused verbatim):** every created artifact is
> `<Purpose> – <Scope> – <Stage>`. **Scope** = `Core OS | Firewall | App Control | All | Identity`;
> **Stage** = `Source` (GPO) | `Target` (Intune) | `Program`. Canonical artifacts:
> `Transition Wave – <Scope> – Pilot`, `Transition Wave – <Scope> – Broad`,
> `Coexistence Policy – MDM Wins Over GP – All Migrated`,
> `Phase Gate Checklist – <Scope> – Program`, `Rationalization Backlog – All – Source`.

---

## The phase sequence (do not reorder)

| # | Phase | Goal | Gate to advance |
|---|---|---|---|
| 0 | **Rationalize** | Retire/consolidate the GPO backlog; baseline both sides. | Rationalization backlog signed off. |
| 1 | **Core OS — set precedence + migrate foundation** | Deploy `MDMWinsOverGP`; migrate low-blast-radius OS settings on a pilot. | Precedence in effect; core-OS parity validated on pilot. |
| 2 | **Stabilize** | Prove no conflicts/loops; expand core OS to broad. | **Stabilization gate** — zero open conflicts/loops on broad core-OS scope. |
| 3 | **Security control A — Firewall** | Only after Phase 2 passes: sequence the firewall migration, gated. | Firewall parity validated; no lockouts on pilot, then broad. |
| 4 | **Security control B — App control** | Only after Phase 3 passes: sequence application control, gated. | App-control parity validated; no block-outs on pilot, then broad. |
| 5 | **Expand & decommission** | Scope legacy GPOs away from migrated devices; one authority per setting. | All phases passed; legacy GPOs unlinked; evidence archived. |

> **The line the program holds:** Phases 3 and 4 **do not start** until the Phase 2 stabilization
> gate is green — regardless of internal pressure to "move security too." The gate, not the pressure,
> decides.

---

## Phase 0 — Rationalize (Assess)

**Goal:** migrate intent, not accumulated cruft; baseline both authorities.

1. **Inventory the GPO estate.** Run the read-only `scripts\GPOPROG-Discovery.ps1` on a domain-joined
   admin workstation — it enumerates every GPO (scope, link state, enabled state) via the
   **GroupPolicy** module, reports the `MDMWinsOverGP` precedence state, and reports Intune coverage
   of the in-scope population.
2. **Rationalize.** For each GPO record a **retire / keep / consolidate** decision into
   `Rationalization Backlog – All – Source`. Retire dead/duplicate/obsolete policy *before* migrating.
3. **Group settings into phases.** Assign every *kept* setting area to exactly one phase: foundational
   OS settings → Phase 1 (Core OS); firewall → Phase 3; application control → Phase 4. **No setting
   area belongs to two phases.**
4. **Export for the mechanics.** Produce GPO backups/XML (the script's export, or GPMC **Back Up
   All**) as the input for Group Policy analytics in the later mechanics phases — and as your retained
   rollback source.

**Exit gate (Phase 0):** a signed `Rationalization Backlog – All – Source`, a per-phase setting-area
assignment, and the Intune-coverage baseline.

---

## Phase 1 — Core OS: set precedence, then migrate the foundation (Configure + Pilot)

**Goal:** establish the precedence rule, then migrate the lowest-blast-radius settings on a pilot.

### Step 1 — Build the phase scope groups
Run `scripts\GPOPROG-Set-PhaseScopeTargeting.ps1` to create (idempotently) the Entra security groups
for this phase: `Transition Wave – Core OS – Pilot` (a few representative devices) and
`Transition Wave – Core OS – Broad`. Reuse these names verbatim in every assignment.

### Step 2 — Confirm enrollment & coverage
Run `scripts\GPOPROG-Discovery.ps1` and confirm the pilot devices are Intune-managed (precedence and
migrated settings only apply to managed devices).

### Step 3 — Deploy the precedence policy FIRST (`MDMWinsOverGP`)
Set the winner *before* migrating settings, so the very first migrated settings already have a defined
authority:
1. Intune → **Devices → Configuration → Create → New policy → Windows 10 and later → Settings
   catalog**.
2. Search **MDM Wins Over GP** (the `ControlPolicyConflict` setting) and set it so **MDM wins**.
3. Name it `Coexistence Policy – MDM Wins Over GP – All Migrated`.
4. **Assignments → Add groups →** `Transition Wave – Core OS – Pilot` (extended to broad in Phase 2).
   **Create**.

### Step 4 — Migrate the core-OS settings (via the mechanics solution)
Using the **Group Policy to Intune Settings Migration** mechanics (Group Policy analytics → settings
catalog / imported ADMX), migrate **only the Phase-1 core-OS setting areas**. Name the resulting
configuration `Settings Catalog – Core OS – Target` and assign it to `Transition Wave – Core OS –
Pilot`. (This program does not re-document the mechanics — it scopes them to the core-OS areas only.)

### Step 5 — Scope the legacy core-OS GPO away from the pilot
As each core-OS area applies in Intune, **security-filter / unlink** the corresponding legacy GPO for
the pilot devices so there is one authority per migrated area (leave the GPO present-but-unlinked for
rollback).

### Step 6 — Validate the core-OS pilot
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**).
2. Run `scripts\GPOPROG-Validation.ps1 -Phase "Core OS"` → confirms `MDMWinsOverGP` is in effect,
   reports applied MDM settings, and flags any same-setting conflicts or flip/loop signatures for the
   phase.
3. Run `scripts\GPOPROG-Report.ps1` → phase status + conflict report.
4. Complete the **Testing Guide** core-OS gate. **Do not advance until the Phase-1 gate passes.**

**Exit gate (Phase 1):** `MDMWinsOverGP` ENABLED on pilot; core-OS parity validated; zero unresolved
conflicts/loops on the pilot scope.

---

## Phase 2 — Stabilize (Validate + Expand core OS) — THE security go/no-go gate

**Goal:** prove the foundation is stable on the broad fleet before any security control is touched.

1. **Expand precedence + core OS to broad.** Add `Transition Wave – Core OS – Broad` to
   `Coexistence Policy – MDM Wins Over GP – All Migrated` and to `Settings Catalog – Core OS – Target`.
   Move devices into the broad group in waves.
2. **Scope legacy core-OS GPOs away** from the broad migrated devices (still present-but-unlinked for
   rollback).
3. **Stabilization soak.** Let the broad scope run for a defined soak period (at least one full policy
   refresh cycle, ideally several) so conflicts/loops have time to surface.
4. **Validate broad.** Run `scripts\GPOPROG-Validation.ps1 -Phase "Core OS"` and
   `scripts\GPOPROG-Report.ps1` across the broad scope. The conflict count must be **zero** and no
   loop signatures present.
5. **Hold the stabilization gate.** This is the program's central go/no-go. It passes **only** when:
   precedence is in effect fleet-wide, core-OS parity is validated, and there are **zero** open
   conflicts/loops on the broad core-OS scope. The program lead signs off `Phase Gate Checklist –
   Core OS – Program` with the stakeholders.

> **Anti-pattern guard:** if there is pressure to start firewall or app-control migration before this
> gate is green, the answer is **no**. Security controls layered on an unstable foundation produce
> lockouts and loops. The gate is the evidence that converts "we feel ready" into "we are ready."

**Exit gate (Phase 2 — the security go/no-go):** zero conflicts/loops on broad core OS; precedence
fleet-wide; `Phase Gate Checklist – Core OS – Program` signed. Only now may Phase 3 begin.

---

## Phase 3 — Security control A: Firewall (gated)

**Goal:** sequence the firewall migration *after* the foundation is stable, behind its own gate.

1. **Build the phase scope groups:** `scripts\GPOPROG-Set-PhaseScopeTargeting.ps1 -Phase "Firewall"`
   → `Transition Wave – Firewall – Pilot` and `Transition Wave – Firewall – Broad`.
2. **Run the firewall migration** using the dedicated **firewall migration** solution (this program
   does not re-document its mechanics). Name the resulting Intune policy `Endpoint Security – Firewall
   – Target` and assign to `Transition Wave – Firewall – Pilot`.
3. **Scope the legacy firewall GPO away** from the firewall pilot devices (present-but-unlinked for
   rollback).
4. **Validate the firewall pilot** — run `scripts\GPOPROG-Validation.ps1 -Phase "Firewall"` and
   `scripts\GPOPROG-Report.ps1`; confirm no precedence conflicts and — critically — **no network
   lockouts** (users can still reach what they need). Complete the Testing Guide firewall gate.
5. **Expand to broad** only after the pilot passes; re-validate the broad scope.

**Exit gate (Phase 3):** firewall parity validated; zero conflicts/loops; no lockouts on pilot then
broad; `Phase Gate Checklist – Firewall – Program` signed.

---

## Phase 4 — Security control B: Application control (gated)

**Goal:** sequence application control **last** among the security controls, behind its own gate.

1. **Build the phase scope groups:** `scripts\GPOPROG-Set-PhaseScopeTargeting.ps1 -Phase "App
   Control"` → `Transition Wave – App Control – Pilot` and `Transition Wave – App Control – Broad`.
2. **Run the application-control migration** using the dedicated **application-control** solution.
   Name the resulting policy `Endpoint Security – App Control – Target` and assign to `Transition Wave
   – App Control – Pilot`. Application control has the highest block-out risk — pilot in **audit/learn
   mode** first where the control supports it.
3. **Scope the legacy app-control GPO away** from the app-control pilot devices (present-but-unlinked).
4. **Validate the app-control pilot** — run `scripts\GPOPROG-Validation.ps1 -Phase "App Control"` and
   `scripts\GPOPROG-Report.ps1`; confirm no precedence conflicts and **no block-outs of required
   apps**. Complete the Testing Guide app-control gate.
5. **Expand to broad** only after the pilot passes (and after any audit-mode learning is reviewed);
   re-validate the broad scope.

**Exit gate (Phase 4):** app-control parity validated; zero conflicts/loops; no required-app
block-outs on pilot then broad; `Phase Gate Checklist – App Control – Program` signed.

---

## Phase 5 — Expand & decommission GPO scope

**Goal:** end coexistence — one authority per setting — under change control.

1. **Confirm all phases passed** (`scripts\GPOPROG-Report.ps1` shows every phase green and zero open
   conflicts/loops).
2. **Scope legacy GPOs away permanently** from the fully migrated fleet — but keep them
   present-but-unlinked for a defined grace period so per-phase rollback stays available.
3. **Confirm one authority per setting** — run `scripts\GPOPROG-Validation.ps1` across the fleet; no
   setting area should still be driven by both authorities.
4. **Retire the legacy GPOs** after the grace period elapses, with the AD/GPO owner under change
   control.
5. **Archive evidence** — the rationalization backlog, every `Phase Gate Checklist – <Scope> –
   Program`, and the final report — and close the program.

**Exit gate (Phase 5):** legacy GPOs retired (or unlinked through grace period); one authority per
setting confirmed; evidence archived; program closed.

---

### Order of operations
`Rationalize → Core OS (set MDMWinsOverGP first → migrate foundation → validate pilot) →
Stabilize (expand broad → soak → STABILIZATION GATE) → Firewall (gated) → App control (gated) →
Expand & decommission GPO scope`
