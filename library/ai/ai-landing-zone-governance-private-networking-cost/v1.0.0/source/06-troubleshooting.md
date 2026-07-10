# Troubleshooting — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

The common failure modes, each as **symptom → cause → fix**. Most issues are DNS/private-endpoint
wiring, policy scope/mode, or OIDC/state — not a broken service.

---

## 1. The AI (or Key Vault) hostname still resolves to a PUBLIC IP

- **Symptom:** From inside the spoke, `<name>.openai.azure.com` (or the vault hostname) resolves to a
  public address; `AILZ-Validate.ps1` Gate 4 is not PASS.
- **Cause:** The `privatelink.*` **private DNS zone isn't linked to the VNet**, or the private
  endpoint's DNS A-record wasn't created — so the public CNAME wins.
- **Fix:** Confirm the correct zone (e.g. `privatelink.openai.azure.com`) is **VNet-linked** to both
  hub and spoke (Gate 2), and the private endpoint has a `private_dns_zone_group`. If you use **central**
  DNS zones (R3), set `create_private_dns_zones = false` and link there instead. *Verify the current
  privatelink zone name for the service.* Run the probe **from inside the VNet** — from outside you'll
  always see the public record.

## 2. `terraform apply` — VNet peering fails

- **Symptom:** `peer-ailz-hub-to-spoke` / `peer-ailz-spoke-to-hub` won't reach **Connected**.
- **Cause:** **Overlapping address space** between the hub and spoke (or with an already-peered
  network), or only one side of the peering was created.
- **Fix:** Re-check the address plan (R2) — hub and spoke CIDRs must not overlap each other or any
  peered network; `AILZ-Discovery.ps1` lists existing VNet address spaces. Both peering directions must
  exist. Re-apply.

## 3. Private endpoint stuck in "Pending" approval

- **Symptom:** `pep-ailz-openai-nonprod` / `pep-ailz-keyvault-nonprod` shows connection state
  **Pending**, and traffic doesn't flow.
- **Cause:** The target resource is in a **different subscription/tenant** or has **manual private-
  endpoint approval** enabled, so the connection needs an owner to approve it.
- **Fix:** Approve the private-endpoint connection on the target resource (or set
  `is_manual_connection = false` when you own both sides). Confirm the connection state is
  **Approved**.

## 4. A policy is blocking legitimate work after you enforced it

- **Symptom:** After flipping a guardrail to enforce, valid deployments are **denied** (wrong region,
  a model you meant to allow, a missing tag).
- **Cause:** The allow-lists (`Policy-AllowedRegions-AILZ`, `Policy-AllowedModels-AILZ`) or the
  required-tag set don't match reality, or you enforced before validating in audit.
- **Fix:** The guardrails ship in **audit (DoNotEnforce)** mode for exactly this reason. Set the
  assignment's `enforcement_mode` back to `DoNotEnforce`, correct the allow-lists (R4), review the
  compliance report (`AILZ-Report.ps1`), and re-enforce. For a one-off legitimate exception, create a
  scoped **Azure Policy exemption** rather than weakening the policy.

## 5. A guardrail policy definition "doesn't exist" / can't be assigned

- **Symptom:** `terraform apply` errors that a policy **definition ID** isn't found, or a guardrail
  (private-only / allowed-models / content-safety) didn't make it into the initiative.
- **Cause:** The **built-in definition is preview, renamed, or absent in your cloud** (definitions
  differ between Commercial and GCC/GCC-High and evolve over time).
- **Fix:** `Get-AzPolicyDefinition | Where-Object {$_.Properties.DisplayName -like '*<term>*'}` to find
  the current definition, put the **verified ID** into the `local.guardrail_definition_ids` map in
  `main.tf` (an empty value drops that reference so the initiative still assigns). If no built-in fits,
  author a **custom** definition. *Verify current AI/content-safety policy availability for your cloud.*

## 6. The pipeline can't authenticate to Azure (OIDC)

- **Symptom:** `terraform init`/`plan` fails with an auth error; the service connection can't get a
  token.
- **Cause:** The ARM service connection isn't configured for **workload identity federation**, the
  federated-credential subject doesn't match the pipeline, or the identity lacks rights at the scope
  (R1).
- **Fix:** Recreate the service connection using **workload identity federation (OIDC)**, confirm the
  federated credential's subject matches the pipeline/environment, and grant the identity **Owner or
  Contributor + User Access Administrator** at the target scope. Never fall back to a stored client
  secret.

## 7. `terraform init` fails on the backend / state is local

- **Symptom:** `init` errors on the `azurerm` backend, or state is sitting on the laptop.
- **Cause:** The remote-state Storage account/container isn't provisioned or the `backend "azurerm"`
  block isn't filled in (R6).
- **Fix:** Bootstrap the **encrypted, versioned** Storage account + container first, fill in the
  backend block (with `use_oidc = true`), and `terraform init`. **Never** run the foundation on local
  state.

## 8. The workload gets 401/403 calling the AI service (keyless)

- **Symptom:** The app authenticates with managed identity but is **denied** by Azure OpenAI / the
  vault.
- **Cause:** The **data-plane RBAC role** isn't assigned (or not at the right scope), or RBAC
  propagation hasn't completed. Key-based auth may also be disabled (as intended) while the role is
  missing.
- **Fix:** Confirm `id-ailz-aiworkload-nonprod` holds **Cognitive Services OpenAI User** at the AI
  resource scope (and **Key Vault Secrets User** on the vault), then wait for propagation. Data-plane
  roles are distinct from control-plane Contributor. `AILZ-Validate.ps1` Gate 5 lists the identity's
  roles.

## 9. Budget exists but no alerts arrive

- **Symptom:** `Budget-AILZ-Platform` is set but owners never get notified as spend climbs.
- **Cause:** The **action group** (`ag-ailz-cost-alerts`) has no receivers (the
  `budget_alert_emails` variable was left empty), or the notification thresholds aren't wired to it.
- **Fix:** Set `budget_alert_emails` and confirm the budget's notifications reference
  `ag-ailz-cost-alerts`. *Cost data can lag — verify current billing latency; spend thresholds are the
  customer's FinOps decision.*

## 10. GCC / GCC-High: a service, policy, or model isn't available

- **Symptom:** A resource, policy definition, or model that works in Commercial fails or is missing in
  a government cloud.
- **Cause:** **Feature, policy, model, and region parity differs by cloud**; some AI services and
  content-safety features aren't yet in GCC/GCC-High.
- **Fix:** Sign in with the correct environment (`Connect-AzAccount -Environment
  AzureUSGovernment`), set the matching endpoints in the provider/backend, and **verify availability**
  per service before you plan. Substitute a supported region/model where needed. *Verify cloud-specific
  availability, endpoints, and pricing.*

## 11. Unexpected foundation cost

- **Symptom:** Bills climb after the landing zone goes in, before any real workload.
- **Cause:** **Private endpoints**, **Log Analytics ingestion/retention**, Key Vault operations, and
  any AI services placed in the zone all bill, and cost scales with traffic and workloads.
- **Fix:** Right-size Log Analytics retention (`log-ailz-platform`), review spend per resource group
  with `AILZ-Report.ps1`, and set quotas (e.g. Azure OpenAI tokens-per-minute). *Verify current Azure
  pricing for your cloud — pricing changes. Cost trade-offs are a customer FinOps decision.*
