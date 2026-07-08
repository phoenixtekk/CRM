# 6. Troubleshooting — Exact Data Match (EDM) in Microsoft Purview

Common EDM failure modes and how to resolve them. Work top-down; most "it isn't matching" cases are
**indexing time**, a **header/primary-element mismatch**, or a **stale/failed upload** — not a broken
SIT. **Verify licensing/tenant, limits, and Upload Agent switches** as you go — they evolve.

---

## The EDM node / schema creation is missing or greyed out
- **Most likely licensing (R1).** EDM requires **E5 / E5 Compliance / Information Protection &
  Governance**. Confirm the SKU in the admin center; the *Exact data match (EDM)* node under **Data
  classification → Classifiers** should then let you create a schema.
- **Or role (R2).** You need an **EDM authoring role** (Compliance Administrator / Compliance Data
  Administrator, or Organization Management / Security Administrator). Confirm membership in Purview →
  **Roles & scopes**. `PURVEDM-Discovery.ps1` surfaces both signals.

## Upload fails with an authorization / access error
- **Account not in `EDM_DataUploaders` (R3).** The Upload Agent account **must** be a member of the
  **`EDM_DataUploaders`** security group in Entra ID. Confirm the group exists and the account is a
  member (`PURVEDM-Discovery.ps1`), then re-run `EdmUploadAgent.exe /Authorize`.
- **Wrong-cloud Agent (R4).** A **Commercial** Upload Agent will not authenticate against **GCC / GCC
  High / DoD** (and vice-versa). Download and use the **build for your cloud**, with your cloud's
  endpoints.
- **Stale authorization.** Re-run `/Authorize` and complete modern-auth/MFA sign-in as the upload
  account.

## `EdmUploadAgent.exe` errors on the data file
- **Header row mismatch.** The **first row** of the `.csv`/`.tsv` must be the **field names**, matching
  the **schema** exactly (names and count). A mismatch is the most common upload/hashing error.
- **Wrong format / separator.** Match `/Format csv` (or `tsv`) to the actual file; if your data uses a
  non-standard separator, set the column-separator switch. Confirm the file isn't quoted/encoded in a
  way the Agent can't parse.
- **Bad lines.** If some rows are malformed, `/AllowedBadLinesPercentage <n>` lets the upload proceed
  while skipping them — but investigate *why* rows are bad rather than raising the threshold blindly.
- **Switch not recognised.** Switches vary by Agent version/cloud — run `EdmUploadAgent.exe /?` and
  confirm against the current Microsoft Learn page; don't assume a switch your build doesn't list.

## The SIT doesn't match values you KNOW are in the data
- **Give it time to index.** After a successful upload the data store must **index** before matching is
  reliable — Microsoft documents this can take up to roughly an hour (longer for large data). Confirm
  the upload **completed** (`/GetSession`) and the data store shows the expected **row count**
  (`/GetDataStore` or `PURVEDM-Report.ps1`) before concluding it's broken.
- **Wrong primary/searchable element.** A document only becomes a candidate if it contains an **exact
  match to a searchable (primary) field**. If your primary element is a low-value field (or the wrong
  one), matching won't trigger — review the schema (Phase 1) and re-create with a high-cardinality
  primary element.
- **Configurable match not set.** If documents format the value differently than stored (e.g.
  `123456789` vs `123-45-6789`), the field needs **ignore delimiters** / **ignore case**. Set the
  option and re-test.
- **No supporting element in proximity.** If the SIT requires a supporting element and your test
  document has only the primary value, it correctly won't match — add a supporting value in proximity
  (or test the primary-only tier if you defined one). Use `PURVEDM-Validate.ps1` to isolate this.

## The SIT matches values that are NOT in the data (over-matching)
- **The rule relies on the primary element alone.** Require **one or more supporting elements in
  proximity** so a lone look-alike value can't trigger. Tighten the SIT and re-validate (Test B).
- **You're actually hitting a different (pattern) SIT.** A built-in pattern SIT for the same data
  category may be matching, not your EDM SIT. Check *which* SIT fired in the match evidence; scope the
  policy to the **EDM SIT** specifically.

## Newly-added records don't match / removed records still match
- **The data store is stale (R8).** EDM matches the **last uploaded** hashes. New records won't match
  and removed records keep matching until you **re-hash + re-upload** (`EdmUploadAgent.exe
  /UploadData`). Confirm the last-upload timestamp (`PURVEDM-Report.ps1`) and stand up an automated
  **refresh schedule** (Best Practices).
- **Refresh failed silently.** A scheduled refresh that errors is invisible until matching degrades —
  alert on refresh failures and verify each run (Test D2/D3).

## The DLP policy isn't acting on EDM matches
- **Still in simulation.** By design the policy is built in **simulation/test** first — it reports
  would-act without enforcing. Confirm the mode; enforce only after the gates pass and sign-off is in
  writing (Phase 6).
- **Scope / workload mismatch (R7).** Confirm the policy covers the workload you're testing and
  includes your pilot user/group (`PURVEDM-Set-Scope.ps1`). A user outside `SG-EDM-Pilot` is correctly
  unaffected during pilot.
- **Condition not referencing the EDM SIT.** Confirm the rule's *Content contains → Sensitive info
  types* lists **`EDM - Customer Account Match`** (`PURVEDM-Report.ps1` shows which policies reference
  each EDM SIT).

## `Test-DataClassification` / validation script returns nothing
- **SIT name mismatch.** Pass the **exact** SIT name; confirm with `Get-DlpSensitiveInformationType`.
- **Not yet indexed.** Same as above — a freshly uploaded data store needs indexing time before
  `Test-DataClassification` will return EDM hits.
- **Connection.** Ensure `Connect-IPPSSession` succeeded and `Test-DataClassification` is available in
  your session.

## Government / sovereign-cloud specifics
- Use the **GCC High / DoD** Upload Agent, endpoints, and portal (`purview.microsoft.us` where
  applicable). A Commercial-cloud build **will not** work. Verify the correct downloads/endpoints for
  your cloud before hashing.

---

### When to escalate vs. defer
- **Technical** (upload errors, indexing, schema/SIT logic, policy wiring) → work the steps above; use
  `PURVEDM-Discovery.ps1` / `PURVEDM-Validate.ps1` / `PURVEDM-Report.ps1` to isolate.
- **Determination** (*which* records may be loaded, the enforced action, minimisation/retention of the
  loaded data) → **defer to compliance/privacy/legal** (GR §5). This solution provides the technical
  method and the evidence, not the determination.
