"""
The workflow consists of:
(Account creation)
- Create account key
- Register account and accept TOS
(Certificate actions)
- Select HTTP-01 within offered challenges by the CA server
- Set up http challenge resource
- Set up standalone web server
- Create domain private key and CSR
- Issue certificate
"""


import OpenSSL
import os
import shutil
import pem
import signal
import ssl
import threading
from util.file_handling import change_owner

from contextlib import contextmanager
from cryptography import x509
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import rsa

from acme import challenges
from acme import client
from acme import crypto_util
from acme import errors
from acme import messages
from acme import standalone
import josepy as jose

# This is the ACME Directory URL for `step-ca`
DIRECTORY_URL_STAGING= 'https://acme-staging-v02.api.letsencrypt.org/directory'
DIRECTORY_URL_PROD = 'https://acme-v02.api.letsencrypt.org/directory'

# User Agent
USER_AGENT="dsiprouter"

# Account key size
ACC_KEY_BITS = 2048

# Certificate private key size
CERT_PKEY_BITS = 2048

# Directory to store certificates
CERT_DIR = "/etc/dsiprouter/certs"

# Port to listen on for `http-01` challenge
ACME_PORT = 80



def new_csr(domain_name, pkey_pem=None):
    """Create certificate signing request."""
    if pkey_pem is None:
        pkey = OpenSSL.crypto.PKey()
        pkey.generate_key(OpenSSL.crypto.TYPE_RSA, CERT_PKEY_BITS)
        pkey_pem = OpenSSL.crypto.dump_privatekey(OpenSSL.crypto.FILETYPE_PEM, pkey)
    csr_pem = crypto_util.make_csr(pkey_pem, [domain_name])
    return pkey_pem, csr_pem


def select_http01_chall(orderr):
    """Look for and select `http-01` from the challenges offered by the server."""
    for authz in orderr.authorizations:
        for i in authz.body.challenges:
            if isinstance(i.chall, challenges.HTTP01):
                return i
    raise Exception('HTTP-01 challenge was not offered by the CA server.')


@contextmanager
def challenge_server(http_01_resources):
    """Manage standalone server set up and shutdown."""

    # Setting up a server that binds at PORT and any address.
    address = ('', ACME_PORT)
    try:
        servers = standalone.HTTP01DualNetworkedServers(address, http_01_resources)
        servers.serve_forever()
        yield servers
    finally:
        servers.shutdown_and_server_close()


def perform_http01(client_acme, challb, orderr):
    """Set up standalone webserver and perform HTTP-01 challenge."""

    response, validation = challb.response_and_validation(client_acme.net.key)

    resource = standalone.HTTP01RequestHandler.HTTP01Resource(
        chall=challb.chall, response=response, validation=validation)

    with challenge_server({resource}):
        # Let the CA server know that we are ready for the challenge.
        client_acme.answer_challenge(challb, response)

        # Wait for challenge status and then issue a certificate.
        # It is possible to set a deadline time.
        finalized_orderr = client_acme.poll_and_finalize(orderr)

    return finalized_orderr.fullchain_pem




def generateCertificate(domain,notification_email,directory_url=DIRECTORY_URL_PROD,cert_dir=None,debug=None,default=None):

    # Create account key
    acc_key = jose.JWKRSA(
        key=rsa.generate_private_key(public_exponent=65537,
                                     key_size=ACC_KEY_BITS,
                                     backend=default_backend()))

    # Create client configured to use our ACME server and trust our root cert
    net = client.ClientNetwork(acc_key, user_agent=USER_AGENT)
    if debug == True:
        directory_url=DIRECTORY_URL_STAGING
    directory = messages.Directory.from_json(net.get(directory_url).json())
    client_acme = client.ClientV2(directory, net=net)

    # Register account and accept TOS
    regr = client_acme.new_account(
        messages.NewRegistration.from_data(
            email=notification_email, terms_of_service_agreed=True))

    # Create domain private key and CSR
    pkey_pem, csr_pem = new_csr(domain)

    # Issue certificate
    orderr = client_acme.new_order(csr_pem)

    # Select HTTP-01 within offered challenges by the CA server
    challb = select_http01_chall(orderr)

    # The certificate is ready to be used in the variable "fullchain_pem".
    fullchain_pem = perform_http01(client_acme, challb, orderr)

    # Store the certificates
    if cert_dir is None:
        cert_dir = CERT_DIR
    
    if default == True:
        cert_domain_dir = CERT_DIR
    else:
        cert_domain_dir = "{}/{}".format(cert_dir,domain)
    
    if not os.path.exists(cert_domain_dir):
        os.makedirs(cert_domain_dir)

    key_file = "{}/dsiprouter.key".format(cert_domain_dir)
    cert_file = "{}/dsiprouter.crt".format(cert_domain_dir)

    with os.fdopen(os.open(key_file, os.O_WRONLY | os.O_CREAT, 0o640), 'w') as keyfile:
        keyfile.write(pkey_pem.decode('utf-8'))
    with os.fdopen(os.open(cert_file, os.O_WRONLY | os.O_CREAT, 0o640), 'w') as certfile:
        certfile.write(fullchain_pem)

    # Change owner to root:kamailio so that Kamailio can load the configurations
    change_owner(cert_domain_dir,"root","kamailio")
    change_owner(key_file,"root","kamailio")
    change_owner(cert_file,"root","kamailio")


    return pkey_pem.decode('utf-8'),fullchain_pem


def deleteCertificate(domain,directory_url=DIRECTORY_URL_PROD,cert_dir=None):
    # Location of certificates
    if cert_dir is None:
        cert_dir = CERT_DIR

    # Location of the certificates
    cert_domain_dir = "{}/{}".format(cert_dir,domain)

    # Remove directory that contains the cert and key for the domain
    try:
        shutil.rmtree(cert_domain_dir)

    except Exception as ex:
        pass
    # TODO: Potential send a unregister command to Let's Encrypt


if __name__ == "__main__":

    directory_url = DIRECTORY_URL_STAGING
    domain = "mack.dsiprouter.net"
    email = "mack@dopensource.com"

    key,cert = generateCertificate(domain,email,directory_url)
    print("Key:\n{}\nCert:\n{}\n".format(key,cert))
