# Executive Summary — Microsoft Tunnel for MAM (Mobile Access to Intranet Resources) — Government (GCC High) Edition

**Solution code:** TUNMAMG · **Platform:** Microsoft Intune · **Cloud:** US Sovereign (GCC High / DoD)

## The business problem
Government agencies, DoD components, and defense-industrial-base contractors need staff to reach **internal, on-premises applications** from **personal mobile devices** — without enrolling those devices in full management and without standing up costly legacy VPN infrastructure. The obstacle in the sovereign cloud is that **Government (GCC High / DoD) is not Commercial with a different sign-in**: the admin portals, service endpoints, and gateway install differ, and a Commercial runbook applied to a Government tenant **silently fails** (most often a Tunnel Gateway that installs but never appears in the admin center).

## The solution
This is the **Government (GCC High) edition** of the Microsoft Tunnel for MAM deployment. **Microsoft Tunnel for MAM** extends the Microsoft Tunnel VPN Gateway to **unenrolled Android and iOS/iPadOS devices**, giving users secure, app-scoped access to intranet resources through **Microsoft Edge and MAM-integrated line-of-business apps** — with modern authentication, single sign-on, Conditional Access, and app protection — while IT never takes control of the personal device.

The solution is packaged specifically for the US sovereign cloud: the correct **`*.us`** portals, the **`intune_env=FXP`** Government gateway install flag, **US Gov Microsoft Graph** endpoints in every script (`-Environment USGov` / `USGovDoD`), and every **Commercial-vs-Government parity gap** documented at the step where it matters.

## Availability finding (important)
**Tunnel for MAM is fully supported in both GCC High and DoD** — Microsoft lists it among the Intune advanced capabilities available in those environments (verified 2026). This is not a feature you must work around in Government. **However, it does not support FIPS** on the Android or iOS data path — a compliance-relevant constraint that must be reviewed and accepted by your ISSO/ISSM before deployment. Certificate issuance should plan on an **enterprise or public CA**, because **Cloud PKI is GCC-High-only and still "planned."**

## What the customer receives
- **Seven implementation documents** — overview (with a Commercial-vs-GCC-High comparison and availability caveat up front), requirements, click-by-click implementation in the Government portals, testing with pass/fail gates, troubleshooting, best practices, and a cited **GCC High parity reference**.
- **Five PowerShell scripts** — Discovery, Validation, Report (read-only), plus safe Remediation and Scope-Targeting (default **`-WhatIf`**) — all connecting to **US Gov Graph**.
- A gated deployment path — **Assess → Configure → Pilot → Validate → Expand** — so the design is proven on a pilot before it scales.

## Business outcome
A **correctly configured** Tunnel-for-MAM deployment on a GCC High / DoD tenant: BYOD access to intranet resources without device enrollment, the sovereign endpoints right the first time, parity gaps handled, and the no-FIPS decision made consciously — delivered self-guided at a fraction of the cost of a bespoke consulting engagement.

---
*White-label solution. Verify all GCC-High/DoD specifics against current Microsoft US Government documentation at deployment time.*
