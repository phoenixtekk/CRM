# 3. Implementation Guide — Standardize Power Platform Secrets in Azure Key Vault

Follow these steps **in order**. Work spans three portals:
- **Azure portal** (`https://portal.azure.com`) — Key Vault and RBAC.
- **Power Platform admin center** (`https://admin.powerplatform.microsoft.com`) — environment.
- **Power Apps maker portal** (`https://make.powerapps.com`) — solution and Secret environment variable.

> **Model:** Prove the pattern on **one** flow or app first (the pilot gate), validate no exposure,
> then expand. **Pattern A (Secret environment variables) is the default path**; Steps 6–7 cover the
> optional connector / Function patterns. Object names below match `02-requirements.md`.

## Step 1 — Create and configure the Key Vault
1. Azure portal → search **Key vaults** → **Create**.
2. **Subscription / Resource group:** select in-scope. **Key vault name:** `PP-Secrets – <Environment> – Vault` (use a DNS-safe form, e.g. `pp-secrets-prod-kv`). **Region:** your standard.
3. On the **Access configuration** tab, set **Permission model** to **Azure role-based access control**. (This satisfies requirement 2.2.)
4. On the **Networking** tab, choose public access, selected networks (allow trusted Microsoft services), or a private endpoint per requirement 2.8.
5. **Review + create → Create.**

> Rollback note: a newly created vault holds no secrets and grants no access until you add them in the next steps — deleting it (soft-delete honored) fully reverses Step 1.

## Step 2 — Store the secrets in the vault
1. Open `PP-Secrets – <Environment> – Vault` → **Objects → Secrets → + Generate/Import**.
2. **Upload options:** Manual. **Name:** a stable, purpose-based name (e.g. `crm-api-key`, `sftp-connection-string`). **Value:** paste the secret value. Set an **Expiration date** (governance — see Step 8).
3. **Create.** Repeat for each secret from the inventory (requirement 2.9).
4. Copy each secret's **Secret Identifier** (the resource URI). Use the **versionless** form (without the trailing version GUID) so consumers always resolve the current version.

> Do not record secret values in documentation, tickets, or scripts — only the names and identifiers.

## Step 3 — Grant the Power Platform service principal read access
1. Vault → **Access control (IAM) → + Add → Add role assignment**.
2. **Role:** `Key Vault Secrets User`. **Next.**
3. **Assign access to:** User, group, or service principal → **+ Select members** → search the first-party **Power Platform** / **Dataverse** service principal (the Microsoft first-party app used by Power Platform to resolve Key Vault references). Select it.
4. **Review + assign.** Name this assignment (for your records) `Secrets Reader – Power Platform SP – <Vault>`.
5. Scope tip: to grant per-secret instead of vault-wide, add the role assignment from the individual **secret's** Access control (IAM) blade.

> If you are unsure which service principal object represents Power Platform in your tenant, run `PPKV-Validation.ps1` — it identifies the Power Platform / Dataverse service principal and reports whether it already holds `Key Vault Secrets User`.

## Step 4 — Create the solution and a Secret environment variable (Pattern A)
1. Power Apps maker portal → select the target environment (top right) → **Solutions**.
2. **+ New solution** → **Display name:** a solution to hold the components → set/choose a **Publisher** → **Create**. (Or open an existing solution.)
3. Inside the solution: **+ New → More → Environment variable** (the exact maker menu path is volatile — if the label differs, choose **Environment variable**; defer UI minutiae to Microsoft docs).
4. **Display name:** `Secret EnvVar – <Integration> – <Environment>`. **Data type:** **Secret**. **Secret store:** **Azure Key Vault**.
5. Provide the Key Vault secret reference: the **Azure subscription**, the **Key Vault name** (`PP-Secrets – <Environment> – Vault`), and the **secret name** from Step 2 (the versionless reference). **Save.**

> Rollback note: deleting the environment variable removes only the reference — the vault secret is untouched.

## Step 5 — Consume the secret (remove the hardcoded value)
1. **In a Power Automate flow:** open the flow, add the environment variable's current value where the secret was hardcoded. Reference the environment variable (via the environment-variable value, e.g. the Dataverse/dynamic-content reference for `Secret EnvVar – <Integration> – <Environment>`) instead of the literal secret. Delete the literal.
2. **In a Power App:** replace the literal in the formula with a reference to the environment variable (retrieved through a flow or the supported environment-variable access, per Microsoft docs — apps should obtain the secret via a flow rather than reading the vault directly).
3. **Mark actions secure:** on any Power Automate action that receives or passes the secret, open **Settings** and enable **Secure Inputs** and **Secure Outputs** so the value never appears in run history.
4. **Save and publish** the flow/app.

> Rollback note: the pre-change flow/app definition captured under requirement G6 is the back-out; re-import it if the vaulted path misbehaves during the pilot.

## Step 6 — (Optional, Pattern B) Wire the Azure Key Vault connector
1. Register an Entra app `Secrets Reader – <Component> – <Environment>` (Entra → **App registrations → New registration**); create a client secret or certificate for it.
2. Assign it `Key Vault Secrets User` on the vault (as in Step 3).
3. In a flow, add the **Azure Key Vault** connector's **Get secret** action; create the connection using the service principal (tenant ID, client ID, credential).
4. On the **Get secret** action → **Settings → enable Secure Outputs**; enable **Secure Inputs** on any consuming action.

> Use only when the env-var pattern will not do; this is a premium connector (requirement 2.6).

## Step 7 — (Optional, Pattern C) Azure Function + managed identity via custom connector
1. Create an **Azure Function** `KV Broker Function – <Integration> – <Environment>`; on its **Identity** blade enable the **system-assigned managed identity**.
2. Assign the managed identity `Key Vault Secrets User` on the vault (as in Step 3).
3. In the Function code, read the secret from Key Vault using the managed identity (e.g. `DefaultAzureCredential` + the Key Vault secret client) and return only the required result.
4. Build a **custom connector** `KV Broker – <Integration> – <Environment>` that calls the Function; secure the connector's authentication. Call it from the flow/app.

> Use when you need transformation, brokering, or the secret to stay entirely inside Azure.

## Step 8 — Set expiry, rotation, and ownership (governance)
1. For each secret, confirm an **Expiration date** (Step 2) and apply **tags** for owner and purpose. Run `PPKV-Set-RotationOwnership.ps1` to set expiry and ownership/rotation tags consistently across secrets.
2. Establish the rotation cadence per the Best Practices guide. Because consumers reference the **versionless** secret, rotating (adding a new secret version) is picked up automatically — no app/flow edit required.

## Step 9 — Validate no exposure (pilot gate)
1. Run `PPKV-Validation.ps1` → confirms the vault is on the RBAC model, the Power Platform service principal has `Key Vault Secrets User`, and a Secret environment variable resolves.
2. Run the flow/app once, then open the flow's **run history** and confirm the secret value is **not** visible in inputs/outputs (Secure Inputs/Outputs working). Complete the **Testing Guide**.
3. Run `PPKV-Discovery.ps1` against fresh **exports** of the pilot flow/app/connector to confirm no hardcoded-secret pattern remains.

## Step 10 — Expand across the environment
1. Repeat Steps 2, 4, 5 (and 6/7 where used) for the remaining secrets/flows/apps from the inventory.
2. Re-run `PPKV-Report.ps1` for a full secrets inventory with expiry/rotation and access, and `PPKV-Discovery.ps1` for a final hardcoded-secret sweep of all exports.

---
### Order of operations
`Create + RBAC vault → Store secrets → Grant PP SP read → Solution + Secret env var → Refactor consumers (mark secure) → (connector/Function if needed) → Governance (expiry/rotation/ownership) → Validate no exposure → Expand`
