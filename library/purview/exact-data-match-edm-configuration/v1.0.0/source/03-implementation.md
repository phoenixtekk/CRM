# 3. Implementation — Exact Data Match (EDM) in Microsoft Purview

This is the ordered, do-this-then-that guide. It follows the standard model
(**Assess → Design → Configure → Pilot (simulation/test) → Validate → Expand**) and — because EDM
loads a hashed copy of **real** sensitive records — it confirms **licensing, roles, upload
authorization, and data-owner/privacy sign-off FIRST**, then hashes/uploads with the plaintext kept
local, then builds enforcement in **simulation** before anything blocks. Every object is named
verbatim so the scripts, testing, and troubleshooting line up. Replace the `contoso.com` /
`CustomerRecords` sample names with your own.

> **Named objects used throughout (rename to your own):**
> - **EDM schema / data store name:** `CustomerRecords`
> - **Fields:** `AccountNumber` (**primary / searchable**, ignore delimiters), `LastName`
>   (supporting), `SSN` (supporting, ignore delimiters), `Email` (supporting)
> - **EDM sensitive information type:** `EDM - Customer Account Match`
> - **Entra security group (upload auth):** `EDM_DataUploaders` *(fixed name)*
> - **Source export:** `C:\EDM\CustomerRecords.csv` — **Hash output folder:** `C:\EDM\Hash`
> - **DLP pilot policy:** `DLP-EDM-CustomerRecords-Sim` (simulation), rule
>   `EDM-CustomerRecords-Block`, scoped to pilot ring `SG-EDM-Pilot`

> **Portal note.** The EDM **schema + SIT** are authored in **Microsoft Purview portal**
> (`purview.microsoft.com` → **Data classification → Classifiers → Exact data match (EDM)**), or via
> **PowerShell/XML**. The **hash + upload** step is **always** `EdmUploadAgent.exe` — there is no
> plaintext upload in the portal. The **DLP policy** is authored in **Purview → Data Loss
> Prevention**. Where a path, limit, or Agent switch may differ by tenant/cloud/version, **verify
> against Microsoft Learn and your tenant.**

> **Hard gate before you enforce.** Do **not** move the DLP policy from simulation to enforce until
> R8 (pilot validated) **and** the data-owner/privacy sign-off on loading these records (R5/R6, GR §5)
> are satisfied **in writing**.

---

## Phase 0 — Assess (confirm you can build safely)

1. **Confirm licensing (R1).** E5 / E5 Compliance / Information Protection & Governance present; the
   **Exact data match (EDM)** node is visible and lets you start a schema.
2. **Confirm authoring role (R2)** and the **`EDM_DataUploaders`** group + upload-account membership
   (R3). Run **`PURVEDM-Discovery.ps1`** (read-only) — it reports EDM licensing signals, existing
   schemas/SITs, and the `EDM_DataUploaders` group/membership via Graph.
   - **Gate 0:** licensing present, authoring role held, `EDM_DataUploaders` exists with the upload
     account in it → continue. Otherwise fix the missing prerequisite first.
3. **Confirm the Upload Agent for your cloud (R4).** `EdmUploadAgent.exe /?` runs; `/Authorize`
   succeeds. **Government tenants: confirm the GCC/GCC High/DoD build and endpoints.**
4. **Confirm the toolchain** (GR §3): `Connect-IPPSSession` and `Connect-MgGraph` succeed with an
   MFA-capable admin.

## Phase 1 — Design (agree it with the data owner, then name everything)

Decide and **record with the data owner / privacy / compliance**:

- **The schema (R5).** The fields and their roles, e.g.:

  | Field | Role | Configurable match | Notes |
  |---|---|---|---|
  | `AccountNumber` | **Primary / searchable** | **Ignore delimiters** | the exact value a document must contain |
  | `LastName` | Supporting | Ignore case | corroborates the match |
  | `SSN` | Supporting | Ignore delimiters | corroborates; never the sole element |
  | `Email` | Supporting | Ignore case | corroborates the match |

  - **At least one** field must be **searchable/primary**. Choose a field with **high cardinality and
    a stable format** (an account/record ID) as primary — not a low-cardinality field like a
    last name. **(Verify current max field count / searchable-field count in Microsoft Learn.)**
- **The SIT logic.** *Match when a document contains an exact `AccountNumber` value **and** at least
  **one supporting element** (`LastName` / `SSN` / `Email`) within a **proximity** window (e.g. the
  default character window), at **high confidence**.* Define a second, higher-confidence variant
  (primary + **two** supporting elements) if you want a stricter tier.
- **The source export.** How `C:\EDM\CustomerRecords.csv` will be produced (header row =
  `AccountNumber,LastName,SSN,Email`), within the documented row/size limits, on the secure host (R6).
- **The DLP pilot policy** and verbatim names (Phase 5):
  - Policy **`DLP-EDM-CustomerRecords-Sim`** — scoped to `SG-EDM-Pilot`, **simulation/test** first.
  - Rule **`EDM-CustomerRecords-Block`** — condition = the EDM SIT `EDM - Customer Account Match`;
    action (once enforced) = **block / block-with-override** per compliance.

## Phase 2 — Create the EDM schema and SIT

**Portal path (recommended):** Purview → **Data classification → Classifiers → Exact data match
(EDM)** → **EDM schemas → Create EDM schema**:

1. **Name** the schema `CustomerRecords` and add a description.
2. **Add the fields** `AccountNumber`, `LastName`, `SSN`, `Email`. Mark **`AccountNumber` as
   searchable (primary)**; set **configurable match** per field (ignore case / ignore delimiters) as
   designed in Phase 1.
3. **Save** the schema (data store `CustomerRecords`).
4. **Create the EDM sensitive information type** `EDM - Customer Account Match` referencing the schema:
   set the **primary element** (`AccountNumber`), the **supporting elements** and their **proximity**,
   and the **confidence level(s)** per the Phase 1 logic.

**PowerShell/XML path (repeatable/source-controlled):** author the schema XML and rule package, then:
```
New-DlpEdmSchema -FileData ([System.IO.File]::ReadAllBytes('CustomerRecords-schema.xml'))
New-DlpSensitiveInformationTypeRulePackage -FileData ([System.IO.File]::ReadAllBytes('CustomerRecords-rulepack.xml'))
```
`PURVEDM-Schema.ps1 -WhatIf` validates a schema XML and prints the intended `New-DlpEdmSchema` call;
`-Commit` creates/updates it.

- **Pass/fail:** `Get-DlpEdmSchema` lists `CustomerRecords`; `Get-DlpSensitiveInformationType` lists
  `EDM - Customer Account Match`. **Rollback:** remove the SIT then the schema
  (`Remove-DlpSensitiveInformationType` / `Remove-DlpEdmSchema`) — nothing matches until data is
  uploaded anyway.

> The schema must exist **before** you can upload data to its data store.

## Phase 3 — Export, hash, and upload the sensitive data (plaintext stays local)

On the **secure host** (R6), signed in as the **`EDM_DataUploaders`** upload account:

1. **Export** the records to `C:\EDM\CustomerRecords.csv` — first row exactly
   `AccountNumber,LastName,SSN,Email`, one record per row, within the documented limits.
2. **Authorize the Agent** (one-time / as needed):
   ```
   EdmUploadAgent.exe /Authorize
   ```
3. **(Optional) Test the hash locally first** — hash **without** uploading to validate the format and
   your salt handling:
   ```
   EdmUploadAgent.exe /CreateHash /DataStoreName CustomerRecords /Format csv `
       /SourceFile C:\EDM\CustomerRecords.csv /HashLocation C:\EDM\Hash /Salt <your-secret-salt>
   ```
   *(If you omit `/Salt`, the Agent generates one — **record it securely and reuse it** for every
   refresh.)*
4. **Hash and upload** the data to the `CustomerRecords` data store:
   ```
   EdmUploadAgent.exe /UploadData /DataStoreName CustomerRecords /DataFile C:\EDM\CustomerRecords.csv `
       /HashLocation C:\EDM\Hash /Format csv /AllowedBadLinesPercentage 5
   ```
5. **Confirm the upload/index status:**
   ```
   EdmUploadAgent.exe /GetSession /DataStoreName CustomerRecords
   EdmUploadAgent.exe /GetDataStore /DataStoreName CustomerRecords
   ```
6. **Securely delete** the plaintext `C:\EDM\CustomerRecords.csv` once the upload is confirmed (R6).

> **Allow time to index.** After a successful upload the data store needs **time to index** before
> matching works reliably (Microsoft documents this can take up to roughly an hour, sometimes longer
> for large data) — **do not judge matching before indexing completes.** `PURVEDM-Report.ps1` (and the
> Agent's `/GetDataStore`) surface the data-store's row count / last-upload signal.

- **Pass/fail:** `/GetSession` reports the upload **completed**; `/GetDataStore` shows the expected
  **row count** and a recent upload timestamp. **Rollback:** re-upload a corrected file (upload
  replaces the data store's data); the SIT simply matches against whatever is currently uploaded.

> **Switches vary by Agent version/cloud.** Confirm the exact switches with `EdmUploadAgent.exe /?`
> and the current Microsoft Learn "Get started with EDM" page — **do not** assume a switch that your
> build doesn't list.

## Phase 4 — Validate the SIT matches your data (before any policy)

Once indexing has had time to complete, **test the SIT with non-production sample values you are
authorised to use** (a handful of test records, or values you own):

1. **Portal Test:** Purview → **Data classification → Classifiers → Sensitive info types** → open
   `EDM - Customer Account Match` → **Test** → upload a document containing a **real primary value +
   a supporting value** → confirm it matches; upload a document with a **primary value that is NOT in
   your data** → confirm it does **not** match.
2. **PowerShell:** `PURVEDM-Validate.ps1` uses `Test-DataClassification` to run sample text against the
   EDM SIT and report whether it matched (exact-value hit + supporting element/proximity) — read-only.

- **Pass/fail:** an in-data primary value **with** a supporting element matches; a **not-in-data**
  value does **not** match; a primary value **without** any supporting element in proximity does
  **not** match (confirms EDM's exactness). If nothing matches, re-check indexing time, the header
  row, and the primary-element choice (see `06-troubleshooting.md`).

## Phase 5 — Build the DLP enforcement in SIMULATION/TEST first

In **Purview → Data Loss Prevention → Policies → Create policy** (custom), create
**`DLP-EDM-CustomerRecords-Sim`**, scoped to **`SG-EDM-Pilot`**, on the in-scope workloads (R7), with
the policy **mode set to simulation / test** (*Test it out first*). Add the rule:

- **`EDM-CustomerRecords-Block`**
  - **Condition:** *Content contains* → **Sensitive info types** → **`EDM - Customer Account Match`**
    (optionally combine with a sensitivity-label condition to scope to labeled content).
  - **Action (defined now, enforced later):** **Block** / **Block with override** per compliance, with
    a policy tip.

`PURVEDM-Schema.ps1`/`PURVEDM-Set-Scope.ps1` help stage the policy scope; the DLP simulation itself is
set in the portal (or with the DLP cmdlets in a Test* mode — never Enable here).

- **Pass/fail:** the policy shows **On (test/simulation)** and **healthy**; simulation begins reporting
  matches once pilot content flows. **Rollback:** set the policy **mode = simulation/Disable** — it
  never blocks users while in test.

## Phase 6 — Pilot, validate, then expand (enforce, then widen)

1. **Validate** — work the gates in `05-testing.md`: exact-match hits, near-miss/not-in-data correctly
   ignored, supporting-element/proximity behavior, and a measured **false-positive rate** (EDM's whole
   point is that this is near-zero). Reconcile with **Activity explorer** / DLP alerts.
2. **Enforce to the pilot ring** — only after the gates pass **and** the R5/R6 data-owner/privacy
   sign-off is in writing: change `DLP-EDM-CustomerRecords-Sim` **mode from simulation to enforce**
   (turn on the action/policy tips). Watch the first cohort closely.
3. **Widen scope deliberately** — group-by-group via `PURVEDM-Set-Scope.ps1` (`-WhatIf` first),
   re-running the gates after each expansion.
4. **Stand up the refresh (R8)** — schedule a re-hash + re-upload (`/UploadData`) of the source data on
   the agreed cadence so the data store never goes stale (see Best Practices for automating this on the
   secure host).

---

### Rollback summary

| Change | Rollback |
| --- | --- |
| Schema/SIT wrong | `Remove-DlpSensitiveInformationType` then `Remove-DlpEdmSchema` (or fix + re-create); nothing matches until data is uploaded. |
| Bad / stale uploaded data | Re-run `EdmUploadAgent.exe /UploadData` with a corrected export — the upload replaces the data store's data. |
| SIT not matching | Re-check indexing time, header row, primary-element choice, configurable-match options; re-test with `PURVEDM-Validate.ps1`. |
| DLP rule too aggressive / mis-scoped | Set `DLP-EDM-CustomerRecords-Sim` **mode = simulation** (instant, no data change); adjust conditions/scope and re-pilot. |
| Scope too wide | Remove members from `SG-EDM-Pilot` (`PURVEDM-Set-Scope.ps1`); the policy follows the group. |

> **Never** put the **salt**, the **plaintext export**, or any real record values into a script, log,
> or repository. The provided scripts never read source data or take a salt — the hashing/upload is
> done only by the Upload Agent on the secure host.
