# Executive Summary — Pre-Logon VPN for Cloud & Hybrid-Joined Devices: First-Time Off-Network Sign-In & Password Reset

## The business problem
Remote-first work breaks two everyday moments that used to "just work" in the office. A **new
employee's** laptop is shipped to their home with **no cached credentials**, and they cannot complete
their **first Windows sign-in** because the device can't reach a domain controller. And a remote
user's **password expires** off-network, but they can't change it at the sign-in screen because the
password change also has to reach a domain controller. Both leave people stranded, generate help-desk
tickets, and — worst case — result in laptops being couriered around just to log in once.

## The solution
This is a complete, self-guided **decision, scenario, and validation** package for **pre-logon VPN** —
bringing the network up **before or at** Windows sign-in so a domain controller is in reach at exactly
the moment it's needed. It does the part teams actually get wrong: it **chooses the right approach**
for your fleet (Windows Always On VPN **device tunnel** vs. Cisco Secure Client **Start Before Logon /
PLAP**), explains the **two hard scenarios by device join type**, and **validates** them end to end —
proving a never-logged-on user can first-sign-in and an expired-password user can reset, both off the
network. It uses a proven method: **Assess → Configure → Pilot → Validate → Expand**, with explicit
pass/fail gates.

## What you get
- **A defensible decision** — a device-tunnel-vs-SBL/PLAP matrix by join type, OS SKU, existing VPN
  vendor, and support model, so you pick once and pick right.
- **The two scenarios covered** — first-time off-network logon and off-network password change,
  explained by join type (why it's a **hybrid/domain-joined** problem, and why **Entra-joined**
  devices largely avoid it), with SSPR positioned as the cloud complement.
- **Five PowerShell scripts** — fleet join-type + readiness discovery, on-device validation (join
  type, pre-logon path, DC reachability), a coverage report, safe remediation (preview-by-default), and
  a segmentation-group builder.
- **Requirements, testing, troubleshooting, and best-practice guides** so a competent admin can decide,
  validate, and operate it.

## Business outcomes
- **New hires sign in on day one, from anywhere** — no couriered laptops, no "log in at the office
  first" workaround.
- **Expired passwords self-resolve off-network** — the change reaches a domain controller through the
  pre-logon tunnel, cutting lockout tickets.
- **No wasted deployment** — clear guidance that cloud-only Entra-joined devices usually need neither
  approach, so you don't ship a tunnel where none is required.
- **Proven before it matters** — both scenarios validated on a pilot with explicit gates, and a
  documented break-glass fallback for the day something breaks.

## Scope and boundary
This package is the **decision + scenario + validation** layer. The **step-by-step builds** for the
device tunnel and for SBL/PLAP are **separate companion products**, referenced here by their exact
object names so the decision, the build, and the validation stay coherent — this solution does not
recreate them. VPN gateway and vendor client internals follow those products and the **vendor's
official documentation**.

## Bottom line
The two remote-work sign-in problems — first logon with no cached credentials, and password reset off
the network — solved by choosing the right pre-logon approach and proving it works, at a fraction of
the cost and time of a hands-on consulting engagement.
