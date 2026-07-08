# 7. Best Practices — Oracle Data Governance: Microsoft Purview

- Confirm connector availability and version support before you design anything. The Oracle connector,
  the supported Oracle versions, the JDBC-driver requirement, and the supported authentication methods
  are evolving — read them from the Purview registration UI and Microsoft's current docs for your tenant
  rather than assuming a value that may have moved.
- Keep the Oracle secret in Key Vault, referenced by name. Link an Azure Key Vault to the account, store
  the scanning login's password there, and reference it by name (`DGORACLE-Cred-Oracle-KV`) — this is
  both the secure pattern and what keeps the provided scripts secret-free. Never put an Oracle password
  in a script, a scan definition, or a document.
- Use a least-privilege, read-only scanning login — never a DBA account. Grant `CREATE SESSION` plus
  `SELECT` on just the in-scope schemas/objects and the data-dictionary views the scanner reads; verify
  the exact grant list in Microsoft's current docs. Widen access deliberately as you expand, one scope
  at a time.
- Right-size the network path and lock the firewall down. Stand up a self-hosted integration runtime
  (SHIR) with line of sight to the Oracle listener, and open the listener port (default 1521) **only**
  from the SHIR host — no broader. Confirm the SHIR shows Running/Available before you scan.
- Get the JDBC driver right on the SHIR. Missing or mismatched Oracle JDBC driver on the SHIR machine is
  the most common cause of a failed Test connection; verify whether your SHIR version bundles the driver
  or requires a manual install, and place it exactly where Microsoft's current docs specify.
- Pilot every scan on a bounded scope. Scoped, one-time scans on a few schemas prove classification,
  connectivity, driver, and database load before you point a scan at an entire instance; move to
  scheduled scans only after a scope validates.
- Mind database and SHIR load. Scanning reads live Oracle objects and sample data through the SHIR;
  agree the scan window with the DBA, keep scans one-time until validated, and watch instance load as
  scope grows.
- Trust system classifications first, add custom sparingly. The built-in classifications cover most
  regulated data; define a custom classification rule (`DGORACLE-Classification-Custom-<name>`) only for
  a real internal pattern (an internal account-number or customer-ID format), and validate it against
  sample data before Oracle-wide use.
- Every scanned Oracle asset gets an owner and a steward. Ownership is what makes classification and
  access decisions accountable; an unowned database or schema in the catalog is a governance gap, not a
  governed asset.
- Treat determinations as someone else's job. The solution registers, scans, classifies, and catalogs
  Oracle data; the business/records/legal owners decide sensitivity, retention, and access. Keep that
  separation explicit so technical scanning is never mistaken for a compliance ruling.
- Verify licensing, pricing, and portal paths as you go. The connector and the consumption billing are
  evolving — confirm current availability and pricing in Microsoft's docs and the portal rather than
  assuming a path, a supported version, or a price is permanent.
