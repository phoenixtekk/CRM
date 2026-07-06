# Best Practices

These practices keep the runbook library working as intended and turn it into a genuine
**enablement kit**: **documentation** that stays current, **training** that spreads the knowledge
off one engineer's head, and **feature evaluation** that adopts new Intune/Apple capabilities
deliberately. They apply across every runbook.

## Documentation

- **Capture as you go, not at the end.** Screenshot the failing signal at the moment you see it —
  compliance setting, sign-in log reason, `fdesetup status`, `profiles status` output, error code.
- **Use the runbook's evidence list as a checklist.** Every runbook ends with an explicit *evidence
  to collect* list; treat it as the definition of "documented."
- **Record IDs, serials, command output, and timestamps** — not just descriptions. The Intune device
  name/serial, the exact non-compliant setting, `0x…`/exit codes, and precise times let the next
  person (or an escalation target) continue without redoing your diagnosis.
- **Prefer read-only tooling for capture.** Use MACRUN-Discovery/Validation/Report and the Intune
  portal to gather state; they don't change anything and are safe to run repeatedly.
- **Never capture secrets.** Do **not** screenshot or paste **FileVault recovery keys**, passwords,
  bootstrap-token material, or full VPP/ADE tokens into a ticket. Reference *that* a key is escrowed,
  never its value.
- **Keep the runbooks themselves current.** When a menu moves, a command is deprecated, or Apple/Intune
  changes a behavior, edit the affected runbook the same day. macOS changes faster than Windows —
  a stale runbook is worse than none because it sends technicians down a wrong path.

## Training and enablement

- **Onboard new technicians on the operating model first.** Teach intake → triage → diagnose →
  resolve/escalate → document once; it applies to every runbook, so a new hire is productive after
  learning the shape, not all seven runbooks at once.
- **Pair the first runs.** Have a new technician shadow, then run a live-but-supervised
  enrollment, an SSO setup, and a compliance fix on a pilot Mac before working real Mac tickets solo.
- **Rehearse the incident-response runbook off-hours.** Runbook 7 (FileVault lock-out / SecureToken)
  is the one you cannot afford to improvise under pressure. Walk it on a test Mac — recover with an
  escrowed key, rotate it, and confirm — so the steps are muscle memory before a real lock-out.
- **Build a short internal knowledge base from the evidence.** Real tickets, redacted of secrets,
  become the best training material — they show the checks producing real signals.
- **Cross-train beyond one engineer.** The whole point of the library is that Mac knowledge stops
  living in one person's head. Rotate who runs enrollment, SSO, and IR so no single person is the
  bus factor.

## Feature evaluation (adopting new capabilities deliberately)

- **Track the release notes as a standing task.** Watch Intune "What's new" and Apple's macOS/ABM
  release notes. New capabilities (a new Platform SSO mode, a new declarative-management setting, a
  new compliance control) are opportunities — but only after evaluation.
- **Evaluate before you enable.** For any new feature, ask: what problem does it solve for us, what
  does it change for the user, what are the prerequisites (macOS version, hardware, licensing), and
  what is the rollback? Write that down before touching production.
- **Pilot every feature on the pilot group first.** Enable it for the pilot Entra group, run the
  relevant Testing gate, and confirm it behaves as documented on real hardware before fleet rollout —
  Platform SSO and FileVault changes especially.
- **Flag uncertainty honestly.** Where a feature's behavior is version-dependent or the documentation
  is thin, say so in the runbook and verify against the vendor docs rather than guessing. (This
  library flags several such spots — Platform SSO options, SecureToken grants.)
- **Add a runbook when a new feature becomes routine.** Once a new capability is adopted and
  supported repeatedly, give it its own runbook (or a branch of an existing one) so support stays
  consistent.

## Escalation

- **Escalate at the gate, not before or after.** Each runbook names the exact conditions that mean
  *stop and hand off*. Escalating earlier drops ownership; escalating later delays the user.
- **Escalate with a complete package.** Hand over the collected evidence, what you already tried, and
  the specific decision or right the target needs to supply. A good escalation is one the receiver can
  act on without a follow-up question.
- **Route to the right team.** Identity/security for accounts, MFA, Conditional Access, and Platform
  SSO design; endpoint engineering for ADE tokens, enrollment, FileVault/SecureToken recovery, and
  re-enroll; app owner/vendor for packaging or product-internal faults; the ABM owner for ABM/VPP
  token and Apple Configurator work.
- **Own the ticket across the hand-off.** Escalation is a transfer of *action*, not of
  *responsibility for the user's experience* — track it to resolution.

## Live-environment safety (Mac specifics)

- **FileVault key before anything FileVault-adjacent.** Confirm the recovery key is escrowed
  **before** any action that could touch encryption, the unlock account, or the key. No exceptions.
- **Default to `-WhatIf`.** The Remediation and Set-ScopeTargeting scripts ship WhatIf-first; review
  the planned change before removing it, and run any state change on a **pilot** Mac or group first.
- **Confirm data backup before anything destructive.** Erase/reset, re-enrollment, and account
  rebuilds require owner approval **and** confirmed backup **and** a confirmed escrowed recovery key.
- **Change targeting, not the endpoint, to fix "missing policy/app."** If a Mac isn't getting a
  profile or app, fix its Entra group membership rather than sideloading or forcing settings locally.

## Keeping the library healthy
- **Feed corrections back.** When a runbook step is wrong (a menu moved, a command deprecated, a
  check no longer shows what's described), update the runbook so the next technician benefits.
- **Watch the trend.** Use MACRUN-Report over time — a rising category is a signal to add or refine a
  runbook (or to evaluate a feature that would prevent the tickets), not just to work more tickets.
