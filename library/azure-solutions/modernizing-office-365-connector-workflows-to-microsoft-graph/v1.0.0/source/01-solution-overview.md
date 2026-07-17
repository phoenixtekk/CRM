# 1. Solution Overview — Modernizing Office 365 Connector Workflows to Microsoft Graph

## Why this is a program, not a one-off

One Logic App hitting the Office 365 connector's authentication wall is a **fix**. Dozens of Logic Apps and Power Automate flows — all built on the Office 365 Outlook / Office 365 Users / Excel Online connectors, all authenticated as a user or a shared service account — is a **program**. Organizations accumulate these connector-based flows over years: a mail-sending flow here, a mailbox-polling flow there, a "when a new email arrives" trigger somewhere else. Each one holds a standing credential (a signed-in user's token or a service account's password), each one is a piece of the estate nobody re-authorized, and together they are a large, quiet authentication-risk surface that no single fix retires.

This solution is the **migration program** that retires that surface at estate scale. It does three things a single-flow fix cannot: it **inventories** every connector-based flow and how each one authenticates; it **classifies** them by risk and by how cleanly each maps onto a managed-identity Microsoft Graph design; and it **re-platforms** them in **waves** — pilot first — onto managed-identity Graph workflows, validating parity so nothing silently breaks. The program-level value is the **inventory + classification + wave rollout + governance** discipline; the per-flow engineering depth lives in the sibling products this program orchestrates.

## The inventory → classify → migrate → govern arc

The program follows one arc from a sprawling connector estate to a governed, credential-free end state:

1. **Inventory** — enumerate every Logic App and, where the platform allows, every Power Automate flow that uses an Office 365 connector, and record **how each authenticates** (interactive user, shared service account, or stored secret). The output is the **Connector Flow Inventory – Estate – Program** register.
2. **Classify** — score each flow by **risk** (standing credentials, over-scoped access, a shared service account behind many flows) and by **Graph-migratability** (does the flow's behaviour map cleanly onto a managed-identity Graph pattern, or does it need redesign). The output is the **Migration Register – Estate – Program**.
3. **Migrate** — run the **per-flow playbook**: for each flow, pick the matching sibling pattern, scope its Graph permission to only what it needs, cut it over, and validate parity. This is where the program **references, and does not reproduce**, the per-flow products (below).
4. **Govern** — after the estate is migrated, keep it that way: prevent regression to connector-based auth, and report any flow that still carries a connector or a stored credential.

The repeatable delivery shape across the whole program is **Assess → Configure → Pilot → Validate → Expand**, with a **pilot-first gate** and a **per-flow rollback**.

## The per-flow playbook leans on the sibling products (reference, don't re-teach)

The program does not re-teach how to build a single managed-identity Graph workflow — that depth is already productized. For each flow, the playbook says **"apply the pattern from the relevant product below,"** then focuses on the program-level concerns (sequencing, parity, rollback, governance):

- **Sending / reading / moving mail, or general mailbox automation** → apply **"Exchange Online Mailbox Automation with Logic Apps Managed Identity — Replacing the O365 Connector with Microsoft Graph"** (sibling #1).
- **Event-driven "when a new email arrives" triggers** → apply **"Event-Driven Mail Processing with Microsoft Graph Change Notifications (Logic Apps + Managed Identity)"** (sibling #2).
- **Scheduled / recurring mailbox polling** → apply **"Graph Mailbox Polling Workflows in Azure Logic Apps (Managed Identity, No Service Account)"** (sibling #3).
- **The managed-identity + app-permission foundation any flow needs** → apply **"Managed Identities for Azure Logic Apps & Functions — Authenticating to Microsoft 365 Without Stored Credentials"** (sibling #5).
- **Scoping the Graph application permission down to a single mailbox (or a defined set)** → **defer to** **"Scoping Application-Permission Mailbox Access — Graph RBAC & Application Access Policies for Exchange Online"** (sibling #4). The program never grants a tenant-wide mailbox permission where a scoped one will do; it references #4 for exactly how to constrain it.

The through-line the program owns is the **discipline**: which flow migrates in which wave, how parity is proven, and how the end state is governed. The per-flow "how" is in #1/#2/#3/#4/#5.

## Logic Apps and Power Automate are not the same — treat the difference honestly

Azure **Logic Apps** and **Power Automate** flows both use Office 365 connectors, but they **do not authenticate the same way**, and this shapes the migration:

- **Azure Logic Apps** can be assigned an **Azure managed identity** (system- or user-assigned) and can call Microsoft Graph with an application permission — this is the clean managed-identity Graph end state the sibling products build.
- **Power Automate** flows typically authenticate through **connection references** tied to a user or a service account, and **do not consume Azure managed identities** the same way Logic Apps do. A Power Automate flow's "modernized" target is therefore not always a drop-in managed-identity swap; it may need to be **re-platformed into a Logic App**, re-pointed at a **least-privilege service principal / connection**, or redesigned.

Because the exact capabilities drift between platform versions and connector releases, **the specific answer for any given flow — whether a particular Office 365 connector trigger/action supports managed identity, and what the correct modern target is for a Power Automate flow — must be verified against current Microsoft documentation** at migration time. What is stable, and what this program commits to, is the **target end state** (a Graph-based workflow with **no stored user or service-account credential**) and the **migration discipline** (inventory → classify → pilot → validate → wave → govern).

## Benefits

- **The whole estate is seen, not guessed** — a single register of every connector-based flow and its authentication model, instead of tribal knowledge.
- **Risk is ranked, not uniform** — the flows with standing service-account credentials and the broadest access are migrated first.
- **Credentials are eliminated at scale** — the end state is managed-identity Graph (Logic Apps) and least-privilege service principals (where Power Automate can't take a managed identity), with **no stored passwords or user tokens** behind automation.
- **Least privilege by construction** — every migrated flow's Graph **application** permission is scoped (per sibling #4) to only the mailbox(es) it needs, not the whole tenant.
- **Nothing breaks silently** — each flow is migrated with a parity check and a per-flow rollback; the pilot proves the method before the estate follows.
- **It stays fixed** — governance reporting catches any new or reverted connector-based flow before it becomes the next quiet risk.

## Limitations (be honest with buyers)

- **Power Automate flows may not be a like-for-like managed-identity swap.** Where a flow cannot take an Azure managed identity, the modern target is a re-platform or a least-privilege service-principal connection — more work than a Logic Apps swap. The program flags these in classification rather than pretending they are identical.
- **Enumerating Power Automate flows is not the same as enumerating Logic Apps.** Logic Apps are Azure resources the discovery script can list directly; Power Automate flows live in the Power Platform and require a Power Platform admin enumeration method. The exact enumeration surface is a **verify-against-current-documentation** item.
- **The per-flow depth is in the sibling products.** This program orchestrates and sequences; the detailed build of any single managed-identity Graph workflow is delivered by #1/#2/#3/#5 (and scoped by #4). It references them; it does not reproduce them.
- **Graph does not always expose an identical shape to the old connector action** — some flows need a small redesign to reach behavioural parity. The classification step surfaces these before the wave, not during it.
- **This is a migration program, not a net-new automation build** — it re-platforms existing behaviour; it does not invent new automation.
- **Connector deprecation timelines, Graph permission names, change-notification lifetimes, and national-cloud endpoint specifics are not asserted here** — they are explicitly deferred to current Microsoft documentation, because they change.

## The standard deployment model

> **Inventory the connector estate and its auth → classify by risk and Graph-migratability → configure the pilot cohort's managed-identity Graph targets (per the sibling patterns, scoped per #4) → pilot the migration on a small cohort → validate parity and confirm no residual credentials → expand in waves with per-flow rollback → govern the end state to prevent regression.** This is the repeatable pattern **Assess → Configure → Pilot → Validate → Expand**, with a **pilot-first gate** and a **documented per-flow rollback**.
