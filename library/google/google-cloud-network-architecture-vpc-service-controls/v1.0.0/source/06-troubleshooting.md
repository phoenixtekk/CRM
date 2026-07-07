# Troubleshooting

Common failure modes and how to resolve them. Artifact names match the Implementation guide
(`vpc-prod-shared`, `sn-prod-use4`, `Access Level – Corp-Managed – v1`, `Perimeter – Prod – v1`).

---

## Private access

**Symptom: DNS resolves `storage.googleapis.com` to a *public* IP, or API calls from an internal-only
VM time out.**
- **Cause:** Cloud DNS is not mapping `googleapis.com` to the restricted/private VIP, the restricted-VIP
  route is missing, or Private Google Access is off for the subnet.
- **Resolve:** Confirm `privateIpGoogleAccess=True` on `sn-prod-use4` (test T1); verify the Cloud DNS
  private zone / response policy points `*.googleapis.com` at the **restricted** VIP; confirm the route
  to the restricted VIP range exists. **Verify the current restricted VIP range in Google's "Private
  Google Access" documentation** — do not assume a hard-coded value. Re-run
  `gcpnet_private_access_validate.py`.

**Symptom: API access works but only when the VM has an external IP.**
- **Cause:** Traffic is going out the public path, not the private VIP — private access is not actually
  in effect.
- **Resolve:** Remove the external IP and re-test; fix DNS/route as above until the call succeeds with
  internal IP only.

## Shared VPC

**Symptom: `shared-vpc associated-projects add` fails, or the service project cannot use subnets.**
- **Cause:** Missing `roles/compute.xpnAdmin` (Shared VPC Admin) at the org/folder, Shared VPC not
  enabled on the host, or the service account lacks subnet IAM.
- **Resolve:** Confirm Shared VPC is enabled on `Net-Host – Prod – Shared-VPC`
  (`gcloud compute shared-vpc get-host-project …`); grant `compute.xpnAdmin` at the narrowest scope
  (Requirement 1); grant subnet-level `networkUser` on the shared subnet to the service project's
  service accounts.

**Symptom: hybrid/VPN/peering routes fail or behave oddly after adding a subnet.**
- **Cause:** Overlapping IP ranges with on-prem or a peered VPC (Requirement 3).
- **Resolve:** Audit the IP plan for overlap; ranges cannot be renumbered non-disruptively — plan a
  migration for the overlapping subnet rather than patching routes.

## Firewall / egress

**Symptom: arbitrary public egress still succeeds from a workload.**
- **Cause:** The deny-egress baseline in `HFW – Org – Baseline` is missing, out-prioritized by a
  broader allow, or the policy is not associated with the folder/VPC.
- **Resolve:** Confirm the hierarchical policy is associated and that the deny-egress rule is at a lower
  (broader) priority number than any 0.0.0.0/0 allow; ensure the only egress allows are the named ones
  (Google API VIP ranges, explicit destinations).

## VPC Service Controls — dry-run

**Symptom: the known exfiltration test (copy to an outside project) produces *no* dry-run violation.**
- **Cause:** The service (`storage.googleapis.com`) is not in the perimeter's restricted list, the
  source/target project is not in `--resources`, or Data Access **audit logging is off** for the
  service (Requirement 7).
- **Resolve:** Add the service to `restricted-services`; add the project number to the perimeter's
  resources (in dry-run); enable Data Access audit logs for the protected services, then regenerate the
  test request and re-check with `gcpnet_vpcsc_perimeter_build.py --show-dry-run-violations`.

**Symptom: dry-run shows would-deny violations for flows you believe are legitimate.**
- **Cause:** A real business flow (CI/CD service account, on-prem source, cross-project pipeline) is not
  yet covered by an ingress/egress rule.
- **Resolve:** Add a **narrow** ingress/egress rule referencing `Access Level – Corp-Managed – v1`, the
  specific identity, and the specific service — do not widen the perimeter or drop a restricted service.
  Re-run dry-run until only intended blocks remain (Gate G2).

## VPC Service Controls — enforced

**Symptom: after enforcing, a legitimate call fails with `VPC Service Controls` / `PERMISSION_DENIED`
and a unique violation ID.**
- **Cause:** A legitimate flow was not covered before enforcement (Gate G2 was passed on incomplete
  logs).
- **Resolve:** Execute the documented **rollback to dry-run** immediately to stop denials
  (`perimeters dry-run drop …` — **verify the exact subcommand for your gcloud version**), add the
  missing ingress/egress rule, confirm in dry-run, then re-enforce. Use the unique violation ID in the
  error to pinpoint the blocked request in the logs.

**Symptom: enforcement did not seem to take effect (exfiltration still succeeds).**
- **Cause:** The `dry-run enforce` step was not run, or a spec/status mismatch left the perimeter still
  in dry-run.
- **Resolve:** Run `gcpnet_perimeter_report.py` — if it reports `DRY-RUN`, the enforce step did not
  promote the spec; re-run `perimeters dry-run enforce perimeter_prod_v1`.

## Permissions & policy

**Symptom: `access-context-manager` commands fail with permission denied.**
- **Cause:** Missing `roles/accesscontextmanager.policyAdmin` / `policyEditor`, or the wrong/absent
  org access policy ID.
- **Resolve:** Confirm the org access policy exists
  (`gcloud access-context-manager policies list --organization=ORG_ID`) and that the running identity
  holds the policy roles (Requirement 1 & 5); pass the correct `--policy` ID.

## Tooling

**Symptom: a Python tool prints `gcloud not found on PATH` or empty results.**
- **Cause:** Google Cloud SDK not installed / not on PATH, or ADC not configured.
- **Resolve:** Install the SDK and run `gcloud auth application-default login` (or use the pipeline's
  Workload Identity); confirm `gcloud version`. The tools are read-only/dry-run by default, so re-running
  after fixing auth is safe.
