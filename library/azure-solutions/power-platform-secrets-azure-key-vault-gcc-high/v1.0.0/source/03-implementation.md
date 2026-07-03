# Implementation Guide — Standardize Power Platform Secrets in Azure Key Vault (Government / GCC High)

This is the ordered, click-to-implement procedure for a novice admin, using the **GCC High** portals throughout. GCC-High-only caveats appear inline at the step where they matter. Follow the phases in order and honor each gate.

> **Sovereign portals used here:**
> Azure Government portal — `https://portal.azure.us`
> Power Platform admin center (GCC High) — `https://high.admin.powerplatform.microsoft.us`
> Power Apps maker (GCC High) — `https://make.high.powerapps.us`
> Copilot Studio — `https://copilotstudio.microsoft.com` (sign in with your GCC High identity)
> Entra sign-in endpoint — `https://login.microsoftonline.us`

> **Objects you will create and reuse (names):**
> Vault `PowerPlatform Secrets – <EnvName> – Prod` · Group `Key Vault Secrets – Makers – <EnvName>` · Environment variable `Secret – <SystemName> – <EnvName>`.

---

## Phase 0 — Assess (read-only)

**0.1 Confirm you are in the right cloud.** Open `https://portal.azure.us` and sign in. In the top-right account pill, confirm the directory is your **GCC High / Entra Government** tenant. If your bookmark went to `portal.azure.com`, stop — that is Commercial and will not show your Gov resources.

**0.2 Run discovery.** From an admin workstation:

```powershell
powershell -ExecutionPolicy Bypass -File .\PPKVG-Discovery.ps1
# prompts a Gov sign-in (Connect-AzAccount -Environment AzureUSGovernment)
```

Review the CSV: existing vaults, their permission model, secret **names** (never values), and Key Vault Secrets User assignments. Note where Power Platform secrets currently live in plaintext (flow steps, connection references, config tables) — these are your migration backlog.

**Gate 0 → 1:** Requirements R1–R2 and R7 met; a clean discovery report exists.

---

## Phase 1 — Configure

### 1.1 Register the `Microsoft.PowerPlatform` resource provider

1. `https://portal.azure.us` → search **Subscriptions** → select the subscription that will hold the vault.
2. Left nav → **Settings → Resource providers**.
3. Search `Microsoft.PowerPlatform`. If **Status** is not **Registered**, select it → **Register**. Wait until it shows **Registered** (refresh).

*(Or run `PPKVG-Remediation.ps1` in preview, then `-Apply`.)*

### 1.2 Create the Key Vault (one per environment)

1. `https://portal.azure.us` → **Create a resource** → search **Key Vault** → **Create**.
2. **Basics:** choose the subscription and resource group; **Name** = `PowerPlatform Secrets – <EnvName> – Prod` (or your naming standard — vault names have character limits, so use a compliant short form and record the mapping); **Region** = a **US Gov** region (US Gov Virginia or US Gov Texas). **Do not** include ITAR/export-controlled data in the resource name.
3. **Access configuration** tab → **Permission model** → select **Azure role-based access control**. *(This is the recommended model; Power Platform evaluates access via RBAC regardless.)*
4. **Networking** tab → for the pilot you may leave **Public access** enabled; you will lock this down in 1.5. **Review + create → Create.**
5. Confirm the vault's data-plane DNS is the sovereign suffix — the vault URI ends in **`.vault.usgovcloudapi.net`** (not `.vault.azure.net`). If you see `.vault.azure.net`, you created it in Commercial by mistake.

### 1.3 Create the makers group and grant Key Vault Secrets User

1. Create (or reuse) an Entra Government security group `Key Vault Secrets – Makers – <EnvName>` and add the makers/operators who will create or use the environment variable.
2. In the vault → **Access control (IAM)** → **Add → Add role assignment**.
3. **Role** tab → select **Key Vault Secrets User** → **Next**.
4. **Members** → **Select members** → pick the makers group → **Review + assign**.

### 1.4 Grant Key Vault Secrets User to the Dataverse principal

> **GCC High caveat — verify for GCC High.** In Commercial the Dataverse first-party app is `00000007-0000-0000-c000-000000000000`. In GCC High the first-party principal that Dataverse uses may appear under a different display name/object id. **Confirm the actual principal first.**

1. In a new tab open **Entra ID → Enterprise applications** (via `portal.azure.us`). Search for the Dataverse / Power Platform first-party application and note its **Object ID**. If you cannot positively identify it, treat this as **"verify for GCC High"** and confirm with Microsoft support / your AOS-G partner before proceeding.
2. Back in the vault → **Access control (IAM) → Add → Add role assignment**.
3. **Role** = **Key Vault Secrets User** → **Next**.
4. **Members** → **Assign access to = User, group, or service principal** → **Select members** → choose the confirmed Dataverse principal → **Review + assign**.
5. If multiple Dataverse service principals exist in the tenant, assign them all, then review each and remove any whose Application ID is not the legitimate Dataverse identity you confirmed in step 1.

*(`PPKVG-Remediation.ps1` automates 1.1, 1.2 RBAC switch, and 1.3/1.4 — but it will REVIEW-flag the Dataverse principal if it cannot resolve the id, exactly because of this caveat.)*

### 1.5 Lock down the vault network (US Gov IP ranges)

If you will enforce the Key Vault firewall:

1. Vault → **Networking → Firewalls and virtual networks** → **Enabled from selected networks**.
2. Under **Firewall**, add the **Power Platform US Government IP ranges** (from *Power Platform URLs and IP address ranges* — use the **US Gov** set, focusing on `AzureCloud.usgovvirginia` / `AzureCloud.usgovtexas`). **Power Platform is not covered by "Allow trusted Microsoft services,"** so you must add its IPs explicitly.
3. For a no-public-internet posture, instead configure **VNet support for Power Platform + Private Link**: disable public access, create a private endpoint on the Power-Platform-delegated subnet, and validate connectivity. (See Microsoft: *Set up Virtual Network support for Power Platform*.)

**Gate 1 → 2:** Run `PPKVG-Validation.ps1` against the pilot vault — every required control **PASS** (provider registered, RBAC model, Key Vault Secrets User present, network reachable).

---

## Phase 2 — Pilot (one environment, one secret)

### 2.1 Add the secret to the vault (value stays in Key Vault)

1. `https://portal.azure.us` → the vault → **Objects → Secrets → + Generate/Import**.
2. **Name** = `Secret – <SystemName> – <EnvName>`; **Value** = the secret; optionally set an **Expiration date** (recommended). **Create.**

> The scripts in this solution never read this value. Only a human, in the portal, sets it.

### 2.2 Create the environment-variable secret in Power Platform

1. `https://make.high.powerapps.us` → confirm the correct **environment** (top-right environment picker) = your pilot environment.
2. **Solutions** → open (or create) an **unmanaged** solution for development.
3. **New → More → Environment variable**.
4. **Display name** = `Secret – <SystemName> – <EnvName>`; add a description.
5. **Data type = Secret**; **Secret Store = Azure Key Vault**.
6. Select **New Azure Key Vault value reference** and enter:
   - **Azure Subscription ID** — the Gov subscription id (vault **Overview** page).
   - **Resource Group Name** — the vault's resource group.
   - **Azure Key Vault Name** — the vault name.
   - **Secret Name** — `Secret – <SystemName> – <EnvName>`.
7. **Save.**

> If you get *"User isn't authorized to read secrets from 'Azure Key Vault path'"*, the signed-in maker is missing **Key Vault Secrets User** on that vault (R5). Fix the role, then re-save.

### 2.3 Consume the secret from a test cloud flow

1. In the same solution → **New → Automation → Cloud flow → Instant** → trigger **Manually trigger a flow** → **Create**.
2. **New step → Microsoft Dataverse → Perform an unbound action**.
3. **Action name** = **RetrieveEnvironmentVariableSecretValue**. Provide the environment variable's **unique (schema) name** (not the display name).
4. Rename the step (e.g. **GetSecret**). Open **… → Settings** and enable **Secure Outputs** so the value never lands in run history.
5. Add an **HTTP** step (or your real consumer) that uses the secret — bind the value from `body('GetSecret')?['EnvironmentVariableSecretValue']`. On the HTTP step, **… → Settings**, enable **Secure Inputs** and **Secure Outputs**.
6. **Save**, then **Run** manually.

**Gate 2 → 3:** The flow runs successfully and the secret resolves; the value does **not** appear anywhere in run history (secure in/out confirmed).

---

## Phase 3 — Validate

1. **Access control:** `PPKVG-Validation.ps1` → all required controls PASS; Dataverse principal confirmed for GCC High.
2. **Network:** with the firewall enabled (1.5), the pilot flow still resolves the secret (proves the US Gov IP allowance / Private Link works).
3. **Rotation:** in the portal, add a **new version** of the secret; confirm the flow picks up the new value without editing the environment variable (reference is version-agnostic to current).
4. **Governance report:** `PPKVG-Report.ps1` → review Findings (no missing-expiry, no access-policy vaults).

### 3a. Copilot Studio consumer (only if in scope)

Copilot Studio needs two extra things beyond a flow:

1. Grant **Key Vault Secrets User** to the **Microsoft Copilot Studio Service** principal on the vault (IAM → Add role assignment) — **verify for GCC High** that this principal resolves in your Gov tenant.
2. Scope the secret with a **tag**: either `AllowedBots = {envId}/{schemaName}` (specific agents) or `AllowedEnvironments = {environmentId}` (all agents in an environment). Build/apply the tag with:

```powershell
# preview first
powershell -ExecutionPolicy Bypass -File .\PPKVG-Set-ScopeTargeting.ps1 -AllowedEnvironments 'your-environment-id'
# then apply
powershell -ExecutionPolicy Bypass -File .\PPKVG-Set-ScopeTargeting.ps1 -AllowedEnvironments 'your-environment-id' -Apply
```

Test the agent topic; if it errors with an `AllowedBots` message, the error text gives you the exact `{envId}/{schemaName}` value to tag.

**Gate 3 → 4:** All pass/fail gates in `05-testing.md` pass.

---

## Phase 4 — Expand

1. Repeat Phase 1–3 **per Power Platform environment** — one vault each (`PowerPlatform Secrets – <EnvName> – Prod`).
2. Work the migration backlog from Phase 0: for each plaintext secret, create the vault secret + environment variable, repoint the consumer, then remove the plaintext copy.
3. Standardize expiry/rotation and run `PPKVG-Report.ps1` on a schedule; hand off the runbooks in `ADMIN_DOCS` and the troubleshooting guide.

**Exit:** Governance report clean across environments; operators trained; no plaintext secrets remain in flows/connectors.
