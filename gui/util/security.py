import os, hashlib, binascii, string
from Crypto.Cipher import AES
from Crypto.Util import Counter
from Crypto.Random import get_random_bytes
from sqlalchemy import exc as sql_exceptions
from shared import updateConfig
import settings

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
    def setCreds(dsip_creds=b'', api_creds=b'', kam_creds=b'', mail_creds=b'', ipc_creds=b''):
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
        :return:                None
        :rtype:                 None
        """
        fields = {}

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
