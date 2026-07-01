# 2. Requirements Guide — Standardize Power Platform Secrets in Azure Key Vault

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide prerequisites are in
`global-requirements-azure-solutions.md`.

> Object naming (reused verbatim across docs and scripts):
> - Key Vault: `PP-Secrets – <Environment> – Vault`
> - Secret environment variable: `Secret EnvVar – <Integration> – <Environment>`
> - Read role assignment: `Secrets Reader – Power Platform SP – <Vault>`
> - App registration / managed identity (connector/Function): `Secrets Reader – <Component> – <Environment>`
> - Custom connector: `KV Broker – <Integration> – <Environment>`
> - Azure Function: `KV Broker Function – <Integration> – <Environment>`

## 2.1 An Azure subscription with an Azure Key Vault
**Description:** An Azure subscription in scope and a Key Vault to hold the secrets (`PP-Secrets – <Environment> – Vault`).
**Why required:** The vault is the single store for all Power Platform secrets.
**How to verify:** Azure portal → **Key vaults**; confirm the vault exists (or the subscription can create one). Run `PPKV-Discovery.ps1` to list vaults.
**How to implement if missing:** Create a Key Vault (Implementation Step 1). One vault per Power Platform environment is the clean default.

## 2.2 Key Vault uses the Azure RBAC permission model
**Description:** The vault's permission model is set to **Azure role-based access control**, not the legacy **Vault access policy** model.
**Why required:** The Secret environment variable pattern and least-privilege role grants assume RBAC; a vault on the access-policy model will not honor the RBAC role assignments this solution uses.
**How to verify:** Vault → **Settings → Access configuration** shows **Azure role-based access control**. Run `PPKV-Validation.ps1` (reports the permission model).
**How to implement if missing:** Switch **Access configuration → Permission model** to **Azure role-based access control** (Implementation Step 1).

## 2.3 The Power Platform / Dataverse service principal has Key Vault read access
**Description:** The first-party Power Platform / Dataverse service principal is granted the **`Key Vault Secrets User`** RBAC role on the vault (or on the specific secrets) — the role assignment `Secrets Reader – Power Platform SP – <Vault>`.
**Why required:** Pattern A (Secret environment variables) resolves the vault reference **as** this service principal; without the read role the environment variable will not resolve.
**How to verify:** Vault → **Access control (IAM) → Role assignments**; confirm `Key Vault Secrets User` is assigned to the Power Platform service principal. Run `PPKV-Validation.ps1`.
**How to implement if missing:** Assign the role (Implementation Step 3) or run `PPKV-Remediation.ps1` to assign `Key Vault Secrets User` to the service principal.

## 2.4 A Power Platform environment with Dataverse
**Description:** The target Power Platform environment has **Dataverse** provisioned (required for solutions and environment variables of type Secret).
**Why required:** Secret environment variables are Dataverse components; without Dataverse there are no solutions and no Secret env-var type.
**How to verify:** Power Platform admin center (`https://admin.powerplatform.microsoft.com`) → **Environments** → the environment shows a **Dataverse** database.
**How to implement if missing:** Add a Dataverse database to the environment in the Power Platform admin center.

## 2.5 Maker access and a solution to hold the components
**Description:** A maker account with rights to the target environment and a **solution** in the Power Apps maker portal to contain the Secret environment variable(s).
**Why required:** Environment variables (Secret type) are authored inside a solution in the maker portal.
**How to verify:** Power Apps maker portal (`https://make.powerapps.com`) → select the environment → **Solutions**; confirm a solution exists (or can be created) and you can edit it.
**How to implement if missing:** Create a solution (Implementation Step 4); ensure the maker holds at least environment-maker rights.

## 2.6 Licensing for the retrieval pattern chosen
**Description:** Licensing sufficient for the pattern in use. Pattern A (Secret env vars) uses standard Power Platform capability. Pattern B (Azure Key Vault connector) is a **premium** connector requiring premium Power Platform licensing. Pattern C adds an **Azure Function** (Azure consumption cost).
**Why required:** Premium connectors and Azure resources are gated by licensing/subscription cost.
**How to verify:** Power Platform admin center → **Billing / Licenses**; confirm premium entitlement if using Pattern B. Confirm the Azure subscription can host a Function for Pattern C.
**How to implement if missing:** Assign premium Power Platform licensing for Pattern B, or default to Pattern A (no premium requirement).

## 2.7 An Entra identity for the connector / Function pattern (if used)
**Description:** For Pattern B, an **app registration / service principal** (`Secrets Reader – <Component> – <Environment>`) for the connector's connection. For Pattern C, a **managed identity** on the Azure Function.
**Why required:** The connector authenticates as a service principal; the Function reads the vault as its managed identity. Each needs `Key Vault Secrets User`.
**How to verify:** Entra → **App registrations** (Pattern B) or the Function's **Identity** blade (Pattern C); confirm the identity exists and holds `Key Vault Secrets User` on the vault (`PPKV-Validation.ps1`).
**How to implement if missing:** Register the app / enable the managed identity, then assign `Key Vault Secrets User` (Implementation Step 6/7). Skip if using Pattern A only.

## 2.8 Network access to Key Vault
**Description:** Power Platform / Azure Function egress can reach the Key Vault data-plane endpoint (`https://<vault>.vault.azure.net`); vault firewall / private endpoint allows the consumer.
**Why required:** If the vault firewall blocks the caller, secret resolution fails even with correct RBAC.
**How to verify:** Vault → **Networking**; confirm the caller is permitted (public access, selected networks including trusted Microsoft services, or private endpoint reachable).
**How to implement if missing:** Adjust the vault firewall to allow the required networks / trusted services, or add a private endpoint (Implementation Step 1).

## 2.9 An inventory of current hardcoded secrets
**Description:** A list of where secrets are hardcoded today — flow actions, app formulas, custom connector definitions, plaintext environment variables, scripts.
**Why required:** You cannot remove what you have not found; the inventory scopes the remediation.
**How to verify:** Run `PPKV-Discovery.ps1` against **exported** flow/app/connector JSON to flag hardcoded-secret patterns; review manually.
**How to implement if missing:** Export the solution(s) / flows / apps and run the discovery scan; record each finding for remediation.

---
## Checklist
- [ ] Azure subscription + Key Vault `PP-Secrets – <Environment> – Vault`
- [ ] Vault on the **Azure RBAC** permission model — `PPKV-Validation.ps1`
- [ ] Power Platform service principal has `Key Vault Secrets User` — `PPKV-Validation.ps1`
- [ ] Power Platform environment with Dataverse
- [ ] Maker access + a solution to hold the Secret env var
- [ ] Licensing for the chosen pattern (premium if using the connector)
- [ ] Entra identity + read role for connector/Function pattern (if used)
- [ ] Network path to the vault open for the consumer
- [ ] Hardcoded-secret inventory captured — `PPKV-Discovery.ps1`
