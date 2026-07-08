# Solution Overview — Adaptive Protection in Microsoft Purview

## What this solution delivers

Most data-protection programs apply **the same controls to everyone**. The finance analyst who has
never triggered a single alert is blocked exactly as hard — or as softly — as the person who copied
a customer database to a USB stick on the day they resigned. Static controls are blunt: turn them up
and you throttle the whole organization; turn them down and you leave the genuinely risky user
under-controlled. **Microsoft Purview Adaptive Protection** closes that gap. It takes the **insider
risk level** Purview already computes for a user (**Elevated / Moderate / Minor**) and feeds it, as a
**live condition**, into your protective controls — so protection **dials up automatically for the
users who are actually behaving riskily** and stays out of the way for everyone else.

This solution walks a competent-but-novice administrator through a **complete, repeatable Adaptive
Protection deployment**:

1. **Stand up (or confirm) the insider-risk signal that drives everything** — Adaptive Protection is
   powered by **Insider Risk Management (IRM)**: an insider-risk policy scores activity, and Adaptive
   Protection maps that scoring onto the three dynamic risk levels. No IRM signal, no adaptive
   behavior.
2. **Configure Adaptive Protection** — using **Quick setup** (Microsoft's recommended default
   mapping) or **Custom setup** (map each risk level to specific insider-risk policies and
   thresholds), so users start receiving a **dynamic, time-bound risk level**.
3. **Make the risk level enforce protection** across three surfaces, **piloted in simulation/test /
   report-only first**:
   - **Data Loss Prevention (DLP)** — a DLP policy whose rules use *"a user's risk level for adaptive
     protection is …"* as a condition, so the **same** attempted action is **audited** for a Minor
     user, **warned/overridable** for a Moderate user, and **blocked** for an Elevated user — and, by
     scoping the rules to **sensitivity-labeled** content, protection on your most sensitive
     (labeled) data scales with the person handling it.
   - **Microsoft Entra Conditional Access** — an insider-risk-conditioned access policy that can
     **block, step-up, or limit the session** for Elevated-risk users, deployed in **report-only**
     first.
4. **Validate, then expand** — prove the end-to-end path (activity → score → risk level → DLP/CA
   action) with a **sanctioned test**, then widen scope deliberately.

Together these turn a **blunt, one-size-fits-all posture** into a **risk-adaptive** one: strong where
it needs to be, frictionless where it does not — configured, piloted, validated, and defensible.

## Adaptive Protection is built on people-monitoring signals — read this first

Adaptive Protection is **driven by Insider Risk Management**, which evaluates **people's activity**.
That inherits IRM's employee-privacy, works-council, labour-law, and data-protection obligations —
this is **not** a plain DLP or labeling project. Three principles run through every step:

- **Privacy by design in the source signal.** The IRM policy that feeds Adaptive Protection runs with
  IRM's **anonymization (pseudonymization)** guardrails and **role separation** intact. Adaptive
  Protection consumes a **risk level**, not a dossier — but the signal underneath it is people data,
  so scope to the **minimum** population and keep the IRM privacy posture on.
- **The risk level automates protection, not judgement.** A user reaching *Elevated* means their
  **controls tighten** — it is **not** a finding of misconduct. Whether risky activity reflects
  wrongdoing, and any consequence, remains an **HR/legal determination** (see IRM), never a technical
  default and never the administrator's call.
- **High-impact, so pilot first.** DLP block actions and Conditional Access grant controls can stop
  legitimate work if mis-scoped. **Every** protective control here is deployed in
  **simulation/test (DLP)** or **report-only (Conditional Access)** first, validated, and only then
  enforced.

> **Deploy this with HR, legal, and privacy** (and, where applicable, works-council / employee
> representatives) — the same stakeholders IRM requires. The **lawful basis / applicability** of
> monitoring is a **legal determination** for your organization; this solution provides the technical
> method and the guardrails, not the legal decision (see `global-requirements-purview.md` §5).

## The Adaptive Protection model — how the pieces fit

- **Risk levels.** Adaptive Protection classifies each in-scope user into one of three **dynamic,
  time-bound** levels: **Elevated**, **Moderate**, or **Minor**. The level rises when the user's
  insider-risk activity crosses the mapped threshold and **decreases automatically** over time as
  behavior normalizes — so protection is responsive, not permanent.
- **The source signal (IRM).** The levels are derived from **Insider Risk Management** scoring. You
  either let Adaptive Protection use the **recommended default** (Quick setup, backed by a Microsoft
  default insider-risk policy) or map levels to **specific insider-risk policies and thresholds**
  (Custom setup) — e.g. *Elevated = a high-severity insider-risk alert; Moderate = medium; Minor =
  low*.
- **The protective controls (consumers of the level).** Once Adaptive Protection is on, the risk
  level becomes a **selectable condition** in:
  - **Purview DLP** — the condition *"the user's risk level for adaptive protection is
    Elevated/Moderate/Minor"* on DLP rules, so actions (audit → warn/override → block) scale with the
    level. Combine with a **sensitivity-label** condition to make the strongest protection apply to
    labeled sensitive content.
  - **Entra Conditional Access** — the **Insider risk** condition, so access controls (block / require
    MFA / limited session) apply to Elevated-risk users.
- **The loop.** Activity → IRM scores it → Adaptive Protection assigns a level → DLP/CA read the level
  and adapt → as behavior normalizes the level decays and controls relax. It is **self-adjusting** by
  design.

> **Label enforcement, precisely.** "Label enforcement" here means **DLP rules that combine the
> adaptive-protection risk-level condition with a sensitivity-label condition** — protection on
> labeled content scales with the handler's risk. The **primary, documented** Adaptive Protection
> integrations are **DLP** and **Conditional Access**; treat any additional integration as
> **"verify availability in your licensing/tenant."**

## The standard deployment model

Every step follows the same repeatable model, with an explicit **pass/fail gate** between phases:

**Assess → Design → Configure → Pilot (simulation/test / report-only) → Validate → Expand (enforce).**

- **Assess** — confirm licensing (E5 / E5 Compliance for IRM + DLP; **Entra ID P2** for the CA
  integration), roles, the IRM signal, the in-scope labeled data, and HR/legal/privacy sign-off.
- **Design** — decide Quick vs Custom setup and the level→threshold mapping, the DLP rules per level,
  the CA control for Elevated, the pilot scope, and name every object — **with HR/legal**.
- **Configure** — confirm/stand up the IRM source policy, enable Adaptive Protection, then build the
  DLP policy (in **simulation/test**) and the CA policy (in **report-only**).
- **Pilot** — run in simulation/test/report-only; verify levels are assigned and rules *would* act,
  without blocking anyone yet.
- **Validate** — run the pass/fail gates in `05-testing.md`.
- **Expand** — turn DLP to enforce and CA to on, then widen scope **only** after the gate passes.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting**, **Best Practices**, and a **Deliverables Summary** + **Executive
  Summary**.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph): an Adaptive Protection
  **readiness/discovery** assessment, a **DLP-policy configuration helper** (`-WhatIf`/simulation
  first), a **validation** checker, an **enforcement reporting** rollup, and a **scope helper** —
  read-only or `-WhatIf` by default; **no credentials in code**.

> **Sources:** Microsoft Learn — *Adaptive Protection in Microsoft Purview* (learn about / quick &
> custom setup, risk levels), *Insider Risk Management*, *Data Loss Prevention* (conditions/actions,
> simulation mode), and *Microsoft Entra Conditional Access* (insider risk condition, report-only).
> Adaptive Protection is **licensing-dependent** (Microsoft 365 E5 / E5 Compliance for IRM + DLP;
> **Entra ID P2** for the Conditional Access integration; some capabilities may be in preview) and the
> Purview/Entra portals are **evolving** — **verify capability availability and portal paths against
> your licensing/tenant** rather than assuming.
