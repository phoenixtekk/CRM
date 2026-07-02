# Best Practices

These practices keep the runbook library working as intended: **consistent triage**, **complete
evidence capture**, and **clean escalation**. They apply across every runbook.

## Consistent triage
- **Scope before cause.** In intake, always establish whether the issue affects one user, one
  device, one location, or the whole fleet. A fleet-wide symptom is almost always policy/targeting
  or a service outage — chasing it on a single device wastes time.
- **Always start at the triage tree.** Don't skip to a fix you "have a feeling about." The tree
  exists so two technicians reach the same branch from the same symptoms.
- **Run checks in order and stop at the cause.** Checks are ordered cheapest/least-disruptive
  first. When a check identifies the cause, stop — you don't need to run the rest.
- **One runbook at a time, with clear hand-offs.** If a check reveals the real issue belongs to
  another category (e.g. an "app" problem is really a sign-in problem), switch to that runbook and
  note why.
- **Least-disruptive fix first.** Sync → local retry → targeted config/group change → reinstall →
  (only with approval + backup) re-enroll/reset. Never jump straight to a destructive action.

## Evidence capture
- **Capture as you go, not at the end.** Screenshot the failing signal at the moment you see it —
  sign-in log reason, compliance setting, error code, `dsregcmd` output.
- **Use the runbook's evidence list as a checklist.** Every runbook ends with an explicit
  *evidence to collect* list; treat it as the definition of "documented."
- **Record IDs and timestamps, not just descriptions.** Intune device name/serial, event IDs,
  `0x…` error codes, and exact times let the next person (or an escalation target) continue without
  redoing your diagnosis.
- **Prefer read-only tooling for capture.** Use DESKSUP-Discovery/Validation/Report and the Intune
  portal to gather state; they don't change anything and are safe to run repeatedly.
- **Never capture secrets.** Don't screenshot passwords, tokens, TAPs, or full BitLocker keys into
  a ticket.

## Escalation
- **Escalate at the gate, not before or after.** Each runbook names the exact conditions that mean
  *stop and hand off*. Escalating earlier drops ownership; escalating later delays the user.
- **Escalate with a complete package.** Hand over the collected evidence, what you already tried,
  and the specific decision or right the target needs to supply. A good escalation is one the
  receiver can act on without a follow-up question.
- **Route to the right team.** Identity/security for accounts, MFA, and Conditional Access;
  desktop/endpoint engineering for OS, drivers-by-policy, enrollment, and re-image; network team for
  upstream connectivity; app owner/vendor for packaging or product-internal faults; hardware/warranty
  for physical repair.
- **Own the ticket across the hand-off.** Escalation is a transfer of *action*, not of
  *responsibility for the user's experience* — track it to resolution.

## Live-environment safety
- **Default to `-WhatIf`.** The remediation and scope-targeting scripts ship WhatIf-first; review
  the planned change before removing it, and run destructive-adjacent actions on a **pilot** device
  or group first.
- **Confirm data backup before anything that touches user data.** Profile rebuilds, re-enrollment,
  resets, and re-imaging require owner approval and confirmed backup — no exceptions.
- **Change targeting, not the endpoint, to fix "missing policy/app."** If a device isn't getting a
  policy or app, fix its Entra group membership rather than sideloading or forcing settings locally.

## Keeping the library healthy
- **Feed corrections back.** When a runbook step is wrong (a menu moved, an object renamed, a check
  no longer shows what's described), update the runbook so the next technician benefits. Consistency
  is only maintained if the library stays current.
- **Watch the trend.** Use DESKSUP-Report over time — a rising category is a signal to add or refine
  a runbook, not just to work more tickets.
