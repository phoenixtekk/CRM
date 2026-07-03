# Implementation Guide — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Ordered, click-to-implement steps for a 1:1-domain Exchange Online migration **within GCC High**. Every portal path uses the **`*.us`** GCC High URLs. GCC-High-only caveats are called out **inline at the step where they matter**.

> **Before Step 1:** complete the Requirements Guide (`02-requirements.md`, R0–R8) and the category baseline (G1–G6). Confirm **R0** (both tenants GCC High) and **R1** (migration method + support status) — these gate everything below.
>
> **Object naming (reused across steps).** Create and reuse these named objects: a pilot group **`EXOMIGG-Pilot`**, wave groups **`EXOMIGG-Wave1..N`**, a migration endpoint / org relationship named **`EXOMIGG-CrossTenant`**, and a working folder **`EXOMIGG-baseline\`** holding all exports. Later steps refer to these by name.

---

## Phase A — Assess

### Step 1. Establish sovereign-cloud connections

On the operator workstation (PowerShell 7):

```powershell
# Exchange Online — GCC High
Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh -UserPrincipalName admin@source-tenant.onmicrosoft.us
# Microsoft Graph — US Gov
Connect-MgGraph -Environment USGov -Scopes 'User.Read.All','Organization.Read.All','Directory.Read.All'
```

> **GCC High caveat.** Omitting `-ExchangeEnvironmentName O365USGovGCCHigh` or `-Environment USGov` makes the modules authenticate against the **Commercial** cloud (`login.microsoftonline.com`) and fail for a GCC High tenant. `-ExchangeEnvironmentName O365USGovGCCHigh` auto-selects `outlook.office365.us` and the `login.microsoftonline.us/organizations` authority — do **not** also pass `-ConnectionUri`. (Microsoft Learn, *Connect to Exchange Online PowerShell*.)

### Step 2. Run Discovery (read-only) on both tenants

Run **`EXOMIGG-Discovery.ps1`** against the **source**, then the **target**. It captures: detected cloud/environment, mailbox inventory and sizes, licensing, DNS/MX/Autodiscover/SPF/DKIM/DMARC for the migrating domain(s), and admin-role holders — writing them into **`EXOMIGG-baseline\`**.

This baseline satisfies **G6/R8** (rollback) and feeds the readiness gate.

### Step 3. Readiness gate (Assess exit)

Confirm from the Discovery output: both tenants are GCC High (R0); target has enough US Gov licenses (R3); DNS is under your control (R6); endpoints reachable (R4); roles assigned (R2). **Do not proceed to Configure until this is clean or exceptions are waived in writing.**

---

## Phase B — Configure

### Step 4. Assign/confirm admin roles (GCC High portals)

- In **`https://entra.microsoft.us`** → **Identity → Roles & admins → Roles**, confirm **Global Administrator** on the account that will consent the migration configuration.
- In **`https://admin.exchange.office365.us`** → **Roles → Admin roles**, confirm **Organization Management** (for the one-time `OrganizationRelationship`) and a **Move Mailboxes**-capable role for the operator running batches.

> **GCC High caveat.** These are the **`*.us`** portals — the Commercial `entra.microsoft.com` / `admin.exchange.microsoft.com` will not show your GCC High tenant.

### Step 5. Prepare target licensing

In **`https://portal.office365.us`** → **Billing → Licenses**, confirm US Gov mailbox licenses for every migrated user. **For a native move**, confirm the **Cross-Tenant User Data Migration** add-on is present.

> **GCC High caveat.** Buy through your **authorized US Gov reseller / AOS-G partner**. **verify for GCC High:** confirm the Cross-Tenant User Data Migration add-on is orderable on your Gov agreement **before** relying on a native move; if not, use the third-party/PST path (Step 7B). **Do not license the target MailUser before its `ExchangeGUID` is stamped** — doing so provisions a new empty mailbox instead of accepting the move. (Microsoft Learn, *Cross-tenant mailbox migration*.)

### Step 6. Allow-list endpoints and validate connectivity

Ensure the proxy/firewall allows the **GCC High `.us`** endpoints (R4). Then run **`EXOMIGG-Validation.ps1`** against both tenants — it verifies module versions, a successful Gov connection, role presence, license counts, and endpoint reachability, and reports **pass/fail** per check.

### Step 7. Configure the migration engine

Choose **one** path per the decision in R1:

**7A — Native same-cloud move (GCC High → GCC High only, if confirmed available).**
- In the **target** tenant, set up the cross-tenant `OrganizationRelationship` named **`EXOMIGG-CrossTenant`** and its **`-MailboxMoveCapability`** (Organization Administrator only). Register/consent the migration application in **both** tenants against **`login.microsoftonline.us`**.
- Build the target-side **MailUser** objects (mail-enabled users) carrying the source **ExchangeGUID** and proxy addresses, so the move converts them to mailboxes rather than creating new ones.
- Use **`EXOMIGG-Set-ScopeTargeting.ps1`** (default `-WhatIf`) to build the pilot/wave target groups from a mapping CSV.

> **GCC High caveat.** Every app registration, consent, and endpoint here is the **`.us`** instance. **verify for GCC High:** the native cross-tenant feature is **Public Preview** in government clouds — confirm eligibility for your tenants before enabling. Newer conveniences like **Cross-Tenant Identity Mapping** should be assumed **unavailable** in GCC High until Microsoft documents otherwise. (Microsoft Learn, *national cloud deployments*.)

**7B — Third-party tool or PST (required for cross-cloud; supported alternative for same-cloud).**
- Register the vendor's application against the **US Gov instance** (`login.microsoftonline.us`) in both tenants and select the vendor's **GCC High** service. Provide the mailbox-mapping CSV (map using the `*.onmicrosoft.us` initial domains).
- **Tool internals — batch configuration, throttling, delta passes — are deferred to that vendor's GCC High documentation.**

### Step 8. Configure gate (Configure exit)

`EXOMIGG-Validation.ps1` passes on **both** tenants and the chosen engine can authenticate. Only then proceed to Pilot.

---

## Phase C — Pilot

### Step 9. Prepare the pilot domain/DNS (non-disruptive prep)

In **`https://portal.office365.us`** (target) → **Settings → Domains**, **add** the migrating domain and create the verification **TXT** record in DNS.

> **Expected behavior (same as Commercial):** verification **fails while the domain is still in use in the source tenant**. Adding it now lets DNS propagate (up to 72h). Final verification happens at cutover.

Lower the domain's **MX TTL** (e.g., to 5 minutes) ahead of any cutover.

### Step 10. Migrate the pilot batch

Populate **`EXOMIGG-Pilot`** with a small set of low-risk, named test mailboxes. Run the move for just this group using the engine from Step 7 (native `New-MigrationBatch`/`New-MoveRequest`, or the vendor tool). Monitor to completion.

### Step 11. Validate the pilot (Pilot exit gate)

Run **`EXOMIGG-Report.ps1`** for the pilot mailboxes and perform the checks in `05-testing.md`: content present, folder counts match, permissions/delegation intact, mail flow to/from works. **Do not expand until every pilot mailbox passes and there are no unresolved errors.**

---

## Phase D — Validate & Expand

### Step 12. Build waves

Use **`EXOMIGG-Set-ScopeTargeting.ps1`** (default `-WhatIf`; re-run with `-Execute`/`-Confirm` only after reviewing the WhatIf output) to assign the remaining mailboxes to **`EXOMIGG-Wave1..N`** from the mapping CSV. Keep waves sized to your validated throughput.

### Step 13. Migrate waves with validation between each

For each wave: run the move, then **`EXOMIGG-Report.ps1`** + the `05-testing.md` checks. Treat each wave's validation as a gate before the next.

### Step 14. Source-side domain release and target verification (cutover prep)

On cutover day, in the **source** tenant remove the migrating domain from all objects (reset default addresses to `*.onmicrosoft.us`, strip proxy addresses, set default domain to the initial domain). Then complete **domain verification in the target** (`portal.office365.us` → Domains).

> **GCC High caveat.** All of this is in the **`*.us`** portals. The domain cannot verify in the target until fully released from the source — expect a short window after release before target verification succeeds.

### Step 15. MX / Autodiscover cutover

Point the domain's **MX** and **Autodiscover CNAME** to the **target** GCC High tenant. When the (lowered) TTL expires, mail flows to the migrated mailboxes. Recreate transport rules, connectors, and allow/block lists in the target. Verify mail flow both directions.

### Step 16. Post-migration cleanup and closeout

Clear Outlook Auto-Complete (nickname cache) or add legacy DN as an X.500 proxy to avoid NDRs. Run a final **`EXOMIGG-Report.ps1`** across all migrated mailboxes and archive it with the change record. Confirm rollback baseline is retained for the agreed period.

---

## Rollback (if a gate fails)

Re-point **MX/Autodiscover to the source** tenant (records captured in `EXOMIGG-baseline\`), re-add the domain to the source if it was released, and re-enable source mailboxes. Because moves are staged in waves behind gates, rollback scope is limited to the current wave.

---

## Endpoint quick-reference (this engagement)

| Purpose | GCC High value |
|---|---|
| M365 admin center | `https://portal.office365.us` |
| Exchange admin center | `https://admin.exchange.office365.us` |
| Entra admin center | `https://entra.microsoft.us` |
| Defender / Purview | `https://security.microsoft.us` / `https://compliance.microsoft.us` |
| EXO PowerShell | `Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` |
| Graph PowerShell | `Connect-MgGraph -Environment USGov` |
| Login authority | `https://login.microsoftonline.us` |

Full cited detail: `gcc-high-parity-notes.md`.
