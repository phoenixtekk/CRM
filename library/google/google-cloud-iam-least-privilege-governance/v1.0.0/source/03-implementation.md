# 3. Implementation — Google Cloud IAM & Least-Privilege Governance

Follow these steps in order. They implement the **Assess → Design → Configure → Pilot → Validate →
Expand** model. Every artifact is **named** with the `<Purpose> – <Scope> – <Stage>` convention and
that exact name is reused in Testing, Troubleshooting, and the scripts. All write operations are
**dry-run first**; the org-wide rollout at the end has an explicit rollback.

Set working variables once:
```bash
export ORG_ID="123456789012"                 # your Organization ID
export ADMIN_PROJECT="iam-governance-admin"   # project you run tooling from
export PILOT_FOLDER_ID="234567890123"         # the "IAM Governance – Pilot" folder
```

---

## Stage 1 — Assess (read-only baseline)

### 1.1 Capture the current IAM posture
Run the assessment tool at the Organization scope (read-only):
```bash
python GCPIAM-Assess.py --organization "$ORG_ID" --out iam-baseline.json
```
It reports, and writes to the baseline file:
- **Primitive-role grants** — every `roles/owner` / `roles/editor` binding, by principal and resource.
- **Service-account keys** — all **user-managed** (exportable) keys, by service account.
- **External principals** — bindings to `user:` / `serviceAccount:` outside your domains.
- **Role sprawl** — direct **user** (non-group) bindings and per-project role counts.

Keep `iam-baseline.json` — it is the **rollback reference** and the "before" side of validation.

### 1.2 Export the current IAM policies for rollback
For the pilot scope and any project you will touch, snapshot the exact policy:
```bash
gcloud projects get-iam-policy PILOT_PROJECT_ID --format=json > iam-policy-PILOT_PROJECT_ID.backup.json
gcloud resource-manager folders get-iam-policy "$PILOT_FOLDER_ID" --format=json > iam-policy-pilotfolder.backup.json
```
> **Gate (Assess):** you have a complete inventory of primitive grants, exportable keys, and external
> principals, plus a restorable IAM-policy snapshot for every in-scope resource. Do not proceed without
> the backups.

---

## Stage 2 — Design (author on paper, apply nothing)

### 2.1 Define the role model — `Role Model – Org – v1`
Produce a table (record it in your design doc) mapping each **Google Group** to the **least-privilege
roles** it needs and the **hierarchy level** to bind at:

| Group | Role(s) | Bind at | Why this level |
|---|---|---|---|
| `gcp-platform-admins@` | `roles/resourcemanager.folderAdmin`, `roles/iam.securityReviewer` | Organization | platform team governs all |
| `gcp-app-team-a-developers@` | `roles/compute.instanceAdmin.v1`, `roles/storage.objectAdmin` | Folder `App Team A` | scoped to their folder |
| `gcp-billing-viewers@` | `roles/billing.viewer` | Organization | read-only, org-wide |
| `gcp-break-glass@` | `roles/owner` (audited, IAM-Conditioned/time-bound) | Organization | emergency only |

Rules: **predefined roles first**; a **custom role** only where no predefined role fits; **no
`roles/owner`/`roles/editor`** except the audited break-glass group.

### 2.2 Design custom roles only where predefined roles do not fit
For each gap, list the exact permissions. Design (do not yet apply) with the role designer in dry-run:
```bash
python GCPIAM-RoleDesigner.py --organization "$ORG_ID" \
  --role-id customAppDeployer --title "Custom App Deployer – Org – v1" \
  --permissions run.services.get,run.services.update,artifactregistry.repositories.downloadArtifacts \
  --dry-run
```
Name each custom role `Custom <Function> – Org – v1`. Define custom roles at the **Organization** level
so they are reusable across projects.

### 2.3 Design the guardrail set — `IAM Guardrails – Org – v1`
Decide which IAM-restricting org-policy constraints apply (all applied in `dryRunSpec` first):
- `constraints/iam.disableServiceAccountKeyCreation` — block new **exported** keys.
- `constraints/iam.allowedPolicyMemberDomains` — **Domain-Restricted Sharing** (only your customer IDs).
- `constraints/iam.automaticIamGrantsForDefaultServiceAccounts` — stop default SAs getting Editor.
- `constraints/iam.disableServiceAccountKeyUpload` and, where available,
  `constraints/iam.serviceAccountKeyExpiryHours` — **verify constraint availability in your organization.**

### 2.4 Plan the WIF replacement — `WIF Pool – Pilot – v1`
For each pilot workload on an exported key, record its external IdP (OIDC issuer or AWS account), the
subject/attribute to map, and the target service account to impersonate.

> **Gate (Design):** role-to-group map complete, custom roles minimized and dry-run-validated, guardrail
> set chosen, WIF plan written. No changes applied yet.

---

## Stage 3 — Configure (apply to the pilot scope only, dry-run guardrails)

### 3.1 Create the custom roles — `Custom <Function> – Org – v1`
Apply the designed custom roles at the Organization (they are definitions; they grant nothing until
bound):
```bash
python GCPIAM-RoleDesigner.py --organization "$ORG_ID" \
  --role-id customAppDeployer --title "Custom App Deployer – Org – v1" \
  --permissions run.services.get,run.services.update,artifactregistry.repositories.downloadArtifacts \
  --apply
```

### 3.2 Apply group-based bindings on the pilot scope
Bind the designed groups→roles on the **pilot folder** (`IAM Governance – Pilot`) and pilot projects —
**never individual users**:
```bash
gcloud resource-manager folders add-iam-policy-binding "$PILOT_FOLDER_ID" \
  --member="group:gcp-app-team-a-developers@your-domain.com" \
  --role="roles/compute.instanceAdmin.v1"
```
Where a grant should be context-limited, attach an **IAM Condition** (verify the role/resource supports
it):
```bash
gcloud projects add-iam-policy-binding PILOT_PROJECT_ID \
  --member="group:gcp-app-team-a-developers@your-domain.com" \
  --role="roles/storage.objectAdmin" \
  --condition='expression=resource.name.startsWith("projects/_/buckets/appa-"),title=appa-buckets-only'
```

### 3.3 Stand up Workload Identity Federation — `WIF Pool – Pilot – v1`
Replace one pilot workload's exported key with WIF (example: GitHub Actions OIDC):
```bash
python GCPIAM-WIFSetup.py --project "$ADMIN_PROJECT" \
  --pool-id wif-pool-pilot --pool-name "WIF Pool – Pilot – v1" \
  --provider-id github --issuer-uri "https://token.actions.githubusercontent.com" \
  --attribute-mapping "google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --service-account "app-a-ci@${ADMIN_PROJECT}.iam.gserviceaccount.com" \
  --allowed-attribute "attribute.repository/your-org/app-a" \
  --dry-run
```
Review the plan, then re-run with `--apply`. The tool prints the **workload-side** configuration the CI
uses; the workload obtains **short-lived** credentials and the exported key is retired.

### 3.4 Retire the exported key (after the workload is on WIF)
Once the pilot workload authenticates via WIF and its jobs pass:
```bash
gcloud iam service-accounts keys list --iam-account=app-a-ci@${ADMIN_PROJECT}.iam.gserviceaccount.com
gcloud iam service-accounts keys delete KEY_ID --iam-account=app-a-ci@${ADMIN_PROJECT}.iam.gserviceaccount.com
```

### 3.5 Apply guardrails in dry-run on the pilot scope — `IAM Guardrails – Org – v1`
Apply each constraint in **`dryRunSpec`** on the pilot folder so violations are *logged, not enforced*:
```bash
python GCPIAM-PolicyCheck.py --resource "folders/$PILOT_FOLDER_ID" \
  --constraint constraints/iam.disableServiceAccountKeyCreation --set-dry-run
```
(For Domain-Restricted Sharing, supply your allowed **customer IDs**, not domains.)

> **Gate (Configure):** custom roles exist, pilot bindings are **group-based**, the pilot workload runs
> on WIF, its exported key is deleted, and guardrails are in dry-run on the pilot folder.

---

## Stage 4 — Pilot (enforce on the pilot scope, observe)

### 4.1 Promote guardrails to enforced on the pilot folder
After a clean dry-run period (guardrail violations reviewed, none legitimate):
```bash
python GCPIAM-PolicyCheck.py --resource "folders/$PILOT_FOLDER_ID" \
  --constraint constraints/iam.disableServiceAccountKeyCreation --enforce
```
### 4.2 Confirm nothing legitimate broke
Re-run `GCPIAM-Assess.py --folder "$PILOT_FOLDER_ID"` and confirm pilot teams still have the access they
need and none they should not.

> **Gate (Pilot):** on `IAM Governance – Pilot` — **zero** primitive grants (except audited break-glass),
> **key creation blocked** (a test `keys create` is denied), pilot workload authenticates via WIF, and no
> legitimate access is broken. **Fail → rollback (Stage 6.2), fix the design, re-pilot.**

---

## Stage 5 — Validate (prove the reference design)

### 5.1 Assert the reference-design invariants
```bash
python GCPIAM-PolicyCheck.py --resource "folders/$PILOT_FOLDER_ID" --assert-reference-design
```
Expected: no primitive Owner/Editor outside break-glass, no user-managed keys creatable, all human
bindings are to `group:` principals, guardrails enforced.

### 5.2 Generate the access-review report — `Access Review – Pilot – Q?`
```bash
python GCPIAM-Review.py --organization "$ORG_ID" --scope "folders/$PILOT_FOLDER_ID" \
  --out access-review-pilot.csv
```
It pulls **IAM Recommender** (over-granted / unused roles) and **Policy Analyzer** and lists each
binding for owner attestation.

> **Gate (Validate):** reference-design assertion passes and the access-review report is produced and
> attested. Only now promote guardrails toward the Organization node.

---

## Stage 6 — Expand (roll out) and Rollback

### 6.1 Expand folder-by-folder
For each remaining folder/project, repeat **Configure → Pilot → Validate** using the same named
artifacts, then apply the guardrail set at the **Organization** node in `dryRunSpec` first, review
org-wide violations, and only then enforce:
```bash
python GCPIAM-PolicyCheck.py --resource "organizations/$ORG_ID" \
  --constraint constraints/iam.disableServiceAccountKeyCreation --set-dry-run   # review first
python GCPIAM-PolicyCheck.py --resource "organizations/$ORG_ID" \
  --constraint constraints/iam.disableServiceAccountKeyCreation --enforce       # after clean review
```

### 6.2 Rollback (documented, per scope)
If any stage fails, restore the captured state:
```bash
# Restore IAM policy from the Stage-1.2 backup
gcloud projects set-iam-policy PILOT_PROJECT_ID iam-policy-PILOT_PROJECT_ID.backup.json
gcloud resource-manager folders set-iam-policy "$PILOT_FOLDER_ID" iam-policy-pilotfolder.backup.json
# Set an enforced guardrail back to dry-run (non-blocking) while you investigate
python GCPIAM-PolicyCheck.py --resource "folders/$PILOT_FOLDER_ID" \
  --constraint constraints/iam.disableServiceAccountKeyCreation --set-dry-run
```
A guardrail regression is non-destructive (dry-run keeps logging); an IAM regression is fixed by
re-applying the backup policy. WIF setup is additive — retire the WIF provider only after the workload
is moved back, and never re-create an exported key to "fix" a WIF issue.
