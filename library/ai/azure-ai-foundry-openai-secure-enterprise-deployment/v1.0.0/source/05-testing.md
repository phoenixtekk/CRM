# 5. Testing — Azure AI Foundry & Azure OpenAI: Secure Enterprise Deployment

Validate the platform against a **non-production** Foundry project and Azure OpenAI resource before you expand to production. Each test has an explicit **pass/fail gate**. Reference the scripts by name; they authenticate **keylessly** (`DefaultAzureCredential`) and are read-only except where noted.

## Test 1 — Public network access is disabled
- **How:** `python AIFOUNDRY-Validate.py --account aoai-ent-nonprod ...`, or **Azure OpenAI → Networking** in the portal.
- **Pass:** `publicNetworkAccess` is **Disabled**; the resource shows no usable public endpoint.
- **Fail:** Still **Enabled** → the private endpoint/DNS is not yet in place (Step 4) or the parameter was not set; do **not** flip it to Disabled until the private path works (Test 3), or you lock yourself out.

## Test 2 — Keys are disabled (keyless-only)
- **How:** `AIFOUNDRY-Validate.py` reports `disableLocalAuth`; or try a **key** call and confirm it is rejected.
- **Pass:** `disableLocalAuth` is **true**; an attempted key-based call returns **401** (`AuthenticationTypeDisabled` or similar), while a token call succeeds.
- **Fail:** A key call succeeds → local auth is still enabled; set `disableLocalAuth: true` and redeploy. Both fail → check the role assignment (Test 5) before disabling keys.

## Test 3 — Private endpoint resolves and the private path works
- **How:** From a host **inside the VNet**, `nslookup aoai-ent-nonprod.openai.azure.com`; then run `AIFOUNDRY-ModelSmokeTest.py` from inside the VNet.
- **Pass:** The hostname resolves to the **private IP**; the smoke test returns a completion. From **outside** the VNet the call fails to reach the resource.
- **Fail:** Resolves to a public IP / fails inside the VNet → the private DNS zone isn't linked to this VNet or the endpoint isn't Approved; re-check Step 4 (`Private Endpoint – OpenAI – NonProd`).

## Test 4 — Custom subdomain is set
- **How:** `AIFOUNDRY-Validate.py` reports the endpoint; or **Overview → Endpoint** in the portal.
- **Pass:** Endpoint is `https://aoai-ent-nonprod.openai.azure.com/` (a custom subdomain), which is what makes keyless + private endpoint work (**R3**).
- **Fail:** A shared regional endpoint → the resource was created without a custom subdomain; it must be **recreated** with `customSubDomainName` (cannot be added after creation).

## Test 5 — Least-privilege data-plane RBAC is assigned
- **How:** `AIFOUNDRY-Validate.py` reports role assignments on the resource; or **Access control (IAM) → Role assignments**.
- **Pass:** **`OpenAI User – AI App – NonProd`** assigns **Cognitive Services OpenAI User** to **`Managed Identity – AI App – NonProd`** at the resource scope; app identities have **User**, not Contributor/Owner.
- **Fail:** Missing → the smoke test returns 403; assign the role (Step 5). Over-privileged (Contributor/Owner on an app identity) → tighten to User.

## Test 6 — Model deployment has an explicit quota and a content filter
- **How:** `AIFOUNDRY-Validate.py` / `AIFOUNDRY-Report.ps1` list deployments, their **TPM capacity**, and the attached content-filter policy; or **Deployments** in the portal.
- **Pass:** **`gpt-4o Deployment – Chat – NonProd`** exists with a **non-zero, bounded TPM** and the content-filter policy **`Content Filter – Standard – NonProd`** attached.
- **Fail:** No TPM ceiling / no filter attached → the deployment is unbounded or unguarded; redeploy the model block (Step 6). *If a model/version is unavailable in the region, verify current availability (R1).*

## Test 7 — The content filter actually blocks
- **How:** Send a deliberately disallowed prompt via the smoke test's `--filter-check` mode (safe, canned test prompt) and observe the response.
- **Pass:** The request is **filtered** (content-filter error / finish reason `content_filter`), proving the guardrail is live at the configured thresholds.
- **Fail:** Disallowed content passes → the deployment has no policy attached or thresholds are permissive; re-check Step 6 and **R7**. *Acceptable thresholds are your trust-and-safety decision.*

## Test 8 — Diagnostics flow and the budget exists
- **How:** After a test call, run a resource-log query in **`Log Analytics – AI Platform – NonProd`**; check **Cost Management → Budgets**.
- **Pass:** The test request appears in Log Analytics within a few minutes; **`Budget – AI Platform – NonProd`** exists with alert recipients.
- **Fail:** No logs → the diagnostic setting isn't pointed at the workspace (Step 7). No budget → create it (Step 7); an AI platform without a spend alarm is a bill-shock risk.

## Test 9 — Deployment stack tracks and can roll back
- **How:** `az stack sub show --name aifoundry-stack-nonprod`.
- **Pass:** The stack lists its managed resources; a `what-if` of `az stack ... delete`/`update` shows exactly what would change.
- **Fail:** Stack not found → you deployed with plain `az deployment` instead of `az stack`; redeploy via the stack so rollback is available.

## Test 10 — Pipeline enforces what-if and approval
- **How:** Push a trivial parameter change on a branch; open a PR; watch the pipeline.
- **Pass:** **Validate** and **What-If** run automatically and post the preview; **Deploy** pauses at the approval gate and proceeds only after sign-off.
- **Fail:** Deploy runs without pausing → the environment approval check isn't attached to the production stage; fix in the pipeline environment configuration.

## Exit criteria
All ten tests pass against the non-production resource — public access disabled with a working private path, keyless-only auth, least-privilege RBAC, a quota-bounded and content-filtered deployment, live diagnostics and a budget, stack rollback available, and an approval-gated pipeline — **only then** expand to production and onboard further projects and models.
