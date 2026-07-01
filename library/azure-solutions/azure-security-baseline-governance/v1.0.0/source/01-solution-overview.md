# 1. Solution Overview — Azure Security Baseline & Governance

## What Azure security baseline and governance is
Azure security baseline and governance is the discipline of putting **enforced guardrails** around an Azure estate so that secure configuration, least-privilege access, and a consistent baseline are the default — not something an admin has to remember. It combines four Azure capabilities: **management groups** (a hierarchy that lets one control apply to many subscriptions), **Azure Policy initiatives** (rules that audit or block non-compliant resources), **Azure role-based access control (RBAC)** tightened to least privilege, and **Microsoft Defender for Cloud** to measure and continuously improve posture.

## Why this matters
An Azure subscription without governance drifts fast. Owners accumulate standing privilege, storage accounts get created with public access, resources are deployed unencrypted or in disallowed regions, and there is no consistent baseline anyone can audit against — exactly the findings Defender for Cloud and external auditors flag. Governance turns those one-off mistakes into things Azure itself prevents (deny) or at minimum records (audit), and it gives you a single secure-score number that trends the right way over time. The goal is an estate that stays secure because the platform enforces it, proven on a small pilot scope before it is applied everywhere.

## How it works
1. A **management-group and subscription scope** is defined so one policy or role assignment can cover many subscriptions from a single point in the hierarchy.
2. **Azure Policy initiatives** (grouped policy sets) are assigned at that scope in **audit** effect first — they report non-compliant resources without blocking anything.
3. Once the audit picture is understood and false positives are exempted, the same guardrails are moved to **deny** effect so non-compliant resources can no longer be created.
4. **RBAC is tightened to least privilege** — standing Owner assignments are reduced, purpose-built **custom roles** replace over-broad built-in roles, and access is granted at the narrowest scope that still lets people work.
5. A **secure-configuration baseline** (encryption required, public network access restricted, allowed locations and SKUs, secure transfer, diagnostic logging) is expressed as policy so every resource inherits it.
6. **Microsoft Defender for Cloud** is enabled to produce a **secure score**, a **regulatory compliance** view, and prioritized **recommendations**; the top findings are remediated and the score is tracked each cycle.

## What you can control
- **Guardrail effect** — audit (report only) or deny (block creation) per policy, moved from one to the other on a controlled gate.
- **Least-privilege access** — custom roles, removal of standing Owner, and scope-narrowed assignments.
- **Allowed configuration** — required encryption, restricted public storage/network access, allowed locations (regions) and allowed SKUs/resource types.
- **Posture measurement** — Defender for Cloud secure score, regulatory-compliance mapping, and recommendation remediation.
- **Scope** — which management groups and subscriptions each guardrail and role applies to.

## Limitations (be honest with buyers)
- A **deny** policy blocks *new* non-compliant resources; it does not delete or reconfigure resources that already exist — those are remediated separately (audit findings, remediation tasks, or the remediation script).
- Some Defender for Cloud plans and features are **paid** per resource type; the free foundational CSPM covers secure score and recommendations, enhanced plans add more.
- Policy evaluation and compliance state are **not instantaneous** — new assignments can take time to evaluate; a manual compliance scan speeds this up.
- Tightening RBAC can break automation or people who relied on standing privilege — this is exactly why the model pilots on a narrow scope first and keeps a rollback.
- Governance reduces risk; it does not replace patching, backup, or workload-specific security controls.

## The standard Phoenixtekk deployment model
> **Define scope (management groups/subscriptions) → assign guardrail initiatives in audit → tighten RBAC to least privilege → apply the secure-config baseline → enable Defender for Cloud and remediate top findings → validate on a pilot scope → move guardrails to deny → expand.** Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand**, with an **audit-before-deny gate** and a documented rollback.
