# 1. Solution Overview — Microsoft 365 Copilot Secure Adoption & Governance

## What Microsoft 365 Copilot is
Microsoft 365 Copilot is an AI assistant that answers questions and generates content by reasoning
over your organization's Microsoft 365 data — files in SharePoint and OneDrive, emails, Teams chats,
and calendar. It grounds its answers using the **Microsoft Graph** and the **semantic index** (a
meaning-based index of your tenant content) through an orchestration Microsoft calls **retrieval**.
The critical property to understand: Copilot only ever returns content the **signed-in user already
has permission to open**. It does not grant new access — but it makes everything a user *can* reach
instantly findable in plain language.

## How it accesses data (and why oversharing is the top risk)
1. A user asks Copilot a question.
2. Copilot searches the semantic index and Graph **as that user**, honoring existing SharePoint,
   OneDrive, and Exchange permissions.
3. It retrieves the content the user is permitted to see, reasons over it, and returns an answer
   with citations back to the source items.
4. Because retrieval respects — and is therefore limited only by — existing permissions, any file a
   user *could technically* open (even one they never knew existed) can now be surfaced by a simple
   question. This is **oversharing**: broad or stale access that was survivable when nobody browsed
   for it becomes a live data-exposure path the moment Copilot makes it searchable.

The rule of thumb: `Copilot exposure = what the user can access`. Fix the access, and you fix the
exposure. That is why this solution assesses and remediates the data estate **before** enabling
Copilot.

## What constrains Copilot (the controls this solution configures)
- **SharePoint / OneDrive sharing and permissions.** The primary control. Removing broad
  "Everyone / Everyone except external users", org-wide links, and stale guest access shrinks what
  Copilot can surface. This is the highest-leverage remediation.
- **Sensitivity labels (Microsoft Purview).** Labels classify content and can **encrypt** it and set
  usage rights. Copilot **honors** label-based access: if a user cannot open an encrypted item, Copilot
  cannot use it for that user, and Copilot-generated content **inherits** the most restrictive label
  of its sources. Labels also drive extract/copy rights that flow into Copilot responses.
- **Data Loss Prevention (DLP).** A DLP policy scoped to Copilot can **exclude labeled content** from
  being processed or summarized by Copilot, adding a policy layer on top of labels.
- **Restricted SharePoint Search / Copilot data controls.** A tenant control that limits Copilot (and
  organization-wide search) to an **allowed list of curated sites** while you remediate the rest — a
  temporary containment measure so you can pilot safely before oversharing is fully fixed.
- **Access reviews and lifecycle.** Entra access reviews and site lifecycle keep permissions from
  drifting back to oversharing after you remediate.

## AI governance (the human controls)
- **Acceptable-use policy** for Copilot: what it may/may not be used for, data-handling expectations,
  and review of AI-generated output before it is trusted or shared.
- **Admin controls** in the Microsoft 365 admin center and Copilot admin experience: who is licensed,
  which users are in the pilot, and (where available) web-grounding and plugin/agent controls.
- **Named owners** for data governance, labels/DLP, and AI use — governance is a role, not a one-time task.

## Benefits
- **Data safety** — the top risk (oversharing) is assessed and fixed before Copilot can exploit it.
- **Protection Copilot respects** — sensitivity labels and DLP constrain what Copilot surfaces and what
  its output inherits.
- **Controlled blast radius** — restricted search and a phased pilot mean a small, curated scope goes
  first, not the whole tenant.
- **Governed AI** — acceptable-use and admin controls put humans in charge of how Copilot is used.
- **Repeatable and auditable** — a documented Assess → Configure → Pilot → Validate → Expand process.

## Limitations (be honest with buyers)
- Copilot honors permissions **as they are** — it will not fix oversharing for you; the remediation is
  the work, and this solution front-loads it.
- Sensitivity labels only help where content is **actually labeled**; unlabeled files rely on
  permissions and search controls alone until labeling catches up.
- Restricted SharePoint Search is a **containment** measure, not a permanent architecture — it narrows
  Copilot but also narrows legitimate search; plan to remediate and lift it.
- Some Copilot admin and DLP-for-Copilot controls evolve quickly; portal-specific toggles are noted
  generically here and **volatile specifics are deferred to Microsoft's documentation**.
- Copilot licensing is a paid add-on with prerequisites — confirm licensing before you begin.

## The deployment model
> **Assess oversharing and access → Configure labels, DLP, search controls, and AI governance →
> Pilot with a curated group → Validate exposure and behavior → Expand.** The pattern is
> **Assess → Configure → Pilot → Validate → Expand**, with a pilot gate and rollback.
