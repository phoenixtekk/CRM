# 1. Solution Overview — Deploy a Third-Party PFX Certificate to Mobile Devices for App Use

## What this solves
A third-party PFX certificate — one that behaves like a software/license credential an app consumes,
not a standard TLS/SSL web certificate — needs to reach iOS/iPadOS devices through Microsoft Intune
so a specific app can use it. The certificate already exists as a file (a `.pfx`/`.p12` with a
private key, protected by a password) and was issued by an external party, not by your internal
certification authority (CA).

The common trap: teams reach for a SCEP or PKCS (CA-issued) profile, assign it, and nothing arrives —
even when the PFX object is already visible in Intune/Graph. The deployment stalls because a static,
externally-issued PFX uses a *different delivery path* from a CA-issued certificate. This solution
explains why, then gives you the correct, repeatable way to import the PFX and deliver it to devices
so the app can consume it.

## Why a static third-party PFX is NOT a SCEP/PKCS (CA-issued) scenario
This is the single most important point in the package, so it leads the overview.

- A SCEP profile and a PKCS certificate profile both *issue a brand-new certificate* from an internal
  CA at deployment time. The device (SCEP) or the Intune Certificate Connector (PKCS) talks to your
  CA, the CA mints a fresh certificate against a template, and that new certificate lands on the
  device. There is no way to "feed" a pre-existing third-party `.pfx` into either of those flows —
  they only know how to request *new* certificates from *your* CA.
- A third-party PFX is the opposite: it is a *static, already-issued* credential with its private key
  baked in. There is no CA request to make and no template to issue against. You are *delivering an
  existing file*, not *issuing a new certificate*.
- This is why the usual symptoms appear: nothing shows up "on the CA," the SCEP/PKCS template never
  fires, and the request the team is looking for never exists — because no certificate is being
  requested. The PFX object can sit in Intune/Graph indefinitely and still never reach a device,
  because importing the object and *assigning a delivery profile* are two separate actions.

The fix is to stop using the CA-issued (SCEP/PKCS *template*) path and use one of the two correct
delivery paths below.

## The two correct paths — decision guide
There are two supported enterprise ways to put a static third-party PFX onto an iOS device.

### Path A — PKCS imported certificate (import to Intune via Graph, then assign an imported-PFX profile)
1. An admin imports the `.pfx` into Intune. The import encrypts the PFX to the Intune Certificate
   Connector's public key and uploads it via Microsoft Graph (the imported/user PFX certificate flow —
   the same pattern as the PFXImport helper / Add-IntuneUserPfxCertificate).
2. You assign a `Devices > Configuration > Templates > PKCS imported certificate` profile to the user
   (or group). At delivery time the Intune Certificate Connector *decrypts* the imported PFX and the
   identity is installed on the device.
- The Intune Certificate Connector is **required** for this path — it is what decrypts the imported
  PFX. No healthy connector, no delivery.
- Caveat to flag up front: the imported-PFX profile's "intended purpose" options are **S/MIME-oriented**
  (signing / encryption). That matters for a *non-S/MIME* app certificate — if your app does not
  consume an S/MIME identity, the intended-purpose framing may not match the app's expectation, which
  is one reason Path B is often cleaner for a plain app identity.

### Path B — Custom iOS/iPadOS configuration profile carrying a PKCS12 (.p12/.pfx) payload
1. You build a `.mobileconfig` containing a PKCS12 payload (the `.p12`/`.pfx` plus its password).
2. You deliver it via `Devices > Configuration > Create > iOS/iPadOS > Templates > Custom`, uploading
   the `.mobileconfig`.
- Best when you control the certificate and its password and simply need a specific identity present
  on the device for an app. For an iOS app scenario this is frequently the most direct path — no
  Certificate Connector and no Graph import required.

### Choosing between A and B
| Use Path A (PKCS imported certificate) when… | Use Path B (Custom PKCS12 profile) when… |
|---|---|
| You want Intune to manage the imported PFX object centrally and the Certificate Connector is already healthy | You control the `.pfx` + password and want the most direct delivery for an app identity |
| The identity is genuinely S/MIME (signing/encryption) | The identity is a plain app credential (not S/MIME) |
| You need per-user PFX objects tracked in Intune/Graph | You are fine packaging the identity in a `.mobileconfig` you produce |

In both paths you also deploy a **Trusted certificate** profile to install the root/intermediate
**chain**. A leaf certificate is useless on the device if the issuing chain is not trusted — so the
chain is not optional.

## App-use and the iOS keychain — the nuance that decides success
Delivering the certificate is necessary but not always sufficient for the app to *use* it.

- On iOS, a profile-delivered identity lands in the **system keychain**.
- Whether the **target app** can read that identity depends on the app's **keychain access group /
  entitlements**, or on an Intune **App Configuration policy** that points the app at the identity.
- If the app expects the identity in *its own* keychain access group, a plain config-profile PKCS12
  may not be directly accessible to it — the app vendor's required delivery method governs.
- **Therefore:** make the Intune *delivery* correct (this is what this solution guarantees) and apply
  the decision criteria above; **defer app-internal specifics** (which keychain group the app reads,
  whether it needs an App Configuration key) to the app vendor's documentation.

## Mapping the real symptom
> "The PFX object exists in Graph but won't deploy."
The missing piece is almost always a **PKCS imported certificate profile assigned to the user** (Path
A) — or switching to the **custom-profile** path (Path B) — *plus a healthy Certificate Connector*.
It is **not** a SCEP/PKCS *template* problem, and it is **not** a CA permissions/mapping problem.
Importing the object and assigning a delivery profile are two separate steps; the object alone never
reaches a device.

## Benefits
- **Right path the first time** — stop burning cycles on SCEP/PKCS templates that cannot deliver a
  static PFX.
- **Two proven options** — imported-PFX vs custom PKCS12, with a clear decision guide for the app case.
- **App-ready** — the keychain-access guidance tells you what determines whether the app can use the
  identity, so you do not "deliver" a certificate the app can never read.
- **Validated** — per-device presence checks and a fleet report so you know the certificate actually
  landed.

## Limitations (be honest with buyers)
- Path A **requires** the Intune Certificate Connector; if you cannot run a connector, use Path B.
- Whether the app can *consume* the identity is ultimately governed by the **app vendor** (keychain
  access group / App Configuration). This solution makes Intune delivery correct; it does not modify
  third-party apps.
- The imported-PFX profile's intended-purpose options are S/MIME-oriented — note this for a non-S/MIME
  app certificate.
- This is an **iOS/iPadOS** app-certificate scenario; other platforms use different payloads.

## The standard deployment model
> **Confirm/import the PFX → stand up a healthy Certificate Connector (Path A) → deliver the trusted
> chain → assign the imported-PFX profile (or the custom PKCS12 profile) → validate the app can use it
> → pilot → expand.** Pattern: **Assess → Configure → Pilot → Validate → Expand.**
