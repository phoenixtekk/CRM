# 1. Solution Overview — Endpoint Imaging, Inventory & Hardware Lifecycle Management

## What this solution is
A repeatable way to manage the whole life of every Windows device: how it gets provisioned, how it
is inventoried, when it gets refreshed, and how it is securely retired. It replaces ad hoc imaging
and a stale spreadsheet with a defined provisioning method, an accurate hardware inventory that acts
as the source of truth, and a governed procure → deploy → refresh → retire flow that ends in a
secure wipe.

## The device lifecycle model
1. Procure — a device is purchased and its hardware identity (hardware hash or serial / manufacturer
   / model) is captured before or at receipt.
2. Deploy — the device is provisioned by your chosen method (Windows Autopilot cloud provisioning or
   Configuration Manager task-sequence imaging) and enrolled in Intune.
3. Operate / inventory — the device is in service and its hardware details are tracked in Intune,
   which is the inventory system of record.
4. Refresh — when the device meets refresh criteria (age, warranty expiry, or spec), it is flagged
   for replacement and its successor is procured.
5. Retire — at end of life the device is retired and securely wiped, then removed from inventory
   (and de-registered from Autopilot if applicable).

## The provisioning decision (Autopilot vs. imaging)
This is the most important choice in the solution, so make it deliberately.

- Windows Autopilot cloud provisioning is the default for modern, cloud-managed fleets. The device
  ships from the vendor (or is reset), the user signs in, and Intune provisions it over the internet
  with no custom image. You register the device's hardware identity once; everything else is policy.
  Choose this when devices are internet-connected, you want zero-touch deployment, and you do not
  need a custom on-disk image.
- Configuration Manager task-sequence imaging is the alternative for environments that genuinely
  require it: an on-premises image with a specific disk layout or drivers, offline or
  bandwidth-constrained sites, or a managed estate already standardized on Configuration Manager.
  It lays down an OS image and applications from a distribution point on the LAN.

Why the choice matters: it decides where your "golden state" lives (Microsoft cloud policy vs. an
on-prem image), how new hardware is onboarded, and how much network you need at deploy time. Most
fleets should standardize on Autopilot and keep imaging only for the sites or device types that
truly need it.

## Hardware inventory as a source of truth
Intune holds per-device hardware details (manufacturer, model, serial number, processor, memory,
storage, enrollment and last-check-in dates). Once devices are enrolled, this becomes the single
inventory you reconcile against — not a spreadsheet. Autopilot adds a registered-devices list keyed
by hardware hash, which is your procurement-to-deployment ledger. Reconciling purchased devices
against enrolled devices is how you find machines that were bought but never deployed, or deployed
but never inventoried.

## The procure → deploy → refresh → retire flow with secure wipe
Lifecycle-stage security groups move a device through the flow and let policy and reporting target
the right stage. The solution names them with a fixed convention so they are reusable verbatim:
- `Device Lifecycle – Procurement – Procured`
- `Device Lifecycle – Fleet – Deployed`
- `Device Lifecycle – Aging – Refresh-Due`
- `Device Lifecycle – End-of-Life – Retire`

At retirement, Intune performs a secure wipe. Retire removes company data and management; Wipe
returns the device to a clean factory state (a full reset). Choosing the correct action at end of
life is what guarantees no data leaves with a retired device.

## Benefits
- Accountability — every device is tracked from procurement to retirement; nothing falls off the
  books.
- A defined provisioning method — one repeatable way to stand up a device, chosen deliberately.
- Accurate inventory — Intune is the source of truth for audits and refresh planning, not a
  spreadsheet.
- Clean retirement — every retired device is securely wiped, so no data walks out the door.
- Proven before scale — piloted on a small group before the whole fleet.

## Limitations (be honest with buyers)
- Autopilot needs the hardware identity registered (hash or vendor registration) and internet
  connectivity at provisioning; it does not lay down a custom on-disk image.
- Task-sequence imaging requires a working Configuration Manager environment (site, distribution
  point, boot media); standing that up is out of scope here, though we note where it fits.
- Intune hardware inventory reflects enrolled devices; devices bought but never enrolled appear in
  the reconciliation as gaps, not in inventory.
- A secure wipe is irreversible — confirm the device and the action before applying.

## The repeatable deployment model
> Choose the provisioning method → register/import devices and establish inventory → build the
> lifecycle-stage groups → pilot the flow → validate → expand to the fleet. The repeatable way:
> Assess → Configure → Pilot → Validate → Expand.
