import hashlib, binascii
from Crypto.Cipher import AES
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

def hashCreds(creds, salt=None):
    """
    Hash credentials using pbkdf2_hmac with sha512 algo
    :param creds:   byte string to hash
    :param salt:    salt to hash creds with as hex encoded byte string
    :return:        (hash, salt) as hex encoded byte strings
    """
    if not isinstance(creds, bytes):
        creds = creds.encode('utf-8')
    if salt is None:
        salt = get_random_bytes(64)
    else:
        if not isinstance(salt, bytes):
            salt = salt.encode('utf-8')
        salt = binascii.unhexlify(salt)
    if len(salt) > 64:
        raise ValueError('Salt must be 64 bytes')

    hash = hashlib.pbkdf2_hmac('sha512', creds, salt, 100000)
    return (binascii.hexlify(hash), binascii.hexlify(salt))


def setCreds(dsip_creds=b'', api_creds=b'', kam_creds=b'', mail_creds=b'', ipc_creds=b''):
    """
    Set secure credentials, either by hashing or encrypting
    :param dsip_creds:      dsiprouter admin password as byte string
    :param api_creds:       dsiprouter api token as byte string
    :param kam_creds:       kamailio db password as byte string
    :param mail_creds:      dsiprouter mail password as byte string
    :param ipc_creds:       dsiprouter ipc connection password as byte string
    :return:                None
    """
    fields = {}
    aes = AES_CBC()

    if len(dsip_creds) > 0:
        if len(dsip_creds) > 64:
            raise ValueError('dsiprouter credentials must be 64 bytes or less')
        hash, salt = hashCreds(dsip_creds)
        fields['DSIP_PASSWORD'] = hash
        fields['DSIP_SALT'] = salt

    if len(api_creds) > 0:
        if len(api_creds) > 64:
            raise ValueError('kamailio credentials must be 64 bytes')
        fields['DSIP_API_TOKEN'] = aes.encrypt(api_creds)

    if len(kam_creds) > 0:
        if len(kam_creds) > 64:
            raise ValueError('kamailio credentials must be 64 bytes or less')
        fields['KAM_DB_PASS'] = aes.encrypt(kam_creds)

    if len(mail_creds) > 0:
        if len(mail_creds) > 64:
            raise ValueError('mail credentials must be 64 bytes or less')
        fields['MAIL_PASSWORD'] = aes.encrypt(mail_creds)

    if len(ipc_creds) > 0:
        if len(ipc_creds) > 64:
            raise ValueError('mail credentials must be 64 bytes or less')
        fields['DSIP_IPC_PASS'] = aes.encrypt(ipc_creds)

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
            SessionLoader.remove()

class AES_CBC(object):
    """
    Wrapper class for pycrypto's AES256 functions in CBC mode
    """

    def __init__(self, keyfile=settings.DSIP_PRIV_KEY):
        self.keyfile = keyfile

    def genKey(self):
        with open(self.keyfile, 'wb') as f:
            key = get_random_bytes(AES.block_size)
            iv = get_random_bytes(AES.block_size)
            f.write(key)
            f.write(iv)

    def pad(self, byte_string, block_size=16):
        # we don't need to pad if multiple of block size
        remainder = len(byte_string) % block_size
        if remainder > 0:
            padding_len = block_size - remainder
            byte_string = byte_string + padding_len * chr(block_size).encode('utf-8')
        return byte_string

    def unpad(self, byte_string, block_size=16):
        return byte_string.rstrip(chr(block_size).encode('utf-8'))

    def encrypt(self, byte_string):
        if isinstance(byte_string, str):
            byte_string = byte_string.encode('utf-8')

        with open(self.keyfile, 'rb') as f:
            key = f.read(AES.block_size)
            iv = f.read(AES.block_size)

        cipher = AES.new(key, AES.MODE_CBC, iv)
        cipher_bytes = cipher.encrypt(self.pad(byte_string, AES.block_size))
        return binascii.hexlify(cipher_bytes)

    def decrypt(self, byte_string):
        if isinstance(byte_string, str):
            byte_string = byte_string.encode('utf-8')
        byte_string = binascii.unhexlify(byte_string)

        with open(self.keyfile, 'rb') as f:
            key = f.read(AES.block_size)
            iv = f.read(AES.block_size)

        cipher = AES.new(key, AES.MODE_CBC, iv)
        plain_bytes = self.unpad(cipher.decrypt(byte_string))
        return plain_bytes
