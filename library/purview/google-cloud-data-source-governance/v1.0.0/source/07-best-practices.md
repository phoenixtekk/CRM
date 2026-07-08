# 7. Best Practices — Google Cloud Data-Source Governance: Microsoft Purview

- Design the collection hierarchy before you register anything. Collections carry both organization
  and access control; a hierarchy planned by GCP project or sensitivity (with
  `DGGCP-Collection-Pilot` as the first node) is far cheaper than re-parenting sources later.
- Least-privilege by collection, always. Assign Data source admin, Data curator, and Data reader at
  the narrowest collection scope; reserve account-level Collection admin for a small named group.
  Broad roles at the root are the most common governance finding.
- Never put key material in a script or scan. Grant the Google Cloud **service account read-only**
  BigQuery access, store its **private key in an Azure Key Vault** linked to the account, and
  reference the credential **by name** — this is both the secure pattern and what keeps the provided
  scripts secret-free. Rotate the service-account key on a schedule and re-store it in Key Vault.
- Pilot every scan on a bounded scope. Scoped, one-time scans on a pilot dataset set prove
  classification and BigQuery cost before you point a scan at an entire project or the whole estate;
  move to scheduled scans only after a scope validates.
- Keep the SHIR healthy and reachable. BigQuery scans run on the self-hosted integration runtime;
  keep its Java/driver prerequisites current, monitor that it stays **Running**, and confirm its
  network line of sight to BigQuery before each expansion wave.
- Trust system classifications first, add custom sparingly. The built-in classifications cover most
  regulated data; define a custom classification rule (`DGGCP-Classification-Custom-<name>`) only for
  a real internal pattern, and validate it against sample data before estate-wide use.
- Every scanned asset has an owner and a steward. Ownership is what makes classification and access
  decisions accountable; an unowned BigQuery dataset in the catalog is a governance gap, not a
  governed asset.
- Watch BigQuery cost as scope grows. Scanning issues read jobs against BigQuery and can incur
  query/egress cost; scope scans to what needs classifying, schedule only validated scopes, and agree
  the expected cost with the source owners before widening.
- Treat determinations as someone else's job. The solution classifies, maps, and catalogs; the
  business/records/legal owners decide sensitivity, retention, and access. Keep that separation
  explicit so technical scanning is never mistaken for a compliance ruling.
- Verify licensing and portal paths as you go. The Data Governance experience, the Google BigQuery
  connector, the required GCP IAM roles, and its consumption billing are evolving — confirm current
  availability and pricing in Microsoft's docs and the portal rather than assuming a path, a role, or
  a price is permanent.
