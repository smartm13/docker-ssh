import ldap
import sys
import os
def get_user(username, password, domain="ORGG.com", ldap_uri="ldap://raappdc1.corp.{domain}:3268"):
    if domain == "ORGG.com" and os.environ.get('org_domain'):
        domain = os.environ.get('org_domain')
    email = username +"@"+ domain
    try:
        connect = ldap.initialize(ldap_uri.format(domain=domain))
        connect.protocol_version = 3
        connect.set_option(ldap.OPT_REFERRALS, 0)
        connect.simple_bind_s(email, password)
        connect.unbind_s()
        return True
    except ldap.LDAPError:
        return None

if __name__=='__main__':    
    if get_user(*sys.argv[1:]):
        print('Success') or sys.exit(0)
    else:
        print('Failed') or sys.exit(1)
