# 7. Best Practices — SharePoint & OneDrive Lifecycle Policies (Microsoft Purview)

- **Start retain-only; enable deletion deliberately.** The single most important discipline: create the
  policy so it **retains** and deletes nothing, validate that, and enable the **delete** action only after
  approval. Deletion after the window is irreversible — never let it be the default.
- **The schedule is a records determination, not a technical default.** How long content is kept, what is
  a record, and what may be deleted are owned by records-management/compliance/legal. Configure the rules
  the schedule dictates; capture the determinations and approvers in `Lifecycle Schedule – Map`.
- **Pilot on a limited scope before all locations.** Prove the policy on `SPO Lifecycle – Pilot Scope –
  Stage1` — a small set of sites / an adaptive subset — before scoping to the estate. Retention behavior
  and hold-library growth are easier to reason about on a bounded scope.
- **Understand the Preservation Hold Library before you test.** Deleted-but-retained content lands in the
  hold library, so "I deleted it and it's still there" is retention working, not a bug. Account for the
  hold library's **storage growth** in capacity planning.
- **Prefer adaptive scopes for drift — where licensed.** An adaptive scope (rule over site/user
  properties) keeps coverage current as sites and accounts come and go; a static scope must be maintained
  by hand. Where adaptive scopes aren't licensed, use static and **schedule a review** to catch drift.
- **Coordinate with eDiscovery holds and existing labels.** A location can be under a retention policy, a
  retention label, and an eDiscovery hold at once; the most restrictive wins. Check for overlapping holds
  before enabling deletion so you don't fight a hold you didn't know about.
- **Retention policies vs retention labels — use the right tool.** Location-level lifecycle is a policy
  job (this solution); item-level classification and records/file-plan work are labels. Deploy them
  together, but don't try to do item-level records management with a location policy.
- **Communicate before enabling deletion.** Users notice when old content starts disappearing on
  schedule. Tell site owners what will be cleaned up and when before the delete action goes live, so
  cleanup reads as governance, not data loss.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write behind `-WhatIf` → `-Commit`; the delete action behind its own explicit `-Action
  EnableDelete -Commit`. Sign in interactively; no credentials or secrets in a script or a document.
- **Re-report on a schedule.** New sites and OneDrive accounts appear constantly. Re-run
  `DLCSPO-Report.ps1` periodically so `Lifecycle – Coverage Report` stays a live evidence artifact and
  catches locations that fell outside the scope.
- **Keep determinations with their owners.** The solution configures and evidences the lifecycle; the
  schedule, the keep/delete decision, and any legal hold are determinations for records-management,
  compliance, and legal. Keep that separation explicit so a technical rule is never mistaken for a
  records ruling.
