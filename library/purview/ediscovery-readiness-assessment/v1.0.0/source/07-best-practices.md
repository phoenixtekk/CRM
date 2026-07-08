# 7. Best Practices — eDiscovery Readiness Assessment (Microsoft Purview)

Durable practices for keeping the eDiscovery capability **ready, least-privilege, and defensible** —
so the next real matter is routine, not a scramble.

## Readiness is a state you maintain, not a project you finish
- **Re-assess periodically.** Readiness drifts — people leave the role groups, licensing changes,
  new workloads appear. Re-run this assessment **quarterly** and after any tenant/licensing change,
  re-scoring R/H/S/P and updating the gap register.
- **Track the scorecard over time.** A rising number of Ready domains (and a shrinking gap register)
  is the evidence of a maturing capability; show it to legal and leadership.
- **Rehearse before you need it.** Run the **readiness proof on the test account** at least once per
  assessment cycle. A team that has placed a hold and run a search this quarter responds faster when
  a real hold lands.

## Least privilege and coverage (domain R)
- **Grant eDiscovery through the role groups, never Global Admin.** eDiscovery can read anyone's mail
  and files; operators belong in **eDiscovery Manager**, a small lead group in **eDiscovery
  Administrator** — Global Admin is not an eDiscovery role.
- **Avoid the single point of failure.** Keep **at least two** trained operators; document who does
  what. One person on leave should not stop a hold.
- **Consider compliance boundaries early.** In multi-region/multi-agency tenants, decide *before* a
  matter whether an eDiscovery team may search everyone — the boundary is a legal/HR determination
  implemented as a compliance security filter.

## Preservation you can prove (domain H)
- **Keep the unified audit log on — always.** It is the defensibility evidence; auditing off is the
  single highest-severity readiness gap. Do not disable it.
- **Prove, don't assume.** "We have holds" is not readiness; "we placed a hold on a test account,
  deleted a held item, and it survived" is. The proof is the point.
- **Cover the easy-to-miss data.** **Inactive/legacy mailboxes**, litigation-hold state, and the
  **retention-vs-hold interplay** are where preservation silently fails — inventory and verify them.
- **Understand headroom.** Know the practical limits on the number/size of holds you may run, so a
  large matter does not surprise you.

## Complete scope (domain S)
- **Remember where content really lives.** **Teams chat is stored in mailboxes**; **Teams files** and
  **M365 Group** content live in SharePoint/OneDrive. A mailbox-only mental model under-collects.
- **Account for unindexed/partially-indexed items and imported/third-party data** in the scope note —
  they do not vanish because a search missed them.
- **Map, then verify.** A written scope note is necessary but not sufficient; confirm the workloads
  are actually discoverable in the tenant.

## Process and defensibility (domain P)
- **Legal owns the determination; IT executes and evidences it.** Scope, custodians, holds, and
  production are legal/records decisions. Readiness means the **intake step** captures that sign-off
  *before* configuration — never improvise scope.
- **Name everything to a standard.** A consistent naming convention (`<Purpose> – <Matter> – <Stage>`)
  makes matters auditable and the audit trail legible.
- **Change control and rollback for holds and exports.** Even a test hold is a production change;
  every hold/export has an approver, a pilot gate, and a documented rollback.
- **Own the evidence pack.** Decide who keeps the audit trail and export reports, and for how long —
  the evidence of a defensible collection is only useful if someone retains it.

## Safe automation
- **Dry-run first, commit deliberately.** The remediation script is **`-WhatIf` by default**; read
  every previewed action before `-Commit`. Discovery/scope/validation/reporting are **read-only**.
- **Modern auth, no secrets.** Connect with `Connect-IPPSSession` / `Connect-ExchangeOnline` using
  modern auth/MFA; **never** put credentials or app secrets in scripts.
- **Keep docs and automation in lockstep.** The scripts print the same artifact names used in the
  Implementation and Testing guides — when you change a name, change it in both.

## Know the boundaries
- **Verify licensing/tenant, don't assume.** Premium (custodians/review sets/analytics/export) is
  E5-gated and the portal evolves; record the actual tier and flag version-dependent paths.
- **Government clouds differ.** GCC High / DoD use different hosts and some features lag — verify.
- **This assessment makes you ready; it does not run matters.** Operate real matters with the
  **eDiscovery Administration** solution, with legal in control of every determination.
