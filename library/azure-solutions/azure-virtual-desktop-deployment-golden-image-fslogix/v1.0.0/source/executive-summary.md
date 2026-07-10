# Executive Summary — Azure Virtual Desktop: Deployment, Golden Image & FSLogix

**Azure Solutions**

Deploying Azure Virtual Desktop (AVD) by hand produces snowflake session hosts, roaming-profile pain, and a runaway bill. Every host is patched slightly differently, profiles do not follow users cleanly, and idle VMs run all night. This package builds AVD the engineered way: a **versioned golden image** produced by a repeatable build pipeline, session hosts deployed from that image by **infrastructure-as-code (Bicep)**, **FSLogix profile containers** on a correctly sized Azure Files or Azure NetApp Files share, **role-based access control** on the AVD objects, a **drain-mode patch workflow** for updates, and **autoscale scaling plans** that shut idle hosts down.

This is a complete, **deploy-it-today** package for the *build and operate* side of AVD, written for an administrator with no prior image-pipeline or IaC experience.

## Scope boundary
This solution covers the **deployment, imaging, host-pool build, FSLogix storage, and scaling** side of AVD. It does **not** re-cover end-user client access and connectivity from Windows and macOS — that is the companion **Azure Virtual Desktop Remote Access (Windows & macOS Clients)** solution. Where the two meet (host pools, workspaces, FSLogix), this guide cross-references rather than duplicates.

## What you get
- A plain-language **Solution Overview** of golden images, Azure Compute Gallery versioning, image-build pipelines, IaC session-host deployment, FSLogix storage sizing, RBAC, drain/patch, and scaling plans.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite specific to the build — a build/source VM, Azure Compute Gallery, FSLogix storage account, IaC tooling, and Azure roles.
- An **Implementation Guide** of precise, ordered steps: build and capture the golden image, version it in a gallery, deploy pilot session hosts from Bicep, wire up FSLogix, assign RBAC, apply a scaling plan, then expand.
- Five **automation artifacts** — read-only discovery, validation, and reporting scripts (PowerShell/Az), a **Bicep** session-host + scaling-plan template, and a gated drain/patch maintenance script.
- **Testing** and **Troubleshooting** guides for a confident rollout.

## What this delivers
A repeatable, cost-controlled AVD estate: session hosts built from one **versioned image** in an Azure Compute Gallery, deployed by **Bicep** (not hand-built), profiles roamed by **FSLogix** on a right-sized share, updates rolled out with **drain mode**, and idle capacity removed by an **autoscale scaling plan** — proven on a pilot host pool before you scale.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Consistent golden images, roaming profiles, IaC-deployed hosts, and automatic cost control — an AVD estate a single administrator can build, version, and operate, proven on a pilot before production.

## Effort
Roughly two to four days for a first pilot host pool (image build and capture is the longest single step), then hours per subsequent wave because the image, the Bicep template, and the scaling plan are reused.
