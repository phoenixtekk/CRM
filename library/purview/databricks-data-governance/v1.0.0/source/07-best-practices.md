# 7. Best Practices — Databricks Data Governance (Unity Catalog / lakehouse): Microsoft Purview

- Confirm the connector before you design anything. The Azure Databricks connector — **Unity Catalog** vs.
  **Hive metastore** — its prerequisites, and its lineage support are evolving; read them from the Purview
  registration UI and Microsoft's current docs for your tenant rather than assuming a connector name or a
  capability that may have moved. Choosing the wrong connector produces an empty or partial scan.
- Prefer Unity Catalog where it is enabled. The Unity Catalog connector enumerates `catalogs → schemas →
  tables/views` and brings Unity Catalog **lineage** into Purview — the lineage-rich path. Use the Hive
  metastore connector only for workspaces that are not Unity Catalog-enabled.
- Keep the scan secret in Key Vault, referenced by name. Link an Azure Key Vault to the account, store the
  Databricks service principal / PAT there, and reference it by name (`DGDBX-Cred-Databricks-KV`) — this is
  both the secure pattern and what keeps the provided scripts secret-free. **No Databricks token or secret
  ever goes into a script, a scan, or a document.**
- Grant the scan identity least-privilege metadata read — never workspace admin. The connector needs to
  read catalog/schema/table **metadata** for the in-scope objects (Unity Catalog grants / metadata read),
  not admin rights and not row data beyond what classification sampling requires. Widen the grants
  deliberately as you expand to new catalogs.
- Pilot every scan on a bounded scope. Scoped, one-time scans on a single catalog/schema prove
  classification, connectivity, lineage, and **Databricks/Azure cost** before you point a scan at an entire
  metastore; move to scheduled scans only after a scope validates.
- Mind compute and metered cost. Scanning drives Databricks compute and Purview Data Governance is
  consumption-billed; scope scans tightly, keep them one-time until validated, and agree the expected cost
  with the workspace and Azure subscription owners as part of change control. Cancel a runaway scan in the
  portal (no source data is modified) and re-scope.
- Trust system classifications first, add custom sparingly. The built-in classifications cover most
  regulated data; define a custom classification rule (`DGDBX-Classification-Custom-<name>`) only for a
  real internal pattern, and validate it against sample data before metastore-wide use.
- Treat lineage as verify-first, not guaranteed. Unity Catalog lineage depth in Purview is connector- and
  tenant-dependent and evolving; confirm what surfaces for your tenant and connector version, and don't
  promise lineage coverage the connector doesn't yet provide.
- Every scanned lakehouse asset gets an owner and a steward, and is cataloged. Ownership is what makes
  classification and access decisions accountable; publish curated **data products** under
  `DGDBX-Domain-Lakehouse` so the lakehouse is discoverable with a use purpose — an unowned, uncataloged
  table is a governance gap, not a governed asset.
- Right-size the network path. Use the Azure (managed) integration runtime for a reachable workspace; stand
  up a self-hosted integration runtime (`DGDBX-SHIR`) with line of sight for a VNet-injected / Private Link
  workspace, and open only the rules the scanner needs to reach the workspace and metastore — no broader.
- Treat determinations as someone else's job. The solution registers, scans, classifies, catalogs, and
  wires lineage for Databricks data; the business/records/privacy/legal owners decide sensitivity,
  retention, and access. Keep that separation explicit so technical scanning is never mistaken for a
  compliance ruling.
- Verify licensing, pricing, and portal paths as you go. The Data Governance connectors, the Unified
  Catalog experience, and consumption billing are evolving — confirm current availability, connector name,
  lineage support, `api-version` values, and pricing in Microsoft's docs and the portal rather than
  assuming a path or a price is permanent.
