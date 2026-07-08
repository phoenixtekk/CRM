# Executive Summary — Custom DLP Policy Development (Microsoft Purview)

Microsoft Purview ships with built-in, templated DLP policies — but they rarely fit real data. Your
organisation has its own document types, its own identifiers, and its own approved sharing paths, and a
template run unchanged produces noise: false positives that train users to click through every warning,
and false negatives that miss the data you actually care about. Worse, a DLP block shipped straight to
enforcement can stop legitimate business email and file sharing on day one. This solution fixes that: it
develops **custom DLP policies in Microsoft Purview, tuned to your exact data**, piloted safely, and
promoted to enforcement only once the evidence says they're ready.

It gives you a repeatable way to design **tailored conditions** — the right sensitive information types at
the right confidence and instance counts, plus labels and content/recipient conditions — with deliberate
**exceptions** for approved business flows, and **staged actions** (audit → notify → restrict/block →
encrypt). Every policy is created in **simulation / test mode first**, so it observes and records matches
with **zero user impact**; it is then tuned against that evidence and moved to enforcement under change
control. All of it is done with the Microsoft Purview portal and Security & Compliance PowerShell — no
third-party tooling.

This is a complete, deploy-it-today package for building and tuning custom DLP policies, written for a
competent M365 / compliance administrator.

## What you get
- A plain-language Solution Overview of how custom DLP maps to your data: conditions, actions, exceptions,
  and the simulate-first tuning loop.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including which workloads
  your licensing covers and which sensitive info types your conditions need.
- An Implementation Guide of precise, ordered portal + PowerShell steps, with the policy created in
  simulation, each policy/rule named, `-WhatIf` previews, and pass/fail gates + rollback at every stage.
- Five PowerShell scripts: environment discovery, a policy author/tuner (`-WhatIf` by default, simulation
  by default), a policy validator, a match reporter for tuning, and a scope/health helper.
- Testing and Troubleshooting guides for a confident, safe rollout.

## What this delivers
Custom DLP policies that fit your data — tailored conditions and sensitive info types, exceptions that keep
approved flows working, and staged actions — piloted in simulation with **no user impact**, tuned until the
false-positive and false-negative rates hit the agreed target, and only then enforced. The result is
data-loss protection that is precise, credible with users, and defensible in an audit.

## The deployment model
Assess → Design → Configure → Pilot (simulate) → Validate → Expand (enforce).

## Scope boundary
This solution develops the **policies and rules**. The data classes they reference — **custom sensitive
information types, Exact Data Match, document fingerprints, trainable classifiers, and sensitivity labels**
— are prerequisites built in their own dedicated solutions and consumed here as conditions. **Endpoint** and
**cloud-app** coverage have their own onboarding; this policy targets those locations once they're in place.
**What data is sensitive, and which regulations apply, is deferred to the organisation's compliance,
privacy, and legal functions** — this solution provides the technical configuration and the match evidence,
not the determination.

## Outcome
DLP tuned to your exact data in Microsoft Purview — custom policies with tailored conditions, sensitive
info types, exceptions, and tuning — delivered, validated in simulation, and enforced defensibly.
