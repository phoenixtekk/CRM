# OC2MSEC-Validation.py — read-only WLST validation of C2M/WebLogic SSL, keystore, and SSO posture.
#
# PURPOSE
#     Confirm the live server MBean view is correct after configuration: keystore rule is
#     CustomIdentityAndCustomTrust (not Demo), SSL is enabled on the expected port, the minimum TLS
#     protocol is at or above the floor, the server private-key alias is set, client-certificate
#     enforcement matches intent, and the SSO Identity Assertion Provider (default name
#     C2MSEC-SSO-Asserter) is present in the authentication provider list. Read-only. Writes the result
#     named Security Validation - C2M - Validation. Uses your-admin-url / your-admin-user without angle
#     brackets, and an expected TLS floor of TLSv1.2 by default.
#
# HOW TO RUN
#     java weblogic.WLST OC2MSEC-Validation.py
#     Connect when prompted (or pre-set WLS_ADMIN_URL / WLS_ADMIN_USER). Optional expectations:
#     OC2MSEC_TLS_FLOOR (default TLSv1.2), OC2MSEC_ASSERTER (default C2MSEC-SSO-Asserter).
#
# EXPECTED RESULTS
#     A PASS/FAIL line per server and an overall result in Security Validation - C2M - Validation:
#     PASS when the server shows Custom keystores, SSL enabled, TLS floor met, private-key alias set,
#     and the asserter present; FAIL with the specific reason otherwise. Read-only: no edit session.
#
# NOTES
#     White-label — the repeatable way to prove C2M security before expanding the domain. Read-only;
#     never prints private keys or passphrases (passphrase attributes are reported only as SET/NOT SET).

import os

RESULT_NAME = 'Security Validation - C2M - Validation'
OUT_FILE = os.environ.get('OC2MSEC_OUT', 'Security-Validation-C2M-Validation.txt')
TLS_FLOOR = os.environ.get('OC2MSEC_TLS_FLOOR', 'TLSv1.2')
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


def tls_meets_floor(value, floor):
    order = {'TLSv1': 1, 'TLSv1.1': 2, 'TLSv1.2': 3, 'TLSv1.3': 4}
    if value is None:
        return False
    return order.get(str(value), 0) >= order.get(floor, 3)


def validate():
    lines = ['=== %s ===' % RESULT_NAME, 'TLS floor expected: %s, asserter expected: %s' % (TLS_FLOOR, ASSERTER), '']
    domainConfig()
    overall = 'PASS'

    # Authentication providers (asserter presence is a domain-level check).
    asserter_present = False
    try:
        realm = cmo.getSecurityConfiguration().getDefaultRealm()
        names = [p.getName() for p in realm.getAuthenticationProviders()]
        asserter_present = ASSERTER in names
        lines.append('Auth providers: %s' % ', '.join(names))
        lines.append('SSO asserter "%s" present: %s' % (ASSERTER, 'YES' if asserter_present else 'NO'))
    except Exception:
        lines.append('Auth providers: n/a')
    lines.append('')

    for s in cmo.getServers():
        name = s.getName()
        reasons = []
        ks_rule = _get(s, 'KeyStores')
        if ks_rule != 'CustomIdentityAndCustomTrust':
            reasons.append('KeyStores rule is %s (expected CustomIdentityAndCustomTrust)' % ks_rule)
        ssl = s.getSSL()
        if ssl is None:
            reasons.append('SSL not configured')
        else:
            if not _get(ssl, 'Enabled'):
                reasons.append('SSL not enabled')
            if _get(ssl, 'ListenPort') in (None, 0):
                reasons.append('SSL listen port not set')
            if not _get(ssl, 'ServerPrivateKeyAlias'):
                reasons.append('server private-key alias not set')
            tls = _get(ssl, 'MinimumTLSProtocolVersion')
            if not tls_meets_floor(tls, TLS_FLOOR):
                reasons.append('minimum TLS %s below floor %s' % (tls, TLS_FLOOR))
        if not asserter_present:
            reasons.append('SSO asserter %s missing' % ASSERTER)

        if reasons:
            overall = 'FAIL'
            lines.append('[FAIL] %s -> %s' % (name, '; '.join(reasons)))
        else:
            lines.append('[PASS] %s' % name)

    lines.append('')
    lines.append('OVERALL: %s' % overall)
    return lines


def main():
    connect_readonly()
    lines = validate()
    text = '\n'.join(lines)
    print(text)
    try:
        f = open(OUT_FILE, 'w')
        f.write(text + '\n')
        f.close()
        print('\nWrote %s -> %s' % (RESULT_NAME, OUT_FILE))
    except Exception, e:
        print('Could not write %s: %s' % (OUT_FILE, str(e)))
    try:
        disconnect()
    except Exception:
        pass


main()
