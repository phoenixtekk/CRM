# Executive Summary

## The problem

Connectivity failures are among the most expensive and frustrating incidents in any managed
environment. A user "can't reach" an application, website, or cloud service; an identical machine
beside them works fine. The failure could be **DNS**, a **proxy or PAC misroute**, a **VPN
split-tunnel gap**, an **IP/port firewall block**, or a **URL/category filter** — and without a
method, teams *guess*: reboot, reinstall, blame the network. Guesswork burns hours, escalates the
wrong tickets to the wrong teams, and lets the same root cause recur.

## The solution

This toolkit replaces guessing with a **vendor-neutral, endpoint-side, layered root-cause method**. It
models every connection as a stack of layers — DNS → proxy/PAC → VPN → firewall → URL filter — and
gives you the **exact check that proves each layer** from the affected Windows endpoint. You isolate
the failure to **one** layer, prove it with saved evidence, and either fix it locally or escalate to
the owning team with proof instead of a hunch.

## What's inside

- A **Solution Overview** and layered model explaining the endpoint-to-service path.
- A **Requirements Guide** (endpoint access, a control device, exact targets, expected path).
- A **Diagnostic Playbook** — a symptom tree with per-layer checks for every common failure mode.
- **Five PowerShell scripts** — posture discovery, per-target reachability validation, a coverage
  report, safe local remediation (default preview mode), and a pilot-group builder.
- **Testing** (pass/fail gates that name the responsible layer), **Troubleshooting**, and **Best
  Practices** for repeatable, evidence-based triage.

## Why it matters

- **Faster resolution.** A defined top-down method finds the blocking layer in minutes, not a day of
  trial and error.
- **Right team, first time.** Evidence-backed escalation ("port to the target times out; control host
  on the same port succeeds") is actioned immediately instead of bouncing between teams.
- **Repeatable and reusable.** The same scripts and target lists apply to every connectivity incident
  and every new app rollout — you keep them and reuse them.
- **Safe.** Discovery, validation, and reporting are read-only; remediation and scope changes preview
  by default and only touch safe, local, reversible settings.

## Bottom line

The exact layer blocking the endpoint — DNS, proxy, VPN, or a filter — proven with a repeatable method
and scripts you keep and reuse on every connectivity incident. Vendor-neutral, self-guided, tested,
and a fraction of the cost of ad-hoc consulting.
