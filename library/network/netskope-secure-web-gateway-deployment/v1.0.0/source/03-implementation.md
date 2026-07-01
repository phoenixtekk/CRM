# 3. Implementation Guide — Netskope Secure Web Gateway (SWG)

Follow these steps **in order**. Microsoft-side steps give exact navigation in the Microsoft Entra
admin center (`https://entra.microsoft.com`) and the Microsoft Intune admin center
(`https://intune.microsoft.com`). Netskope-side steps name the exact control to configure but defer
the precise current console screen to Netskope's official documentation — find the named control in
your tenant.

> **Model:** Configure categorization, filtering, and threat/content policy first; steer only the
> `Web Steering – Pilot – Stage 1` scope; validate enforcement and user experience; then expand the
> steering scope to `Web Steering – Broad – Stage 2`. The gateway is inline — never steer production
> users before the pilot gate passes.
>
> **Rollback at any stage:** remove the affected scope group from steering, or disable the
> `Web Filtering Policy – All Users – Production` policy, or uninstall the client — restoring
> direct-to-internet traffic.

## Step 1 — Confirm tenant and identity
1. Sign in to the Netskope console as an administrator and confirm the SWG and SSL inspection modules
   are available (the named area is the web/SWG policy and the SSL decryption policy).
2. Confirm the tenant's identity integration resolves users (SSO / directory). The exact integration
   screen is deferred to Netskope's documentation; verify by confirming a test user is identified.
3. Run `NSSWG-Discovery.ps1` to record tenant readiness before changing anything.

## Step 2 — Create the steering-scope groups (Entra)
1. Entra → **Groups → New group** → **Group type: Security** → **Name:** `Web Steering – Pilot – Stage 1`
   → add a few representative pilot devices/users → **Create**.
2. Repeat for `Web Steering – Broad – Stage 2` (the rest of the fleet) → **Create**.
   (You can create both with `NSSWG-Set-ScopeTargeting.ps1`.)

## Step 3 — Deploy the decryption certificate (Intune)
1. Export the Netskope SSL decryption (root) certificate from your tenant (the certificate-download
   control; screen deferred to Netskope's documentation).
2. Intune → **Devices → Configuration → Create → New policy** → **Platform: Windows 10 and later** →
   **Profile type: Templates → Trusted certificate** → **Create**.
3. **Name:** `Decryption Certificate – Managed Devices – Production`. Upload the certificate;
   **Destination store: Computer certificate store – Root**. **Next**.
4. **Assignments → Add groups →** `Web Steering – Pilot – Stage 1`. **Next → Create**.

## Step 4 — Deploy the Netskope client (Intune)
1. Obtain the Netskope client package and its tenant enrollment parameters from your Netskope tenant
   (the client-download/parameters control; screen deferred to Netskope's documentation).
2. Intune → **Apps → Windows → Add** → choose the appropriate Windows app type for the package →
   upload the package and set the install/enrollment parameters.
3. **Name:** `SWG Client Deployment – Managed Devices – Production`.
4. **Assignments → Required → Add groups →** `Web Steering – Pilot – Stage 1`. **Create.**

## Step 5 — Build the URL categorization profile (Netskope)
1. In the Netskope console, create a URL categorization profile named
   `URL Categorization Profile – Standard – Production`.
2. Select the categories your `Web Filtering Policy` will reference — at minimum a block set
   (malware, phishing, command-and-control, and other security categories) and any
   acceptable-use categories (for example gambling, adult, illegal) per your policy.
3. The exact categorization screen is deferred to Netskope's documentation; the control to find is the
   URL category list / custom categories used by web policy.

## Step 6 — Configure SSL decryption with the bypass list (Netskope)
1. In the SSL decryption policy, enable decryption for steered traffic so HTTPS can be inspected.
2. Apply the **decryption bypass list** prepared in Requirement 2.7 (certificate-pinned apps and
   sensitive/regulated categories) so those flows are **not** decrypted.
3. The control to find is the SSL decryption (inspection) policy and its bypass/exception list; the
   screen is deferred to Netskope's documentation.

## Step 7 — Create the threat and content control (Netskope)
1. Create a threat/content control named `Threat & Content Control – All Users – Production` that
   blocks threat-classified destinations and risky file types for steered traffic.
2. The control to find is the threat-protection / file-type policy applied to web traffic; the screen
   is deferred to Netskope's documentation.

## Step 8 — Create the web-filtering policy (Netskope)
1. Create a web-filtering policy named `Web Filtering Policy – All Users – Production` that references
   `URL Categorization Profile – Standard – Production`.
2. Define rule actions: **block** the security/unacceptable categories, **coach** (warn) any
   borderline categories per your policy, and **allow** the rest.
3. Scope the policy to the steered users (identity-based). Order the rules so block rules precede
   allow rules. The control to find is the real-time/web protection policy; the screen is deferred to
   Netskope's documentation.

## Step 9 — Steer the pilot scope
1. In the Netskope steering configuration, add `Web Steering – Pilot – Stage 1` to the active steering
   scope so only pilot devices are steered into the gateway. The control to find is the steering
   configuration / user-group scope; the screen is deferred to Netskope's documentation.
2. On a pilot device, confirm the client shows steering active and the decryption certificate is
   trusted; run `NSSWG-Validation.ps1`.

## Step 10 — Validate the pilot (gate)
1. Run `NSSWG-Validation.ps1` on pilot devices → client running, steering active, certificate trusted.
2. Run `NSSWG-Report.ps1` → confirms pilot web activity is flowing through the gateway and policy
   coverage (which steering groups exist and are scoped).
3. Browse known-category test sites from a pilot device and confirm block/coach/allow behavior matches
   `Web Filtering Policy – All Users – Production`. Complete the Testing Guide.
4. **Pilot gate:** do not proceed until the pilot passes and no user-impacting breakage remains.

## Step 11 — Expand the steering scope
1. Add `Web Steering – Broad – Stage 2` to the active steering scope in Netskope.
2. Add `Web Steering – Broad – Stage 2` to the **Assignments** of
   `SWG Client Deployment – Managed Devices – Production` and
   `Decryption Certificate – Managed Devices – Production` in Intune so broad devices receive the
   client and certificate.
3. Re-validate with `NSSWG-Report.ps1`; remediate any mis-steered or non-compliant devices with
   `NSSWG-Remediation.ps1` (default `-WhatIf`).

---
### Order of operations
`Confirm tenant + identity → steering groups → certificate → client → categorization profile →
SSL decryption + bypass → threat/content control → web-filtering policy → steer pilot → validate
(gate) → expand`
