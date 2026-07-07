# 6. Troubleshooting — Google Cloud IAM & Least-Privilege Governance

Common failure modes when standing up the IAM governance model, and how to resolve them. Each maps back
to a step or test in the Implementation and Testing guides and reuses the named artifacts
(`IAM Governance – Pilot`, `IAM Guardrails – Org – v1`, `WIF Pool – Pilot – v1`).

---

## T1 — A team lost access after tightening bindings ("permission denied" for legitimate work)
- **Symptom:** After replacing primitive grants with least-privilege roles, a pilot team gets
  `PERMISSION_DENIED` on a task they should be able to do.
- **Cause:** The predefined/custom role in `Role Model – Org – v1` is missing a permission the workflow
  needs, or the binding is at too *low* a level (project) when the resource lives in a sibling project.
- **Resolution:** Identify the exact missing permission from the error, confirm which predefined role
  contains it (`gcloud iam roles describe roles/<role>`), and either add that predefined role or extend
  the custom role via `GCPIAM-RoleDesigner.py --apply`. If the scope is wrong, re-bind at the correct
  folder level. If access is broken for many users, **roll back** the IAM policy from the Stage-1.2
  backup (`gcloud ... set-iam-policy ...backup.json`) and re-derive the role.

## T2 — Org-policy guardrail is not blocking (a key still gets created)
- **Symptom:** Test 3 fails — `keys create` succeeds even though
  `constraints/iam.disableServiceAccountKeyCreation` is "applied."
- **Cause:** The constraint is still in **`dryRunSpec`** (logging, not enforcing), or it is set on a
  *sibling* scope that does not cover the target project, or a higher scope's policy overrides it.
- **Resolution:** Confirm the effective policy on the *project* that hosts the SA:
  `python GCPIAM-PolicyCheck.py --resource projects/PID --constraint constraints/iam.disableServiceAccountKeyCreation`.
  Promote dry-run → enforced at the correct scope
  (`... --resource folders/$PILOT_FOLDER_ID --constraint ... --enforce`), remembering org policy is
  inherited **downward** — enforce at a level that is an ancestor of the target.

## T3 — WIF workload cannot authenticate (STS token exchange fails)
- **Symptom:** The pilot workload on `WIF Pool – Pilot – v1` fails with an `invalid_target`,
  `unauthorized_client`, or "subject does not match" error; no STS event, or a rejected one.
- **Cause:** The **audience** in the workload config does not match the provider resource, the
  **attribute-mapping** or **attribute-condition** does not match the token's claims, or the
  `principalSet://` member does not match the mapped attribute value.
- **Resolution:** Re-run `GCPIAM-WIFSetup.py` **without** `--apply` to reprint the exact audience and
  workload-side config, and compare against what the workload sends. Confirm the `--allowed-attribute`
  (e.g. `attribute.repository/org/repo`) exactly matches the external token's claim, and that the OIDC
  `--issuer-uri` is the IdP's real issuer (**verify against the external IdP's docs**). Check the STS
  events: `gcloud logging read 'protoPayload.serviceName="sts.googleapis.com"'`.

## T4 — Access-review report is empty or missing Recommender flags
- **Symptom:** `GCPIAM-Review.py` produces bindings but no `recommender_flag` values, or errors on the
  Recommender call.
- **Cause:** The **Recommender API** (`recommender.googleapis.com`) is not enabled, the caller lacks
  `roles/recommender.iamViewer`, or the recommendations have not yet been generated (Recommender needs
  observation time and applies at **project** scope). Availability can be **edition-dependent — verify in
  your organization.**
- **Resolution:** Enable the API (Requirement 2.5), grant the viewer role (Requirement 2.1), and run the
  review at a **project** scope. Recommendations populate after Google has observed usage; a brand-new
  project will have none yet — re-run after the observation window.

## T5 — Custom role rejects a permission ("permission is not supported")
- **Symptom:** `GCPIAM-RoleDesigner.py --apply` fails because a listed permission cannot be used in a
  custom role.
- **Cause:** Some permissions are **not grantable in custom roles** (they are only available through
  specific predefined roles), or the permission name is mistyped / has been renamed.
- **Resolution:** Remove the unsupported permission and, if the capability is genuinely needed, grant the
  **predefined** role that carries it instead of forcing it into a custom role. Verify exact permission
  names with `gcloud iam list-testable-permissions //cloudresourcemanager.googleapis.com/projects/PID`.

## T6 — Domain-Restricted Sharing blocks a legitimate external principal
- **Symptom:** After enforcing `constraints/iam.allowedPolicyMemberDomains`, a needed partner /
  cross-org service account can no longer be granted a role.
- **Cause:** The allow-list holds only your **customer IDs**; the external principal's customer ID (or
  the special value for federated identities) is not included.
- **Resolution:** Do **not** disable the guardrail. Add the specific, approved external **customer ID** to
  the `allowedPolicyMemberDomains` allow-list under change control (or provision the external party via a
  WIF/federated principal instead of a direct cross-domain grant), then re-test the grant.

## T7 — "You need permission" when setting org policy or creating custom roles
- **Symptom:** `gcloud org-policies ...` or `gcloud iam roles create ...` returns `PERMISSION_DENIED` for
  the operator.
- **Cause:** The operator holds `roles/owner` expectations but not the **specific** admin role — setting
  org policy needs `roles/orgpolicy.policyAdmin`; custom roles need `roles/iam.organizationRoleAdmin`;
  WIF needs `roles/iam.workloadIdentityPoolAdmin` (Requirement 2.1).
- **Resolution:** Have a super-admin grant the **named** role at the Organization (not primitive Owner).
  This is by design — the solution deliberately runs without relying on Owner. Use the audited
  break-glass path only if a named role genuinely cannot perform the action.

## T8 — Locked out at the Organization node after an org-wide change
- **Symptom:** An org-node IAM or org-policy change removed the operator's own access, or broke access
  broadly.
- **Cause:** An over-broad org-node change applied without a dry-run window — inheritance pushed it to
  every folder/project instantly.
- **Resolution:** Use the **break-glass super-admin** to restore the org-node IAM policy from the backup
  and set the offending org policy back to `dryRunSpec` (rollback, Implementation 6.2). Then re-apply the
  change **on the pilot scope first** with a dry-run window, per the deployment model — never enforce a
  new org-node change without piloting it.
