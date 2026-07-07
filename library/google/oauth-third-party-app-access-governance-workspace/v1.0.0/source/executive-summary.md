# Executive Summary

**Outcome.** This solution brings the organization's largest invisible attack surface — the OAuth
grants that third-party applications hold against Google Workspace data — under explicit, auditable
governance. On completion, every connected app and OAuth scope is inventoried and risk-scored, only
vetted apps are trusted, unverified apps and high-risk scopes are blocked by default, risky standing
tokens are revoked with evidence, and a repeatable vetting workflow governs every new app going
forward.

**The problem.** In a large Google Workspace estate, thousands of users grant hundreds of external
apps standing access to mail, Drive, calendars, and directory data with a single "Allow" click. These
tokens survive password resets, are invisible to most endpoint controls, and are rarely reviewed. One
over-scoped or compromised vendor can exfiltrate data at scale. Most organizations cannot even name
which apps hold restricted scopes today.

**The approach.** Using Google's **native API access control** model and the **Admin SDK** (Reports
and Directory APIs) driven by **Python** automation, the solution: (1) inventories connected apps and
scopes and risk-scores them; (2) classifies apps **Trusted / Limited / Blocked**; (3) configures
**Marketplace allowlisting** and **unverified-app blocking**; (4) reviews and revokes high-risk
tokens; and (5) stands up an **app-vetting/approval workflow**. It follows a strict **Assess →
Design → Configure → Pilot → Validate → Expand** model with explicit pass/fail gates and a documented
rollback for every org-wide change.

**Why it is safe and governed.** Nothing is changed org-wide before it is proven on a representative
pilot OU. The included Python tools are **read-only or dry-run by default**; every write and every
token revocation requires an explicit `--apply` flag and approver sign-off, and produces an evidence
log. No credentials or service-account keys live in code — automation uses Application Default
Credentials scoped to the minimum read-only APIs. Legal and compliance determinations remain with the
organization's security, legal, and data-governance functions; this solution provides the technical
inventory, controls, and evidence they need.

**Deliverables.** A complete implementation guide, requirements and testing procedures, best-practice
guidance, and **five Python tools** (inventory, access-control config helper, validation/report
generator, risky-grant revoker, and a scope-config helper) — everything a competent cloud/identity
engineer needs to run the governance to completion. Self-guided and tested, at a fraction of the cost
of a bespoke consulting engagement.
