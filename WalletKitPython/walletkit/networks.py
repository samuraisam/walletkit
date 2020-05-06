import logging
import os
import tempfile
import threading
from typing import Callable
from walletkit import native as n
from walletkit.blockchain_client import BlocksetBlockchainClient
from walletkit.client import Blockset
from walletkit.currency import Currency, Units
from walletkit.wallet import Wallet

logger = logging.getLogger('walletkit.networks.Network')

_was_imported = False
if not _was_imported:
    n.Network.install_builtins()
    _was_imported = True

_default_uuid = 'ca214746-acf9-4355-872a-2c9affe7755d'
_default_timestamp = 0


def _get_temp_dir(subpath: str = _default_uuid):
    temp_dir = os.path.join(tempfile.gettempdir(), subpath)
    os.makedirs(temp_dir, exist_ok=True)
    return temp_dir


def default_client_factory() -> Blockset:
    return Blockset()


class Network:
    _network: n.NetworkBase

    @property
    def native(self) -> n.NetworkBase:
        return self._network

    @native.setter
    def native(self, new_native: n.NetworkBase):
        self._network = new_native

    @property
    def height(self) -> int:
        return self._network.height()

    @height.setter
    def height(self, new_height: int):
        self._network.set_height(new_height)

    def __init__(self, network_name: str, token: str,
                 client_factory: Callable[[], Blockset] = default_client_factory):
        self._network_name = network_name
        self._network = n.Network.find_builtin(network_name)
        if token is None:
            token = os.getenv('BLOCKSET_TOKEN', None)
        if token is None:
            raise ValueError('Blockset token not provided to Network constructor, and not found in environment '
                             'variable BLOCKSET_TOKEN')
        self._blockset_token = token
        self._client_factory = client_factory
        self._thread_local = threading.local()

    def set_currency(self, currency: Currency, base_unit: Units, unit: Units):
        self._network.add_currency(currency.native, base_unit.native, unit.native)
        self._network.set_currency(currency.native)

    async def start(self):
        blockchain = await self._threadlocal_client_factory().get_blockchain(self._network_name)
        self._network.set_height(blockchain.block_height)

    async def wallet(self, phrase: str,
                     uids: str = _default_uuid,
                     timestamp: int = _default_timestamp,
                     storage_path: str = None) -> Wallet:
        if storage_path is None:
            storage_path = _get_temp_dir(uids)
        account = n.Account.create_from_phrase(phrase=phrase, timestamp=timestamp, uids=uids)
        wallet = Wallet()
        manager = n.WalletManager.create(
            account=account,
            network=self._network,
            blockchain_client_factory=self._threadlocal_blockchain_client_factory,
            sync_mode=n.SyncMode.API_ONLY,
            address_scheme=n.AddressScheme.GEN_DEFAULT,
            storage_path=storage_path,
            listener=wallet
        )
        wallet._manager = manager
        return wallet

    def _threadlocal_client_factory(self):
        val = getattr(self._thread_local, '_client', None)
        if val is None:
            val = self._client_factory()
            val.use_token(self._blockset_token)
            setattr(self._thread_local, '_client', val)
        return val

    def _threadlocal_blockchain_client_factory(self):
        val = getattr(self._thread_local, '_blockchain_client', None)
        if val is None:
            val = BlocksetBlockchainClient(self._threadlocal_client_factory())
            setattr(self._thread_local, '_blockchain_client', val)
        return val


class Bitcoin(Network):
    _currency = Currency(name='bitcoin', code='btc', type='native', issuer='')
    SAT = _currency.create_base_unit(code='sat', name='satoshi', symbol='SAT')
    BTC = _currency.create_unit(code='btc', name='bitcoin', symbol='B', base=SAT, decimals=8)

    @staticmethod
    def mainnet(token: str = None):
        network = Bitcoin('bitcoin-mainnet', token=token)
        network.set_currency(Bitcoin._currency, Bitcoin.SAT, Bitcoin.BTC)
        return network

    @staticmethod
    def testnet(token: str = None):
        network = Bitcoin('bitcoin-testnet', token=token)
        network.set_currency(Bitcoin._currency, Bitcoin.SAT, Bitcoin.BTC)
        return network
