# Troubleshooting

Agent governance fails in two ways: **organisationally** (people route around the model) and
**technically** (a control or script does not behave as expected). Both are covered below. Use the
exact object names from Section 3 when you follow a fix.

---

## Organisational failure modes

### Users are sharing agents around the gate

**Symptom.** New agents keep appearing shared to teams or org-wide without an intake request or an
`AGBGOV – Agent Decision Record`.

**Cause.** Either the Step 5b org-wide sharing control is still set to **All users**, or building is
open and users share via **Specific users in your organization** (which the org-wide control does not
restrict), or the model was announced by IT and reads as optional.

**Fix.** Confirm Step 5b is set to **Specific users or groups** = `AGBGOV – Agent Sharing – Org-Wide
Approved` (this only blocks *new* org-wide shares — run `AGBGOV-Review-SharedAgents.ps1` to catch
existing ones). For team-level sharing that bypasses review, tighten the intake expectation and have
the **executive sponsor** re-announce the gate as mandatory. Publish the Tier 1 pre-approval rule
prominently so the fast path is obvious — people bypass slow gates, not fast ones.

### The Agent Review Board has become a bottleneck

**Symptom.** The intake queue is growing; makers complain the ARB is slow; shadow agents rise.

**Cause.** The Tier 1 standard-change pre-approval is not being used, or the board cadence is monthly,
or the evidence pack requirement is being applied to trivial changes.

**Fix.** Enforce the Tier 1 rule (minor instruction tweaks with no source/data/sharing change need no
ARB slot). Keep the cadence fortnightly. Reserve the full evidence pack for Tier 2+ items. If volume
is still high, the intake gate in Step 7 is too loose — return incomplete requests rather than tabling
them.

### Nobody will own the ownerless agents

**Symptom.** The **Agents without owners** count does not fall; agents sit ownerless for months.

**Cause.** No forcing function, and no sponsor willing to say "reassign or retire".

**Fix.** Put the ownerless count on the monthly scorecard the sponsor sees. Set a rule: an agent
ownerless for 30 days is **blocked**; ownerless for 60 days with no reassignment is **retired** per
Step 10. Reassign wherever a business use persists — orphaning is not a decision.

### A rejected agent's maker escalates over the ARB's head

**Symptom.** A director insists their team's agent be shared org-wide despite a rejection or a data
finding.

**Cause.** The decision rights are not backed by the sponsor.

**Fix.** This is exactly why R1 (the executive sponsor) is mandatory. Route the escalation to the
sponsor, not the ARB chair. If the sponsor overrides, record it as a **documented risk acceptance** in
the `AGBGOV – Agent Decision Record` with the sponsor named — governance survives an override that is
recorded; it does not survive one that is hidden.

---

## Technical failure modes

### `AGBGOV-Discovery.ps1` returns "copilotPackages API not available / not authorized" (HTTP 403 / 404)

**Symptom.** The Graph path fails and the script tells you to use the CSV export.

**Cause (any of).** The signed-in account lacks the `CopilotPackages.Read.All` scope or the **AI
Administrator** role; the tenant has **no Microsoft Agent 365 licence** (the Package Management API
requires one); or you are in a **Government tenant** (the API is **not available** in US Gov L4/L5).

**Fix.** Export the agent list from Microsoft 365 admin center → **Agents → All agents → Registry →
Export**, then re-run with `-RegistryCsv .\ExportedAgents.csv`. This is the expected, supported path
for Government tenants and any tenant without Agent 365. *Verify current API availability against
Microsoft documentation — it is preview/licence-gated and moving.*

### The "Anyone in your organization" sharing option is still available after Step 5b

**Symptom.** A non-approved user can still share org-wide in Agent Builder.

**Cause.** The control change has not propagated, the wrong group was selected, or the user was
already in the approved group.

**Fix.** Re-open the Copilot Control System agent sharing setting; confirm **Specific users or
groups** = `AGBGOV – Agent Sharing – Org-Wide Approved` and that the test user is not a member. Allow
time for tenant replication. Remember the documented behaviour: the control governs **new** sharing
actions and does **not** retroactively revoke existing org-wide shares — clean those up via
`AGBGOV-Review-SharedAgents.ps1` and Step 9.

### An agent shared with a user still returns no answers from its knowledge

**Symptom.** The agent is shared, but the recipient gets empty or partial responses.

**Cause.** The agent respects the **end user's** information and sensitivity privileges — if the
recipient lacks access to the underlying SharePoint/OneDrive knowledge source, the agent excludes that
content. Automatic SharePoint file/folder sharing only occurs when the agent is shared to **Specific
users in your organization** and the owner has rights to share those files; sensitivity labels are
honoured.

**Fix.** This is by design, not a governance defect — the agent cannot grant access the user does not
have. If the recipient legitimately needs the data, grant access to the source in SharePoint directly
(or reshare the agent's knowledge sources). Do **not** widen the source's permissions broadly to make
an agent work — that recreates the oversharing this whole programme exists to control.

### `AGBGOV-Validation.ps1` reports FAIL for agents you believe are compliant

**Symptom.** Gates fail unexpectedly (commonly G3 approval or G6 naming).

**Cause.** The CSV export uses different column headers than the script's defaults, or the naming uses
a hyphen (`-`) instead of the en dash (`–`), or `Lifecycle State` / `ARB Decision Reference` were not
exported.

**Fix.** The script matches column names defensively, but confirm the register export carries `Agent
Owner`, `Business Sponsor`, `Data Classification`, `Sharing Scope`, `Lifecycle State`, `ARB Decision
Reference`, and `Next Review Date`. Fix names to use the **en dash with single spaces** per the Step 6
standard — G6 tests exactly `AGBGOV – <Function> – <Purpose> – <Audience>`.

### An agent submitted to the org catalog never reaches an admin for approval

**Symptom.** Makers submit to the org catalog but no request appears in the admin center.

**Cause.** The submitter's tenant/licensing does not support org-catalog publishing, the request queue
is being viewed by an account without the right role, or (Government) you assumed a Commercial-only
behaviour.

**Fix.** Confirm you are viewing **Agents → All agents → Registry** (agent requests) as an **AI
Administrator**. Confirm publishing to the org is supported for your tenant — it **is** supported in
GCC High (GCCH) and GCC Moderate (GCCM). If submissions genuinely do not appear, verify the maker used
the org-catalog submission (not a direct share) and check current tenant support against Microsoft
documentation.

### Deleting an agent did not remove it for the users it was shared with

**Symptom.** After deletion, some access or knowledge-source sharing appears to persist.

**Cause.** Only the maker can delete a maker-built agent; when a user's access to an agent is removed,
it does **not** automatically remove their access to files/folders that were shared via the agent —
those are managed directly in SharePoint.

**Fix.** Ensure the actual owner performed the deletion (or the Agent Admin deleted an ownerless agent
from the Agent Registry). Then reconcile any lingering SharePoint file/folder permissions in
SharePoint itself. Record the block date, delete date, and this reconciliation in the `AGBGOV – Agent
Retirement Log`.

### `AGBGOV-Export-ApprovalEvidence.ps1` produces an empty audit CSV

**Symptom.** The pack builds but the directory-audit file is empty or absent.

**Cause.** The directory audit does not carry the specific Copilot/agent activity you need, or the
account lacks `AuditLog.Read.All`.

**Fix.** This is expected — the authoritative trail for Copilot/agent approve/publish/block actions is
the **unified audit log in Microsoft Purview** (Purview portal → **Audit**, or
`Search-UnifiedAuditLog`). Export the relevant activity there and add it to the pack. The decision
record remains the primary governance evidence regardless. *Verify current audit record availability
for agent actions against Microsoft documentation.*

### Government tenant: a documented agent feature is missing

**Symptom.** A capability described for Commercial (e.g. declarative agents with actions) is not
present in your GCC High / DoD tenant.

**Cause.** Government agent features roll out on a **later, narrower schedule** than Commercial.

**Fix.** Do not treat this as a defect. The governance *operating model* is identical; only feature
availability differs. Verify the capability's current GCC High / DoD availability against Microsoft's
US-sovereign-cloud documentation and adjust scope accordingly — govern the features you actually have.
