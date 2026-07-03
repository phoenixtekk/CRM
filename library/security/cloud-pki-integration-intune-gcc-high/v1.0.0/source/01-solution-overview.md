# Solution Overview — Cloud PKI Integration with Intune (Government / GCC High)

## Read this first — Cloud PKI availability in GCC High

**Microsoft Cloud PKI is *not yet available* in GCC High, and is *not planned* for DoD.** In
Microsoft's *Intune Government Service overview*, Cloud PKI is listed under **"Intune features
planned for GCC High and DoD"** — the table of features that are **currently not available and not
supported** but where planning has started — annotated **"(GCC High only)."** That annotation means
the *plan* to deliver Cloud PKI covers **GCC High**, not **DoD**.

So on a US sovereign-cloud tenant today:

- **You cannot deploy Microsoft Cloud PKI in GCC High yet** (it is planned; Microsoft public-sector
  messaging points at a Government-cloud arrival during 2026 — **treat as an ETA, verify before you
  plan a go-live**).
- **DoD is not on the Cloud PKI roadmap at all.**
- **The supported way to issue certificates to Intune-managed devices in GCC High is SCEP and/or
  PKCS certificate profiles delivered by the Intune Certificate Connector**, anchored to your own
  **AD CS** (or a partner CA that supports the government cloud). This edition builds the certificate
  program on that **supported** foundation, and treats Cloud PKI as a **future migration** you slot
  in once Microsoft ships it to GCC High.

This is the difference that makes this a **different solution, not a re-login**: a Commercial "stand
up Cloud PKI in the Intune admin center" runbook **does not apply in GCC High** — the capability is
simply not there.

> **Source:** Microsoft Learn — *Microsoft Intune Government Service overview*, "Intune features
> planned for GCC High and DoD," row **Cloud PKI (GCC High only)**
> (`https://learn.microsoft.com/en-us/intune/fundamentals/government-service`, doc dated 2026-06-04).
> Full citations in `gcc-high-parity-notes.md`.

## What this solution delivers

This is the **Government (GCC High)** edition of the certificate-management modernization solution.
It walks a competent-but-novice administrator through issuing and managing device/user certificates
on a **US sovereign-cloud (GCC High)** tenant, the repeatable way:

1. **A trusted-root/intermediate trust chain** published to Intune-managed devices via **trusted
   certificate profiles**.
2. **SCEP certificate profiles** (dynamic, per-device enrollment via NDES + the Intune Certificate
   Connector) and/or **PKCS certificate profiles** (connector-issued from AD CS) for Wi-Fi, VPN,
   Wi-Fi/802.1X, S/MIME, and device-identity scenarios.
3. **Certificate lifecycle hygiene** — issuance, renewal, and revocation — validated on a pilot,
   with drift-detection scripts, **before** you scale.

Together these turn a **fragile or manual certificate estate** (hand-issued certs, no renewal story,
GPO-only distribution, no visibility on mobile) into a **managed** one: certificates **issued,
trusted, renewed, and revoked** through Intune — proven on a pilot before you scale — on the
**supported** government path, with a clean forward road to Cloud PKI when it arrives.

## Why GCC High is a different solution, not a re-login

Certificate management in **GCC High is not the Commercial portal with a different sign-in.** Two
things differ in ways that break Commercial runbooks:

- **The portals and endpoints are different sovereign-cloud hosts.** You administer Intune at
  **`intune.microsoft.us`**, sign in at **`login.microsoftonline.us`**, and your scripts must target
  **US Gov Graph endpoints** (`Connect-MgGraph -Environment USGov`, `graph.microsoft.us`). Point a
  Commercial runbook at `intune.microsoft.com` and you are in the wrong cloud. (Intune GCC High/DoD
  runs on **Azure Government**, a physically separate **IL4/IL5** datacenter.)
- **Feature parity lags Commercial — and for this topic the gap is decisive.** The marquee Commercial
  capability for this solution, **Microsoft Cloud PKI, is not available in GCC High** (planned) and
  **not planned for DoD**. Following a Commercial "enable Cloud PKI" runbook silently fails: the
  option is not there. The **supported** government approach — SCEP/PKCS via the Intune Certificate
  Connector — is a different design with different prerequisites (an on-prem CA, NDES, a connector).

This edition calls out the correct GCC High portals/endpoints at each step, and flags the parity gap
**where it matters**, so a government tenant is configured correctly. The full parity reference lives
in `gcc-high-parity-notes.md` and is cited throughout.

## The certificate model (how the pieces fit)

- A **trusted certificate profile** deploys your **root** (and any **intermediate**) CA public
  certificate to devices so they *trust* certificates issued from that chain.
- A **SCEP certificate profile** tells the device to generate a key pair on-device (**the private
  key never leaves the device**) and request a leaf certificate. With an **AD CS** CA, the request is
  serviced by **NDES**, validated by the **Intune Certificate Connector**, and signed by your CA.
- A **PKCS certificate profile** has the **Intune Certificate Connector** request the certificate
  from **AD CS** on the device's behalf and deliver it. **Imported PKCS (PFX)** covers per-user
  S/MIME.
- **Renewal and revocation** are driven from Intune (renewal thresholds on the profile; revocation
  on unenroll/wipe or manually), with the connector performing revocation against the CA.

The design principle is **assign once, repeat everywhere**: one well-named trust profile plus a
small set of named SCEP/PKCS profiles, assigned to a pilot group and then expanded — instead of
one-off, hand-issued certificates.

> **Where Cloud PKI fits later:** Cloud PKI replaces the on-prem CA + NDES + connector with a
> cloud-hosted root/issuing CA and a built-in SCEP registration authority. When it reaches GCC High,
> the **trusted-root and SCEP profiles** you build here map onto a Cloud PKI *issuing CA* with
> minimal rework — which is why building the profile layer correctly now pays off. (`gcc-high-parity-notes.md` §2.)

## Commercial vs GCC High — what's different

*(Doc-confirmed from Microsoft's *Intune Government Service overview* and *Microsoft Cloud PKI* /
*Certificate Connector* docs unless flagged. See `gcc-high-parity-notes.md` for the full table and
citations.)*

**Portals & endpoints (always different):**

| Purpose | Commercial | GCC High |
| --- | --- | --- |
| Sign-in | `login.microsoftonline.com` | `login.microsoftonline.us` |
| Microsoft 365 admin | `admin.microsoft.com` | `portal.office365.us` |
| Intune admin center | `intune.microsoft.com` / `endpoint.microsoft.com` | `intune.microsoft.us` |
| Security portal | `security.microsoft.com` | `security.microsoft.us` |
| Entra admin | `entra.microsoft.com` | `entra.microsoft.us` |
| Azure portal | `portal.azure.com` | `portal.azure.us` |
| Graph (scripts) | `graph.microsoft.com` (`-Environment Global`) | `graph.microsoft.us` (`-Environment USGov`) |

**The parity gap that changes the whole design (GCC High status in parentheses):**

- **Microsoft Cloud PKI** is **not available** in GCC High (*planned, GCC High only*) and **not
  planned for DoD**. **Do not design on it.** Use **SCEP/PKCS + the Intune Certificate Connector**
  (below), which **is** supported.
- **SCEP certificate profiles, PKCS certificate profiles, imported PKCS (PFX), and trusted
  certificate profiles** are **available** in GCC High as **standard MDM / device-configuration**
  features.
- **The Certificate Connector for Microsoft Intune** is **available**; install it from
  `intune.microsoft.us`. Its network requirements are the **same as a managed device** — in GCC High
  that means the **US Gov** endpoints, plus `autoupdate.msappproxy.net:443` for auto-update.
- **NDES** is **required** to issue SCEP from an **AD CS (Microsoft) CA**. (Third-party SCEP CAs do
  not require the connector.)
- **Partner-CA connectors (e.g. DigiCert)** work **only where the partner supports the GCC High
  government cloud** — **verify for GCC High** before designing on one (mirrors how MTD connectors are
  limited to vendors that support GCC High).
- **Remote Help** is also **planned/not-yet-available**; **classic Windows Autopilot** is **not
  available** in GCC High — noted because certificate rollouts often ride enrollment flows.

Where a specific menu, connector, or Cloud PKI option is not visible in `intune.microsoft.us`, treat
it as a **GCC High parity gap, not a permissions problem** — re-check the parity table before
troubleshooting.

## The standard deployment model

Every step in this solution follows the same repeatable model, with an explicit **pass/fail gate**
between phases:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm licensing (Gov G3/G5), roles, portal access, an available CA + NDES +
  connector, and (critically) **that Cloud PKI is not being assumed** (the parity check).
- **Configure** — build the trusted-root profile and the SCEP/PKCS profiles. Name every object
  verbatim.
- **Pilot** — assign to a **named pilot group** only.
- **Validate** — run the pass/fail gates in `05-testing.md` against the pilot (certs issued, trusted,
  Wi-Fi/VPN authenticate, renewal/revocation behave).
- **Expand** — widen scope group-by-group only after the gate passes.

## What's in the box

- This overview, a **Requirements** guide, an ordered **Implementation** guide, **Testing** (pass/fail
  gates), **Troubleshooting** (with GCC-High-specific gotchas), **Best Practices**, and a
  **Deliverables Summary** + **Executive Summary**.
- A **GCC High parity notes** reference (`gcc-high-parity-notes.md`) with per-feature status and
  Microsoft citations — including the Cloud-PKI-not-available finding.
- **Five PowerShell scripts** (Graph SDK, US Gov endpoints): Discovery, Validation, Report,
  Remediation, and Set-ScopeTargeting — read-only tools default to read-only; change tools default
  to `-WhatIf`.

> **Sources:** Microsoft Learn — *Microsoft Intune Government Service overview*
> (`.../fundamentals/government-service`); *Microsoft Cloud PKI for Microsoft Intune*
> (`.../cloud-pki/`); *Overview of Certificate Connector for Microsoft Intune*
> (`.../protect/certificate-connector-overview`); MSPortals.io US Government portals. Full citations
> in `gcc-high-parity-notes.md`.
