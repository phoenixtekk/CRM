# Executive Summary

## The problem

Pre-logon VPN — a tunnel that comes up **before** a user signs in, so a device can reach a domain
controller and a first-time user can log on off the corporate network — is powerful and fragile. When
it stops working, the failure is genuinely hard to place: the **Network sign-in** option never appears,
the device tunnel silently never connects, or authentication is rejected with no obvious reason. Worse,
there are **two different mechanisms** in play — Cisco **Start Before Logon (SBL/PLAP)** and the Windows
Always On VPN **device tunnel** — each with its own strict preconditions, and a break in any one
precondition looks like a total failure. Teams burn hours per incident guessing, and often "fix" the
wrong mechanism entirely.

## What this toolkit delivers

A **structured, precondition-by-precondition diagnostic workflow** plus **five read-only PowerShell
tools** that together isolate the missing precondition in minutes instead of hours — for **both**
mechanisms. It is a **troubleshooting/diagnostics** product: a self-guided playbook you keep and reuse
on every incident, not a fresh deployment guide.

The toolkit includes:

- **Solution Overview** — the two pre-logon mechanisms and every precondition each one needs (the SBL
  module + `vpnplap64.dll` PLAP provider + `UseStartBeforeLogon`; the device tunnel's SKU/join,
  single-tunnel, IKEv2, machine cert, and AlwaysOn rules).
- **Requirements Guide** — the device access, admin rights, and Intune/Graph read access to have ready,
  each with how to verify it.
- **Diagnostic Workflow** — the ordered **Collect → Analyze → Remediate → Verify** process and a
  symptom → tool map that sends you straight to the right check.
- **Five read-only tools** — a master collector plus focused checks for SBL/PLAP, the device tunnel,
  the certificate, and the Intune object/scope audit. All **read-only**.
- **Testing & Troubleshooting guides** — gates that prove the tool reports a known-good device healthy
  and a known-bad device's true fault, and a comprehensive symptom → cause → fix matrix covering both
  mechanisms.

## How it isolates the failure fast

Each mechanism's preconditions are checked in a **fixed order**, so the **first FAIL is the whole
reason**: no SBL tile almost always means a missing module or an unset `UseStartBeforeLogon`; a dead
device tunnel almost always means the wrong SKU/join, more than one tunnel, a non-IKEv2 type, or a
profile mis-scoped to a **user** group instead of a **device** group. The toolkit names the precondition
and hands you the remedy.

## The vendor boundary (by design)

The **Windows, Intune, Entra, and certificate side is authored at exact detail** — that's where the
scripts and precision live. The **VPN head-end / gateway internals are deferred to the vendor's
official documentation**: the toolkit tells you exactly *what evidence to read* at the gateway (did the
attempt arrive, the rejection reason, the issuing-CA it must trust) and hands you to the vendor doc for
the exact console clicks, so you never chase a fabricated menu path.

## The bottom line

The missing precondition behind a broken pre-logon VPN — SBL/PLAP or device tunnel — isolated in
minutes. A structured workflow and read-only scripts you keep and reuse on every incident, at a
fraction of the cost of consulting on each outage.
