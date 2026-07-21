# 1. Solution Overview — Remote Help — Government (GCC High) Edition

> This is the **Government (GCC High)** edition. It does **not** assume the commercial Remote Help
> deployment works — or is even available — in the US sovereign cloud. It adapts the commercial
> Remote Help solution's deployment discipline, but its **first and governing step is to establish,
> against current Microsoft documentation, whether Remote Help is available in your sovereign cloud
> tier** (GCC vs GCC High vs DoD). Where it is available, deploy it with the correct national-cloud
> plane. Where it is **not** available, this document says so plainly and gives the compliant
> alternative — it does **not** fabricate a deployment or assert commercial parity.

## The availability-first principle (read this first)

Government tenants cannot assume a commercial-cloud feature behaves the same way — or exists at all —
in the sovereign cloud. Remote Help is a case where the answer is **not uniform across the government
tiers**. Therefore **Step 1 of the Implementation Guide is a gate**: confirm availability for *your*
specific tier before configuring anything. Never deploy "Remote Help for GCC High" by copying the
commercial steps; that path silently authenticates against the wrong cloud and, on GCC High / DoD,
targets a feature that is not there.

## What Remote Help is (the capability being evaluated)

Remote Help is Microsoft's cloud-based remote-assistance application, integrated with Microsoft
Intune. A help-desk technician (the **helper**) can view and, with consent, control an enrolled
user's device (the **sharer**) — authenticated through Microsoft Entra, governed by **role-based
access control (RBAC)**, shown the device's **compliance** state, and recorded in an **audit** trail.
The service brokers sessions over port 443 to a Microsoft cloud endpoint. This overview describes the
capability; the sovereign-cloud availability of that capability is established in Step 1 and detailed
in `gcc-high-parity-notes.md`.

## The sovereign-cloud finding that drives this solution (verify against current Microsoft documentation)

At authoring time, current Microsoft documentation states the following. **Treat availability as the
gating item and re-verify it against current Microsoft docs at deployment time — sovereign-cloud
availability changes over time.**

- **GCC:** Remote Help is **supported** in Government Community Cloud (GCC) environments (except in
  Azure Virtual Desktop). Note that, for Intune, **GCC is the commercial service instance** — there
  is no separate Intune "GCC" datacenter — so a GCC deployment uses the **commercial** endpoints, not
  the `*.us` sovereign endpoints. *(Source: Microsoft Learn, "Plan for Remote Help with Microsoft
  Intune"; "Microsoft Intune Government Service overview." Verify against current Microsoft
  documentation.)*
- **GCC High / DoD:** Remote Help **is not supported** on GCC High or DoD tenants. Microsoft lists
  Remote Help under **"Intune features planned for GCC High and DoD"** — planning has started, and no
  ETA is published. There is currently **no** sovereign Remote Help service to deploy on the `*.us`
  plane. *(Source: Microsoft Learn, "Plan for Remote Help with Microsoft Intune"; "Microsoft Intune
  Government Service overview." Verify against current Microsoft documentation — this is the item most
  likely to change.)*

So this edition resolves into **two honest branches**, decided by the availability gate in Step 1:

| Your tier | Availability (verify) | What this solution does |
|---|---|---|
| **GCC** | Supported (commercial instance; not AVD) | Deploy Remote Help using the **commercial** endpoints and the platform limits below. |
| **GCC High / DoD** | **Not supported** (planned, no ETA) | **Do not** deploy Remote Help. Select a **compliant alternative** for governed remote assistance within your authorization boundary, and monitor the Microsoft roadmap. |

## What this adapts from the commercial solution

The commercial Remote Help solution's discipline is preserved and re-verified for the sovereign
cloud: name every object you create, enable least-privilege RBAC, deploy the app as Required, pilot a
real session before expanding, and validate with scripts against pass/fail gates. What changes here
is the **cloud plane** (sovereign `*.us` admin portals and US Gov Graph for GCC High / DoD, versus
commercial for GCC) and, above all, the **availability gate** that decides whether a Remote Help
deployment is even the right work — or whether the compliant alternative is.

## Security model (where Remote Help is available)

- **Entra-authenticated** helpers and sharers — no anonymous access; all participants in the **same tenant**.
- **RBAC** — least-privilege built-in or custom Intune roles (e.g. **Help Desk Operator**) control view / full control / elevation / unattended.
- **Compliance visibility** — helpers see the device compliance state before connecting.
- **Consent** — sessions are consensual and visibly indicated on the sharer's screen; no session recordings are stored by the service.
- **Audited** — who helped whom, when, and features used are logged (retained ~30 days by Microsoft — verify against current Microsoft documentation).

## Benefits

- **Honest** — you learn *before* you build whether Remote Help is available for your tier, so you don't burn a rollout on a feature that isn't in GCC High / DoD.
- **Sovereign-correct** — where you administer on the `*.us` plane, you do so deliberately (GCC High / DoD), and where GCC uses the commercial instance, the document says so instead of forcing a wrong `*.us` path.
- **Compliant fallback** — if Remote Help is unavailable for your tier, you get a decision framework and a compliant alternative, not a fabricated deployment.
- **Least privilege + audited** — the same governed, consent-based assistance model the commercial edition delivers, where the feature exists.

## Limitations (be honest with buyers)

- **The headline limitation:** Remote Help is **not available on GCC High / DoD** at authoring time. If that is your tier, this solution guides you to the compliant alternative rather than a Remote Help deployment. Re-verify against current Microsoft documentation.
- Requires a **Remote Help license** (an add-on to Intune Plan 1/2) for **every** helper and sharer — where the feature is available.
- In GCC, Remote Help is **not** supported in **Azure Virtual Desktop (AVD)**, and platform support is a subset (see the parity notes).
- **Conditional Access for Remote Help helpers is supported only on Windows and macOS** (verify against current Microsoft documentation).
- Sessions require the Remote Help **service endpoint** to be reachable; do not SSL-inspect that traffic.
- Cross-tenant assistance is not supported — all participants must be in the same tenant.

## The standard deployment model

> **Establish availability (gate) → [if available] configure the correct national-cloud plane →
> licensing → security/consent + RBAC → deploy the app → pilot a governed session → validate → expand;
> [if unavailable] select the compliant alternative and validate it.**
> Pattern: **Assess → Configure → Pilot → Validate → Expand.** Assessment here explicitly includes the
> availability gate.
