# Executive Summary — Microsoft Purview for Education (FERPA)

Schools, districts, colleges, and universities hold some of the most sensitive personal data there
is — **student education records** protected under **FERPA** (the U.S. Family Educational Rights and
Privacy Act), plus staff PII, health and counseling notes, financial-aid data, and research. A
generic, out-of-the-box Purview configuration does not reflect an education institution's specific
data-protection obligations: it leaves a **compliance gap** and a **data-risk exposure**. The fix is
a Purview program **tailored to education** — sensitivity labels, Data Loss Prevention (DLP),
retention/records, and compliance posture aligned to **FERPA** and the way education data actually
flows.

This solution delivers that end to end in **Microsoft Purview**: an education-tailored label taxonomy,
FERPA-oriented DLP, a student-record retention approach, and a Compliance Manager posture —
**configured, piloted in simulation/test where the capability supports it, validated against pass/fail
gates, and made operable**. It is an **industry bundle**: it composes the institution's program and
references the granular Purview capability products (label taxonomy, DLP packs, retention/records,
Compliance Manager) so the pieces fit together for an education tenant rather than being wired up
in isolation.

## What you get
- A plain-language **Solution Overview** of the education-tailored Purview program and the
  **Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce)** model.
- A **Requirements Guide** with **verify / implement-if-missing** for every prerequisite —
  compliance licensing (E5 / E5 Compliance where features require it), least-privilege Purview roles,
  in-scope education workloads and data, and the compliance/records/privacy/legal stakeholders. The
  six category-wide Purview requirements are **referenced, not repeated**.
- An **Implementation Guide** of precise, ordered **Purview portal + Security & Compliance PowerShell
  + Graph** steps: publish the education label set, stand up FERPA-oriented DLP in **Test/simulation**,
  configure student-record retention, and set the Compliance Manager posture — each label/policy/object
  **named**, **piloted in simulation first**, with pass/fail gates and rollback.
- **Five PowerShell scripts** — Discovery, Configuration/Remediation (simulation / `-WhatIf` first),
  Validation, Reporting, and a scope/health helper — via **Security & Compliance PowerShell**
  (`Connect-IPPSSession`) and/or **Microsoft Graph**, read-only or `-WhatIf` by default, **no
  credentials in code**.
- **Testing** and **Troubleshooting** guides and a **Best Practices** section for a confident rollout.

## What this delivers
An education institution whose Purview program **fits FERPA and the education data estate** — student
records labeled and protected, DLP catching education-record leaks (proven in simulation before it
blocks anyone), retention aligned to the records schedule, and a defensible, evidenced compliance
posture.

## The deployment model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** — build the
labels, DLP, and retention; prove them in simulation/test on a pilot scope; validate against
pass/fail gates; then enforce and expand in waves.

## An honest note
Microsoft Purview capabilities are **heavily licensing-/plan-dependent** (many require **Microsoft 365
E5** or the **E5 Compliance** add-on; some are in preview) and the portal is **actively evolving** —
this package **cites Microsoft's public documentation or flags "verify your licensing/tenant"** rather
than asserting availability or inventing portal paths. **Regulatory, records-retention, and legal
determinations** — FERPA applicability, the records schedule, retention periods, legal holds — are
**deferred to the institution's compliance, records, privacy, and legal functions**. This solution
provides the technical configuration method and the evidence, **not** the determination. High-impact
policies (DLP, labels, retention) are always **piloted in simulation/test first**.

## Outcome
A Microsoft Purview program **tailored to education and aligned to FERPA** — configured, piloted,
validated, and defensible — so the capability is in place and evidenced, not left as a generic
default.
