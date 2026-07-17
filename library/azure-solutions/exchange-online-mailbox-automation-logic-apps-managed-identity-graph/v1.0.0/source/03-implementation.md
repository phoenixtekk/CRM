# 3. Implementation Guide — Exchange Online Mailbox Automation with Logic Apps Managed Identity (Graph)

Follow these steps **in order**. Work in the **Azure portal** (`https://portal.azure.com`), the **Entra admin center** (`https://entra.microsoft.com`), and PowerShell (Microsoft.Graph / Exchange Online). Objects are named once below and reused **verbatim** in every later step, script, and test.

> **Model:** Enable the identity → grant the least-privilege application permission (app role) with admin consent → **scope the mailbox to exactly one** → build the Graph read → pilot. Do **not** trust any workflow logic until the out-of-scope read is proven to fail (Testing).
>
> **Portal navigation paths and Graph permission names below are current-at-writing — treat them as `verify-with-Microsoft`. Confirm each blade name and each permission name against current Microsoft documentation before you click/grant.**

## Naming (set once, reuse verbatim)
| Object | Name |
|---|---|
| Resource group | `rg-mailbox-automation-pilot` |
| Logic App (Consumption) | `la-mailbox-automation-pilot` |
| Managed identity (default) | **system-assigned** identity of `la-mailbox-automation-pilot` |
| Managed identity (alternative) | user-assigned `id-mailbox-automation-pilot` |
| Target mailbox | `automation-inbox@contoso.com` |
| Application permission (app role) | `Mail.Read` (Microsoft Graph, **application**) — *verify name* |
| Mail-enabled security group (App Access Policy scope) | `sg-MailboxAutomation-Scope-Pilot` |

## Step 1 — Enable the managed identity on the Logic App
1. `portal.azure.com` → **Logic apps** → open `la-mailbox-automation-pilot` (create it in `rg-mailbox-automation-pilot` first if it does not exist).
2. In the left menu → **Settings → Identity**. *(Verify the exact blade name against current portal navigation.)*
3. On the **System assigned** tab, set **Status** = **On** → **Save** → **Yes** to confirm.
4. Azure creates a **service principal** for the identity and shows its **Object (principal) ID**. **Record this Object ID** — the app-role grant (Step 2) and the scripts use it.
   - **User-assigned alternative:** instead create `id-mailbox-automation-pilot` (**Managed Identities** → **Create**), then on the Logic App's **Identity → User assigned** tab **Add** it. Record *its* Object ID. **Verify with Microsoft** how a Consumption vs Standard Logic App references a user-assigned identity in a workflow action.
5. Run `LAMIMAIL-Discovery.ps1` to confirm the identity and its service principal are visible.

## Step 2 — Grant the application Graph permission (app role) to the identity, with admin consent
The managed identity's service principal must hold the **application** permission `Mail.Read` (Microsoft Graph). Application permissions are granted as **app-role assignments** on the service principal and require **admin consent**. There is no interactive consent screen for a managed identity, so the assignment is made directly (portal Enterprise Applications, or the included helper script).

1. **Option A — helper script (recommended, auditable):** run `LAMIMAIL-Set-AppRole.ps1` to assign the `Mail.Read` app role to the identity's service principal. **It defaults to `-WhatIf`** and only previews the change; re-run with `-Execute` to apply. The script requires a role able to grant application permissions (Global Administrator / Privileged Role Administrator).
2. **Option B — portal:** `entra.microsoft.com` → **Identity → Applications → Enterprise applications** → set the filter to include **Managed Identities** → open the service principal for `la-mailbox-automation-pilot` (or `id-mailbox-automation-pilot`) → **Permissions** → grant the Microsoft Graph **application** permission `Mail.Read` and **Grant admin consent**. *(Verify the exact blade path and the permission name against current Microsoft documentation — Enterprise Applications navigation and Graph permission names change.)*
3. **Confirm consent:** re-open the service principal's **Permissions** — `Mail.Read` (application) shows as **granted**. Run `LAMIMAIL-Report.ps1` to export the app-role grants on the identity.

> **Do not stop here.** At this point the identity can read **every mailbox in the tenant** — an application `Mail.Read` grant is tenant-wide by default. Step 3 is mandatory.

## Step 3 — Scope the mailbox access to exactly one mailbox (concise; deep walkthrough deferred)
Restrict the application permission so the identity can read **only** `automation-inbox@contoso.com`. Choose one control:

**Option A — Application Access Policy (mail-enabled security group):**
1. Create a **mail-enabled security group** `sg-MailboxAutomation-Scope-Pilot` and add **only** `automation-inbox@contoso.com` as a member.
2. In Exchange Online PowerShell, create an **application access policy** that restricts the app (identified by the managed identity's **application/client ID**) to members of `sg-MailboxAutomation-Scope-Pilot`, with **AccessRight = RestrictAccess**.
3. **Test the policy** for both an in-scope and an out-of-scope mailbox — it must allow the first and deny the second.

**Option B — Graph RBAC for Exchange Online (newer model):**
- Assign an Exchange mail-read role to the app, scoped to a management scope that resolves to only `automation-inbox@contoso.com`.

**Verify with Microsoft — this is important:** **which control to use (Application Access Policy vs Graph RBAC-for-Exchange), the exact cmdlet names, parameters, and how long the scope takes to take effect are version- and tenant-dependent.** Confirm against current Microsoft documentation before you run them.

> **For the full click-by-click scoping walkthrough** — both controls compared, exact cmdlets, edge cases, and how to prove the boundary — **use the dedicated sibling product: *"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online."*** This step is intentionally the summary needed to finish the build; do not treat it as the complete scoping design.

4. Run `LAMIMAIL-Test-MailboxAccess.ps1` — it must show the **in-scope** mailbox readable and an **out-of-scope** mailbox **denied**. Do not proceed until it does.

## Step 4 — Build the Graph-based read in the Logic App (managed identity auth)
Replace the Office 365 Outlook connector with an explicit Graph call authenticated by the managed identity.

1. Open `la-mailbox-automation-pilot` → **Logic app designer**.
2. Add an **HTTP** action to call Microsoft Graph, for example read messages from the target mailbox:
   - **Method:** `GET`
   - **URI:** `https://graph.microsoft.com/v1.0/users/automation-inbox@contoso.com/messages?$top=10&$select=id,subject,receivedDateTime,from`
   - *(Verify the exact Graph endpoint/path and query options against current Microsoft Graph documentation.)*
3. Under the HTTP action's **Authentication**, choose **Managed identity**:
   - **Managed identity:** **System-assigned** (or select `id-mailbox-automation-pilot` for the user-assigned alternative).
   - **Audience / Resource:** `https://graph.microsoft.com` — the token audience must be Graph. *(Verify the audience value against current Microsoft documentation; a wrong audience is the classic token/audience failure.)*
4. **Save.** For the very first proof you can use a **Recurrence** trigger (e.g. every hour) so the workflow runs and reads the mailbox — this is only to prove auth + scope end to end. **The production trigger pattern (webhook vs polling) is chosen next.**
5. **Do not build the connector's *"When a new email arrives"* trigger** — it authenticates as a user/service account via a stored OAuth connection and cannot bind to the managed identity (the root cause this solution fixes).

## Step 5 — Choose the trigger pattern and go deep with the matching sibling
The foundation (identity + app role + one-mailbox scope + a working Graph read) is now in place. Choose how the workflow learns there is new mail:
- **Event-driven / near-real-time** → build **Graph change-notification subscriptions**. **Follow the sibling product *"Event-Driven Mail Processing with Microsoft Graph Change Notifications (Logic Apps + Managed Identity)"*** for subscription creation, the validation handshake, and the renewal loop. **Verify subscription lifetime and renewal cadence against current Microsoft documentation.**
- **Polling / simplest** → build a **recurrence + query** loop with a processed-message watermark. **Follow the sibling product *"Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)."***

## Step 6 — Pilot and validate
1. Run `LAMIMAIL-Validate.ps1` → confirms the identity exists, holds **only** the least-privilege `Mail.Read` app role, the mailbox is in scope, and the workflow is present. Expect **PASS**.
2. Run `LAMIMAIL-Test-MailboxAccess.ps1` → in-scope read succeeds, out-of-scope read denied.
3. Send a test message to `automation-inbox@contoso.com` and confirm a workflow run reads it (Testing Guide).
4. **Rollback if needed:** remove the app-role assignment (`LAMIMAIL-Set-AppRole.ps1` supports removal preview) and remove the scope binding; the Logic App and mailbox are otherwise unaffected.

---
### Order of operations
`Enable managed identity → grant Mail.Read app role (+ admin consent) → scope to one mailbox (defer deep steps to #4) → build the Graph read with managed-identity auth → choose webhook (#2) or polling (#3) → pilot & validate (in-scope passes, out-of-scope denied)`
