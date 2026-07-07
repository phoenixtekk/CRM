# Implementation

Follow these ordered steps. The house model is **Assess → Design → Configure → Pilot → Validate →
Expand**, pilot-first, with explicit pass/fail gates and a documented rollback for every
production-affecting change. **Every artifact is named** with the `<Purpose> – <Scope> – <Stage>`
convention and the exact name is reused in testing, troubleshooting, and the scripts.

Set these shell variables once (substitute your values):

```bash
export ORG_ID=123456789012
export NET_HOST_PROJECT_ID=net-host-prod            # Net-Host – Prod – Shared-VPC
export PILOT_SVC_PROJECT_ID=app-a-prod              # App-A – Prod  (pilot service project)
export REGION=us-east4
export POLICY_ID=$(gcloud access-context-manager policies list \
  --organization=$ORG_ID --format='value(name)' | head -n1)
```

Artifact names used throughout:

| Artifact | Name |
|---|---|
| Shared VPC host project | `Net-Host – Prod – Shared-VPC` |
| VPC network | `vpc-prod-shared` |
| Pilot subnet | `sn-prod-use4` |
| Hierarchical firewall policy | `HFW – Org – Baseline` |
| VPC network firewall policy | `NFW – Prod – Workload` |
| PSC endpoint (Google APIs) | `psc-googleapis` |
| Access level | `Access Level – Corp-Managed – v1` |
| Service perimeter | `Perimeter – Prod – v1` |

---

## Stage 0 — Assess (read-only)

1. Inventory the current network exposure with the assessment tool (safe, read-only):

   ```bash
   python scripts/gcpnet_network_assessment.py --project $NET_HOST_PROJECT_ID --org $ORG_ID
   ```

   It reports VPCs/subnets, whether Private Google Access is on per subnet, external IPs in use,
   permissive (0.0.0.0/0) firewall rules, and whether any VPC-SC perimeter already exists. Save the
   JSON output as the **baseline**.

2. **Gate G0 (pass/fail):** You have a written baseline of exposure and an agreed IP plan
   (Requirement 3). **Fail →** do not proceed until the network team signs off the IP plan and pilot
   scope.

## Stage 1 — Design (no changes)

3. Confirm the resource hierarchy: `Net-Host – Prod – Shared-VPC` under the **Network** folder;
   `App-A – Prod` (pilot) and other service projects under the workload folders. Confirm the subnet /
   secondary-range table and which Google services the perimeter will protect (Requirement 6).

## Stage 2 — Configure the Shared VPC + private access (pilot host first)

4. **Enable Shared VPC on the host project** (`Net-Host – Prod – Shared-VPC`):

   ```bash
   gcloud compute shared-vpc enable $NET_HOST_PROJECT_ID
   ```

5. **Create the VPC and the pilot subnet with Private Google Access ON:**

   ```bash
   gcloud compute networks create vpc-prod-shared \
     --project=$NET_HOST_PROJECT_ID --subnet-mode=custom

   gcloud compute networks subnets create sn-prod-use4 \
     --project=$NET_HOST_PROJECT_ID --network=vpc-prod-shared \
     --region=$REGION --range=10.20.0.0/20 \
     --enable-private-ip-google-access --enable-flow-logs
   ```

   Add secondary ranges (`--secondary-range pods=…,services=…`) only where GKE is in scope.

6. **Configure DNS + the restricted VIP route for private API access.** Create a Cloud DNS private
   zone (or response policy) so `*.googleapis.com` resolves to the **restricted** VIP, and add the
   route. **Verify the current restricted/private VIP ranges in Google's "Private Google Access"
   documentation** before using them:

   ```bash
   gcloud compute routes create rt-restricted-googleapis \
     --project=$NET_HOST_PROJECT_ID --network=vpc-prod-shared \
     --destination-range=199.36.153.4/30 --next-hop-gateway=default-internet-gateway
   # Cloud DNS private zone mapping googleapis.com → restricted.googleapis.com (see docs for exact records)
   ```

7. **(Optional, recommended) Create a Private Service Connect endpoint for the Google APIs bundle**
   named `psc-googleapis`, giving an org-owned private IP for the APIs (choose the `all-apis` or
   `vpc-sc` bundle per your perimeter design — **verify current bundle names**):

   ```bash
   gcloud compute addresses create psc-googleapis-ip \
     --project=$NET_HOST_PROJECT_ID --global --purpose=PRIVATE_SERVICE_CONNECT \
     --addresses=10.20.255.2 --network=vpc-prod-shared
   gcloud compute forwarding-rules create psc-googleapis \
     --project=$NET_HOST_PROJECT_ID --global --network=vpc-prod-shared \
     --address=psc-googleapis-ip --target-google-apis-bundle=all-apis
   ```

8. **Provision helper (dry-run by default).** Instead of running the raw commands, you may use the
   provisioning helper, which prints the plan and only mutates with `--apply`:

   ```bash
   python scripts/gcpnet_shared_vpc_provision.py \
     --host-project $NET_HOST_PROJECT_ID --network vpc-prod-shared \
     --region $REGION --subnet sn-prod-use4 --range 10.20.0.0/20    # dry-run
   # add --apply only after reviewing the printed plan
   ```

9. **Attach the pilot service project** (`App-A – Prod`) to the Shared VPC:

   ```bash
   gcloud compute shared-vpc associated-projects add $PILOT_SVC_PROJECT_ID \
     --host-project=$NET_HOST_PROJECT_ID
   ```

## Stage 3 — Firewall & egress policy (deny-by-default)

10. **Create the hierarchical firewall policy** `HFW – Org – Baseline` at the Network folder, with
    **deny-egress by default** plus explicit allows for the Google API VIP ranges, then associate it:

    ```bash
    gcloud compute firewall-policies create --organization=$ORG_ID \
      --short-name=hfw-org-baseline --description="HFW – Org – Baseline"
    # add rules: allow egress to restricted VIP; deny egress 0.0.0.0/0 (low priority)
    # then: gcloud compute firewall-policies associations create --folder=NETWORK_FOLDER_ID …
    ```

11. **Create the VPC network firewall policy** `NFW – Prod – Workload` for workload-specific allows and
    associate it with `vpc-prod-shared`. Keep the default egress posture **deny**; every allow is named.

12. **Gate G1 (pass/fail):** From a pilot VM with **no external IP** on `sn-prod-use4`, private access
    works (`gcloud storage ls` / API call succeeds via the restricted VIP) and unlisted egress is
    denied. Run `scripts/gcpnet_private_access_validate.py --project $PILOT_SVC_PROJECT_ID`.
    **Fail →** fix DNS/route/firewall before touching perimeters. **Rollback:** the network is additive
    so far; detach the service project (`shared-vpc associated-projects remove`) and delete the pilot
    subnet/VPC if the pilot is abandoned.

## Stage 4 — VPC Service Controls perimeter (DRY-RUN first)

13. **Create the access level** `Access Level – Corp-Managed – v1` describing trusted conditions (corp
    IP ranges and, where BeyondCorp device posture is available, managed-device requirements — **verify
    device-posture availability in your org**). Author it as a `.yaml` and apply:

    ```bash
    gcloud access-context-manager levels create corp_managed_v1 \
      --policy=$POLICY_ID --title="Access Level – Corp-Managed – v1" \
      --basic-level-spec=access-level-corp-managed-v1.yaml
    ```

14. **Create the service perimeter in DRY-RUN mode** `Perimeter – Prod – v1`, listing the in-scope
    projects and the restricted services (**verify current VPC-SC coverage for each service**):

    ```bash
    gcloud access-context-manager perimeters dry-run create perimeter_prod_v1 \
      --policy=$POLICY_ID --title="Perimeter – Prod – v1" \
      --perimeter-type=regular \
      --resources=projects/PILOT_PROJECT_NUMBER \
      --restricted-services=storage.googleapis.com,bigquery.googleapis.com,aiplatform.googleapis.com
    ```

    You may instead use the builder, which emits the spec and stays in dry-run unless `--apply`:

    ```bash
    python scripts/gcpnet_vpcsc_perimeter_build.py --policy $POLICY_ID \
      --title "Perimeter – Prod – v1" --resource-project-number PILOT_PROJECT_NUMBER \
      --restricted-services storage.googleapis.com bigquery.googleapis.com    # dry-run
    ```

15. **Let dry-run run.** For at least one full business cycle (e.g. 1–2 weeks), the perimeter **logs
    what it would block** without denying anything. Review the **dry-run violation logs** (Requirement
    7) with the validation report tool:

    ```bash
    python scripts/gcpnet_vpcsc_perimeter_build.py --policy $POLICY_ID --show-dry-run-violations
    python scripts/gcpnet_perimeter_report.py --policy $POLICY_ID --perimeter perimeter_prod_v1
    ```

16. **Add ingress/egress rules for legitimate flows** the dry-run surfaced (e.g. a CI/CD service
    account, an on-prem source reaching BigQuery), each referencing `Access Level – Corp-Managed – v1`.
    Keep iterating dry-run until the only remaining violations are ones you *intend* to block.

17. **Gate G2 (pass/fail):** Dry-run violation logs contain **no legitimate flow** that would break at
    enforcement (all real flows are covered by ingress/egress rules), and a **known exfiltration
    attempt** (e.g. copying a protected bucket to an outside project) appears as a *would-deny*.
    **Fail →** add the missing rule and re-run dry-run; do not enforce.

## Stage 5 — Enforce (production change, with rollback)

18. **Promote the dry-run config to enforced** for `Perimeter – Prod – v1`:

    ```bash
    gcloud access-context-manager perimeters dry-run enforce perimeter_prod_v1 --policy=$POLICY_ID
    ```

19. **Immediately re-validate:** private access still works from inside; the known exfiltration attempt
    is now **actually denied** (`PERMISSION_DENIED` / `VPC Service Controls` unique ID in the error).
    Run `scripts/gcpnet_perimeter_report.py` again and archive the report as go-live evidence.

20. **Rollback (documented):** if enforcement breaks a legitimate flow, revert to dry-run to stop
    denials immediately while you fix the rule:

    ```bash
    gcloud access-context-manager perimeters dry-run drop perimeter_prod_v1 --policy=$POLICY_ID
    # (returns the enforced config to dry-run behavior; add the ingress/egress rule, then re-enforce)
    ```

    **Verify the exact revert/drop subcommand in your gcloud version** before you need it, and rehearse
    it in the pilot.

## Stage 6 — Expand

21. Repeat Stages 2–5 for the remaining regions and service projects, **one wave at a time**, each
    wave: attach service projects → confirm private access (G1) → add the projects to the perimeter in
    **dry-run** → review logs (G2) → **enforce**. Never add a project straight to an enforced
    perimeter — always dry-run the addition first. Bump the perimeter/access-level version suffix
    (`– v2`, …) when the spec materially changes, and keep the previous spec for rollback.
