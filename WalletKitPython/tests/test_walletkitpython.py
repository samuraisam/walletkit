import asyncio
import os
import unittest
import uuid
import tempfile
import threading
import time
from asyncio import get_event_loop
from typing import List
from walletkit import Network
from walletkit import Account
from walletkit import WalletManager, SyncMode, AddressScheme
from walletkit import client
from walletkit.blockchain_client import BlocksetBlockchainClient
from walletkit.model import WalletManagerListener, TransferEvent, WalletEvents, WalletManagerEvents
from walletkit.model import WalletManagerEventType
from walletkit import Hasher, HasherType
from walletkit.wordlists import english


# class TestNetwork(unittest.TestCase):
#     def test_install_builtins(self):
#         networks = Network.install_builtins()
#         self.assertTrue(len(networks) > 0)
#
#
# class TestAccount(unittest.TestCase):
#     def test_generate_phrase(self):
#         phrase, ms_timestamp = Account.generate_phrase(english.words)
#         split = phrase.split(' ')
#         self.assertEqual(len(split), 12)
#         for w in split:
#             self.assertGreater(len(w), 1)
#
#     def test_validate_phrase(self):
#         phrase, _ = Account.generate_phrase(english.words)
#         is_valid = Account.validate_phrase(phrase, english.words)
#         self.assertTrue(is_valid)
#
#     def test_create_from_phrase(self):
#         uids = str(uuid.uuid4())
#         phrase, ms_timestamp = Account.generate_phrase(english.words)
#         account = Account.create_from_phrase(phrase, ms_timestamp, uids)
#         self.assertIsNotNone(account)
#         self.assertEqual(uids, account.uids)
#         self.assertEqual(ms_timestamp, account.timestamp)
#         self.assertIsNotNone(account.file_system_identifier)
#
#     def test_account_serialize(self):
#         phrase, ms_timestamp = Account.generate_phrase(english.words)
#         account = Account.create_from_phrase(phrase, ms_timestamp, str(uuid.uuid4()))
#         serialized = account.serialize()
#         self.assertIsNotNone(serialized)
#         self.assertTrue(len(serialized) > 2)
#
#     def test_account_serialize_round_trip(self):
#         phrase, ms_timestamp = Account.generate_phrase(english.words)
#         account = Account.create_from_phrase(phrase, ms_timestamp, str(uuid.uuid4()))
#         serialized = account.serialize()
#         deserialized = Account.create_from_serialization(serialized, str(uuid.uuid4()))
#         reserialized = deserialized.serialize()
#         self.assertEqual(len(serialized), len(reserialized))
#
#     def test_validate_serialization(self):
#         phrase, ms_timestamp = Account.generate_phrase(english.words)
#         account = Account.create_from_phrase(phrase, ms_timestamp, str(uuid.uuid4()))
#         serialized = account.serialize()
#         is_valid = account.validate_serialization(serialized)
#         self.assertTrue(is_valid)
#
#
# class TestHasher(unittest.TestCase):
#     def test_do_hash(self):
#         h = Hasher(HasherType.SHA256)
#         v = h.hash('hello'.encode('utf8'))
#         self.assertEqual(v.hex(), '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824')
#


class EventAccumulatingListener(WalletManagerListener):
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

    def read_wallet_manager_events(self) -> List[WalletManagerEvents]:
        ret = self.wallet_manager_events
        self.wallet_manager_events = []
        return ret

    def was_stopped(self):
        for event in self.wallet_manager_events:
            if event.type == WalletManagerEventType.SYNC_STOPPED:
                return True
        return False


class TestWalletManager(unittest.TestCase):
    account: client.Account

    @classmethod
    def setUpClass(cls) -> None:
        cls.email = os.getenv('BLOCKSET_EMAIL', None)
        cls.password = os.getenv('BLOCKSET_PASSWORD', None)
        if cls.email is None or cls.password is None:
            raise ValueError("BLOCKSET_EMAIL and BLOCKSET_PASSWORD must be set in the environment")
        cls.account = get_event_loop().run_until_complete(
            client.Blockset().create_or_login_account('Test User', cls.email, cls.password))

    def setUp(self) -> None:
        blockset = client.Blockset()
        blockset.token = TestWalletManager.account.token
        self.event_loop = get_event_loop()
        clients = self.event_loop.run_until_complete(blockset.get_clients())
        if not len(clients):
            clients = [self.event_loop.run_until_complete(blockset.create_client('WalletTest'))]
        self.client = clients[0]
        self.thread_local = threading.local()

    def blockset_blockchain_client_factory(self):
        val = getattr(self.thread_local, '_blockset_client', None)
        if val is None:
            blockset = client.Blockset(logging_enabled=False)
            blockset.use_token(self.client.token)
            val = BlocksetBlockchainClient(blockset)
            setattr(self.thread_local, '_blockset_client', val)
        return val

    @staticmethod
    def _get_temp_dir():
        temp_dir = os.path.join(tempfile.gettempdir(), str(uuid.uuid4()))
        os.makedirs(temp_dir, exist_ok=False)
        return temp_dir

    def test_create(self):
        network = Network.find_builtin('bitcoin-testnet')
        phrase_from_env = os.getenv('WALLETKIT_PHRASE')
        if phrase_from_env is not None:
            print('using phrase from environment')
            timestamp = 1588319433
            uids = '3655ed8c-98b3-45ba-be66-d2e7682e2e63'
            account = Account.create_from_phrase(phrase_from_env, timestamp, uids)
        else:
            print('generating new phrase')
            account = Account.generate(english.words)
        listener = EventAccumulatingListener()
        wallet_manager = WalletManager.create(account=account, network=network,
                                              blockchain_client_factory=self.blockset_blockchain_client_factory,
                                              sync_mode=SyncMode.API_ONLY, address_scheme=AddressScheme.GEN_DEFAULT,
                                              storage_path=TestWalletManager._get_temp_dir(),
                                              listener=listener)
        self.assertIsNotNone(wallet_manager)
        wallet_manager.set_reachable(True)
        wallet_manager.sync()
        wallet_manager.connect()

        for i in range(100):
            was_stopped = listener.was_stopped()
            events = listener.read_wallet_manager_events()
            print(f"events={events}")
            if was_stopped:
                break
            time.sleep(1)

        wallets = wallet_manager.get_wallets()
        self.assertTrue(len(wallets) > 0)
        print(f"wallets: {wallets}")
        for wallet in wallets:
            print(f"wallet {wallet.currency.code} balance={wallet.balance.int_value}")

        wallet_manager.disconnect()
        wallet_manager.stop()

        print("done waiting")
