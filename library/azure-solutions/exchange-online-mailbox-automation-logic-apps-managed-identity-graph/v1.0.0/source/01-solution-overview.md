# 1. Solution Overview — Exchange Online Mailbox Automation with Logic Apps Managed Identity (Replacing the O365 Connector with Microsoft Graph)

## The problem this solves (root cause, stated plainly)
A common pattern is to build an Azure **Logic Apps** workflow that acts on an Exchange Online mailbox — read new mail, process attachments, trigger downstream work — and to try to authenticate it with the Logic App's **managed identity** by using the **Office 365 Outlook** connector (the *"When a new email arrives"* / *Mail Receive* trigger). **It does not work, and it is not a bug you can configure around.**

**Root cause:** the **Office 365 Outlook connector authenticates as a user / service account through an interactive OAuth connection** — it is bound to a signed-in mailbox principal, stored as an API connection resource. It has **no mechanism to authenticate as the Logic App's managed identity**. The trigger therefore cannot bind to a system-assigned (or user-assigned) managed identity at all; the connector simply is not a managed-identity-aware connector. *(Whether any specific Office 365 Outlook connector operation or trigger supports managed identity is a product detail that changes over time — **verify against current Microsoft documentation** before relying on it. As of this writing the trigger authenticates via a stored OAuth connection, not a managed identity.)*

The result is a design that forces you to store a **service-account credential** (a licensed mailbox whose OAuth token the connection holds) — the exact stored-secret and shared-account risk that using a managed identity was supposed to eliminate.

## The supported fix — drive the mailbox through Microsoft Graph
Stop using the Office 365 Outlook connector for this. Instead, have the Logic App call **Microsoft Graph** directly, authenticating with its **managed identity**, where the identity holds an **application** Graph permission (an **app role**, e.g. `Mail.Read`) and the mailbox access is **scoped so the identity can read exactly one mailbox — not every mailbox in the tenant**.

In this model:
- The Logic App has a **managed identity** — either **system-assigned** (tied to the Logic App's lifecycle) or **user-assigned** (a standalone identity you can share across resources). Either works; this solution uses **system-assigned** by default and notes where user-assigned differs.
- That identity's **service principal** is granted an **application** Microsoft Graph permission — an *app role* such as `Mail.Read` — with **admin consent**. Application permissions are **not** delegated: there is no signed-in user, and by default an application `Mail.Read` grant can read **every** mailbox in the tenant. That tenant-wide reach is the risk, which is why scoping is mandatory.
- The mailbox access is **scoped to one mailbox** so the identity can read only `automation-inbox@contoso.com`, not the whole tenant. This is the security spine of the design (summarized below; the deep walkthrough is a separate product — see *Mailbox scoping*).
- The Logic App calls the Graph mail endpoints (e.g. `GET /users/{id}/messages`) using its managed identity as the authentication type. **No service account, no stored OAuth connection, no shared password.**

*(Exact Graph permission names and scopes, and the precise Graph endpoints for reading mail, are Microsoft product details — the concepts here are stable, but **verify the exact permission name and endpoint against current Microsoft Graph documentation** before you grant or call them.)*

## Webhook vs polling — how the workflow learns there is new mail
Graph gives you two ways to drive a mailbox workflow. This flagship builds the **authentication and scoping foundation** that **both** patterns require; the two patterns themselves are covered in depth by dedicated sibling products.

| | **Event-driven (webhook / change notifications)** | **Polling** |
|---|---|---|
| How it triggers | Graph **change notifications** push to your workflow when mail arrives | The workflow **wakes on a timer** and queries Graph for new mail |
| Latency | Near-real-time | Bounded by the polling interval |
| Moving parts | A **subscription** you must **create and renew** before it expires; a validated public HTTPS notification endpoint | A recurrence trigger and a "what have I already seen" watermark |
| Best when | You need low latency and can operate a renewing subscription + public endpoint | You want the simplest possible design and can tolerate interval latency |
| Watch-outs (verify) | Max subscription lifetime, renewal cadence, and which mailbox resources support notifications **change — verify against current Microsoft documentation** | Duplicate/last-processed handling; throttling under tight intervals |

- **For the event-driven design, go deep with the sibling product:** ***"Event-Driven Mail Processing with Microsoft Graph Change Notifications (Logic Apps + Managed Identity)."*** It covers subscription creation, the validation handshake, the renewal loop, and delta handling — do not reinvent those here.
- **For the polling design, go deep with the sibling product:** ***"Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)."*** It covers the recurrence pattern, watermarking already-processed messages, and throttling-safe intervals.

This product deliberately stops at "the identity can authenticate and read exactly one mailbox." Once that foundation is proven, choose your trigger pattern and follow the matching sibling.

## How access is scoped to one mailbox (concise — full walkthrough is a separate product)
An application `Mail.Read` grant is **tenant-wide by default** — the identity could read every mailbox. To reduce it to a single mailbox, Microsoft provides mailbox-scoping controls for application permissions. Conceptually there are two approaches:
- **Application Access Policy** (the long-standing Exchange Online control) — you create a **mail-enabled security group** containing only the target mailbox and bind a policy that restricts the app (the managed identity's service principal, by its app/client ID) to members of that group.
- **Graph RBAC for Exchange Online** (the newer, role-based scoping model) — role assignments scope an app's mailbox access to a defined set of mailboxes.

**Which control to use, and its exact syntax, is version- and tenant-dependent — verify against current Microsoft documentation.** This flagship includes only the concise "make it one mailbox" step needed to finish the build (Implementation Step 3). **For the full, click-by-click scoping walkthrough — Application Access Policy vs Graph RBAC, when to use each, the exact cmdlets, and how to prove the boundary — use the dedicated sibling product:** ***"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online."*** Do not treat the summary here as the complete scoping design.

## Benefits
- **No stored credentials.** The managed identity replaces the service account and its OAuth connection — nothing to rotate, leak, or share.
- **Least privilege, provable.** One application permission, scoped to one mailbox, with an explicit out-of-scope test that must fail.
- **Supported and durable.** Microsoft Graph is the strategic API for mail; the Office 365 Outlook connector's user-auth model is the thing being modernized away.
- **Pattern-ready.** The same authenticated, scoped identity underpins either a webhook or a polling workflow (the two siblings).

## Limitations (be honest with buyers)
- **You give up the connector's convenience.** The Office 365 Outlook connector's ready-made triggers/actions are replaced by explicit Graph calls; you build the request, handle paging, and handle the trigger pattern yourself (or via a sibling product's pattern).
- **Application permission is powerful.** `Mail.Read` as an application permission is tenant-wide **until you scope it** — scoping is not optional, it is the design.
- **Consumption vs Standard Logic Apps differ.** How the managed identity is enabled and referenced, and some workflow features, differ between **Logic Apps Consumption** and **Logic Apps Standard** — this guide uses **Consumption** by default and flags where Standard differs; **verify the specifics against current Microsoft documentation.**
- **National clouds differ.** GCC High / DoD and other national clouds use **different Graph and login endpoints** and may differ in feature availability — **verify the sovereign-cloud endpoints and parity against current Microsoft documentation** before deploying there.
- This solution provisions **read** access (`Mail.Read`) as the worked example. Send/modify scenarios need different (higher) permissions and their own scoping and approval.

## The standard deployment model
> **Assess** the current (broken) connector-based workflow and the target mailbox → **Configure** the Logic App managed identity, the application Graph permission (app role), and the one-mailbox scope → **Pilot** a Graph-based read against the single mailbox → **Validate** that in-scope reads succeed and out-of-scope reads are denied and a test message flows end to end → **Expand** to the chosen trigger pattern (webhook or polling sibling) and to additional mailboxes/workflows as needed.

Repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with a **least-privilege, one-mailbox scope** as the non-negotiable gate before any workflow logic is trusted.
