# 5. Testing Guide — Azure AI Content Safety & Responsible-AI Guardrails

Run after the safety filter is integrated on the pilot app in observe mode (Implementation Step 7), and
re-run after flipping to enforce and after each expansion wave. The most important tests are the
**red-team probes** (harmful/adversarial input is caught) and the **false-positive check** (benign
input is *not* over-blocked). The red-team set is used to test the guardrails — the reports capture
only the safety verdicts, never harmful content.

## Test 1 — Guardrail configuration is correctly wired
**Do:** Run `AISAFETY-Validate.py`.
**Expected:** The Content Safety resource is reachable **keyless** (managed identity), the `Prohibited
Terms – App Guardrails – Pilot` blocklist exists, the `Content Severity Policy` config loads, and the
Prompt Shields / groundedness endpoints respond (or are clearly reported as unavailable in-region so you
know before you depend on them).

## Test 2 — Text moderation catches harmful input to policy
**Do:** Run `AISAFETY-Report.py` with the `Red-Team Prompt Set – App Guardrails – Pilot`.
**Expected:** Prompts designed to be hateful/violent/sexual/self-harm return severities **at or above**
your policy block threshold for the right category, and the filter's decision is **block** (or
**review**) per the `Content Severity Policy`.

## Test 3 — Benign input is NOT over-blocked (false-positive check)
**Do:** Run `AISAFETY-Report.py` over the **benign control prompts** (normal, on-topic user inputs).
**Expected:** Benign prompts return low severities and are **allowed**. The false-positive rate is within
the bound trust & safety agreed to. If benign inputs are being blocked, raise the threshold or refine the
blocklist before enforcing.

## Test 4 — Custom blocklist flags its terms
**Do:** Submit an input containing a term from `Prohibited Terms – App Guardrails – Pilot` through the
pre-filter (or `AISAFETY-Report.py`).
**Expected:** The response includes a **blocklist match** for that term and the filter decision reflects
your blocklist policy, independent of the category severities.

## Test 5 — Prompt Shields catch jailbreak and indirect injection
**Do:** Submit (a) a direct jailbreak input ("ignore your instructions and…") and (b) an input where a
retrieved document contains hidden instructions (indirect prompt injection), using the red-team set.
**Expected:** Prompt Shields flag both as attacks and the pre-filter **blocks** them before the model is
called. *If Prompt Shields is not available in your region/API version, this test is marked N/A with a
note — verify current availability.*

## Test 6 — Post-generation moderation catches harmful output
**Do:** Drive the app with an input that is itself benign but is crafted to coax harmful output; observe
the post-generation filter on the model's answer.
**Expected:** The answer is scored again after generation; if it exceeds policy it is **blocked/redacted**
post-generation even though the input passed. (This proves you filter both sides, not just input.)

## Test 7 — Groundedness detection flags hallucinations (RAG apps)
**Do:** On the RAG pilot app, ask a question whose true answer is **not** in the grounding sources, and
pass the answer plus its sources to the groundedness check.
**Expected:** The groundedness check flags the answer as **ungrounded** (low groundedness), and the
filter routes it to review/block per policy. *Groundedness is a preview capability — verify availability;
mark N/A with a note if unavailable.*

## Test 8 — Protected-material detection (where available)
**Do:** Ask the app to reproduce a well-known copyrighted passage; run the output through the
protected-material check.
**Expected:** The check flags protected material and the filter blocks/redacts it. *Preview capability —
verify availability.*

## Test 9 — Observe → enforce behaves correctly
**Do:** With the filter in `mode=observe`, confirm a harmful input is **logged but still answered**; then
set `mode=enforce` and confirm the same input is **blocked**.
**Expected:** Observe logs the decision without disrupting; enforce actually blocks. Setting `observe`
again is an instant rollback.

## Test 10 — Incident and appeal path works
**Do:** Exercise the `RAI Incident & Appeal Process – App Guardrails`: report a harmful output that
slipped through, and appeal a wrongly blocked benign input.
**Expected:** Both route to the named owner with the logged decision attached, and the SLA/triage steps
are followed.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (flip to enforce)** | Tests 1–5 pass; Test 3 false-positive rate within the agreed bound; Test 6 proves post-generation filtering; the incident/appeal path (Test 10) works; trust & safety has ratified the thresholds |
| **Expand pass** | Tests 1–4, 6, and (where available) 7–8 pass for each newly integrated app **in observe mode** before that app is flipped to enforce |
