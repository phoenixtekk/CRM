# 7. Best Practices — Android Enterprise Enrollment Troubleshooting

Field-proven habits that make enrollment failures fast to root-cause and rare to recur. They reinforce the
tree in the Diagnostic Playbook and the pass/fail discipline in the Testing Guide.

## Diagnose in the right order
- **Reproduce first, always.** Never troubleshoot from a screenshot or a ticket description alone — wipe the
  test device and reproduce the exact failure on the exact network. A fault you can't reproduce is a fault
  you can't confirm you fixed.
- **Binding before everything.** `bindStatus ≠ bound`, a missing owner account, or a stale sync produces
  almost every downstream symptom. Clear Playbook A before chasing account-add or dev-vs-prod.
- **One variable at a time.** Change one thing, re-run the reproduction, then decide. Batch changes hide which
  one worked and which one broke something else.
- **Let the symptom pick the entry node,** but keep the two universal suspects — **binding** and
  **endpoints** — in view for every symptom.

## Respect the account model
- On a **work profile**, the Google account is a **managed account added by the profile** — not a consumer
  Gmail login. Teach the service desk this: "can't add a personal Google account in the work profile" is
  usually **expected behavior**, not a fault.
- Match the **enrollment method to its path**: device-owner methods (fully managed / dedicated / corp-owned
  work profile) need a **factory-reset** device and a valid QR/token; BYOD needs Company Portal. A
  device-owner flow started on a non-reset device is a self-inflicted failure.

## Treat the network as a first-class suspect
- Test reachability **from the device's own network segment**, not from an admin workstation on a different
  VLAN — they often have different egress rules.
- **Exempt Google and Microsoft hosts from TLS/SSL inspection.** Intercepted TLS to `accounts.google.com` /
  `*.googleapis.com` breaks account add and enrollment even when the host is "reachable."
- Keep the **allowlist current** against Microsoft's and Google's **published** endpoint lists — they change.
  The shipped tool carries a documented core set and tells you to verify; do verify, per region/tenant.

## Handle high-impact changes with care
- **Binding, connector, enrollment-profile/token, and AMAPI changes can affect existing devices.** Always use
  a change window and a written rollback, and prove the fix on the pilot scope first.
- **Never switch the binding model to troubleshoot.** Account-enterprise vs Google Workspace is a deliberate,
  high-impact architectural choice — diagnose within the model the tenant already uses.
- **Do not assert re-enrollment behavior.** Whether an AMAPI change forces re-enrollment is **evolving** —
  **verify against current Microsoft guidance / your tenant** every time, and plan for re-enrollment as a
  possibility, not a surprise.

## Dev-vs-prod discipline
- When "it works in dev," **diff the two configs** before theorizing — export both snapshots and compare.
  Most "prod is haunted" tickets are a single setting, endpoint, or Conditional Access rule that differs.
- Keep a **known-good dev/reference config** so you always have something to diff prod against.

## Make it repeatable and reduce ticket volume
- Keep a **standing reproduction device** and a **pilot scope group** so every retest targets a known set.
- **Record every finding** as its named artifact (`Binding Health – Android – Baseline`,
  `Endpoint Allowlist – Android – Verified`, `Diagnostic Report – Android – <symptom>`) so the next engineer
  inherits the trail.
- Turn each root cause into a **service-desk note** (especially the account-model one) so the same class of
  ticket is answered at tier 1 next time instead of escalating.
- Run `ANDROIDDX-EnrollmentReadiness.ps1` **periodically**, not just during incidents — a stale sync or a
  drifting binding is cheaper to catch before it becomes a wave of failed enrollments.

## Automation hygiene
- Keep the tools **read-only by default**; only the scope helper writes, and it is `-WhatIf`-gated and
  idempotent. Preview with `-WhatIf` before applying.
- Connect with **least-privilege scopes**; never put credentials or secrets in scripts.
- Where a Graph resource is **beta** (the managed-store binding settings), treat property names as subject to
  change and **verify against current Microsoft Graph documentation**.
