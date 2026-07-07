# Executive Summary — Google Cloud IAM & Least-Privilege Governance

**The problem.** On Google Cloud, over-granting is the default failure mode. The `Owner` primitive role
is one click away, service-account **keys** can be exported and never expire, and access permissions
accrete project by project with no one accountable for who holds what. The three most common findings in
any Google Cloud security review are the same every time: **broad Owner/Editor grants, unmanaged exported
service-account keys, and role sprawl.** Each is a standing breach risk — a leaked key or an
over-privileged account is a direct path to the organization's cloud estate.

**The outcome.** This solution puts Google Cloud access under **least-privilege control**: role sprawl is
tamed, exported keys are eliminated, and every binding is reviewed — so *who can do what* is
**intentional and auditable** across the organization.

**The approach.** A repeatable Cloud IAM governance model, delivered as documentation plus five Python
tools, established in six staged phases with explicit gates:
- **A least-privilege role model** — predefined roles first, custom roles only where nothing fits, and
  **no primitive Owner/Editor** outside one audited break-glass path.
- **Group-based access** — humans are bound only through Google Groups at the correct level of the
  resource hierarchy, so joiner/mover/leaver is a membership change, not an IAM edit.
- **Exported keys eliminated** — external and federated workloads move to **Workload Identity Federation**
  (short-lived, auto-rotated credentials), and org policy makes new keys **impossible to create**.
- **IAM-restricting org-policy guardrails** — Domain-Restricted Sharing, key-creation disable, and
  default-service-account grant disable make the wrong grant *impossible*, not merely discouraged.
- **A recurring access review** — IAM Recommender and Policy Analyzer drive quarterly re-attestation so
  least privilege stays true over time.

**Why it is safe and governed.** Every change follows a **pilot-first** model — *Assess → Design →
Configure → Pilot → Validate → Expand* — with pass/fail gates and a documented rollback. Guardrails are
applied in **dry-run** and reviewed before enforcement; IAM policies are snapshotted for instant restore.
The automation is **read-only or dry-run by default**, authenticates without any key file, and contains
no secrets. Nothing reaches the Organization node until it has been proven on a contained pilot scope.

**Bottom line.** Google Cloud access under least-privilege control — role sprawl tamed, exported keys
eliminated, bindings reviewed — intentional and auditable across the organization, proven on a pilot
before you scale, at a fraction of the cost of a bespoke consulting engagement.
