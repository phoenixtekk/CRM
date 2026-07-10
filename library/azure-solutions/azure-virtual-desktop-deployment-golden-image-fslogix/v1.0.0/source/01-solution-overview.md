# 1. Solution Overview — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

## What this solution is
This is the **build-and-operate** side of Azure Virtual Desktop (AVD). Where the companion *AVD Remote Access* solution covers how end users connect from Windows and macOS clients, this solution covers how you **produce a consistent golden image**, **deploy session hosts from it with code**, **store user profiles at scale with FSLogix**, **control who can administer the estate (RBAC)**, and **keep cost down with autoscale** — so the estate is repeatable instead of hand-built.

If you have not yet created any AVD host pool at all, deploy the pilot host pool described here; the *AVD Remote Access* solution then covers publishing it to end users and validating the Windows/macOS client experience. The two are designed to be used together without overlap.

## How the technology works
1. A **golden image** is a single, fully configured Windows master (Windows 11 Enterprise multi-session, plus your agents, runtime, and line-of-business apps) that every session host is built from. Building once and cloning many is what makes hosts identical instead of snowflakes.
2. An **Azure Compute Gallery** (formerly Shared Image Gallery) stores that image as an **image definition** with numbered, immutable **image versions** (for example `1.0.0`, `1.1.0`). Because each version is immutable, you always know exactly what a host was built from, and you can replicate a version to multiple regions and roll back to a prior version.
3. An **image-build pipeline** turns "build a new image" into a repeatable job. It starts from a source (the Azure Marketplace base image or your previous gallery version), applies your customizations (Windows Update, app installs, FSLogix agent, optimizations), then captures the result as a **new image version**. This can be a documented manual capture, or automated with **Azure VM Image Builder** (Azure Image Builder / VM image templates) so the same definition rebuilds monthly.
4. **Session hosts** are the real Windows VMs that carry user sessions. Deploying them from **infrastructure-as-code (Bicep)** — referencing a specific gallery image version — means a host pool of ten or a hundred hosts is one reviewable, re-runnable template, not a hundred manual VM creations.
5. **FSLogix profile containers** store each user's Windows profile as a VHDX on a file share (**Azure Files** or **Azure NetApp Files**). On a pooled multi-session host pool, a user can land on any host and their profile, settings, and Outlook/Teams cache follow them. Correct **sizing, redundancy, and permissions** on that share is the single biggest driver of logon performance.
6. **Role-based access control (RBAC)** on the AVD objects (using the built-in *Desktop Virtualization* roles) governs who can operate the host pools, workspaces, and application groups without handing out broad subscription rights.
7. A **scaling plan** attached to the host pool ramps session hosts up before business hours and drains/deallocates them when idle, so you pay for compute only when people are working.
8. A **drain-and-patch workflow** takes hosts out of rotation gracefully (drain mode), updates them (or replaces them with a new image version), and returns them to service — so updates never disconnect an active user mid-session.

## The standard deployment model
> **Assess** your subscription, licensing, regions, and where profiles and images will live → **Configure** the Compute Gallery, build and version the golden image, and prepare FSLogix storage → **Pilot** a small host pool deployed from the image by Bicep, with FSLogix and a scaling plan → **Validate** image currency, host health, profile roaming, RBAC, and scaling against explicit pass/fail gates → **Expand** to production waves, reusing the same image, template, and scaling plan.
>
> The repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## What you can control
- **Image contents and cadence** — what is baked into the golden image, and how often a new version is built.
- **Versioning and rollback** — immutable gallery versions and multi-region replication; roll a host pool back to a prior version if a new one regresses.
- **Deployment method** — session hosts deployed reproducibly from a Bicep template pinned to a specific image version.
- **Profile storage** — FSLogix on Azure Files vs Azure NetApp Files, share sizing, redundancy, and identity (Kerberos) model.
- **Administration** — least-privilege RBAC on the AVD objects using the built-in Desktop Virtualization roles.
- **Cost** — autoscale scaling plans, ramp schedules, and capacity thresholds.
- **Updates** — drain-mode patch cycles or image-version replacement, host by host, with no mid-session disconnects.

## Scope — in
Golden-image build and capture; Azure Compute Gallery image definitions and versions; an image-build pipeline (manual-capture method plus the Azure VM Image Builder option); Bicep deployment of a host pool and session hosts from a gallery image version; FSLogix profile-container storage design and configuration on Azure Files / Azure NetApp Files; RBAC on the AVD objects; a scaling plan for cost control; and the drain/patch update workflow.

## Scope — out (covered elsewhere or by the customer)
- **End-user client access and connectivity** from Windows and macOS, workspace subscription, and the connection experience — see the companion **AVD Remote Access (Windows & macOS Clients)** solution.
- **Conditional Access / MFA policy design** for AVD sign-in — covered by the Remote Access solution and your Entra security baseline.
- **Which applications belong in the image**, application packaging/licensing, and **data-residency, records, and regulatory determinations** — these are customer business, compliance, and legal decisions; this guide provides the technical build, not the decision.
- **Production change approval** — disruptive steps (image cutover, host replacement, scaling changes) are staged behind your own change-management process.

## Authentication and connections used
- **Azure RBAC** (Owner/Contributor to build; Desktop Virtualization roles to operate) on the subscription or resource group in scope.
- **Microsoft Entra ID** for the identity that session hosts and FSLogix storage join to (Entra join, Entra Domain Services, or AD DS — verify which your tenant uses).
- **Az PowerShell modules** (`Az.Accounts`, `Az.Compute`, `Az.DesktopVirtualization`, `Az.Storage`, `Az.Resources`) for the discovery, validation, reporting, and maintenance scripts.
- **Bicep / Azure Resource Manager** for the session-host and scaling-plan deployment template.

*Feature availability, image SKUs, licensing, and any preview capabilities (for example Azure VM Image Builder regional availability or Entra-Kerberos for Azure Files) change over time — verify current availability in your tenant and region before you build.*
