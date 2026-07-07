# Executive Summary

**Outcome.** "Outlook won't connect" is one of the highest-volume, most time-consuming ticket
categories any messaging support team carries — and, without a method, each one is solved by
guesswork: reboot, recreate the profile, escalate. This toolkit replaces the guesswork with a
**repeatable, layered diagnostic method** that resolves Outlook, Outlook on the web (OWA), and
mobile client-connectivity issues on **Exchange Online and hybrid** on first contact, with a
named root cause on every ticket.

**Approach.** The toolkit is a **symptom-to-root-cause decision tree** that walks a
connectivity problem down the four layers a mail client actually depends on — **Autodiscover
(discovery) → protocol endpoints (MAPI-over-HTTP / EWS / ActiveSync / OWA) → authentication
(modern auth / Conditional Access / MFA) → client profile and cached-mode state** — plus the
hybrid **free/busy** and **mobile** paths. At each node the playbook names the *exact* test to
run (`Test-OutlookConnectivity`, `Test-OutlookWebServices`, `Get-CASMailbox`, the Microsoft
Remote Connectivity Analyzer, sign-in logs) and the pass/fail branch, so the failing layer is
**isolated, not guessed**. Five PowerShell tools (Exchange Online PowerShell EXO V3 / Microsoft
Graph) automate the server-side half — a per-user connectivity and protocol assessment, an
Autodiscover/endpoint test, a modern-auth / Conditional-Access checker, a validation report,
and a scope/health helper.

**Why low-risk.** Every diagnostic is **read-only by default**; the single tool that can change
state defaults to a **dry-run that records the prior value** and requires an explicit `-Commit`
switch under change control. Nothing in the toolkit alters production mail flow, connectors, or
DNS as part of diagnosis. It is adopted the disciplined way — **Assess → Design → Configure →
Pilot → Validate → Expand** — proven on a pilot ticket batch against explicit pass/fail gates
before it becomes the standard first-contact runbook. Scripts carry **no hardcoded
credentials** and connect only via modern authentication.

**Bottom line.** The highest-volume mail tickets resolved on first contact — Autodiscover,
protocols, and authentication diagnosed by a repeatable decision tree with exact tests — means
less guesswork, faster fixes, fewer escalations, and, as the reporting loop surfaces systemic
causes, a *falling* volume of client-connectivity tickets over time.
