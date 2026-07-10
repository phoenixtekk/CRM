# 7. Best Practices — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

Keep the estate clean, repeatable, and cheap. These practices keep hosts identical, profiles fast, and the bill predictable.

## Golden image discipline
- **One source of truth.** Every session host comes from a **gallery image version** — never a hand-patched live host. If you edit a host directly, you have created a snowflake; rebuild it from the image instead.
- **Semantic versioning with intent.** Monthly Windows/app patch → minor bump (`1.0.0` → `1.1.0`); a from-scratch rebuild or major OS change → major bump (`2.0.0`). The version number should tell you what changed.
- **Keep a written build checklist** (Section 3, Step 3) so any engineer can reproduce the image. Better still, graduate the manual capture to **Azure VM Image Builder** so the definition rebuilds on a schedule — *verify VM Image Builder availability in your region/cloud.*
- **Replicate versions** to every region you run hosts in, and **retain the previous version** so you can roll a host pool back if a new image regresses.

## FSLogix and profile performance
- **Co-locate** the profile share with the session hosts (same region) — cross-region profile I/O is the top cause of slow logons.
- **Size for the real profile**, including Outlook cached mode and Teams cache; premium Azure Files or the right Azure NetApp Files service level, not standard storage.
- **Least-privilege share permissions** (users: Modify, admins: Full) so users create only their own container.
- **Exclude** the FSLogix VHDX path from on-host antivirus real-time scanning to avoid logon stalls (follow your AV vendor's AVD guidance).

## Deployment and change control
- **What-if before every apply.** The Bicep `what-if` (Testing T7) is your drift detector and your change record — a clean what-if means the estate equals the code.
- **Fresh registration tokens at deploy time.** Never reuse an old token; let the template mint one. Expired tokens are the classic "VM deployed but not a session host" failure.
- **Patch by replacement, not by hand.** Use the drain-and-patch workflow (Section 3, Step 10): drain old hosts, deploy new ones from the new image version, remove the old — no mid-session disconnects, and a clean rollback (redeploy the prior version).

## Cost control
- **Always attach a scaling plan.** Idle multi-session hosts running overnight are the biggest avoidable cost. Tune ramp-down aggressively for non-24×7 audiences.
- **Right-size the VM SKU** to real session density; measure with AVD Insights before scaling out.
- **Deallocate the imaging build VM** (auto-delete after capture) so build boxes never linger.

## Security and governance
- **Least-privilege RBAC** with the Desktop Virtualization roles; prefer **PIM** eligible activation over standing Owner.
- **Defer the business decisions** — which apps belong in the image, data-residency and records requirements, and production change approval are customer compliance/legal/ops calls, not technical defaults (Overview, "Scope — out").
- **Enable AVD Insights / Log Analytics** so health, logon time, and FSLogix errors are observable, not guessed.

## Where to go next (adjacent catalog areas)
- **Azure Virtual Desktop Remote Access (Windows & macOS Clients)** — the companion solution for publishing this estate to end users and validating client connectivity and Conditional Access. Deploy this build solution first, then that one.
- **Azure Security Baseline & Governance** — Azure Policy, RBAC, and guardrails to wrap the subscription your AVD estate lives in.
- **Windows 365 Cloud PC Deployment** — for personal, always-on Cloud PCs where per-user simplicity beats pooled multi-session economics; useful to compare against pooled AVD for parts of your population.
- **Azure Kubernetes Service Secure Baseline** — if the same team runs containerized workloads alongside AVD and wants the same IaC-and-baseline rigor.
