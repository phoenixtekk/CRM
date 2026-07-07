# Best Practices

Durable practices for a governed, navigable SharePoint Online estate.

## Architecture

- **Flat, not nested.** Give each workload its own site collection and relate sites by **hub
  association**, never by classic subsites. Subsites inherit permissions and lifecycle in ways
  that become unmanageable at scale.
- **Few hubs, deliberate hubs.** Hubs organize the estate; they are not per-team containers. A
  handful of hubs on a clear organizing axis (corporate, divisions) beats dozens of overlapping
  ones. Reserve a hub change for a real structural change.
- **A closed set of site archetypes.** Every site should fit a known type with a known template.
  Resist one-off "special" sites; if a new pattern is genuinely needed, add it to the catalog as a
  named template rather than hand-building.

## Provisioning

- **Govern at creation, not after.** It is far cheaper to provision a site correctly than to
  remediate an ungoverned one. The request→approve→provision gate is the core control — protect
  it by constraining self-service creation.
- **Templates as versioned artifacts.** Keep each `.pnp` template under source control and version
  it. Extract from a validated reference site; do not hand-edit templates blindly.
- **Dry-run everything.** Provisioning and hub/metadata scripts default to `-WhatIf`; review the
  planned name, template, hub, and metadata before `-Commit`. Make the safe default the habit.
- **Compute names, don’t let users choose URLs.** Encode `Naming Policy – Sites – Prod` in the
  provisioning flow so every URL is consistent and machine-parseable — later reporting and
  lifecycle automation depend on it.

## Taxonomy & metadata

- **Structure is yours; values are the business’s.** Build the term store structure and the
  governed content type once; get the actual term values (departments, document types, regions)
  from the taxonomy owner. Do not invent vocabulary.
- **Publish, don’t duplicate.** Define the governed content type once in the content type gallery
  and publish it. Never redefine the same columns per site — that is how taxonomy drifts.
- **Keep term sets small and stewarded.** A term set nobody maintains rots. Assign a Term Store
  Administrator and a business taxonomy owner, and review term sets on a schedule.

## Lifecycle & governance

- **No site without an owner.** Require a business owner and two site owners at provisioning;
  refuse the request otherwise. Owner-less sites are the root of ungoverned sprawl.
- **Every site has an end-of-life path.** Use M365 group expiration for group-connected sites and
  review `PROJ-*` sites at project close. Archive or hand to retention deliberately.
- **Defer compliance determinations.** Retention schedules, records declarations, sensitivity-label
  policy, and legal holds are set by compliance/records/legal. Build the mechanism and produce the
  evidence; do not make the determination.

## Operations & safety

- **Least privilege.** Use **SharePoint Administrator**, not Global Administrator, for site and
  provisioning work; reserve Global Admin for the rare tenant-wide setting that truly needs it.
- **App registration hygiene.** Provisioning runs as the registered app `PnP – Provisioning –
  Prod`; use certificate-based app-only auth for unattended flows, store the certificate/secret in
  a secure store, and never hardcode credentials in scripts.
- **Change control for tenant-wide changes.** Disabling self-service creation, restricting group
  creation, and publishing content types are high-impact — make them in a window, record prior
  values, and keep the rollback ready.
- **Verify plan- and cloud-dependent behavior.** Storage/hub limits, advanced records/Syntex
  features, and **Commercial vs Government** admin URLs and endpoints differ by tenant — always
  confirm in your own tenant before relying on a specific limit or URL.
- **Report continuously.** Run the compliance report on a schedule, not just at go-live, so drift
  (unassociated sites, missing metadata, owner-less sites) is caught early.
