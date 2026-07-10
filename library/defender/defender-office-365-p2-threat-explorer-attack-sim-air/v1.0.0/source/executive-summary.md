# Executive Summary — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

## The problem

Blocking spam and known malware at the gateway is table stakes — and it is only half of email
security. The threats that matter most are the ones that **land in a mailbox anyway**: a
convincing credential-harvesting page a user clicks an hour after delivery, a payload that is
weaponized after it arrived clean, a targeted phish that slips past the filter. Organizations that
own **Defender for Office 365 Plan 2** usually run only its *prevention* half and leave its
detection-and-response half switched off. The result is a predictable set of gaps:

- **No post-delivery visibility.** Once mail is delivered, no one can quickly answer "who else got
  this?", "who clicked?", or "is it still in inboxes?" — so cleanup is manual, slow, and incomplete.
- **Untrained users.** The single most-exploited control — the human — is never safely tested, so
  there is no measured picture of who is susceptible and no targeted training to fix it.
- **Manual, inconsistent response.** Removing a malicious message from dozens of mailboxes is done
  by hand, one investigation at a time, with no repeatable playbook and no approval trail.

## The solution

This solution turns on and operationalizes the **detect / hunt / simulate / auto-respond** half of
Defender for Office 365 Plan 2 — the value that lives *after* delivery. It:

- **Stands up Threat Explorer / Real-time detections** so you can hunt post-delivery email threats —
  pivot on sender, URL, file, or click, and see exactly who received and who interacted.
- **Runs Attack Simulation Training** — safe, benign phishing campaigns that measure who is
  susceptible and auto-assign targeted training, with user-risk reporting to track improvement.
- **Enables Automated Investigation & Response (AIR)** — alert-triggered investigations that gather
  evidence and *recommend* remediation, held behind **explicit approval** until you trust them.
- **Provides an email Advanced Hunting query library and custom detections** — reusable KQL over the
  email tables to find threats the built-in alerts miss.
- **Makes remediation deliberate** — soft-delete, hard-delete, and ZAP-style purge actions run
  through the **Action center with approval gates**, never silently.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure →
Pilot → Validate → Expand**. We first inventory what Plan 2 features are licensed and available,
then configure Explorer, a first Attack Simulation campaign, and AIR in an **approval-required**
posture, run everything against a small **pilot group** first, validate that hunting works and
remediation is gated, and only then expand across the organization. Nothing disruptive — no
simulation to all staff, no automated deletion — happens before it is trusted.

The solution ships as **self-guided, click-by-click documentation plus five PowerShell tools**
(Microsoft.Graph security + Exchange Online / Security & Compliance) and a **KQL hunting library**
that inventory Plan 2 readiness, run email Advanced Hunting, report post-delivery threats and
attack-simulation user risk, validate the configuration against pass/fail gates, and **preview**
remediation actions — all **read-only or preview-first**, with **no credentials in code**.

## Why it matters

- **You see what happens after delivery** — who received it, who clicked, whether it is still in
  inboxes — in minutes instead of a manual mailbox-by-mailbox hunt.
- **Your users get measurably safer** — real susceptibility data and targeted training instead of a
  once-a-year slideshow.
- **Response is fast but controlled** — repeatable, approval-gated remediation with an audit trail,
  not ad-hoc deletions.
- **A fraction of consulting cost** — the same disciplined method a Defender specialist would use,
  delivered as a repeatable, tested runbook.

## Important boundaries

This is the **post-delivery detect / hunt / simulate / respond** layer of Defender for Office 365.
It **deliberately does not cover** anti-spam, anti-malware, anti-phishing policy, Safe Links / Safe
Attachments, connection filtering, or mail-flow hygiene — that **prevention** layer is the companion
*Microsoft 365 Mail Hygiene: Anti-Spam, EOP & Defender for Office 365* solution, which this one
assumes is already in place and **cross-references rather than repeats**. It **requires Defender for
Office 365 Plan 2** (Threat Explorer, Attack Simulation Training, AIR, and the email Advanced
Hunting tables are Plan 2 features) — *verify current availability and licensing in your tenant*.
It provides the **technical controls**, not the **decisions**: which users to simulate, what
counts as acceptable click-rate, and every production remediation approval are the customer's
security-operations calls. Feature names, automation behavior, and table schemas **evolve and can
differ by cloud (Commercial vs GCC / GCC High)** — *verify current availability in your tenant*.
