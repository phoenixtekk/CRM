# 7. Best Practices — Microsoft Purview Data Governance: Data Map, Scanning & Unified Catalog

- Design the collection hierarchy before you register anything. Collections carry both organization
  and access control; a hierarchy planned by business unit or sensitivity (with `DG-Collection-Pilot`
  as the first node) is far cheaper than re-parenting sources later.
- Least-privilege by collection, always. Assign Data source admin, Data curator, and Data reader at
  the narrowest collection scope; reserve account-level Collection admin for a small named group.
  Broad roles at the root are the most common governance finding.
- Never put a secret in a script or scan. Use the account's managed identity or an Azure Key Vault
  linked to the account for every source credential — this is both the secure pattern and what keeps
  the provided scripts secret-free.
- Pilot every scan on a bounded scope. Scoped, one-time scans on a pilot source set prove
  classification and cost before you point a scan at an entire lake or database estate; move to
  scheduled scans only after a scope validates.
- Trust system classifications first, add custom sparingly. The built-in classifications cover most
  regulated data; define a custom classification rule (`DG-Classification-Custom-<name>`) only for a
  real internal pattern, and validate it against sample data before estate-wide use.
- Curate to data products, not just assets. A raw classified asset is visible to IT; a published
  **data product** with an owner, a use purpose, and terms of use is what the business can actually
  find and trust — curation is the point of the catalog.
- Every published asset has an owner and a steward. Ownership is what makes classification and access
  decisions accountable; an unowned asset in the catalog is a governance gap, not a governed asset.
- Let lineage come from the source systems. Lineage populates automatically from supported systems
  (Data Factory, Synapse, Power BI); wire those integrations rather than hand-drawing lineage, and
  record which systems are not lineage sources so the gaps are known.
- Treat determinations as someone else's job. The solution classifies, maps, and catalogs; the
  business/records/legal owners decide sensitivity, retention, and access. Keep that separation
  explicit so technical scanning is never mistaken for a compliance ruling.
- Verify licensing and portal paths as you go. The Data Governance experience, its feature set (data
  quality, multicloud connectors), and its consumption billing are evolving — confirm current
  availability and pricing in Microsoft's docs and the portal rather than assuming a path or a price
  is permanent.
