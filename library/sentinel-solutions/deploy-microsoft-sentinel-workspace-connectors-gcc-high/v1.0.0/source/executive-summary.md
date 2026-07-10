# Executive Summary — Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion — Government (GCC High)

> **Government (GCC High) edition.** This is the US Government national-cloud edition for public-sector
> and defense-industrial-base tenants — the same disciplined method as the commercial version, adapted
> for **Microsoft Sentinel on Azure Government** (`portal.azure.us`, `security.microsoft.us`,
> `login.microsoftonline.us`, `graph.microsoft.us`) and the FedRAMP High / DoD IL4–IL5 / CMMC context.
> Connector and feature availability in GCC High/DoD can lag or differ from commercial; every such point
> is flagged **"verify against current Microsoft Government documentation"** (see
> `gcc-high-parity-notes.md`).

## The problem

Most Microsoft Sentinel deployments start the same way: someone clicks **Enable**, connects every data
source on the list, and turns on every rule template. Within a month the workspace is ingesting
hundreds of gigabytes a day, the monthly bill is a surprise, half the connected sources feed
detections nobody wrote, and no one can say whether a critical log is actually arriving. The result is
a SIEM that is simultaneously **too expensive** and **not trustworthy** — the two things a SIEM must
never be.

The failure is not the tool; it is the order of operations. Sentinel is built on a Log Analytics
workspace, and once telemetry lands in that workspace it costs money to ingest and to retain. Decisions
about **which workspace, which region, which sources, which tier, and how long to keep the data** are
cheap to make up front and expensive to unwind later.

## The solution

This solution stands Sentinel up **in the right order**. It builds a properly sized, governed Log
Analytics workspace with least-privilege access, connects the **high-value** data sources a real
detection program needs — **Microsoft Entra ID, Microsoft Defender XDR, Office 365, Azure Activity, and
syslog/CEF via the Azure Monitor Agent (AMA) and Data Collection Rules (DCRs)** — and shapes ingestion
so you collect **what detections actually consume**, not everything a connector can emit.

Concretely, it delivers:

- A **workspace and RBAC design** — one right-sized workspace (`Security Telemetry - Tenant -
  Workspace`) with reader/responder/contributor access split across named security groups.
- A **connector plan** — the five high-value sources above, each with a named diagnostic setting or DCR
  so you know exactly what is flowing and can turn it off cleanly.
- **Data Collection Rules that filter noise before it is billed** — dropping the informational syslog
  and verbose CEF that inflate cost without improving detection.
- A **table plan** — which tables belong on the **Analytics** tier (queryable, detection-driving) and
  which belong on **Basic/Auxiliary** logs (cheap, search-only) — plus a **retention and archive**
  decision per table.
- **Connector health monitoring** — so you can prove data is still arriving and catch ingestion drift
  before a detection silently goes blind.

## How it works

We follow the same repeatable model every solution in this program uses — **Assess → Configure → Pilot
→ Validate → Expand**. We confirm the workspace design and cost plan first, connect one high-value
source and prove it end to end, add the noisy AMA/syslog/CEF path behind a **filtering DCR**, validate
that the right data is arriving at a controlled volume, and only then expand to the full source list.
Every object is named and reused; every ingestion change is reversible.

The solution ships as **self-guided, click-by-click documentation plus five PowerShell tools** (Az /
Microsoft.Graph modules, with KQL for the reporting) that discover the current workspace and connector
state, preview and apply diagnostic settings and retention with **`-WhatIf` by default**, validate the
build against pass/fail gates, and report ingestion volume and connector health — all **read-only or
preview-first**, with **no credentials in code**.

## Why it matters

- **The right data, not all data** — detections are fed by the sources that matter, at a volume you
  chose deliberately.
- **Cost under control from day one** — DCR filtering and a deliberate Analytics-vs-Basic table plan
  stop the runaway bill before it starts.
- **Governed access** — least-privilege RBAC on the workspace, not blanket contributor for everyone.
- **Provable and reversible** — you can show what is arriving and how much it costs, and unwind any
  change cleanly.
- **A fraction of consulting cost** — the same disciplined method a specialist would use, delivered as
  a repeatable, tested runbook you reuse on every rollout.

## Important boundaries

This solution builds the **foundation** — a governed workspace collecting the right data at a controlled
cost. It **does not** author the analytics rules or MITRE ATT&CK coverage that turn this data into
detections; that is the companion **Sentinel Analytics Rules & MITRE ATT&CK Coverage** solution, which
this foundation is designed to feed. Sentinel and Log Analytics pricing, tier availability (Basic vs
Auxiliary logs), and some connector capabilities **change over time and differ by cloud (Commercial vs
Government)** — capability and cost should be **verified against your tenant, region, and current
Microsoft pricing** before you commit. Data-residency, retention-duration, and log-category decisions
that carry regulatory weight are **determinations for your organization's compliance and security
functions**; this solution provides the technical controls, not the decision.
