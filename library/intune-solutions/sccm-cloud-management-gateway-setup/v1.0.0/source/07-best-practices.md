# 7. Best Practices — Configuration Manager Cloud Management Gateway (CMG)

- Pilot first, always. Stand the CMG up against `CMG – Internet Clients – Pilot` and prove policy,
  inventory, and a real deployment over the internet before widening client settings — this is the
  single most important practice.
- Prefer Microsoft Entra ID token authentication. For Entra-joined / hybrid-joined fleets, token auth
  avoids issuing and managing client PKI certificates; reserve PKI client auth for devices that cannot
  be Entra-registered.
- Name the CMG by its certificate. The CMG service name comes from the
  `CMG – Internet Clients – Server Auth` certificate subject/SAN; match the public DNS CNAME to it
  exactly, or clients cannot connect.
- Watch certificate expiry. The server authentication certificate expiring silently breaks all
  internet management; track the expiry and renew ahead of time with your CA/PKI team.
- Keep it outbound-only. Never open inbound firewall ports to the site for CMG; all traffic is
  outbound from clients to Azure and from the connection point to Azure.
- Enable Enhanced HTTP. For token-based auth, Enhanced HTTP on the site systems is the clean path;
  use full PKI only where your environment already requires it.
- Right-size CMG instances. Start at one VM instance for the pilot and scale instances only as real
  internet-client load and content demand require — Azure cost scales with instances and egress.
- Plan the content path. Decide up front whether the CMG serves content or you use another internet
  content source, so internet deployments do not stall.
- Coexist deliberately. Alongside co-management with Microsoft Intune, decide which authority owns
  each workload so the two do not conflict.
- Monitor continuously. Use the Connection Analyzer and `CMG-Report.ps1` each cycle to catch a dark
  client, an unhealthy connection point, or an aging certificate early.
- Document the build. Record the CMG name, region, resource group, certificate subject/expiry, auth
  model, and assigned collections for audits and repeatability.
