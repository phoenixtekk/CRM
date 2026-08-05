# Deliverables Summary

Everything in this solution, and how the pieces fit together. Delivered as a single ZIP you keep and
reuse across unlimited investigations.

## Documents (Word + PDF)

| Document | What it gives you |
|---|---|
| **Executive Summary** | The problem, the method, and the key verified facts for a decision-maker. |
| **Solution Overview** (`01`) | What the `/beta/copilot/admin/*` surface is, the GA-vs-beta support posture, the 401-vs-403 and scope-vs-role distinctions, and the diagnostic model. |
| **Requirements** (`02`) | The nine prerequisites to call the endpoints — tooling, delegated admin, exact scopes, admin role, consent, correct cloud, licensing, tenant flighting, and the evidence file — each with Description / Why / Verify / Implement-if-missing. |
| **Global Requirements — Copilot** | The category-wide Copilot prerequisites (tenant, licensing, identity, data readiness, roles, governance). |
| **Diagnostic Runbook** (`03`) | The core: Step 0 fact-finding plus **Branches A–J**, one per root cause, each with symptom → confirm → fix/workaround → re-validate. |
| **Testing & Validation** (`05`) | Five PASS/FAIL gates that prove the call now works **and** whether the data is truly exposed or needs a fallback. |
| **Troubleshooting** (`06`) | Edge cases: throttling storms, tenant-not-enabled flighting, undocumented-endpoint deprecation, tooling/consent snags. |
| **Best Practices** (`07`) | When to depend on beta vs wait for GA, and how to wrap a beta dependency so it fails safe. |

## PowerShell scripts (5, read-only, cloud-aware)

All scripts accept `-Environment Global | USGov | USGovDoD` and perform **GET requests only** — they
never change tenant state and never fabricate a response for a beta endpoint.

| Script | Purpose |
|---|---|
| `CPADMDX-Preflight.ps1` | Report the signed-in account, **delegated vs app-only**, token **scopes**, **directory roles**, and cloud — Step 0. |
| `CPADMDX-Probe-Endpoint.ps1` | Call the target endpoint and **decode** the 401/403/404/429 into the likely branch, printing the real error `code`/`message`/`request-id`. |
| `CPADMDX-Resolve-Scopes.ps1` | Report **have vs need** for scopes and admin role, isolating a scope gap (C/D) from a role gap (E). |
| `CPADMDX-Test-Fallbacks.ps1` | Exercise the **supported alternatives** (GA usage reports, GA package catalog, admin-center/Purview pointers) to prove the exit path. |
| `CPADMDX-Report-Findings.ps1` | Consolidate all outputs into `CPADMDX-Diagnostics\CPADMDX-Findings.json` + `.txt` with the resolved branch and next action. |

## Named artifacts you create

- **`CPADMDX-Diagnostics`** — the working folder for all diagnostic output.
- **`CPADMDX-Findings.json`** / **`CPADMDX-Findings.txt`** — the consolidated evidence file (support-case ready).

## What this solution deliberately does not include

- It does **not** build or configure Copilot agents, and does **not** reproduce the **agent inventory +
  sharing export** deliverable — that is the sibling *Copilot Agent Builder — Inventory, Sharing,
  Governance & Export* product. This runbook unblocks the API and points you there for the export.
- It does **not** invent undocumented endpoints or response shapes; where data is not exposed, it names
  the supported fallback instead.

## How to use it

Start at the **Diagnostic Runbook** Step 0, run `CPADMDX-Preflight.ps1` and
`CPADMDX-Probe-Endpoint.ps1`, follow the branch the probe names, apply the fix, then confirm with the
**Testing** gates. Keep the findings file for your records and for Microsoft support.
