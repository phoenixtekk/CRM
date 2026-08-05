# Troubleshooting

This is the **blocked/failed-request decision tree** for the customer's exact situation. Start at T1,
read the HTTP status, and follow the branch. The goal is to tell the causes apart — permission vs role
vs Agent 365 entitlement vs feature-not-enabled vs undocumented-use vs a genuine product limitation — so
you fix the real one instead of guessing.

## T1 — First, capture the exact status code and the endpoint

The single most useful action is to see the raw HTTP status. Run the preflight
(`AGBINV-Connect-Preflight.ps1`) or call the endpoint directly:

```
Connect-MgGraph -Environment Global -Scopes CopilotPackages.Read.All
Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/copilot/admin/catalog/packages?$top=1'
```

- Confirm the **URL/namespace** is `/copilot/admin/catalog/packages` (correct) — not `/admin/...` or
  `/solutions/...`.
- Note the status: **`401`** → T2. **`403`** → T3–T6. **`404`** → T7. **`200` but wrong/empty data** →
  T8–T9.

## T2 — `401 Unauthorized`: it is the token, not permissions

- **Symptom:** `401` before any data check.
- **Cause:** No token, an expired token, or a token minted for the wrong cloud (e.g. a Commercial token
  against `graph.microsoft.us`).
- **Fix:** Re-run `Connect-MgGraph` with the correct `-Environment` for your tenant (R7). Confirm the
  token audience is `https://graph.microsoft.com` (or the `.us` host for Government). Do not touch roles
  or scopes yet — a `401` never means the role is wrong.

## T3 — `403` decision: is it the SCOPE, the ROLE, the ENTITLEMENT, or the ROLLOUT?

A `403` means "authenticated but not allowed," and four different causes produce it. Work them in this
order — the preflight prints them in the same priority:

1. **Scope / consent (most common — this is usually the customer's cause).** Decode the token at
   `jwt.ms` and check the `scp` claim for **`CopilotPackages.Read.All`**. If it is absent, the scope was
   not requested or admin consent was never granted. → T4.
2. **Admin role.** If the scope is present, confirm the signed-in identity holds a qualifying role
   (**AI Administrator**, Global Administrator, Cloud Application Administrator, Application
   Administrator, or Copilot Administrator). A correct scope with an unqualified role still returns
   `403`. → T5.
3. **Agent 365 entitlement.** If both scope and role are correct and you *still* get `403`, the current
   docs' **Microsoft Agent 365** requirement for this API (R4) is the leading suspect. → T6.
4. **Feature not rolled out.** A tenant that has not received the API can also surface `403` at the
   backend before permission evaluation. → T7 (usually presents as `404`, sometimes `403`).

## T4 — `403` caused by missing scope or consent

- **Symptom:** `scp` claim lacks `CopilotPackages.Read.All`.
- **Cause:** The delegated app never requested the scope, or a Global Administrator never consented to it
  for the tenant, or (application flow) the app permission was added but consent not granted.
- **Fix:**
  - **Delegated:** run `Connect-MgGraph -Scopes CopilotPackages.Read.All`; on the consent prompt, a
    Global Administrator selects **Consent on behalf of your organization**. Re-acquire the token and
    retry.
  - **Application:** in the Entra app **`AGBINV – Agent Governance – Graph Reader`** > **API permissions**
    > add **`CopilotPackages.Read.All`** (Application) > **Grant admin consent for <tenant>** (state must
    read *Granted*). Re-run.
- **Confirm:** the `scp`/`roles` claim now contains the scope and the call returns `200` (or advances to
  the next `403` cause).

## T5 — `403` caused by an insufficient admin role

- **Symptom:** Scope is present, but `403` persists.
- **Cause:** The account lacks a qualifying admin role, or the role was assigned after the current token
  was issued.
- **Fix:** Assign **AI Administrator** (least-privileged practical choice) in **Entra admin center** >
  **Roles & administrators** > **AI Administrator** > **Add assignments**; then **sign out and back in**
  so the new role is reflected in a fresh token. Retry.
- **Confirm:** `(Get-MgContext)` shows the account, and the call returns `200` (or advances to T6).

## T6 — `403` caused by the Microsoft Agent 365 entitlement (verify — you ruled this out)

- **Symptom:** Scope **and** role are both correct, the API is live for the tenant (other Copilot admin
  APIs work), yet packages still returns `403`.
- **Cause:** The **current** Microsoft Learn pages state the Package Management API **requires a
  Microsoft Agent 365 license**. If the entitlement is enforced and absent, this is the residual `403`.
- **You told us Agent 365 is ruled out.** Take that at face value for your decision, but verify honestly:
  check **Microsoft 365 admin center** > **Billing** > **Licenses/Subscriptions** for an Agent 365 /
  agent-management subscription. If it is genuinely absent **and** scope+role are correct, then the
  supported programmatic path is currently gated for your tenant.
- **Fix / path forward:** Use **Path A — the Microsoft 365 admin center Agent Registry Export to CSV**
  (Implementation Step 5). It produces the Agent Builder inventory **without** Agent 365. The granular
  `allowedUsersAndGroups` sharing detail from Path B becomes available only if/when the entitlement is in
  place. *(Verify against current Microsoft documentation — Microsoft may change this entitlement as the
  API matures; re-test Path B after any change.)*

## T7 — `404` (or backend `403`): the API is not rolled out to your tenant/cloud

- **Symptom:** `404 Not Found` on a correctly-formed `/copilot/admin/catalog/packages` URL with a valid
  token and qualifying role; or a `403` that persists after T4–T6 are cleanly ruled out.
- **Cause:** The Package Management API released **tenant-by-tenant**; your tenant has not received it
  yet. Or you are in a **Government cloud** (GCC High L4 / DoD L5) where the API is **not available at
  all** (R7).
- **Fix:** There is no self-service switch to force earlier availability. Use **Path A** now and re-test
  Path B after Microsoft confirms general availability for your cloud (track **Message Center MC1173195**
  and Microsoft Learn). In Government clouds, Path A is the standing method — do not wait for Path B.
  **Verify for GCC High.**
- **Confirm:** re-running the preflight later returns `200` once the tenant is enabled.

## T8 — `200` but the result is empty or missing agents

- **Symptom:** The call succeeds but returns few or no Agent Builder agents.
- **Causes and fixes:**
  - **Legitimately empty** — no Agent Builder agents exist yet (R5). Confirm in the admin center Registry
    under *Shared by creator* / Platform = *Microsoft 365 Copilot Agent Builder*.
  - **Over-filtered** — the `platform`/`elementTypes` filter excluded valid agents (e.g. a casing or
    value mismatch). Re-list without the filter, inspect the `platform` values actually returned, then
    reapply the exact string `Microsoft 365 Copilot Agent Builder`.
  - **Paging dropped** — the script did not follow `@odata.nextLink`, so only the first page returned.
    Confirm the export loops until `nextLink` is null (Gate 4).

## T9 — `200` on the list, but no per-user sharing appears

- **Symptom:** The inventory lists agents, but the sharing export shows empty recipients.
- **Causes and fixes:**
  - **You only called the list endpoint.** The list `copilotPackage` object exposes `availableTo` /
    `deployedTo` as `all`/`some`/`none` — **not** the recipients. You must call **`GET .../packages/{id}`**
    per agent to read **`allowedUsersAndGroups`** (Implementation Step 4). This is the #1 reason "sharing
    is missing."
  - **Org-wide share.** An agent shared with **Anyone in your organization** has `availableTo = all` and
    may carry no explicit per-user entries — that is correct; the register labels it **Org-wide shared**,
    not blank.
  - **Unresolved object IDs.** Recipients show as raw GUIDs when the account cannot read `GET /users/{id}`
    / `GET /groups/{id}`. Grant the resolver directory read (a Global/Directory Reader-level scope) and
    re-run (Gate 6).

## T10 — Distinguishing an undocumented/wrong endpoint from a real limitation

- **If you used a different path** (e.g. `/beta/admin/...` or a `/solutions/...` guess), you will get
  `404` because the resource does not exist — that is a **wrong-endpoint** error, not a limitation. The
  correct, documented namespace is `/copilot/admin/catalog/packages` (list) and `/{id}` (detail).
- **A genuine product limitation** (as opposed to a fixable block) is narrow: the API returns the
  **allowed audience** (`allowedUsersAndGroups`), **not** a runtime log of who actually opened or ran the
  agent. If your requirement is *usage* rather than *who it is shared with*, that data is not in this API
  — source it from Copilot usage reporting or the unified audit log instead. Everything else the customer
  asked for (inventory + sharing recipients, filtered to Agent Builder) **is** supported; the failures
  are blocks to clear (T4–T7), not dead ends.
