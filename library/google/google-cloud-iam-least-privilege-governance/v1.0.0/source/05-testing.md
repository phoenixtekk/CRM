# 5. Testing & Validation — Google Cloud IAM & Least-Privilege Governance

Run these after Configure and again after each Expand step. Each test states the procedure and the
**expected pass/fail**. Tests reuse the named artifacts from the Implementation Guide
(`IAM Governance – Pilot`, `IAM Guardrails – Org – v1`, `WIF Pool – Pilot – v1`).

---

## Test 1 — No primitive Owner/Editor except audited break-glass
- **Procedure:**
  ```bash
  python GCPIAM-Assess.py --folder "$PILOT_FOLDER_ID" --only primitive-roles
  ```
- **Pass:** the only `roles/owner`/`roles/editor` binding reported is `group:gcp-break-glass@` (and it
  is time-bound / IAM-Conditioned). No user or app team holds a primitive role.
- **Fail:** any other primitive grant appears → remove it, re-bind the least-privilege role from
  `Role Model – Org – v1`.

## Test 2 — Human bindings are group-based, not individual
- **Procedure:**
  ```bash
  python GCPIAM-Assess.py --folder "$PILOT_FOLDER_ID" --only user-bindings
  ```
- **Pass:** zero direct `user:` bindings (all human access is via `group:`), except any explicitly
  documented exception.
- **Fail:** a `user:` binding appears → move the user into the correct Google Group and remove the direct
  binding.

## Test 3 — New service-account keys cannot be created (guardrail enforced)
- **Procedure:** on a pilot service account, attempt to create a key:
  ```bash
  gcloud iam service-accounts keys create /dev/null \
    --iam-account=app-a-ci@${ADMIN_PROJECT}.iam.gserviceaccount.com
  ```
- **Pass:** the request is **denied** by org policy
  (`constraints/iam.disableServiceAccountKeyCreation` on `IAM Guardrails – Org – v1`) with a
  `FAILED_PRECONDITION` / policy-violation error.
- **Fail:** a key is created → the constraint is still in `dryRunSpec`; promote it to enforced
  (Implementation 4.1) and re-test.

## Test 4 — No exportable (user-managed) keys remain on migrated accounts
- **Procedure:**
  ```bash
  gcloud iam service-accounts keys list \
    --iam-account=app-a-ci@${ADMIN_PROJECT}.iam.gserviceaccount.com \
    --managed-by=user
  ```
- **Pass:** the list is empty (only Google-managed keys remain, which are not exportable) for every
  workload moved to `WIF Pool – Pilot – v1`.
- **Fail:** a user-managed key is listed → confirm the workload is on WIF, then delete the key.

## Test 5 — The pilot workload authenticates via Workload Identity Federation
- **Procedure:** trigger the pilot CI/workload job configured against `WIF Pool – Pilot – v1` and observe
  it obtain credentials without a key file. Confirm the exchange in logs:
  ```bash
  gcloud logging read 'protoPayload.serviceName="sts.googleapis.com"' --limit=5 --project="$ADMIN_PROJECT"
  ```
- **Pass:** the workload runs successfully and STS token-exchange events appear — proving short-lived,
  federated credentials, no static key.
- **Fail:** the job cannot authenticate → see Troubleshooting T3 (attribute-mapping / audience mismatch).

## Test 6 — Domain-Restricted Sharing blocks external principals
- **Procedure:** attempt to grant a role to an out-of-domain principal on the pilot scope:
  ```bash
  gcloud projects add-iam-policy-binding PILOT_PROJECT_ID \
    --member="user:someone@example.com" --role="roles/viewer"
  ```
- **Pass:** denied by `constraints/iam.allowedPolicyMemberDomains` — only your customer IDs may be
  granted.
- **Fail:** the grant succeeds → the constraint is not enforced or the customer-ID allow-list is wrong;
  re-apply from `IAM Guardrails – Org – v1`.

## Test 7 — Reference-design assertion passes
- **Procedure:**
  ```bash
  python GCPIAM-PolicyCheck.py --resource "folders/$PILOT_FOLDER_ID" --assert-reference-design
  ```
- **Pass:** the tool exits `0` — no primitive grants (outside break-glass), no creatable user-managed
  keys, all human bindings group-based, guardrails enforced.
- **Fail:** it exits non-zero and lists the violated invariant → fix that specific item and re-run.

## Test 8 — Access-review report generates and reconciles
- **Procedure:**
  ```bash
  python GCPIAM-Review.py --organization "$ORG_ID" --scope "folders/$PILOT_FOLDER_ID" --out review.csv
  ```
- **Pass:** `review.csv` lists every binding with its principal, role, and any IAM Recommender
  "over-granted / unused" flag, ready for owner attestation.
- **Fail:** empty or errored output → check Recommender/Policy Analyzer APIs are enabled (Requirement
  2.5) and the operator holds the viewer roles (Requirement 2.1).

---

### Overall pass criteria (promotion gate)
Promote from pilot to expand only when **Tests 1–8 all pass** on `IAM Governance – Pilot`:
no primitive grants outside break-glass, group-based human access, exported keys eliminated and
un-creatable, the pilot workload on WIF, Domain-Restricted Sharing enforced, the reference-design
assertion green, and the access-review report attested.
