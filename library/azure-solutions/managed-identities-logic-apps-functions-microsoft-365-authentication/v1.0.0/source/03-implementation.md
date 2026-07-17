# 3. Implementation Guide — Managed Identities for Azure Logic Apps & Functions

Follow these steps **in order**, in the **Azure portal** (`https://portal.azure.com`) and the **Entra admin center** (`https://entra.microsoft.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test. Contoso is the sample tenant throughout (`contoso.com`).

> **Model:** Enable a managed identity → grant least-privilege application permissions with admin consent → wire a **Logic App** to call Graph with the identity → wire an **Azure Function** to call Graph with the identity → validate → migrate secret-based flows and retire the credentials. Pilot on one workflow first; keep a rollback for every cutover.
>
> Everything version/feature/licensing-specific — exact Graph permission names, whether a given connector action supports managed identity, Consumption-vs-Standard behaviour, national-cloud endpoints, and Azure SDK class/method names — is flagged **_verify against current Microsoft documentation_**. Do not treat those as asserted fact.

## Naming (set once, reuse verbatim)
- Shared user-assigned managed identity: `Graph Automation Identity – Contoso – Prod`
- Pilot Logic App: `Graph Automation LogicApp – Contoso – Pilot`
- Pilot Function App: `Graph Automation FuncApp – Contoso – Pilot`
- App-role assignment record (informal label for the grant): `Mail.Read App Grant – Graph Automation Identity – Prod`

> **Choosing the identity kind (decide before Step 1):** use a **system-assigned** identity for a single, self-contained workflow whose identity should live and die with it; use the **shared user-assigned** identity `Graph Automation Identity – Contoso – Prod` when several Logic Apps/Functions should share one identity and one set of grants. This guide shows **both**.

## Step 1 — Enable a managed identity on the compute

### Option A — System-assigned (per resource)
1. `portal.azure.com` → open the Logic App `Graph Automation LogicApp – Contoso – Pilot` (or the Function App).
2. Left menu → **Identity** → **System assigned** tab → set **Status = On** → **Save** → **Yes**.
3. Azure creates a service principal for the resource. Note the **Object (principal) ID** shown — you will grant the app-role to this ID.

### Option B — User-assigned (shared across many workflows) — recommended for an estate
1. `portal.azure.com` → **Managed Identities** → **Create**. Subscription/Resource group as required; **Name:** `Graph Automation Identity – Contoso – Prod` → **Review + create** → **Create**.
2. Open the Logic App `Graph Automation LogicApp – Contoso – Pilot` → **Identity** → **User assigned** tab → **Add** → select `Graph Automation Identity – Contoso – Prod` → **Add**.
3. Repeat 2 for the Function App `Graph Automation FuncApp – Contoso – Pilot` and any other workflow that will share the identity.
4. On the managed identity's **Overview**, note its **Object (principal) ID** and **Client ID** — you will need the **Object ID** to grant the app-role and the **Client ID** in Function code that targets a specific user-assigned identity.

Run `MIM365-Discovery.ps1` to confirm which Logic Apps/Functions now have an identity and which app-roles (if any) are already assigned.

## Step 2 — Grant least-privilege application Graph permissions with admin consent
Grant **only** the one application permission the task needs (least privilege). This example uses **`Mail.Read`**; substitute the exact permission your Graph call requires. *Verify the exact application permission name/scope for your call against current Microsoft documentation.*

1. Identify the managed identity's **service principal Object ID** from Step 1 (system-assigned: the resource's principal ID; user-assigned: the identity's Object ID).
2. Assign the **application** app-role to that principal and grant admin consent. The repeatable way is the helper script — **preview first**, then execute:
   ```powershell
   # Preview (default -WhatIf): shows the grant, changes nothing
   .\MIM365-Set-AppRole.ps1 -ManagedIdentityObjectId '<identity object id>' -GraphAppRole 'Mail.Read'
   # Apply for real (explicit):
   .\MIM365-Set-AppRole.ps1 -ManagedIdentityObjectId '<identity object id>' -GraphAppRole 'Mail.Read' -Execute
   ```
   The script resolves the Microsoft Graph service principal, finds the named **application** app-role, and creates the app-role assignment to the managed identity — the equivalent of granting the application permission and consenting to it for that identity.
3. Record the grant as `Mail.Read App Grant – Graph Automation Identity – Prod`. **Grant nothing else** — no extra "just in case" permissions.
4. **Scope mailbox permissions before production.** `Mail.Read` as granted is **tenant-wide** (every mailbox). Restrict it to the specific mailbox(es) the workflow needs using the companion product **#4 "Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online."** Do not consider a mailbox grant production-ready until it is scoped per #4. *(This guide does not reproduce #4's scoping steps.)*

Run `MIM365-Validate.ps1` to confirm the identity holds the intended least-privilege app-role and nothing broader.

## Step 3 — Wire a Logic App to call Graph with the managed identity (no connector, no secret)
1. Open `Graph Automation LogicApp – Contoso – Pilot` → the workflow designer.
2. Add an **HTTP** action for the Graph call — e.g. **Method** `GET`, **URI** `https://graph.microsoft.com/v1.0/users/adele@contoso.com/messages?$top=5`. *Verify the Graph endpoint/host for your cloud against current Microsoft documentation (commercial vs national cloud differ).*
3. Expand **Add new parameter → Authentication** → **Authentication type = Managed identity**.
4. **Managed identity:** choose **System-assigned managed identity**, or the user-assigned `Graph Automation Identity – Contoso – Prod`.
5. **Audience:** `https://graph.microsoft.com` — the resource the token is requested for. *Verify the audience/resource URI for your cloud against current Microsoft documentation.*
6. **Save.** No connector, no client secret, and no stored connection is created — the action asks Azure for a token for the identity at run time.
7. **Run** the workflow (or trigger it) and confirm the HTTP action returns **200** with the expected Graph payload.

> If a step in an existing workflow uses the **Office 365 Outlook connector**, note that not every connector action supports managed-identity auth — the robust pattern is the **direct Graph HTTP call** shown here. *Verify which connector operations support managed identity against current Microsoft documentation.* The mailbox-specific siblings (#1 replace-the-connector, #2 change-notifications, #3 polling) show these Graph mail calls end-to-end.

## Step 4 — Wire an Azure Function to call Graph with the managed identity (code)
The Function acquires a token for the managed identity in code with **`DefaultAzureCredential`** (which resolves to the managed identity when running in Azure) or **`ManagedIdentityCredential`**, then calls Graph. Minimal, correct-shaped C# example — *verify the exact Azure SDK package names, class names, and method signatures against current Microsoft documentation, as they change between SDK versions:*

```csharp
using Azure.Identity;              // Azure.Identity package — verify current version
using Microsoft.Graph;            // Microsoft.Graph SDK — verify current version/namespaces

// DefaultAzureCredential resolves to the Function's managed identity when running in Azure.
// For a SPECIFIC user-assigned identity, pass its Client ID so the right identity is used:
var credential = new DefaultAzureCredential(
    new DefaultAzureCredentialOptions
    {
        ManagedIdentityClientId = "<user-assigned identity Client ID>"  // omit for system-assigned
    });

// The Graph client uses the managed-identity token automatically. Scope/host differ by cloud —
// verify "https://graph.microsoft.com/.default" and the Graph base URL for your cloud.
var graph = new GraphServiceClient(credential,
    new[] { "https://graph.microsoft.com/.default" });

// Example least-privilege call (requires the Mail.Read app-role granted in Step 2):
var messages = await graph.Users["adele@contoso.com"].Messages
    .GetAsync(cfg => cfg.QueryParameters.Top = 5);
```

1. In the Function App `Graph Automation FuncApp – Contoso – Pilot`, ensure the managed identity from Step 1 is enabled/attached.
2. Add the Azure Identity and Microsoft Graph SDK packages to the project. *Verify the current package names/versions against current Microsoft documentation.*
3. Use the code shape above: build the credential, build the Graph client, make the least-privilege call. For a **user-assigned** identity, set `ManagedIdentityClientId` to its **Client ID**; for **system-assigned**, omit it.
4. Deploy and invoke the Function; confirm it returns the expected Graph result **without any secret in app settings or code**.

> The same pattern applies in other languages via that language's Azure Identity library (`ManagedIdentityCredential` / `DefaultAzureCredential`). *Verify the library and API names for your language against current Microsoft documentation.*

## Step 5 — Validate least-privilege and the token flow
1. Run `MIM365-Validate.ps1` → confirms the target compute has a managed identity, holds the intended least-privilege app-role (e.g. `Mail.Read`) and **nothing broader**, and has **no leftover secret-based connection**.
2. Confirm the Logic App HTTP action (Step 3) and the Function (Step 4) both return **200 / expected data** with no stored credential.
3. Run `MIM365-Report.ps1` to capture the identity/permission inventory as the pre-migration baseline.

## Step 6 — Migrate secret-based flows onto the identity and retire the credentials
1. Run `MIM365-Find-StoredCredentials.ps1` to produce the **migration worklist** — the Logic Apps/Functions still using stored service-account connections or client secrets.
2. For each item, on a pilot-first basis: enable the managed identity (Step 1), grant the same least-privilege permission (Step 2), re-point the workflow's Graph call to managed-identity auth (Step 3 / Step 4), and validate parity (Step 5) — the migrated flow must do exactly what the secret-based flow did.
3. Once parity is confirmed and the change window is approved, **remove the stored credential** — delete the saved connector connection and delete the client secret / service-account app setting. **Rollback:** if the migrated flow misbehaves, re-enable the previous connection until fixed.
4. Re-run `MIM365-Find-StoredCredentials.ps1` — the migrated workflow should no longer appear. Repeat until the worklist is empty.

## Step 7 — Expand across the estate
1. Attach the shared `Graph Automation Identity – Contoso – Prod` to the remaining workflows that need the same permission (they inherit the existing grant — nothing new to consent).
2. For workflows needing a **different** permission, grant that one least-privilege app-role (Step 2) — scoping mailbox permissions per #4.
3. Re-validate each with `MIM365-Validate.ps1` and track the estate with `MIM365-Report.ps1` each cycle; drive the stored-credential worklist to zero with `MIM365-Find-StoredCredentials.ps1`.

---
### Order of operations
`Enable identity (system/user-assigned) → grant least-privilege app-role + consent → Logic App calls Graph with the identity → Function calls Graph with the identity → validate least-privilege + token flow → migrate secret flows and retire credentials → expand`
