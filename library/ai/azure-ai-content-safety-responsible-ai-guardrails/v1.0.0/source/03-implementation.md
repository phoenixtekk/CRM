# 3. Implementation Guide — Azure AI Content Safety & Responsible-AI Guardrails

Follow these steps **in order**, across the **Azure portal** (`https://portal.azure.com`), your **AI
app's code**, and the supplied Python scripts. Where a portal action has a CLI equivalent it is shown
so the work is reproducible.

> **Model:** Provision the guardrail resource keyless, define the severity policy and blocklist, build
> the safety filter, then integrate it into **one** pilot app in **observe mode** (log, don't block),
> validate with red-team prompts, and only then flip to enforce and expand to more apps. Observe before
> enforce; roll back to observe at any sign of over-blocking.

Name every object exactly as shown, in the form `<Purpose> – <Scope> – <Stage>`, and reuse the names
verbatim across scripts, config, and reports:

| Object | Name |
|---|---|
| Resource group | `rg-ai-guardrails-pilot` |
| Content Safety resource | `AI Content Safety – App Guardrails – Pilot` |
| Severity policy (config doc) | `Content Severity Policy – App Guardrails – Pilot` |
| Custom blocklist | `Prohibited Terms – App Guardrails – Pilot` |
| Safety filter component | `Safety Filter – Pre-Post Generation – Pilot` |
| Red-team prompt set | `Red-Team Prompt Set – App Guardrails – Pilot` |
| Incident & appeal process | `RAI Incident & Appeal Process – App Guardrails` |

## Step 1 — Assess the AI apps and current guardrails (read-only)
1. Run `AISAFETY-Discovery.py` to inventory the in-scope AI apps/endpoints, whether an Azure AI Content
   Safety resource already exists in the subscription, and whether each app calls any safety layer
   today (pre/post-generation).
2. Record, per app: does it accept user text/images? does it generate content? does it ground answers on
   your data (RAG)? is there any moderation today? Pick **one** representative app as the pilot and
   confirm its owner.
3. Do **not** change any app yet. The output of this step is the worklist and the chosen pilot app.

## Step 2 — Provision the Content Safety resource (keyless)
1. In the Azure portal, **Create a resource → "Content Safety" → Create**. Set:
   - **Resource group:** `rg-ai-guardrails-pilot`
   - **Name:** `AI Content Safety – App Guardrails – Pilot` (Azure resource names have character
     limits — if the display name is rejected, use `ai-contentsafety-guardrails-pilot` as the resource
     name and keep the friendly name in your config/docs).
   - **Region:** co-located with the pilot app; **Pricing tier:** per your expected volume.
   CLI equivalent:
   ```bash
   az group create -n rg-ai-guardrails-pilot -l <region>
   az cognitiveservices account create \
     -n ai-contentsafety-guardrails-pilot -g rg-ai-guardrails-pilot \
     --kind ContentSafety --sku S0 -l <region> --custom-domain ai-contentsafety-guardrails-pilot
   ```
2. **Disable public network access** where your architecture requires it and add a **private endpoint**
   (global requirement G3): resource → **Networking → Private access**. Reach it from the app's VNet.
3. Turn on **diagnostic settings** → send logs to your Log Analytics workspace so every moderation call
   is auditable (resource → **Monitoring → Diagnostic settings → Add**).

## Step 3 — Grant the app keyless access (managed identity + RBAC)
1. Enable a **system-assigned managed identity** on the pilot app's compute (App Service / Container
   App / VM / AKS workload identity): app → **Identity → System assigned → On**.
2. On the Content Safety resource → **Access control (IAM) → Add role assignment**, assign **Cognitive
   Services User** to the app's managed identity (and to your own dev identity for local testing).
   ```bash
   az role assignment create --assignee <app-managed-identity-object-id> \
     --role "Cognitive Services User" \
     --scope /subscriptions/<sub>/resourceGroups/rg-ai-guardrails-pilot/providers/Microsoft.CognitiveServices/accounts/ai-contentsafety-guardrails-pilot
   ```
3. Confirm the app can authenticate with `DefaultAzureCredential` — **no key in code**. If a key is
   genuinely unavoidable, store it in **Key Vault** and reference it; never hard-code it.
4. Set the endpoint as app configuration, e.g. `CONTENT_SAFETY_ENDPOINT=https://<resource>.cognitiveservices.azure.com/`.

## Step 4 — Define the severity policy (trust & safety ratifies)
1. Create the config document `Content Severity Policy – App Guardrails – Pilot` recording, per category
   (**Hate / Sexual / Violence / Self-Harm**), the **block** and **review** thresholds on the 0–7 scale.
   A safe starting point: **block ≥ 4**, **review = 2**, **allow 0** for all four categories.
2. Have the customer's **legal / trust-and-safety** function **ratify** the thresholds — this is a
   policy decision, not a technical default. Record the owner and sign-off date.
3. Store the thresholds as **configuration** the safety filter reads (e.g. `severity_policy.json`), so
   changing policy never means changing code. The supplied scripts read this config.

## Step 5 — Create the custom blocklist (safe preview first)
1. Assemble the reviewed term list (owned by trust & safety / legal). Run
   `AISAFETY-Blocklist.py --create --name "Prohibited Terms – App Guardrails – Pilot" --terms-file terms.txt`
   in its **default preview mode** to see exactly what it would create/add.
2. Re-run with `--apply` to create the blocklist `Prohibited Terms – App Guardrails – Pilot` and add the
   terms. The script is idempotent — re-running updates the list without duplicating it.
3. Note the blocklist name; the safety filter references it in every `analyze_text` call via
   `blocklist_names`.

## Step 6 — Build the safety filter (pre/post-generation), observe mode
1. Take `AISAFETY-SafetyFilter.py` as the starting point for the `Safety Filter – Pre-Post Generation –
   Pilot` component. It implements:
   - **Pre-generation:** `analyze_text` (four categories + severity) on user input **and** any retrieved
     documents, the blocklist, and **Prompt Shields** (jailbreak + indirect injection). *Prompt Shields
     API shape evolves — verify the current API version for your region.*
   - **Post-generation:** `analyze_text` on the model's answer, a **groundedness** check against the RAG
     sources, and a **protected-material** check. *Groundedness and protected-material are
     preview/evolving — verify current availability.*
   - A decision per stage: **allow / block / review**, driven by the `Content Severity Policy` config.
   - Structured **logging** of every decision (categories, severities, shield hits, groundedness score)
     for the RAI review and incident process.
2. Set the filter to **`mode=observe`** (default): it computes and logs a decision but does **not**
   block — the app still returns its normal answer. This measures false positives without disrupting
   users.
3. Wire the filter into the pilot app: call the pre-filter before the model call, the post-filter after,
   passing retrieved sources for groundedness.

## Step 7 — Integrate on the pilot app and run in observe mode
1. Deploy the pilot app with the safety filter in observe mode. Confirm the app still works normally.
2. Let real (or scripted) traffic flow. Run `AISAFETY-Validate.py` to confirm the guardrail
   configuration is correctly wired (resource reachable keyless, blocklist present, severity config
   loaded, Prompt Shields / groundedness endpoints reachable).
3. Run `AISAFETY-Report.py` to send the **`Red-Team Prompt Set – App Guardrails – Pilot`** and a set of
   benign control prompts through the safety endpoints and produce a **moderation-posture report** —
   which prompts trip which categories/severities/shields, and the false-positive rate on benign inputs.
   (The red-team set contains *adversarial prompts to test the guardrails*; the report never emits
   harmful content, only the safety verdicts.)

## Step 8 — Stand up the responsible-AI review
1. Establish a recurring **RAI review** of the logged decisions: sample blocked/flagged items, confirm
   the thresholds are catching real harm and not over-blocking, and adjust the `Content Severity Policy`
   config (re-ratified by trust & safety) as needed.
2. Record the review cadence, participants, and where the logs live. This is the loop that keeps the
   thresholds honest.

## Step 9 — Stand up the incident and appeal process
1. Adopt the `RAI Incident & Appeal Process – App Guardrails`: how a user reports harmful output that
   slipped through, how a user **appeals** content wrongly blocked, who triages, and the SLA.
2. Wire the appeal path into the app's UX (e.g. a "report / this was wrongly blocked" affordance) and
   route it to the named owner from requirement 2.9.

## Step 10 — Validate against the gate, then flip to enforce (pilot pass)
1. Work through the **Testing Guide**. The pilot gate is met when: harmful/adversarial prompts are
   caught to policy, benign prompts are **not** over-blocked (false-positive rate within your agreed
   bound), groundedness flags hallucinations on the RAG app, and the incident/appeal path works.
2. Once the gate passes and trust & safety signs off, change the filter to **`mode=enforce`** on the
   pilot app so it actually blocks/redacts per policy. Keep the observe-mode logs for comparison.
3. Confirm the rollback: setting `mode=observe` (or bypassing the filter) instantly reverts to
   non-blocking. Record it in the change ticket.

## Step 11 — Expand to more apps
1. Only after the pilot enforces cleanly: integrate `Safety Filter – Pre-Post Generation – Pilot` into
   the next app(s) from the Step 1 worklist, each in **observe mode first**, then enforce after its own
   validation.
2. Reuse the same Content Safety resource (or add regional resources for latency), the same severity
   policy and blocklist, and the same RAI review/red-team/incident process. Re-run `AISAFETY-Report.py`
   per app and on a schedule so posture does not drift.
3. Feed new jailbreaks discovered in production back into the `Red-Team Prompt Set` — red-teaming is
   continuous.

---
### Order of operations
`Assess apps → Provision resource (keyless) → Grant RBAC → Severity policy → Blocklist → Build safety
filter (observe) → Integrate on pilot → RAI review → Incident/appeal process → Validate + enforce →
Expand`
