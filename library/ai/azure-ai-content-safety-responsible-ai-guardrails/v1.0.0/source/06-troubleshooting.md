# 6. Troubleshooting Guide — Azure AI Content Safety & Responsible-AI Guardrails

Use `AISAFETY-Validate.py` to confirm the guardrail config is wired, `AISAFETY-Report.py` for the
current moderation posture (red-team + benign), `AISAFETY-Discovery.py` to re-inventory apps, and
`AISAFETY-Blocklist.py` (default preview) for safe blocklist changes.

## A. Authentication and connectivity
| Symptom | Cause | Remediation |
|---|---|---|
| `401`/`403` from Content Safety | Managed identity lacks the data-plane role, or wrong credential | Assign **Cognitive Services User** to the app's managed identity on the resource; confirm `DefaultAzureCredential` picks up that identity; for local testing sign in with `az login` |
| Works locally, fails when deployed | Local dev identity has access, the app's managed identity does not | Enable a managed identity on the app compute and grant it *Cognitive Services User* — don't rely on a key |
| Timeouts / connection refused | Public access disabled and no private endpoint from the app's VNet | Add a private endpoint + private DNS for the resource (global G3), or re-enable public access if that matches your architecture |
| App has an API key hard-coded | Anti-pattern (keys leak) | Move to keyless (managed identity); if a key is unavoidable, store it in Key Vault and reference it — never in source |

## B. Over-blocking (false positives)
| Symptom | Cause | Remediation |
|---|---|---|
| Benign, on-topic inputs are blocked | Severity threshold too low for your use case | Raise the per-category block threshold in `Content Severity Policy – App Guardrails – Pilot` (re-ratified by trust & safety); re-run `AISAFETY-Report.py` on benign controls |
| A normal word keeps getting flagged | It is in the blocklist (or a substring match) | Review `Prohibited Terms – App Guardrails – Pilot` with `AISAFETY-Blocklist.py`; remove/refine the term |
| Users complain right after go-live | You flipped to enforce without observing first | Roll back to `mode=observe`, measure the false-positive rate, tune thresholds, then re-enforce |

## C. Under-blocking (harmful content gets through)
| Symptom | Cause | Remediation |
|---|---|---|
| Harmful **output** slips through though input was filtered | Only the input is being moderated | Confirm the **post-generation** filter runs on the model's answer, not just the input (see Testing Test 6) |
| A jailbreak works | Prompt Shields not called, or the attack is novel | Ensure the pre-filter calls Prompt Shields on the user prompt **and** retrieved content; add the bypass to `Red-Team Prompt Set – App Guardrails – Pilot` and re-test |
| Category severity is high but nothing blocked | The filter isn't reading the severity policy, or is in observe mode | Confirm `mode=enforce` and that the filter compares severities to the loaded policy thresholds |

## D. Prompt Shields / indirect injection
- Confirm the pre-filter runs Prompt Shields over **both** the user prompt and any **documents the app
  retrieved** — indirect injection hides in ingested content. If Prompt Shields is unavailable in your
  region or API version, `AISAFETY-Validate.py` reports it; treat that capability as N/A and compensate
  with stricter input handling until it is available. *Verify current availability.*

## E. Groundedness detection issues
| Symptom | Cause | Remediation |
|---|---|---|
| Groundedness always "grounded" (never flags) | Sources not being passed, or the wrong sources | Pass the exact retrieved passages the answer was generated from to the groundedness call |
| Groundedness endpoint errors / not found | Preview capability not available in-region or API version drift | Confirm current availability and API version; design the filter to skip-with-log rather than fail the request |
| Everything flagged ungrounded | Answer includes reasoning beyond the sources by design | Tune what you route to review vs block; groundedness is a signal, not an absolute — keep a human in the loop |

## F. Protected-material detection
- Preview capability — if it errors or is unavailable, `AISAFETY-Validate.py` reports it; skip-with-log
  and revisit when it is GA in your region. *Verify current availability.* Do not let a preview endpoint
  outage fail the whole request.

## G. Latency and cost
| Symptom | Cause | Remediation |
|---|---|---|
| Noticeable added latency per request | Multiple synchronous safety round trips | Co-locate the resource with the app region; short-circuit later stages once an earlier stage already blocks; parallelize independent checks |
| Unexpected spend / throttling (`429`) | Volume above quota / no budget controls | Set budgets and alerts and request quota appropriate to volume (global G8); back off and retry on `429` |

## H. Diagnostics quick reference
```bash
# Confirm the guardrail config is wired (keyless, blocklist, policy, endpoints)
python AISAFETY-Validate.py

# Read-only moderation posture: red-team + benign controls (verdicts only)
python AISAFETY-Report.py

# Re-inventory apps and current safety layer
python AISAFETY-Discovery.py

# Preview blocklist changes before applying
python AISAFETY-Blocklist.py --list
python AISAFETY-Blocklist.py --name "Prohibited Terms – App Guardrails – Pilot" --terms-file terms.txt   # preview
```
Portal checks: the Content Safety resource → **Access control (IAM)** (role assignments),
**Networking** (private access), and **Monitoring → Diagnostic settings / Logs** (moderation call
history and errors).

## I. When to escalate
If auth is keyless and correct, the filter reads a ratified severity policy, both pre- and
post-generation stages run, Prompt Shields are called on prompt and retrieved content, and harmful
content **still** slips through (or benign content is still over-blocked after tuning) — capture the
exact input, the safety verdict logged, and the API version in use, and open a Microsoft support case.
Volatile Prompt Shields / groundedness / protected-material specifics are deferred to Microsoft's
documentation. **Acceptable-content and responsible-AI policy determinations remain the customer's
legal / trust-and-safety decision — this guide provides the controls, not the policy.**
