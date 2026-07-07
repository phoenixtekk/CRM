# 8. Deliverables Summary — BeyondCorp Enterprise: Zero-Trust Access

## Documentation
- **01 Solution Overview** — the zero-trust model (Access Context Manager access levels, Identity-Aware
  Proxy, context-aware access bindings, device-trust signals), the reference design, benefits/limits,
  the deployment model, and how this differs from Workspace Context-Aware Access.
- **02 Requirements** — solution-specific prerequisites (access policy, pilot app behind an HTTPS load
  balancer, pilot VM for IAP TCP forwarding, device-signal source + license, pilot group + admin roles,
  IAP/API enablement, rollback/change window), building on the shared GCP global requirements.
- **03 Implementation** — ordered Assess → Design → Configure → Pilot → Validate → Expand steps: define
  access levels, front a pilot app and VM with IAP, add context-aware bindings and device signals,
  validate deny/allow, retire the VPN path, and expand — with pass/fail gates and a rollback.
- **05 Testing & Validation** — the deny/allow matrix (allowed on identity+context, denied on
  unmanaged/wrong-region, denied for unauthorized identity, direct-bypass refused), device-signal and
  guardrail checks, and VPN-retirement verification, each with expected pass/fail.
- **06 Troubleshooting** — common failure modes (IAP not enforcing, access-level condition not applied,
  device signal not evaluated, SSH-over-IAP failures, VPN-retirement lockouts) and resolutions.
- **07 Best Practices** — durable practices for reusable access levels, gate-driven rollout, keeping the
  two products distinct, device-signal/licensing hygiene, monitoring, least-privilege admin, and scope
  governance.
- **Executive Summary** — the outcome, approach, and why it is safe and governed, for decision-makers.

## The 5 Python tools (in `scripts/`)
Automation is Python over the `gcloud` CLI / Google Cloud Client Libraries. Every tool is
**safe-by-default** (read-only or `--dry-run` unless `--apply` is passed), uses **Application Default
Credentials / the environment** for auth, and contains **no hardcoded credentials, service-account
keys, or secrets**.

1. **`bce_access_assessment.py`** — *Assessment / discovery (read-only).* Reports the current access
   policies and access levels, which candidate resources already have IAP enabled, and firewall rules
   that broadly expose SSH or HTTP(S) (a flat-trust / VPN-dependency signal). Produces the Stage 0
   baseline. Read-only.

2. **`bce_iap_enable_helper.py`** — *IAP enablement helper for an app or VM (dry-run default).* Checks
   prerequisites and prints the exact steps to enable IAP for a web backend service or IAP TCP
   forwarding for a VM (including the `35.235.240.0/20` firewall requirement and the context-aware
   binding form). Applies only with `--apply`.

3. **`bce_zerotrust_validation_report.py`** — *Validation / report generator (read-only).* Exercises the
   allow/deny matrix for a resource and pilot group and reads IAP/audit-log evidence, producing the
   deny/allow validation report that backs the Stage 4 and Stage 5 gates.

4. **`bce_policy_guardrail_check.py`** — *Policy / guardrail check (read-only).* Flags weak
   configuration: IAP bindings without an access-level condition, over-broad principals, access levels
   lacking a device/context condition, and SSH firewall rules not scoped to the IAP range. High-severity
   findings block VPN retirement.

5. **`bce_scope_config_helper.py`** — *Scope / config helper (dry-run default for writes).* Two modes:
   (a) **build** an Access Context Manager access level from basic attribute conditions or a CEL
   custom-level skeleton, printing the exact `gcloud`/YAML it would apply (no change unless `--apply`);
   and (b) **export** the current zero-trust scope — which resources are behind IAP, which access levels
   apply, which broad firewall paths remain — as a JSON/table inventory for governance sign-off
   (read-only).
