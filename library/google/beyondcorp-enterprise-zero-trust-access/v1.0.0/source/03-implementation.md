# 3. Implementation — BeyondCorp Enterprise: Zero-Trust Access

Follow the house model **Assess → Design → Configure → Pilot → Validate → Expand**, pilot-first. Name
every artifact with `<Purpose> – <Scope> – <Stage>` and reuse the exact name in later steps, testing,
and the scripts. Commands below use the **Google Cloud Console** and the **`gcloud` CLI**; where a
capability is version- or preview-dependent it is flagged **verify** — confirm the current path in your
own organization rather than assuming it. The **provided Python tools** (see §8) automate the read-only
assessment, dry-run configuration, validation, and guardrail checks referenced here.

Set shell variables once (adapt values):

```bash
ORG_ID=<your-org-id>
POLICY_ID=<access-context-manager-policy-id>   # from requirement 2.1
PILOT_PROJECT=<pilot-project-id>
PILOT_GROUP=group:zero-trust-pilot@<domain>    # Pilot Group – ZeroTrust
PILOT_VM=iap-vm-pilot                           # IAP VM – Pilot
```

---

## Stage 0 — Assess (read-only)
**Goal:** know the current access exposure before changing anything.

1. Inventory the current front doors for the pilot app and VM: how are they reached today (public IP,
   VPN route, bastion), and what firewall rules expose them.
2. Run the assessment tool (read-only) to capture the baseline:
   `python bce_access_assessment.py --project $PILOT_PROJECT --org $ORG_ID`. It reports existing access
   policies/levels, whether IAP is enabled on candidate resources, and firewall rules that expose SSH
   or HTTP(S) broadly (a VPN/flat-trust signal). **Gate 0 (record-only):** you have a written baseline
   of how the pilot app and VM are reachable today.

## Stage 1 — Design access levels
**Goal:** define the reusable identity+device+context conditions.

1. Decide the first two access levels:
   - `Access Level – Trusted-Network – v1` — allowed corporate IP CIDR ranges (a basic access level).
   - `Access Level – Corp-Managed – v1` — corporate-managed device + allowed region, drawing on the
     device-trust signal from requirement 2.4. **Verify** which device attributes your signal source
     exposes before finalizing this level.
2. Author them as a **dry-run** first with the scope/config helper's build mode, which prints the exact
   `gcloud`/YAML it would apply without changing anything:
   `python bce_scope_config_helper.py build --policy $POLICY_ID --name "Access Level – Trusted-Network – v1" --ip-ranges 203.0.113.0/24 --dry-run`
3. Review the printed definition. Basic access levels use attribute conditions; if you need combined
   logic (identity AND device AND region), use a **custom** access level with a **CEL** expression —
   the helper emits the CEL skeleton to review. Keep expressions in version control.
4. Apply when reviewed (the builder requires explicit `--apply`, or apply the printed `gcloud`
   yourself):
   ```bash
   gcloud access-context-manager levels create trusted_network_v1 \
     --policy $POLICY_ID \
     --title "Access Level – Trusted-Network – v1" \
     --basic-level-spec level.yaml   # the YAML the builder printed
   ```
   **Gate 1:** both access levels exist and list under
   `gcloud access-context-manager levels list --policy $POLICY_ID`.

## Stage 2 — Configure IAP for the pilot web app
**Goal:** put IAP in front of `IAP App – Pilot` so no request reaches the backend unauthenticated.

1. Enable IAP for the app's HTTPS load-balancer backend service (Console: Security → Identity-Aware
   Proxy → toggle the backend service on; configure the OAuth consent/brand if prompted — this
   first-run step is version-dependent, **verify** against current IAP docs). The IAP helper tool
   prints the exact enable steps and checks prerequisites in dry-run:
   `python bce_iap_enable_helper.py --project $PILOT_PROJECT --resource-type web --backend-service iap-app-pilot-bes --dry-run`
2. Grant the pilot group web access **conditioned on** an access level (context-aware binding):
   ```bash
   gcloud iap web add-iam-policy-binding \
     --project=$PILOT_PROJECT \
     --resource-type=backend-services \
     --service=iap-app-pilot-bes \
     --member=$PILOT_GROUP \
     --role=roles/iap.httpsResourceAccessor \
     --condition="expression=<access-level condition>,title=Corp-Managed-v1"
   ```
   The condition references `Access Level – Corp-Managed – v1`. **Verify** the exact condition
   expression syntax for access-level conditions in your `gcloud` version; the IAP helper prints the
   current form for your CLI.
3. Confirm the backend is not reachable except through IAP: the load balancer only accepts IAP-signed
   requests, and no firewall rule allows the backend to be hit directly.
   **Gate 2:** IAP is enabled on `IAP App – Pilot` and the context-aware binding is present.

## Stage 3 — Configure IAP TCP forwarding for the pilot VM
**Goal:** replace bastion/VPN SSH to `IAP VM – Pilot` with brokered, context-checked SSH.

1. Ensure the firewall allows SSH ingress **only from the IAP forwarding range** `35.235.240.0/20`
   (requirement 2.3) and remove any rule that allowed SSH from the internet or the broad VPN range.
   The IAP helper checks this in dry-run:
   `python bce_iap_enable_helper.py --project $PILOT_PROJECT --resource-type ssh --instance $PILOT_VM --dry-run`
2. Grant the pilot group the TCP-tunnel accessor role on the VM, conditioned on an access level:
   ```bash
   gcloud iap tcp add-iam-policy-binding \
     --project=$PILOT_PROJECT \
     --member=$PILOT_GROUP \
     --role=roles/iap.tunnelResourceAccessor \
     --condition="expression=<access-level condition>,title=Corp-Managed-v1"
   ```
   (Scope the binding to the instance/zone per your policy; **verify** the exact resource scoping flags
   for tunnel bindings in your `gcloud` version.)
3. Test the brokered connection: `gcloud compute ssh $PILOT_VM --tunnel-through-iap --zone <zone>`.
   **Gate 3:** SSH to `IAP VM – Pilot` succeeds *only* through `--tunnel-through-iap` and the pilot
   group, and direct SSH (without IAP) is refused.

## Stage 4 — Pilot & Validate (the deny/allow gate)
**Goal:** prove access is granted on identity+context and denied otherwise, with evidence.

1. Run the validation report tool, which exercises the allow/deny matrix and reads IAP/audit logs:
   `python bce_zerotrust_validation_report.py --project $PILOT_PROJECT --resource iap-app-pilot-bes --group $PILOT_GROUP`
2. Confirm the four required outcomes (details and expected pass/fail in **05-testing.md**):
   - Pilot user on a **corp-managed device from an allowed region** → **allowed**.
   - Pilot user on an **unmanaged device / disallowed region** → **denied** (fails the access level).
   - **Non-pilot** user (not in the group) → **denied** (fails IAM).
   - Direct access **bypassing IAP** → **refused** (backend/VM not reachable directly).
3. Run the guardrail tool to catch weak configuration (unconditioned IAP bindings, access levels with
   no device/context condition, SSH firewall not locked to the IAP range):
   `python bce_policy_guardrail_check.py --project $PILOT_PROJECT --policy $POLICY_ID`.
   **Gate 4 (go/no-go):** all four outcomes are correct **and** the guardrail check reports no
   high-severity findings. Do not proceed to VPN retirement until this gate passes.

## Stage 5 — Retire the VPN path (production-affecting — change window)
**Goal:** make the app/VM reachable *only* by identity+context, not by network position.

1. In the change window, remove the VPN route and firewall exposure that previously reached the pilot
   app/VM (the ones inventoried in Stage 0). The app is now reachable solely through IAP.
2. Re-run `bce_zerotrust_validation_report.py` to confirm access still works through IAP and is now
   impossible via the retired path.
   **Gate 5:** the retired VPN/firewall path no longer reaches the app/VM, and IAP access still passes.

## Stage 6 — Expand
**Goal:** apply the validated pattern to more apps/VMs.

1. Reuse the same access levels across additional resources (define once, reference everywhere).
2. For each new resource repeat Stages 2–5, promoting access-level names to `– v2`/`– Prod` scopes as
   the policy hardens. Version access-level definitions in IaC (Terraform / Cloud Foundation Toolkit)
   as a **pattern** — representative snippet:
   ```hcl
   # Pattern only — module internals deferred to the provider's docs
   resource "google_access_context_manager_access_level" "corp_managed_v1" {
     parent = "accessPolicies/${var.policy_id}"
     name   = "accessPolicies/${var.policy_id}/accessLevels/corp_managed_v1"
     title  = "Access Level – Corp-Managed – v1"
     # basic { conditions { ... device_policy / regions / ip_subnetworks ... } }
   }
   ```
3. Run the scope/config helper's export mode to capture the current zero-trust scope (which resources
   are behind IAP, which access levels apply, which broad firewall paths remain) as an inventory for
   governance sign-off:
   `python bce_scope_config_helper.py export --org $ORG_ID --project $PILOT_PROJECT --format json`.

---

## Rollback (keep ready before any enforcement change)
- **Access-level binding wrong / users locked out:** remove the access-level condition from the IAP
  binding (re-add without `--condition`) or delete the offending binding, restoring identity-only IAM
  access, then fix the access level and re-bind.
- **IAP web enforcement broke the app:** disable IAP on the backend service (Console: IAP → toggle
  off), returning to the prior load-balancer behavior, then diagnose and re-enable.
- **IAP SSH lockout:** re-add a temporary, narrowly-scoped SSH firewall rule from a known admin IP (or
  use the serial console) to regain access, then re-lock to `35.235.240.0/20`.
- **VPN retirement caused an outage:** re-apply the removed route/firewall rule from the Stage 0
  baseline to restore the prior path, then re-plan the retirement. Only retire again after Gate 4/5
  pass cleanly.
Every rollback step operates on artifacts named in this guide; log each rollback for the change record.
