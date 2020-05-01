import os
import unittest
import uuid
from asyncio import sleep, get_event_loop, new_event_loop, set_event_loop
from walletkit.client import Blockset, Account


# class TestClient(unittest.TestCase):
#     account: Account
#
#     @classmethod
#     def setUpClass(cls) -> None:
#         cls.email = os.getenv('BLOCKSET_EMAIL', None)
#         cls.password = os.getenv('BLOCKSET_PASSWORD', None)
#         if cls.email is None or cls.password is None:
#             raise ValueError("BLOCKSET_EMAIL and BLOCKSET_PASSWORD must be set in the environment")
#         cls.account = get_event_loop().run_until_complete(
#             Blockset().create_or_login_account('Test User', cls.email, cls.password))
#
#     def setUp(self) -> None:
#         self.client = Blockset()
#         self.event_loop = get_event_loop()
#         self.account = TestClient.account
#         self.client.token = self.account.token
#         clients = self.event_loop.run_until_complete(self.client.get_clients())
#         for client in clients:
#             self.event_loop.run_until_complete(self.client.delete_client(client.client_id))
#
#     def test_get_account(self):
#         account = self.event_loop.run_until_complete(self.client.get_account(self.account.account_id))
#         self.assertEqual(self.account.account_id, account.account_id)
#
#     def test_get_clients_empty(self):
#         clients = self.event_loop.run_until_complete(self.client.get_clients())
#         self.assertEqual(0, len(clients))
#
#     def test_create_client(self):
#         cn = str(uuid.uuid4())
#         client = self.event_loop.run_until_complete(self.client.create_client(cn))
#         self.assertEqual(cn, client.name)
#
#     def test_get_blockchains(self):
#         client = self.event_loop.run_until_complete(self.client.create_client(str(uuid.uuid4())))
#         self.client.token = client.token
#         blockchains = self.event_loop.run_until_complete(self.client.get_blockchains())
#         self.assertTrue(len(blockchains) > 0)
#
#     def test_get_single_blockchain(self):
#         client = self.event_loop.run_until_complete(self.client.create_client(str(uuid.uuid4())))
#         self.client.token = client.token
#         blockchain = self.event_loop.run_until_complete(self.client.get_blockchain('bitcoin-mainnet'))
#         self.assertIsNotNone(blockchain)
#
#     def test_get_transactions(self):
#         client = self.event_loop.run_until_complete(self.client.create_client(str(uuid.uuid4())))
#         self.client.token = client.token
#         transactions_page = self.event_loop.run_until_complete(
#             self.client.get_transactions(blockchain_id='bitcoin-mainnet', max_page_size=20))
#         self.assertIsNotNone(transactions_page)
#         self.assertEqual(20, len(transactions_page.transactions))
#
#     def test_get_transactions_empty_page(self):
#         client = self.event_loop.run_until_complete(self.client.create_client(str(uuid.uuid4())))
#         self.client.token = client.token
#         transactions_page = self.event_loop.run_until_complete(
#             self.client.get_transactions(blockchain_id='bitcoin-mainnet', addresses=['a'], max_page_size=20))
#         self.assertIsNotNone(transactions_page)
#         self.assertEqual(0, len(transactions_page.transactions))
#
#     def test_get_transactions_raw_and_proof(self):
#         client = self.event_loop.run_until_complete(self.client.create_client(str(uuid.uuid4())))
#         self.client.token = client.token
#         transactions_page = self.event_loop.run_until_complete(
#             self.client.get_transactions(blockchain_id='bitcoin-mainnet', include_raw=True, include_proof=True,
#                                          max_page_size=20))
#         self.assertIsNotNone(transactions_page)
#         self.assertEqual(20, len(transactions_page.transactions))
#         for t in transactions_page.transactions:
#             self.assertIsNotNone(t.raw)
#             self.assertIsNotNone(t.proof)
