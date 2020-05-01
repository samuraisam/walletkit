from core cimport *
from python cimport Py_INCREF, PyUnicode_AsUTF8, PyUnicode_FromString, PyBytes_FromStringAndSize
from python cimport PyLong_AsLong, PyLong_AsSize_t, PyLong_FromUnsignedLong, PyLong_FromSize_t
from libc.stdio cimport printf
from libc.stdlib cimport malloc, free
from asyncio import get_event_loop, new_event_loop, set_event_loop
from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4
from time import time_ns
from typing import List, Tuple, Callable, Optional
from enum import Enum
from babel.numbers import format_currency
from .model import BlockchainClient, WalletManagerListener
from .model import (WalletManagerEventType, WalletManagerStateEvent, WalletManagerWalletEvent, WalletManagerSyncEvent,
                    WalletManagerBlockHeightEvent, WalletManagerSyncStoppedReason)

# TODO: this should not be global
def executor_initializer():
    event_loop = new_event_loop()
    set_event_loop(event_loop)

executor = ThreadPoolExecutor(max_workers=10, initializer=executor_initializer)

cdef class CryptoWalletListener:
    cdef BRCryptoCWMListener _listener
    cdef object _state_listener

    cdef BRCryptoCWMListener native(self):
        return self._listener

    cdef void wallet_manager_event_callback(self, BRCryptoWalletManager manager,
                                            BRCryptoWalletManagerEvent event) with gil:
        cdef const char *event_name = cryptoWalletManagerEventTypeString(event.type)
        print(f"Wallet manager event callback event={event_name.decode('utf8')}")
        if self._state_listener is not None:
            event_type = WalletManagerEventType(event.type)
            if (event.type == CRYPTO_WALLET_MANAGER_EVENT_CREATED or
                    event.type == CRYPTO_WALLET_MANAGER_EVENT_CHANGED or
                    event.type == CRYPTO_WALLET_MANAGER_EVENT_DELETED):
                listener_event = WalletManagerStateEvent(event_type)  # TODO: fill out state
                self._state_listener.received_wallet_manager_event(listener_event)
            elif (event.type == CRYPTO_WALLET_MANAGER_EVENT_WALLET_ADDED or
                  event.type == CRYPTO_WALLET_MANAGER_EVENT_WALLET_CHANGED or
                  event.type == CRYPTO_WALLET_MANAGER_EVENT_WALLET_DELETED):
                listener_event = WalletManagerWalletEvent(event_type)  # TODO: fill out wallet
                self._state_listener.received_wallet_manager_event(listener_event)
            elif (event.type == CRYPTO_WALLET_MANAGER_EVENT_SYNC_STARTED or
                  event.type == CRYPTO_WALLET_MANAGER_EVENT_SYNC_CONTINUES or
                  event.type == CRYPTO_WALLET_MANAGER_EVENT_SYNC_STOPPED or
                  event.type == CRYPTO_WALLET_MANAGER_EVENT_SYNC_RECOMMENDED):
                listener_event = WalletManagerSyncEvent(event_type)  # TODO: fill out reason/etc
                if event.type == CRYPTO_WALLET_MANAGER_EVENT_SYNC_STOPPED:
                    listener_event.reason = WalletManagerSyncStoppedReason(event.u.syncStopped.reason.type)
                self._state_listener.received_wallet_manager_event(listener_event)
            elif event.type == CRYPTO_WALLET_MANAGER_EVENT_BLOCK_HEIGHT_UPDATED:
                listener_event = WalletManagerBlockHeightEvent(event_type)  # TODO: fill out height
                self._state_listener.received_wallet_manager_event(listener_event)
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

cdef class GetBlockHeightJob:
    cdef BRCryptoWalletManager _manager
    cdef BRCryptoClientCallbackState _callback_state
    cdef object _blockchain_id
    cdef object _network_client_factory

    def run_job(self):
        try:
            network_client = self._network_client_factory()
            block_height = get_event_loop().run_until_complete(network_client.get_block_height(self._blockchain_id))
            cwmAnnounceGetBlockNumberSuccess(self._manager, self._callback_state, PyLong_AsLong(block_height))
        except Exception as e:
            printf("[GetBlockHeightJob] error: %s", PyUnicode_AsUTF8(str(e)))
            cwmAnnounceGetBlockNumberFailure(self._manager, self._callback_state)
        finally:
            cryptoWalletManagerGive(self._manager)


cdef extern from "string.h":
    int strcmp(const char *s1, const char *s2)


cdef BRCryptoTransferStateType crypto_transfer_state(const char *state_str):
    if 0 == strcmp(state_str, "confirmed"):
        return CRYPTO_TRANSFER_STATE_INCLUDED
    if 0 == strcmp(state_str, "submitted") or 0 == strcmp(state_str, "reverted"):
        return CRYPTO_TRANSFER_STATE_SUBMITTED
    if 0 == strcmp(state_str, "failed") or 0 == strcmp(state_str, "rejected"):
        return CRYPTO_TRANSFER_STATE_ERRORED
    # TODO: not this!
    return CRYPTO_TRANSFER_STATE_SUBMITTED

cdef class GetTransactionsJob:
    cdef BRCryptoWalletManager _manager
    cdef BRCryptoClientCallbackState _callback_state
    cdef object _blockchain_id
    cdef object _addresses
    cdef object _currency
    cdef object _start_block
    cdef object _end_block
    cdef object _network_client_factory

    def run_job(self):
        try:
            network_client = self._network_client_factory()
            transactions = get_event_loop().run_until_complete(
                network_client.get_raw_transactions(
                    self._blockchain_id, self._addresses, self._currency,
                    self._start_block, self._end_block
                ))
            for tx in transactions:
                cwmAnnounceGetTransactionsItem(
                    self._manager,
                    self._callback_state,
                    crypto_transfer_state(PyUnicode_AsUTF8(tx.status)),
                    tx.data,
                    PyLong_AsSize_t(len(tx.data)),
                    PyLong_AsLong(tx.timestamp),
                    PyLong_AsLong(tx.block_height)
                )
            cwmAnnounceGetTransactionsComplete(self._manager, self._callback_state, CRYPTO_TRUE)
        except Exception as e:
            printf("[GetTransactionsJob] error: %s\n", PyUnicode_AsUTF8(str(e)))
            cwmAnnounceGetTransactionsComplete(self._manager, self._callback_state, CRYPTO_FALSE)
        finally:
            cryptoWalletManagerGive(self._manager)

cdef class CryptoClient:
    cdef BRCryptoClient _client
    cdef object _network_client_factory

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
        job._network_client_factory = self._network_client_factory
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
        job._network_client_factory = self._network_client_factory
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
    def find_builtin(uids: str) -> NetworkBase:
        cdef BRCryptoNetwork network = cryptoNetworkFindBuiltin(PyUnicode_AsUTF8(uids))
        if network is not NULL:
            obj = NetworkBase()
            obj._network = network
            return obj

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
        print(f"phrase is {phrase}")
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
            "confirmed": CRYPTO_TRANSFER_STATE_INCLUDED,
            "submitted": CRYPTO_TRANSFER_STATE_SUBMITTED,
            "reverted": CRYPTO_TRANSFER_STATE_SUBMITTED,
            "failed": CRYPTO_TRANSFER_STATE_ERRORED,
            "rejected": CRYPTO_TRANSFER_STATE_ERRORED
        }
        return TransferStatus(m[status])


cdef class UnitBase:
    cdef BRCryptoUnit _unit

    @property
    def currency(self) -> CurrencyBase:
        obj = CurrencyBase()
        obj._currency = cryptoUnitGetCurrency(self._unit)
        return obj

    @property
    def uids(self) -> str:
        return PyUnicode_FromString(cryptoUnitGetUids(self._unit))

    @property
    def name(self) -> str:
        return PyUnicode_FromString(cryptoUnitGetName(self._unit))

    @property
    def symbol(self) -> str:
        return PyUnicode_FromString(cryptoUnitGetSymbol(self._unit))

    @property
    def base(self) -> UnitBase:
        obj = UnitBase()
        obj._unit = cryptoUnitGetBaseUnit(self._unit)
        return obj

    @property
    def decimals(self) -> int:
        return PyLong_FromSize_t(cryptoUnitGetBaseDecimalOffset(self._unit))

    def is_compatible_with(self, other: UnitBase) -> bool:
        if not isinstance(other, UnitBase):
            raise ValueError("other must be a Unit object")
        return CRYPTO_TRUE == cryptoUnitIsCompatible(self._unit, <BRCryptoUnit>other._unit)

    def has_currency(self, currency: CurrencyBase) -> bool:
        if not isinstance(currency, CurrencyBase):
            raise ValueError("currency must be a Currency object")
        return CRYPTO_TRUE == cryptoUnitHasCurrency(self._unit, <BRCryptoCurrency>currency._currency)

    def __str__(self):
        return self.name

    def __repr__(self):
        return f"<Unit: {self.name}>"

    def __eq__(self, other):
        if not isinstance(other, UnitBase):
            return False
        return cryptoUnitIsIdentical(self._unit, <BRCryptoUnit>other._unit)


class Unit:
    @staticmethod
    def create_base(currency: CurrencyBase, code: str, name: str, symbol: str):
        obj = UnitBase()
        obj._unit = cryptoUnitCreateAsBase(currency._currency,
                                           PyUnicode_AsUTF8(code),
                                           PyUnicode_AsUTF8(name),
                                           PyUnicode_AsUTF8(symbol))
        return obj

    @staticmethod
    def create(currency: CurrencyBase, code: str, name: str, symbol: str, base: UnitBase, decimals: int):
        obj = UnitBase()
        obj._unit = cryptoUnitCreate(<BRCryptoCurrency>currency._currency,
                                     PyUnicode_AsUTF8(code),
                                     PyUnicode_AsUTF8(name),
                                     PyUnicode_AsUTF8(symbol),
                                     <BRCryptoUnit>base._unit,
                                     PyLong_AsSize_t(decimals))
        return obj


cdef class CryptoAmountBase:
    cdef BRCryptoAmount _amount

    @property
    def unit(self) -> UnitBase:
        obj = UnitBase()
        obj._unit = cryptoAmountGetUnit(self._amount)
        return obj

    @property
    def currency(self) -> CurrencyBase:
        return self.unit.currency

    @property
    def is_negative(self) -> bool:
        return CRYPTO_TRUE == cryptoAmountIsNegative(self._amount)

    @property
    def int(self) -> int:
        cdef const char * amt = cryptoAmountGetStringPrefaced(self._amount, 16, "")
        return int.from_bytes(amt, byteorder='little')

    def float(self, as_unit: UnitBase) -> float:
        if not isinstance(as_unit, UnitBase):
            raise ValueError("as_unit must be a Unit object")
        cdef BRCryptoBoolean overflow
        cdef double ret = cryptoAmountGetDouble(self._amount, as_unit._unit, &overflow)
        return ret

    def format(self, as_unit: UnitBase, locale='en_US') -> str:
        return format_currency(self.float(as_unit), currency=as_unit.symbol, locale=locale,
                               currency_digits=as_unit.decimals)

    def is_compatible(self, with_amount: CryptoAmountBase) -> bool:
        if not isinstance(with_amount, CryptoAmountBase):
            raise ValueError("with_amount must be an Amount object")
        return CRYPTO_TRUE == cryptoAmountIsCompatible(self._amount, with_amount._amount)

    def has_currency(self, currency: CurrencyBase) -> bool:
        if not isinstance(currency, CurrencyBase):
            raise ValueError("currency must be a Currency object")
        return CRYPTO_TRUE == cryptoAmountHasCurrency(self._amount, currency._currency)

    def convert(self, to_unit: UnitBase) -> CryptoAmountBase:
        if not isinstance(to_unit, UnitBase):
            raise ValueError("to_unit must be a Unit object")
        obj = CryptoAmountBase()
        obj._amount = cryptoAmountConvertToUnit(self._amount, to_unit._unit)
        return obj

    def negate(self) -> CryptoAmountBase:
        obj = CryptoAmountBase()
        obj._amount = cryptoAmountNegate(self._amount)
        return obj

    def is_zero(self) -> bool:
        return CRYPTO_TRUE == cryptoAmountIsZero(self._amount)

    def __add__(self, other) -> CryptoAmountBase:
        if not self.is_compatible(other):
            raise ValueError("incompatible amount")
        obj = CryptoAmountBase()
        obj._amount = cryptoAmountAdd(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)
        return obj

    def __sub__(self, other) -> CryptoAmountBase:
        if not self.is_compatible(other):
            raise ValueError("incompatible amount")
        obj = CryptoAmountBase()
        obj._amount = cryptoAmountSub(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)
        return obj

    def __eq__(self, other):
        if not isinstance(other, CryptoAmountBase):
            return False
        return CRYPTO_COMPARE_EQ == cryptoAmountCompare(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)

    def __lt__(self, other):
        if not self.is_compatible(other):
            return False
        return CRYPTO_COMPARE_LT == cryptoAmountCompare(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)

    def __gt__(self, other):
        if not self.is_compatible(other):
            return False
        return CRYPTO_COMPARE_GT == cryptoAmountCompare(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)

    def __ne__(self, other):
        if not isinstance(other, CryptoAmountBase):
            return True
        return CRYPTO_COMPARE_EQ != cryptoAmountCompare(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)

    def __le__(self, other):
        if not self.is_compatible(other):
            return False
        return CRYPTO_COMPARE_GT != cryptoAmountCompare(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)

    def __gt__(self, other):
        if not self.is_compatible(other):
            return False
        return CRYPTO_COMPARE_LT != cryptoAmountCompare(<BRCryptoAmount>self._amount, <BRCryptoAmount>other._amount)

    def __str__(self):
        return self.format(self.unit)

    def __repr__(self):
        return f"<Amount: {self.format(self.unit)} unit={self.unit}>"

cdef class FeeBasisBase:
    cdef BRCryptoFeeBasis _fee_basis

    def __dealloc__(self):
        if self._fee_basis is not NULL:
            cryptoFeeBasisGive(self._fee_basis)

    @property
    def price_per_cost_factor(self) -> CryptoAmountBase:
        cdef BRCryptoAmount amount = cryptoFeeBasisGetPricePerCostFactor(self._fee_basis)
        obj = CryptoAmountBase()
        obj._amount = amount
        return obj

    @property
    def price_per_cost_factor_unit(self) -> UnitBase:
        cdef BRCryptoUnit unit = cryptoFeeBasisGetPricePerCostFactorUnit(self._fee_basis)
        obj = UnitBase()
        obj._unit = unit
        return obj

    @property
    def fee(self) -> CryptoAmountBase:
        cdef BRCryptoAmount amount = cryptoFeeBasisGetFee(self._fee_basis)
        obj = CryptoAmountBase()
        obj._amount = amount
        return obj

    def __repr__(self):
        return f"<FeeBasis: {self.price_per_cost_factor}/{self.price_per_cost_factor_unit}>"

cdef class CurrencyBase:
    cdef BRCryptoCurrency _currency

    def __dealloc__(self):
        if self._currency is not NULL:
            cryptoCurrencyGive(self._currency)

    @property
    def uids(self) -> str:
        return PyUnicode_FromString(cryptoCurrencyGetUids(self._currency))

    @property
    def name(self) -> str:
        return PyUnicode_FromString(cryptoCurrencyGetName(self._currency))

    @property
    def code(self) -> str:
        return PyUnicode_FromString(cryptoCurrencyGetCode(self._currency))

    @property
    def type(self) -> str:
        return PyUnicode_FromString(cryptoCurrencyGetType(self._currency))

    @property
    def issuer(self) -> Optional[str]:
        cdef const char * issuer = cryptoCurrencyGetIssuer(self._currency)
        if issuer == NULL:
            return None
        return PyUnicode_FromString(issuer)

    def __repr__(self):
        return f"<Currency: name={self.name} code={self.code}>"

cdef class AddressBase:
    cdef BRCryptoAddress _address

    def __str__(self):
        return PyUnicode_FromString(cryptoAddressAsString(self._address))


cdef class TransferBase:
    cdef BRCryptoTransfer _transfer
    cdef BRCryptoWallet _wallet

    def __dealloc__(self):
        if self._transfer != NULL:
            cryptoTransferGive(self._transfer)
        if self._wallet != NULL:
            cryptoWalletGive(self._wallet)

    @property
    def source_address(self):
        cdef BRCryptoAddress caddress = cryptoTransferGetSourceAddress(self._transfer)
        obj = AddressBase()
        obj._address = caddress
        return obj

    @property
    def target_address(self):
        cdef BRCryptoAddress caddress = cryptoTransferGetTargetAddress(self._transfer)
        obj = AddressBase()
        obj._address = caddress
        return obj

    @property
    def amount(self):
        cdef BRCryptoAmount camount = cryptoTransferGetAmount(self._transfer)
        obj = CryptoAmountBase()
        obj._amount = camount
        return obj

    def __str__(self):
        return f"{self.source_address}->{self.target_address} {self.amount}"


cdef class WalletBase:
    cdef BRCryptoWallet _wallet
    cdef BRCryptoWalletManager _manager

    def __dealloc__(self):
        if self._wallet is not NULL:
            cryptoWalletGive(self._wallet)
        if self._manager is not NULL:
            cryptoWalletManagerGive(self._manager)

    @property
    def currency(self) -> str:
        cdef BRCryptoCurrency currency = cryptoWalletGetCurrency(self._wallet)
        obj = CurrencyBase()
        obj._currency = currency
        return obj

    @property
    def balance(self) -> CryptoAmountBase:
        cdef BRCryptoAmount amount = cryptoWalletGetBalance(self._wallet)
        obj = CryptoAmountBase()
        obj._amount = amount
        return obj

    @property
    def default_fee_basis(self) -> FeeBasisBase:
        cdef BRCryptoFeeBasis basis = cryptoWalletGetDefaultFeeBasis(self._wallet)
        obj = FeeBasisBase()
        obj._fee_basis = basis
        return obj

    def address(self, scheme: AddressScheme) -> AddressBase:
        cdef BRCryptoAddress address = cryptoWalletGetAddress(self._wallet, scheme.value)
        obj = AddressBase()
        obj._address = address
        return obj

    @property
    def address_default_scheme(self):
        return self.address(AddressScheme.GEN_DEFAULT)

    def create_transfer(self, network: NetworkBase, address: AddressBase, amount: int, fee_basis: FeeBasisBase):
        cdef BRCryptoCurrency currency = cryptoNetworkGetCurrency(network._network)
        cdef BRCryptoUnit cunit = cryptoUnitGetBaseUnit(cryptoNetworkGetUnitAsDefault(network._network, currency))
        cdef uint64_t iamount = PyLong_AsLong(amount)
        cdef BRCryptoAmount camount = cryptoAmountCreateInteger(iamount, cunit)
        cdef BRCryptoFeeBasis cbasis = cryptoWalletGetDefaultFeeBasis(self._wallet)
        cdef BRCryptoTransfer ctransfer = cryptoWalletManagerCreateTransfer(
            self._manager, self._wallet, address._address, camount, cbasis, 0, NULL)  # returns NULL!
        obj = TransferBase()
        obj._transfer = ctransfer
        obj._wallet = cryptoWalletTake(self._wallet)
        return obj

    def __repr__(self):
        return f"<Wallet: currency={self.currency} address={self.address_default_scheme} default_fee_basis={self.default_fee_basis}>"

cdef class WalletManagerBase:
    cdef BRCryptoWalletManager _manager

    def __dealloc__(self):
        if self._manager is not NULL:
            cryptoWalletManagerGive(self._manager)

    cdef BRCryptoWalletManager native(self):
        return self._manager

    @property
    def network(self):
        cdef BRCryptoNetwork network = cryptoWalletManagerGetNetwork(self._manager)
        obj = NetworkBase()
        obj._network = network
        return obj

    def connect(self):
        cryptoWalletManagerConnect(self._manager, NULL)  # TODO: sometimes deadlocks

    def disconnect(self):
        cryptoWalletManagerDisconnect(self._manager)  # TODO: sometimes deadlocks

    def sync(self):
        cryptoWalletManagerSync(self._manager)  # TODO: sometimes deadlocks

    def stop(self):
        cryptoWalletManagerStop(self._manager)  # TODO: sometimes deadlocks

    def set_reachable(self, reachable: bool):  # TODO: sometimes deadlocks
        cryptoWalletManagerSetNetworkReachable(self._manager, CRYPTO_TRUE if reachable else CRYPTO_FALSE)

    def get_wallets(self) -> List[WalletBase]:
        cdef size_t wallet_count = 0
        cdef BRCryptoWallet *wallets = cryptoWalletManagerGetWallets(self._manager, &wallet_count)
        ret = []
        for i in range(wallet_count):
            obj = WalletBase()
            obj._wallet = wallets[i]
            obj._manager = cryptoWalletManagerTake(self._manager)
            ret.append(obj)
        return ret

    def submit(self, wallet: WalletBase, transfer: TransferBase, paper_key: str):
        cryptoWalletManagerSubmit(self._manager, wallet._wallet, transfer._transfer, PyUnicode_AsUTF8(paper_key))


class WalletManager:
    @staticmethod
    def create(account: AccountBase,
               network: NetworkBase,
               blockchain_client_factory: Callable[[], BlockchainClient],
               sync_mode: SyncMode,
               address_scheme: AddressScheme,
               storage_path: str,
               listener: WalletManagerListener = None) -> WalletManagerBase:
        cwml = CryptoWalletListener()
        cdef BRCryptoCWMListener cwml_native
        cwml_native.context = <BRCryptoCWMListenerContext> cwml
        Py_INCREF(cwml)
        cwml_native.walletManagerEventCallback = <BRCryptoCWMListenerWalletManagerEvent> cwml.wallet_manager_event_callback
        cwml_native.walletEventCallback = <BRCryptoCWMListenerWalletEvent> cwml.wallet_event_callback
        cwml_native.transferEventCallback = <BRCryptoCWMListenerTransferEvent> cwml.transfer_event_callback
        cwml._listener = cwml_native
        if listener is not None:
            cwml._state_listener = listener

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
        ccli._network_client_factory = blockchain_client_factory

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
