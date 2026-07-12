# 1. Solution Overview — Enablement Kit: Identity Modernization with Entra

## What this kit is
This is a self-guided **enablement kit**: a training deliverable that teaches an admin team how to
modernize identity on Microsoft Entra. It combines concepts, guided hands-on labs, a take-home
runbook, and a knowledge-check. It is not a production implementation project — it builds the
understanding and muscle memory the team needs before (and while) they drive the real modernization,
and it points to the dedicated implementation solutions for each building block.

## What "identity modernization" means
Identity modernization is the move from a legacy, perimeter-and-password model to a cloud-first Zero
Trust model on Microsoft Entra ID:

- **From** on-premises Active Directory as the center of gravity, AD FS federation, per-user MFA,
  legacy authentication protocols (POP/IMAP/SMTP/older Office), passwords as the primary factor, and
  static group-based access.
- **To** Entra ID as the identity control plane: **Conditional Access** as the policy engine,
  **Identity Protection** feeding risk into those policies, **passwordless / phishing-resistant MFA**
  (FIDO2 passkeys, Windows Hello for Business, certificate-based auth), **identity governance**
  (access packages, access reviews, PIM) for least privilege and lifecycle, and **Global Secure
  Access (GSA)** extending Zero Trust to network access.

The legacy world is not switched off overnight — most organizations run a **coexistence** period
where hybrid sync and modern controls operate side by side. Teaching that coexistence, and the safe
order of moves, is a core purpose of this kit.

## The Entra target-state architecture (the building blocks)
1. **Entra ID directory** — the cloud identity source; users and groups (cloud-only or synchronized
   from AD during coexistence).
2. **Conditional Access (CA)** — the policy engine. Every access decision (who, what app, what
   device, what risk) is evaluated here. Requires Entra ID P1. *Verify current licensing in your tenant.*
3. **Identity Protection** — risk detection (risky users, risky sign-ins) that CA consumes as signal.
   Risk-based CA and the full risk experience require **Entra ID P2**. *Verify in your tenant.*
4. **Passwordless & phishing-resistant authentication** — FIDO2 security keys / passkeys, Windows
   Hello for Business, certificate-based authentication, and Microsoft Authenticator, managed through
   the **Authentication methods** policy.
5. **Identity governance** — entitlement management (access packages), access reviews, and Privileged
   Identity Management (PIM). Governance features (access reviews, entitlement management, PIM)
   require **Entra ID P2 / Entra ID Governance**. *Verify in your tenant.*
6. **Global Secure Access (GSA)** — identity-centric Secure Web Gateway / private access, extending
   Conditional Access to network traffic. Licensing and some capabilities are evolving — *verify
   current availability and licensing in your tenant.*
7. **Break-glass and monitoring** — emergency access accounts excluded from policy, plus sign-in and
   audit logs (optionally streamed to Log Analytics / Microsoft Sentinel) for the KQL analysis in
   this kit.

## The legacy → modern journey (what the team learns to sequence)
1. **Baseline** the current estate — where identities live, what authenticates them, what legacy
   protocols are still in use, MFA registration coverage, and federated domains.
2. **Establish safety** — break-glass accounts, report-only Conditional Access, and pilot scoping.
3. **Introduce modern controls in report-only / pilot** — CA baseline, Identity Protection signals,
   MFA registration campaigns.
4. **Move authentication forward** — from per-user MFA to CA-driven MFA; from passwords toward
   passwordless / phishing-resistant methods.
5. **Layer governance** — access reviews, access packages, and PIM for privileged roles.
6. **Extend Zero Trust to the network** — Global Secure Access.
7. **Retire legacy** — decommission AD FS / legacy auth once coexistence is proven.

## The standard deployment model
Every solution in this catalog follows the same shape, and this kit teaches the team to apply it to
each building block:

> **Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — run the read-only discovery and score the current posture.
- **Configure** — build the control in report-only / preview, scoped to the lab pilot group.
- **Pilot** — apply it to the small pilot lab group only.
- **Validate** — confirm the intended effect (What-If, sign-in logs, the knowledge-check) with
  explicit pass/fail gates.
- **Expand** — only after validation, widen scope in staged rings.

## Scope of this kit
- **In scope:** teaching the modernization journey and target-state architecture; guided, pilot-scoped
  labs for CA, Identity Protection, passwordless, governance, and GSA; migration/coexistence patterns
  (AD FS / hybrid → cloud); a take-home runbook and a knowledge-check; read-only discovery, validation,
  reporting, and KQL analysis helpers.
- **Out of scope (by design — use the dedicated implementation solutions):** production rollout of any
  single building block at scale. This kit deliberately does **not** duplicate the deep
  implementation guides. For production work, cross-reference:
  - **Zero Trust Conditional Access baseline** (ENTZTCA) — the full CA baseline rollout.
  - **Entra Passwordless / FIDO2 passkey rollout** (ENTPASSKEY) — production passwordless.
  - **Entra ID Governance — PIM & Access Reviews / Entitlement** (ENTPIM / ENTIGA) — governance at scale.
  - **Hybrid Identity with AD & Entra Connect** (HYBID) and the **Hybrid Identity Enablement Kit**
    (EKHYBID) — the sync / coexistence layer.
  - **Enterprise App & Service Principal Governance** and the **SAML App Factory** — app modernization.
  - **Global Secure Access** solution — production GSA.
- **Not covered / deferred to the customer:** regulatory, records, and legal determinations;
  data-classification decisions; and production change-approval sign-off. This kit provides the
  technical understanding and controls, not those decisions.

## Authentication and connections used
- **Microsoft Entra admin center** (`https://entra.microsoft.com`) and **Microsoft 365 admin center**
  for portal labs.
- **Microsoft Graph PowerShell SDK** (`Microsoft.Graph`) for read-only discovery, validation, and the
  safe lab-setup helper — using delegated, least-privilege scopes.
- **Az PowerShell** (optional) where Azure / Log Analytics context is used.
- **Log Analytics / Microsoft Sentinel** (optional) for running the KQL signal pack against
  `SigninLogs` and related tables — *requires diagnostic settings to export Entra logs; verify in your
  tenant.*
