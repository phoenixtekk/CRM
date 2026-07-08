# 7. Best Practices — AWS Data-Source Governance (S3/RDS): Microsoft Purview

- Confirm connector availability before you design anything. The Amazon S3 and Amazon RDS connectors,
  the supported RDS engines, and the Microsoft AWS principal/external ID are evolving — read them from
  the Purview registration UI and Microsoft's current docs for your tenant rather than assuming a value
  that may have moved.
- Prefer role-based trust over keys for S3. A cross-account IAM role (ARN + external ID, assumed by
  Purview) avoids long-lived AWS access keys entirely; the external-ID condition prevents the
  confused-deputy problem. Never store an AWS access key in a script, a scan, or a document.
- Scope the S3 IAM role to read-only and the buckets in scope. Grant `AmazonS3ReadOnlyAccess` only if
  you must; a bucket-scoped read policy plus `kms:Decrypt` on just the encrypted buckets in scope is the
  least privilege a scan needs. Widen the role deliberately as you expand.
- Keep RDS secrets in Key Vault, referenced by name. Link an Azure Key Vault to the account, store the
  RDS read login there, and reference it by name — this is both the secure pattern and what keeps the
  provided scripts secret-free. Use a least-privilege read login, not an admin account.
- Pilot every scan on a bounded scope. Scoped, one-time scans on a couple of buckets or one database
  prove classification, connectivity, and **AWS request/egress cost** before you point a scan at an
  entire account or instance; move to scheduled scans only after a scope validates.
- Mind AWS cost and blast radius. S3 scanning issues list/get requests and can incur request and egress
  charges; scope scans, keep them one-time until validated, and agree the expected cost with the AWS
  account owner as part of change control.
- Trust system classifications first, add custom sparingly. The built-in classifications cover most
  regulated data; define a custom classification rule (`DGAWS-Classification-Custom-<name>`) only for a
  real internal pattern, and validate it against sample data before AWS-wide use.
- Every scanned AWS asset gets an owner and a steward. Ownership is what makes classification and access
  decisions accountable; an unowned bucket or database in the catalog is a governance gap, not a
  governed asset.
- Right-size the network path. Use the Azure (managed) integration runtime for reachable S3/RDS; stand
  up a self-hosted integration runtime (SHIR) with line of sight for RDS in a private VPC, and open only
  the security-group/bucket-policy rules the scanner needs — no broader.
- Treat determinations as someone else's job. The solution registers, scans, classifies, and catalogs
  AWS data; the business/records/legal owners decide sensitivity, retention, and access. Keep that
  separation explicit so technical scanning is never mistaken for a compliance ruling.
- Verify licensing, pricing, and portal paths as you go. The multicloud connectors and the consumption
  billing are evolving — confirm current availability and pricing in Microsoft's docs and the portal
  rather than assuming a path, an AWS account ID, or a price is permanent.
