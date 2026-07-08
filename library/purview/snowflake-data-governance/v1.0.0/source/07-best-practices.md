# 7. Best Practices — Snowflake Data Governance (Microsoft Purview)

- **Confirm the connector and consumption model before you design anything.** Purview Data Governance is
  evolving (classic Data Map and the newer unified catalog), the Snowflake connector's requirements change,
  and scans **consume capacity**. Read the current connector docs and confirm the pricing/consumption model
  for *your* account before scanning — surprises here are budget surprises.
- **Never put a Snowflake secret in a script.** Store the credential secret in **Azure Key Vault**, link
  the Key Vault to Purview, and reference the Purview **credential by name**. The scripts pass the
  credential name, never a password. Rotating the secret is then a Key Vault action that touches no script.
- **Least-privilege the Snowflake scanning login.** The scan only needs to read metadata for the in-scope
  databases. Give the Snowflake user/role the minimum read it needs — not an admin role — so a compromised
  scan credential is low-impact.
- **Pilot on one database/schema first.** A full-account scan is expensive and surfaces more findings than
  you can curate at once. Prove the connection, scope, and classifications on `Snowflake – Pilot Scope –
  Stage1` before expanding.
- **Get the integration runtime right early.** If Snowflake isn't reachable from the managed runtime, a
  self-hosted integration runtime (SHIR) on a host with connectivity is required. Sort the network path and
  SHIR before creating the scan — most scan failures are connectivity, not configuration.
- **The classification scheme and owners are governance determinations.** Which classifications matter, who
  owns the data, and the glossary come from data-governance/privacy. Configure the scan rule set they
  specify and curate to their direction; capture determinations and stewards in `Snowflake Governance –
  Map`.
- **Schedule scans so the catalog stays current.** A one-time scan goes stale as Snowflake changes. Put
  `Snowflake – Scan` on a recurring schedule so the catalog reflects the live estate, and re-report to
  catch drift.
- **Curate, don't just connect.** Registering and scanning is the foundation; the value comes from
  assigning owners, glossary terms, and validating classifications. Treat curation as part of "done," led
  by the governance team.
- **Scope classifications deliberately.** Applying every classification to every column is noisy. Choose
  the classifications/SITs that matter for Snowflake in the scan rule set so the findings are actionable,
  not overwhelming.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write (register/scan) behind `-WhatIf` → `-Commit`; sign in interactively; reference the
  credential by name only. No secrets in a script or a document.
- **Keep determinations with their owners.** The solution registers, scans, and classifies Snowflake; the
  classification scheme, data ownership, glossary, and any regulatory obligation are determinations for
  data-governance, compliance, and privacy. Keep that separation explicit so cataloging is never mistaken
  for a governance ruling.
