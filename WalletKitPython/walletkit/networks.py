import asyncio
import logging
import os
import tempfile
import threading
from typing import Callable, Tuple, List
from .blockchain_client import BlocksetBlockchainClient
from .client import Blockset
from .model import WalletManagerListener, TransferEvent, WalletEvents, WalletManagerEvents
import native

logger = logging.getLogger('walletkit.networks.Network')

_was_imported = False
if not _was_imported:
    native.Network.install_builtins()
    _was_imported = True

_default_uuid = 'ca214746-acf9-4355-872a-2c9affe7755d'
_default_timestamp = 0


def _get_temp_dir(subpath: str = _default_uuid):
    temp_dir = os.path.join(tempfile.gettempdir(), subpath)
    os.makedirs(temp_dir, exist_ok=True)
    return temp_dir


def default_client_factory() -> Blockset:
    return Blockset()


class Wallet(WalletManagerListener):
    _manager: native.WalletManagerBase
    wallet_manager_events: List[WalletManagerEvents]
    wallet_events: List[WalletEvents]
    transfer_events: List[TransferEvent]

    def __init__(self):
        self.wallet_manager_events = []
        self.wallet_events = []
        self.transfer_events = []

    def received_wallet_manager_event(self, event: WalletManagerEvents):
        self.wallet_manager_events.append(event)

    def received_wallet_event(self, event: WalletEvents):
        self.wallet_events.append(event)

    def received_transfer_event(self, event: TransferEvent):
        self.transfer_events.append(event)

    def _clear_events(self) -> Tuple[List[WalletManagerEvents], List[WalletEvents], List[TransferEvent]]:
        wme, we, te = (self.wallet_manager_events.copy(), self.wallet_events.copy(), self.transfer_events.copy())
        self.wallet_manager_events = []
        self.wallet_events = []
        self.transfer_events = []
        return wme, we, te

    def _was_stopped(self):
        for event in self.wallet_manager_events:
            if event.type == native.WalletManagerEventType.SYNC_STOPPED:
                return True
        return False

    async def sync(self) -> Tuple[List[WalletManagerEvents], List[WalletEvents], List[TransferEvent]]:
        await asyncio.sleep(0.1)
        self._manager.sync()
        await asyncio.sleep(0.1)
        self._manager.connect()

        while not self._was_stopped():
            await asyncio.sleep(0.1)

        return self._clear_events()


class Network:
    def __init__(self, network_name: str, token: str,
                 client_factory: Callable[[], Blockset] = default_client_factory):
        self._network_name = network_name
        self._network = native.Network.find_builtin(network_name)
        if token is None:
            token = os.getenv('BLOCKSET_TOKEN', None)
        if token is None:
            raise ValueError('Blockset token not provided to Network constructor, and not found in environment '
                             'variable BLOCKSET_TOKEN')
        self._blockset_token = token
        self._client_factory = client_factory
        self._thread_local = threading.local()

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

    async def start(self):
        blockchain = await self._threadlocal_client_factory().get_blockchain(self._network_name)
        self._network.height = blockchain.block_height

    async def wallet(self, phrase: str,
                     uids: str = _default_uuid,
                     timestamp: int = _default_timestamp,
                     storage_path: str = None) -> Wallet:
        if storage_path is None:
            storage_path = _get_temp_dir(uids)
        account = native.Account.create_from_phrase(phrase=phrase, timestamp=timestamp, uids=uids)
        wallet = Wallet()
        manager = native.WalletManager.create(
            account=account,
            network=self._network,
            blockchain_client_factory=self._threadlocal_blockchain_client_factory,
            sync_mode=native.SyncMode.API_ONLY,
            address_scheme=native.AddressScheme.GEN_DEFAULT,
            storage_path=storage_path,
            listener=wallet
        )
        wallet._manager = manager
        return wallet


class Bitcoin:
    _currency = native.Currency.create('bitcoin', code='btc', type='native')
    SAT = native.Unit.create_base(_currency, code='sat', name='satoshi', symbol='SAT')
    BTC = native.Unit.create(_currency, code='bitcoin', name='bitcoin', symbol='B', base=SAT, decimals=8)

    @staticmethod
    def mainnet(token: str = None):
        return Network('bitcoin-mainnet', token=token)

    @staticmethod
    def testnet(token: str = None):
        return Network('bitcoin-testnet', token=token)
