# Solution Overview — Pre-Logon VPN for Cloud & Hybrid-Joined Devices: First-Time Off-Network Sign-In & Password Reset

## What this solution is

This solution is the **decision, scenario, and validation layer** for pre-logon VPN. It answers the
two questions that a remote-first fleet actually gets stuck on:

1. **A brand-new employee's laptop is off the corporate network and has *no cached credentials* —
   how do they complete their *first* Windows sign-in?**
2. **A remote user's password has *expired* while off-network — how do they *change* it at the
   logon/lock screen when the password change has to reach a domain controller?**

Both problems have the same root cause: the network is not up *before* Windows sign-in, so the
device cannot reach a **domain controller (DC)** at the moment it needs one. **Pre-logon VPN** solves
both by bringing the tunnel up **before or at** the Windows credential prompt.

This solution does **not** re-teach the two deployment builds that create a pre-logon tunnel. Those
are **separate products** (see below). This product tells you **which approach to choose**, **how the
two scenarios actually behave** by device join type, and **how to validate end to end** that a
never-logged-on user and an expired-password user can both get in from off the network.

## What this solution is NOT (and where to get it)

- It does **not** contain the step-by-step **Always On VPN device-tunnel** build. That is the
  companion product *Always On VPN — Device Tunnel (Pre-Logon) via Intune*, which creates the
  device-tunnel profile named `AOVPN – Device Tunnel – ProfileXML – Windows` (plus its trusted-root
  and machine-certificate profiles).
- It does **not** contain the step-by-step **Start Before Logon (SBL/PLAP)** build. That is the
  companion product *Pre-Logon VPN — Cisco Secure Client (SBL/PLAP) via Intune*, which creates the
  Win32 app named `Cisco Secure Client – Pre-Logon (SBL) – Win32` (plus its SBL profile).

This product **references those objects by name** so the three pieces stay coherent, but it does not
duplicate their builds. If you have not deployed either approach yet, you run this decision guide
**first** to pick the right one, then implement the chosen companion product, then return here to
validate the two scenarios.

## The two approaches you are choosing between

Pre-logon connectivity comes from one of two mechanisms. This solution's job is to help you pick the
right one for your fleet — not to reconfigure them.

### Approach A — Windows Always On VPN **device tunnel**
- **What it is:** A machine-level IKEv2 VPN that Windows brings up **automatically at boot, before
  any user signs in**, authenticated by a **machine certificate** (no user interaction).
- **Hard requirements (facts):** the device must be **domain-joined or Entra hybrid-joined**, run
  **Windows Enterprise or Education** SKU, hold a **machine certificate** the VPN gateway trusts, and
  the gateway must support **IKEv2**.
- **Best when:** you want a *silent, always-available* DC path for every managed Windows device with
  no user action, and you own the PKI + an IKEv2-capable gateway.
- **Object it deploys (companion product):** `AOVPN – Device Tunnel – ProfileXML – Windows`.

### Approach B — Cisco Secure Client **Start Before Logon (SBL / PLAP)**
- **What it is:** A **Windows credential provider (PLAP)** that lets the user bring up the Cisco
  Secure Client VPN **at the Windows logon screen**, *before* submitting their Windows credentials.
- **Hard requirements (facts):** Windows only; the Secure Client with the **SBL/PLAP** module
  installed; a reachable Cisco head-end. It is **user-initiated at the logon screen**, not silent.
- **Best when:** you already run Cisco Secure Client (AnyConnect), you cannot meet the device-tunnel
  SKU/PKI/IKEv2 requirements, or you want the user to choose the network before signing in.
- **Object it deploys (companion product):** `Cisco Secure Client – Pre-Logon (SBL) – Win32`.

## The decision matrix (summary)

| Factor | Device tunnel (A) | SBL / PLAP (B) |
|---|---|---|
| Join type supported | Domain-joined **or** Entra hybrid-joined | Domain-joined **or** hybrid-joined (Windows) |
| OS SKU | **Enterprise / Education required** | Any Windows Pro/Enterprise (per Cisco support) |
| Auth at pre-logon | **Machine certificate (silent)** | User brings up VPN at logon screen |
| Tunnel protocol | **IKEv2** | Cisco Secure Client (per head-end) |
| User action needed | **None** (auto at boot) | User connects at the logon screen |
| Existing VPN vendor fit | Native Windows / any IKEv2 gateway | You already run Cisco Secure Client |
| Entra-joined (cloud-only) devices | Usually **not needed** (see below) | Usually **not needed** (see below) |

The full matrix, with a step-by-step "choose the approach" procedure, is in `03-implementation.md`.

## Why join type is the whole story

The first-logon / DC-reachability problem is fundamentally a **hybrid-joined / domain-joined**
problem — because those devices authenticate the user against **Active Directory**, which lives on a
**domain controller** the device must reach.

- **Entra-joined (cloud-only) devices** authenticate the user against **Entra ID in the cloud**, not
  against an on-prem DC. A first sign-in works over ordinary internet with no pre-logon tunnel, and a
  password change is a **cloud** operation. These devices **largely avoid** the classic first-logon
  and off-network password-change problems this product solves. Do not deploy a pre-logon tunnel to
  solve a problem an Entra-joined device does not have.
- **Entra hybrid-joined and domain-joined devices** still need a DC for the *interactive* logon of a
  user who has **never signed in on that device** (no cached credentials) and for an **AD password
  change**. These are the devices pre-logon VPN is for.

Getting this right up front avoids the two most common mistakes: deploying a pre-logon tunnel to
cloud-only devices that never needed it, and expecting SSPR (a cloud feature) to fix an on-prem AD
password change on a hybrid device.

## Scenario 1 — First-time off-network logon

A new hire's hybrid-joined laptop is shipped to their home. They have **never logged on** to that
device, so Windows has **no cached credential** for them. Without a DC in reach at the logon screen,
the *first* interactive logon cannot be validated and fails.

- **Cached credentials** only help a user who has **already** signed in on that device — Windows
  caches a verifier after a successful DC logon. A never-logged-on user has **nothing cached**, so
  they **require** a live DC path for the first logon.
- **Pre-logon VPN provides that path.** Device tunnel (A) brings the DC into reach automatically
  before the logon screen; SBL/PLAP (B) lets the user bring it up at the logon screen. Either way,
  the first interactive logon can now reach a DC and succeed.
- **Validation** (see `05-testing.md`, T1) proves a freshly provisioned device with a never-logged-on
  user completes first logon off-network via the pre-logon tunnel.

## Scenario 2 — Off-network password change / reset

A remote user's password has **expired**. Windows prompts them to change it at the logon/lock
screen — but an **Active Directory password change** must be written to a **domain controller**. Off
the network with no pre-logon tunnel, the change cannot reach a DC and fails.

- **The tunnel must be up so the change reaches a DC.** With device tunnel (A) the machine tunnel is
  already up at the lock screen; with SBL/PLAP (B) the user brings the tunnel up first, then changes
  the password. The Kerberos/AD password change then completes against the DC.
- **SSPR (Entra self-service password reset) is the cloud-native complement.** For **Entra-joined**
  users, SSPR changes the cloud password and there is no on-prem DC dependency. For **hybrid** users,
  SSPR with **password writeback** can reset the *directory* password, but the **Windows on-prem
  credential at the lock screen still expects an AD change that reaches a DC** — SSPR does **not**
  remove the need for a DC path for the local interactive password change on a hybrid/domain-joined
  device. Treat SSPR as complementary, not a replacement, and validate the actual behavior (T2).

## Break-glass and fallback

Pre-logon VPN is infrastructure, and infrastructure fails. This solution documents the fallbacks:

- **Local administrator account** on the device for recovery (kept per your security policy).
- **Temporary Access Pass (TAP)** in Entra for passwordless first sign-in / recovery where the flow
  is cloud-capable.
- **What to do if pre-logon VPN fails** — bring the device on-network once (office/known network),
  use SBL/PLAP as a manual fallback where a silent device tunnel did not come up, or use SSPR/TAP for
  the cloud-capable paths. Full guidance is in `06-troubleshooting.md`.

## Benefits

- **The right approach, chosen once.** A defensible device-tunnel-vs-SBL decision by join type, OS
  SKU, existing vendor, and support model — not a coin toss.
- **The two hard scenarios actually covered.** First-time off-network logon and off-network password
  change, explained by join type and validated end to end.
- **No cloud-only over-deployment.** Clear guidance that Entra-joined devices usually need neither
  approach, so you don't ship a tunnel where none is required.
- **Coherent with the deployment products.** Objects are referenced by their exact companion-product
  names, so the decision, the build, and the validation all line up.
- **Reportable readiness.** The included scripts report join types across the fleet and which devices
  already have a pre-logon path, so you know your coverage before an employee is stranded.

## Limitations and boundaries

- **This is the decision + scenario + validation layer, not a deployment build.** The device-tunnel
  and SBL/PLAP step-by-step builds live in their companion products and are referenced, not repeated.
- **Vendor and OS internals are deferred.** IKEv2/ProfileXML internals and the Cisco head-end / SBL
  module internals follow the companion products and the **vendor's official documentation**.
- **Active Directory and PKI are assumed.** A reachable DC (through the tunnel) and, for the device
  tunnel, a machine-certificate PKI path are prerequisites, not deliverables.

## The standard model

This solution follows the category-standard model, with explicit pass/fail gates — but framed around
**scenario validation** rather than profile creation:

**Assess → Configure → Pilot → Validate → Expand**

1. **Assess.** Inventory device join types and existing pre-logon capability; confirm prerequisites.
2. **Configure.** *Choose* the approach with the decision matrix and confirm the chosen companion
   product's objects exist; segment the pilot users.
3. **Pilot.** Put a representative pilot cohort (hybrid + domain-joined + one Entra-joined control)
   into `PILOT – Pre-Logon First-Logon Users`.
4. **Validate.** Run the two decisive scenario tests (first-logon, password-change) end to end.
5. **Expand.** Widen to production, monitor readiness coverage, keep the break-glass fallback ready.

Proceed to the **Requirements guide** (`02-requirements.md`) to confirm you are ready to decide and
validate.
