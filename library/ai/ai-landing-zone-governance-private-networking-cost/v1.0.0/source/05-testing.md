# Testing & Validation — AI Landing Zone & Governance (Private Networking, Content Safety, Cost)

Validate the landing zone against explicit **pass/fail gates** before you **enforce** the policy
guardrails or **expand** beyond the pilot scope. Run the helpers and walk the manual checks. Do not
proceed to **Expand** until every gate passes. The automated gates are produced by
**`AILZ-Validate.ps1`**; posture and cost evidence come from **`AILZ-Report.ps1`**; readiness from
**`AILZ-Discovery.ps1`**; and every change went through the plan/what-if-first pipeline
**`azure-pipelines.yml`** (with `main.tf` as the source of truth).

Each gate lists **What good looks like / How to test / If it fails**.

---

## Gate 1 — The hub/spoke network and peering exist

- **What good looks like:** `vnet-ailz-hub-platform` and `vnet-ailz-spoke-nonprod` exist with the
  agreed CIDRs, `snet-ailz-privateendpoints` and `snet-ailz-aiworkload` subnets are present, and
  `peer-ailz-hub-to-spoke` / `peer-ailz-spoke-to-hub` are **Connected**.
- **How to test:** `AILZ-Validate.ps1` lists the VNets, subnets, and peering state.
- **If it fails:** Re-check the address plan (R2) for overlap and re-apply the network resources
  (Phase 2); peering fails if address spaces overlap.

## Gate 2 — Private DNS zones exist and are linked to the VNets

- **What good looks like:** The five `privatelink.*` zones are present (or your central zones are
  linked) and each is **VNet-linked** to the hub/spoke.
- **How to test:** `AILZ-Validate.ps1` lists the private DNS zones and their VNet links.
- **If it fails:** Create or link the zones (R3); an unlinked zone means the private hostname won't
  resolve to the private IP. *Verify the current privatelink zone names.*

## Gate 3 — AI service and Key Vault are private (public access disabled)

- **What good looks like:** The pilot AI (Cognitive Services / OpenAI) account and
  `kv-ailz-nonprod-<suffix>` have **public network access = Disabled**, each with a private endpoint
  (`pep-ailz-openai-nonprod`, `pep-ailz-keyvault-nonprod`) in `snet-ailz-privateendpoints`.
- **How to test:** `AILZ-Validate.ps1` checks `publicNetworkAccess = Disabled` and lists the private
  endpoints and their connection state.
- **If it fails:** Disable public access and add/repair the private endpoint (Phase 2). A service with
  public access ON is the exact risk this zone removes.

## Gate 4 — The AI hostname resolves to a private IP

- **What good looks like:** From inside the spoke, the AI service's hostname
  (`<name>.openai.azure.com`) resolves to a **private IP** in `snet-ailz-privateendpoints`, not a
  public one.
- **How to test:** `AILZ-Validate.ps1` runs a read-only **private-resolution probe** (a DNS lookup /
  private-endpoint DNS-record check) and reports the resolved address. *The probe is read-only and
  designed to be safe — verify it suits your environment; running it from outside the VNet will not
  see the private record.*
- **If it fails:** Confirm the private DNS zone is linked (Gate 2) and the private endpoint's DNS
  A-record exists; fix the zone/VNet link.

## Gate 5 — The workload authenticates keyless (managed identity + RBAC)

- **What good looks like:** `id-ailz-aiworkload-nonprod` holds the **Cognitive Services OpenAI User**
  (and, for secrets, **Key Vault Secrets User**) role at the correct scope, and no API keys are used
  in workload config.
- **How to test:** `AILZ-Validate.ps1` lists the managed identity's role assignments and flags the
  presence of a keyless path.
- **If it fails:** Assign the least-privilege data-plane role to the managed identity and remove any
  key usage (category G2).

## Gate 6 — The policy initiative is assigned and reporting (audit mode)

- **What good looks like:** `AILZ-AI-Guardrails-Initiative` is assigned at the pilot scope with its
  five `Policy-*-AILZ` assignments in **`DoNotEnforce` (audit)** mode, and a **compliance evaluation**
  has produced results.
- **How to test:** `AILZ-Validate.ps1` confirms the assignment exists, its enforcement mode is
  `DoNotEnforce`, and `AILZ-Report.ps1` shows per-policy compliance. *Any definition that is preview/
  absent in your cloud is flagged as not-assigned — verify availability.*
- **If it fails:** Re-assign the initiative (Step 2.2); wait for evaluation; investigate any policy
  that failed to assign (definition may be unavailable in your cloud).

## Gate 7 — Content-safety default and responsible-AI posture are in place

- **What good looks like:** The content-safety posture is applied at the platform (the
  `Policy-ContentSafetyOn-AILZ` assignment reports it, and the pilot AI service has the content-safety
  default), pending the deeper configuration in the companion Content-Safety solution.
- **How to test:** `AILZ-Validate.ps1` checks the content-safety policy assignment and the pilot
  service's content-safety signal. *Content-safety features / some responsible-AI tooling may be
  preview — verify current availability. Acceptable-content thresholds are the customer's trust-and-
  safety decision.*
- **If it fails:** Confirm the content-safety default is enabled and the policy assignment is present;
  defer threshold decisions to the customer's trust-and-safety function.

## Gate 8 — Budget, alerts, and usage dashboard exist

- **What good looks like:** `Budget-AILZ-Platform` exists with alert thresholds wired to
  `ag-ailz-cost-alerts`, and `Workbook-AILZ-AIUsage` shows the pilot AI spend.
- **How to test:** `AILZ-Validate.ps1` confirms the budget and thresholds; `AILZ-Report.ps1` shows
  current spend vs budget and the usage workbook.
- **If it fails:** Create the budget + action group and confirm the workbook's Log Analytics source
  (`log-ailz-platform`). *Spend thresholds are the customer's FinOps decision.*

## Gate 9 — Every change was plan/what-if-first and state is protected

- **What good looks like:** No portal click-ops changed the foundation; each apply followed a reviewed
  `terraform plan` behind the pipeline's approval gate; remote state is encrypted, versioned, and
  locked.
- **How to test:** Confirm the pipeline's plan/approval/apply history and that `apply` required the
  Environment approval; confirm the state backend is an encrypted, versioned Azure Storage container.
- **If it fails:** Bring drift back under Terraform (`terraform plan` shows drift), stop out-of-band
  portal changes, and protect the state backend (R6).

---

### Validation summary

| Gate | Check | Pass condition |
| --- | --- | --- |
| 1 | Hub/spoke + peering | VNets/subnets exist; peerings Connected |
| 2 | Private DNS linked | Five `privatelink.*` zones VNet-linked |
| 3 | AI + Key Vault private | `publicNetworkAccess=Disabled` + private endpoints |
| 4 | Private resolution | AI hostname resolves to a private IP |
| 5 | Keyless identity | Managed identity holds data-plane roles; no keys |
| 6 | Policy initiative reporting | Assigned in `DoNotEnforce`; compliance produced |
| 7 | Content-safety default | Content-safety assignment + service default present |
| 8 | Budget + usage | `Budget-AILZ-Platform` + `Workbook-AILZ-AIUsage` exist |
| 9 | Plan-first + state protected | Reviewed plans; encrypted/locked remote state |

All nine gates pass ⇒ proceed to **Expand** (flip policies to enforce, extend to the management
group). Any fail ⇒ stay in the pilot scope, keep policies in audit, and remediate the gate first.
