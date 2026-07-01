# 1. Solution Overview — AppLocker to WDAC (App Control for Business) Migration

## What this migration is
This is the controlled replacement of `AppLocker` with `WDAC` (Windows Defender Application Control,
now branded App Control for Business) as your Windows application-control mechanism, delivered and
assigned through Microsoft Intune. You are not standing up app control for the first time — you
already run AppLocker — so the work is a migration: translate what AppLocker currently allows into a
WDAC policy, prove that policy in audit mode, enforce it in rings, and only then retire AppLocker.

## Why WDAC over AppLocker (the why — covered only here)
- OS-level enforcement. WDAC is enforced by the kernel code-integrity engine, earlier and deeper than
  AppLocker's user-mode service, so it is far harder to bypass.
- Modern trust model. WDAC trusts code by signer, hash, file attributes, a managed installer, or the
  Intelligent Security Graph (ISG) reputation service — richer and more durable than AppLocker's
  publisher/path/hash rules, which break on every app update.
- Strategic direction. Microsoft positions App Control for Business as the forward path for Windows
  application control; AppLocker is maintained but no longer the recommended primary control.
- Single managed surface. Both the WDAC policy and the migration rings are authored and assigned from
  Intune, giving one console, one audit trail, and one assignment model.

## The migration model
1. Translate. Export the existing AppLocker policy and inventory what it allows, then author an
   equivalent WDAC base policy (trust Windows + Store, plus managed installer and optionally ISG, plus
   any explicit signer/hash rules carried over from AppLocker).
2. Audit. Deploy the WDAC policy in audit mode via Intune. Audit mode blocks nothing — it only logs
   what would have been blocked (Code Integrity event 3076), so no user is ever locked out during
   this phase.
3. Analyze and close gaps. Read the audit events, identify legitimate apps that would have been
   blocked, and add trust for them (preferably by deploying them through Intune so the managed
   installer covers them). Re-audit until the log is clean of legitimate blocks.
4. Enforce by ring. Promote the policy to enforced for the pilot ring first, validate, then expand to
   broad rings in waves.
5. Retire AppLocker. Once WDAC enforcement is proven across the fleet, remove the AppLocker policy.

## AppLocker / WDAC coexistence
AppLocker and WDAC can run on the same device at the same time — they are independent engines and
both evaluate execution. During this migration they coexist deliberately: AppLocker stays in force
while the WDAC policy runs in audit mode and through early enforcement rings, so application control
is never absent mid-cutover. AppLocker is removed only as the final step, per ring, after WDAC
enforcement is validated. Where both enforce, the most restrictive outcome wins, so the audit phase
is essential to confirm WDAC trusts everything AppLocker allowed before AppLocker is withdrawn.

## Trust mechanisms you will use
- Managed installer. Apps deployed through Intune are tagged as installed by a trusted managed
  installer, so their files are automatically trusted by WDAC — the primary way to keep business apps
  allowed without per-app rules.
- ISG (Intelligent Security Graph). Optional reputation-based trust for well-known, good-reputation
  apps not deployed through Intune.
- Carried-over rules. Explicit signer or hash rules translated from AppLocker for apps that are
  neither Intune-deployed nor ISG-trusted.

## Limitations (be honest with buyers)
- WDAC is stricter than AppLocker by design; unsigned or low-reputation line-of-business apps that
  AppLocker allowed by path must be re-trusted by signer, hash, managed installer, or ISG — this is
  exactly what the audit phase surfaces.
- Some kernel-level WDAC features (for example HVCI) interact with hardware/driver compatibility;
  this migration uses application (user-mode) control and does not require enabling HVCI.
- A misconfigured enforced policy can block boot or critical apps — which is why this solution never
  enforces before the audit log is clean and always keeps a rollback path.

## The standard deployment model
> Translate AppLocker rules, author the WDAC policy, deploy in audit mode, close gaps, enforce by
> ring, retire AppLocker. The pattern: Assess to Configure to Pilot to Validate to Expand.
