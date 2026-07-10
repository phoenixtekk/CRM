# Best Practices — Microsoft Sentinel Analytics Rules & MITRE ATT&CK Detection Coverage

Keep-it-clean guidance for a detection program that stays trusted, measured, and current over time.

## Detect against a map, not a checklist

- **Measure coverage; don't assume it.** Enable rules against the **risk-ranked ATT&CK gaps** you
  measured, not the longest list of templates. A rule that duplicates existing coverage adds noise, not
  protection.
- **Coverage is depth, not just breadth.** A technique cell showing "covered" means a rule targets it —
  not that every variant is caught. Prefer a few good detections per high-risk technique over one shallow
  rule per cell.
- **Re-map after every change.** New connectors, new templates, and retired rules all move the map.
  Re-run `SENTRULE-Coverage.ps1` on a cadence so the picture stays honest.

## Tune for trust — a noisy detection is a liability

- **A rule the SOC ignores is worse than no rule.** It consumes the team and gives false comfort. Treat
  the **false-positive rate** as a first-class success metric, measured per rule.
- **Tune cheapest-and-safest first:** allow-list known-good (watchlists) → suppress with an automation
  rule → raise threshold/tighten window → refine grouping/entities. Change **one thing at a time** and
  re-measure.
- **Suppress, don't blind.** Prefer suppressing a known-benign pattern with `AR-Suppress-KnownScanners-
  Pilot` over gutting the detection logic — you keep the detection for the case that matters.
- **Group alerts into meaningful incidents.** Map entities and set grouping so 50 related alerts become
  one triage-able incident, not 50 tickets.

## Pilot before you trust

- **Low-impact posture first.** Run new rules with **incident creation disabled** so they generate
  measurable alerts without flooding the queue or driving automation. Promote only after the
  false-positive rate meets the agreed tolerance.
- **Set the tolerance with leadership, not in the tool.** Which techniques matter and what noise is
  acceptable are **risk decisions (R5)**. The solution measures; leadership decides.

## Enrich for precision

- **Keep watchlists current.** A stale `WL-TerminatedUsers-Tenant` misses exactly the risk it exists to
  catch. Assign an owner and a refresh cadence to every watchlist.
- **Key detections on context.** Use watchlists to fire *only* for VIP/high-value accounts or assets, and
  to suppress sanctioned admin IPs/scanners — precision beats volume.

## Treat detections as code

- **Version every rule.** Export tuned rules with `SENTRULE-Export.ps1` (or Sentinel Repositories) and
  commit them. Detection logic living only in the portal is unreviewable and unrecoverable.
- **Review and diff changes.** A tuning change is a code change — review it, and keep the previous version
  as a one-click rollback.
- **Make detections portable.** Detection-as-code lets you promote the same rule from test to production,
  or across workspaces/tenants, without re-clicking.

## Run it as a program

- **Loop, don't launch-and-forget.** Map → enable → pilot → tune → validate → expand, then take the next
  batch of gaps. Coverage and noise both drift; the loop keeps them honest.
- **Watch the trend.** A falling false-positive rate and a growing covered-technique count are the signs
  the program is working; track them.

## Where to go next

With detections tuned and ATT&CK-mapped, the natural next steps in this catalog are:

- **Sentinel SOAR / automation** — turn the trusted incidents these rules raise into automated response
  (enrichment, containment, notification) with playbooks and automation rules.
- **Deploy Microsoft Sentinel: Workspace, Data Connectors & Ingestion** — the foundation this layer
  depends on; revisit it to add the sources that close coverage gaps you cannot yet detect.
- **Threat hunting / notebooks** — proactive hunting on the same telemetry to find what scheduled rules
  do not.
- **Microsoft Defender XDR** and **Entra ID** hardening solutions — reduce the attack surface the
  detections watch.
