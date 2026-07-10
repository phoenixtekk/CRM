# Executive Summary — Azure Landing Zone with Bicep

**White-label · DevOps**

Most Azure estates start as a single subscription clicked together in the portal: no management-group hierarchy, no policy guardrails, over-privileged owners, ad-hoc networking, and nothing in source control. It works until it doesn't — the estate drifts, no two subscriptions look alike, and there is no repeatable way to stand up the next one. This solution builds an **Azure landing zone as code** using **Bicep** — Microsoft's native infrastructure-as-code language — so the foundation is governed, versioned, and repeatable without leaving the Microsoft toolchain.

This is a complete, **deploy-it-today** package for standing up a Bicep landing zone, written for an administrator who has used the Azure portal but has never authored Bicep, assigned Azure Policy as code, or run an IaC pipeline.

## What you get
- A plain-language **Solution Overview** of the landing-zone pattern — management groups, Azure Policy and initiatives as Bicep, an identity/RBAC baseline, deployment stacks, and hub-spoke networking with DNS.
- A **Requirements Guide** with verify / implement-if-missing for every solution-specific prerequisite (the category-wide ones live in the separate Global Requirements).
- An **Implementation Guide** of precise, ordered steps — scaffold the repo, deploy the management-group hierarchy, assign policy in **audit**, apply the RBAC baseline, deploy hub-spoke networking, then wire the CI/CD pipeline with **what-if** and approvals.
- Five IaC / automation artifacts: a read-only **PowerShell discovery** script, the core **`main.bicep`** landing-zone template, a **PowerShell what-if validation** script, an **`azure-pipelines.yml`** pipeline (what-if → approval → deploy), and a **PowerShell posture report**.
- **Testing** and **Troubleshooting** guides for a confident, pilot-first rollout.

## What this delivers
A **management-group hierarchy** deployed as Bicep, **Azure Policy initiatives** assigned in audit and promoted to deny on a controlled gate, an **identity/RBAC baseline** with custom roles and no standing Owner, **hub-spoke networking** with a central firewall subnet and private DNS, all deployed through **Azure deployment stacks** and a **CI/CD pipeline** that runs **what-if first** and requires approval before every production deploy — proven against a non-production scope before it touches production.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand** — every apply is preview-first (`what-if`), reviewed in a pull request, and approval-gated, with a documented rollback via deployment-stack delete/update.

## Outcome
A Microsoft-native, versioned Azure foundation expressed entirely as Bicep in Git — management groups, policy guardrails, least-privilege identity, and hub-spoke connectivity — governed and repeatable, deployable by a single administrator and validated before you scale to the rest of the estate.
