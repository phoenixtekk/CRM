# 6. Troubleshooting

Common failure modes when standing up and running Google Groups governance, with concrete resolutions.
Symptoms reference the named artifacts and tools from the Implementation and Testing sections.

---

## Auth, scopes & API access

**Symptom — a tool exits with `403 insufficient permissions` / `insufficientPermissions` / `Not
Authorized to access this resource`.**
- The ADC/service-account identity lacks the scope for that call. Assessment/validation need the
  **read-only** scopes (Requirement 2.6); `groups_settings_policy_helper.py --apply` needs the
  **write** scopes.
- For a **delegated service account**, the scopes must be authorized in **Admin console → Security →
  API controls → Domain-wide delegation** against the SA's client ID, *and* the SA must impersonate an
  admin who holds the Groups/Cloud Identity privilege. A missing DWD scope is the most common cause.
- Confirm the **Admin SDK API** and **Cloud Identity API** are enabled on the project.

**Symptom — `groupssettings` calls fail but Directory calls succeed.**
- The **Groups Settings API** is a separate service (`groupssettings/v1`) with its own scope
  (`apps.groups.settings`). Enable it and add the scope; a read of settings needs the scope even though
  Directory reads worked.

**Symptom — `ImportError` / `pip install google-api-python-client google-auth`.**
- The Google client libraries aren't installed in the active interpreter. Install them; the tools
  import lazily so `--help` still works without them.

## Naming/type validator failures (Gate 3/4)

**Symptom — a group is flagged `email prefix off-standard`.**
- Its local-part doesn't start with `dl-`/`sec-`/`collab-`/`dyn-`/`ext-`. Decide its type and rename the
  address to the convention (Step 3.1). Renaming an email address changes where mail is delivered — do
  it in the change window and add an alias for the old address if it was in active use.

**Symptom — a group is flagged `display name not '<Type> – <Scope> – <Purpose>'`.**
- The validator expects a three-part, en-dash-separated name. Rename in **Directory → Groups → (group)
  → group name**. If your standard legitimately uses a hyphen instead of an en dash, adjust the name to
  the exact separator your policy defines (the tool accepts either dash, but the string must have three
  parts).

**Symptom — `whoCanPostMessage=… not in policy for type …`.**
- The group's settings don't match its type row (Step 1.1). Apply the type policy:
  `groups_settings_policy_helper.py apply-settings --group <g> --type <type> --dry-run`, inspect the
  diff, then `--apply`.

## Settings that "won't stick" / apply has no effect

**Symptom — after `apply-settings --apply`, a re-check shows the old value.**
- Some Groups settings are **overridden by an Admin-console org-wide default or an OU policy** (e.g.
  external members disallowed org-wide will keep `allowExternalMembers` effectively off regardless of
  the per-group value). Reconcile the org baseline (Stage 2) with the per-group intent, or set the
  per-group override where the console allows it — **verify in your tenant** which setting wins.
- A **deprecated/renamed enum**: if the API accepts a value but it doesn't take effect, the field or
  value may have changed for your tenant version. Check the current Groups Settings API reference and
  adjust the value in the type policy.

## External-member removal breaks mail flow or collaboration

**Symptom — after scoping external membership (Step 3.6), an external partner stops receiving a
distribution, or a shared inbox thread breaks.**
- Removing an external member from a group that was silently acting as an external distribution point
  cuts that delivery. **Rollback:** re-add the removed member from the `Baseline – Groups Estate –
  Assess` record. Then decide the correct home: if the external relationship is legitimate, move it to a
  properly typed `ext-` group with an allow-listed partner domain rather than leaving external members
  on an internal group.

**Symptom — a legitimate external group can't accept partner mail after tightening.**
- Confirm the group is typed `ext-`, `allowExternalMembers=true`, the partner domain is allow-listed,
  and inbound external posting is permitted for that group. The org-wide inbound-posting restriction
  (Step 2.3) can block external senders even when membership is correct — grant the exception at the
  group level.

## Dynamic-group membership is wrong or empty

**Symptom — a `dyn-` group has fewer/more members than expected, or none.**
- The **CEL query** doesn't match, or the **source attribute is empty/stale** for the users concerned
  (Requirement 2.4). Verify the attribute (`Directory → Users`) is populated and current for a sample,
  and that the CEL expression references the right attribute path — **verify the exact CEL syntax in
  your tenant**, which is version-dependent.
- **Sync latency:** dynamic membership recomputes after directory changes; allow for propagation before
  concluding the query is wrong. **Never retire the equivalent static group until Test 7 confirms the
  computed membership matches.**

## Ownership / orphaned groups

**Symptom — the hygiene assessment keeps reporting ORPHANED groups.**
- The `OWNER` is a **suspended/deleted user**, or the group has no owner at all. Add the owner group
  `sec-groups-owners@corp.example` as `OWNER` (`groups_settings_policy_helper.py set-owner …`) and
  ensure ≥2 owners. Prefer the owner *group* so a future departure doesn't re-orphan it.

**Symptom — `set-owner --apply` fails with `memberKey not found` or a role error.**
- The owner group must **exist** first (Step 2.4) and be resolvable. Create
  `sec-groups-owners@corp.example` as a Cloud Identity security group before assigning it as OWNER.

## Security-group / Cloud Identity issues

**Symptom — a group can't be used in an IAM binding or a context where a security group is required.**
- Plain Groups-for-Business groups aren't security groups. The group must carry the **security label**,
  which requires **Cloud Identity Premium** (Requirement 2.2) and creation/labelling as a **security
  group**. Confirm the subscription, then create/label it — **verify in your tenant** whether an
  existing group can be converted or must be recreated.

## Retirement pitfalls

**Symptom — deleting a group broke mail delivery or an access grant.**
- A group was deleted before it was fully de-referenced. Follow **staged retirement** (Step 5.3):
  **suspend** (stop posting + remove from access grants) → **hold** for the rollback window → **delete**
  only after no breaks are reported. If a break occurs during the hold, **re-enable** (rollback). If the
  group is already deleted, recreate it with the same address and re-point the affected grants from the
  baseline record.

## Rate limits / large estates

**Symptom — sweeps slow down or return `rate limit exceeded` / `quotaExceeded` on a large tenant.**
- The Admin SDK enforces per-project quotas. Scope runs with `--scope` (per function/BU) and `--max` to
  stay under quota, run sweeps off-peak, and add backoff/retry if you extend the tools. The assessment
  is safe to run incrementally — it's read-only and always exits 0.
