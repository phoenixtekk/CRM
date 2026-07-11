# Best Practices — Workshop: Microsoft Defender for Endpoint

Keep-it-clean guidance for turning an MDE workshop into a durable investigation-and-response skill
that stays sharp over time.

## Investigate, don’t just triage

- **Always read the story.** Before closing an alert, walk the **incident graph** and the **alert
  story** (process tree) and open the **device timeline**. Establish root cause and blast radius —
  the summary card is a headline, not the investigation.
- **Answer a question with the timeline.** "What did this machine do between X and Y?" is a timeline
  query, not a guess. Practise reconstructing sequences until it is fast.
- **Re-hunt after every incident.** A new indicator (hash, IP, filename, command line) is a new query
  — run it across all devices, not just the one that alerted.

## Roll out ASR the safe way

- **Audit first, always.** Put a new ASR rule in **audit** (`ASR-Lab-AuditOnly-Pilot` is the pattern),
  read the `DeviceEvents` audit entries, and understand what it **would** block before enforcing.
- **Enforce by ring, with rollback.** Move a clean rule to **block** in stages (lab devices → a pilot
  ring → broadly), watching for breakage, and know how to revert. Enforcing is an **operations
  decision**, not a switch you flip in class.
- **Exclude narrowly.** When a rule blocks something legitimate, add a **specific** exclusion, not a
  blanket one — and record why.

## Respond deliberately, through approvals

- **Read-only Live Response by default.** Use `processes`, `dir`, `fileinfo`, `getfile` to gather
  evidence. Reserve change commands (`run`, `remediate`, `putfile`) for real incidents under the SOC’s
  approvals — never as a workshop reflex.
- **Right action, right approval.** Isolate contains a device but disrupts the user; stop-and-quarantine
  removes a file; collect-package preserves evidence. Match the action to the scenario and know how to
  reverse it (release from isolation).
- **Never execute production response in a class.** Teach and gate the actions; perform them only in a
  real incident.

## Turn hunts into durable coverage — carefully

- **Alert-only first.** Promote a hunt to a custom detection (`Detect-MDELab-Pilot`) only once it is
  quiet and accurate, and keep it **alert-only** until proven. A noisy detection trains the team to
  ignore alerts.
- **Version your queries.** Keep the endpoint KQL library in source control so hunts are reviewable and
  portable — the same discipline the Sentinel detection-as-code solution applies.

## Run it as a program, not a one-off class

- **Practice keeps the skill.** Schedule recurring investigation drills and rotate who leads the hunt
  of the week.
- **Feed the hunt library.** Hand tuned endpoint queries to the **Threat Hunting hunt-library**
  solution so they join the maintained, operated program.
- **Re-run for new hires.** The take-home runbook and knowledge-check make onboarding a new analyst
  repeatable.

## Where to go next

With the team able to investigate and respond on the endpoint, the natural next steps in this catalog
are:

- **Microsoft Defender for Endpoint — onboarding accelerator / optimization** — ensure the deployment
  itself is complete and tuned (the platforms this workshop drives).
- **Advanced KQL for SecOps workshop** — deepen the query language this workshop applies to endpoint
  tables, and extend hunting across Sentinel.
- **Microsoft Defender XDR onboarding** — bring identity, email, and cloud-app signal into the same
  incident so endpoint threats correlate with the whole kill chain.
- **Threat Hunting hunt-library** — adopt and operate a curated, maintained hunt program built on the
  skill this workshop gives you.
