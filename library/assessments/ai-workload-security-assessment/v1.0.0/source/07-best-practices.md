# 7. Best Practices — AI Workload Security Assessment

Field-proven guidance for running an AI workload security assessment that people trust and act on — plus
where to go next to close the gaps.

## Keep it read-only, keep it least-privilege
- Run the assessment as **Azure Reader + Security Reader** and let `AIWLSEC-Validate.ps1` prove it. An AI
  security review that could change a resource is no longer an assessment.
- Consent only **read** Graph scopes. If a script seems to need write access, treat it as a bug.

## Don't cry wolf on preview features
- Several AI safety controls (prompt shields, groundedness detection, protected-material detection,
  asynchronous filtering) may be **preview** or **region-limited**. *Verify current availability before
  treating absence as a hard finding.* Report an unavailable feature as "verify availability", not as a
  missing control — false alarms erode trust in the whole report.

## Rank RAG data-exposure highest
- A RAG index that **isn't permission-trimmed** over sensitive data is the most damaging common AI finding:
  it silently hands users answers from documents they can't open. Confirm permission-trimming by inspection
  (the script points you at it) and rank it Critical when the corpus is sensitive.
- *What data is sensitive is the customer's classification decision* — the assessment scores whether the
  access control exists, not what should be protected.

## Keyless and private are the target state
- Flag every AI resource with **public network access enabled** and every one with **local auth (keys)
  enabled**. The secure target — **private endpoints + disabled public access + managed identity +
  least-privilege RBAC** — is exactly what the paired build solutions deploy. Point findings at them.
- Flag any **secret/key hard-coded** in a connection string or app setting; it belongs in Key Vault.

## Score against a named baseline and record it
- Name the **AI security baseline** and the **run date** in the report header so the findings are comparable
  and defensible. *Baselines and Azure AI resource models evolve — verify each run.*

## Pilot before you present
- Run **one AI workload** first and **validate High/Critical findings against the live portal** before the
  full run. Record any confirmed false positive with the reason rather than deleting it.

## Treat the report as sensitive
- The findings map your AI attack surface. Store it in the restricted **`AIWorkloadSec – Estate – Findings`**
  location and share on a need-to-know basis.

## Leave the decisions with the owners
- The assessment states each gap and its risk and recommends a sequence. **Acceptable-AI-use policy,
  data-classification, risk-acceptance, and any regulatory / legal mapping are the customer's decisions** —
  trust-and-safety, legal, and security own them, not this guide or its scripts.

## Where to go next (paired AI catalog solutions)
This assessment is the **map**; these solutions do the **build/fix** (each pilot-first, `what-if`/approval-gated):
- **Azure AI Foundry & OpenAI secure enterprise deployment (AIFOUNDRY)** — deploys the private, keyless,
  quota-bounded, content-filtered Azure OpenAI + Foundry platform the network/identity/content-safety findings
  call for.
- **Enterprise RAG platform on Azure AI Search (AIRAG)** — builds the **permission-trimmed** RAG index that
  closes the data-exposure findings.
- **AI Content Safety & Responsible-AI guardrails (AISAFETY)** — implements the content filters, prompt
  shields, and responsible-AI governance the safety/governance findings call for.
- **AI Landing Zone governance & private networking (AILZ)** — the org-wide guardrails, policy, and networking
  that keep new AI workloads secure by default.
- **Cloud Adoption Security Assessment (CLDSEC)** — the sibling whole-estate assessment, if you also need the
  broader identity/endpoint/data/infra/network picture around these AI workloads.

Close the top-ranked findings with the paired solutions, then **re-run this assessment** to prove the posture
moved.
