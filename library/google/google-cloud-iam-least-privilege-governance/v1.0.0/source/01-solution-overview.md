# 1. Solution Overview — Google Cloud IAM & Least-Privilege Governance

By default, Google Cloud makes it *easy* to over-grant. The `roles/owner` primitive role is one
click away, service-account **keys** can be exported and emailed around, and bindings accrete at the
project level with no one accountable for who holds what. The three most common findings in a
Google Cloud security review are, predictably: **broad Owner/Editor grants**, **unmanaged exported
service-account keys**, and **role sprawl** — permissions granted once and never removed. This
solution establishes **Cloud IAM governance**: a repeatable, least-privilege access model that is
**intentional and auditable**, deployed **pilot-first** with explicit gates and a documented
rollback.

> **Vendor boundary.** The **Google Cloud Console** (console.cloud.google.com), the **`gcloud` CLI**,
> and **Cloud Identity / Google Admin** are authored at exact, current command / click detail from
> Google's public documentation. Where a capability or default is version- or preview-dependent —
> Workload Identity Federation provider types, org-policy constraint names, IAM Recommender / Policy
> Analyzer availability, IAM Conditions — it is **cited or flagged "verify in your organization."**
> Terraform / Cloud Foundation Toolkit is referenced at the **pattern level** with representative
> snippets; module internals defer to the tool's own docs. Automation is **Python** over `gcloud` /
> the Cloud Client Libraries — **no exported keys, no hardcoded credentials, no secrets in code.**

## The Cloud IAM model — who can do what, deliberately

Google Cloud IAM answers one question — *which principal has which role on which resource* — and the
answer is inherited **down the resource hierarchy** (Organization → Folder → Project → resource).
Governing IAM means controlling each part of that sentence on purpose.

### Principals — humans as groups, workloads as service accounts
- **Humans** are never bound individually. Access is granted to **Google Groups** sourced from the
  identity system (Cloud Identity / Workspace, typically synchronized from the enterprise IdP), so
  joiner/mover/leaver is handled by group membership, not by editing IAM policies. One person leaving
  a team is a group change, not a hunt across every project.
- **Workloads** run as **service accounts**. External and federated workloads (CI/CD, on-prem, other
  clouds, GitHub Actions) authenticate via **Workload Identity Federation (WIF)** — short-lived,
  automatically-rotated credentials — instead of a **downloaded service-account key** that never
  expires and cannot be revoked without breaking every consumer.

### Roles — predefined and custom, never primitive
- **Primitive roles** (`roles/owner`, `roles/editor`, `roles/viewer`) are coarse legacy grants that
  span thousands of permissions. Owner and Editor are effectively "can do almost anything"; they are
  the finding, not the fix. This solution **eliminates primitive grants** (except a tightly-audited
  break-glass path) in favor of scoped roles.
- **Predefined roles** are service-scoped, Google-maintained role bundles (e.g.
  `roles/storage.objectViewer`, `roles/compute.instanceAdmin.v1`). **Prefer predefined roles** — they
  track new permissions as services evolve, so you do not have to.
- **Custom roles** are authored only when no predefined role fits — to trim a predefined role down to
  the exact permissions a job needs. They carry a maintenance cost (you own the permission list as
  services change), so they are the exception, defined at the Organization level for reuse.

### Bind at the right level of the hierarchy
A binding at the **Organization** node is inherited by every folder and project beneath it; a binding
at a **project** affects only that project. Grant each role at the **highest level that is still
correct and no higher** — platform-team roles high, application-team roles on their own folder or
project — so access is broad only where it is genuinely meant to be. Over-broad *scope* is as much a
finding as an over-broad *role*.

### Conditions and guardrails
- **IAM Conditions** attach an expression (resource name prefix, request time, resource tag) to a
  binding so a grant applies only in the intended context — e.g. a role that is valid only on
  resources tagged `env=dev`. (IAM Conditions support varies by role/resource — **verify** the
  target supports the condition you need.)
- **IAM-restricting org policies** cap what any principal can grant, regardless of their role:
  `iam.disableServiceAccountKeyCreation` (block exported keys),
  `iam.allowedPolicyMemberDomains` (**Domain-Restricted Sharing** — only your domains can be granted),
  `iam.automaticIamGrantsForDefaultServiceAccounts` (stop default SAs receiving Editor), and
  `constraints/iam.serviceAccountKeyExpiryHours` where applicable. These are **guardrails**: they make
  the wrong grant *impossible*, not just discouraged. (Constraint availability is
  version-dependent — **verify** each in your organization.)

### Review — access is a cadence, not an event
Least privilege decays. A recurring **access review** re-attests bindings: **IAM Recommender** and
**Policy Analyzer** surface over-granted and unused roles; owners confirm or the role is trimmed. The
model only stays true if it is re-checked on a schedule.

## Reference design — the target end state
- **No primitive Owner/Editor** on projects except an audited break-glass group.
- **Human access** via Google Groups bound to **predefined (or trimmed custom) roles**, at the
  correct hierarchy level.
- **Workload access** via service accounts, with **WIF for every external/federated caller** and
  **`iam.disableServiceAccountKeyCreation` enforced** so new exported keys cannot be created.
- **Org-policy guardrails** (Domain-Restricted Sharing, key-creation disable, default-SA grant
  disable) applied at the Organization node.
- **A quarterly access-review runbook** driven by Recommender / Policy Analyzer output.

## Deployment model — Assess → Design → Configure → Pilot → Validate → Expand
Every change follows the category-standard staged model with explicit pass/fail gates and a
documented rollback (mandatory for org-wide changes):

1. **Assess** — inventory the current IAM posture with `GCPIAM-Assess.py`: primitive-role grants,
   service-account **keys**, external/federated principals, and role sprawl. Establish the baseline.
2. **Design** — define the role model (predefined-first, the short list of custom roles), the
   group-to-role map, the hierarchy level for each binding, and the guardrail policy set.
3. **Configure** — author custom roles and org policies in **dry-run** (`GCPIAM-RoleDesigner.py
   --dry-run`, org policy `dryRunSpec`), scoped to a **pilot folder/project**
   (`IAM Governance – Pilot`), not the whole organization.
4. **Pilot** — apply group-based bindings, stand up **WIF** for a pilot workload
   (`GCPIAM-WIFSetup.py`), and enforce guardrails on `IAM Governance – Pilot`. **Gate:** no primitive
   grants, no new keys creatable, pilot workload authenticates via WIF, no legitimate access broken.
5. **Validate** — run `GCPIAM-PolicyCheck.py` and `GCPIAM-Review.py`; confirm the reference-design
   assertions hold and produce the access-review report. Promote org-policy `dryRunSpec` → enforced
   only after clean results.
6. **Expand** — roll out folder-by-folder / project-by-project, keeping the rollback (restore prior
   IAM policy from the captured baseline, set org policies back to `dryRun`) documented at each step.

## What this solution delivers
- The **Solution Overview** (this document) — the Cloud IAM governance model.
- A **Requirements Guide** — organization, org-admin access, group source of truth, gcloud
  toolchain, and pilot scope, each with verify / implement-if-missing.
- An **Implementation Guide** — the role model, group-based bindings at the right level, WIF to kill
  exported keys, IAM-restricting org policies, and the access-review cadence; pilot then expand.
- **5 Python tools** — IAM-posture assessment (read-only), a custom-role designer/applier (dry-run),
  a WIF setup helper, an access-review report generator, and an org-policy guardrail check — authentic
  `gcloud` / Cloud Client Library automation, read-only or `--dry-run` by default, no keys in code.
- **Testing, Troubleshooting, and Best-Practices** guides plus a deliverables summary.

**Bottom line:** Google Cloud access under least-privilege control — role sprawl tamed, exported keys
eliminated, bindings reviewed — intentional and auditable across the organization, proven on a pilot
before you scale.
