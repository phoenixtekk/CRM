# 3. Implementation Guide — Double Key Encryption (DKE) Implementation, Microsoft Purview

Follow these steps **in order**. DKE spans three surfaces: the **customer-held key service** (hosting
you own), **Microsoft Entra ID** (`https://entra.microsoft.com`), and the **Microsoft Purview portal**
(`https://purview.microsoft.com`). Where exact versions, file names, or endpoint paths depend on
Microsoft's evolving reference implementation, **follow Microsoft's current Double Key Encryption
deployment documentation** — do not assume; the named objects and the order below are stable.

> **Model:** Deploy and secure your key service, wire it to a sensitivity label, then pilot the label
> on a small named audience before you expand. Pattern: Assess → Design → Configure → Pilot → Validate
> → Expand, with a documented rollback (unpublish the label policy).

The named objects created below are reused verbatim in Testing, Troubleshooting, and the scripts:

| Object | Name |
|---|---|
| DKE key service host (example) | `dke.contoso.com` |
| DKE key name | `DKE-Key-01` |
| DKE endpoint URL (public key) | `https://dke.contoso.com/DKE-Key-01` |
| Entra app registration | `App - DKE Key Service` |
| Sensitivity label | `Sensitivity Label - Ultra Confidential (DKE) - Named Group` |
| Label policy | `Label Policy - DKE Ultra Confidential - DKE Pilot` |
| Pilot users group | `Purview - DKE Pilot Users` |
| Authorized readers group | `SG - DKE Ultra Confidential Readers` |

## Step 1 — Confirm scope and the determination (Assess)
1. With data owners and compliance/legal, confirm **which** data is sensitive enough for DKE and the
   required **hosting region** for the key service (Requirement 2.7). DKE is for the **most sensitive**
   data only.
2. Confirm the trade-off is accepted: DKE content will **not** be inspected by content DLP, indexed
   for eDiscovery content search, or processed by Copilot/co-authoring (Overview, Limitations).
3. Record the decision. This is the input to the label's audience in Step 6.

## Step 2 — Provision the host and the scope groups
1. Provision the HTTPS host you control (Requirement 2.3) — for example `dke.contoso.com` with a
   trusted TLS certificate and DNS — in the region agreed in Step 1.
2. Create the audience groups with `IPDKE-Scope-And-ServiceHealth.ps1`:
   - `Purview - DKE Pilot Users` (who will pilot applying the label),
   - `SG - DKE Ultra Confidential Readers` (who is authorized to read DKE content).

## Step 3 — Obtain and configure the DKE key service
1. On the build workstation (Requirement 2.4), obtain **Microsoft's open-source Double Key Encryption
   service** source (published by Microsoft on GitHub) using `git`.
2. Edit the service's **`appsettings.json`** per Microsoft's documentation. The key settings are:
   - **`AuthorizedEmailAddress`** — the users/domains allowed to request key operations (align to
     `SG - DKE Ultra Confidential Readers`).
   - **`JwtAudience`** — the app ID/URI of `App - DKE Key Service` (from Step 4).
   - **`JwtIssuer`** — your tenant's token issuer, `https://sts.windows.net/<your-tenant-id>/`.
   - **`TestKeys` / key name and ID** — set the key **Name** to `DKE-Key-01` and a generated **GUID**.
   - **Issuer/Audience validation** — leave validation **on**.
3. Generate the DKE **key pair** as Microsoft's documentation directs (this is the customer-held key —
   keep the private key under your control; **never** commit it to source control or share it).

## Step 4 — Register the DKE service in Microsoft Entra ID
1. Entra admin center → **Applications → App registrations → New registration**. Name it
   `App - DKE Key Service`. Set the redirect/URI values per Microsoft's DKE documentation.
2. **Expose an API:** set the Application ID URI and add the delegated scope Microsoft's DKE docs
   specify (for example `user_impersonation`).
3. **API permissions / consent:** grant the required permission and **grant admin consent** for the
   tenant (Application/Cloud Application Administrator; Global Administrator only if consent requires
   it).
4. Copy the **Application (client) ID** and Application ID URI into the service's `appsettings.json`
   (`JwtAudience`, Step 3) so the two match.

## Step 5 — Build, deploy, and validate the key service
1. Build the service with the .NET SDK and **publish** it to the host from Step 2 (Azure App Service
   or IIS), served over **HTTPS**.
2. **Validate the deployment (read-only):** browse to the public-key endpoint
   `https://dke.contoso.com/DKE-Key-01`. It must return the **public key JSON** for `DKE-Key-01` over a
   trusted TLS connection. Run `IPDKE-Scope-And-ServiceHealth.ps1 -DkeEndpointUrl https://dke.contoso.com/DKE-Key-01`
   to probe reachability, TLS, and the JSON shape.
3. **Pass gate:** the endpoint returns the public key over HTTPS and is reachable from a pilot client.
   Do not proceed until this passes.

## Step 6 — Create the DKE sensitivity label (Configure)
1. Purview portal → **Information Protection → Sensitivity labels → Create a label**.
2. **Name and tooltip:** enter `Sensitivity Label - Ultra Confidential (DKE) - Named Group` and a
   clear user-facing tooltip explaining this is for the most sensitive data.
3. **Scope:** select **Items** (files and emails). **Next**.
4. **Encryption:** choose **Configure encryption**, then select **Use Double Key Encryption** and
   enter your **DKE endpoint URL** `https://dke.contoso.com/DKE-Key-01`. (If **Use Double Key
   Encryption** does not appear, your licensing does not include DKE — Requirement 2.1.)
5. **Permissions:** assign permissions to `SG - DKE Ultra Confidential Readers` (for example
   **Co-Author** or **Viewer** as the business requires). **Next**.
6. **Content marking:** optionally add a header/footer/watermark such as `ULTRA CONFIDENTIAL — DKE`.
   **Next**.
7. Leave auto-labeling **off** — DKE is applied deliberately by users on the most sensitive items, not
   automatically. **Next → Create the label.**

## Step 7 — Publish the label to the pilot audience (Pilot)
1. Purview portal → **Information Protection → Sensitivity labels → Label policies → Publish labels**.
2. **Choose labels to publish:** add `Sensitivity Label - Ultra Confidential (DKE) - Named Group`.
   **Next**.
3. **Assign to users and groups:** add **only** `Purview - DKE Pilot Users` for the pilot. **Next**.
4. **Policy settings:** leave defaults; do **not** set DKE as a default or mandatory label. **Next**.
5. **Name:** `Label Policy - DKE Ultra Confidential - DKE Pilot`. **Next → Submit.** Allow time (up to
   24 hours) for the label to appear in pilot users' Office clients.

## Step 8 — Validate the pilot (Validate)
1. Complete the Testing Guide against `Purview - DKE Pilot Users` on a supported Windows Office
   desktop client.
2. Confirm the core proofs: the DKE label appears; applying it double-encrypts the item; opening it
   requires reaching **your** key service; and a user **outside** `SG - DKE Ultra Confidential Readers`
   is denied.
3. Run `IPDKE-Validation.ps1` (label present with DKE encryption and the expected endpoint URL, label
   policy published to the pilot group, endpoint reachable) and `IPDKE-Report.ps1` (DKE label usage /
   coverage). Confirm the endpoint health with `IPDKE-Scope-And-ServiceHealth.ps1`.
4. **Gate:** proceed to Expand only when every proof passes and the key service is healthy and
   monitored.

## Step 9 — Expand under change control (Expand)
1. Once the pilot passes, widen the label policy `Label Policy - DKE Ultra Confidential - DKE Pilot`
   from `Purview - DKE Pilot Users` to the broader approved audience (still a **named** audience for
   the most sensitive data — not All users).
2. Add authorized readers to `SG - DKE Ultra Confidential Readers` as the business approves.
3. Put the **key service into production operations** — monitoring, backup of the customer key,
   patching, and a documented disaster-recovery plan (its availability now gates access to DKE
   content).
4. Re-validate each expansion with `IPDKE-Validation.ps1`, `IPDKE-Report.ps1`, and
   `IPDKE-Scope-And-ServiceHealth.ps1`.
5. **Rollback (if needed):** unpublish the label policy (Purview → **Label policies →** delete/disable
   `Label Policy - DKE Ultra Confidential - DKE Pilot`). The label remains defined but is applied to no
   one; **already-protected content still requires both keys to open**, so keep the key service running
   during and after any rollback.

---
### Order of operations
`Assess/determine → host + groups → obtain & configure key service → Entra app registration → build/deploy & validate endpoint → create DKE label (endpoint URL) → publish to pilot → validate → expand`
