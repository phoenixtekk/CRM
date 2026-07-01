# Executive Summary — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use (Microsoft Intune)

**Workplace Marketplace · Intune Solutions**

A third-party PFX certificate — one that acts like a software/license credential an app consumes, not
a standard TLS/SSL web certificate — needs to land on iOS/iPadOS devices through Microsoft Intune so a
specific app can use it. The usual trap is reaching for a SCEP or PKCS (CA-issued) template: the
request never appears the way the team expects and the deployment stalls, even though the PFX object
already exists in Intune/Graph. The reason is simple once you see it — a static, externally-issued PFX
is a **different delivery path** from a CA-issued certificate.

This is a complete, **deploy-it-today** package that corrects the path and delivers the certificate
the right way, written for an administrator with no prior certificate-deployment experience.

## What you get
- A plain-language **Solution Overview** explaining why a static third-party PFX is **not** a
  SCEP/PKCS scenario, with a clear **Path A vs Path B** decision guide and the iOS **keychain-access**
  nuance that decides whether the app can actually use the certificate.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (including the
  Intune Certificate Connector and the trusted chain).
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order — import
  via Graph, the trusted-root chain, the **PKCS imported certificate** profile, the **custom PKCS12**
  alternative, and app validation.
- Five **PowerShell scripts** for discovery, per-device validation, fleet reporting, safe remediation,
  and a Graph PFX-import helper.
- **Testing** and **Troubleshooting** guides, including the "PFX exists in Graph but won't deploy"
  diagnostic tree.

## What this delivers
The third-party PFX **imported into Intune** (Path A, via the Certificate Connector + Graph) or
packaged in a **custom PKCS12 configuration profile** (Path B), delivered to iOS devices alongside the
**trusted root/intermediate chain**, with the decision criteria and keychain guidance that make the
certificate **usable by the target app** — not just present on the device.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
A third-party PFX correctly delivered to iOS devices through the right profile type, with the app able
to consume it — instead of stalling on the wrong SCEP/PKCS template — proven on a pilot before you
scale.
