# 3. Implementation — AI Workload Security Assessment

This is the exact, ordered procedure. It is **read-only** end to end — you enumerate and score, you never
change a resource. Follow the standard model: **Assess → Configure → Pilot → Validate → Expand**. Run the
**pilot** on one AI workload first, confirm the findings are real, then expand to every AI workload.

**Naming convention.** Every artifact you create uses `<Purpose> – <Scope> – <Stage>`. Reuse the exact
names in later steps, testing, and the report:
- Scope document: **`AIWorkloadSec – Estate – Scope`**
- Output folder: **`AIWorkloadSec – Estate – Findings`**
- Pilot run label: **`AIWorkloadSec – ChatbotPilot – Pilot`**
- Full run label: **`AIWorkloadSec – Estate – Full`**
- Roadmap deliverable: **`AIWorkloadSec – Estate – Roadmap`**
- Saved KQL query: **`AIWorkloadSec – KeyAuth – Signal`**

---

## Stage 0 — Assess: prepare and validate access (read-only)

### Step 0.1 — Write the scope document
1. Create **`AIWorkloadSec – Estate – Scope`**. Record: the subscriptions/resource groups in scope, the AI
   workloads in scope (name each Azure OpenAI / AI Foundry / AI Search / Azure ML resource you know of), the
   **AI security baseline** you score against (Microsoft AI security guidance + the paired build solutions'
   target state — *verify the current baseline*), and the run date (the score is point-in-time, G5).

### Step 0.2 — Create the output folder
1. Create a restricted folder **`AIWorkloadSec – Estate – Findings`** in your secure destination (R7). All
   exports land here.

### Step 0.3 — Install modules and validate read-only access
1. In **PowerShell 7+**: `Install-Module Az -Scope CurrentUser` and
   `Install-Module Microsoft.Graph -Scope CurrentUser` if not present (R4).
2. Connect read-only:
   - `Connect-AzAccount` (then `Set-AzContext -SubscriptionId <sub>` per in-scope subscription).
   - `Connect-MgGraph -Scopes "Directory.Read.All","Policy.Read.All"` *(verify the current least-privilege scope set)*.
3. Run **`AIWLSEC-Validate.ps1`**. It confirms PowerShell/module versions, that Azure and Graph are
   connected, that your identity is **read-only** (Azure Reader + Security Reader, no Contributor/write), that
   the AI resource providers are registered, and lists the **AI resources it can see** in scope. **Do not
   proceed until Validate passes** — a missing role makes a whole review area silently empty.

---

## Stage 1 — Configure: choose the baseline and pilot workload

1. In **`AIWorkloadSec – Estate – Scope`**, confirm and record the **AI security baseline** — the report must
   name what it scored against (G6).
2. Pick one **representative AI workload** for the pilot (e.g. a customer-facing chatbot with a RAG index) and
   label it **`AIWorkloadSec – ChatbotPilot – Pilot`**. The pilot proves the method and surfaces false
   positives before the full run.

---

## Stage 2 — Pilot: discover and review the pilot workload (read-only)

### Step 2.1 — AI estate discovery
1. Run **`AIWLSEC-Discovery.ps1 -SubscriptionIds <pilot sub> -OutputFolder "<...>\AIWorkloadSec – Estate – Findings"`**.
   It enumerates, read-only, every:
   - **Azure OpenAI / Cognitive Services** account (kind `OpenAI` / `AIServices`) — public access, local-auth
     (keys) state, custom subdomain, model deployments and content-filter policies, private endpoints, diagnostics.
   - **Azure AI Foundry** hub/project (*verify current resource types*).
   - **Azure AI Search** service — public access, API-key vs RBAC (`disableLocalAuth`/`authOptions`), indexes,
     and whether data sources indicate a RAG pattern.
   - **Azure ML** workspace — public access, managed VNet, associated storage/Key Vault posture.
2. It writes a per-resource posture CSV/JSON to the output folder.

### Step 2.2 — Network isolation review
1. Run **`AIWLSEC-NetworkIsolation.ps1 -SubscriptionIds <pilot sub> -OutputFolder "<...>\AIWorkloadSec – Estate – Findings"`**.
   For every AI resource it reports: **public network access** (Enabled = finding), **private endpoint**
   present/absent, and whether a private DNS path exists — the highest-frequency AI findings live here.

### Step 2.3 — Content-safety / responsible-AI posture review
1. Run **`AIWLSEC-ContentSafety.ps1 -SubscriptionIds <pilot sub> -OutputFolder "<...>\AIWorkloadSec – Estate – Findings"`**.
   For each Azure OpenAI model deployment it reports whether a **content-filter (RAI) policy** is attached and
   the default filter state, and flags **prompt-shield / jailbreak / groundedness** protections to verify.
   *Several of these are preview — the script marks them "verify availability", it does not assert a gap where
   the feature is simply unavailable in your region.*

### Step 2.4 — RAG data-exposure and secrets review (manual + scripted)
1. From the discovery output, for each **AI Search** index that backs a RAG app, confirm in the portal
   (`portal.azure.com` → the Search service → **Indexes** / **Search explorer**, and the app's data-access
   design) whether the index is **permission-trimmed** (security filters / document-level access) or exposes
   the whole corpus to every caller. Record the answer as a finding — a non-trimmed index over sensitive data
   is Critical.
2. Check the app's configuration and any Foundry/Search **connections** for **hard-coded keys / secrets** in
   connection strings or app settings (they belong in Key Vault). Record any found.
   *Data-classification of what the index contains is the customer's decision; the assessment scores whether
   the access control exists.*

### Step 2.5 — (Optional) corroborate with KQL
1. If diagnostics flow to Log Analytics/Sentinel (R6), run the read-only query saved as
   **`AIWorkloadSec – KeyAuth – Signal`** (in Testing) to see whether Azure OpenAI calls are still
   authenticating with a **key** rather than a token — live evidence behind the keyless finding.

### Step 2.6 — Score and rank the pilot
1. Run **`AIWLSEC-Report.ps1 -InputFolder "<...>\AIWorkloadSec – Estate – Findings" -Label "AIWorkloadSec – ChatbotPilot – Pilot"`**.
   It rolls the discovery + network + content-safety outputs (and any RAG/secrets findings you recorded) into
   a per-resource posture, tags each finding with a **risk rating**, and emits a draft risk-ranked report.

---

## Stage 3 — Validate: confirm the pilot findings are real

1. For each **High/Critical** finding, open the live Azure portal blade and confirm:
   - Network → the AI resource → **Networking** (public access + private endpoints).
   - Keyless → the resource → **Keys and Endpoint** / **Identity**, and **Access control (IAM)** for the
     managed-identity role.
   - Content safety → Azure AI Foundry / Azure OpenAI → the deployment's **content filter**.
   - RAG → the AI Search service → **Indexes** and the app's access design.
2. Mark any confirmed false positive with the reason (e.g. a preview feature not yet GA in the region, or a
   compensating control the script can't see) — **do not silently delete findings**.
3. If a review area returned empty, re-check the matching role/scope (R1–R3) — a common cause.

---

## Stage 4 — Expand: review every AI workload and produce the roadmap

1. Re-run **Steps 2.1–2.6** with the full scope, labelled **`AIWorkloadSec – Estate – Full`** — point the
   scripts at all in-scope subscriptions/RGs and review every AI resource.
2. Run **`AIWLSEC-Report.ps1 ... -Label "AIWorkloadSec – Estate – Full"`** to produce the final
   **risk-ranked findings report**.
3. Build the roadmap **`AIWorkloadSec – Estate – Roadmap`** in three phases, mapping each item to the paired
   AI build solution that fixes it:
   - **Phase 1 — Quick wins:** disable public network access, attach a content-filter policy, disable local
     auth on resources already keyless-capable → **AIFOUNDRY** / **AISAFETY**.
   - **Phase 2 — Foundational:** private endpoints + DNS, managed-identity + least-privilege RBAC, move
     secrets to Key Vault → **AIFOUNDRY**; permission-trim RAG indexes → **AIRAG**.
   - **Phase 3 — Strategic:** responsible-AI governance program, prompt-shield/groundedness rollout,
     AI landing-zone guardrails → **AISAFETY** / **AILZ**.
4. Store the report and roadmap in **`AIWorkloadSec – Estate – Findings`** (restricted). Present the executive
   summary (top AI risks) to leadership and the technical findings to the AI/workload owners.

> **Determinations that are NOT yours to make in this guide:** what content is *acceptable*, what data is
> *sensitive*, whether to *accept* a given risk, and any **regulatory / legal** mapping of a finding belong to
> your trust-and-safety, legal, and security functions. The assessment supplies the evidence and a
> recommended sequence; the decisions are the customer's.

## Re-run to trend
Re-run the whole assessment after each remediation wave with the same scope and baseline to **trend** the AI
security posture and prove the gaps are closing.
