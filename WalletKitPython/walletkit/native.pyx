from core cimport *
from python cimport Py_INCREF, PyUnicode_AsUTF8, PyUnicode_FromString, PyBytes_FromStringAndSize, PyLong_AsLong
from libc.stdlib cimport malloc, free
from asyncio import get_event_loop, new_event_loop, set_event_loop
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4
from time import time_ns
from typing import List, Tuple
from enum import Enum
from .model import BlockchainClient

cdef class CryptoWalletListener:
    cdef BRCryptoCWMListener _listener

    cdef BRCryptoCWMListener native(self):
        return self._listener

    cdef void wallet_manager_event_callback(self, BRCryptoWalletManager manager,
                                            BRCryptoWalletManagerEvent event) with gil:
        cdef const char *event_name = cryptoWalletManagerEventTypeString(event.type)
        print(f"Wallet manager event callback event={event_name.decode('utf8')}")
        cryptoWalletManagerGive(manager)

    cdef void wallet_event_callback(self, BRCryptoWalletManager manager,
                                    BRCryptoWallet wallet,
                                    BRCryptoWalletEvent event) with gil:
        cdef const char *event_name = cryptoWalletEventTypeString(event.type)
        print(f"Wallet event callback event={event_name.decode('utf8')}")
        cryptoWalletManagerGive(manager)
        cryptoWalletGive(wallet)

    cdef void transfer_event_callback(self, BRCryptoWalletManager manager,
                                      BRCryptoWallet wallet,
                                      BRCryptoTransfer transfer,
                                      BRCryptoTransferEvent event) with gil:
        cdef const char *event_name = cryptoTransferEventTypeString(event.type)
        print(f"Transfer event callback {event_name.decode('utf8')}")
        cryptoWalletManagerGive(manager)
        cryptoWalletGive(wallet)
        cryptoTransferGive(transfer)

def executor_initializer():
    event_loop = new_event_loop()
    set_event_loop(event_loop)

executor = ThreadPoolExecutor(max_workers=10, initializer=executor_initializer)

cdef class GetBlockHeightJob:
    cdef BRCryptoWalletManager _manager
    cdef BRCryptoClientCallbackState _callback_state
    cdef object _blockchain_id
    cdef object _network_client

    def run_job(self):
        try:
            block_height = get_event_loop().run_until_complete(
                self._network_client.get_block_height(self._blockchain_id))
            cwmAnnounceGetBlockNumberSuccess(self._manager, self._callback_state, PyLong_AsLong(block_height))
        except:
            cwmAnnounceGetBlockNumberFailure(self._manager, self._callback_state)
        finally:
            cryptoWalletManagerGive(self._manager)

cdef class GetTransactionsJob:
    cdef BRCryptoWalletManager _manager
    cdef BRCryptoClientCallbackState _callback_state
    cdef object _blockchain_id
    cdef object _addresses
    cdef object _currency
    cdef object _start_block
    cdef object _end_block
    cdef object _network_client

    def run_job(self):
        try:
            transactions = get_event_loop().run_until_complete(
                self._network_client.get_raw_transactions(
                    self._blockchain_id, self._addresses, self._currency,
                    self._start_block, self._end_block
                ))
            for tx in transactions:
                cwmAnnounceGetTransactionsItem(
                    self._manager,
                    self._callback_state,
                    TransferStatus.from_network_status(tx.status).value,
                    tx.data,
                    len(tx.data),
                    tx.timestamp,
                    tx.block_height
                )
            cwmAnnounceGetTransactionsComplete(self._manager, self._callback_state, CRYPTO_TRUE)
        except:
            cwmAnnounceGetTransactionsComplete(self._manager, self._callback_state, CRYPTO_FALSE)
        finally:
            cryptoWalletManagerGive(self._manager)

cdef class CryptoClient:
    cdef BRCryptoClient _client
    cdef object _network_client

    cdef BRCryptoClient native(self):
        return self._client

    cdef void get_block_number(self, BRCryptoWalletManager manager,
                               BRCryptoClientCallbackState callback_state) with gil:
        cdef BRCryptoNetwork network = cryptoWalletManagerGetNetwork(manager)
        cdef const char *network_uids = cryptoNetworkGetUids(network)
        blockchain_id = network_uids.decode('utf8')
        print(f"[CryptoClient] get_block_number blocchain_id={blockchain_id}")
        job = GetBlockHeightJob()
        job._manager = manager
        job._callback_state = callback_state
        job._blockchain_id = blockchain_id
        job._network_client = self._network_client
        executor.submit(job.run_job)

    cdef void get_transactions(self, BRCryptoWalletManager manager,
                               BRCryptoClientCallbackState callback_state,
                               const char ** caddresses,
                               size_t address_count,
                               const char *currency,
                               uint64_t start_block_number,
                               uint64_t end_block_number) with gil:
        cdef BRCryptoNetwork network = cryptoWalletManagerGetNetwork(manager)
        cdef const char *network_uids = cryptoNetworkGetUids(network)
        blockchain_id = network_uids.decode('utf8')
        currency_id = currency.decode('utf8')
        addresses = []
        for i in range(address_count):
            addresses.append(caddresses[i].decode('utf8'))
        print(f"[CryptoClient] get_transactions blockchain_id={blockchain_id} "
              f"address_count={len(addresses)} currency_id={currency_id}")
        job = GetTransactionsJob()
        job._manager = manager
        job._callback_state = callback_state
        job._blockchain_id = blockchain_id
        job._addresses = addresses
        job._currency = currency_id
        job._start_block = start_block_number
        job._end_block = end_block_number
        job._network_client = self._network_client
        executor.submit(job.run_job)

    cdef void get_transfers(self, BRCryptoWalletManager manager,
                            BRCryptoClientCallbackState callback_state,
                            const char ** addresses,
                            size_t address_count,
                            const char *currency,
                            uint64_t start_block_number,
                            uint64_t end_block_number) with gil:
        for i in range(address_count):
            print(f"Getting transfers address={addresses[i].decode('utf8')} "
                  f"currency={currency.decode('utf8')} "
                  f"start_block_number={start_block_number} "
                  f"end_block_number={end_block_number}")
        cryptoWalletManagerGive(manager)

    cdef void submit_transaction(self, BRCryptoWalletManager manager,
                                 BRCryptoClientCallbackState callback_state,
                                 const uint8_t *transaction,
                                 size_t transaction_length,
                                 const char *raw_tx_hex) with gil:
        print(f"Submitting transaction raw_tx={raw_tx_hex.decode('utf8')}")
        cryptoWalletManagerGive(manager)

    cdef void estimate_transaction_fee(self, BRCryptoWalletManager manager,
                                       BRCryptoClientCallbackState callback_state,
                                       const uint8_t *transaction,
                                       size_t transaction_length,
                                       const char *raw_tx_hex) with gil:
        print(f"Estimating transaction fee raw_tx={raw_tx_hex.decode('utf8')}")
        cryptoWalletManagerGive(manager)


class NetworkType(Enum):
    BTC = CRYPTO_NETWORK_TYPE_BTC
    BCH = CRYPTO_NETWORK_TYPE_BCH
    ETH = CRYPTO_NETWORK_TYPE_ETH
    XRP = CRYPTO_NETWORK_TYPE_XRP
    HBAR = CRYPTO_NETWORK_TYPE_HBAR


cdef class NetworkBase:
    cdef BRCryptoNetwork _network

    def __dealloc__(self):
        if self._network is not NULL:
            cryptoNetworkGive(self._network)

    cdef BRCryptoNetwork native(self):
        return self._network

    @property
    def uids(self) -> str:
        return PyUnicode_FromString(cryptoNetworkGetUids(self._network))

    @property
    def type(self) -> NetworkType:
        return NetworkType(cryptoNetworkGetCanonicalType(self._network))

    @property
    def name(self) -> str:
        return PyUnicode_FromString(cryptoNetworkGetName(self._network))

    @property
    def is_mainnet(self) -> bool:
        return CRYPTO_TRUE == cryptoNetworkIsMainnet(self._network)

    @property
    def currency_code(self) -> str:
        return PyUnicode_FromString(cryptoNetworkGetCurrencyCode(self._network))

    def __repr__(self):
        return f'<Network {self.name} mainnet={self.is_mainnet}>'

    def __str__(self):
        return self.name


class Network:
    @staticmethod
    def install_builtins() -> List[NetworkBase]:
        cdef size_t networks_count = 0
        cdef BRCryptoNetwork *networks = cryptoNetworkInstallBuiltins(&networks_count)
        ret = []
        for i in range(networks_count):
            network = networks[i]
            obj = NetworkBase()
            obj._network = network
            ret.append(obj)
        return ret


cdef class AccountBase:
    cdef BRCryptoAccount _account

    def __dealloc__(self):
        if self._account is not NULL:
            cryptoAccountGive(self._account)

    cdef BRCryptoAccount native(self):
        return self._account

    @property
    def uids(self) -> str:
        return PyUnicode_FromString(cryptoAccountGetUids(self._account))

    @property
    def timestamp(self) -> int:
        return cryptoAccountGetTimestamp(self._account)

    @property
    def file_system_identifier(self) -> str:
        return PyUnicode_FromString(cryptoAccountGetFileSystemIdentifier(self._account))

    def serialize(self) -> bytes:
        cdef size_t bytes_count = 0
        cdef uint8_t *ret_bytes = cryptoAccountSerialize(self._account, &bytes_count)
        return PyBytes_FromStringAndSize(<char *> ret_bytes, bytes_count)

    def validate_serialization(self, serialization: bytes) -> bool:
        return CRYPTO_TRUE == cryptoAccountValidateSerialization(self._account, serialization, len(serialization))


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
        cdef BRCryptoAccount account = cryptoAccountCreateFromSerialization(data, len(data), uids.encode('UTF-8'))
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

    @staticmethod
    def generate(words: List[str]) -> AccountBase:
        phrase, ms_timestamp = Account.generate_phrase(words)
        return Account.create_from_phrase(phrase, ms_timestamp, str(uuid4()))


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


class TransferStatus(Enum):
    CREATED = CRYPTO_TRANSFER_STATE_CREATED
    SIGNED = CRYPTO_TRANSFER_STATE_SIGNED
    SUBMITTED = CRYPTO_TRANSFER_STATE_SUBMITTED
    INCLUDED = CRYPTO_TRANSFER_STATE_INCLUDED
    ERRORED = CRYPTO_TRANSFER_STATE_ERRORED
    DELETED = CRYPTO_TRANSFER_STATE_DELETED

    @staticmethod
    def from_network_status(status: str):
        m = {
            "confirmed": TransferStatus.INCLUDED,
            "submitted": TransferStatus.SUBMITTED,
            "reverted": TransferStatus.SUBMITTED,
            "failed": TransferStatus.ERRORED,
            "rejected": TransferStatus.ERRORED
        }
        return m[status]


cdef class WalletManagerBase:
    cdef BRCryptoWalletManager _manager

    def __dealloc__(self):
        if self._manager is not NULL:
            cryptoWalletManagerGive(self._manager)

    cdef BRCryptoWalletManager native(self):
        return self._manager

    def connect(self):
        cryptoWalletManagerConnect(self._manager, NULL)

    def disconnect(self):
        cryptoWalletManagerDisconnect(self._manager)

    def sync(self):
        cryptoWalletManagerSync(self._manager)

    def stop(self):
        cryptoWalletManagerStop(self._manager)

    def set_reachable(self, reachable: bool):
        cryptoWalletManagerSetNetworkReachable(self._manager, CRYPTO_TRUE if reachable else CRYPTO_FALSE)


class WalletManager:
    @staticmethod
    def create(account: AccountBase,
               network: NetworkBase,
               blockchain_client: BlockchainClient,
               sync_mode: SyncMode,
               address_scheme: AddressScheme,
               storage_path: str) -> WalletManagerBase:
        cwml = CryptoWalletListener()
        cdef BRCryptoCWMListener cwml_native
        cwml_native.context = <BRCryptoCWMListenerContext> cwml
        Py_INCREF(cwml)
        cwml_native.walletManagerEventCallback = <BRCryptoCWMListenerWalletManagerEvent> cwml.wallet_manager_event_callback
        cwml_native.walletEventCallback = <BRCryptoCWMListenerWalletEvent> cwml.wallet_event_callback
        cwml_native.transferEventCallback = <BRCryptoCWMListenerTransferEvent> cwml.transfer_event_callback
        cwml._listener = cwml_native

        ccli = CryptoClient()
        cdef BRCryptoClient ccli_native
        ccli_native.context = <BRCryptoClientContext> ccli
        Py_INCREF(ccli)
        ccli_native.funcGetBlockNumber = <BRCryptoClientGetBlockNumberCallback> ccli.get_block_number
        ccli_native.funcGetTransactions = <BRCryptoClientGetTransactionsCallback> ccli.get_transactions
        ccli_native.funcGetTransfers = <BRCryptoClientGetTransfersCallback> ccli.get_transfers
        ccli_native.funcSubmitTransaction = <BRCryptoClientSubmitTransactionCallback> ccli.submit_transaction
        ccli_native.funcEstimateTransactionFee = <BRCryptoClientEstimateTransactionFeeCallback> ccli.estimate_transaction_fee
        ccli._client = ccli_native
        ccli._network_client = blockchain_client

        cwm_native = cryptoWalletManagerCreate(
            cwml_native,
            ccli_native,
            account.native(),
            network.native(),
            sync_mode.value,
            address_scheme.value,
            PyUnicode_AsUTF8(storage_path)
        )
        ret = WalletManagerBase()
        ret._manager = cwm_native
        return ret


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
