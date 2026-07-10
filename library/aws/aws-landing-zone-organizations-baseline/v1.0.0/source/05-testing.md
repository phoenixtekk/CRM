# Testing & Validation — AWS Landing Zone & Organizations Baseline

Validate the foundation against explicit **pass/fail gates** before expanding the SCPs beyond the
pilot OUs. Run the helpers and walk the manual checks. Do not proceed to **Expand** until every gate
passes. The automated gates are produced by **`AWSLZ-Validate.sh`**; posture evidence comes from
**`AWSLZ-Report.sh`**; readiness from **`AWSLZ-Discovery.sh`**; and every change went through the
plan-first **`AWSLZ-Deploy.sh`**.

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — Organizations is All-features from the management account

- **What good looks like:** The org is in **All features** mode, enabling SCPs.
- **How to test:** `aws organizations describe-organization` returns `FeatureSet: ALL` (or read
  `AWSLZ-Discovery.sh`).
- **If it fails:** Enable All features from the management account (R1); SCPs cannot attach otherwise.

## Gate 2 — The OU hierarchy exists and accounts are placed

- **What good looks like:** `Security`, `Infrastructure`, `Workloads-Prod`, `Workloads-NonProd`, and
  `Sandbox` OUs exist; `Log-Archive` and `Security-Tooling` are in the **Security** OU.
- **How to test:** `AWSLZ-Validate.sh` lists OUs and placements; the two core accounts are under
  Security.
- **If it fails:** Create the missing OUs / move accounts (Phase 1–2); re-plan and apply.

## Gate 3 — Organization CloudTrail is logging to the Log-Archive account

- **What good looks like:** `Trail-Org-CloudTrail` is an **organization trail**, multi-region,
  delivering to `org-log-archive-<id>` in the **Log-Archive** account, encrypted with `kms-org-logs`.
- **How to test:** `AWSLZ-Validate.sh` confirms the trail exists, `IsOrganizationTrail=true`,
  `IsLogging=true`, and recent objects are in the log bucket.
- **If it fails:** Re-check the trail resource and bucket policy/KMS grants; ensure the log-archive
  bucket accepts org-trail delivery.

## Gate 4 — AWS Config is recording and aggregating

- **What good looks like:** Config recorders are on across accounts and `Config-Org-Aggregator`
  aggregates centrally.
- **How to test:** `AWSLZ-Validate.sh` confirms the aggregator exists and reports recorder status.
- **If it fails:** Enable Config recorders (baseline) and confirm the aggregator authorization.

## Gate 5 — The SCP guardrails are attached to the pilot OUs

- **What good looks like:** `SCP-DenyLeaveOrg-Guardrail`, `SCP-DenyRootActions-Guardrail`,
  `SCP-RegionLockdown-Guardrail`, `SCP-ProtectSecurityServices-Guardrail`, and
  `SCP-RequireEncryption-Guardrail` are attached to **`Workloads-NonProd`** and **`Sandbox`** (not
  yet prod).
- **How to test:** `AWSLZ-Validate.sh` lists SCP attachments per OU.
- **If it fails:** Attach the SCPs to the pilot OUs (Step 2.2); confirm no broad deny hit the
  management/security accounts.

## Gate 6 — Guardrails actually **deny** the dangerous action (and allow the safe one)

- **What good looks like:** In a pilot account, an action **outside an allowed region** is **denied**,
  and an in-region, permitted action is **allowed** — proving the SCP is preventive, not cosmetic.
- **How to test:** `AWSLZ-Validate.sh` runs read-only **guardrail probes** (e.g. a dry-run/
  describe-style call in a disallowed region) and reports DENY as expected. *Probes are read-only and
  designed to be safe — verify they suit your environment.*
- **If it fails:** Review SCP JSON (conditions/regions), inheritance/order, and any conflicting
  allow — SCPs bound, they never grant.

## Gate 7 — A vended test account is pre-baselined

- **What good looks like:** The `Sandbox` test account lands in the right OU with SCPs applied,
  logging flowing, an **IAM password policy**, **default encryption**, and **no root access keys**.
- **How to test:** `AWSLZ-Validate.sh` checks the test account's baseline; `AWSLZ-Report.sh` shows it
  compliant.
- **If it fails:** Re-run the baseline for the account (vending should apply it automatically); fix
  the vending template so future accounts are correct.

## Gate 8 — Every change was plan-first and state is protected

- **What good looks like:** No console click-ops changed the foundation; each apply followed a
  reviewed `terraform plan`; remote state is encrypted, versioned, and locked.
- **How to test:** Confirm the plan/apply history (pipeline logs) and that `AWSLZ-Deploy.sh apply`
  required explicit confirmation; confirm the state backend is S3 + DynamoDB, encrypted/versioned.
- **If it fails:** Bring drift back under Terraform (`terraform plan` shows drift), stop out-of-band
  console changes, and protect the state backend (R6).

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | Org All-features | `FeatureSet: ALL` |
| 2 | OU hierarchy + placement | OUs exist; core accounts in Security |
| 3 | Org CloudTrail centralized | Org trail logging to Log-Archive, encrypted |
| 4 | Config recording + aggregation | Recorders on; `Config-Org-Aggregator` aggregating |
| 5 | SCPs attached to pilot OUs | Five SCPs on NonProd + Sandbox |
| 6 | Guardrails deny/allow correctly | Disallowed action denied; allowed action allowed |
| 7 | Vended account pre-baselined | Test account in-OU, SCP'd, logged, baselined |
| 8 | Plan-first + state protected | Reviewed plans; encrypted/locked remote state |

All eight gates pass ⇒ proceed to **Expand** (attach SCPs to remaining OUs, enable vending). Any
fail ⇒ stay in the pilot scope and remediate the gate first.
