# 6. Troubleshooting — Azure AI Foundry & Azure OpenAI: Secure Enterprise Deployment

Common failures during a secure Azure OpenAI / AI Foundry rollout, as **symptom → cause → fix**. Re-run `AIFOUNDRY-Validate.py` after any fix to re-check the gates.

## Access, resource creation, and region
**Symptom:** You can't create the Azure OpenAI resource, or the SKU/kind isn't offered.
**Cause:** The subscription isn't approved for the AI service, or the resource isn't offered in the region (**R1**).
**Fix:** Request access to the AI service if your tenant still gates it; pick a region that offers Azure OpenAI. `az cognitiveservices account list-skus --kind OpenAI --location <region>`. *Verify current access requirements and regional availability.*

**Symptom:** Model deployment fails with a quota/capacity error.
**Cause:** No TPM quota left for that model in the region, or you requested more capacity than granted (**R5**).
**Fix:** Lower the deployment `capacity`, request a quota increase for the model/region, or deploy in a region with headroom. Pilot with a small TPM and raise deliberately.

## Custom subdomain (the keyless + private-endpoint prerequisite)
**Symptom:** Managed-identity auth returns 401, or you can't attach a private endpoint the expected way.
**Cause:** The resource was created **without a custom subdomain**; the endpoint is a shared regional URL (**R3**).
**Fix:** `customSubDomainName` generally **cannot be added after creation** — recreate the resource with it set (the Bicep does this). `AIFOUNDRY-Discovery.ps1` flags resources with no subdomain.

## Keyless / RBAC (401 / 403)
**Symptom:** Your app or `AIFOUNDRY-ModelSmokeTest.py` gets **401 Unauthorized** / **403 PermissionDenied** calling the model.
**Cause:** The identity has no data-plane role on the resource; with `disableLocalAuth: true` there is **no key fallback** (**R4**, Test 5).
**Fix:** Assign **Cognitive Services OpenAI User** to the app's managed identity at the resource scope (`OpenAI User – AI App – NonProd`). Wait for the assignment to propagate (can take a few minutes), then retry.

**Symptom:** A key-based call used to work and now returns `AuthenticationTypeDisabled` (or similar).
**Cause:** `disableLocalAuth: true` turned keys off — this is intended (Test 2).
**Fix:** Switch the caller to token auth (`DefaultAzureCredential` + the `https://cognitiveservices.azure.com/.default` scope), as the smoke-test script shows. Do **not** re-enable local auth.

**Symptom:** `DefaultAzureCredential` can't get a token locally.
**Cause:** You're not logged in, or no managed identity is available in the runtime.
**Fix:** `az login` for local runs; ensure the managed identity is assigned to the compute (VM/App Service/AKS/CI agent) for runtime. Confirm the identity holds the OpenAI User role.

## Private endpoint / DNS / networking
**Symptom:** After disabling public access, apps can't reach the resource at all.
**Cause:** Public access was disabled **before** a working private endpoint + DNS existed (Test 1 warning), or the caller is outside the VNet.
**Fix:** Ensure `Private Endpoint – OpenAI – NonProd` is **Approved** and the private DNS zone is linked to the caller's VNet; run apps/scripts **inside** the VNet. Order matters: prove the private path, *then* disable public access.

**Symptom:** `nslookup <account>.openai.azure.com` returns a public IP from inside the VNet.
**Cause:** The private DNS zone (`privatelink.openai.azure.com` — *verify the exact zone name for your cloud*) isn't linked to that VNet, or the A record wasn't created by the DNS zone group.
**Fix:** Confirm the zone name, that the VNet has a **virtual network link** to the zone, and that the endpoint's **DNS configuration** created the A record; re-check with `AIFOUNDRY-Discovery.ps1`.

**Symptom:** The private endpoint can't be created on the subnet.
**Cause:** `privateEndpointNetworkPolicies` blocks it, or the subnet is full (**R2**).
**Fix:** Adjust the subnet's private-endpoint network policy and ensure address space; the discovery script reports both per subnet.

## Model deployment / content filter
**Symptom:** The model/version in the Bicep no longer deploys.
**Cause:** The model or version was retired or isn't offered in the region — model availability changes.
**Fix:** *Verify current model + version availability in your region* and update `modelName`/`modelVersion` parameters; re-`what-if` before deploy.

**Symptom:** A clearly disallowed prompt is **not** filtered (Test 7 fail).
**Cause:** No content-filter policy is attached to the deployment, or thresholds are permissive (**R7**).
**Fix:** Attach `Content Filter – Standard – NonProd` to the deployment and set thresholds to your trust-and-safety decision; redeploy the model block. *Some filter features are in preview — verify availability.*

**Symptom:** Legitimate prompts are being over-blocked after tightening the filter.
**Cause:** Thresholds set too strict for the workload.
**Fix:** This is a trust-and-safety tuning decision, not a bug — adjust thresholds deliberately and re-test. Change it as a parameter through the pipeline, not a portal click on prod.

## Monitoring / cost
**Symptom:** No requests appear in Log Analytics after test calls.
**Cause:** The diagnostic setting isn't pointed at the workspace, or the wrong log category is enabled (Test 8).
**Fix:** Confirm `Diagnostics – OpenAI – NonProd` targets `Log Analytics – AI Platform – NonProd` with the request/audit categories; wait a few minutes for ingestion. *Verify current diagnostic category names.*

**Symptom:** Spend climbed with no warning.
**Cause:** No budget/alert, or TPM set too high (**R5/R6**).
**Fix:** Create `Budget – AI Platform – NonProd` with alert recipients; cap each deployment's TPM to a deliberate ceiling. `AIFOUNDRY-Report.ps1` shows budget status and per-deployment TPM.

## Deployment stacks / IaC
**Symptom:** `az stack sub show` reports the stack is missing after you deployed.
**Cause:** You deployed with `az deployment sub create` instead of `az stack sub create`, so there's no rollback unit (Test 9).
**Fix:** Redeploy via `az stack sub create` with the named stack so resources are tracked and rollback is available.

**Symptom:** `what-if` shows unexpected **Delete/Modify** on the resource.
**Cause:** A parameter changed the resource name (ARM sees a replace), or a stack-managed resource was edited in the portal (drift).
**Fix:** **Stop — do not approve.** Diff the parameter files, run `AIFOUNDRY-Report.ps1` for drift, reconcile, then re-`what-if` until clean.

**Symptom:** `az stack` / `az bicep` is "not a recognized command," or the Foundry resource types don't resolve.
**Cause:** Azure CLI / Bicep too old, or the Foundry hub/project resource model differs from the template (**R8**, Overview note).
**Fix:** `az bicep upgrade` and update the CLI; *verify the current AI Foundry resource types and apiVersions for your tenant/cloud* and adjust the template. Pin versions in the repo.

## Pipeline
**Symptom:** The Deploy stage runs without pausing for approval.
**Cause:** The environment approval check isn't attached to the production stage (Step 9).
**Fix:** Add required reviewers to the production environment and confirm the deploy job references it; re-run (Test 10).

**Symptom:** Pipeline auth fails with a token/credential error.
**Cause:** The service connection isn't configured for workload identity federation, or its subject/scope is wrong (**G5**).
**Fix:** Reconfigure the service connection for OIDC/workload identity federation, scoped to the deployment target; never fall back to a stored secret.
