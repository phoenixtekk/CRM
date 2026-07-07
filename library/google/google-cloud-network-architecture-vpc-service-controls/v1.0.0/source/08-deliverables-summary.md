# Deliverables Summary

Everything included in this solution, on one page.

## Documentation

| Document | What it gives you |
|---|---|
| **Solution Overview** | The network reference design: Shared VPC topology, private access (Private Google Access / PSC), hybrid connectivity, firewall/egress model, and VPC Service Controls perimeter design — with benefits, limitations, and the deployment model. |
| **Requirements Guide** | Solution-specific prerequisites (network admin roles, host/service projects, IP plan, private-access DNS/route, Access Context Manager policy, required APIs, audit-log sink) — each with how to verify and how to implement if missing — on top of the shared GCP category requirements. |
| **Implementation Guide** | Exact, ordered, named steps: build the Shared VPC + private-access subnet, apply deny-by-default firewall/egress policy, and design + **dry-run then enforce** VPC-SC perimeters — pilot-first, with pass/fail gates (G0–G2) and a documented rollback. |
| **Testing & Validation** | Eight tests (T1–T8) with expected pass/fail signals, from Shared VPC correctness and private access through the dry-run exfiltration test to enforced-perimeter validation and drift checking. |
| **Troubleshooting** | Common failure modes (private access resolving public, perimeter not logging, enforcement breaking a flow, permission errors) and their resolutions. |
| **Best Practices** | Durable practices for evolving perimeters safely, access-level design, private access, and safe automation. |
| **Executive Summary** | The outcome, approach, and why it is safe/governed — for decision-makers. |

## Python tools (5) — `gcloud` / Cloud Client Library automation

All are **read-only or dry-run by default**, require an explicit `--apply` for any write, use
Application Default Credentials, and contain **no hardcoded credentials or keys**. Python 3.10+.

| # | Tool | What it does |
|---|---|---|
| 1 | **`gcpnet_network_assessment.py`** | Read-only exposure baseline: VPCs/subnets, subnets missing Private Google Access, 0.0.0.0/0 firewall rules, external IPs, and whether any VPC-SC perimeter exists. Emits JSON. |
| 2 | **`gcpnet_shared_vpc_provision.py`** | Provisioning helper (dry-run default): enables Shared VPC on the host project and creates the VPC + private-access subnet; prints the exact plan and only mutates with `--apply`. |
| 3 | **`gcpnet_private_access_validate.py`** | Read-only validator that Private Google Access is on per subnet, the restricted-VIP route exists, and (from an internal-only VM) API hostnames resolve to a private VIP. |
| 4 | **`gcpnet_vpcsc_perimeter_build.py`** | Builds a VPC-SC service perimeter **in dry-run mode first** (creates only with `--apply`, still dry-run; never enforces), and reads back dry-run would-deny violation logs. |
| 5 | **`gcpnet_perimeter_report.py`** | Read-only go/no-go report: perimeter mode (dry-run vs enforced), restricted services, resources, access levels, and a dry-run violation count — the evidence for Gate G2. |

*(Bonus config/scope helper: **`gcpnet_config_helper.py`** emits the intended artifact config and runs
a read-only drift check against live state — used by test T8.)*

## Named artifacts (reused across docs, tests, and tools)

`Net-Host – Prod – Shared-VPC` · `vpc-prod-shared` · `sn-prod-use4` · `HFW – Org – Baseline` ·
`NFW – Prod – Workload` · `psc-googleapis` · `Access Level – Corp-Managed – v1` ·
`Perimeter – Prod – v1`.
