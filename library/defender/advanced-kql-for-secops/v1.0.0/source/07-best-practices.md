# Best Practices — Guide: Advanced KQL for SecOps

Keep-it-clean guidance for turning a KQL guide into a durable hunting-and-detection skill that
stays sharp over time.

## Write KQL that a teammate can read

- **Filter early, filter cheaply.** Put the most selective `where` first, and prefer `has` over
  `contains` (token vs substring) — it is faster and clearer. A hunt that returns fast gets re-run.
- **`project` down to what you need.** Trim columns early so results are readable and joins are cheap;
  the reader should see the story, not every field.
- **Name your intent with `let` and comments.** Use `let` for reusable time windows and indicator
  lists, and a one-line comment per query stating the question it answers. Queries you save should be
  self-explanatory a month later.

## Hunt on a question, not a hunch

- **Start every hunt from an answerable question** — "who else ran this binary?", "what did this
  identity do before the alert?" — then pivot with joins. Save the good hunts to `Hunt-KQLLab-Pilot`
  so the team reuses them.
- **Aim for a small, explainable result.** A hunt that returns thousands of rows is not tuned. Push
  filters and aggregation until every row is one you can justify.
- **Re-hunt after every incident.** A new indicator (hash, IP, account) is a new query — run it across
  the whole tenant, not just the one reported entity.

## Know your two surfaces

- **Same language, different tables.** Reach for **Defender advanced hunting** for endpoint /
  identity / email XDR tables; reach for **Sentinel** for connected logs and long-retention
  correlation. Teach learners to choose the right surface, not memorize one.
- **Verify the schema — it drifts.** Microsoft renames and reshapes hunting tables periodically. Treat
  every delivered query as a **starting point**, and confirm table/column names against your tenant.
  *Verify current schema.*

## Turn hunts into durable coverage — carefully

- **Alert-only first.** Promote a hunt to a custom detection (`Detect-KQLLab-Pilot`) only once it is
  quiet and accurate, and keep it **alert-only** until proven. A noisy detection trains the team to
  ignore alerts.
- **Promote deliberately.** Moving a lab detection to production, tightening its schedule, or wiring
  any response is a **documented operations decision** — the SOC’s call, made with rollback in mind,
  not a default this guide flips.
- **Version your queries.** Keep the KQL library in source control so hunts are reviewable and
  portable — the same discipline the Sentinel detection-as-code solution applies.

## Run it as a program, not a one-off class

- **Practice keeps the skill.** KQL fades without use. Schedule recurring hunt sessions and rotate who
  writes the query of the week.
- **Feed the hunt library.** Hand tuned queries to the **Threat Hunting hunt-library** solution so
  they join the maintained, operated program — the guide builds the skill; that product runs the
  library.
- **Re-run for new hires.** The take-home runbook and knowledge-check make onboarding a new analyst
  repeatable.

## Where to go next

With the team able to hunt and author detections, the natural next steps in this catalog are:

- **Threat Hunting hunt-library** — adopt and operate a curated, maintained hunt program built on the
  skill this guide gives you (adjacent, not duplicate).
- **Microsoft Sentinel analytics rules & SOAR** — turn trusted detections into scheduled analytics
  rules and automated playbooks beyond alert-only.
- **Microsoft Defender XDR onboarding** — ensure every pillar’s tables are present so hunts span the
  whole kill chain.
- **The per-pillar guides** — **Defender for Endpoint** and **Defender for Office 365** guides
  apply the same KQL skill to endpoint and email hunting specifically.
