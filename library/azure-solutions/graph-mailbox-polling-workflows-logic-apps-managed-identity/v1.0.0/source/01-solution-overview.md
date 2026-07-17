# 1. Solution Overview — Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)

## What this solution is
This solution builds a **scheduled Microsoft Graph mailbox-polling workflow** in **Azure Logic Apps** that reads new mail from an Exchange Online mailbox on a timer, authenticating with the Logic App's **managed identity** and an **application permission** — no service account, no stored password, and no reliance on the legacy Office 365 Outlook connector. Crucially, it polls the mailbox **properly**: it tracks a **high-water mark** so every message is processed **exactly once**, it honors Graph **throttling and paging** so a busy mailbox never breaks a run, and it **marks or moves** processed items so a re-run is safe.

It is the **polling alternative** named inside the parent solution *"Exchange Online Mailbox Automation with Logic Apps Managed Identity — Replacing the O365 Connector with Microsoft Graph"* (**product #1** — the parent; do not re-derive its connector-replacement rationale here). It is deliberately the fallback to the event-driven design in *"Event-Driven Mail Processing with Microsoft Graph Change Notifications (Logic Apps + Managed Identity)"* (**product #2**). For confining the managed identity so it can read **only the one target mailbox**, this guide points to *"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online"* (**product #4**) and does not reproduce its depth.

## When to poll vs. when to use a webhook
- **Prefer the event-driven webhook (product #2)** when the environment can expose a **public HTTPS endpoint** for Graph **change notifications**. It is lower-latency (near-real-time) and does less work — Graph pushes only the changes.
- **Use this polling design (product #3)** when a public inbound endpoint is **not available or not permitted** (locked-down networks, no reverse proxy/public listener, policy against inbound webhooks), or when the workload only needs periodic batch processing. Polling makes **outbound** calls to Graph on a schedule, so it needs no inbound endpoint at all.
- Both designs share the **same identity spine**: a managed identity holding a **least-privilege application permission (e.g. `Mail.Read`)** scoped to **one mailbox** (product #4). Exact permission names and whether a lighter read scope suffices — **verify against current Microsoft documentation**.

> The Office 365 Outlook connector **cannot authenticate with a managed identity** — whether any given Office 365 Outlook connector trigger/action supports managed identity is a moving target; **verify against current Microsoft documentation**. This solution therefore calls **Microsoft Graph** directly via the Logic App **HTTP** action with **Managed identity** authentication.

## How it works
1. A **recurrence trigger** fires the Logic App on a schedule (e.g. every 5 minutes) — no inbound endpoint required.
2. The workflow **reads the stored watermark** (the high-water mark from the previous run) from a durable store.
3. It calls **Microsoft Graph** for **new messages only** using the watermark, authenticated by the Logic App's **managed identity** (the `Authorization` header is issued by Azure for the `https://graph.microsoft.com` audience — no secret in the workflow). Two supported high-water-mark strategies (see below).
4. It **follows paging** (`@odata.nextLink`) until all new messages for this run are retrieved, and **honors throttling** — on HTTP **429** it reads **`Retry-After`** and backs off rather than hammering Graph.
5. For each message it does the **business action** (the customer's own processing — create a ticket, save an attachment, notify a queue), then makes the item **idempotent**: **mark-as-read** and/or **move to a `Processed` folder** so it is never handled twice.
6. It **advances and persists the watermark** to the durable store so the next run starts exactly where this one ended — messages are neither skipped nor double-processed across runs.

## Exactly-once: the two high-water-mark strategies
Choose one; the guide implements a watermark by default and documents delta as the alternative.

- **A) Watermark on `receivedDateTime` (default in this guide).** Persist the timestamp of the newest message processed. Each run queries `…/messages?$filter=receivedDateTime gt <watermark>&$orderby=receivedDateTime asc`, processes in order, then stores the newest `receivedDateTime`. **Tradeoffs:** simple, transparent, and store-agnostic; edge cases are **same-timestamp ties** (mitigate by also tracking the last processed message `id` and skipping it) and **clock/precision** granularity. Pair the watermark with **mark-as-read / move-to-`Processed`** so re-runs are idempotent even if the watermark write is interrupted.
- **B) Delta query (`/messages/delta` + `deltaLink`).** Graph returns a `@odata.deltaLink`; each run calls the stored `deltaLink` and Graph returns **only what changed** since last time, then hands back a fresh `deltaLink` to store. **Tradeoffs:** Graph tracks the change state for you (less filtering logic) but you must **persist and reuse the exact `deltaLink`**, handle its expiry/`410 Gone` (full re-sync), and understand that delta reflects **changes** (new, updated, deleted), not only arrivals. **Delta-query specifics — supported mailbox resources, `deltaLink` lifetime/expiry behavior, and paging semantics — must be verified against current Microsoft documentation** before relying on them; do not assume behavior.

Whichever strategy is chosen, the **mark/move step is the backstop**: because processed items are marked-as-read and/or moved out of the polled folder, a duplicated read (e.g. after a crash between "process" and "advance watermark") is caught and skipped — the workflow is idempotent by design.

## Throttling and paging (keep a busy mailbox from failing runs)
- **Paging:** Graph returns messages in pages with an **`@odata.nextLink`**. The workflow **loops** on `nextLink` (an Until loop) until it is absent, so a backlog is fully drained in one run rather than silently truncated.
- **Throttling:** Graph enforces **per-app / per-mailbox request limits**; when exceeded it returns **HTTP 429** with a **`Retry-After`** header. The workflow **reads `Retry-After` and waits** that long before retrying, and uses **exponential backoff** on transient **5xx**. **Exact Graph throttling thresholds and limits change over time and must be verified against current Microsoft documentation** — never hard-code an assumed number; always defer to the returned `Retry-After`.
- **Page size:** use a modest `$top` (e.g. 25–50) so each page is cheap and a single run stays well within its execution window.

## Benefits
- **No service account, no stored secret** — the managed identity is credentialless; nothing to rotate, leak, or have blocked by a password-expiry policy.
- **No public endpoint required** — pure outbound polling works in locked-down networks where a webhook (product #2) cannot.
- **Exactly-once processing** — the watermark plus idempotent mark/move means each message is handled once, even across restarts, throttling, and re-runs.
- **Throttle- and backlog-safe** — honoring `Retry-After` and following `@odata.nextLink` keeps a busy mailbox reliable.
- **Least-privilege** — one application permission (e.g. `Mail.Read`) scoped to **one mailbox** (product #4).

## Limitations (be honest with buyers)
- **Polling has latency** — mail is picked up on the recurrence interval, not instantly. If near-real-time matters and a public endpoint is available, use the **event-driven webhook (product #2)**.
- **Application permissions are tenant-wide unless scoped** — `Mail.Read` as an application permission grants access to **all mailboxes** until you constrain it to the one target mailbox; that scoping is **mandatory** and is covered in depth by **product #4** (Application Access Policy and/or the newer Graph RBAC-for-Exchange model — which to use, and their exact behavior, **verify against current Microsoft documentation**).
- **Logic Apps Consumption vs. Standard differ** — trigger types, managed-identity support, private-networking, and the natural watermark store differ between **Consumption** (multi-tenant) and **Standard** (single-tenant, App Service). Which capabilities each offers **must be verified against current Microsoft documentation**; this guide notes where the choice matters.
- **National clouds differ** — Graph and login endpoints are different in **GCC High / DoD** and other national clouds (e.g. `graph.microsoft.us`). Endpoint hosts and feature parity **must be verified against current Microsoft documentation**.
- Polling reduces missed mail; it does not replace the mailbox's own retention, journaling, or compliance controls.

## The standard deployment model
> **Enable the Logic App's managed identity → grant the least-privilege application permission and admin-consent it → scope the identity to the one target mailbox (product #4) → build the recurrence Logic App (Graph read + paging + throttling + watermark + idempotent mark/move) → pilot on one mailbox → validate exactly-once → expand.** The repeatable pattern is **Assess → Configure → Pilot → Validate → Expand**, with an explicit **exactly-once validation gate** (two consecutive runs process each message once) and a documented rollback.
