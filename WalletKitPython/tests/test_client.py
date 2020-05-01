import os
import unittest
import uuid
from asyncio import new_event_loop, set_event_loop
from walletkit.client import Blockset


class TestClient(unittest.TestCase):
    def setUp(self) -> None:
        self.email = os.getenv('BLOCKSET_EMAIL', None)
        self.password = os.getenv('BLOCKSET_PASSWORD', None)
        if self.email is None or self.password is None:
            raise ValueError("BLOCKSET_EMAIL and BLOCKSET_PASSWORD must be set in the environment")
        self.client = Blockset()
        self.event_loop = new_event_loop()
        set_event_loop(self.event_loop)
        self.account = self.event_loop.run_until_complete(self.client.create_or_login_account('Test User', self.email, self.password))
        clients = self.event_loop.run_until_complete(self.client.get_clients())
        for client in clients:
            self.event_loop.run_until_complete(self.client.delete_client(client.client_id))

    def test_get_account(self):
        account = self.event_loop.run_until_complete(self.client.get_account(self.account.account_id))
        self.assertEqual(self.account.account_id, account.account_id)

    def test_get_clients(self):
        clients = self.event_loop.run_until_complete(self.client.get_clients())
        self.assertEqual(0, len(clients))

    def test_create_client(self):
        cn = str(uuid.uuid4())
        client = self.event_loop.run_until_complete(self.client.create_client(cn))
        self.assertEqual(cn, client.name)

