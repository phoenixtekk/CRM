# 3. Implementation Guide — ServiceNow SAM Request Fulfillment & License Reclamation Workflow

Follow these steps in order, in your ServiceNow instance (Service Catalog designer, Flow Designer, and
the SAM admin area). ServiceNow module internals (exact menu paths, plugin/store-app names, console
layouts) are version-specific and deferred to ServiceNow's official documentation — this guide gives the
correct workflow design and the named artifacts; build each artifact using ServiceNow's authoring tools.

> Model: A catalog-driven intake feeds a triage flow, which calls an entitlement check before a
> fulfillment flow allocates the license; a scheduled reclamation flow harvests unused licenses back.
> Pilot on one product family before expanding.

## Step 1 — Create the groups
1. Create the assignment group `Fulfillment Group – Software – Fulfillment` and add the fulfillment team
   as members; set a group manager.
2. Create the approval group `Approval Group – Restricted Software – Triage` and add the approvers
   (product/license owners); set a group manager.

## Step 2 — Build the intake catalog items
1. In the Service Catalog designer, create `Software Request – Standard – Intake` for self-service
   (low-cost / already-owned) software. Variables: requester, software model, business justification,
   target device/user.
2. Create `Software Request – Restricted – Intake` for paid or restricted software, with the same
   variables plus a cost-center / approver field.
3. Reference real software models (Requirement 2.4) so each request maps to an entitlement. Publish both
   items to the pilot audience only for now.

## Step 3 — Build the triage flow
1. In Flow Designer, create `Request Triage – Software – Triage`, triggered when an intake catalog item
   is submitted.
2. Logic: validate the request (requester active, software model resolved); categorize standard vs
   restricted; for standard with an owned entitlement, auto-approve; for restricted, request approval
   from `Approval Group – Restricted Software – Triage`.
3. On approval, call `Entitlement Check – Software – Entitlement` (Step 4). On rejection, close the
   request with a reason.

## Step 4 — Build the entitlement check flow
1. Create `Entitlement Check – Software – Entitlement` as a subflow.
2. Logic: look up the entitlement record for the requested software model; compute available =
   purchased minus allocated. If available > 0, return "available" and reserve one unit; if 0, return
   "needs procurement / reharvest" and route to the SAM owner (and optionally trigger reclamation
   first).
3. Keep the entitlement-match rule explicit (which entitlement a request consumes when several exist —
   e.g. edition/version/cost-center match) so fulfillment is deterministic.

## Step 5 — Build the fulfillment flow
1. Create `License Fulfillment – Software – Fulfillment`, called when the entitlement check returns
   "available".
2. Logic: allocate the license to the user/device, record the assignment against the entitlement
   (decrementing available), assign the task to `Fulfillment Group – Software – Fulfillment`, and trigger
   or instruct deployment.
3. On completion, mark the request fulfilled and stamp the fulfillment time for the time-to-fulfill KPI.

## Step 6 — Build the reclamation rules and flow
1. Create the reclamation rules:
   - `Reclaim Rule – Inactive User – Reclamation`: assignment belongs to a user marked inactive /
     terminated.
   - `Reclaim Rule – No Usage 90d – Reclamation`: assignment has no recorded usage for 90 days (tune the
     window per product).
2. Create `License Reclamation – Unused – Reclamation` as a scheduled flow (e.g. daily/weekly). Logic:
   evaluate active assignments against both rules; for matches, open a reclamation task, apply a grace
   period / notification where appropriate, then remove the assignment (returning the unit to available)
   and record the reclamation event.
3. Start in report-only mode (flag candidates, do not remove) for the first cycle, then enable removal
   after the pilot validates the candidates are correct.

## Step 7 — Build the KPI set
1. Create `KPI Set – Request & Reclamation – Reporting` with: request volume, average time-to-fulfill,
   approval cycle time, reclamation count and reclaimed units, and entitlement pool utilization
   (available vs allocated) per product.
2. Surface it as a ServiceNow dashboard (or Performance Analytics) and, for external sharing, export via
   the scripts to Excel / Power BI.

## Step 8 — Apply and validate on the pilot
1. Submit test requests through both catalog items for `Pilot Scope – First Product Family – Pilot`;
   confirm triage, entitlement check, and fulfillment behave as designed.
2. Run `SNOWSAM-Validation.ps1` to confirm the catalog items, flows, and entitlement records are present
   and consistent via the Table API. Run `SNOWSAM-Report.ps1` for the first KPI snapshot. Complete the
   Testing Guide.

## Step 9 — Enable reclamation, then expand
1. Review the report-only reclamation candidates with the SAM owner; once correct, switch
   `License Reclamation – Unused – Reclamation` to enforce (remove + return to pool). Re-run
   `SNOWSAM-Report.ps1` to confirm reclaimed units appear.
2. Expand catalog publication and the flows to the next product families only after the pilot passes.
   Use `SNOWSAM-Set-ScopeTargeting.ps1` to record/expand which products and groups are in scope.

---
### Order of operations
`Groups -> Catalog items -> Triage flow -> Entitlement check -> Fulfillment flow -> Reclamation rules & flow -> KPI set -> Pilot validate -> Enable reclamation -> Expand`
