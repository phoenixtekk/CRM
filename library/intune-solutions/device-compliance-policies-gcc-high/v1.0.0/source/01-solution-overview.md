# Solution Overview — Device Compliance Policies (Government / GCC High edition)

## What this solution does

Microsoft Intune **device compliance policies** define the health and security rules a
device must meet — encryption, minimum OS build, firewall, antivirus, a maximum risk
score, and more — and mark each device **compliant** or **noncompliant**. Paired with a
Conditional Access policy, that compliant/noncompliant signal becomes the gate that lets a
trusted device reach email, SharePoint, and Teams while a noncompliant device is blocked.

This is the **Government (GCC High) edition** of that solution. It deploys device
compliance policies on a **US sovereign-cloud** Intune tenant — Government Community Cloud
High (GCC High) — using the correct sovereign portals and endpoints, and it calls out every
place where GCC High differs from the Commercial cloud so a government tenant is configured
correctly rather than with Commercial steps that silently fail.

> **Who this is for.** Defense-industrial-base contractors, federal agencies, and any
> organization on a **GCC High** (Impact Level 4/5) tenant subject to **DFARS 7012,
> NIST SP 800-171, or CMMC**. If your Intune admin center is `intune.microsoft.us` and you
> sign in at `login.microsoftonline.us`, this is your edition. If your admin center is
> `intune.microsoft.com`, use the **Commercial** edition instead.

## Commercial vs GCC High — what's different

GCC High is **not** the Commercial portal behind a different sign-in. It is a **physically
separate datacenter** built on Microsoft Azure Government, shared by GCC High and DoD
tenants, and locked down for government customers only.
[[MS-GOV-SVC]](gcc-high-parity-notes.md) The differences that matter for device compliance:

| Area | Commercial | GCC High (this edition) |
| --- | --- | --- |
| Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Sign-in / identity (Entra) | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Azure portal | `portal.azure.com` | **`portal.azure.us`** |
| Microsoft 365 admin | `admin.microsoft.com` | **`portal.office365.us`** |
| Company Portal service | `portal.manage.microsoft.com` | **`portal.manage.microsoft.us`** |
| Microsoft Graph (PowerShell/API) | `graph.microsoft.com` (Global) | **`graph.microsoft.us`** via **`-Environment USGov`** |
| Service backbone | Commercial Azure | **Azure Government (IL4/IL5)** |
| Feature availability | Full, first | **Some features absent, limited, or delayed** — see parity notes |

> **Verify for GCC High — the portal URL.** Microsoft's published US Government designated
> endpoints list the Intune admin center as **`https://intune.microsoft.us/`**. Some older
> material (and the Commercial `endpoint.microsoft.com` redirect) references an
> `endpoint.microsoft.us` host; treat **`intune.microsoft.us`** as the authoritative admin
> URL and confirm it loads for your tenant before relying on any other host.
> [[MS-GOV-EP]](gcc-high-parity-notes.md)

The **compliance-relevant parity gaps** — features that change how you author or validate
compliance on GCC High — are collected, with sources, in
**`gcc-high-parity-notes.md`**. The headline ones:

- **Windows Device Health Attestation (DHA)** — the attestation service behind
  *Require BitLocker*, *Require Secure Boot*, and *Require code integrity* — is listed by
  Microsoft's Government Service overview among features **planned but not yet available** in
  GCC High and DoD, while the Windows compliance-settings reference states DHA runs across
  Commercial, GCC High, and DoD. **This is a contradiction in Microsoft's own docs — verify
  for your GCC High tenant before you depend on these three settings.**
  [[MS-GOV-SVC]](gcc-high-parity-notes.md) [[MS-WIN-COMPL]](gcc-high-parity-notes.md)
- **Mobile Threat Defense (MTD)** compliance signals work **only if your MTD vendor also
  supports GCC High** — fewer partners are available than on Commercial.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md)
- **Chrome Enterprise Connector** (ChromeOS compliance) is **not available** in GCC High/DoD.
  [[MS-GOV-SVC]](gcc-high-parity-notes.md)

## The deployment model

This solution follows the standard, repeatable model used across every solution in this
library:

**Assess → Configure → Pilot → Validate → Expand**, with a **gate** between each stage — you
do not advance until the current stage's exit criteria are met.

1. **Assess** — confirm you are on a GCC High tenant, licensing, roles, sovereign portal
   access, and network endpoints (see `02-requirements.md`).
2. **Configure** — author the baseline compliance policies in `intune.microsoft.us`
   (see `03-implementation.md`), naming objects to a convention and reusing the pilot group.
3. **Pilot** — assign to a small pilot group and observe, changing nothing else.
4. **Validate** — confirm devices evaluate correctly and Conditional Access behaves as
   intended (see `05-testing.md`).
5. **Expand** — widen assignment in waves to the full fleet.

## Object naming and reuse

Author objects once and reuse them everywhere so the deployment stays legible and auditable:

- **Pilot group:** `SG-Compliance-Pilot` (Entra security group — from Global Requirement G5).
- **Windows baseline policy:** `CP-Win-Baseline-GovHigh`.
- **Windows Firewall/AV policy (optional split):** `CP-Win-Defender-GovHigh`.
- **Noncompliance notification:** `MT-Compliance-Noncompliant-GovHigh`.
- **Conditional Access gate:** `CA-Require-Compliant-GovHigh`.

Every script and later document refers back to these exact names. Adjust the suffix if your
tenant uses a different naming standard — but pick one convention and hold to it.

## What you get

- This overview and the **Commercial vs GCC High** map above.
- A **requirements guide** with verify/implement steps per prerequisite (`02-requirements.md`).
- A **step-by-step implementation guide** using the GCC High portals, with parity caveats
  inline (`03-implementation.md`).
- **Five PowerShell scripts** that connect to **US Gov Graph** (`-Environment USGov`):
  discovery, validation, reporting, safe remediation, and scope-targeting.
- A **testing guide** with pass/fail gates (`05-testing.md`) and a **troubleshooting guide**
  with GCC-High-specific gotchas (`06-troubleshooting.md`).
- A **GCC High parity reference** with citations (`gcc-high-parity-notes.md`).

> **The repeatable way.** Nothing here is one-off. Name objects to the convention, pilot
> before you expand, gate each stage, and re-run the discovery and validation scripts any
> time you need proof the tenant still matches the design.
