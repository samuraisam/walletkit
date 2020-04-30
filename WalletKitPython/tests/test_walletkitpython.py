import unittest
import uuid
from walletkit import Hasher, HasherType
from walletkit import Account
from walletkit.wordlists import english


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
        phrase, ms_timestamp = Account.generate_phrase(english.words)
        account = Account.create_from_phrase(phrase, ms_timestamp, str(uuid.uuid4()))
        self.assertIsNotNone(account)

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


class TestHasher(unittest.TestCase):
    def test_do_hash(self):
        h = Hasher(HasherType.SHA256)
        v = h.hash('hello'.encode('utf8'))
        self.assertEqual(v.hex(), '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824')
