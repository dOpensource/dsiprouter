# make sure the generated source files are imported instead of the template ones
import sys
sys.path.insert(0, '/etc/dsiprouter/gui')

import os, hashlib, binascii, string, ssl, OpenSSL
from Crypto.Cipher import AES
from Crypto.Util import Counter
from Crypto.Random import get_random_bytes
from sqlalchemy import exc as sql_exceptions
from shared import updateConfig,StatusCodes
from functools import wraps
from flask import Blueprint, jsonify, render_template, request, session
import settings, globals

#
# Notes on storing credentials:
#
# best practice is to store hash and salt of the credentials
# when plaintext access is mandatory we can use symmetric encryption
# when sending encrypted data over the net asymmetric encryption is preferred
# if credentials need to be stored/accessed in a python module, they need encoded/decoded
#

def urandomChars(length=64):
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

    HASH_LEN = 64
    HASH_ENCODED_LEN = 128
    SALT_LEN = 64
    SALT_ENCODED_LEN = 128
    CREDS_MAX_LEN = 64
    HASHED_CREDS_ENCODED_MAX_LEN = 256
    AESCTR_CREDS_ENCODED_MAX_LEN = 160

    @staticmethod
    def hashCreds(creds, salt=None):
        """
        Hash credentials using pbkdf2_hmac with sha512 algo

        :param creds:   byte string to hash
        :type creds:    bytes|str
        :param salt:    salt to hash creds with as hex encoded byte string
        :type salt:     bytes|str
        :return:        hash+salt as hex encoded byte string
        :rtype:         bytes
        """
        if not isinstance(creds, bytes):
            creds = creds.encode('utf-8')
        if salt is None:
            salt = get_random_bytes(Credentials.SALT_LEN)
        else:
            if not isinstance(salt, bytes):
                salt = salt.encode('utf-8')
            salt = binascii.unhexlify(salt)
        if len(salt) != Credentials.SALT_LEN:
            raise ValueError('Salt must be {} bytes long'.format(str(Credentials.SALT_LEN)))

        hash = hashlib.pbkdf2_hmac('sha512', creds, salt, 100000)
        return binascii.hexlify(hash)+binascii.hexlify(salt)

    @staticmethod
    def setCreds(dsip_creds=b'', api_creds=b'', kam_creds=b'', mail_creds=b'', ipc_creds=b'', rootdb_creds=b''):
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
                raise ValueError('kamailio credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))
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
                raise ValueError('mail credentials must be {} bytes or less'.format(str(Credentials.CREDS_MAX_LEN)))
            fields['DSIP_IPC_PASS'] = AES_CTR.encrypt(ipc_creds)

        # some fields are not synced with DB
        if len(rootdb_creds) > 0:
            local_fields['ROOT_DB_PASS'] = AES_CTR.encrypt(rootdb_creds)

        # update settings based on where they are loaded from
        if settings.LOAD_SETTINGS_FROM == 'file':
            updateConfig(settings, fields)
        elif settings.LOAD_SETTINGS_FROM == 'db':
            from database import SessionLoader, DummySession
            db = DummySession()
            try:
                db = SessionLoader()
                db.execute(
                    'update dsip_settings set {} where DSIP_ID={}'.format(', '.join(['{}=:{}'.format(x, x) for x in fields.keys()]), settings.DSIP_ID),
                    fields)
                db.commit()
            except sql_exceptions.SQLAlchemyError:
                db.rollback()
                raise
            finally:
                db.remove()

        # update local only settings everytime
        updateConfig(settings, local_fields)

class AES_CTR():
    """
    Wrapper class for pycrypto's AES256 functions in AES_CTR mode
    """

    BLOCK_SIZE = 16
    KEY_SIZE = 32

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

        iv = get_random_bytes(AES_CTR.BLOCK_SIZE)
        ctr = Counter.new(AES_CTR.BLOCK_SIZE * 8, initial_value=int(binascii.hexlify(iv), 16))
        aes = AES.new(key, AES.MODE_CTR, counter=ctr)
        cipher_bytes = iv + aes.encrypt(byte_string)

        return binascii.hexlify(cipher_bytes)

    @staticmethod
    def decrypt(byte_string, key_file=settings.DSIP_PRIV_KEY):
        if isinstance(byte_string, str):
            byte_string = byte_string.encode('utf-8')
        byte_string = binascii.unhexlify(byte_string)

        with open(key_file, 'rb') as f:
            key = f.read(AES_CTR.KEY_SIZE)

        iv = byte_string[:AES_CTR.BLOCK_SIZE]
        ctr = Counter.new(AES_CTR.BLOCK_SIZE * 8, initial_value=int(binascii.hexlify(iv), 16))
        aes = AES.new(key, AES.MODE_CTR, counter=ctr)

        return aes.decrypt(byte_string[AES_CTR.BLOCK_SIZE:])


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
                    tokencheck = AES_CTR.decrypt(settings.DSIP_API_TOKEN).decode('utf-8')
                else:
                    tokencheck = settings.DSIP_API_TOKEN

                return tokencheck == self.token

            return False
        except:
            return False


def api_security(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        apiToken = APIToken(request)

        if not session.get('logged_in') and not apiToken.isValid():
            accept_header = request.headers.get('Accept', '')

            if 'text/html' in accept_header:
                return render_template('index.html', version=settings.VERSION), StatusCodes.HTTP_UNAUTHORIZED
            else:
                payload = {'error': 'http', 'msg': 'Unauthorized', 'kamreload': globals.reload_required, 'data': []}
                return jsonify(payload), StatusCodes.HTTP_UNAUTHORIZED
        return func(*args, **kwargs)

    return wrapper
  
class EasyCrypto():
    """
    Wrapper class for some simlpified crypto use cases
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

        ssl_ver = EasyCrypto.getOpenSSLVer()
        if ssl_ver < 101:
            return [OpenSSL.SSL.TLSv1_METHOD]
        elif ssl_ver < 111:
            return [OpenSSL.SSL.TLSv1_1_METHOD, OpenSSL.SSL.TLSv1_2_METHOD]
        else:
            # TODO: pyOpenSSL does not expose TLSv1.3 support yet
            # ref: https://github.com/pyca/pyopenssl/issues/860
            return [OpenSSL.SSL.TLSv1_2_METHOD]

    @staticmethod
    def convertPKCS7CertToPEM(pkcs7_cert):
        """
        Modified version of: https://github.com/pyca/pyopenssl/pull/367/files#r67300900 \n
        Returns all certificates for the PKCS7 structure, if present

        :param pkcs7_cert: the PKCS cert object
        :type pkcs7_cert: OpenSSL.crypto.PKCS7
        :return: The certificates in PEM format
        :rtype: bytes
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

        return b'\n'.join([OpenSSL.crypto.dump_certificate(OpenSSL.crypto.FILETYPE_PEM, x) for x in pycerts])

    @staticmethod
    def convertKeyCertPairToPEM(files):
        """
        Convert private key / cert pair of random format to PEM formats

        :param files: key and cert file paths
        :type files: list
        :return: (private key object and bytes) (x509 cert object and bytes)
        :rtype: ((OpenSSL.crypto.PKey, bytes), (OpenSSL.crypto.X509, bytes))
        """

        if len(files) != 2:
            raise ValueError("Only one key/cert pair can be uploaded at a time")

        priv_key, x509_cert, priv_key_bytes, x509_cert_bytes = None, None, None, None
        for file in files:
            if isinstance(file, str):
                with open(file, 'rb') as fp:
                    file_buff = fp.read()
            elif hasattr(file, 'read'):
                file_buff = file.read()
            else:
                raise ValueError('Improper arguments for key and cert')

            # TODO: more sophisticated PEM / ASN.1 file detection prior to conversion
            # try loading each type of file and if we don't find a key and cert raise exception
            if priv_key is None or priv_key_bytes is None:
                try:
                    priv_key = OpenSSL.crypto.load_privatekey(OpenSSL.crypto.FILETYPE_PEM, file_buff)
                    priv_key_bytes = OpenSSL.crypto.dump_privatekey(OpenSSL.crypto.FILETYPE_PEM, priv_key)
                    continue
                except:
                    pass
                try:
                    priv_key = OpenSSL.crypto.load_privatekey(OpenSSL.crypto.FILETYPE_ASN1, file_buff)
                    priv_key_bytes = OpenSSL.crypto.dump_privatekey(OpenSSL.crypto.FILETYPE_PEM, priv_key)
                    continue
                except:
                    pass
                try:
                    pkcs12_obj = OpenSSL.crypto.load_pkcs12(file_buff)
                    priv_key_bytes = OpenSSL.crypto.dump_privatekey(OpenSSL.crypto.FILETYPE_PEM, pkcs12_obj.get_privatekey())
                    priv_key = OpenSSL.crypto.load_privatekey(OpenSSL.crypto.FILETYPE_PEM, priv_key_bytes)
                    continue
                except:
                    pass
            if x509_cert is None or x509_cert_bytes is None:
                try:
                    x509_cert = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, file_buff)
                    x509_cert_bytes = OpenSSL.crypto.dump_certificate(OpenSSL.crypto.FILETYPE_PEM, x509_cert)
                    continue
                except:
                    pass
                try:
                    x509_cert = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_ASN1, file_buff)
                    x509_cert_bytes = OpenSSL.crypto.dump_certificate(OpenSSL.crypto.FILETYPE_PEM, x509_cert)
                    continue
                except:
                    pass
                try:
                    pkcs12_obj = OpenSSL.crypto.load_pkcs12(file_buff)
                    x509_cert_bytes = OpenSSL.crypto.dump_certificate(OpenSSL.crypto.FILETYPE_PEM, pkcs12_obj.get_certificate())
                    x509_cert = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, x509_cert_bytes)
                    continue
                except:
                    pass
                try:
                    pkcs7_cert = OpenSSL.crypto.load_pkcs7_data(OpenSSL.crypto.FILETYPE_PEM, file_buff)
                    x509_cert_bytes = EasyCrypto.convertPKCS7CertToPEM(pkcs7_cert)
                    x509_cert = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, x509_cert_bytes)
                    continue
                except:
                    pass
                try:
                    pkcs7_cert = OpenSSL.crypto.load_pkcs7_data(OpenSSL.crypto.FILETYPE_ASN1, file_buff)
                    x509_cert_bytes = EasyCrypto.convertPKCS7CertToPEM(pkcs7_cert)
                    x509_cert = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, x509_cert_bytes)
                    continue
                except:
                    pass

        if priv_key is None or x509_cert is None or priv_key_bytes is None or x509_cert_bytes is None:
            raise ValueError("A valid certificate and key file must be provided")
        return ((priv_key, priv_key_bytes), (x509_cert, x509_cert_bytes))

    @staticmethod
    def validateKeyCertPair(priv_key, x509_cert):
        """
        Check if the key/cert pair is valid

        :param priv_key: private key to check
        :type priv_key: OpenSSL.crypto.PKey
        :param x509_cert: x509 cert to check
        :type x509_cert: OpenSSL.crypto.X509
        :return: None, raise exception on failure
        :rtype: None
        """

        if x509_cert.has_expired():
            raise ValueError("Uploaded certificate is expired, renew certificate and try again")
        try:
            ctx = OpenSSL.SSL.Context(EasyCrypto.getSupportedSSLProtocols()[0])
            ctx.use_privatekey(priv_key)
            ctx.use_certificate(x509_cert)
            ctx.check_privatekey()
        except:
            raise ValueError('Private key does not match x509 cert supplied')
        return None

