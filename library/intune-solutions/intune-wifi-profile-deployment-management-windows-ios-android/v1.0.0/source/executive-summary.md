# Executive Summary

Corporate Wi-Fi should never be a manual step. Yet most organizations still hand users an SSID and a
password, or leave proxy settings to guesswork — producing inconsistent connectivity, help-desk
tickets, and security gaps from shared keys written on sticky notes. This solution replaces that with
**centrally deployed Wi-Fi configuration profiles from Microsoft Intune**, delivered correctly to
**Windows, iOS/iPadOS, and Android Enterprise** devices so each one connects automatically, with the
right security type and the right proxy — no user action required.

The package is a **self-guided, click-by-click implementation** a competent administrator can follow
end to end, plus five tested, read-only PowerShell scripts. It authors the Wi-Fi profile on all three
platforms — handling the real differences in field labels, security-type options, and (critically) the
**proxy field**, where a manual proxy is a **host + port** and only the automatic profile takes a
**PAC URL**. Getting that one detail wrong is the single most common cause of broken Wi-Fi deployments;
this guide gets it right per platform on the first try.

Delivery follows a disciplined **Assess → Configure → Pilot → Validate → Expand** model: every object
is named to a consistent convention, assigned first to a named pilot group, proven against three
explicit pass/fail gates (profile deployed, device auto-joins the SSID, proxy applied), then expanded
to production with a documented rollback. For certificate-authenticated (WPA-Enterprise/802.1X)
networks, the guide shows how to point the Wi-Fi profile at the certificate and RADIUS trust chain
built by the companion Cisco ISE 802.1X product — deploying the profiles at scale without reproducing
the PKI work.

The outcome: every managed device on every platform joins corporate Wi-Fi automatically and correctly
— deployed once, validated on a pilot, and repeatable for every future rollout, at a fraction of the
cost of a consulting engagement.
