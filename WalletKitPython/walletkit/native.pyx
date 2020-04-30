from core cimport *
from python cimport PyUnicode_AsUTF8, PyUnicode_FromString
from libc.stdlib cimport malloc, free
from time import time_ns
from typing import List, Tuple
from enum import Enum

cdef class CryptoWalletListener:
    cdef BRCryptoCWMListener _listener

    cdef BRCryptoCWMListener native(self):
        return self._listener

cdef class CryptoClient:
    cdef BRCryptoClient _client

    cdef BRCryptoClient native(self):
        return self._client

cdef class Network:
    cdef BRCryptoNetwork _network

    cdef BRCryptoNetwork native(self):
        return self._network

cdef class AccountBase:
    cdef BRCryptoAccount _account

    def __dealloc__(self):
        if self._account is not NULL:
            cryptoAccountGive(self._account)

    cdef BRCryptoAccount native(self):
        return self._account


class Account:
    @classmethod
    def create_from_phrase(cls, phrase: str, timestamp: int, uids: str) -> AccountBase:
        cdef BRCryptoAccount account = cryptoAccountCreate(phrase.encode('UTF-8'), timestamp, uids.encode('UTF-8'))
        if account == NULL:
            raise MemoryError
        ret = AccountBase()
        ret._account = account
        return ret

    @classmethod
    def create_from_serialization(cls, data: bytes, uids: str) -> AccountBase:
        cdef BRCryptoAccount account = cryptoAccountCreateFromSerialization(data, len(data), uids)
        if account == NULL:
            raise MemoryError
        ret = AccountBase()
        ret._account = account
        return ret

    @staticmethod
    def generate_phrase(words: List[str]) -> Tuple[str, int]:
        valid_word_count = cryptoAccountValidateWordsList(len(words))
        if valid_word_count != CRYPTO_TRUE:
            raise ValueError(f"invalid word list length {len(words)}")
        cdef char ** word_list = to_cstring_array(words)
        phrase = PyUnicode_FromString(cryptoAccountGeneratePaperKey(word_list))
        free(word_list)
        return phrase, time_ns() // 1000000

    @staticmethod
    def validate_phrase(phrase: str, words: List[str]) -> bool:
        valid_word_count = cryptoAccountValidateWordsList(len(words))
        if valid_word_count != CRYPTO_TRUE:
            raise ValueError(f"invalid word list length {len(words)}")
        cdef char ** word_list = to_cstring_array(words)
        cdef char *cphrase = PyUnicode_AsUTF8(phrase)
        ret = CRYPTO_TRUE == cryptoAccountValidatePaperKey(cphrase, word_list)
        free(word_list)
        return ret


class AddressScheme(Enum):
    BTC_LEGACY = CRYPTO_ADDRESS_SCHEME_BTC_LEGACY
    BTC_SEGWIT = CRYPTO_ADDRESS_SCHEME_BTC_SEGWIT
    ETH_DEFAULT = CRYPTO_ADDRESS_SCHEME_ETH_DEFAULT
    GEN_DEFAULT = CRYPTO_ADDRESS_SCHEME_GEN_DEFAULT


class SyncMode(Enum):
    API_ONLY = CRYPTO_SYNC_MODE_API_ONLY
    API_WITH_P2P_SEND = CRYPTO_SYNC_MODE_API_WITH_P2P_SEND
    P2P_WITH_API_SYNC = CRYPTO_SYNC_MODE_P2P_WITH_API_SYNC
    P2P_ONLY = CRYPTO_SYNC_MODE_P2P_ONLY


cdef class CryptoWalletManager:
    cdef BRCryptoWalletManager _manager

    def __cinit__(self,
                  listener: CryptoWalletListener,
                  client: CryptoClient,
                  account: AccountBase,
                  network: Network,
                  mode: SyncMode,
                  scheme: AddressScheme,
                  storage_path: str):
        self._manager = cryptoWalletManagerCreate(
            listener.native(),
            client.native(),
            account.native(),
            network.native(),
            mode.value,
            scheme.value,
            storage_path
        )
        if self._manager is NULL:
            raise MemoryError

    def __dealloc__(self):
        if self._manager is not NULL:
            cryptoWalletManagerGive(self._manager)

    cdef BRCryptoWalletManager native(self):
        return self._manager


class HasherType(Enum):
    SHA1 = CRYPTO_HASHER_SHA1
    SHA224 = CRYPTO_HASHER_SHA224
    SHA256 = CRYPTO_HASHER_SHA256
    SHA256_2 = CRYPTO_HASHER_SHA256_2
    SHA384 = CRYPTO_HASHER_SHA384
    SHA512 = CRYPTO_HASHER_SHA512
    SHA3 = CRYPTO_HASHER_SHA3
    RMD160 = CRYPTO_HASHER_RMD160
    HASH160 = CRYPTO_HASHER_HASH160
    KECCAK256 = CRYPTO_HASHER_KECCAK256
    MD5 = CRYPTO_HASHER_MD5


cdef class Hasher:
    cdef BRCryptoHasher native_hasher

    def __init__(self, hasher_type: HasherType):
        pass

    def __cinit__(self, hasher_type: HasherType):
        self.native_hasher = cryptoHasherCreate(hasher_type.value)
        if self.native_hasher is NULL:
            raise MemoryError

    def __dealloc__(self):
        if self.native_hasher is not NULL:
            cryptoHasherGive(self.native_hasher)

    def hash(self, data: bytes) -> bytes:
        hashlen = cryptoHasherLength(self.native_hasher)
        out = bytes(1) * hashlen
        cryptoHasherHash(self.native_hasher, out, hashlen, data, len(data))
        return out

cdef char ** to_cstring_array(list_str):
    cdef char ** ret = <char **> malloc(len(list_str) * sizeof(char *))
    for i in range(len(list_str)):
        ret[i] = PyUnicode_AsUTF8(list_str[i])
    return ret
