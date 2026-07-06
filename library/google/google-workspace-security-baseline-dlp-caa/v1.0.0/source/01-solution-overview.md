# 1. Solution Overview — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

A new or freshly-adopted Google Workspace tenant is **not secure by default at enterprise
standard**. The out-of-the-box posture leaves two-step verification optional, sessions long-lived,
Drive/Gmail sharing wide open, no Data Loss Prevention (DLP) on sensitive content, and access
granted from any device on any network. This solution closes that gap by establishing a repeatable
**Google Workspace security posture** built from three reinforcing layers, deployed **pilot-first**
and **rollback-ready**.

> **Vendor boundary.** Google **Admin console** (admin.google.com) paths and settings are authored
> at click-by-click detail from Google's current public documentation. Feature availability is
> **edition-gated** — several controls (Context-Aware Access, and the full DLP for Drive/Gmail rule
> engine) require **Enterprise / Education Plus / Enterprise Plus** tiers — and those gates are
> flagged where they apply. Where a page or toggle is evolving, it is flagged **"verify in your
> tenant."**

## The Workspace security model — three layers, one posture

### Layer 1 — Admin-console hardening baseline (identity & session hygiene)
The foundation is a **named, documented baseline** of admin-console settings applied to the
organization:
- **2-Step Verification (2SV)** enforced (phone prompt → security key / passkey for
  privileged accounts), with a **new-user enrollment grace period** so onboarding is not broken.
- **Google session control** set to a bounded reauthentication window (e.g. 8–12 hours web
  session) instead of indefinite sessions that let a stolen cookie bypass 2SV forever.
- **Sharing settings** for Drive & Docs tightened: external sharing constrained, "anyone with the
  link" curtailed, warnings on outside-domain sharing.
- **Less-secure surfaces closed**: legacy/basic-auth protocols, unrestricted third-party app
  access (OAuth app allow-listing), and super-admin count minimized.

This layer is **edition-independent** — every Workspace tenant should have it.

### Layer 2 — Data Loss Prevention (DLP) for Drive & Gmail
Baseline hygiene stops account takeover; **DLP stops the data itself from leaking**. Using the
Admin console **Data protection** engine, named rules scan **Drive** files and **Gmail** messages
for sensitive content (credit-card numbers, national IDs, health/financial data, or custom
word-list / regex detectors) and take a graded **action** — **audit → warn → block** — when a rule
matches. DLP for Drive/Gmail rule authoring is an **Enterprise-tier** capability (see Requirements).

### Layer 3 — Context-Aware Access (CAA) — the Zero-Trust gate
Even a hardened, DLP-protected tenant grants access from **any device, any network** by default.
**Context-Aware Access** adds the Zero-Trust gate: **access levels** define the *context* required
to reach an app — corporate IP range, an encrypted / screen-locked / company-owned device, a
minimum OS, an allowed region — and **assignments** bind those levels to apps (Drive, Gmail,
Admin console) per organizational unit or group. CAA requires an **Enterprise / Education**
edition and works best with **monitor mode** first (simulate before enforce). This is what turns
"correct password + 2SV" into "correct password + 2SV **from a trusted context**."

## How the three layers enforce Zero-Trust
Zero-Trust means *never trust, always verify* on **identity**, **device/context**, and **data**:
- **Identity** is verified by the hardening baseline (2SV, bounded sessions, minimized admins).
- **Device & context** are verified by CAA access levels (trusted network / managed, encrypted
  device / allowed region) before an app will open.
- **Data** is protected by DLP regardless of who the user is — sensitive content cannot be
  over-shared or emailed out even by a legitimately-authenticated user.

Together they move the tenant from *implicit trust* to *explicit, contextual, data-aware trust*.

## Deployment model — Assess → Configure → Pilot → Validate → Expand
Every change follows the category-standard staged model with explicit gates and a documented
rollback (mandatory for production changes):

1. **Assess** — discover current posture (2SV coverage, session length, sharing exposure, DLP/CAA
   presence) with `GWSEC-Discovery.ps1`; identify the risky defaults.
2. **Configure** — apply the named hardening baseline, author DLP rules in **audit** mode, and
   create CAA access levels in **monitor** mode — scoped to a **pilot OU**, not the whole org.
3. **Pilot** — enable on the pilot OU (e.g. `Security Baseline - Pilot`); confirm no legitimate
   work is broken. **Gate:** baseline applied, DLP fires on test content, CAA gates as designed.
4. **Validate** — run `GWSEC-Validation.ps1` per OU and `GWSEC-Report.ps1` for coverage/exceptions;
   promote DLP audit→block and CAA monitor→enforce only after clean results.
5. **Expand** — roll out OU-by-OU to the fleet, keeping the rollback (re-widen sharing, drop
   session enforcement, set DLP/CAA back to audit/monitor) documented at every step.

## What this solution delivers
- The **Solution Overview** (this document) — the Workspace security model.
- A **Requirements Guide** — edition, super-admin, identity/context signals, and pilot OU, each
  with verify / implement-if-missing.
- An **Implementation Guide** — the exact, named hardening baseline; DLP rules for Drive/Gmail;
  CAA access levels + assignments; pilot then expand.
- **5 PowerShell scripts** — security-posture discovery, per-OU baseline/DLP/CAA validation, a
  posture coverage/exception report, safe (default `-WhatIf`) remediation, and a pilot-scope helper.
- **Testing, Troubleshooting, and Best-Practices** guides plus a deliverables summary.

**Bottom line:** a Google Workspace tenant hardened to enterprise standard — baseline, DLP, and
Context-Aware Access enforcing Zero-Trust — proven on a pilot before you scale.
