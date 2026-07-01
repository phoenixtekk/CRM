# Executive Summary

## The risk

Pre-shared Wi-Fi keys and open switch ports are an open door. A shared passphrase can be copied off a
whiteboard or extracted from one device; an unattended network jack lets anything that plugs in reach
the corporate network. Neither approach establishes **who** or **what** is connecting. As the fleet
grows, this is an unmanaged, unauditable attack surface sitting underneath everything else.

## The outcome

Every managed device **proves its identity with a certificate before it is allowed onto the network** —
on both **Wi-Fi and wired**. Access is granted by **certificate**, not by a password anyone can share.
A device without a valid certificate simply cannot connect. This is on-premises **Network Access
Control (NAC)** done the strong way, and it is the wired/wireless counterpart to certificate-based VPN.

## The approach

The solution combines two proven platforms across a clean boundary:

- **Microsoft Intune** issues the device certificate (SCEP/PKCS, or Microsoft Cloud PKI) and delivers
  the **Wi-Fi and wired 802.1X network profiles** to every managed device — automatically, at scale.
- **Cisco ISE** acts as the **RADIUS authentication authority**, validating each device's certificate
  over **EAP-TLS** and admitting or denying it. The switches and wireless controllers enforce the
  verdict at the port.

The Intune, Entra, and certificate work is documented at **exact, click-by-click detail**. The Cisco
ISE and network-infrastructure configuration is addressed at the **architectural level with pointers
to Cisco's official documentation** — this solution never fabricates ISE or switch menu paths.

## How it is delivered

A disciplined, reversible rollout: **Assess → Configure → Pilot → Validate → Expand**, with three
explicit pass/fail gates — **certificate present**, **profile applied**, **ISE 802.1X authentication
success** — proven on a small pilot group before any fleet-wide expansion, and a documented rollback
at every step.

Included: full requirements, implementation, testing, troubleshooting, and best-practice guides, plus
**five PowerShell scripts** for readiness discovery, per-device validation, fleet coverage reporting,
safe remediation, and pilot-group targeting — all read-only or `-WhatIf` by default.

## The bottom line

Every device certificate-authenticated onto Wi-Fi and wired by Cisco ISE — profiles and certificates
delivered from Intune, and proven on a pilot before you scale. Self-guided, tested, and repeatable, at
a fraction of the cost of a bespoke consulting engagement.
