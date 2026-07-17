# 5. Testing Guide — Managed Identities for Azure Logic Apps & Functions

Run after Implementation Step 5 (validate) and again after each migration (Step 6) and expansion (Step 7). Objects are referenced by their `<Purpose> – <Scope> – <Stage>` names. Each test is **PASS/FAIL**.

## Test 1 — Managed identity enabled on the compute
**Do:** `portal.azure.com` → the Logic App `Graph Automation LogicApp – Contoso – Pilot` and the Function App `Graph Automation FuncApp – Contoso – Pilot` → **Identity** blade; or run `MIM365-Validate.ps1`.
**Expected (PASS):** Each resource has a **system-assigned** identity **On**, or the user-assigned `Graph Automation Identity – Contoso – Prod` attached.
**FAIL:** No identity present → return to Implementation Step 1.

## Test 2 — Least-privilege app-role granted (and nothing broader)
**Do:** Run `MIM365-Validate.ps1`; or Entra → **Enterprise applications** → the managed identity → **Permissions**.
**Expected (PASS):** The identity holds exactly the intended application permission (e.g. `Mail.Read`, recorded as `Mail.Read App Grant – Graph Automation Identity – Prod`) and **no additional** application permissions.
**FAIL:** Missing grant, or extra permissions beyond least privilege → fix in Implementation Step 2.

## Test 3 — Logic App authenticates to Graph with the identity
**Do:** Trigger `Graph Automation LogicApp – Contoso – Pilot`; inspect the HTTP action run.
**Expected (PASS):** The HTTP action's **Authentication type = Managed identity**, no connector/secret is used, and the call returns **200** with the expected Graph payload.
**FAIL:** 401/403, or a stored connection is in use → check the grant (Test 2), the audience, and that Authentication type is Managed identity.

## Test 4 — Azure Function authenticates to Graph with the identity
**Do:** Invoke `Graph Automation FuncApp – Contoso – Pilot`.
**Expected (PASS):** The Function returns the expected Graph result using `DefaultAzureCredential` / `ManagedIdentityCredential`, with **no secret in app settings or code**.
**FAIL:** Credential does not resolve, or 401/403 → confirm the identity is attached and (for user-assigned) that the correct **Client ID** is passed; check the granted app-role.

## Test 5 — No stored credential remains on migrated flows
**Do:** Run `MIM365-Find-StoredCredentials.ps1` against the migrated workflow.
**Expected (PASS):** The workflow no longer appears on the stored-credential worklist — no saved service-account connection and no client secret.
**FAIL:** The workflow still lists a stored credential → complete the credential removal in Implementation Step 6.

## Test 6 — Secret-based flow migrated with parity
**Do:** Compare the migrated flow's output against the original secret-based flow for the same input (the Graph result it produced before cutover).
**Expected (PASS):** The managed-identity flow returns the **same result** the secret-based flow did — functional parity — and the stored credential has been retired.
**FAIL:** Behaviour differs → keep the rollback in place, reconcile the Graph call, and re-test before removing the credential.

## Test 7 — Least-privilege boundary holds
**Do:** From the identity, attempt a Graph call the granted permission does **not** authorize (e.g. writing mail when only `Mail.Read` is granted, or reading a mailbox excluded by the #4 scoping).
**Expected (PASS):** The unauthorized call is **denied** (403 / insufficient privileges) — proof the identity is bounded to least privilege (and, for mailboxes, to the #4 scope).
**FAIL:** The call succeeds → the identity is over-permissioned; remove the extra grant (Step 2) and apply #4 mailbox scoping.

## Test 8 — Estate inventory report
**Do:** Run `MIM365-Report.ps1`.
**Expected (PASS):** A clear identity/permission inventory across the estate (each Logic App/Function, its identity, its app-roles) plus a CSV, with the stored-credential worklist trending toward zero.
**FAIL:** Report empty or errors → confirm Microsoft.Graph connectivity and scopes.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass — the identity authenticates to Graph from **both** a Logic App and a Function, least-privilege confirmed |
| **Migration pass** | Tests 5–6 pass — a secret-based flow is migrated with parity and its stored credential retired |
| **Least-privilege pass** | Test 7 passes — an unauthorized call is denied |
| **Expand pass** | Tests 1–3/4, 8 pass on each newly onboarded workflow before the next expansion |
