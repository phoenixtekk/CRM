# 2. Requirements Guide — Azure AI Content Safety & Responsible-AI Guardrails

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (Azure subscription and rights, Entra + managed
identity, private networking, Python/IaC tooling, CI/CD, data source, responsible-AI posture, cost
controls) are published once in `global-requirements-ai.md` — they are **referenced, not repeated**
here. The items below are specific to Azure AI Content Safety.

## 2.1 Azure AI Content Safety resource availability
**Description:** Azure AI Content Safety available in a region you can deploy to (a standalone Content
Safety resource, or the equivalent capability on an Azure AI Services multi-service resource).
**Why:** The resource is the endpoint your app's safety filter calls; region and capability
availability vary.
**Verify:** In the Azure portal, **Create a resource → search "Content Safety"** resolves and offers a
region near your app. Or `az cognitiveservices account list-kinds` shows the Content Safety kind.
**Implement:** Choose a supported region (co-locate with your AI app to minimize latency); confirm your
subscription can create the resource. *AI service regions/features move — verify current availability.*

## 2.2 A custom AI app in scope (with an owner)
**Description:** At least one AI app you own — chatbot, copilot, document assistant — that generates or
accepts text/images, identified as the pilot, with a named app owner.
**Why:** This solution guardrails an app you already run; the pilot app is where the safety filter is
first integrated and validated.
**Verify:** Run `AISAFETY-Discovery.py` to inventory in-scope AI endpoints and whether any safety layer
exists today; confirm the app owner.
**Implement:** Pick one representative app as the pilot; if you have no app yet, build it first (see the
AI landing-zone / RAG solutions) — guardrails wrap an existing app.

## 2.3 Keyless authentication (managed identity + RBAC)
**Description:** A managed identity for the app (or the developer's Azure identity for local testing)
holding the **Cognitive Services User** role on the Content Safety resource.
**Why:** Keys leak; the app should authenticate to Content Safety via managed identity + RBAC with no
key in code (global requirement G2).
**Verify:** In the resource → **Access control (IAM)**, the app's managed identity has *Cognitive
Services User*. `DefaultAzureCredential` succeeds from the app context.
**Implement:** Enable a managed identity on the app compute; assign **Cognitive Services User** at the
resource scope; use `DefaultAzureCredential`. If a key is genuinely unavoidable, store it in **Key
Vault**, never in source.

## 2.4 Python toolchain and the Content Safety SDK
**Description:** Python 3.8+ with `azure-ai-contentsafety` and `azure-identity` installed (plus
`requests` for preview REST endpoints), pinned in the project.
**Why:** The scripts and the safety-filter integration are Python using the Content Safety SDK.
**Verify:** `python --version` ≥ 3.8; `pip show azure-ai-contentsafety azure-identity` returns
versions. *The AI SDKs move fast — verify current package versions and pin them (global G4).*
**Implement:** `pip install azure-ai-contentsafety azure-identity requests`; pin versions in
`requirements.txt`; store in Git.

## 2.5 Severity policy (thresholds ratified by trust & safety)
**Description:** A documented content-severity policy: per-category (Hate / Sexual / Violence /
Self-Harm) block and review thresholds on the 0–7 scale, named `Content Severity Policy – App
Guardrails – Pilot`.
**Why:** The service returns severities; **where to draw the block line is a trust-and-safety policy
decision**, not a technical default — it must be owned and signed off.
**Verify:** A written policy exists with per-category thresholds and an owner. The safety filter reads
these thresholds from config, not hard-coded values.
**Implement:** Draft a starting policy (e.g. block ≥ 4, review = 2, allow 0) and have the customer's
**legal / trust-and-safety** function ratify it before enforcing. *Acceptable-content determinations
are the customer's decision (global G7).*

## 2.6 Custom blocklist source (if used)
**Description:** A list of terms/phrases to always flag — brand names, banned terms, competitor or PII
patterns — for the blocklist `Prohibited Terms – App Guardrails – Pilot`.
**Why:** The category model catches general harm; a blocklist enforces organization-specific terms the
model would not know about.
**Verify:** A reviewed term list exists (owned by trust & safety / legal, not invented by the
implementer).
**Implement:** Collect and review the term list; load it with `AISAFETY-Blocklist.py` (which defaults to
a safe preview). Keep the list in source control (excluding anything sensitive).

## 2.7 Grounding sources for groundedness detection (RAG apps)
**Description:** For apps that ground answers on your data (RAG), the **source passages** the app
retrieved for a given answer, available to pass to the groundedness check.
**Why:** Groundedness detection compares the answer to its sources; it needs the sources as input.
**Verify:** The app can surface the retrieved context for each answer (it usually already has it).
**Implement:** Wire the retrieved passages through to the post-generation filter. *Groundedness
detection is a preview capability — verify current availability and API version in your region.*

## 2.8 Observe-before-enforce and rollback (change control)
**Description:** A documented plan to run the safety filter in **audit/observe mode** (log decisions,
do not block) on the pilot first, with a defined rollback.
**Why:** Blocking user content is disruptive; false positives must be measured before enforcement, and
a rollback is mandatory (global G8, and the pilot-before-enforce house rule).
**Verify:** The filter has an `observe` mode flag; a change ticket names the pilot app, an approver, and
the rollback (revert to observe / bypass the filter).
**Implement:** Default the filter to observe mode; measure false-positive rate on the pilot; only flip
to enforce after the trust-and-safety gate passes.

## 2.9 Responsible-AI review, red-team, and incident/appeal process owners
**Description:** Named owners for the responsible-AI review, the red-team prompt set (`Red-Team Prompt
Set – App Guardrails – Pilot`), and the incident/appeal process (`RAI Incident & Appeal Process – App
Guardrails`).
**Why:** Guardrails are a process, not a one-time config — someone must review flagged content, run
red-team cycles, and handle user appeals of blocked content.
**Verify:** Owners are named and the process documents exist (this package supplies the templates).
**Implement:** Assign owners; adopt the review/red-team/incident templates in Implementation Steps 7–9.
*Responsible-AI policy determinations are the customer's legal / trust-and-safety decision (global G7).*

---
## Checklist
- [ ] Azure AI Content Safety resource available in a supported region
- [ ] Pilot AI app identified with a named owner (`AISAFETY-Discovery.py`)
- [ ] Keyless auth: app managed identity has *Cognitive Services User* on the resource
- [ ] Python 3.8+ with `azure-ai-contentsafety` / `azure-identity` pinned
- [ ] `Content Severity Policy – App Guardrails – Pilot` drafted and ratified by trust & safety
- [ ] Blocklist term source reviewed (if using `Prohibited Terms – App Guardrails – Pilot`)
- [ ] Grounding sources available to the post-generation filter (RAG apps)
- [ ] Safety filter defaults to observe mode; rollback documented
- [ ] RAI review / red-team / incident-and-appeal owners named
