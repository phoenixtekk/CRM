# Executive Summary — Enablement Kit: Microsoft Defender for Office 365

## The problem

Email is still the number-one way attackers get in, and **Microsoft Defender for Office 365 (MDO)**
is the platform meant to stop them — before and after delivery. Most teams that own it run the
prevention half on defaults and never learn the detection-and-response half, so the tool is bought
and under-driven. The predictable gaps:

- **No post-delivery visibility.** When a phish lands anyway, no one can quickly answer "who else got
  this?", "who clicked?", or "is it still in inboxes?" — because they never learned **Threat
  Explorer**.
- **Protection policies as a black box.** Anti-phishing, **Safe Links**, and **Safe Attachments** are
  configured once and never understood, so no one can read why a message was (or wasn’t) caught.
- **Untrained users, untested.** **Attack Simulation Training** — the safe way to measure who is
  susceptible and train them — sits unused.
- **Manual investigation.** **Automated Investigation & Response (AIR)** and email advanced hunting go
  unused, so removing a malicious message from dozens of mailboxes is done by hand.

## The solution

This is a **structured enablement enablement kit** — concepts, **guided hands-on labs**, a **take-home
runbook**, and a **knowledge-check** — that takes an admin or SOC analyst across the whole MDO
surface: **Threat Explorer** hunting, understanding **anti-phish / Safe Links / Safe Attachments**,
running **Attack Simulation Training**, working **AIR** in an approval posture, and **email advanced
hunting** with KQL. It is a **skills** product:

- **Teaches post-delivery hunting** — pivot in Threat Explorer on sender, URL, file, or click and see
  who received and who interacted.
- **Makes the protection policies legible** — inspect (read-only) how anti-phish, Safe Links, and
  Safe Attachments decide, so analysts can reason about verdicts.
- **Runs a safe, benign simulation** — measure susceptibility on a lab group and auto-assign training.
- **Practices AIR and remediation safely** — AIR held **approval-required**, remediation **previewed**
  only; ends in an **alert-only** custom detection and a **knowledge-check**.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure →
Pilot → Validate → Expand** — reframed for enablement. We confirm the MDO features are available and
email tables have data, stand up a small **lab user group** and a learner **cohort**, run the
**guided labs** read-only / preview-first against real telemetry, **validate** with a capstone and a
knowledge-check, and then **expand** — folding the skills, saved hunts, and detection into the live
email-security practice.

The package ships as **self-guided, click-by-click documentation plus a runnable email KQL lab pack
and four PowerShell helpers** that check readiness, run a chosen lab query read-only, score the
knowledge-check, and report cohort progress — all **read-only or preview-first**, with **no
credentials in code**.

## Why it matters

- **You see what happens after delivery** — who received, who clicked, whether it’s still in inboxes
  — in minutes, from Explorer and hunting.
- **Users get measurably safer** — real susceptibility data and targeted training, not a once-a-year
  slideshow.
- **Response is fast but controlled** — AIR and remediation understood and practiced safely, then run
  through approvals in real incidents.
- **A fraction of consulting cost** — the same disciplined method a Defender specialist would teach,
  delivered as a repeatable runbook you keep and re-run for new hires.

## Important boundaries

This is a **skills / enablement** product — it teaches people to hunt, simulate, and respond with
MDO. It **cross-references rather than repeats** two adjacent catalog solutions: the **Defender for
Office 365 (Plan 2): Threat Explorer, Attack Simulation & AIR** implementation solution (which turns
these features *on and operationalizes* them) and the **Microsoft 365 Mail Hygiene: Anti-Spam, EOP &
Defender for Office 365** solution (which *configures the prevention policies*). This enablement kit
**inspects** the protection policies read-only and **does not reconfigure** them. All labs are
**read-only or preview-first**: AIR stays **approval-required**, remediation is **previewed only**,
and no message is deleted in class. It provides the **technical skill and the labs**, not the
**decisions**: which users to simulate, acceptable click-rate, the AIR automation level, and every
production remediation are the customer’s **security-operations / HR-legal calls**. MDO features
(Threat Explorer, Attack Simulation, AIR, email tables) are **Plan-gated and evolve, and can differ
by cloud (Commercial vs GCC / GCC High)** — *verify current availability and licensing in your
tenant*.
