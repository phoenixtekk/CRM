# 1. Solution Overview — Event-Driven Mail Processing with Microsoft Graph Change Notifications

## What this solution is
This solution processes new mail in a target mailbox **the moment it arrives**, using a **Microsoft Graph change-notification (webhook) subscription** to drive an **Azure Logic App** — with **no polling timer** and **no Office 365 Outlook connector**. When a message lands in the monitored mailbox, Microsoft Graph sends an HTTP POST ("notification") to the Logic App's public HTTPS endpoint; the Logic App validates the call, then reads the changed message from Graph and runs whatever processing you need (parse, route, ticket, store).

Authentication uses the Logic App's **managed identity** holding a least-privilege **application** Graph permission (for example `Mail.Read`), and mailbox access is **scoped to the one target mailbox**. There is **no service account, no stored password, and no client secret** anywhere in the workflow.

This is the **event-driven** member of a family of related products. It is the pattern named as the "push" alternative in the parent product **"Exchange Online Mailbox Automation with Logic Apps Managed Identity — Replacing the O365 Connector with Microsoft Graph"** (product #1, the root-cause explanation of *why* the O365 connector is being retired for Graph + managed identity). Where a public HTTPS endpoint that Graph can reach is not available, use the **polling** alternative instead — **"Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)"** (product #3). For the deep treatment of **restricting an application permission to a single mailbox**, use **"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online"** (product #4); this guide performs the scoping concisely and defers the depth there.

## Why event-driven (and why not the O365 connector or a poll)
- **The Office 365 Outlook connector cannot use a managed identity.** It authenticates with a delegated user connection (a service mailbox sign-in / API connection), which means a stored credential and an interactive consent that expires — exactly the dependency this family removes. *(Whether any specific connector trigger has since gained a managed-identity option is version-specific — **verify against current Microsoft documentation**.)*
- **Polling is slow and wasteful.** A timer-triggered "check the mailbox every N minutes" workflow adds latency (up to the poll interval) and burns runs even when nothing arrived. It is the right answer only when a webhook cannot be delivered — hence product #3.
- **Change notifications are near real time and efficient.** Graph pushes a small notification the instant the mailbox changes; the workflow only runs when there is actually work to do.

## How it works
1. A **Graph change-notification subscription** is created against the **target mailbox's message resource** (for example `users/svc-mailevents@contoso.com/messages`), with a `changeType` of `created`, a `notificationUrl` pointing at the Logic App's HTTPS endpoint, a random secret `clientState`, and an `expirationDateTime`. *(The exact supported resource forms, the maximum allowed subscription lifetime, and the renewal cadence are Graph-version-specific — **verify against current Microsoft documentation**; never hard-code a lifetime.)*
2. **Graph validates the endpoint** at creation time: it sends a request carrying a `validationToken`, and the endpoint must **echo that token back** as `text/plain` within a few seconds or the subscription is rejected. The **receiver Logic App** answers this handshake first.
3. When a new message arrives, **Graph POSTs a notification** to the `notificationUrl`. By default the notification carries only a **reference** to the changed item (mailbox + message id + `changeType`), **not the message body**. *(Graph can optionally include **resource data** in the payload, which for mail must be **encrypted** with a key you supply — availability and encryption requirements are version-specific; **verify against current Microsoft documentation**.)*
4. The **receiver workflow verifies `clientState`** matches the secret it set, discards the call if it does not, then **reads the changed message from Graph using the managed identity** (`GET /users/{mailbox}/messages/{id}`) and processes it **idempotently**.
5. A separate **renewal workflow** runs on a schedule and **extends the subscription before it expires**, so notifications never stop. A **reconcile/catch-up read** covers any gap (a missed notification or a lapsed subscription) by reading messages since the last processed watermark.

## What you control
- **Which mailbox** is monitored (one mailbox, least-privilege scoped — see product #4).
- **Which change** fires the workflow (`created` for new mail; other `changeType` values are possible — verify support per resource).
- **What the workflow does** with each message once read.
- **Subscription lifetime and renewal cadence** (within Graph's current limits — verify).
- **Idempotency and reliability** — how duplicates are suppressed and how missed events are recovered.

## Benefits
- **Near-real-time** processing instead of poll-interval latency.
- **No stored credentials** — managed identity + application permission; nothing to rotate or leak.
- **Least privilege** — one application permission, scoped to one mailbox.
- **Efficient** — the workflow runs only when the mailbox actually changes.
- **Durable** — renewal and catch-up mean a single missed notification or expired subscription does not silently drop mail.

## Limitations (be honest with buyers)
- **A public HTTPS endpoint is required.** Graph must be able to reach the `notificationUrl` from the internet over TLS. If your Logic App can only run on a private endpoint with no public path, use the **polling** pattern (product #3) instead.
- **Subscriptions expire and must be renewed.** There is no "permanent" subscription; the renewal workflow is not optional. A missed renewal stops notifications until re-created — the catch-up read is what prevents data loss in that window.
- **Notifications can be missed or delivered more than once.** Delivery is best-effort and at-least-once, so the workflow **must** be idempotent and must reconcile gaps; treat every notification as "maybe already processed, maybe one of several."
- **Notifications are references, not content, by default.** The workflow reads the message separately (encrypted resource-data delivery is an option to verify).
- **Graph specifics change.** Maximum lifetime, renewal cadence, supported resources, permission names, and national-cloud endpoints are all version- and cloud-specific — this guide flags each; **verify against current Microsoft documentation** before you rely on a number.
- **Consumption vs Standard Logic Apps differ** in hosting, networking, and pricing for an always-reachable HTTP endpoint — **verify against current Microsoft documentation** which plan fits your endpoint and scale needs.

## The standard deployment model
> **Enable the managed identity → grant the least-privilege application permission (admin consent) → scope access to the one mailbox (see #4) → build the receiver Logic App with the validation handshake and clientState check → create the change-notification subscription → build the renewal + catch-up workflow → pilot, validate, expand.** The repeatable pattern is **Assess → Configure → Pilot → Validate → Expand**, with an explicit end-to-end event test and a documented rollback (delete the subscription; the mailbox is untouched).
