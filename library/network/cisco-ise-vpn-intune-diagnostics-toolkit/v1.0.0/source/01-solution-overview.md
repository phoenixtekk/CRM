# Solution Overview

## What this toolkit is

This is a **diagnostics toolkit**, not a deployment guide. It assumes you already run — or are supposed to run — certificate-based VPN with a **Cisco Secure Client** connecting through **Cisco Identity Services Engine (ISE)**, where the client certificate is issued and the device is managed by **Microsoft Intune**. Something in that stack has stopped working, and the failure is hiding somewhere across four cooperating layers. This document explains the full signal path and the layered model so the root-cause tree in the **Diagnostic Playbook** (`03-implementation.md`) makes sense.

The core idea: **a VPN + posture failure is almost never "the VPN is broken."** It is one specific layer failing and cascading downstream. If you can name the layer, you can name the fix. The whole toolkit exists to help you name the layer fast.

## The four layers (the layered model)

The stack has four layers. Signal flows top-to-bottom on every connection attempt; a break at any layer looks like a failure at every layer below it.

| Layer | Name | Owner plane | What it does | Primary evidence source |
|-------|------|-------------|--------------|--------------------------|
| L1 | **Certificate / Profile** | Intune / Entra | Issues the client certificate and pushes the VPN + trusted-root profiles to the device | Intune portal, Graph, device certificate store |
| L2 | **Client Connect** | Cisco Secure Client (device) | Reads its profile, presents the certificate, opens the tunnel transport | Secure Client UI + DART logs (Cisco) |
| L3 | **EAP-TLS Chain** | ISE ⇄ device (network) | Mutually authenticates: device proves its cert, trusts the ISE/server cert, chain validates to a common root | ISE live logs (Cisco) + device cert chain |
| L4 | **Posture / Authorization** | Cisco ISE | After authentication succeeds, evaluates compliance/posture and applies an authorization result (permit, quarantine, deny) | ISE live logs (Cisco) + Intune compliance state (Graph) |

**The rule of the layered model:** diagnose **top-down**. A missing certificate (L1) makes L2, L3, and L4 all fail — but only L1 is the real fault. Always confirm the layer above is healthy before blaming the layer below. The root-cause tree enforces exactly this order.

## The full signal path (happy path, end to end)

When everything works, a single successful connection walks through these stages in order:

1. **Cert issuance (L1).** Intune delivers a certificate configuration profile (SCEP or PKCS) to the enrolled device. The device generates a key, requests a certificate, and the issuing CA returns a client authentication certificate into the device's certificate store. A matching **trusted-root / intermediate certificate profile** is also delivered so the device will trust the ISE server certificate later.
2. **Profile apply (L1 → L2).** Intune delivers the **VPN configuration profile** naming the Cisco Secure Client, the head-end/gateway address, and which certificate to use for authentication. The Secure Client on the device reads this profile.
3. **Client connect (L2).** The user (or an always-on rule) triggers the tunnel. Cisco Secure Client resolves the gateway, establishes transport, and begins the authentication handshake, presenting the L1 certificate as its identity.
4. **EAP-TLS (L3).** The device and ISE perform mutual TLS authentication. The **device** presents its client certificate and validates the **ISE server certificate** against the trusted roots from step 1; **ISE** validates the device certificate against its own trusted CA store and any certificate-authentication policy (revocation, template, SAN/CN identity mapping). Both sides must chain to a root each trusts. Success here means "we know who this device is."
5. **Posture / authorization (L4).** Authentication answers *who*; authorization answers *what they're allowed*. ISE evaluates its authorization policy — which can include a **posture/compliance signal**. In an Intune-integrated design, ISE reads the device's **Intune compliance state** (via the Entra/Graph connector) and grants full access only to a *compliant, enrolled* device; a non-compliant or unknown device is quarantined, redirected, or denied.

Only when **all four** succeed does the user get a working, authorized tunnel. The toolkit's job is to tell you **which stage stopped**.

## Where the vendor boundary sits

This toolkit authors the **Intune, Entra, and certificate side (L1, and the Intune-compliance half of L4)** at exact, click-by-click detail — that is where your read-only Graph scripts and portal checks live.

The **Cisco side is deferred to Cisco's official documentation.** Specifically:

- **Cisco Secure Client (AnyConnect) UI, profile editor, and DART log collection (L2)** — we tell you *what* evidence to gather and *what it means*, but exact menu paths belong to Cisco docs and your Secure Client version.
- **Cisco ISE live logs, RADIUS/EAP-TLS detail, certificate-auth policy, posture policy, and authorization results (L3, L4)** — we tell you *what to look for* in the ISE authentication detail (e.g. "EAP-TLS failed on certificate chain validation," "authorization matched the quarantine rule"), but ISE console navigation and posture-module specifics are Cisco's domain.

This boundary is deliberate: Cisco console layouts and ISE versions change, and fabricating menu paths would send you down wrong turns. So the tree always tells you **which ISE/Secure Client screen to open and which field to read**, then hands you to the vendor doc for the exact clicks.

## How to use the rest of this toolkit

- **`02-requirements.md`** — the read access, logs, and vantage points you need before you can diagnose. Confirm these first; a blind diagnosis wastes an incident.
- **`03-implementation.md` (Diagnostic Playbook)** — the root-cause decision tree, entered by **symptom**. This is the core deliverable. Start here during an incident.
- **`05-testing.md`** — pass/fail gates to confirm a fix actually cleared the failing layer (and didn't just move it).
- **`06-troubleshooting.md`** — deeper edge cases and the evidence checklist to hand Cisco if the fault proves to be L2/L3/L4 inside their stack.
- **`07-best-practices.md`** — repeatable triage habits, evidence collection, and clean escalation.
- **The 5 PowerShell scripts** — read-only collectors that snapshot the L1/L4-Intune evidence for you, so you spend the incident reasoning, not gathering.

**Standing constraint for the whole toolkit:** every script and check here is **read-only**. Diagnostics observe; they never remediate. You decide the fix; the toolkit only tells you where it is.
