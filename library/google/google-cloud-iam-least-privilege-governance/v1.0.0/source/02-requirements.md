# 2. Requirements — Google Cloud IAM & Least-Privilege Governance

This solution assumes the **shared GCP category requirements** in `global-requirements-gcp.md` are met
— a **Google Cloud Organization** linked to Cloud Identity/Workspace (§1), **Organization-level
administrative access** (§2), a **Cloud Billing account** (§3), the **gcloud / IaC toolchain and API
enablement** (§4), a **resource-hierarchy, naming & environment design** with a **named pilot scope**
(§5), and engagement with **security / governance stakeholders** (§6). Do not re-establish those here;
verify them, then confirm the **solution-specific** prerequisites below.

Each prerequisite is listed as **Description / Why required / How to verify / How to implement if
missing.**

---

## 2.1 IAM administrative roles at the Organization node (not primitive Owner)
- **Description:** The operator running this solution holds the **specific** IAM-governance roles at
  the Organization: `roles/resourcemanager.organizationAdmin` (see IAM policies),
  `roles/iam.organizationRoleAdmin` (create/manage **custom roles**),
  `roles/orgpolicy.policyAdmin` (set **org policies**), and
  `roles/iam.workloadIdentityPoolAdmin` (create **WIF** pools/providers). Recommender/Analyzer use adds
  `roles/recommender.iamAdmin` and `roles/policyanalyzer.activityAnalysisViewer` (name varies by
  edition — **verify in your organization**).
- **Why required:** Authoring custom roles, setting org-policy guardrails, and standing up Workload
  Identity Federation each require a distinct admin role; the goal is to run this work **without**
  relying on primitive `roles/owner`.
- **How to verify:**
  ```bash
  gcloud organizations get-iam-policy $ORG_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:user:you@your-domain.com" \
    --format="table(bindings.role)"
  ```
  Confirm the roles above appear (and that you are **not** relying on `roles/owner`).
- **How to implement if missing:** Have a super-admin grant the named roles under change control
  (`gcloud organizations add-iam-policy-binding $ORG_ID --member=... --role=...`). Keep the
  **break-glass super-admin** as a separate, MFA-protected, audited account used only when a named
  admin role cannot perform the action.

## 2.2 Google Groups as the source of truth for human access
- **Description:** Enterprise **Google Groups** (in Cloud Identity / Workspace), typically synchronized
  from the enterprise IdP, that represent job functions / teams — the principals you will bind roles
  to. Individual-user bindings are the exception, not the rule.
- **Why required:** Group-based bindings make joiner/mover/leaver a membership change instead of an
  IAM-policy edit, and keep the policy readable. Binding individuals directly is the root cause of role
  sprawl.
- **How to verify:** In the **Google Admin console** (admin.google.com → Directory → Groups), confirm
  role-mapped groups exist (e.g. `gcp-platform-admins@`, `gcp-app-team-a-developers@`). Confirm whether
  membership is IdP-synchronized or managed in Google.
- **How to implement if missing:** Create the role-mapped groups (or provision them from the IdP), agree
  the **group-to-role map** with team owners, and confirm ownership of each group before binding roles
  to it.

## 2.3 Workload inventory and a federation plan for external callers
- **Description:** A list of **service accounts** and the workloads that use them, flagging every
  workload that today authenticates with a **downloaded service-account key** — CI/CD runners, on-prem
  jobs, other clouds (AWS/Azure), GitHub Actions, or partner integrations. For each, the external
  identity provider's issuer (OIDC issuer URL or the AWS account) that WIF will trust.
- **Why required:** Replacing exported keys with **Workload Identity Federation** requires knowing which
  workloads exist, who owns them, and what external IdP each trusts — WIF trades a static key for a
  short-lived token brokered from that IdP.
- **How to verify:** Enumerate service-account keys with `GCPIAM-Assess.py` (or
  `gcloud iam service-accounts keys list --iam-account=SA_EMAIL` per account) and identify **user-managed**
  keys (the exportable ones). Map each key back to a consuming workload and its owner.
- **How to implement if missing:** Build the SA→workload→owner→external-IdP map before configuring WIF;
  a key with no known consumer is itself a finding — investigate and revoke.

## 2.4 A named pilot folder or project for IAM changes
- **Description:** A **pilot scope** — a folder or a small number of projects (`IAM Governance – Pilot`)
  where the role model, group bindings, WIF, and org-policy guardrails are applied and validated
  **before** any Organization-node change.
- **Why required:** IAM and org-policy changes inherit **downward**; an over-broad org-node change can
  lock out legitimate access instantly. Piloting on a folder contains blast radius and lets guardrails
  run in **dry-run** first.
- **How to verify:** Confirm the pilot folder/project exists (`gcloud resource-manager folders list
  --organization=$ORG_ID`) and that you may apply IAM and org policy there.
- **How to implement if missing:** Create the pilot folder/project under the Organization and record its
  ID; all Configure/Pilot steps target it by the name `IAM Governance – Pilot`.

## 2.5 Required APIs enabled on the administration project
- **Description:** On the project you run tooling from, enable **Cloud Resource Manager**
  (`cloudresourcemanager.googleapis.com`), **IAM** (`iam.googleapis.com`), **IAM Credentials**
  (`iamcredentials.googleapis.com`, for WIF token exchange), **Service Usage**
  (`serviceusage.googleapis.com`), **Org Policy** (`orgpolicy.googleapis.com`), **Security Token Service**
  (`sts.googleapis.com`, for WIF), and **Recommender** (`recommender.googleapis.com`) / **Policy
  Analyzer** (`policyanalyzer.googleapis.com`) for the review tooling.
- **Why required:** The `gcloud` commands and the Python tools call these APIs; a disabled API returns a
  `SERVICE_DISABLED` error rather than data.
- **How to verify:** `gcloud services list --enabled --project=ADMIN_PROJECT` and confirm each ID is
  present.
- **How to implement if missing:**
  ```bash
  gcloud services enable cloudresourcemanager.googleapis.com iam.googleapis.com \
    iamcredentials.googleapis.com serviceusage.googleapis.com orgpolicy.googleapis.com \
    sts.googleapis.com recommender.googleapis.com policyanalyzer.googleapis.com \
    --project=ADMIN_PROJECT
  ```

## 2.6 Application Default Credentials for the Python tools (no keys on disk)
- **Description:** The provided Python tools authenticate via **Application Default Credentials (ADC)** —
  `gcloud auth application-default login` for an operator workstation, or the **attached** service
  account / **WIF** on a runner. **No exported key file** is used or referenced.
- **Why required:** The whole point of this solution is to eliminate exported keys; the tooling must
  practice it. ADC lets `gcloud` and the Cloud Client Libraries obtain short-lived credentials without a
  static key.
- **How to verify:** `gcloud auth application-default print-access-token` returns a token; confirm no
  `GOOGLE_APPLICATION_CREDENTIALS` points at a downloaded key file
  (`echo $GOOGLE_APPLICATION_CREDENTIALS` should be empty on a workstation using user ADC).
- **How to implement if missing:** Run `gcloud auth application-default login` (workstation) or attach a
  least-privilege service account / configure WIF (pipeline). Never commit or reference a key file.
