# 3. Implementation Guide — AWS Data-Source Governance (S3/RDS): Microsoft Purview

Follow these steps in order. This guide assesses AWS readiness, designs the collection and role model,
establishes the S3 trust and RDS credential paths safely, registers and **pilot-scans** a bounded AWS
source set, reviews classifications, then expands across the AWS estate. Artifact names are fixed —
create them with the exact names shown and reuse them everywhere. **Every scan is piloted on a bounded
scope before the AWS estate is scanned.**

> Model: prove the AWS connector, credential/trust path, and classification on a pilot scope, then
> expand. The repeatable way: **Assess → Design → Configure → Pilot → Validate → Expand.** Verify
> current portal paths, connector availability, supported RDS engines, and the Microsoft AWS
> principal/external ID for your tenant as you go — the multicloud connectors are evolving.

## Step 1 — Assess current state (read-only)
1. Run `DGAWS-Discovery.ps1` to capture readiness signals: the Purview account endpoint is reachable,
   which **collections** exist and their **role coverage**, which **integration runtimes** are
   registered, and how many AWS (and other) sources are already registered. No changes are made.
2. In the Purview portal (**Data Map → Sources → Register**) confirm **Amazon S3** and **Amazon RDS**
   are offered and note the **supported RDS engines** for your tenant.
3. Record gaps against the Requirements checklist. Do **not** proceed past a missing account, a missing
   connector, missing least-privilege roles, or a missing network path — remediate those first.

## Step 2 — Design the collection and role model
1. Decide the **collection** the AWS sources register into. For the pilot, create one collection named
   `DGAWS-Collection-Pilot` under the root; plan the broader hierarchy (for example an `AWS` branch by
   AWS account or by sensitivity) on paper for the expansion phase.
2. Assign least-privilege roles at the narrowest scope: **Data source admin** on
   `DGAWS-Collection-Pilot` to whoever will register/scan AWS sources, **Data curator** to the catalog
   editors, **Data reader** to browsers, and **Collection admin** to a small named group. Reserve
   account-level admin for a minimal named group.

## Step 3 — Establish the S3 trust path (cross-account IAM role, safe by design)
1. In the Purview portal, begin **Register → Amazon S3** and read the **Microsoft AWS account /
   principal and the external ID** it displays. **Copy them from the portal — do not assume an account
   ID.**
2. In AWS IAM, create a role named (for example) `PurviewScanRole-S3` with a **trust policy** that
   allows that Microsoft Purview AWS principal to assume it, **conditioned on the external ID**.
3. Grant the role **read-only** access to the in-scope buckets (the AWS-managed
   `AmazonS3ReadOnlyAccess`, or a tighter bucket-scoped read policy) and **`kms:Decrypt`** on the KMS
   key for any encrypted bucket. **Put no AWS secret anywhere** — the trust is role-based.
4. In Purview, register the role's **ARN** as a credential **by name** (for example
   `DGAWS-Cred-S3-Role`). This name is what the scripts reference; the ARN is never inlined in a script.

## Step 4 — Establish the RDS credential path (Key Vault, safe by design)
1. Link an **Azure Key Vault** to the Purview account (or confirm one is linked).
2. Create a **least-privilege read login** on the in-scope RDS database, store its secret in the Key
   Vault, and create a Purview credential **by name** (for example `DGAWS-Cred-RDS-KV`) that references
   the Key Vault secret. **No credential is ever placed in a script or document.**
3. Confirm the **integration runtime** for each source: the **Azure (managed) runtime** for reachable
   S3/RDS, or install and register a **self-hosted integration runtime (SHIR)** for RDS in a private
   VPC. Confirm it shows **Running/Available**, and adjust the AWS **security group / bucket policy** to
   permit the scanner.

## Step 5 — Record the pilot scope
1. Run `DGAWS-Set-Scope.ps1` to record the pilot AWS source set (a couple of S3 buckets and/or one RDS
   database) with owners, plus the pilot collection and scan-rule-set intent (read-only; produces the
   scope manifest you register against).

## Step 6 — Register the pilot AWS sources into the Data Map
1. Register the pilot sources into `DGAWS-Collection-Pilot`. You may use the portal
   (**Register → Amazon S3 / Amazon RDS**), or run `DGAWS-Register-AwsSource.ps1` which **defaults to
   `-WhatIf`** and prints exactly what it would register (kind `AmazonS3` / `AmazonRDS`, the bucket or
   endpoint, the collection, and the credential name); re-run with `-Commit` to register.
2. Run **Test connection** for each registered source and confirm it passes (S3 role assume succeeds;
   RDS auth + network path succeed) before scanning. Do not scan until Test connection passes.

## Step 7 — Configure and pilot the scan (bounded scope, pilot-first)
1. Define the scan configuration: a **scan rule set** named `DGAWS-ScanRuleSet-Pilot` (start from the
   system default rule set), the **classifications** to apply (system classifications plus any custom
   rule named `DGAWS-Classification-Custom-<name>`), and a **scoped** scan that targets only the pilot
   buckets/database — not every bucket in the account or every database on the instance.
2. Trigger the scan **once** on the bounded scope (not scheduled yet) via
   `DGAWS-Register-AwsSource.ps1 -ConfigureScan` (`-WhatIf` by default; `-Commit` to apply) or the
   portal. Pass/fail: the scan completes with **status Succeeded** and returns assets with
   classifications.
3. **Rollback:** if a scan misbehaves, over-reaches, or runs up AWS request/egress cost, cancel the run
   in the portal and set the scan to disabled; a scan does not modify source data, but cancel to stop
   resource/cost consumption. Re-scope and re-run on a smaller set.

## Step 8 — Review scanned assets and classifications
1. Run `DGAWS-Report.ps1` to list the pilot AWS assets discovered (S3 objects/paths, RDS
   tables/columns), the classifications applied, and any assets returned **unclassified**.
2. With the data owner, confirm the classifications are correct. Where a real internal pattern was
   missed, define a **custom classification rule** (`DGAWS-Classification-Custom-<name>`), validate it
   against sample data, add it to `DGAWS-ScanRuleSet-Pilot`, and re-scan the pilot scope.

## Step 9 — Assign ownership on the AWS assets
1. In the catalog, assign the **data owner** and **steward** recorded in the scope manifest to the
   scanned buckets/databases so every governed AWS asset has a named owner — ownership is what makes
   classification and later access decisions accountable.

## Step 10 — Validate against the pilot gate
1. Complete the Testing Guide. Run `DGAWS-Test-Readiness.ps1` for a consolidated PASS/GAP gate check.
   The pilot passes only when: the AWS sources are registered and **Test connection** passes; the scan
   **Succeeded** and returned classified assets; and every scanned pilot asset has an owner assigned.
2. Remediate any gaps and re-run the relevant validation before proceeding. Do **not** widen scope
   until the gate passes.

## Step 11 — Expand across the AWS estate (enforce)
1. After the pilot passes, register further S3 buckets and RDS databases one grouping at a time (for
   example per AWS account), re-running `DGAWS-Set-Scope.ps1`, `DGAWS-Register-AwsSource.ps1`, and
   `DGAWS-Report.ps1` for each new scope. Reuse the same IAM role pattern (extending its bucket/KMS
   scope) and Key Vault credential pattern.
2. Move scans from one-time to **scheduled** only once a scope is validated, so classifications stay
   current as AWS data changes — and watch AWS request/egress cost as scope grows.
3. Keep ownership assigned on every newly scanned asset and track coverage with `DGAWS-Report.ps1`.

---
### Order of operations
`Assess -> Design (collection/roles) -> S3 trust (IAM role + external ID) -> RDS credential (Key Vault) & network -> Record scope -> Register AWS sources -> Pilot scan (bounded) -> Review classifications -> Assign ownership -> Validate gate -> Expand (scheduled scans)`
