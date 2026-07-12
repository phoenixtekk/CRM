# Executive Summary — Enablement Kit: Multi-Factor Authentication & Conditional Access

White-label · Entra ID Solutions

## The problem

Multi-Factor Authentication and Conditional Access are the front line of identity security in
Microsoft Entra — and they are also the single easiest place to lock the whole company out of its own
tenant. A team that does not deeply understand MFA methods, how a Conditional Access policy is
evaluated, and how to test a policy *before* it can block anyone tends to swing between two failures:
too timid (gaps left open because nobody dares turn a policy on) or too reckless (an overbroad policy
saved straight to enforcement that locks out real users, or worse, the admins). The missing thing is
not another policy — it is a team that can **design, test, and troubleshoot** MFA and CA safely.

## The solution

This is a **self-guided enablement kit** — concepts, **guided hands-on labs**, a **take-home
runbook**, and a **knowledge-check** — that levels a team up on Microsoft Entra MFA and Conditional
Access. It is deliberately a **skills** product and is **distinct from the CA implementation
solutions** in this catalog (the Zero Trust Conditional Access Baseline and Conditional Access
Integration *deploy and operate* a production baseline). This kit builds the **capability**: the
team learns MFA methods (including phishing-resistant), CA design patterns and personas, and — most
importantly — the **report-only + What-If** discipline that lets them practice on real Entra **with
no lockouts**.

- **Teaches MFA methods properly** — from SMS (weak) through authenticator to phishing-resistant
  FIDO2/passkeys, plus registration and the authentication-methods policy.
- **Teaches CA by design, not by accident** — the anatomy of a policy, personas
  (admins/internals/guests/service accounts), and the common baseline patterns — as *understanding*,
  not a copy-paste.
- **Ships report-only, no-lockout labs** — every lab policy is built in **report-only**, validated
  with the **What-If** tool, with **break-glass** protected throughout — so learning is safe.
- **Teaches troubleshooting** — how to read a sign-in failure and trace exactly why a Conditional
  Access policy did or did not apply.

## What you get

- A plain-language **Solution Overview** of MFA methods and the Conditional Access model — signals,
  conditions, grant/session controls, personas, report-only, What-If, and break-glass.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific
  prerequisite (on top of the shared category requirements).
- An **Implementation Guide** structured as guided labs — MFA methods & registration, CA anatomy, CA
  design patterns & personas, building **report-only** policies, **What-If** testing, and
  sign-in/CA-evaluation troubleshooting — then a capstone and knowledge-check.
- **Five lab helpers** — a read-only MFA/CA discovery, a gated report-only lab-policy builder (preview
  by default), a sign-in/CA-evaluation **KQL lab pack**, a read-only validation/knowledge-check
  runner, and a report-only-impact + cohort report.
- **Testing and Troubleshooting** guides so the team learns to validate and self-diagnose.

## What this delivers

A team that can **design, test, and troubleshoot** MFA and Conditional Access on Microsoft Entra
safely — choosing the right MFA methods, building CA policies by persona, proving every policy in
report-only and What-If before it can enforce, protecting break-glass, and reading a sign-in log to
explain a CA decision — plus a take-home runbook and a passed knowledge-check.

## The standard deployment model

Assess -> Configure -> Pilot -> Validate -> Expand — reframed for enablement: assess readiness,
configure the cohort and lab persona groups, run the guided labs (pilot) in report-only, validate
skills with a capstone and knowledge-check, then expand into the real CA baseline solutions.

## Outcome

Confident MFA and Conditional Access policies designed, tested, and troubleshot by a team that
understands them — no lockouts, no gaps — and a clear on-ramp to the production CA implementation
solutions.

## Important boundaries

This is a **skills / enablement** product — it teaches a team to design, test, and troubleshoot MFA
and CA. It is **adjacent to, and deliberately does not duplicate**, the catalog's CA **implementation**
solutions: the **Zero Trust Conditional Access Baseline (ENTZTCA)** and **Conditional Access
Integration** *design and roll out a production, enforced baseline*; this kit builds the *team
capability* and practices in **report-only** only. It cross-references the **Passwordless & Passkey
(ENTPASSKEY)**, **PIM (ENTPIM)**, **Identity Governance (ENTIGA)**, and **Hybrid Identity** solutions
rather than repeating them. Every lab policy is **report-only** and can never enforce; break-glass is
protected throughout. Where a feature needs a specific license (Entra ID P1 for CA, **P2** for
risk-based conditions and PIM) or is in preview, this kit flags it — *verify current availability and
licensing in your tenant*, which can differ by cloud (Commercial vs GCC / GCC High).
