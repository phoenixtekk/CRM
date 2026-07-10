# 8. Deliverables Summary — Azure AI Content Safety & Responsible-AI Guardrails

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, what's in the box, and the boundary between technical controls and policy |
| 1. Solution Overview | How Azure AI Content Safety works (categories, severity, Prompt Shields, blocklists, groundedness, protected material) and the pre/post-generation filtering pattern |
| 2. Requirements Guide | Content-safety-specific prerequisites with Verify / Implement-if-missing |
| Global Requirements (AI) | Category-wide AI prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps: provision keyless, severity policy, blocklist, build the safety filter, integrate on a pilot in observe mode, RAI review, incident/appeal, validate + enforce, expand |
| 5. Testing Guide | Validation procedures with red-team probes, false-positive checks, and pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations + where to go next |

## Python scripts
| Script | What it does |
|---|---|
| `AISAFETY-Discovery.py` | Read-only: inventories in-scope AI apps/endpoints, whether a Content Safety resource exists, and whether each app calls any safety layer today |
| `AISAFETY-Validate.py` | Read-only: confirms the guardrail config is wired — resource reachable keyless, `Prohibited Terms – App Guardrails – Pilot` blocklist present, severity policy loaded, Prompt Shields / groundedness endpoints reachable |
| `AISAFETY-Report.py` | Read-only: runs the `Red-Team Prompt Set – App Guardrails – Pilot` plus benign controls through the safety endpoints and reports categories/severities/shield hits and the false-positive rate (verdicts only — never emits harmful content) |
| `AISAFETY-SafetyFilter.py` | Integration sample: the reusable pre/post-generation `Safety Filter – Pre-Post Generation – Pilot` — moderation + blocklist + Prompt Shields pre-generation, moderation + groundedness + protected-material post-generation, decisions driven by the severity policy config; defaults to `mode=observe` (log, don't block) |
| `AISAFETY-Blocklist.py` | Safe blocklist manager (default preview): creates/updates `Prohibited Terms – App Guardrails – Pilot` and adds terms only with `--apply`; idempotent |

> The five scripts are **Python** using the `azure-ai-contentsafety` SDK and `azure-identity` (keyless).
> Preview capabilities (Prompt Shields specifics, groundedness, protected-material) are called via the
> current API and degrade gracefully with a logged note where a capability is unavailable in-region —
> *verify current availability in your tenant*.

## What the buyer receives
- This implementation guide as a **Word** document and **PDF**.
- All five **Python scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**
- Delivered as a **Complete Solution Package (PDF + Word + scripts)**.

## Outcome
Custom AI apps with real guardrails — harmful text/image content moderated to a ratified severity
policy, jailbreak and indirect-injection attacks shielded, answers checked for groundedness and
protected material, and a responsible-AI review, red-team, and incident/appeal process behind it —
proven on a pilot app in observe mode before any app enforces or ships.
