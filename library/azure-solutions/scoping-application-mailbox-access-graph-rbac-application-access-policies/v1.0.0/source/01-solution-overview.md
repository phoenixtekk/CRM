# 1. Solution Overview — Scoping Application-Permission Mailbox Access (Graph RBAC & Application Access Policies)

## The exposure: an application permission is tenant-wide by default
When you grant an **application** (an app registration, or the managed identity of a Logic App / Function / VM) an **application-type** Microsoft Graph permission over mail — for example **`Mail.Read`**, **`Mail.ReadWrite`**, **`Mail.Send`**, **`MailboxSettings.Read`**, or their Exchange-Web-Services equivalents — that grant is **tenant-wide**. The app can read, write, or send as **every mailbox in the organization**, not just the one mailbox it was built to service. This is different from *delegated* permissions (which act only as the signed-in user); an **application permission runs with no user and is bounded by nothing** unless you add a boundary yourself.

That is almost never what the app actually needs, and it is a classic security-review finding: an invoicing automation that should read one shared mailbox can, with the same credential, read the CEO's inbox. The blast radius of a leaked client secret or a compromised managed identity is *the entire organization's mail*.

> **This solution's whole premise is least privilege.** A tenant-wide application mail permission with no scope is **not** an acceptable end state — it is the finding you are here to close. Every path below narrows the app to exactly the mailboxes it is allowed to touch, and then **proves** the boundary.

## The two scoping models
Exchange Online provides **two** ways to constrain an application's mailbox access. This product owns the deep material for **both**, because they solve the same problem differently and the right choice depends on your situation.

- **Application Access Policy** — the established model. You create a **mail-enabled security group** containing the mailboxes the app is allowed to touch, then bind the app to that group with an access policy (using **`New-ApplicationAccessPolicy`** in Exchange Online PowerShell — *verify the exact cmdlet name and parameters against current Microsoft documentation*). The policy restricts (or denies) the app to the group's members. It layers a **scope on top of** the broad application permission the app already holds.

- **Graph RBAC for Exchange Online** — the newer, resource-scoped model (sometimes described as **RBAC for Applications in Exchange Online**; *confirm the current product name against Microsoft documentation*). Instead of granting a broad Graph application permission and then restricting it, you assign the app's **service principal** a specific Exchange **application role** (for example an "Application Mail.Read"-style role — *verify exact role names against current Microsoft documentation*) **scoped** to a management scope, administrative unit, or group of mailboxes. Access is granted **narrowly from the start** rather than granted broadly and then fenced in.

> **Which model is current / recommended is version- and roadmap-dependent — do NOT assume.** Microsoft has been evolving the RBAC-for-applications model. **Verify against current Microsoft documentation** which model Microsoft recommends for a new deployment, whether both are supported in your cloud (commercial vs GCC / GCC High / DoD), and the exact cmdlets, role names, and scope objects before you implement. This guide gives you the workflow for each and a decision path; it deliberately does **not** assert which one Microsoft currently prefers.

## The decision path (which model fits)
Use this as a starting decision, then confirm against current Microsoft guidance:

1. **Do you already operate Application Access Policies, and is your app holding a broad Graph mail permission you simply need to fence to a set of mailboxes?** → **Application Access Policy** is the low-friction fit: create the mail-enabled security group, bind the app, done.
2. **Do you want the app to hold only a narrow, specific Exchange right scoped to specific mailboxes — never a tenant-wide grant at all — for the tightest possible least privilege?** → lean toward **Graph RBAC for Exchange Online** (resource-scoped assignment), if it is available and supported for your scenario and cloud.
3. **Is the app a managed identity (Logic App / Function)?** Both models can scope a managed identity's service principal; the mechanics are the same as for an app registration. *Verify managed-identity support for the specific model and cloud.*
4. **Are you in a government cloud (GCC / GCC High / DoD)?** Feature parity and rollout timing differ from commercial — **verify** that the chosen model and its cmdlets are available in your cloud before committing.

When unsure, pilot the **Application Access Policy** model first (it is the more broadly available and the one most audit reviewers recognize), and evaluate Graph RBAC as the target-state model once you have verified its support.

## How the boundary is proven
Scoping is only credible if you can **demonstrate** it. This solution proves the boundary two ways:

- **In-scope read succeeds** — the app, using its own application credential, reads the mailbox it is allowed to touch (`reports@contoso.com`). This must **PASS**.
- **Out-of-scope read is denied** — the same app, same credential, attempts to read a mailbox it is *not* scoped to (`ceo@contoso.com`). This must be **DENIED** (a `403`/`ErrorAccessDenied`-class failure). If an out-of-scope read succeeds, the scope is not in effect — the product's troubleshooting guide covers exactly this.

The evidence (who the app is, which mailboxes it can and cannot reach, and the deny result) is captured to a report so an auditor can see the boundary without re-running anything.

## Benefits
- **Least privilege, provable.** The app touches only its intended mailboxes, and you have the test evidence to show it.
- **Smaller blast radius.** A leaked secret or compromised managed identity can reach one mailbox, not the whole tenant.
- **Two models, one reference.** Whether your estate uses Application Access Policies or is moving to Graph RBAC for Exchange Online, the decision path and the boundary proof are the same.
- **Audit-ready.** A tenant-wide report of every mail-capable application permission and whether it is scoped is exactly what a security review asks for.
- **Reusable across every app/identity.** This scoping applies to any application or managed identity that reads or sends mail — including the automation patterns covered by the sibling solutions (Logic Apps mailbox automation, managed-identity authentication to Microsoft 365).

## Limitations (be honest with buyers)
- **A scope constrains the app, not the permission grant.** With Application Access Policy, the app still *holds* the broad Graph permission; the policy fences it. If the policy is removed or misconfigured, the broad grant is back in force — the report and validation script exist to catch that.
- **Propagation is not instant.** New Application Access Policies and RBAC assignments take time to take effect across Exchange Online (commonly cited as up to ~30 minutes or longer — *verify current propagation guidance with Microsoft*). A boundary test run too soon can give a false result.
- **Model availability varies.** Graph RBAC for Exchange Online is newer; its exact cmdlets, role names, supported resources, and availability in government clouds are **version-dependent — verify before relying on them.**
- **Groups must be the right type.** Application Access Policy requires a **mail-enabled security group** — a plain security group or a Microsoft 365 group will not behave the same way; membership must be maintained as mailboxes come and go.
- **This is access scoping, not DLP.** Scoping limits *which mailboxes* an app can reach; it does not inspect or restrict *what content* leaves. Pair it with data-loss-prevention controls where the risk warrants.

## The standard deployment model
> **Discover mail-capable application permissions and whether each is scoped → choose the model (Application Access Policy or Graph RBAC for Exchange Online) → create the scope (mail-enabled security group / management scope) and bind the app → validate the app is scoped (not tenant-wide) → prove the boundary (in-scope PASS, out-of-scope DENIED) → expand to the next app.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand**, with the **boundary proof as the gate** and a documented rollback (remove the policy / assignment) for every change.
