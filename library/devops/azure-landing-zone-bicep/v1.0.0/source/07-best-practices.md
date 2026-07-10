# 7. Best Practices — Azure Landing Zone with Bicep

## Keep it clean
- **Everything through the pipeline.** After the initial bootstrap, never `az deployment`/`az stack` from a laptop against production. The pipeline's what-if → approval → deploy path is the only production route, so every change is reviewed and recorded.
- **What-if is a gate, not a formality.** Read every what-if before approving. An unexpected **delete** or **modify** on a resource you did not intend to touch means **stop** — investigate before you approve.
- **Audit before deny, always.** Assign new guardrails in audit, understand the compliance picture, exempt legitimate cases, then promote to deny. Never ship a new policy straight to deny in production.
- **Pin your toolchain.** Pin the Bicep and Azure CLI versions in the repo (`bicepconfig.json` / a tool-version file). IaC that "worked last month" breaks when a CLI silently updates. *Verify current supported versions periodically.*
- **Parameterize, never hard-code.** Address ranges, tags, prefixes, and management-group IDs live in `.bicepparam` files — one file per environment. The same `main.bicep` deploys non-prod and prod; only parameters differ.
- **Use deployment stacks for rollback.** Deploy as stacks with `denyDelete` so out-of-band portal edits are blocked, and keep `--action-on-unmanage` explicit so a rollback does exactly what you expect.
- **Least privilege by default.** No standing Owner except a documented break-glass account; prefer custom roles scoped to the narrowest management group; use PIM-eligible assignments where Entra ID P2 is licensed (*verify licensing*).
- **Modularize.** Keep hierarchy, policy, RBAC, and network as separate Bicep modules toggled by parameters (`deployHierarchy`, `deployPolicy`, `deployNetwork`) so you can what-if and deploy each independently.
- **Secrets stay out of code.** Workload-identity federation for the pipeline (no secret), Key Vault for anything a resource needs, and secret scanning on the repo (Global Requirements G4/G6).
- **Non-overlapping addressing forever.** Reserve hub/spoke ranges in IPAM up front; re-addressing after workloads land is painful. The discovery script's VNet inventory is your overlap check.

## Governance and decisions that belong to the customer
- **Production change approval**, who may approve, and the soak period before deny are the customer's **change-control** decisions — the solution provides the technical gate, not the policy.
- **Regulatory / data-residency** determinations (allowed regions, sovereign-cloud requirements) belong to the customer's compliance function; the guardrails **enforce** those choices once made.
- **Break-glass account** ownership and testing cadence are the customer's security decision.

## Where to go next
Once the landing zone is live, adjacent catalog areas extend it:
- **Azure Solutions** — *Azure Security Baseline & Governance* deepens the policy/Defender-for-Cloud posture on top of the hierarchy you just built.
- **DevOps** — the sibling *Azure Landing Zone with Terraform* solution if a team standardizes on Terraform instead of Bicep, and *Intune-as-Code (Graph & Terraform)* to bring endpoint management under the same code-and-pipeline discipline.
- **Security / Identity** — Conditional Access and PIM solutions to harden the identity baseline this landing zone starts.
- **Networking** — extend hub-spoke with Azure Firewall policy, VPN/ExpressRoute gateways, and private-endpoint patterns per workload.
