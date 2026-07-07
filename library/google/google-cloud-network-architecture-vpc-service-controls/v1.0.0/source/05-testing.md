# Testing & Validation

Run these after the corresponding implementation stage. Each test states the **procedure** and the
**expected pass/fail signal**. Artifact names match the Implementation guide
(`vpc-prod-shared`, `sn-prod-use4`, `Access Level – Corp-Managed – v1`, `Perimeter – Prod – v1`).

---

## T1 — Shared VPC topology is correct

- **Procedure:**
  ```bash
  gcloud compute shared-vpc get-host-project $PILOT_SVC_PROJECT_ID
  gcloud compute networks subnets describe sn-prod-use4 --region=$REGION \
    --project=$NET_HOST_PROJECT_ID --format='value(privateIpGoogleAccess)'
  ```
- **Pass:** the host project returns `Net-Host – Prod – Shared-VPC`'s ID, and
  `privateIpGoogleAccess` is `True`.
- **Fail:** empty host project (service project not attached) or `False` (private access not enabled)
  → return to Implementation Stage 2.

## T2 — Private Google Access works from an internal-only VM

- **Procedure:** On a VM in `sn-prod-use4` with **no external IP**:
  ```bash
  nslookup storage.googleapis.com          # expect the restricted/private VIP
  gcloud storage ls                        # expect success with no public egress
  python scripts/gcpnet_private_access_validate.py --project $PILOT_SVC_PROJECT_ID --region $REGION
  ```
- **Pass:** DNS resolves to the restricted/private VIP and the API call succeeds; the validator reports
  `PRIVATE ACCESS: OK`.
- **Fail:** DNS resolves to a public IP, or the call times out / needs an external IP → fix the Cloud
  DNS zone and the restricted-VIP route (Implementation step 6).

## T3 — Egress is deny-by-default

- **Procedure:** From the same internal-only VM, attempt egress to an arbitrary public host not on any
  allow rule (e.g. `curl -m 5 https://example.com`).
- **Pass:** the connection is **blocked/timed out** (no matching allow in `HFW – Org – Baseline` /
  `NFW – Prod – Workload`), while Google API access (T2) still works.
- **Fail:** arbitrary egress succeeds → the deny-egress baseline is missing or out-prioritized; review
  the firewall policies.

## T4 — Perimeter dry-run logs a known exfiltration attempt

- **Procedure:** With `Perimeter – Prod – v1` in **dry-run**, attempt to copy a protected bucket to a
  project **outside** the perimeter:
  ```bash
  gcloud storage cp gs://protected-bucket/obj gs://outside-bucket/obj    # from inside perimeter
  python scripts/gcpnet_vpcsc_perimeter_build.py --policy $POLICY_ID --show-dry-run-violations
  ```
- **Pass:** the copy **succeeds** (dry-run does not deny) but a **would-deny** VPC-SC violation for
  that request appears in the dry-run logs / tool output.
- **Fail:** no violation logged → the perimeter does not cover `storage.googleapis.com`, the project is
  not in `--resources`, or audit logging is off (Requirement 7).

## T5 — Legitimate flows are covered before enforcement (Gate G2)

- **Procedure:**
  ```bash
  python scripts/gcpnet_perimeter_report.py --policy $POLICY_ID --perimeter perimeter_prod_v1
  ```
  Review the report's classification of dry-run violations into **legitimate (needs a rule)** vs
  **intended-block**.
- **Pass:** every legitimate flow has a matching ingress/egress rule referencing
  `Access Level – Corp-Managed – v1`; only intended exfiltration-style violations remain.
- **Fail:** any legitimate business flow still shows as would-deny → add the ingress/egress rule and
  re-run dry-run. **Do not enforce.**

## T6 — Enforcement blocks exfiltration and preserves legitimate access

- **Procedure:** After `perimeters dry-run enforce`, repeat T4's exfiltration copy and a legitimate
  in-perimeter API call.
- **Pass:** the exfiltration copy now **fails** with a `VPC Service Controls` `PERMISSION_DENIED`
  (note the unique violation ID), while the legitimate in-perimeter call still **succeeds**.
- **Fail:** exfiltration still succeeds (not enforced / wrong service) **or** a legitimate call now
  fails (missing ingress/egress rule) → for the latter, execute the **rollback to dry-run**
  (Implementation step 20), add the rule, and re-enforce.

## T7 — Access level gates by trusted condition

- **Procedure:** Trigger a request that satisfies `Access Level – Corp-Managed – v1` (from a corp IP /
  managed device) and one that does not, against a service governed by an ingress rule.
- **Pass:** the satisfying request is allowed; the non-satisfying request is denied by VPC-SC.
- **Fail:** both allowed → the ingress rule is not actually referencing the access level; both denied →
  the access level's conditions are too strict or misconfigured (verify device-posture availability in
  your org).

## T8 — Config helper output matches live state (drift check)

- **Procedure:**
  ```bash
  python scripts/gcpnet_config_helper.py --org $ORG_ID --host-project $NET_HOST_PROJECT_ID \
    --policy $POLICY_ID --check
  ```
- **Pass:** the helper reports the expected artifacts present and named
  (`vpc-prod-shared`, `sn-prod-use4`, `Perimeter – Prod – v1`, `Access Level – Corp-Managed – v1`) with
  no drift from the intended config.
- **Fail:** the helper flags a missing/renamed artifact or drift → reconcile against the Implementation
  guide before expanding to the next wave.
