# 3. Implementation Guide — Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)

Follow these steps **in order**, in the **Azure portal** (`https://portal.azure.com`) and **Microsoft Entra admin center** (`https://entra.microsoft.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Enable the managed identity → grant + admin-consent the least-privilege application permission → **scope it to one mailbox (product #4)** → build the recurrence Logic App (Graph read + paging + throttling + watermark + idempotent mark/move) → pilot → validate exactly-once → expand.
>
> **Verify-before-asserting:** Exact Graph permission names/scopes, throttling limits, delta-query behavior, Consumption-vs-Standard differences, and national-cloud endpoints all change — where this guide flags **"verify against current Microsoft documentation,"** confirm before relying on it.

## Naming (set once, reuse verbatim)
- Logic App (poller): `Mail Polling – Support Mailbox – Pilot`
- Managed identity (if user-assigned): `Mail Polling MI – Support Mailbox – Prod`
- Target mailbox: `supportmailbox@contoso.com`
- Idempotency folder (child of the mailbox): `Processed`
- Mail-scoped security group (for one-mailbox scoping, product #4): `Mail Polling Scoped – Support Mailbox – Prod`
- Application permission granted to the identity: **`Mail.Read`** *(verify least-privilege name against current Microsoft documentation)*
- Watermark store (Azure Storage table): `mailpollingwatermark`

## Step 1 — Create the Logic App and enable its managed identity
1. `portal.azure.com` → **Logic apps** → **Add**. Choose **Consumption** (simplest single-mailbox poller) or **Standard** (single-tenant, private networking) — **the trigger/identity/networking differences must be verified against current Microsoft documentation**; keep the choice consistent through this guide. Name it **`Mail Polling – Support Mailbox – Pilot`**. **Review + create.**
2. Open the Logic App → **Identity**.
   - **System-assigned** (default in this guide): set **Status** → **On** → **Save**. Copy the **Object (principal) ID** shown.
   - *Or* **User-assigned**: create/attach a user-assigned identity named **`Mail Polling MI – Support Mailbox – Prod`** and copy its **Object (principal) ID**.
3. Run `GRAPHPOLL-Discovery.ps1` to record the identity's object id, the target mailbox reachability, and the current backlog before any change.

## Step 2 — Grant the least-privilege application permission and admin-consent it
1. Decide the permission — start with **`Mail.Read`** (application). **Whether a narrower read scope suffices must be verified against current Microsoft documentation.**
2. Preview the assignment: `GRAPHPOLL-Set-AppRole.ps1 -ManagedIdentityObjectId '<object id>' -PermissionName 'Mail.Read'` — it **defaults to `-WhatIf`** and prints exactly what it would grant.
3. Apply it: re-run with **`-Execute`**. This assigns the Graph app role to the managed identity **and** effects admin consent for that app-role assignment (an app-role assignment is itself the tenant admin's grant).
4. Confirm with `GRAPHPOLL-Validate.ps1` — the app-role assignment must be present. In the portal you can also check Entra → **Enterprise applications** → the managed identity → **Permissions**.

## Step 3 — Scope the identity to the ONE target mailbox (concise; defer to product #4)
> An application `Mail.Read` grant reads **every** mailbox until scoped. Scoping to the single mailbox is **mandatory** — the security spine of this solution. **Full design and verification are in product #4** *"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online"*; the concise version:
1. Create the mail-enabled security group **`Mail Polling Scoped – Support Mailbox – Prod`** and add **only** `supportmailbox@contoso.com`.
2. Apply the scoping model — an **Application Access Policy** bound to that group, and/or the newer **Graph RBAC-for-Exchange** model. **Which model to use and its exact behavior must be verified against current Microsoft documentation (see product #4).**
3. Validate the scope: the identity can read `supportmailbox@contoso.com` and is **denied** any other mailbox. `GRAPHPOLL-Validate.ps1` confirms the target is reachable; product #4 covers the deny-other proof in depth.

## Step 4 — Provision the durable watermark store
1. Create (or reuse) an **Azure Storage account** and add a **table** named **`mailpollingwatermark`**. *(For **Standard** Logic Apps a stateful workflow variable is an alternative — availability differs; **verify against current Microsoft documentation**.)*
2. Grant the **same managed identity** the least-privilege data role to read/write that table (so the workflow persists the watermark with the same credential-free identity).
3. Seed one row: `partitionKey=supportmailbox@contoso.com`, `rowKey=watermark`, `value=<a start time, e.g. now in ISO 8601 UTC>`. This is the initial high-water mark; the first run processes only mail newer than it.

## Step 5 — Build the recurrence polling workflow
Open **`Mail Polling – Support Mailbox – Pilot`** → **Logic app designer** and build these actions in order:

1. **Recurrence** trigger — **Interval 5, Frequency Minute** (tune to the workload). No inbound endpoint is used.
2. **Read watermark** — action to read row `watermark` for `supportmailbox@contoso.com` from table **`mailpollingwatermark`**. Store it in a variable **`Watermark`**.
3. **HTTP — GET new messages (Graph, Managed identity):**
   - **Method:** GET.
   - **URI:** `https://graph.microsoft.com/v1.0/users/supportmailbox@contoso.com/mailFolders/Inbox/messages?$filter=receivedDateTime gt @{variables('Watermark')}&$orderby=receivedDateTime asc&$top=25`
     *(Use the national-cloud Graph host instead of `graph.microsoft.com` where applicable — verify.)*
   - **Authentication:** **Managed identity** → the Logic App's identity from Step 1 → **Audience** `https://graph.microsoft.com` *(national-cloud audience where applicable — verify)*. No secret is entered.
   - **Delta alternative:** to use delta instead of the timestamp watermark, GET `…/mailFolders/Inbox/messages/delta`, store the returned `@odata.deltaLink`, and call that stored link next run. **Delta `deltaLink` lifetime/expiry (`410 Gone` → full re-sync) and supported resources must be verified against current Microsoft documentation.**
4. **Handle throttling (429):** add a condition on the HTTP action's status — on **429**, read the **`Retry-After`** response header, **Delay** for that many seconds, then retry. On transient **5xx**, retry with **exponential backoff**. Configure the action's built-in **retry policy** as a backstop. **Do not hard-code a throttling limit — always honor the returned `Retry-After` (exact limits vary; verify against current Microsoft documentation).**
5. **Page through results (Until loop):** set an **Until** loop that runs while the response body contains **`@odata.nextLink`** — each iteration does an **HTTP GET** on the `@odata.nextLink` (same Managed identity auth) and appends the returned `value` array, until `@odata.nextLink` is absent. This drains a backlog fully instead of truncating it.
6. **For each message** (`value` array), in order:
   1. **Do the business action** — the customer's own processing (create a ticket, save an attachment, post to a queue). This is where the workflow does its real work.
   2. **Make it idempotent** — **PATCH** `…/users/supportmailbox@contoso.com/messages/{id}` with `{ "isRead": true }` **and/or** **POST** `…/messages/{id}/move` with `{ "destinationId": "Processed" }` to move it to the **`Processed`** folder. Marking/moving means a re-read never double-processes.
7. **Advance the watermark** — after the loop, set the watermark to the **newest `receivedDateTime`** processed (for delta: store the new `@odata.deltaLink`). **Write** it back to row `watermark` in table **`mailpollingwatermark`**. Also record the last processed message **`id`** to break same-timestamp ties on the next run.
8. **Save** the workflow.

## Step 6 — Pilot on the one mailbox
1. Send a few known test messages to `supportmailbox@contoso.com`.
2. **Run trigger** manually (or wait for the recurrence). Confirm each test message is processed and lands in **`Processed`** (or is marked read), and that the watermark row advanced.
3. Run `GRAPHPOLL-Report.ps1` to capture unread count, backlog, and the last-processed watermark.
4. Run `GRAPHPOLL-Test-Watermark.ps1` to inspect **two consecutive reads** and confirm **no overlap and no gap** (exactly-once). Complete the **Testing Guide** before expanding.

## Step 7 — Expand
1. Once exactly-once is proven on `supportmailbox@contoso.com`, roll the pattern to additional mailboxes — **each mailbox gets its own scoped access (product #4) and its own watermark row** (`partitionKey=<mailbox>`), so mailboxes never share a high-water mark.
2. Keep the same least-privilege identity model; re-validate each mailbox with `GRAPHPOLL-Validate.ps1` and track backlog with `GRAPHPOLL-Report.ps1`.
3. If a mailbox needs near-real-time processing and a public endpoint becomes available, consider moving it to the **event-driven webhook (product #2)** instead of polling.

---
### Order of operations
`Create Logic App + enable MI → grant + consent least-priv app permission → scope to one mailbox (product #4) → provision watermark store → build recurrence workflow (read watermark → Graph GET → handle 429 → page nextLink → process + mark/move → advance watermark) → pilot → validate exactly-once → expand`
