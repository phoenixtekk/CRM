# Executive Summary — Device Compliance Policies (Government / GCC High edition)

## The problem

Device compliance policies are the control that decides whether a device is healthy enough to
reach corporate email, files, and collaboration — and, paired with Conditional Access, the gate
that blocks the ones that aren't. On a **GCC High** tenant, deploying them is **not** the
Commercial experience with a different sign-in. GCC High is a **physically separate US
sovereign cloud** (Azure Government, Impact Level 4/5) with **different admin portals**,
**different service endpoints**, and a **feature set that lags, limits, or omits** parts of
Commercial. Following Commercial instructions on a government tenant produces policies that
target the wrong hosts, depend on features that may not exist there, and silently fail an audit.

## The solution

This **Government (GCC High) edition** deploys Intune device compliance policies **correctly on
the sovereign cloud**. It uses the right portals (`intune.microsoft.us`,
`portal.azure.us`, `portal.office365.us`), the right US Gov Microsoft Graph endpoints
(`-Environment USGov`), and it **calls out every Commercial-vs-GCC-High parity gap** — with
Microsoft citations — at the exact step where it matters. A novice administrator can follow it
click-by-click.

## What's inside

- A **solution overview** with an explicit *Commercial vs GCC High — what's different* map.
- A **requirements guide** (verify/implement per prerequisite) in sovereign-cloud form.
- A **step-by-step implementation guide** in the GCC High portals, with parity caveats inline.
- **Five PowerShell scripts** — discovery, validation, reporting, safe remediation
  (default `-WhatIf`), and scope-targeting — all on **US Gov Graph**.
- **Testing** with pass/fail gates and a **troubleshooting** guide of GCC-High-specific gotchas.
- A **cited GCC High parity reference** so nothing is assumed.

## Why it matters

- **Correct on the sovereign cloud.** Right portals, right endpoints — no Commercial steps that
  quietly fail on a government tenant.
- **Parity gaps handled, not discovered in production.** The single most dangerous item —
  **Device Health Attestation**, which Microsoft's own docs disagree about for GCC High — is
  flagged with a concrete verification step and a documented fallback, so BitLocker/Secure
  Boot/code-integrity compliance never silently breaks.
- **Audit-ready.** Settings map to NIST SP 800-171 / CMMC control families, and the read-only
  scripts produce point-in-time evidence on demand.
- **Safe to scale.** The **Assess → Configure → Pilot → Validate → Expand** model with gates,
  a reused pilot group, and a break-glass-excluded Conditional Access policy means a single
  mistake can't take the tenant offline.

## The bottom line

**Device Compliance Policies deployed correctly on GCC High** — right portals, right endpoints,
parity gaps handled — proven on a pilot before you scale. A fraction of the cost of a
consulting engagement, and repeatable every time.
