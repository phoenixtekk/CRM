# Executive Summary

**Outcome.** Reliable Microsoft 365 sign-in — either a healthy, diagnosable **ADFS federation** or a
cleanly retired path to **managed cloud authentication**. For most organizations, replacing on-premises
ADFS with cloud authentication removes a fragile single point of failure (certificate-expiry outages,
on-premises dependency, claims errors) and simplifies operations, while preserving the sign-in experience
users expect.

**The problem.** Many enterprises still authenticate to Microsoft 365 through **ADFS**. When it works,
few notice; when a **token-signing certificate** lapses, a **claims rule** is wrong, or the **ADFS/WAP**
service or on-premises network fails, **every federated user is locked out** of Microsoft 365. Managed
cloud authentication does not carry that on-premises sign-in dependency.

**The approach.** This solution covers both jobs. Where federation stays, it makes ADFS **healthy and
diagnosable** — verifying claims rules, rolling the **token-signing certificate** safely, and confirming
endpoints, WAP, and the Microsoft Entra federation trust. Where the organization is ready to simplify, it
runs a **staged, reversible migration** to **Password Hash Sync** or **Pass-through Authentication** with
**Seamless SSO**: pilot selected users with **Microsoft Entra Connect Staged Rollout** (while the domain
stays federated), validate, convert the domain **federated → managed**, then **decommission ADFS/WAP** —
keeping the farm parked until the change is proven.

**Why it's low-risk.** Every change is **pilot-first with a documented rollback**. Staged Rollout proves
the target sign-in path on a small group **without converting the domain**, and is reversible per user.
Conditional Access parity is established **before** conversion so no access control is silently lost.
Provided PowerShell tooling is **safe-by-default** — read-only assessment and reporting, and change
helpers that **preview with `-WhatIf`** and only act on an explicit commit, with **no credentials stored
in code**. The result: fewer moving parts, fewer outages, and a modern security posture — delivered
self-guided at a fraction of a bespoke consulting engagement.
