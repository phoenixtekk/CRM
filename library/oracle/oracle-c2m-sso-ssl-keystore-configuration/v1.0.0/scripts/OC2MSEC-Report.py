# OC2MSEC-Report.py — read-only WLST coverage report of C2M/WebLogic security across the domain.
#
# PURPOSE
#     Produce a single per-server coverage sheet for stakeholders and audit: keystore rule (Custom vs
#     Demo), SSL on/off and port, minimum TLS floor, client-certificate enforcement, server private-key
#     alias, and whether the SSO asserter is wired. It rolls the per-server rows into a coverage summary
#     (how many servers are fully secured vs partial) so domain expansion progress is visible at a
#     glance. Read-only. Writes the report named Security Coverage - C2M - Report. Uses your-admin-url /
#     your-admin-user without angle brackets.
#
# HOW TO RUN
#     java weblogic.WLST OC2MSEC-Report.py
#     Connect when prompted (or pre-set WLS_ADMIN_URL / WLS_ADMIN_USER).
#
# EXPECTED RESULTS
#     A formatted coverage table on screen and in Security Coverage - C2M - Report, ending with a
#     summary line (e.g. "Secured 3/5: Custom+SSL+SSO"). Read-only: no edit session, nothing changes.
#
# NOTES
#     White-label — the repeatable way to report C2M security coverage during pilot and expansion.
#     Read-only; never prints private keys or passphrases.

import os

REPORT_NAME = 'Security Coverage - C2M - Report'
OUT_FILE = os.environ.get('OC2MSEC_OUT', 'Security-Coverage-C2M-Report.txt')
ASSERTER = os.environ.get('OC2MSEC_ASSERTER', 'C2MSEC-SSO-Asserter')


def _get(mbean, attr):
    try:
        return mbean.getAttribute(attr)
    except Exception:
        return None


def connect_readonly():
    url = os.environ.get('WLS_ADMIN_URL')
    user = os.environ.get('WLS_ADMIN_USER')
    if url and user:
        connect(user, url=url)
    else:
        connect()


def report():
    lines = ['=== %s ===' % REPORT_NAME, '']
    header = '%-24s %-10s %-6s %-6s %-9s %-9s %-8s' % (
        'Server', 'KeyStores', 'SSL', 'Port', 'TLSfloor', 'ClientCrt', 'SSO')
    lines.append(header)
    lines.append('-' * len(header))

    domainConfig()

    asserter_present = False
    try:
        realm = cmo.getSecurityConfiguration().getDefaultRealm()
        names = [p.getName() for p in realm.getAuthenticationProviders()]
        asserter_present = ASSERTER in names
    except Exception:
        asserter_present = False

    secured = 0
    total = 0
    for s in cmo.getServers():
        total += 1
        name = s.getName()
        ks = _get(s, 'KeyStores')
        ks_short = 'Custom' if ks == 'CustomIdentityAndCustomTrust' else ('Demo' if ks and 'Demo' in str(ks) else str(ks))
        ssl = s.getSSL()
        if ssl is not None:
            enabled = 'on' if _get(ssl, 'Enabled') else 'off'
            port = _get(ssl, 'ListenPort')
            tls = _get(ssl, 'MinimumTLSProtocolVersion') or 'default'
            cce = 'need' if _get(ssl, 'ClientCertificateEnforced') else 'off'
        else:
            enabled, port, tls, cce = 'off', '-', '-', '-'
        sso = 'yes' if asserter_present else 'no'
        lines.append('%-24s %-10s %-6s %-6s %-9s %-9s %-8s' % (
            name, ks_short, enabled, str(port), str(tls), cce, sso))
        if ks_short == 'Custom' and enabled == 'on' and asserter_present:
            secured += 1

    lines.append('')
    lines.append('Summary: Secured %d/%d (Custom keystores + SSL on + SSO asserter present)' % (secured, total))
    return lines


def main():
    connect_readonly()
    lines = report()
    text = '\n'.join(lines)
    print(text)
    try:
        f = open(OUT_FILE, 'w')
        f.write(text + '\n')
        f.close()
        print('\nWrote %s -> %s' % (REPORT_NAME, OUT_FILE))
    except Exception, e:
        print('Could not write %s: %s' % (OUT_FILE, str(e)))
    try:
        disconnect()
    except Exception:
        pass


main()
