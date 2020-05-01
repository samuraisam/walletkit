import asyncio
import os
import unittest
import uuid
import tempfile
import time
from typing import List
from walletkit import Network
from walletkit import Account
from walletkit import WalletManager, SyncMode, AddressScheme
from walletkit.model import BlockchainClient, RawTransaction
from walletkit import Hasher, HasherType
from walletkit.wordlists import english


class TestNetwork(unittest.TestCase):
    def test_install_builtins(self):
        networks = Network.install_builtins()
        self.assertTrue(len(networks) > 0)


class TestAccount(unittest.TestCase):
    def test_generate_phrase(self):
        phrase, ms_timestamp = Account.generate_phrase(english.words)
        split = phrase.split(' ')
        self.assertEqual(len(split), 12)
        for w in split:
            self.assertGreater(len(w), 1)

    def test_validate_phrase(self):
        phrase, _ = Account.generate_phrase(english.words)
        is_valid = Account.validate_phrase(phrase, english.words)
        self.assertTrue(is_valid)

    def test_create_from_phrase(self):
        uids = str(uuid.uuid4())
        phrase, ms_timestamp = Account.generate_phrase(english.words)
        account = Account.create_from_phrase(phrase, ms_timestamp, uids)
        self.assertIsNotNone(account)
        self.assertEqual(uids, account.uids)
        self.assertEqual(ms_timestamp, account.timestamp)
        self.assertIsNotNone(account.file_system_identifier)

    def test_account_serialize(self):
        phrase, ms_timestamp = Account.generate_phrase(english.words)
        account = Account.create_from_phrase(phrase, ms_timestamp, str(uuid.uuid4()))
        serialized = account.serialize()
        self.assertIsNotNone(serialized)
        self.assertTrue(len(serialized) > 2)

    def test_account_serialize_round_trip(self):
        phrase, ms_timestamp = Account.generate_phrase(english.words)
        account = Account.create_from_phrase(phrase, ms_timestamp, str(uuid.uuid4()))
        serialized = account.serialize()
        deserialized = Account.create_from_serialization(serialized, str(uuid.uuid4()))
        reserialized = deserialized.serialize()
        self.assertEqual(len(serialized), len(reserialized))

    def test_validate_serialization(self):
        phrase, ms_timestamp = Account.generate_phrase(english.words)
        account = Account.create_from_phrase(phrase, ms_timestamp, str(uuid.uuid4()))
        serialized = account.serialize()
        is_valid = account.validate_serialization(serialized)
        self.assertTrue(is_valid)


class TestHasher(unittest.TestCase):
    def test_do_hash(self):
        h = Hasher(HasherType.SHA256)
        v = h.hash('hello'.encode('utf8'))
        self.assertEqual(v.hex(), '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824')


class TestWalletManager(unittest.TestCase):
    @staticmethod
    def _get_temp_dir():
        temp_dir = os.path.join(tempfile.gettempdir(), str(uuid.uuid4()))
        os.makedirs(temp_dir, exist_ok=False)
        return temp_dir

    def test_create(self):
        class DummyBlockchainClient(BlockchainClient):
            async def get_block_height(self, blockchain_id: str) -> int:
                print(f"dummy blockchain client get_block_height(blockchain_id={blockchain_id})")
                await asyncio.sleep(.1)  # simulate network delay
                return 10

            async def get_raw_transactions(self, blockchain_id: str, addresses: List[str], currency: str,
                                           start_block_height: int, end_block_height: int) -> List[RawTransaction]:
                print(f"dummy blockchain client get_raw_transactions(\n"
                      f"  blockchain_id={blockchain_id}\n"
                      f"  addresses={len(addresses)}\n"
                      f"  currency={currency}\n"
                      f"  start_block_height={start_block_height}\n"
                      f"  end_block_height={end_block_height}\n"
                      f")")
                await asyncio.sleep(1)
                return []

        blockchain_client = DummyBlockchainClient()
        network = Network.install_builtins()[0]
        account = Account.generate(english.words)
        wallet_manager = WalletManager.create(account, network, blockchain_client, SyncMode.API_ONLY,
                                              AddressScheme.GEN_DEFAULT, TestWalletManager._get_temp_dir())
        self.assertIsNotNone(wallet_manager)
        wallet_manager.set_reachable(True)
        wallet_manager.sync()
        wallet_manager.connect()

        for i in range(10):
            print(f"tick {i}")
            time.sleep(1)

        wallet_manager.disconnect()
        wallet_manager.stop()

        print("done waiting")
