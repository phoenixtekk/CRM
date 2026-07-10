# 7. Best Practices — Azure AI Content Safety & Responsible-AI Guardrails

- **Filter both sides, always.** Moderate the **input** (before the model) *and* the **output** (after
  the model). Clean input can still produce harmful output, and harmful input must never reach the
  model. A one-sided filter is a false sense of safety.
- **Observe before you enforce.** Run the safety filter in `mode=observe` on the pilot first, measure the
  false-positive rate on real benign traffic, then flip to enforce. Blocking users on day one with
  untuned thresholds destroys trust in the guardrail.
- **Thresholds are a policy decision — keep them in config.** The service returns severities; where you
  block is a **trust-and-safety** call, ratified by legal/trust-and-safety and stored as configuration
  the filter reads. Never bury threshold numbers in code where changing policy means shipping code.
- **Stay keyless.** Authenticate the app to Content Safety with a **managed identity** and *Cognitive
  Services User* (`DefaultAzureCredential`). If a key is unavoidable, it lives in **Key Vault**, never in
  source, logs, or config files.
- **Never log the harmful content itself.** Log the **decision** — categories, severities, shield hits,
  groundedness score, and an identifier — not the raw harmful text. Your safety logs must not become a
  new exposure.
- **Red-team continuously, not once.** New jailbreaks and injection patterns appear constantly. Keep
  `Red-Team Prompt Set – App Guardrails – Pilot` alive: add every real-world bypass you find in
  production back into it and re-run `AISAFETY-Report.py`.
- **Shield against indirect injection, not just direct jailbreaks.** The dangerous attacks hide
  instructions inside documents, web pages, and emails your app ingests. Run retrieved content through
  Prompt Shields, not only the user's typed prompt.
- **Ground your answers and check the grounding.** For RAG apps, pass the retrieved sources to the
  groundedness check so confident hallucinations are flagged before a user believes them.
- **Keep a human in the loop for high stakes.** Content Safety is probabilistic. For high-consequence
  uses, route "review" decisions to a person rather than auto-allowing or auto-blocking.
- **Give users an appeal.** Wrongly blocked content erodes trust as much as harmful content does. The
  `RAI Incident & Appeal Process – App Guardrails` must let users report both misses and false blocks,
  routed to a named owner.
- **Budget for the round trips.** Every pre/post call adds latency and cost. Set quotas and budgets
  (global G8), consider co-locating the resource with the app, and batch/short-circuit where a stage's
  verdict already decides the outcome.
- **Treat preview features as preview.** Groundedness and protected-material detection evolve — verify
  current availability and API versions, and design the filter to degrade gracefully (skip-with-log) if a
  preview endpoint is unavailable rather than failing the whole request.

## Where to go next
- **Governing Microsoft 365 Copilot instead of a custom app?** That is a different problem — permissions,
  sensitivity labels, and DLP over tenant data. See **Microsoft 365 Copilot Secure Adoption &
  Governance** and the **Microsoft Purview DLP / Sensitivity Labels / Retention** solution. This
  content-safety solution guardrails *custom* apps; it does not duplicate Copilot/Purview governance.
- **Building the AI app, model deployment, or RAG pipeline** the guardrails wrap — see the AI
  landing-zone and RAG solutions in the AI catalog.
- **Private networking for the AI services** (private endpoints, disabled public access) — see the AI
  landing-zone solution and global requirement G3.
- **Identity, managed identity, and least-privilege RBAC** across your Azure estate — see the Entra ID
  and Azure security-baseline solutions.
