# Best Practices

Durable practices for keeping a Microsoft 365 domain authenticated, aligned, and safely enforced.

## Sequence and evidence

- **Never enforce before you monitor.** Always publish DMARC at `p=none` first and let aggregate
  reports run for 2–4 weeks. Enforcement decisions must be driven by report data, not assumptions.
- **Ramp, don't leap.** Move `p=none → p=quarantine → p=reject`, and use `pct=` (25 → 50 → 100) within
  the quarantine/reject step so a missed sender is caught on a fraction of mail, not all of it.
- **Treat "unknown source in reports" as a hard gate.** An unidentified source that turns out to be
  legitimate will break at enforcement — resolve every unknown before tightening policy.

## SPF hygiene

- **One SPF record per domain.** Multiple `v=spf1` TXT records is a `permerror`; merge into one.
- **Stay under 10 DNS lookups.** Audit `include:`/`a`/`mx`/`ptr`/`exists` regularly, especially after
  adding a vendor. Consolidate by using vendors' published `ip4:` ranges or a sending subdomain instead
  of stacking nested `include:` chains.
- **End with `-all` once proven.** Use `~all` during pilot, tighten to `-all` after the inventory is
  complete. `+all` is never correct.
- **Don't rely on SPF alone for DMARC** — forwarding breaks SPF alignment. Ensure DKIM alignment is
  present so DMARC survives forwarding.

## DKIM hygiene

- **Enable custom-domain DKIM on every accepted domain** you send from — the default
  `onmicrosoft.com` signature does **not** align to your custom `From:` domain.
- **Publish both selector CNAMEs** and keep them in place; Exchange Online rotates between selector1 and
  selector2. Rotate keys periodically with `Rotate-DkimSigningConfig`, and immediately if a key is
  suspected compromised.
- **Extend DKIM alignment to third-party senders** — have each platform sign with `d=<yourdomain>`
  (publish the vendor's CNAMEs) rather than relying only on adding them to SPF.

## DMARC hygiene

- **Keep `rua=` on permanently**, even after reaching `p=reject` — reports are your early-warning
  system for new shadow senders, vendor changes, and spoof campaigns.
- **Set a subdomain policy (`sp=`)** deliberately; unused subdomains are a common spoofing target — an
  organizational `p=reject` with `sp=reject` closes them.
- **Use relaxed alignment (`adkim=r`, `aspf=r`) by default**; only move to strict (`s`) if you have a
  specific reason and have confirmed all senders align strictly.
- **Consider `_dmarc` on a parent org domain** to cover subdomains, plus a policy record for the org
  domain itself.

## Operations

- **Lower DNS TTLs** (e.g. 300–3600s) before a rollout so staged changes and rollbacks propagate fast.
- **Change one record at a time under change control**, keeping the prior value for instant rollback.
- **Schedule the report analysis** so drift (a new un-aligned sender) is caught within a cycle, not at
  the next incident.
- **Layer DMARC with anti-phishing.** DMARC stops exact-domain spoofing only; pair it with Defender for
  Office 365 anti-phish / spoof intelligence for display-name and look-alike-domain protection
  (plan-dependent — verify your EOP vs Defender for Office 365 plan).
- **Document the final records** (SPF string, DKIM selectors, DMARC policy, RUA destination) and the
  sender inventory as living operational documentation.

## Government / sovereign cloud

- In **GCC High / DoD**, verify the exact SPF include host, DKIM CNAME targets (`*.onmicrosoft.us`), and
  portal URLs (`*.office365.us`) for your cloud — don't assume Commercial values. Connect with the
  matching `-ExchangeEnvironmentName`.
