# 3. Implementation Guide — Event-Driven Mail Processing with Microsoft Graph Change Notifications

Follow these steps **in order**. Portal work is in the Azure portal (`https://portal.azure.com`), the Entra admin center (`https://entra.microsoft.com`), and the Exchange admin center (`https://admin.exchange.microsoft.com`). Objects are named per the convention and **reused verbatim** in every later step, script, and test.

> **Model:** Enable the managed identity → grant the least-privilege application permission (admin consent) → scope to the one mailbox → build the receiver with the validation handshake and clientState check → create the subscription → build the renewal + catch-up workflow → pilot, validate, expand. Keep a rollback (delete the subscription; the mailbox is untouched).

## Naming (set once, reuse verbatim)
- Resource group: `rg-mailevents-pilot`
- Logic App (Standard or Consumption — verify plan choice): `logic-mailevents-receiver-pilot`
- Receiver workflow: `wf-NotificationReceiver`
- Renewal / catch-up workflow: `wf-SubscriptionRenewal`
- Key Vault: `kv-mailevents-pilot`
- `clientState` secret: `MailEvents-ClientState`
- Target mailbox: `svc-mailevents@contoso.com`
- Mail-enabled security group (scoping): `MailEvents – Scope – Pilot`
- Application Access Policy: `MailEvents – AppAccess – Pilot`

---

## Step 1 — Enable the managed identity on the Logic App
1. `portal.azure.com` → create (or open) the resource group **`rg-mailevents-pilot`** and the Logic App **`logic-mailevents-receiver-pilot`**. *(Consumption vs Standard changes networking and pricing for an always-reachable HTTP endpoint — **verify against current Microsoft documentation** which plan fits before you create it.)*
2. Open **`logic-mailevents-receiver-pilot`** → **Settings → Identity**.
3. On the **System assigned** tab, set **Status = On** → **Save** → **Yes**. *(Alternatively attach a user-assigned identity on the **User assigned** tab — either works; be consistent.)*
4. Copy the **Object (principal) ID** that appears — you grant the Graph permission to this in Step 2. Run `GRAPHSUB-Discovery.ps1` to confirm the identity is present.

## Step 2 — Grant the least-privilege application permission + admin consent
The managed identity's service principal must hold an **application** Graph permission to read the changed message. You grant an app role to the identity's service principal and consent to it. **The exact permission name and any narrower mail-read scope are version-specific — verify against current Microsoft documentation; grant the least permission that lets the workflow read a message (for example `Mail.Read`), never a write scope.**

1. Note the **Graph service principal AppId** `00000003-0000-0000-c000-000000000000` (Microsoft Graph) — the app roles you assign come from it.
2. Assign the app role to the managed identity's service principal. This is most reliably done with Graph PowerShell (the portal cannot always assign app roles to a managed identity). Using the values you recorded in Step 1:
   ```powershell
   Connect-MgGraph -Scopes 'AppRoleAssignment.ReadWrite.All','Application.Read.All'
   $graph = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
   $mi    = Get-MgServicePrincipal -ServicePrincipalId '<managed-identity-object-id>'
   $role  = $graph.AppRoles | Where-Object { $_.Value -eq 'Mail.Read' -and $_.AllowedMemberTypes -contains 'Application' }
   New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $mi.Id `
       -PrincipalId $mi.Id -ResourceId $graph.Id -AppRoleId $role.Id
   ```
   *(Assigning the app role **is** the admin consent for an application permission granted this way — it requires an admin to run it. Verify the role `Value` string against current Microsoft documentation before assigning.)*
3. Confirm with **Entra → Enterprise applications → `logic-mailevents-receiver-pilot` → Permissions**, or run `GRAPHSUB-Validate.ps1`.

## Step 3 — Scope mailbox access to the one target mailbox (concise — defer depth to product #4)
A bare application `Mail.Read` can read **every** mailbox. Restrict it to `svc-mailevents@contoso.com` before going further. **This is deliberately concise — for the full treatment (Application Access Policy vs the newer Graph RBAC for Exchange Online, edge cases, and validation), use product #4 "Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online." Which model is current is version-specific — verify against current Microsoft documentation.**

Using the classic **Application Access Policy** model:
1. In **Exchange Online PowerShell** (`Connect-ExchangeOnline`), create the mail-enabled security group **`MailEvents – Scope – Pilot`** and add **only** `svc-mailevents@contoso.com` as a member.
2. Create the access policy **`MailEvents – AppAccess – Pilot`** binding the managed identity's **AppId** to that group so the app can access **only** members of the group:
   ```powershell
   New-ApplicationAccessPolicy -AppId '<managed-identity-app-id>' `
       -PolicyScopeGroupId 'MailEvents-Scope-Pilot@contoso.com' `
       -AccessRight RestrictAccess `
       -Description 'MailEvents – AppAccess – Pilot'
   ```
3. Validate scoping:
   ```powershell
   Test-ApplicationAccessPolicy -AppId '<managed-identity-app-id>' -Identity svc-mailevents@contoso.com   # Granted
   Test-ApplicationAccessPolicy -AppId '<managed-identity-app-id>' -Identity someone-else@contoso.com     # Denied
   ```
   *(Access-policy changes can take time to propagate — allow for it. See product #4.)*

## Step 4 — Store the clientState secret
1. `portal.azure.com` → **`kv-mailevents-pilot`** → **Secrets → Generate/Import** → name **`MailEvents-ClientState`**, value = a long random string (for example a GUID plus random bytes). This is the shared secret the subscription sets and the receiver checks.
2. **Access control (IAM)** on the vault → grant the Logic App's managed identity **Key Vault Secrets User** (or add an access policy with **Get** on secrets), so `wf-NotificationReceiver` can read the secret at runtime.

## Step 5 — Build the receiver workflow (`wf-NotificationReceiver`)
This workflow must do three things, in this order: **(1) answer Graph's validation handshake, (2) verify `clientState`, (3) process notifications idempotently.**

1. In **`logic-mailevents-receiver-pilot`**, create a workflow named **`wf-NotificationReceiver`** with a **"When an HTTP request is received"** trigger. Save it once to generate the public **HTTP POST URL** — this is your **`notificationUrl`**. Copy it.
2. **Handle the validation handshake first.** Graph validates the endpoint by calling it with a `validationToken` query parameter and expects that exact token echoed back as `text/plain`, HTTP 200, within a few seconds. Add a **Condition** at the very top:
   - **If** the trigger query contains `validationToken` →
     - **Response** action: **Status Code** `200`, **Headers** `Content-Type: text/plain`, **Body** = the `validationToken` value (URL-decoded). Return immediately.
   *(The endpoint must answer the handshake within Graph's timeout — **verify the exact timeout against current Microsoft documentation**; keep this branch as the first thing the workflow does so it responds fast.)*
3. **Acknowledge fast, then process.** For a real notification (no `validationToken`), respond **202 Accepted** quickly so Graph considers delivery successful, then continue processing asynchronously. Graph retries on non-2xx, which is one source of duplicates — acknowledging promptly reduces needless retries.
4. **Verify `clientState`.** Read `MailEvents-ClientState` from `kv-mailevents-pilot` (via the managed identity) and compare it to the `clientState` field on each notification in the request body. **If it does not match, discard the notification and do not process it** (log and drop). This is what stops a forged POST to your public URL from driving the workflow.
5. **Read the changed message with the managed identity.** Each valid notification carries a `resource` reference and the changed item's id (by default **no message body**). For each notification, call Graph **authenticated as the managed identity**:
   - `GET https://graph.microsoft.com/v1.0/users/svc-mailevents@contoso.com/messages/{id}`
   - In a Consumption Logic App, use the **HTTP** action with **Authentication = Managed identity**, Audience `https://graph.microsoft.com`. In Standard, use the HTTP action or a Graph connector bound to the identity. *(Whether the notification's `resource` value can be used directly as the request path is version-specific — **verify against current Microsoft documentation**.)*
   - *(Optionally, Graph can deliver **encrypted resource data** in the notification so you skip the read — this requires supplying an encryption key and decrypting in the workflow; availability and the encryption contract are version-specific — **verify against current Microsoft documentation**.)*
6. **Make processing idempotent.** Before acting on a message, record and check its **message id** (and `changeKey`/internet message id) against a small dedup store (a table, a Key Vault-referenced list, or your downstream system's natural key). If you have already processed that id, **skip it**. This is mandatory — notifications are at-least-once and can arrive more than once. See Step 8 for the reliability details.
7. Save `wf-NotificationReceiver`.

## Step 6 — Create the change-notification subscription
Create the subscription **against the target mailbox**, pointing `notificationUrl` at the receiver from Step 5. **The maximum allowed `expirationDateTime`, the supported `resource` forms, and the supported `changeType` values are Graph-version-specific — verify against current Microsoft documentation; never hard-code a lifetime.**

1. Put the receiver URL and the same `clientState` value from Key Vault into the request. Create the subscription (as the app identity, or interactively with a scope that allows it):
   ```powershell
   $params = @{
     changeType         = 'created'
     notificationUrl    = '<wf-NotificationReceiver HTTP POST URL>'
     resource           = 'users/svc-mailevents@contoso.com/messages'
     expirationDateTime = (Get-Date).ToUniversalTime().AddMinutes(<within Graph max — verify>).ToString('o')
     clientState        = '<value of MailEvents-ClientState>'
   }
   New-MgSubscription -BodyParameter $params
   ```
2. **Graph immediately calls the validation handshake** on your endpoint (Step 5.2). If the endpoint echoes the token correctly, the subscription is created and returns an **id** and the accepted **expirationDateTime**. If not, creation fails — see Troubleshooting.
3. Record the returned **subscription id** and **expirationDateTime**. Run `GRAPHSUB-Report.ps1` to capture the subscription inventory.

## Step 7 — Build the renewal + catch-up workflow (`wf-SubscriptionRenewal`)
A subscription is **not permanent** — it must be renewed before `expirationDateTime` or notifications stop.

1. In **`logic-mailevents-receiver-pilot`**, create a workflow **`wf-SubscriptionRenewal`** with a **Recurrence** trigger. Set the interval **comfortably shorter than the subscription lifetime** so there is always margin to renew before expiry (for example, if the max lifetime is measured in a few days, renew at least daily). **The safe renewal cadence depends on the current max lifetime — verify against current Microsoft documentation.**
2. On each run, the workflow (authenticated as the managed identity):
   - **Lists the subscription(s)** for the mailbox and finds the one whose id you recorded.
   - **Extends it** by PATCHing a new `expirationDateTime` within the allowed window:
     ```powershell
     Update-MgSubscription -SubscriptionId '<id>' `
       -ExpirationDateTime (Get-Date).ToUniversalTime().AddMinutes(<within Graph max — verify>).ToString('o')
     ```
   - **Recreates the subscription** if it is already gone (expired/deleted) — falling through to `New-MgSubscription` with the same parameters as Step 6.
3. **Catch-up / missed-notification recovery.** In the same workflow (or a companion one), after ensuring the subscription is alive, **reconcile**: read messages in the mailbox **received since the last processed watermark** (a stored timestamp or last message id) via `GET /users/svc-mailevents@contoso.com/messages?$filter=receivedDateTime ge <watermark>` and process any not already in the dedup store. This closes the gap for anything that arrived while a subscription was lapsed or a notification was dropped. Advance the watermark after each successful reconcile.
4. **Lifecycle monitoring.** Enable Logic App run history / alerts on both workflows so a failed renewal or a run of receiver failures raises a signal. Optionally subscribe to Graph **lifecycle notifications** (reauthorization/subscription-removed events) if supported for this resource — **verify against current Microsoft documentation**.
5. Save `wf-SubscriptionRenewal`.

## Step 8 — Reliability: dedup, retry, dead-letter, exactly-once intent
1. **Dedup key.** Use the message **id** (plus `changeKey`/internet message id) as the idempotency key; check it in the dedup store before processing (Step 5.6).
2. **Retry.** Configure the downstream processing action's retry policy (exponential backoff) so a transient failure retries rather than dropping the message.
3. **Dead-letter.** Route messages that fail after all retries to a **dead-letter store** (a queue or table) with the message id and error, so nothing is silently lost and it can be reprocessed.
4. **Exactly-once *intent*.** True exactly-once is not guaranteed by the transport; you achieve *effective* exactly-once by combining **at-least-once delivery + idempotent processing + a durable dedup store**. Design downstream actions to be safe to repeat.

## Step 9 — Pilot, validate, expand
1. **Pilot** on `svc-mailevents@contoso.com` only. Run the full **Testing Guide** — validation handshake, a real new-message event, a forged-call rejection, a renewal, and a dedup test.
2. **Validate** with `GRAPHSUB-Validate.ps1` (identity + least-priv permission present, an active non-expired subscription on the mailbox, receiver reachable as far as Graph can be checked) and `GRAPHSUB-Report.ps1` (subscription inventory + CSV).
3. **Expand** — repeat the pattern for additional mailboxes by adding each to a scoped group and creating its own subscription (one subscription per mailbox resource). Keep one renewal workflow that iterates all monitored subscriptions.

---
### Order of operations
`Enable MI → grant least-priv app permission (consent) → scope to one mailbox (#4) → build receiver (handshake → clientState → idempotent read) → create subscription → build renewal + catch-up → reliability → pilot → validate → expand`
