# Executive Summary — Microsoft Defender for Office 365

## What this is

The complete **Microsoft Defender for Office 365 (MDO)** solution for the phase most teams never
reach: **operating** the product for detection and response, **enabling** the people who run it, and
**proving** — in your own tenant, on real-but-safe signal — that it works. Blocking spam is table
stakes; the value of MDO is post-delivery **hunting, investigation, and response**, and a team that
can drive it. This package takes MDO end to end across two joined tracks:

- **Enable the team** — a set of **guided hands-on labs** that upskill admins and SOC analysts on the
  whole MDO surface: **Threat Explorer** hunting, reading the **anti-phish / Safe Links / Safe
  Attachments** protection stack, running **Attack Simulation Training**, working **Automated
  Investigation & Response (AIR)** in an approval posture, and **email advanced hunting** with KQL.
- **Prove value** — a **scoped, safe, reversible proof of concept** that generates benign, simulated
  test signal (Attack Simulation Training, the **GTUBE** spam-test string, the **EICAR** test file, a
  benign **Safe Links** test URL — never real phishing or malware), demonstrates the headline
  detections on that signal, captures the evidence, and cleanly cleans up.

## The outcome

A team that can **hunt, simulate, investigate, and respond** on email with MDO, and a documented,
in-tenant **proof** that the product catches phishing and malicious mail on your own mail flow — the
evidence a stakeholder needs to commit, and the skills to keep operating it afterward.

## The boundary — this is the operate/enable/prove layer

This solution deliberately **does not re-do configuration or onboarding**. It sits **on top of** two
adjacent catalog solutions and **cross-references** them rather than repeating them:

- **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for Office 365** — *configures the
  prevention policies* (anti-spam/-malware/-phishing, Safe Links, Safe Attachments, connection
  filtering, mail-flow hygiene). This solution **inspects** those policies read-only to teach how
  verdicts are produced; it does **not** reconfigure them.
- **Defender for Office 365 (Plan 2) — Threat Explorer, Attack Simulation & AIR** — *turns the
  post-delivery features on and operationalises them across the org*. This solution builds the
  **skill and the proof**; that solution owns the **production rollout and tuning**.

All labs and the PoC are **read-only or preview-first**: AIR stays **approval-required**, remediation
is **previewed only**, Threat Explorer take-action is understood but not executed against production,
the capstone detection is **alert-only**, and every PoC change is **`-WhatIf`-gated** and reversible.
This solution provides the **technical skill, the labs, and the proof** — not the **decisions**: which
users to simulate, acceptable click-rate, the AIR automation level, what counts as a "pass," and every
production remediation are the customer's **security-operations / HR-legal** calls.

## Effort

A competent administrator can run the enablement labs with a small learner cohort and complete the
scoped PoC — signal, demonstrate, validate, capture evidence, and clean up — in a short, focused
engagement on a handful of pilot mailboxes. No organisation-wide mail-flow change is required, and
every step is reversible.

**Licensing note:** Threat Explorer, Attack Simulation Training, AIR, and the email advanced-hunting
tables require **Defender for Office 365 Plan 2** — *verify current availability and licensing in your
tenant; feature availability can differ by cloud (Commercial vs GCC / GCC High).*
