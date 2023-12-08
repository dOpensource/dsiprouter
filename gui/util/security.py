# make sure the generated source files are imported instead of the template ones
import sys

if sys.path[0] != '/etc/dsiprouter/gui':
    sys.path.insert(0, '/etc/dsiprouter/gui')

import os, hashlib, binascii, string, ssl, OpenSSL, secrets, re
from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from functools import wraps
from flask import render_template, request, session
from shared import updateConfig, StatusCodes
from modules.api.api_functions import createApiResponse
import settings


#
# Notes on storing credentials:
#
# best practice is to store hash and salt of the credentials
# when plaintext access is mandatory we can use symmetric encryption
# when sending encrypted data over the net asymmetric encryption is preferred
# if credentials need to be stored/accessed in a python module, they need encoded/decoded
#

def urandomChars(length=32):
    """
    Return printable characters from urandom

    :param length:  number of bytes to return
    :type length:   int
    :return:        random characters
    :rtype:         str
    """

    chars = string.ascii_lowercase + string.ascii_uppercase + string.digits
    return ''.join([chars[ord(os.urandom(1)) % len(chars)] for _ in range(length)])


class Credentials():
    """
    Wrapper class for credential management functions
    """

    SALT_LEN = 16
    CREDS_MAX_LEN = 64
    DK_LEN_DEFAULT = 48
    HASH_ITERATIONS = 10000
    # literals to make parsing from bash easier
    HASHED_CREDS_ENCODED_MAX_LEN = 128
    assert HASHED_CREDS_ENCODED_MAX_LEN == CREDS_MAX_LEN * 2

    @staticmethod
    def hashCreds(creds, salt=None, dklen=None):
        """
        Hash credentials using pbkdf2_hmac with sha512 algorithm

        :param creds:   byte string to hash
        :type creds:    bytes|str
        :param salt:    salt to hash creds with (hex encoded byte string or string)
        :type salt:     bytes|str
        :param dklen:   the derived key length to return as hash
        :type dklen:    int
        :return:        hash+salt as hex encoded byte string
        :rtype:         bytes
        """
        if isinstance(creds, bytes):
            pass
        elif isinstance(creds, str):
            creds = creds.encode('utf-8')
        else:
            raise ValueError('credentials must be a string or hex encoded byte string')
        if len(creds) > Credentials.CREDS_MAX_LEN:
            raise ValueError('credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))

        if salt is None:
            salt = get_random_bytes(Credentials.SALT_LEN)
        elif isinstance(salt, str):
            salt = salt.encode('utf-8')
        elif isinstance(salt, bytes):
            salt = binascii.unhexlify(salt)
        else:
            raise ValueError('salt must be a string or hex encoded byte string')
        if len(salt) != Credentials.SALT_LEN:
            raise ValueError('salt must be {} bytes long'.format(str(Credentials.SALT_LEN)))

        if dklen is None:
            dklen = Credentials.DK_LEN_DEFAULT
        elif not isinstance(dklen, int):
            raise ValueError('dklen must be an integer')

        hash = hashlib.pbkdf2_hmac('sha512', creds, salt, iterations=Credentials.HASH_ITERATIONS, dklen=dklen)
        return binascii.hexlify(hash + salt)

    @staticmethod
    def setCreds(dsip_creds=b'', api_creds=b'', kam_creds=b'', mail_creds=b'',
                 ipc_creds=b'', rootdb_creds=b'', sesh_creds=b''):
        """
        Set secure credentials, either by hashing or encrypting\n
        Values must be within size limit and empty values are ignored\n

        :param dsip_creds:      dsiprouter admin password as byte string
        :type dsip_creds:       bytes|str
        :param api_creds:       dsiprouter api token as byte string
        :type api_creds:        bytes|str
        :param kam_creds:       kamailio db password as byte string
        :type kam_creds:        bytes|str
        :param mail_creds:      dsiprouter mail password as byte string
        :type mail_creds:       bytes|str
        :param ipc_creds:       dsiprouter ipc connection password as byte string
        :type ipc_creds:        bytes|str
        :param rootdb_creds:    root db user's password as byte string
        :type rootdb_creds:     bytes|str
        :param sesh_creds:      flask session manager key as byte string
        :type sesh_creds:       bytes|str
        :return:                None
        :rtype:                 None
        """
        fields = {}
        local_fields = {}

        if len(dsip_creds) > 0:
            if len(dsip_creds) > Credentials.CREDS_MAX_LEN:
                raise ValueError('dsiprouter credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))
            fields['DSIP_PASSWORD'] = Credentials.hashCreds(dsip_creds)

        if len(api_creds) > 0:
            if len(api_creds) > Credentials.CREDS_MAX_LEN:
                raise ValueError('api credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))
            fields['DSIP_API_TOKEN'] = AES_CTR.encrypt(api_creds)

        if len(kam_creds) > 0:
            if len(kam_creds) > Credentials.CREDS_MAX_LEN:
                raise ValueError('kamailio credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))
            fields['KAM_DB_PASS'] = AES_CTR.encrypt(kam_creds)

        if len(mail_creds) > 0:
            if len(mail_creds) > Credentials.CREDS_MAX_LEN:
                raise ValueError('mail credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))
            fields['MAIL_PASSWORD'] = AES_CTR.encrypt(mail_creds)

        if len(ipc_creds) > 0:
            if len(ipc_creds) > Credentials.CREDS_MAX_LEN:
                raise ValueError('ipc credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))
            fields['DSIP_IPC_PASS'] = AES_CTR.encrypt(ipc_creds)

        # some fields are not synced with DB (also not constrained by max length limitations)
        if len(rootdb_creds) > 0:
            local_fields['ROOT_DB_PASS'] = AES_CTR.encrypt(rootdb_creds)

        if len(sesh_creds) > 0:
            local_fields['DSIP_SESSION_KEY'] = AES_CTR.encrypt(sesh_creds)

        # update settings based on where they are loaded from
        if len(fields) > 0 or len(local_fields) > 0:
            # update db settings
            from database import updateDsipSettingsTable
            # WARNING: if called after updating settings.py the session loader may import
            #          incorrect connection credentials and fail to connect to the DB
            updateDsipSettingsTable(fields)
            # update file settings including the local fields
            updateConfig(settings, dict(fields, **local_fields))


class AES_CTR():
    """
    Wrapper class for pycrypto's AES256 functions in AES_CTR mode
    """

    BLOCK_SIZE = 16
    KEY_SIZE = 32
    # literal to make parsing from bash easier
    NONCE_SIZE = 8
    assert NONCE_SIZE == BLOCK_SIZE // 2
    AESCTR_CREDS_ENCODED_MAX_LEN = 144
    assert AESCTR_CREDS_ENCODED_MAX_LEN == (Credentials.CREDS_MAX_LEN * 2) + (NONCE_SIZE * 2)

    @staticmethod
    def genKey(keyfile=settings.DSIP_PRIV_KEY):
        with open(keyfile, 'wb') as f:
            key = get_random_bytes(AES_CTR.KEY_SIZE)
            f.write(key)

    @staticmethod
    def encrypt(byte_string, key_file=settings.DSIP_PRIV_KEY):
        if isinstance(byte_string, str):
            byte_string = byte_string.encode('utf-8')

        with open(key_file, 'rb') as f:
            key = f.read(AES_CTR.KEY_SIZE)

        nonce = get_random_bytes(AES_CTR.NONCE_SIZE)
        aes = AES.new(key, AES.MODE_CTR, nonce=nonce)
        ct_bytes = aes.encrypt(byte_string)

        return binascii.hexlify(nonce + ct_bytes)

    @staticmethod
    def decrypt(byte_string, key_file=settings.DSIP_PRIV_KEY, decode=True):
        if isinstance(byte_string, str):
            byte_string = byte_string.encode('utf-8')
        byte_string = binascii.unhexlify(byte_string)

        with open(key_file, 'rb') as f:
            key = f.read(AES_CTR.KEY_SIZE)

        nonce = byte_string[:AES_CTR.NONCE_SIZE]
        aes = AES.new(key, AES.MODE_CTR, nonce=nonce)
        pt_bytes = aes.decrypt(byte_string[AES_CTR.NONCE_SIZE:])

        if decode:
            return pt_bytes.decode('utf-8')
        return pt_bytes

class APIToken:
    token = None

    def __init__(self, request):
        if 'Authorization' in request.headers:
            auth_header = request.headers.get('Authorization', None)
            if auth_header is not None:
                header_values = auth_header.split(' ')
                if len(header_values) == 2:
                    self.token = header_values[1]

    def isValid(self):
        try:
            if self.token:
                # Get Environment Variables if in debug mode
                # This is the only case we allow plain text token comparison
                if settings.DEBUG:
                    settings.DSIP_API_TOKEN = os.getenv('DSIP_API_TOKEN', settings.DSIP_API_TOKEN)

                # need to decrypt token
                if isinstance(settings.DSIP_API_TOKEN, bytes):
                    tokencheck = AES_CTR.decrypt(settings.DSIP_API_TOKEN)
                else:
                    tokencheck = settings.DSIP_API_TOKEN

                return secrets.compare_digest(tokencheck, self.token)

            return False
        except:
            return False


def api_security(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        apiToken = APIToken(request)
        accept_header = request.headers.get('Accept', '')

        # If user is logged into a session return right away
        if session.get('logged_in'):
            return func(*args, **kwargs)
        else:
            if 'text/html' in accept_header:
                return render_template('index.html', version=settings.VERSION), StatusCodes.HTTP_UNAUTHORIZED

        # If API Request check for license
        if not re.match('text/html|text/css', accept_header, flags=re.IGNORECASE):
            # Check if they have a Core Subscription
            if settings.DSIP_CORE_LICENSE is None or not isinstance(settings.DSIP_CORE_LICENSE, bytes):
                return createApiResponse(
                    error='http',
                    msg='Unauthorized - Core Subscription Requried.  Purchase from https://dopensource.com/product/dsiprouter-core/',
                    status_code=StatusCodes.HTTP_UNAUTHORIZED
                )
            # Check if token is valid
            elif not apiToken.isValid():
                return createApiResponse(
                    error='http',
                    msg='Unauthorized',
                    status_code=StatusCodes.HTTP_UNAUTHORIZED
                )
            # checks succeeded allow the request
            return func(*args, **kwargs)

    return wrapper


class CryptoLibInfo():
    """
    Wrapper class to standardize and simplify gathering info about the system crypto libraries
    """

    @staticmethod
    def getOpenSSLVer():
        """
        Get major, minor, patch release numbers as one int

        :return: openssl release version
        :rtype: int
        """
        return int(''.join([str(x) for x in ssl.OPENSSL_VERSION_INFO[0:3]]))

    @staticmethod
    def getSupportedSSLProtocols():
        """
        Get the support SSL/TLS protocols we serve

        :return: all support protocols
        :rtype: list
        """

        ssl_ver = CryptoLibInfo.getOpenSSLVer()
        if ssl_ver < 101:
            return [OpenSSL.SSL.TLSv1_METHOD]
        elif ssl_ver < 111:
            return [OpenSSL.SSL.TLSv1_1_METHOD, OpenSSL.SSL.TLSv1_2_METHOD]
        else:
            # TODO: pyOpenSSL does not expose TLSv1.3 support yet
            # ref: https://github.com/pyca/pyopenssl/issues/860
            return [OpenSSL.SSL.TLSv1_2_METHOD]


# TODO: move to the standard library implementation "cryptography" module
class KeyCertPair():
    """
    Represents a private key and cert(s) pair
    """

    X509_DER_FILESIG = b'0\x82'
    X509_PEM_FILESIG = b'-----BEGIN CERTIFICATE-----'
    X509_PEM_CERT_BEGIN = b'-----BEGIN CERTIFICATE-----'
    X509_PEM_CERT_END = b'-----END CERTIFICATE-----'

    def __init__(self, files):
        """
        Files to extract key/cert pair from

        :param files: A list of filepaths or objects implementing the read method
        :type files: list[str|IO]|tuple[str|IO]
        """

        if not isinstance(files, (list, tuple)):
            raise ValueError('files must be provided via a list or tuple')

        # we can accept key/cert pairs in one file or two separate files
        num_files = len(files)
        if num_files == 1:
            buff = KeyCertPair.readFile(files[0])
            self.pkey = KeyCertPair.convertKeyBuffToPkey(buff)
            self.certs = KeyCertPair.convertCertBuffToX509List(buff)
        elif num_files == 2:
            for file in files:
                buff = KeyCertPair.readFile(file)
                # we don't know which file is which so try each type one at a time
                try:
                    self.pkey = KeyCertPair.convertKeyBuffToPkey(buff)
                    continue
                except ValueError:
                    pass
                try:
                    self.certs = KeyCertPair.convertCertBuffToX509List(buff)
                    continue
                except ValueError:
                    pass
        else:
            raise ValueError("key/cert pairs must be in a single file or two files")

    @staticmethod
    def readFile(file):
        """
        Read a file via filepath or using the object's read method
        """

        if isinstance(file, str):
            with open(file, 'rb') as fp:
                return fp.read()
        elif hasattr(file, 'read'):
            return file.read()
        else:
            raise ValueError('files must contain filepaths or file pointers')

    @staticmethod
    def convertPKCS7CertToX509List(pkcs7_cert):
        """
        Modified version of: https://github.com/pyca/pyopenssl/pull/367/files#r67300900 \n
        Returns all certificates for the PKCS7 structure, if present

        :param pkcs7_cert: the PKCS cert object
        :type pkcs7_cert: OpenSSL.crypto.PKCS7
        :return: The certificates in PEM format
        :rtype: list[OpenSSL.crypto.X509]
        """

        if not isinstance(pkcs7_cert, OpenSSL.crypto.PKCS7):
            raise ValueError('Invalid PKCS7 formatted certificate')

        certs = OpenSSL.crypto._ffi.NULL

        if pkcs7_cert.type_is_signed():
            certs = pkcs7_cert._pkcs7.d.sign.cert
        elif pkcs7_cert.type_is_signedAndEnveloped():
            certs = pkcs7_cert._pkcs7.d.signed_and_enveloped.cert

        pycerts = []
        for i in range(OpenSSL.crypto._lib.sk_X509_num(certs)):
            pycert = OpenSSL.crypto.X509.__new__(OpenSSL.crypto.X509)
            pycert._x509 = OpenSSL.crypto._lib.X509_dup(OpenSSL.crypto._lib.sk_X509_value(certs, i))
            pycerts.append(pycert)

        if len(pycerts) == 0:
            raise ValueError('Invalid PKCS7 formatted certificate')

        return pycerts

    @staticmethod
    def convertKeyBuffToPkey(buff):
        """
        Convert a single private key of any format to PKey

        :param buff: private key buffer of unknown format
        :type buff: bytes
        :return: private key in OpenSSL usable format, type of
        :rtype: OpenSSL.crypto.PKey
        :raises: ValueError if the data can not be converted
        """

        if not isinstance(buff, bytes):
            raise ValueError('buffer must be bytes')

        # try loading each type of file until we find the format that works
        # PEM encoded private key
        try:
            return OpenSSL.crypto.load_privatekey(OpenSSL.crypto.FILETYPE_PEM, buff)
        except:
            pass
        # ASN1/DER encoded private key
        try:
            return OpenSSL.crypto.load_privatekey(OpenSSL.crypto.FILETYPE_ASN1, buff)
        except:
            pass
        # PKCS12 formatted file
        try:
            return OpenSSL.crypto.load_pkcs12(buff).get_privatekey()
        except:
            pass

        raise ValueError('could not convert private key to PKey')

    @staticmethod
    def convertCertBuffToX509List(buff):
        """
        Convert a one or more certificates of any format to X509

        :param buff: certificate(s) buffer of unknown format
        :type buff: bytes
        :return: certificate(s) in OpenSSL usable format
        :rtype: list[OpenSSL.crypto.X509]
        :raises: ValueError if the data can not be converted
        """

        if not isinstance(buff, bytes):
            raise ValueError('buffer must be bytes')

        # try loading each type of file until we find the format that works
        try:
            # PEM encoded certificate(s)
            if buff[0:len(KeyCertPair.X509_PEM_FILESIG)] == KeyCertPair.X509_PEM_FILESIG:
                cert_regex = KeyCertPair.X509_PEM_CERT_BEGIN + rb'.*?' + KeyCertPair.X509_PEM_CERT_END
                certs = []
                for cert_bytes in re.findall(cert_regex, buff, flags=re.DOTALL):
                    certs.append(OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, cert_bytes))
                return certs
            # ASN1/DER encoded certificate(s)
            if buff[0:len(KeyCertPair.X509_DER_FILESIG)] == KeyCertPair.X509_DER_FILESIG:
                # return [OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_ASN1, buff)]
                raise NotImplementedError('parsing DER encoded certificates is not supported, convert to PEM encoding and try again')
        except OpenSSL.crypto.Error:
            raise ValueError('could not convert certificate(s) to X509 list')
        try:
            pkcs12_obj = OpenSSL.crypto.load_pkcs12(buff)
            certs = [pkcs12_obj.get_certificate()]
            certs.extend(pkcs12_obj.get_ca_certificates())
            return certs
        except:
            pass
        try:
            pkcs7_cert = OpenSSL.crypto.load_pkcs7_data(OpenSSL.crypto.FILETYPE_PEM, buff)
            return KeyCertPair.convertPKCS7CertToX509List(pkcs7_cert)
        except:
            pass
        try:
            pkcs7_cert = OpenSSL.crypto.load_pkcs7_data(OpenSSL.crypto.FILETYPE_ASN1, buff)
            return KeyCertPair.convertPKCS7CertToX509List(pkcs7_cert)
        except:
            pass

        raise ValueError('could not convert certificate(s) to X509 list')

    @staticmethod
    def getCertSubjectPrintable(cert):
        return str(cert.get_subject())[18:-2]

    def validateKeyCertPair(self):
        """
        Check if the key/cert pair is valid

        :raises: ValueError when invalid
        """

        for cert in self.certs:
            if cert.has_expired():
                raise ValueError('certificate with subject "{}" is expired'.format(KeyCertPair.getCertSubjectPrintable(cert)))

        try:
            ctx = OpenSSL.SSL.Context(CryptoLibInfo.getSupportedSSLProtocols()[0])
            ctx.use_privatekey(self.pkey)
            ctx.use_certificate(self.certs[0])
            for cert in self.certs[1:]:
                ctx.add_extra_chain_cert(cert)
            ctx.check_privatekey()
        except:
            raise ValueError('Private key does not match x509 certificates supplied')

    def dumpPkey(self, encoding=OpenSSL.crypto.FILETYPE_PEM):
        return OpenSSL.crypto.dump_privatekey(encoding, self.pkey)

    def dumpCerts(self, encoding=OpenSSL.crypto.FILETYPE_PEM):
        return b'\n'.join([OpenSSL.crypto.dump_certificate(encoding, cert) for cert in self.certs])
