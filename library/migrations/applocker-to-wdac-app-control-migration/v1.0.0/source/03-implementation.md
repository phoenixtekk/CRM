# 3. Implementation Guide — AppLocker to WDAC (App Control for Business) Migration

Follow these steps in order, in the Microsoft Intune admin center (`https://intune.microsoft.com`).
Use the artifact names from the Requirements Guide verbatim.

> Model: translate AppLocker rules, author the WDAC policy, deploy audit-first via Intune, close
> gaps, enforce by ring, retire AppLocker. AppLocker stays in force throughout audit and early
> enforcement (coexistence) and is removed last. No enforcement until the audit log is clean — no
> lockouts.

## Step 1 — Assess: export and inventory the current AppLocker policy
1. On a representative device in each ring, run `WDACMIG-Discovery.ps1` (captures the effective
   AppLocker policy, its rule collections, current WDAC/code-integrity state, and managed-installer
   status). It writes the effective AppLocker XML for review.
2. Inventory what AppLocker allows: signers/publishers, file paths, and hash rules. Flag path-based
   rules for unsigned line-of-business apps — these are the apps that must be re-trusted under WDAC by
   managed installer, ISG, or explicit signer/hash rules.

## Step 2 — Create the migration ring groups
1. Entra to Groups to New group to Security. Create `App Control Migration – Pilot – Ring 1` and add a
   few pilot devices. Create `App Control Migration – Broad – Ring 2` and `App Control Migration –
   Fleet – Ring 3` for later waves.
2. Optionally populate the pilot ring with `WDACMIG-Set-MigrationRingTargeting.ps1`.

## Step 3 — Configure: author the WDAC base policy
1. Intune to Endpoint security to App Control for Business to Create Policy.
   *(If not present in your tenant, use Devices to Configuration to Create to Settings catalog and
   search "App Control" / "Application Control".)*
2. Platform: Windows. Profile: App Control for Business. Create.
3. Name: `App Control – Fleet – Audit`. Next.

## Step 4 — Configure trust (translated from AppLocker) and set Audit mode
On Configuration settings:
1. Application control code integrity policies = Enable.
2. Trust mode / built-in policy = Trust Windows components and Store apps.
3. Trust apps from managed installers = Enable (so Intune-deployed apps — the re-trust path for
   AppLocker's path-allowed apps — are allowed).
4. Also trust apps with good reputation (ISG) = Enable (recommended for good-reputation apps not
   deployed via Intune).
5. For apps AppLocker allowed that are neither Intune-deployed nor ISG-trusted, plan a
   supplemental/custom policy carrying the translated signer/hash rules (author with the WDAC Wizard
   or `New-CIPolicy`); reference it as `App Control – Migrated from AppLocker – Base`.
6. Enforcement = Audit only.
Click Next.

## Step 5 — Pilot: assign the audit policy and run the audit
1. Assignments to Add groups to `App Control Migration – Pilot – Ring 1`. Next to Create.
2. Keep AppLocker in force on these devices (coexistence) — do not remove it yet.
3. Let pilot devices run normally for 2+ weeks, exercising all line-of-business apps. Audit mode
   blocks nothing; it only logs would-block events (Code Integrity 3076).

## Step 6 — Validate the audit: analyze events and close gaps
1. On pilot devices run `WDACMIG-Validation.ps1` (confirms the audit policy is applied and the device
   is logging) and `WDACMIG-Report.ps1` (summarizes would-block events and migration coverage —
   which AppLocker-allowed apps WDAC would block).
2. For each legitimate app that would be blocked:
   - Preferred: deploy it via Intune so the managed installer trust covers it.
   - For signed apps not from Intune, rely on ISG, or add the translated signer/hash rule to the
     supplemental policy `App Control – Migrated from AppLocker – Base`.
3. Re-audit until `WDACMIG-Report.ps1` shows the audit log is clean of legitimate blocks. This is the
   audit gate — do not enforce before it passes.

## Step 7 — Pilot enforce: promote the pilot ring to Enforced
1. Duplicate the policy as `App Control – Fleet – Enforce` (or edit) and set Enforcement = Enforced.
   Save. Keep it assigned to `App Control Migration – Pilot – Ring 1`.
2. Re-validate with `WDACMIG-Validation.ps1` (confirms an enforced policy is active).
3. Confirm pilot users can run all required apps; untrusted code is blocked. AppLocker still coexists.

## Step 8 — Retire AppLocker on the pilot ring
1. Only after Step 7 validates, remove the AppLocker policy from the pilot devices (clear the
   AppLocker rule collections / disable the Application Identity policy via your AppLocker management
   method).
2. Re-run `WDACMIG-Validation.ps1` to confirm WDAC enforcement remains active with AppLocker gone.

## Step 9 — Expand: enforce and retire by ring
1. Repeat Steps 5 to 8 per ring: assign `App Control – Fleet – Audit` to the next ring, run the audit,
   close gaps, promote to `App Control – Fleet – Enforce`, validate, then retire AppLocker on that
   ring. Roll out `App Control Migration – Broad – Ring 2` then `App Control Migration – Fleet –
   Ring 3` in waves.
2. Keep new apps flowing through Intune (managed installer) so they stay trusted.
3. Re-validate each ring with `WDACMIG-Validation.ps1` and `WDACMIG-Report.ps1`.

> Recovery / rollback: if an enforced policy is too strict, unassign `App Control – Fleet – Enforce`
> in Intune, re-assign `App Control – Fleet – Audit`, and run `WDACMIG-Remediation.ps1` (default
> -WhatIf) to revert the device to audit mode. If AppLocker was already retired on that ring,
> re-deploy it temporarily for coverage while you fix WDAC trust, then re-enforce.

---
### Order of operations
`Export AppLocker (assess) → Ring groups → Author WDAC (Audit) → Assign pilot + coexist → Review
audit + close gaps (audit gate) → Enforce pilot → Retire AppLocker (pilot) → Expand ring by ring`
