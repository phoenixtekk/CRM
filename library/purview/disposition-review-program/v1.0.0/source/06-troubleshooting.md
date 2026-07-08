# 6. Troubleshooting

Common failure modes when standing up and running a disposition review program in Microsoft Purview, with
causes and resolutions. Most disposition behaviour is **eventually consistent** — allow for service
propagation (hours to days) before treating slow behaviour as a fault. **No fix here approves, extends, or
deletes a disposition** — those are reviewer (records/legal) actions in the portal.

---

## Connection, licensing & roles

**`Connect-IPPSSession` fails or `Get-ComplianceTag` errors.**
- Cause: module missing/old, non-modern-auth account, or wrong cloud endpoint.
- Fix: install/update **ExchangeOnlineManagement**; sign in with an MFA-capable admin; in GCC/GCC High/DoD
  pass the correct `-ConnectionUri`. Run `Resolve-DispositionScope.ps1` to confirm health and cloud.

**The label editor doesn't offer "disposition review" (or multi-stage).**
- Cause: the tenant lacks the required compliance entitlement, or multi-stage is not available on that plan.
- Fix: verify the compliance plan/add-on (2.1) in the M365 admin center; confirm **Records management** is
  visible and that a retain-then-delete label offers review. Multi-stage is newer and plan-dependent —
  **verify availability in your tenant**; fall back to single-stage where multi-stage is not offered.

**Admin can create labels but can't manage disposition, or vice versa.**
- Cause: role split not applied — creating labels needs Records Management / Compliance Administrator;
  seeing the queue needs **Disposition Management**.
- Fix: grant the configuring admin the least-privilege records/compliance role and reviewers **Disposition
  Management** (2.3) — deliberately separate, per role-separation best practice.

## Reviewers can't see or act on the queue

**A reviewer opens Records management → Disposition and sees nothing / no queue.**
- Cause: the reviewer is **not in the Disposition Management role group** (most common), or no items have
  reached expiry yet, or the reviewer isn't a named reviewer on any expiring label.
- Fix: `Get-RoleGroupMember -Identity "Disposition Management"` and confirm the reviewer is present; add
  with `Add-RoleGroupMember` (or run `Set-DispositionReviewers.ps1 -Commit`). Confirm the reviewer is a
  reviewer on a label whose items have actually expired. Allow for propagation after adding to the role.

**A reviewer sees items they shouldn't (wrong scope).**
- Cause: the reviewer is a reviewer on more labels than intended, or a stage's reviewer group has extra
  members.
- Fix: reviewers see only the labels they are a reviewer for — audit the stage groups and the label reviewer
  lists (`Assess-DispositionPosture.ps1`); tighten the mail-enabled group membership.

**Reviewers aren't getting notification / reminder email.**
- Cause: reviewer has no mailbox, notifications/reminders are disabled in disposition settings, or mail is
  filtered.
- Fix: confirm each reviewer is mailbox-enabled (2.4); check the disposition notification/reminder settings
  in the portal (**verify the exact setting location in your tenant** — it evolves); check mail flow/junk.

## Labels & routing

**Content is auto-deleting instead of routing to review.**
- Cause: the label is retain-then-delete **without disposition review enabled** — the exact gap this program
  closes.
- Fix: `Get-ComplianceTag` the label; if review is not configured, add it (`Set-DispositionReview.ps1`) so
  the category routes to review. `Assess-DispositionPosture.ps1` flags every auto-delete-no-review label.

**`New-/Set-ComplianceTag -MultiStageReviewProperty` is rejected or the stages don't take.**
- Cause: the multi-stage property **shape/name has changed across releases**, the plan doesn't support
  multi-stage, or the JSON depth/keys don't match the current schema.
- Fix: run `Set-DispositionReview.ps1 -WhatIf` to **echo** the property object and compare it against
  current Microsoft docs and your tenant before committing; confirm the plan supports multi-stage; adjust
  the JSON to the current schema. Where multi-stage isn't available, use single-stage `-ReviewerEmail`.

**The disposition label isn't appearing for pilot users / not auto-applying.**
- Cause: label policy not published to the pilot locations, still propagating, or the auto-apply condition
  doesn't match.
- Fix: confirm the `Label Policy – Disposition-Publish – Pilot` (or `-AutoApply`) policy is scoped to the
  pilot locations and enabled; allow propagation (hours to days); verify the `-ContentMatchQuery` matches
  test content.

## Disposition cycle & evidence

**An item reached expiry but never entered the Disposition queue.**
- Cause: propagation latency, the label doesn't actually have review enabled, or the item is under a **legal
  hold** (hold overrides disposition).
- Fix: allow time; re-confirm the label's review config (T3); check whether the item is on hold — held
  content is exempt from disposal and stays out of the disposition path (legal/eDiscovery owns holds, 2.6).

**Multi-stage item disposed before the final stage (or didn't advance).**
- Cause: mis-configured stage order, or extend/relabel not behaving as expected.
- Fix: re-verify stage order in `Get-ComplianceTag`; disposal must occur **only after the final stage** —
  re-run T8. If a stage isn't advancing, confirm that stage's reviewers are in Disposition Management and
  are acting on the correct item.

**No proof of disposal / audit evidence after a disposition completed.**
- Cause: looking in the wrong place — disposition items aren't enumerable via a supported cmdlet.
- Fix: export the **disposition record / proof of disposal** from the portal **Records management →
  Disposition** area and corroborate with `Search-UnifiedAuditLog`. `Get-DispositionEvidenceReport.ps1`
  compiles the configuration and points to these sources; the item-level proof lives in the portal export +
  audit log, not in a cmdlet inventory.

**The evidence report disagrees with what I see in the portal.**
- Cause: stale run (propagation), or the report is reading a different scope than expected.
- Fix: re-run `Get-DispositionEvidenceReport.ps1` after propagation; confirm the labels/scope it read match
  the pilot/production scope; the report reflects **configuration** — item-level truth is the portal export.

## Cloud & latency

**GCC / GCC High / DoD paths or cmdlets differ.**
- Cause: Government clouds use different portal URLs (`*.office365.us`) and connection endpoints, and some
  features differ.
- Fix: use the correct `Connect-IPPSSession -ConnectionUri`, verify portal paths and disposition/multi-stage
  availability in your cloud — do not assume Commercial parity.

**Everything is slow / a pilot cycle isn't completing.**
- Cause: normal eventual consistency — application, expiry, queue entry, notification, and disposal run on
  service timers.
- Fix: use **short-duration disposable test labels** so expiry occurs within the pilot window; allow hours
  to days for each transition; never judge a cycle in the first minutes.
