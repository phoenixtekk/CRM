# 7. Best Practices — Double Key Encryption (DKE) Implementation, Microsoft Purview

- **Reserve DKE for the crown jewels.** DKE deliberately removes cloud content services (content DLP,
  eDiscovery content search, Copilot, co-authoring). Apply it to a **small, named** set of the most
  sensitive data — never as a broad default — so you do not break routine workflows.
- **Treat the key service as production infrastructure.** The customer key's availability gates access
  to all DKE content. Run it with monitoring, redundancy, patching, and a tested disaster-recovery
  plan; alert on the endpoint before users notice they cannot open files. Probe it with
  `IPDKE-Scope-And-ServiceHealth.ps1`.
- **Protect the customer key like the secret it is.** Back it up securely, restrict who can touch the
  host, and **never** commit the private key or `appsettings.json` secrets to source control or share
  them. Losing the key means losing access to the content it protects.
- **Choose the hosting region deliberately.** If DKE is driven by a sovereignty requirement, host the
  key service in the region compliance/legal require, and record the decision — the region is part of
  the control.
- **Validate the endpoint before you wire the label.** Confirm `https://dke.contoso.com/DKE-Key-01`
  returns the public key over trusted HTTPS (Implementation Step 5) before entering it on the label; a
  bad endpoint URL is the most common DKE failure.
- **Pilot on a named group first.** Publish `Label Policy - DKE Ultra Confidential - DKE Pilot` to
  `Purview - DKE Pilot Users` and prove the mechanics — both keys required, permissions enforced —
  before widening.
- **Keep the audience and the readers explicit.** Publish the label only to a named audience, and keep
  `SG - DKE Ultra Confidential Readers` (and the service's authorized-users setting) tight and in sync;
  DKE permissions and key-access authorization are two separate controls — align them.
- **Name every object by purpose and stage.** Use the `<Purpose> - <Scope> - <Stage>` convention (for
  example `... - DKE Pilot`) so the portal shows exactly where the label and policy are in their
  lifecycle.
- **Keep the key service running through any rollback.** Unpublishing the label stops new labeling, but
  content already protected still needs **both** keys to open — never decommission the key service
  while DKE content exists.
- **Document the objects and the rollback.** Record the endpoint URL, key name, app registration, label
  and policy names, audience, hosting region, and the rollback (unpublish the label policy) for
  repeatability, change control, and audit evidence.
- **Verify platform and service support against current Microsoft docs.** DKE client-platform support
  and the unsupported-cloud-services list evolve — re-check them for your tenant before expanding.
