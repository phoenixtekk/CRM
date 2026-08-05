# Solution Overview

## The question this solves

You tried to call a **Microsoft Graph Copilot admin (beta) endpoint** — most commonly
`GET https://graph.microsoft.com/beta/copilot/admin/catalog/packages` or
`GET https://graph.microsoft.com/beta/copilot/admin/catalog/packages/{id}` — and the request was
**blocked or failed**. You got back a `401`, a `403`, a `404`, or a `429`, and you cannot tell which
of several very different things is actually wrong:

- your token is missing the right **permission scope**, or
- your signed-in user is missing the right **admin role**, or
- you used an **application-only token** where the endpoint demands a **signed-in user**, or
- **admin consent** was never granted in the tenant, or
- the **beta/preview feature has not rolled out** to your tenant yet, or
- the endpoint **is not available in your cloud** (US Gov GCC High / DoD / 21Vianet), or
- a **license prerequisite** applies, or
- the **path/namespace/version is wrong** or has been renamed, or
- you are being **throttled**, or
- the data you want **simply is not exposed** by the beta endpoint yet.

Every one of those returns a similar-looking error, and the beta docs do not always tell them apart.
This runbook is a **branch-based diagnostic method** that turns the raw HTTP status into a single,
named root cause — then hands you the exact fix or the supported fallback for each. It is deliberately
**general to the whole `/beta/copilot/admin/*` surface**, not to one report. It is the deep
troubleshooting companion to the inventory/export product described under **Dedupe boundary** below.

> This is an **API troubleshooting runbook**, not a feature tutorial. Its job is to get a *blocked or
> failing* Graph Copilot admin request working, prove whether the data you need is actually exposed,
> and — where the beta endpoint cannot be relied on — route you to the **supported** alternative.

## What the "Graph Copilot admin" endpoint family is

Microsoft 365 Copilot exposes a set of **admin** operations under the Microsoft Graph `copilot`
namespace. They are available under two versions:

- **`https://graph.microsoft.com/v1.0/copilot/...`** — the **GA (generally available)** surface.
- **`https://graph.microsoft.com/beta/copilot/...`** — the **beta/preview** surface. Microsoft's
  standing notice on every beta page: *"APIs under the `/beta` version are subject to change. Use of
  these APIs in production applications is not supported."*

Within that namespace, the **admin** operations this runbook targets are:

| Operation family | Example endpoint | Purpose |
|---|---|---|
| **Package Management (agent catalog)** | `GET /beta/copilot/admin/catalog/packages` and `.../packages/{id}` | List agents/apps in the org catalog and read one package's detail (metadata + elements). Also GA at `/v1.0/copilot/admin/catalog/packages`. |
| **Policy settings** | `GET /beta/copilot/admin/policySettings/{id}` | Read a tenant-level Copilot policy setting value. |
| **Usage reports** | `GET /v1.0/copilot/reports/getMicrosoft365CopilotUsageUserDetail` | GA usage/adoption data (a supported fallback when a beta admin call is blocked). |

`GET /beta/copilot/admin/catalog/packages/{id}` — the endpoint most customers hit first — returns a
**`copilotPackageDetail`** object: the agent's `id`, `displayName`, `type` (`custom` / `external` /
etc.), `publisher`, `isBlocked`, `supportedHosts`, `availableTo` / `deployedTo`, `elementTypes`, and
per-element `elementDetails`. The list endpoint returns a collection of the lighter `copilotPackage`
objects and supports `$filter` on `supportedHosts`, `elementTypes`, `lastModifiedDateTime`, and
`platform`.

> **Accuracy note (beta is volatile).** Every endpoint path, scope name, license requirement, admin
> role, and error meaning in this runbook was verified against Microsoft Learn on the build date
> (see the Requirements guide for exact source pages). Because this is a **preview** surface,
> Microsoft can change any of it without notice. Where current behavior is known to diverge from the
> published reference, this guide says so explicitly and marks it **"verify against current Microsoft
> documentation — beta, subject to change."** Do not treat any single response shape as permanent.

## The two things that make beta admin calls fail differently

Two distinctions decide almost every failure you will see. Learn them first; the whole playbook turns
on them.

### 1. Authentication vs authorization (401 vs 403)

- A **`401 Unauthorized`** is an **authentication** failure: Graph could not validate *who is
  calling*. The token is missing, expired, malformed, issued for the wrong **resource/audience**, or
  issued in the **wrong cloud** (a commercial token sent to `graph.microsoft.us`, or vice-versa).
- A **`403 Forbidden`** is an **authorization** failure: Graph knows who you are but you are **not
  allowed** to do this. That can be a missing **scope**, a missing **admin role**, an **app-only
  token where a user is required**, an ungranted **admin consent**, a **feature not enabled for the
  tenant**, or a **license** gap. A 403 is therefore *ambiguous by itself* — the runbook's core job is
  to disambiguate it.

### 2. Scope (consent) vs role (directory role)

A Graph call to a tenant-wide admin resource needs **both**:

- **A permission scope** — e.g. `CopilotPackages.Read.All` — present in the **token**. A scope is
  granted by **consent** (admin consent, for `.All` application-style scopes). A missing scope is a
  *consent/registration* problem.
- **A sufficient directory role** — for delegated calls, the **signed-in user** must hold an admin
  role that authorizes reading the tenant-wide agent catalog (see Requirements). A user with the
  right scope in their token but **no admin role** is still refused. A missing role is an
  *assignment* problem, fixed in Entra, not in the app registration.

Missing-scope and missing-role can both surface as `403`, which is exactly why people "have the
permission" and still get denied. The playbook separates them with a preflight that reports **scopes
in the token** and **roles on the user** side by side.

## GA vs beta — Microsoft's support posture (read before you build a dependency)

| | GA (`/v1.0`) | Beta (`/beta`) |
|---|---|---|
| **Support statement** | Supported for production use. | *"Not supported"* for production; *"subject to change."* |
| **Breaking changes** | Follow Graph's deprecation/versioning policy (advance notice). | Can change **shape, path, permissions, or availability without notice**. |
| **Throttling** | Standard Graph limits, `Retry-After` honored. | Similar limits but preview services often have **tighter, less predictable** burst capacity. |
| **Tenant availability** | Broadly available. | Frequently **rolling out tenant-by-tenant**; a correct call can still 403/404 until your tenant is flighted. |
| **Cloud availability** | Varies per API; check the per-endpoint national-cloud table. | Copilot admin beta endpoints are **Global-only** today (not GCC High / DoD / 21Vianet). |

**Decision rule this runbook recommends:** treat a `/beta/copilot/admin/*` endpoint as a **diagnostic
and interim** data source, not a production dependency. If a GA (`/v1.0`) equivalent exists (e.g. the
GA `catalog/packages` path, or the GA usage reports), prefer it. If only beta exists and you must
depend on it, **wrap it** so a shape/permission change or a 404 fails safe, and re-check against the
current docs on a schedule. Best-practices guidance is in `07-best-practices.md`.

## The diagnostic model (how the playbook is organized)

The runbook is a **symptom → cause → fix → re-validate** tree, in a fixed order:

1. **Step 0 — Establish the facts.** Capture the *exact* request (method, full URL, version, cloud),
   the *exact* status code, and the *exact* error `code` / `message` / `request-id`. Read what scopes
   are in your token and what roles are on your user. You cannot branch correctly without this.
2. **Branches A–J.** Each branch owns one root cause (insufficient scope, missing role, app-only vs
   delegated, consent not granted, preview not rolled out, cloud not enabled, license prerequisite,
   wrong path/namespace, throttling, genuine product limitation). Each gives you the **symptom**, how
   to **confirm** it, the **fix or supported workaround**, and how to **re-validate**.
3. **Re-validate** with the testing procedures in `05-testing.md`, which also prove the harder
   question: whether the data you need **is or is not** exposed by the endpoint at all.

## The standard deployment model

Every solution in this catalog follows the same shape so each engagement feels familiar and low-risk:
**Assess → Configure → Pilot → Validate → Expand.** Here that means: assess the exact failing call
(Step 0); configure the missing scope/role/consent/cloud target; pilot the fixed call with a single
delegated admin; validate against the testing gates; then expand to your automation (scheduled export,
report, or integration) — or, if the beta endpoint proves unreliable, expand onto the **supported
fallback** instead.

## Benefits

- **Turns an ambiguous 403 into one named cause** — no more guessing between scope, role, consent,
  rollout, cloud, and license.
- **Verified against Microsoft Learn**, with every beta-volatile claim flagged so you know what to
  re-check.
- **Read-only and safe** — the five scripts diagnose and report; none of them change tenant state.
- **Cloud-aware** — every script targets Global, GCC High, or DoD Graph via a single switch.
- **Gives you the supported exit** — when beta cannot be relied on, you leave with the GA endpoint,
  admin-center export, or audit-log path that *can*.

## Limitations and honest scope

- This runbook covers **diagnosing and unblocking requests to the Graph Copilot admin (beta) surface
  and choosing a supported alternative.** It is not a guide to *building* agents, and it does not and
  cannot make Microsoft expose data the API does not expose.
- Where a beta endpoint is **undocumented or not intended for third-party app use**, the honest answer
  is to **not depend on it** and use the supported path; the playbook says so rather than inventing a
  workaround.
- The customer has already **ruled out Agent 365 licensing** as their blocker; this guide acknowledges
  the license prerequisite that Microsoft's current docs state (Branch G) and then moves past it to the
  other causes.

## Dedupe boundary — how this differs from the Agent Builder inventory product

A sibling product, **Copilot Agent Builder — Inventory, Sharing, Governance & Export**, delivers the
actual **agent inventory + sharing export** deliverable (a scheduled, filtered register of Agent
Builder agents and who they are shared with) and includes a short diagnostic for that one task. **This
product is different:** it is the **deep, general troubleshooting runbook for the
`/beta/copilot/admin/*` API surface itself** — every failure cause, across every admin operation in
that namespace, with the scripts to confirm each. If your goal is *the export*, use the inventory
product. If your goal is *understanding and fixing why any Graph Copilot admin call is blocked*, this
is the runbook. Where you need the export after unblocking the call, this guide points you to that
product rather than reproducing it.
