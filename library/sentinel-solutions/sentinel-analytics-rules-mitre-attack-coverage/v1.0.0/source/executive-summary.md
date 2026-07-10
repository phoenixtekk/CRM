# Executive Summary — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

## The problem

A SIEM that ingests logs but has no tuned detections is an **expensive log bucket**. Two failure modes
are common, and organizations usually suffer both at once:

- **Blind spots.** No one can say which attacker techniques the SIEM would actually catch. Coverage is
  assumed, not measured — so a whole class of intrusion (say, credential theft or privilege escalation)
  may raise no alert at all, and nobody knows until an incident makes it obvious.
- **Alert fatigue.** The detections that *are* on fire off constantly with false positives. Analysts
  learn to close them without looking, and a real alert drowns in the noise. A detection nobody trusts
  is worse than no detection — it consumes the team and provides false comfort.

The root cause is the same in both cases: rules were turned on (or left off) without a **map of what
matters** and without **tuning to the environment**.

## The solution

This solution turns raw telemetry into **detections the SOC can trust**, mapped to a shared language of
attacker behavior — the **MITRE ATT&CK** matrix. It:

- **Enables the right analytics rules** — Microsoft-provided **rule templates**, **scheduled** KQL
  rules, and **near-real-time (NRT)** rules — chosen against a coverage map, not at random.
- **Maps coverage to MITRE ATT&CK and does gap analysis** — so you can *see*, tactic by tactic and
  technique by technique, what you detect and where you are blind, and close the highest-risk gaps
  first.
- **Tunes thresholds and entity mappings to cut false positives** — turning noisy rules into precise
  ones with suppression, allow-lists, and environment-specific thresholds, so alerts are believable.
- **Adds watchlists and enrichment** — VIP users, authorized admin IPs, terminated staff, high-value
  assets — so detections carry context and fire smarter.
- **Exports detections as code** — every rule versioned in a repository (detection-as-code) so your
  detection logic is reviewable, repeatable, and portable across workspaces.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure → Pilot
→ Validate → Expand**. We first **map current coverage** and rank gaps by risk, then enable a small,
high-value set of rules and run them in a **low-impact pilot** (rules produce alerts you triage but do
not yet trigger automation), **tune** them against real data until the false-positive rate is
acceptable, **validate** that coverage improved and noise dropped, and only then **expand** across the
ATT&CK matrix. Anything disruptive is piloted before it is trusted.

The solution ships as **self-guided, click-by-click documentation plus five PowerShell tools** (Az /
Microsoft.Graph + KQL) that discover current rules and templates, build the ATT&CK coverage/gap matrix,
report per-rule alert and **false-positive** rates for tuning, validate the detection set against
pass/fail gates, and export the rules as code — all **read-only or export-only**, with **no credentials
in code**.

## Why it matters

- **Coverage you can see** — an ATT&CK map that shows exactly what you detect and where you are blind,
  so investment goes to the gaps that matter.
- **Alerts the team believes** — tuned thresholds and enrichment mean fewer false positives and faster,
  more confident triage.
- **Detections as durable assets** — versioned, reviewable, portable detection-as-code, not clicks in a
  portal that no one can reproduce.
- **A fraction of consulting cost** — the same disciplined method a detection engineer would use,
  delivered as a repeatable, tested runbook.

## Important boundaries

This solution **tunes and maps detections; it is not a guarantee of coverage** — MITRE ATT&CK is a
model, and a technique shown as "covered" means a rule targets it, not that every variant will be
caught. It **assumes the telemetry is already flowing**: rules can only detect what the workspace
ingests, so it depends on a connected, cost-aware foundation (the companion **Deploy Microsoft Sentinel:
Workspace, Data Connectors & Ingestion** solution). It **does not** decide your organization's **risk
tolerance, alerting priorities, or which techniques are in scope** — those are security-leadership
determinations; the solution provides the technical method and the measured coverage to inform them.
Microsoft rule templates, the NRT rule set, and ATT&CK technique mappings **evolve and can differ by
cloud (Commercial vs Government)** — *verify current availability in your tenant*.
