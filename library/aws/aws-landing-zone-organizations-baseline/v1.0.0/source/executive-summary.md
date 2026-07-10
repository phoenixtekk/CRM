# Executive Summary — AWS Landing Zone & Organizations Baseline

## The problem

Most AWS estates start as **one account with root access everywhere** — and never grow out of it.
That single account becomes the place where production, development, logging, and billing all live
together, protected by nothing but IAM policies that drift over time. It is simultaneously a **breach
waiting to happen** and a **billing surprise waiting to happen**:

- **No blast-radius isolation.** A compromised credential or a bad deploy in "the account" can touch
  everything, because everything is in one account.
- **No preventive guardrails.** Nothing *stops* someone from disabling logging, launching in an
  unapproved region, or using the root user — controls are hopeful, not enforced.
- **No central, tamper-resistant logging.** Audit trails live in the same account as the workloads
  they audit, so an attacker who owns the account owns the evidence too.
- **Click-ops sprawl.** New accounts (when they finally happen) are hand-built, inconsistent, and
  impossible to reproduce or govern.

## The solution

This solution stands up a **governed, multi-account AWS foundation** — a landing zone — so growth is
safe and repeatable from day one. It:

- **Establishes AWS Organizations and an OU hierarchy** — separate Organizational Units for security,
  infrastructure, workloads, and sandbox, so blast radius is bounded by design.
- **Delivers the landing zone as code** — the Terraform baseline in this package (with **AWS Control
  Tower** as the managed alternative), including **account vending** so new accounts are consistent,
  not hand-built.
- **Enforces Service Control Policies (SCPs) as preventive guardrails** — org-wide rules that *deny*
  the dangerous defaults (leaving the org, using root, unapproved regions, disabling security
  services) no matter what an account's own IAM allows.
- **Centralizes CloudTrail and AWS Config into a dedicated log-archive account** — a tamper-resistant
  record separated from the workloads it audits.
- **Applies an account baseline** — IAM password policy, default encryption, and an allowed-region
  posture on every account.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure →
Pilot → Validate → Expand**. We first discover the current org and account state, then build the OU
structure, logging, and SCPs **as Terraform run through plan-first review**, apply them to a
**non-production scope first**, validate that the guardrails deny what they should and the logs land
centrally, and only then expand the SCPs and vend accounts across the organization. Every change is
**`terraform plan` (or Control Tower preview) before apply**, in version control, approval-gated —
never click-ops in the console, never long-lived root keys on a laptop.

The solution ships as **self-guided, click-by-click documentation plus real Infrastructure-as-Code**
— a Terraform baseline (`main.tf`) and AWS CLI helper scripts that **discover** the current state,
**plan-first deploy** the baseline, **validate** the guardrails, and **report** posture — all
**read-only or plan-first**, with **no static credentials in code**.

## Why it matters

- **Bounded blast radius** — a problem in one account cannot trivially become a problem in all of
  them.
- **Guardrails that actually stop things** — SCPs *prevent* the dangerous action, rather than
  detecting it after the fact.
- **Tamper-resistant audit** — CloudTrail and Config in a separate log-archive account survive a
  workload-account compromise.
- **Repeatable account vending** — new accounts are consistent, governed, and reproducible, instead
  of a snowflake each time.
- **A fraction of consulting cost** — the same disciplined method a cloud foundations team would use,
  delivered as a repeatable, tested runbook.

## Important boundaries

This solution builds the **governed foundation** — Organizations, OUs, SCP guardrails, centralized
logging, and the account baseline. It **is not** a full workload platform, a networking/transit
design, a data-perimeter, or a security-detection product (GuardDuty/Security Hub findings triage,
IAM Identity Center federation, and workload landing zones are **separate catalog solutions** it sets
the stage for). It **creates real, billable AWS resources** (CloudTrail, Config, S3, KMS, and new
accounts have cost) — everything runs **plan-first in a non-production scope before production**, and
production apply is **the customer's change-approval decision**. AWS **Control Tower** vs a Terraform
landing zone, service feature availability, region behavior, and **pricing** all **evolve and differ
by AWS partition (Commercial vs GovCloud)** — *verify current provider/CLI versions, feature
availability, and pricing before you apply*.
