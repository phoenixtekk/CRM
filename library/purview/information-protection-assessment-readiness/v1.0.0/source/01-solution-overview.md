# 1. Solution Overview — Information Protection Assessment & Readiness (Microsoft Purview)

## What this solution is
This solution delivers a **posture assessment and readiness roadmap** for **information protection** in
**Microsoft Purview** — the sensitivity **labels**, **encryption/protection**, **content marking**,
**label publishing**, **Data Loss Prevention (DLP)**, **auto-labeling**, and the **sensitive information
types** that together protect an organization's data. It answers three questions with evidence:
**what protects the estate today, where the gaps are, and what to fix first.**

It is deliberately an **assessment**, not a rollout. It **measures** the current posture, **scores** it
against a readiness baseline, produces a **gap register** and a **prioritized information-protection
roadmap**, and **validates one recommended fix by piloting it in simulation/test** — a mode that reports
what a policy *would* do and changes nothing. Enforcing labels/DLP/auto-labeling tenant-wide is
**change-controlled follow-on work** and is out of scope by design.

## The posture-assessment model in one paragraph
Information protection in Purview is a stack of controls: **labels** classify (and can **encrypt** and
**mark**) content; **label policies** publish labels to users/locations; **auto-labeling** applies
labels to content at rest or in transit based on **sensitive information types (SITs)** or trainable
classifiers; and **DLP** detects and (when enforced) restricts risky handling of that content. A control
only protects data if it is **created, published, in the right mode, and scoped to the right
workloads**. This assessment walks that stack, records the state of each control, and finds where the
chain is broken — an unpublished label, a DLP policy stuck in test, a workload with no coverage, a label
that classifies but never encrypts.

## What "posture" means here (the six dimensions assessed)
1. **Classification taxonomy** — do sensitivity labels exist, are they enabled, and is the label set
   coherent (not a sprawl of orphan labels)?
2. **Label publishing & coverage** — are labels **published** (via label policies) to the right
   users/groups and locations, or do they sit unused?
3. **Encryption & protection** — do the labels that should encrypt actually apply **encryption /
   rights protection**, and are content markings (header/footer/watermark) set where required?
4. **Auto-labeling** — is **auto-labeling** configured, and in what **mode** (simulation vs. enabled),
   for content at rest (SharePoint/OneDrive/Exchange) and client-side?
5. **DLP coverage & mode** — which **workloads** (Exchange, SharePoint, OneDrive, Teams, Endpoint,
   Defender for Cloud Apps) have DLP, and are policies **enabled** or stuck in **test/simulation**?
6. **Sensitive information types** — are the **SITs** that define "sensitive" for this org present
   (built-in + any custom), and do labels/DLP actually reference them?

Each dimension yields findings; findings become **gaps**; gaps are **ranked** into the roadmap.

## What is authored exactly vs. deferred
- **Exact detail is given** for **Security & Compliance PowerShell** (`Connect-IPPSSession`:
  `Get-Label`, `Get-LabelPolicy`, `Get-DlpCompliancePolicy`, `Get-DlpComplianceRule`,
  `Get-AutoSensitivityLabelPolicy`, `Get-DlpSensitiveInformationType`) and the **Microsoft Purview
  portal** (`purview.microsoft.com`) navigation for **Information Protection**, **Data Loss Prevention**,
  and **Content/Activity Explorer**.
- **Licensing-gated capability** (auto-labeling, advanced DLP, Data Security Posture Management / DSPM)
  is **flagged**: where a feature is not readable the assessment records it as **"not available —
  verify your licensing/tenant"** rather than asserting it exists.
- **Content Explorer / Activity Explorer / DSPM** are **portal surfaces** with their own role
  requirements; the assessment cites where to read coverage there and does **not** invent an API that
  scrapes their contents.
- **Regulatory, records, and legal determinations** (what *must* be labeled/retained, records file
  plans, legal holds, regulatory applicability) are **deferred** to compliance/records/privacy/legal —
  this solution provides the technical posture and evidence, **not** the determination.

## The pilot-in-simulation principle
Every high-impact Purview control supports a **safe pre-enforcement mode**, and this assessment uses it:
- **Auto-labeling** runs in **simulation** (`Mode = TestWithoutNotifications`) — it evaluates content and
  reports what it **would** label, and applies **nothing**.
- **DLP** policies can be created in **test/simulation** (test with or without policy tips) before
  `Enable` — they detect and report without blocking.
- **Label publishing** can be piloted to a **small pilot group** before tenant-wide publish.

The single fix this engagement validates is proven in **simulation** — never enforced — so the roadmap
is credible without touching production behavior.

## Benefits
- **Know before you build** — a measured baseline of what protects the estate, not guesswork.
- **Prioritized, not overwhelming** — gaps ranked into quick wins vs. strategic work.
- **Defensible** — an evidenced posture scorecard you can show compliance and leadership.
- **Safe** — the validated fix is proven in **simulation**; nothing is enforced.
- **Repeatable** — re-run the discovery/scorecard to measure improvement over time.

## Limitations (be honest with buyers)
- **Assessment, not enforcement.** This measures posture and validates a fix in **simulation**; it does
  **not** roll out labels/DLP/auto-labeling. Enforcement is change-controlled follow-on work.
- **Licensing-dependent visibility.** Advanced DLP, auto-labeling, and DSPM require **E5 / E5
  Compliance**; where unlicensed, those dimensions are recorded as **not available**, not assumed.
- **Portal-only surfaces.** Content Explorer / Activity Explorer / DSPM coverage is read in the portal
  under their own roles — the scripts inventory policy *configuration*, not per-item content.
- **No determinations.** Whether specific data *must* be protected/retained is a
  compliance/records/legal call — deferred by design.

## The standard deployment model
> **Assess the posture → design the target state + roadmap → configure the assessment artifacts →
> pilot one recommended fix in SIMULATION → validate it would work → expand (enforce) as follow-on.**
> Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand**, with explicit
> pass/fail gates and a documented rollback for anything created.
