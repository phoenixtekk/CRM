# Executive Summary — Cloud PKI Integration with Intune (Government / GCC High)

## The problem

Certificate management in **GCC High is not the Commercial product with a different sign-in.** The
admin portals are separate US sovereign-cloud endpoints (`intune.microsoft.us`,
`login.microsoftonline.us`), and — decisively for this topic — **Microsoft Cloud PKI, the marquee
Commercial capability for modernizing certificate management, is *not available* in GCC High** and
**is not planned for DoD**. A government tenant configured from a Commercial "enable Cloud PKI"
runbook silently fails: the capability simply is not present.

## What this solution does

It deploys a **managed certificate program on GCC High correctly**, using the **supported**
government path: a **trusted-root trust chain** plus **SCEP and PKCS certificate profiles** delivered
by the **Intune Certificate Connector**, anchored to your own **AD CS** certification authority — the
right portals, the right endpoints, and the Cloud-PKI parity gap called out **up front and at every
step where it matters**. It follows a repeatable **Assess → Configure → Pilot → Validate → Expand**
model with pass/fail gates, so certificates are issued, trusted, consumed (Wi-Fi/VPN), renewed, and
revoked correctly — proven on a named pilot before it scales.

## The GCC High differences that matter (doc-confirmed)

Drawn from Microsoft's *Intune Government Service overview* and the *Certificate Connector* /
*Cloud PKI* docs:

- **Microsoft Cloud PKI is listed under "Intune features planned for GCC High and DoD"** — i.e.
  **currently not available and not supported** — annotated **"(GCC High only)"**, meaning the plan
  covers GCC High but **not DoD**. **Do not design on Cloud PKI in GCC High today.**
- **SCEP, PKCS, imported PKCS (PFX), and trusted certificate profiles are available** in GCC High as
  standard MDM device-configuration features.
- **The Certificate Connector for Microsoft Intune is available** (installed from
  `intune.microsoft.us`); **NDES is required** for SCEP against a Microsoft (AD CS) CA. **Partner-CA
  connectors work only where the vendor supports GCC High** — verify.
- **Scripts must target US Gov Graph** (`Connect-MgGraph -Environment USGov`, `graph.microsoft.us`).

Where a GCC High specific could not be confirmed (partner-CA support, derived-credential issuers),
the solution states the position and **explicitly flags "verify for GCC High"** rather than inventing
menus or parity claims.

## Business outcome

A fragile or manual certificate estate — hand-issued certificates, no renewal story, no mobile
visibility — becomes a **managed** one on a US sovereign cloud: certificates **issued, trusted,
renewed, and revoked** through Intune on the **supported** path, validated on a pilot, and safe to
expand — with a **clean forward road to Cloud PKI** the moment Microsoft ships it to GCC High.
Self-guided and tested, at a fraction of consulting cost.

**Deployment model:** Assess → Configure → Pilot → Validate → Expand.
