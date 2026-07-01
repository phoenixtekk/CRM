# 7. Best Practices — Netskope Secure Web Gateway (SWG)

- **Pilot first, always.** The gateway is inline — a small `Web Steering – Pilot – Stage 1` scope
  catches wrong blocks and decryption-compatibility problems before they hit the fleet. This is the
  single most important practice.
- **Rehearse the rollback before you steer.** Know exactly how to remove a scope group from steering,
  disable `Web Filtering Policy – All Users – Production`, or uninstall the client — and time it.
- **Start decryption with a bypass list.** Never decrypt everything on day one. Bypass
  certificate-pinned apps and sensitive/regulated categories (health, banking) to avoid breakage and
  privacy issues.
- **Block the security categories, coach the borderline ones.** Block malware, phishing, and
  command-and-control outright; use coach (warn) for acceptable-use grey areas so users self-correct.
- **Deploy the certificate before (or with) the client.** HTTPS inspection throws certificate errors
  if `Decryption Certificate – Managed Devices – Production` is not trusted first.
- **Keep policy identity-based.** Scope `Web Filtering Policy – All Users – Production` to users/groups,
  not IP ranges, so it follows the user on and off network.
- **Order rules deliberately.** Put block rules before allow rules so a broad allow can't shadow a
  security block.
- **Watch coverage.** Run `NSSWG-Report.ps1` to confirm steered scope and per-category activity, and
  to catch devices that should be steered but are not.
- **Handle miscategorization quickly.** Maintain a process for category-correction requests and
  documented allow/block exceptions so user trust holds.
- **Communicate to users.** A short note about the block/coach pages and who to contact dramatically
  reduces tickets at rollout.
- **Document the artifacts.** Record the names and intent of the steering scope, categorization
  profile, filtering policy, and threat/content control for audits and repeatability.
