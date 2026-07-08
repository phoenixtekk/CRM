# 7. Best Practices — SAP Data Governance: Microsoft Purview

- Confirm connector availability before you design anything. The SAP ECC / S/4HANA / BW / HANA
  connectors, the supported SAP versions, and the driver/Java requirements are evolving — read them
  from the Purview registration UI and Microsoft's current docs for your tenant rather than assuming a
  value that may have moved.
- Scan through a SHIR, not the managed runtime. SAP systems sit behind the corporate network; install
  a self-hosted integration runtime on a hardened Windows host with line of sight to SAP, size it per
  Microsoft's guidance, and confirm Running/Available before you register anything.
- Get the SAP driver from SAP, under your license. The SAP JCo (`sapjco3.jar` + `sapjco3.dll`) and the
  HANA JDBC driver (`ngdbc.jar`) come from the SAP Support Portal via your S-user, with a supported
  64-bit Java runtime on the SHIR. Match the exact driver and Java versions Microsoft's current
  connector docs require — a mismatch is the most common Test-connection failure.
- Use a least-privilege SAP read user, and keep its secret in Key Vault by name. Create a dedicated SAP
  service user with a scoped authorization role (the `S_RFC` function-module set and metadata read the
  scanner needs — verify against Microsoft's docs), store its secret in an Azure Key Vault linked to
  the account, and reference it by name. Never place an SAP password in a script, a scan, or a
  document; never reuse an SAP admin account for a governance scan.
- Remember it maps metadata, not bulk data. SAP scans catalog and classify the metadata (systems,
  tables, fields) and sample to classify — set that expectation with SAP owners so a governance scan is
  never mistaken for a data extraction.
- Pilot every scan on a bounded scope. A scoped, one-time scan on one non-production SAP system/client
  proves classification, connectivity, and SAP load before you point a scan at the estate; move to
  scheduled scans only after a source validates, and coordinate every window with SAP Basis.
- Mind SAP system load and timing. Scanning reads the SAP dictionary and executes RFC calls; scope the
  scan, keep it one-time until validated, and agree the window with the SAP Basis team so a scan never
  competes with a batch or period-close.
- Trust system classifications first, add custom sparingly. The built-in classifications cover most
  regulated data; define a custom classification rule (`DGSAP-Classification-Custom-<name>`) only for a
  real internal pattern (an SAP customer- or vendor-ID scheme, for example), and validate it against
  sample data before SAP-wide use.
- Every scanned SAP asset gets an owner and a steward. Ownership is what makes classification and access
  decisions accountable; an unowned SAP source in the catalog is a governance gap, not a governed asset.
- Treat determinations as someone else's job. The solution registers, scans, classifies, and catalogs
  SAP; the business/records/legal owners decide sensitivity, retention, and access. Keep that
  separation explicit so technical scanning is never mistaken for a compliance ruling.
- Verify licensing, pricing, and portal paths as you go. The connectors and the consumption billing are
  evolving — confirm current availability and pricing in Microsoft's docs and the portal rather than
  assuming a path, a driver version, or a price is permanent.
