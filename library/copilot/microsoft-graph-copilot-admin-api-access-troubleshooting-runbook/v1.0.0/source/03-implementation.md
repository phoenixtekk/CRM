# Diagnostic Runbook

This is the core of the solution: a **branch-based diagnostic tree** for a blocked or failing request
to a `/beta/copilot/admin/*` (or `/v1.0/copilot/admin/*`) endpoint. Start from what you observe in
**Step 0**, follow the branch that matches your exact status code and error text, run the checks, apply
the fix or supported workaround, then re-validate with the gates in `05-testing.md`.

**Golden rule:** the request passes through an ordered set of gates —
**Authentication → Consent (scope) → Admin role → Delegated-vs-app → Tenant/cloud availability →
License → Path/version → Throttle**. The **first** gate that fails is the root cause; everything after
it is a symptom. Fix the first failing gate, then re-run the probe. Never invent a response shape for a
beta endpoint — if the call fails, read the **real** status and error body and branch on it.

---

## Step 0 — Establish the facts (always do this first)

You cannot branch correctly without the exact request and the exact error. Capture all of it before
you change anything.

1. **Record the exact request.** Write down, verbatim: the **HTTP method**, the **full URL** including
   the **version segment** (`/v1.0/` vs `/beta/`), any `$filter`, and the **cloud host** you sent it to
   (`graph.microsoft.com`, `graph.microsoft.us`, or `dod-graph.microsoft.us`). A wrong version or wrong
   host is itself a cause (Branches F and H).

2. **Reproduce it with the real status visible.** Run **`CPADMDX-Probe-Endpoint.ps1`** against the same
   endpoint. It sends the request with `Invoke-MgGraphRequest`, and on failure it prints the **HTTP
   status code**, the error **`code`**, the error **`message`**, and the **`request-id`** /
   **`client-request-id`** from the body. Do not rely on the console UI's paraphrase — read the raw
   response. Example of what you are capturing:

   ```json
   {
     "error": {
       "code": "Forbidden",
       "message": "Access is denied to the requested resource.",
       "innerError": {
         "request-id": "00000000-0000-0000-0000-000000000000",
         "client-request-id": "00000000-0000-0000-0000-000000000000",
         "date": "2026-07-24T00:00:00"
       }
     }
   }
   ```

3. **Read your identity, scopes, and roles.** Run **`CPADMDX-Preflight.ps1`**. It reports, in one
   place: the **signed-in account** and **auth type** (delegated vs app — R2), the **scopes in the
   token** (R3), the user's **directory roles** (R4), and the **cloud** you connected to (R6). This is
   the single most important input to branching — most "I have the permission but still get 403"
   cases are a **role** gap or an **app-vs-delegated** gap, both visible here.

4. **Write the facts to evidence.** `CPADMDX-Report-Findings.ps1` records everything into
   **`CPADMDX-Diagnostics\CPADMDX-Findings.json`**. Keep it; it is your support-case attachment.

Now pick the branch whose **symptom** matches. If two could apply, take them **in order A → J** (that
is gate order).

---

## Branch A — 401 Unauthorized (authentication failed)

**Symptom:** `401 Unauthorized`. Error `code` is typically `InvalidAuthenticationToken` with a message
like *"Access token is empty / expired / has invalid signature"*, or *"CompactToken parsing failed"*,
or an audience/issuer mismatch.

**Owner gate:** Authentication — Graph could not validate *who* is calling.

**Confirm:**

1. In `CPADMDX-Preflight.ps1` output, check whether you are even connected: `Get-MgContext` returns
   `$null` if no token. A `401` with no context means you never authenticated.
2. Check **token age** — access tokens expire (typically ~60–90 min). A long-running script that
   cached a token can 401 midway. Reconnect and retry.
3. Check the **audience/resource and cloud**. The token must be issued for
   `https://graph.microsoft.com` (Global) or the matching Gov host. A token minted for
   `graph.microsoft.us` sent to `graph.microsoft.com` (or vice-versa) 401s. Confirm
   `(Get-MgContext).Environment` matches the host in your URL.

**Fix / workaround:** Reconnect with a fresh interactive sign-in in the **correct cloud**:
`Connect-MgGraph -Environment Global -Scopes "CopilotPackages.Read.All"` (or `USGov` / `USGovDoD`).
Ensure the client acquiring the token targets the Graph resource, not another API.

**Re-validate:** Re-run `CPADMDX-Probe-Endpoint.ps1`. A `401` should not recur; you will now get either
`200` (done) or a `403`/`404` — branch again on the new status.

---

## Branch B — 403 with app-only token: "User context is required"

**Symptom:** `403 Forbidden` and the message is specifically *"Access is denied. User context is
required by the requested resource."* You are calling with **application (client-credentials)**
authentication.

**Owner gate:** Delegated-vs-app — the endpoint demands a **signed-in user**; an app-only token is
refused *regardless of granted application permissions*.

**Confirm:**

1. `CPADMDX-Preflight.ps1` shows **AuthType = AppOnly** (or `Get-MgContext` shows a service-principal
   `ClientId` and no user `Account`).
2. Your app registration has `CopilotPackages.Read.All` as an **Application** permission with admin
   consent — and it *still* 403s with the "user context is required" message. That combination is the
   signature of this branch. It matches Microsoft's own reference stating the policy-settings endpoint
   does not support Application permissions, and community confirmation that the packages endpoint
   enforces delegated context despite the reference listing Application permissions.

**Fix / workaround:** Switch to **delegated** authentication with a user who holds the admin role (R4):
`Connect-MgGraph -Scopes "CopilotPackages.Read.All" -Environment Global` (interactive) or
`Connect-MgGraph -UseDeviceAuthentication`. If you need unattended automation, this is a genuine
constraint of the beta endpoint — see Branch J and `07-best-practices.md` for the supported unattended
paths (GA usage reports with `Reports.Read.All` application permission; admin-center scheduled export).

**Re-validate:** `(Get-MgContext).AuthType` now reads `Delegated`; re-run the probe. *(Beta — verify
against current Microsoft documentation; if Microsoft later enables application permissions on this
endpoint, this branch no longer applies.)*

---

## Branch C — 403 because the token is missing the scope (consent gap)

**Symptom:** `403 Forbidden` (`code: Forbidden`, *"Access is denied to the requested resource."*) with
a **delegated** token, and the required scope is **not in the token**.

**Owner gate:** Consent (scope).

**Confirm:**

1. Run `CPADMDX-Resolve-Scopes.ps1` and name your endpoint. It prints **have vs need**. If, for
   `catalog/packages`, `CopilotPackages.Read.All` is in the **need** column but **absent** from the
   **have** column, this is your branch.
2. Cross-check `(Get-MgContext).Scopes`. Remember the families differ: `policySettings` needs
   `CopilotPolicySettings.Read`, **not** `CopilotPackages.Read.All`.

**Fix / workaround:** Reconnect requesting the exact scope:
`Connect-MgGraph -Scopes "CopilotPackages.Read.All"` (or `"CopilotPolicySettings.Read"`). If the
consent prompt is blocked, you have a tenant consent-policy gap → get admin consent (Branch D).

**Re-validate:** `CPADMDX-Resolve-Scopes.ps1` shows the scope now present; re-run the probe.

---

## Branch D — 403 because admin consent was never granted

**Symptom:** You **request** the correct scope at sign-in but it is **not granted** — either the
consent prompt says an administrator must approve, or the scope silently never lands in the token, and
the call 403s. The scope family requires **admin consent**.

**Owner gate:** Consent (tenant policy) — user consent is insufficient/blocked for an admin scope.

**Confirm:**

1. `CPADMDX-Resolve-Scopes.ps1` shows the scope in **need** but it never appears in **have** even
   though you asked for it at `Connect-MgGraph`.
2. Entra → **Enterprise applications** → *Microsoft Graph Command Line Tools*
   (appId `14d82eec-204b-4c2f-b7e8-296a70dad67c`) → **Permissions** does **not** list the Copilot scope
   as granted for the organization.

**Fix / workaround:** A **Global Administrator** grants admin consent **once**: at the interactive
prompt choose *"Consent on behalf of your organization,"* or in Entra → the app → **Grant admin
consent for `<tenant>`**. For a custom app registration, add the delegated Copilot scope on **API
permissions** and click **Grant admin consent**.

**Re-validate:** Reconnect; `CPADMDX-Resolve-Scopes.ps1` now shows the scope present; re-run the probe.

---

## Branch E — 403 because the user lacks the admin role

**Symptom:** `403 Forbidden` with a **delegated** token that **does** contain the correct scope (C and
D are clean) — but the request is still denied. This is the classic *"I have the permission and still
get 403."*

**Owner gate:** Admin role — scope present, but the **signed-in user** is not an admin for this
resource.

**Confirm:**

1. `CPADMDX-Preflight.ps1` shows the scope **present** in the token **and** the user's directory-role
   list contains **neither AI Administrator nor Global Administrator** (nor another role Microsoft
   documents for this surface).
2. `CPADMDX-Resolve-Scopes.ps1` confirms the scope is satisfied — isolating the failure to **role**,
   not scope.

**Fix / workaround:** Assign **AI Administrator** (least privilege) to the user in Entra → **Roles and
administrators** → *AI Administrator* → **Add assignments** (or use an account that already holds it;
Global Administrator also works). If the role is **PIM-eligible**, **activate** it and wait for
activation before retrying.

**Re-validate:** `CPADMDX-Preflight.ps1` now lists the role; sign out/in so the role is reflected;
re-run the probe. *(Beta — the exact directory role the Graph endpoint honors is not named on the
reference page; verify against current Microsoft documentation.)*

---

## Branch F — 403/404 because the endpoint is not available in your cloud

**Symptom:** Scope, consent, role, and auth are all clean (A–E pass), you are certain the path is
correct, yet the call fails with `403` or `404` — **and you are in a US Gov (GCC High / DoD) or
21Vianet tenant**.

**Owner gate:** Cloud availability — the feature is **not offered** in your national cloud.

**Confirm:**

1. `CPADMDX-Preflight.ps1` shows `Environment = USGov` / `USGovDoD` (or you connected to
   `graph.microsoft.us` / `dod-graph.microsoft.us`).
2. The endpoint's national-cloud table shows **❌** for US Gov L4, US Gov L5 (DoD), and 21Vianet — the
   Copilot admin package and policy-settings endpoints are **Global-only** today.

**Fix / workaround:** There is no code fix — the endpoint does not exist in your cloud. Use the
supported alternatives that **are** offered in your cloud (see `05-testing.md` and Branch J):
- the **Microsoft 365 admin center → Agents** surface and its manual/scheduled export;
- any **GA (`/v1.0`) endpoint** whose national-cloud table includes your cloud;
- **Microsoft Purview audit logs** for Copilot/agent activity.

**Re-validate:** Confirm the chosen fallback returns data in your cloud (testing gate T4). *(Beta —
national-cloud availability can expand; re-verify the endpoint's cloud table against current Microsoft
documentation before assuming it is still Gov-unavailable.)*

---

## Branch G — 403 because a license prerequisite is not met (acknowledge, then exclude)

**Symptom:** A–F are clean, but the call still 403s, and the endpoint's reference page states a
**license** prerequisite. For the Package Management API, the **current** docs state:
*"Access to the Package Management API requires a Microsoft Agent 365 license."*

**Owner gate:** License.

**Confirm:**

1. Microsoft 365 admin center → **Billing → Licenses** — check whether the relevant users have the
   license the endpoint's current reference page requires (**Microsoft 365 Copilot**, and for the
   package catalog, **Agent 365**).
2. Note the **volatility**: the original announcement said *"no additional license or add-on is
   required,"* and the reference pages were later changed to require **Agent 365**. Always read the
   requirement from the **current** page, not memory.

**Fix / workaround:** Ensure the required license is assigned. **The customer has already ruled out
Agent 365 licensing as their blocker** — so in this engagement, Branch G is used only to **confirm and
exclude** licensing, then move on to Branch H/J. If a license you do not hold is genuinely required,
that is a product limitation for you today (Branch J), not a bug — use the supported fallback.

**Re-validate:** With licensing confirmed present (or excluded), re-run the probe; if it still fails,
proceed to Branch H. *(Beta — verify the current license requirement on the endpoint reference page.)*

---

## Branch H — 404 because the path, namespace, or version is wrong

**Symptom:** `404 Not Found`. Either `code: notFound` with no matching route, or the resource genuinely
does not resolve. You may have copied a path from a blog, an older doc, or an internal tool.

**Owner gate:** Path / version — the URL does not name a real, current route.

**Confirm:**

1. Compare your URL **character-for-character** against the current reference page: the segments are
   exactly `copilot/admin/catalog/packages` (and `/{id}`) for package management, and
   `copilot/admin/policySettings/{id}` for policy settings. A pluralization, a missing `admin`
   segment, or an invented sub-resource all 404.
2. Confirm the **version**: try the same path on both `/v1.0/` and `/beta/`. The package endpoints
   exist on **both**; a beta-only path called on `/v1.0` (or a route that has since GA'd and moved)
   will 404 on the version that does not host it.
3. **Distinguish a real 404 from a flighting 404.** If the path is provably correct and still 404s,
   this may actually be **Branch R8/F** (not enabled for your tenant/cloud) rather than a typo.
4. For `policySettings`, a `404` with `code: notFound` / *"The setting '…' is not supported"* means the
   **setting id** is not in the supported list — a valid endpoint with an invalid id, not a wrong path.

**Fix / workaround:** Use the exact current path and a version that hosts it. If the path you were told
to use is **undocumented** (not on any current Microsoft Learn reference page), do **not** build a
dependency on it — treat it as not-for-third-party-use and go to Branch J. Never fabricate a
response shape for a path Microsoft does not document.

**Re-validate:** Re-run the probe against the corrected, documented path on the correct version.

---

## Branch I — 429 Too Many Requests (throttling)

**Symptom:** `429 Too Many Requests`, usually with a **`Retry-After`** response header (seconds). It may
appear only under load, in a loop, or when several admins/scripts hit the same tenant.

**Owner gate:** Throttle.

**Confirm:**

1. `CPADMDX-Probe-Endpoint.ps1` reports the `429` and echoes the `Retry-After` value if present.
2. Note that preview endpoints often have **tighter, less predictable** burst limits than GA, and Graph
   throttling is dynamic (varies by app, tenant, workload, endpoint, and time).

**Fix / workaround:** **Honor `Retry-After`** — wait exactly that many seconds, then retry. If no
`Retry-After` is returned, use **exponential backoff** (e.g. 5s, 10s, 20s, capped). Reduce call rate:
batch, cache, page with `$top`, and avoid tight retry loops. Do **not** hammer a `429` — it extends the
throttle.

**Re-validate:** After the backoff, the retry should return `200` (or a different status to branch on).
Confirm your automation now paces itself (best-practices `07`).

---

## Branch J — the data genuinely is not exposed (product limitation)

**Symptom:** A–I are all clean — you authenticate as a delegated admin, with the correct scope,
consent, role, license, path, version, cloud, and no throttling — and yet the endpoint **does not
return the data you need** (it 404s persistently for your tenant, returns an empty/partial payload that
never includes the field you want, or there simply is no documented endpoint for the thing you are
trying to read).

**Owner gate:** Product capability — this is not a configuration bug; the beta surface does not (yet)
expose what you want, or is not intended for your use.

**Confirm:**

1. Reproduce the *clean* call in a **known-enabled** reference tenant (or Graph Explorer with a
   consented admin). If it returns data there but not for you, you are in a **flighting/cloud** gap
   (Branch F / R8), not a true limitation — wait or open a support case.
2. If **no** documented Graph endpoint returns the field/relationship you need (search the current
   Microsoft Learn reference for it and find nothing), or the only path is **undocumented**, treat it
   as **not exposed / not supported for third-party use**. Do not reverse-engineer an internal route.

**Fix / workaround — the supported exit:** stop depending on the beta endpoint and use the supported
alternative that delivers the data you actually need:
- **Microsoft 365 admin center → Agents (Agent Registry)** — the UI inventory and its **export**; use
  this for the agent list/sharing view (and see the sibling *Agent Builder Inventory* product for a
  scheduled export).
- **GA (`/v1.0`) Graph endpoints** — e.g. `copilot/reports/getMicrosoft365CopilotUsageUserDetail`
  (`Reports.Read.All`) for usage/adoption; other GA `copilot` paths as they graduate.
- **Microsoft Purview audit logs** — Copilot and agent activity for compliance/reporting.
- **Microsoft Graph PowerShell** GA cmdlets for whatever adjacent data *is* exposed.

**Re-validate:** Prove the fallback returns the data you need (testing gate T4), and record in
`CPADMDX-Findings.json` that the beta endpoint was excluded as a genuine limitation with the date and
the doc reference — so you can re-check when the API graduates.

---

## After any fix — re-validate, then decide your dependency

Do not stop at the gate you fixed. Re-run **`CPADMDX-Probe-Endpoint.ps1`** and confirm you now get a
**`200`** with the expected object (or a clean, documented non-error like a `200` with `value: null`
for an unconfigured policy setting). Then run the gates in `05-testing.md` to prove the call is
repeatable and to answer the higher question — **is the data actually exposed?** Finally, apply the
GA-vs-beta decision in `07-best-practices.md`: keep beta only as an interim/diagnostic source, prefer
the GA or admin-center path for anything you depend on, and wrap any beta dependency so a future change
fails safe.
