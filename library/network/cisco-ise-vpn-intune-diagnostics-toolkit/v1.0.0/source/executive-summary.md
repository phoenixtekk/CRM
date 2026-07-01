# Executive Summary

## The problem

When a certificate-based VPN or ISE posture check stops working, the failure is genuinely hard to place. The Cisco Secure Client + Cisco ISE + Microsoft Intune stack spans **four cooperating layers** — the Intune certificate/profile, client connect, the EAP-TLS chain, and ISE posture/authorization — and a break in any one layer *looks identical to* a break in every layer below it. Teams burn hours per incident guessing, and escalate to Cisco blind, without the evidence that would resolve the case in one round.

## What this toolkit delivers

A **structured, layered root-cause tree** entered by symptom, plus **five read-only PowerShell diagnostic scripts**, that together isolate the failing layer in minutes instead of hours. It is a **troubleshooting/diagnostics** product — a self-guided playbook you keep and reuse on every incident — not a fresh deployment guide.

The toolkit includes:

- **Solution Overview** — the full signal path (cert issuance → profile apply → client connect → EAP-TLS → posture/authorization) and the four-layer model behind the tree.
- **Requirements Guide** — the read access, logs, and vantage points to have ready, each with how to verify it.
- **Diagnostic Playbook** — the decision tree by symptom (no cert; cert but no chain; client won't connect; EAP-TLS fails; connected but denied by posture; nobody connects), each branch naming the layer it isolates, the exact checks, and the typical fix.
- **Five PowerShell scripts** — end-to-end collection, certificate + chain validation, compliance/enrollment check (as ISE reads it), VPN client + profile check, and a consolidated cross-layer report. All **read-only**.
- **Testing & Troubleshooting guides** — pass/fail gates mapping each fix back to the tree, plus edge cases and a Cisco escalation evidence checklist. Best-practice triage for repeatable, auditable diagnosis.

## How it isolates the failure fast

The tree is worked **top-down**: prove each layer healthy before descending, so an L1 certificate fault can't masquerade as an L3 authentication failure. Most EAP-TLS and posture symptoms resolve back to a certificate/trust fact or a compliance-connector fact — the tree is built to send you straight there.

## The vendor boundary (by design)

The **Intune, Entra, and certificate side is authored at exact, click-by-click detail** — that's where the scripts and precision live. **Cisco ISE live logs and Secure Client DART collection are deferred to Cisco's official documentation**: the toolkit tells you exactly *what evidence to read* (the EAP-TLS failure reason, the matched authorization rule) and hands you to the vendor doc for the exact console clicks, so you never chase a fabricated menu path.

## The bottom line

The failing layer of a Cisco VPN + ISE + Intune stack, isolated in minutes — a structured playbook and read-only scripts you keep and reuse on every incident, at a fraction of the cost of consulting on each outage.
