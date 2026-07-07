# Solution Overview

## What this is

The day a Google Workspace project goes live, the work does not end — it changes shape. Someone has
to **run** the tenant: keep policies coherent as the organization grows, add and remove users, handle
requests and incidents, watch for drift, and prove the whole thing is under control when audit season
arrives. Without a structured operating model, "day-2" degrades into firefighting: policies applied
inconsistently, admin rights handed out too broadly, no monitoring, and tribal knowledge that walks
out the door when a key admin leaves.

This solution is the **Day-2 Administration & Operations Runbook** for Google Workspace. It delivers
the **steady-state operating model** for the tenant after go-live, and it folds in the two structural
foundations that make steady-state operations possible:

1. **Organizational-unit (OU) design and configuration-policy governance** — the OU tree, how
   settings inherit down it, the documented settings baseline, and the change-control and
   config-drift discipline that keep the tenant's configuration matching its intended design.
2. **The day-2 operations runbook library** — the admin-role delegation model (least-privilege),
   monitoring/alerting and health checks, and a library of runbooks: routine SOPs, user/group/device
   lifecycle tasks, request handling, incident handling, and escalation.

The result is an operations practice that is **owned, repeatable, and auditable** from go-live
onward, rather than reinvented on every ticket.

### How it is distinct from the adjacent solutions

- It is **not** the adoption/change-management and end-user training program (that is a separate
  adoption solution) — this is what the *administrators* do to keep the service running.
- It is **not** the migration cutover operations solution (mailbox/Drive/Chat data movement, cutover
  weekend runbook) — this is what happens **after** cutover, in business-as-usual (BAU) steady state.

If you have already migrated to Google Workspace and now need to *operate* it well, this is that
solution.

## How it works

The operating model rests on four pillars, each with a corresponding section of the implementation
guide and at least one Python tool:

### 1. OU tree and policy governance
Google Workspace applies almost all service configuration (Gmail, Drive, Chat, Meet, Calendar,
security settings, Marketplace app allow-lists, and per-service on/off state) through **settings that
attach to an organizational unit** and **inherit** from parent OU to child OU unless overridden. A
deliberate OU tree is therefore the backbone of governance: it decides which populations get which
policy, and where exceptions live. This solution designs the OU tree, documents the intended
**settings baseline** per OU, and establishes the discipline to keep the live configuration matching
that baseline (change control + drift detection). Configuration groups (access groups used for
settings targeting) are covered where a policy must follow membership rather than OU placement —
verify group-based policy availability for the specific service in your tenant.

### 2. Admin-role delegation (least-privilege)
Super-admin is all-powerful and must be rare. Google Workspace ships **pre-built admin roles**
(Groups Admin, User Management Admin, Help Desk Admin, Services Admin, and others) and supports
**custom admin roles** scoped to specific privileges and, optionally, to specific OUs. This solution
defines a least-privilege delegation model: which team gets which role, scoped to which OU, so that a
help-desk agent can reset passwords but cannot alter security policy, and day-to-day work never
requires super-admin.

### 3. Monitoring, alerting, and health checks
Google Workspace exposes operational signal through the **Admin console**, the **Reports API / audit
and usage logs** (login, admin, drive, token, and other activity events), and the **alert center**
(admin.google.com → Security → Alert center) with **system-defined and admin-created alerts**. This
solution stands up a repeatable **health-check** routine and a monitoring/alerting baseline so that
security-relevant events (suspicious logins, admin privilege changes, external sharing spikes) and
service-health issues surface proactively rather than being discovered by a user complaint.

### 4. The runbook library
Everything routine becomes a named, repeatable runbook: onboarding/offboarding, group and Shared
Drive lifecycle, device actions, common request handling, incident handling (account compromise, data
exposure, mail-flow issue), and the escalation path. Runbooks are the artifact that makes operations
survivable when people change roles.

## Reference operating model

```
                    Super-admin (break-glass, rare)
                              │
        ┌─────────────────────┼─────────────────────┐
   Delegated admin roles   OU tree + policy      Monitoring +
   (least-privilege)       baseline               alerting
        │                     │                       │
   Help Desk / Groups /   Root OU                  Reports API
   Services / custom      ├── Corp                  audit + usage
   roles scoped to OUs    │   ├── Standard-Users    Alert center
        │                 │   ├── Privileged-Users  Health checks
        └────────┬────────┤   └── Service-Accounts       │
                 │        └── Contractors                │
                 ▼                 │                      ▼
         ┌───────────────── Runbook library ──────────────────┐
         │  Onboarding · Offboarding · Group/Shared-Drive     │
         │  lifecycle · Device actions · Request handling ·    │
         │  Incident handling · Escalation · Change control ·  │
         │  Config-drift review                                │
         └────────────────────────────────────────────────────┘
```

The OU tree above is an illustrative reference; the real tree is designed to your populations in the
implementation guide. Naming convention for every artifact this solution creates is
`<Purpose> – <Scope> – <Stage>`, for example `OU – Corp/Privileged-Users – Baseline`,
`Admin Role – Help Desk – Corp`, `Alert – External-Sharing-Spike – Enforce`,
`Runbook – User Offboarding – Production`.

## Deployment model

This solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
pilot-first, with explicit pass/fail gates and a documented rollback for every production change:

- **Assess** — inventory the current OU tree, per-OU settings, admin-role assignments, alert
  configuration, and existing (often undocumented) operational practices. The read-only assessment
  tool produces this baseline.
- **Design** — the target OU tree, the settings baseline per OU, the admin-role delegation matrix,
  the monitoring/alert set, and the runbook library table of contents.
- **Configure** — build the OU tree, apply the settings baseline, create the delegated admin roles,
  configure alerts, and author the runbooks.
- **Pilot** — apply to one **pilot OU** (`OU – Corp/Standard-Users – Pilot`) and one help-desk team;
  exercise the onboarding, offboarding, request, and incident runbooks against pilot users only.
- **Validate** — confirm the pilot passes the gates (settings match baseline, drift detector clean,
  alerts fire on test events, runbooks executed successfully with no super-admin required).
- **Expand** — roll the OU/policy structure, roles, alerts, and runbooks to the rest of the
  organization, then hand to the operations team as owned BAU.

## Benefits

- **No firefighting.** Every routine task has a named runbook; every population has a defined policy.
- **Least-privilege by design.** Day-to-day admin work never touches super-admin.
- **Auditable.** Configuration matches a documented baseline; drift is detected; admin and access
  events are monitored and retained via the Reports API.
- **Survivable.** Operations knowledge lives in runbooks, not in one person's head.
- **Self-guided.** Delivered as exact steps plus read-only/dry-run Python tooling, at a fraction of
  the cost of a consulting engagement.

## Limitations and boundaries

- The **Google Admin console and Cloud Identity** steps are authored from Google's public
  documentation. Where a capability is in preview or is rolling out (some group-based policy
  targeting, newer alert types, certain Gemini/AI admin controls), it is flagged **"verify in your
  tenant."**
- **Regulatory and compliance interpretation** — whether a control satisfies CMMC/NIST 800-171,
  ITAR/DFARS applicability, or an assessor's determination — is **deferred to your compliance, legal,
  and assessment (C3PAO) partners.** This solution provides the technical control configuration,
  monitoring, and evidence; it does not make certification determinations.
- The Python tools automate **assessment, validation, health reporting, and drift detection**; they
  are **read-only or dry-run by default** and never contain credentials. They complement, not
  replace, the documented Admin console procedures.
- Exact **audit-log field names, alert types, and admin-role privileges** evolve; the solution names
  the current documented ones and directs you to verify against your tenant's current console.
