# Executive Summary — Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account) (Microsoft Azure)

**White-label · Azure Solutions**

Not every environment can expose a public HTTPS endpoint for Microsoft Graph change notifications, and the legacy Office 365 Outlook connector cannot authenticate with a managed identity. When the event-driven webhook isn't an option, the robust fallback is a **scheduled Graph polling workflow** — but done **properly**, not a naive "get messages every 5 minutes" that double-processes mail and trips throttling. This solution builds a **recurrence-driven Azure Logic App** that reads new mail through Microsoft Graph with a **managed identity** (no service account, no stored secret), tracks a **high-water mark** so each message is processed **exactly once**, handles **throttling and paging**, and **marks or moves** processed items so a re-run is always safe.

This is a complete, **deploy-it-today** package, written for an administrator with no prior Logic Apps or Microsoft Graph experience.

## What you get
- A plain-language **Solution Overview** of the recurrence Logic App, managed-identity authentication, the two exactly-once strategies (received-time watermark vs. `/messages/delta`), throttling/paging, and idempotent handling — plus when to poll vs. use the event-driven webhook (product #2).
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (Logic App, managed identity, least-privilege application permission + admin consent, one-mailbox scoping, target mailbox, watermark store, Microsoft.Graph PowerShell, national-cloud endpoints).
- An **Implementation Guide** of precise, ordered steps — enable the managed identity, grant and consent the least-privilege permission, scope it to one mailbox (defer to product #4), provision the watermark store, and build the workflow with Graph read, 429 handling, `@odata.nextLink` paging, watermark persistence, and idempotent mark/move.
- Five **PowerShell scripts** (Microsoft.Graph) for discovery, PASS/FAIL validation, a processing/backlog report, an exactly-once watermark check, and a `-WhatIf`-gated app-role assignment helper.
- **Testing** and **Troubleshooting** guides for confident rollout.

## What this delivers
A **recurrence-triggered Logic App** reading new messages via **Microsoft Graph** with a **managed identity**; a **high-water mark** (received-time watermark or delta `deltaLink`) that guarantees **exactly-once** processing; **throttle-safe** behavior that honors `Retry-After` and follows `@odata.nextLink` paging; and **idempotent** mark-as-read / move-to-`Processed` handling — with the application permission confined to **one mailbox** (product #4). Version-, throttling-, delta-, Consumption-vs-Standard-, and national-cloud-specific details are flagged to **verify against current Microsoft documentation** rather than asserted.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — with an **exactly-once validation gate** (two consecutive runs process each message once) and a documented rollback.

## Outcome
A dependable, credential-free mailbox-polling workflow that reads each message exactly once over Graph — watermarked, throttle-safe, and idempotent — deployable by a single administrator and validated before you scale, and the right pattern precisely when an event-driven webhook cannot be used.
