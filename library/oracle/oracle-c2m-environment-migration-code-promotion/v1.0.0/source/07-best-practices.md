# 7. Best Practices — Oracle C2M Environment Migration & Code Promotion (Dev → QA → Prod)

- One named Migration Request per scope, reused every release. Build the request once and reuse it; ad-hoc
  "export everything" bundles are neither repeatable nor auditable, and they promote things you did not
  intend to change.
- Check every bundle into version control. The binary export file is just a file — retain it so the exact
  reviewed artifact that passed QA is the one applied to Production, and so every release is auditable.
- Promote configuration and code in lockstep. A CMA bundle without its matching code build (or vice versa)
  is a half-promotion; record the bundle version, build/patch version, and IWS list together as one
  release and move them together.
- Author a Migration Plan for every custom object *before* building the request. An object type with no
  plan is silently excluded from the bundle — the number-one cause of "it worked in QA but is missing in
  Prod."
- Always review before you apply. CMA fully replaces matching target objects and never deletes target-only
  ones; the import review is your last chance to catch an unintended replacement — never click through it.
- Back up the target before every import. Because import replaces objects, the pre-import backup (plus the
  recorded prior bundle level) is your rollback; take it every time, not just for Production.
- Deploy IWS from the command line for QA and Prod. The online deployment portal is supported only in
  non-production; use `iwsdeploy` under `splenviron` for controlled environments and confirm the
  Deployment Status zone reads current.
- Compare, don't assume. Run the environment-compare step on every promotion; "the import said OK" is not
  the same as "source and target are at parity." Parity confirmed is the evidence of a clean promotion.
- Promote one direction, through the gates. Dev → QA → Prod, never sideways or backward; pass the explicit
  gate (parity + functional test) at each hop before the next.
- Prove it on a pilot scope first. Run one bounded Migration Request Dev → QA before promoting a full
  release or touching Production — the pilot gate catches plan, transfer, and IWS gaps cheaply.
- Keep source and target at compatible levels. Same-release promotion is the safe default; treat a
  framework-version gap as its own planned exercise, not an incidental part of a release.
- Never author configuration directly in QA or Prod. All change originates in Dev and is promoted; a
  hand-edit in a downstream environment is exactly the drift this method exists to prevent.
