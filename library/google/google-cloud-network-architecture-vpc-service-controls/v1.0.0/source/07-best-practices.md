# Best Practices

Durable practices for operating and evolving this network and its VPC Service Controls perimeters.

## Perimeters

- **Always change perimeters in dry-run first.** Every material change — adding a project, adding a
  restricted service, tightening an access level — goes through `dry-run` and a log review before it
  becomes enforced. Never add a project directly to an enforced perimeter.
- **Version your specs.** Keep the previous perimeter/access-level spec (`– v1`, `– v2`) so rollback is
  a known-good artifact, not an improvisation. Store the go-live report (from
  `gcpnet_perimeter_report.py`) with the change record.
- **Keep a rehearsed rollback.** The revert-to-dry-run step is the emergency brake; rehearse it in the
  pilot and confirm the exact `gcloud` subcommand for your version *before* you need it.
- **Prefer ingress/egress rules over widening the perimeter.** When a legitimate flow is blocked, add a
  narrow ingress/egress rule referencing a specific access level, service, and identity — do not drop a
  service from the restricted list or add a broad project just to make an error go away.
- **Re-verify service coverage periodically.** VPC-SC support for a service (supported / preview /
  unsupported) changes; recheck coverage for your services — especially Vertex AI / Gemini — on a
  schedule, and adjust the restricted-services list accordingly.

## Access levels & identity

- **Model trust with device + network posture, not IP alone.** Where BeyondCorp device posture is
  available in your org, combine corp IP ranges with managed-device requirements in
  `Access Level – Corp-Managed – v1`; IP-only access levels are weaker.
- **Scope access levels tightly and name them by intent.** One access level per trust profile, reused
  by reference across ingress rules — avoid per-rule copies that drift.

## Shared VPC & private access

- **Host project holds no workloads.** Keep the separation of duties clean: network in the host
  project, apps in service projects.
- **Enable Private Google Access on every subnet and remove external IPs by default.** Reach Google
  APIs via the restricted VIP / PSC; grant external IPs only by exception with justification.
- **Deny egress by default.** Build up from a deny-egress hierarchical policy; every allow is named,
  justified, and reviewed. Turn on VPC Flow Logs and firewall logging for evidence.
- **Plan IP space once, generously.** Non-overlapping ranges with room to grow and reserved secondary
  ranges — you cannot renumber non-disruptively later.

## Automation & secrets

- **Run tools read-only / dry-run first; require an explicit `--apply`.** The included tools follow this
  pattern — keep it for any extension you write.
- **Never commit credentials or service-account keys.** Use Application Default Credentials / the
  environment / Workload Identity; keep keys out of code and out of the repo.
- **Use change control for org-wide guardrails.** Hierarchical firewall policies and perimeter
  enforcement affect many projects — land them under ticketed change with the named security/network
  approvers.

## Operations

- **Route VPC-SC and firewall logs to a queryable sink** and alert on unexpected *enforced* denials —
  they indicate either an attack or a missing legitimate-flow rule.
- **Expand in waves with the same gates.** Each region/service-project wave repeats
  attach → private-access check (G1) → dry-run perimeter add → log review (G2) → enforce. Consistency
  is what keeps a large rollout safe.
