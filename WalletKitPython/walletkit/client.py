import logging
from typing import Mapping, List, Optional
from dataclasses import dataclass
import httpx
from typed_json_dataclass import TypedJsonMixin
from tenacity import retry, stop_after_attempt, wait_random_exponential, retry_if_exception_type, before_sleep_log


class BlocksetError(BaseException):
    def __init__(self, response: httpx.Response):
        self.data = response.text
        self.response = response

    def __str__(self):
        return f'{self.response.status_code} data={self.data}'


logger = logging.getLogger(__name__)
default_retry = retry(wait=wait_random_exponential(1, max=5),
                      stop=stop_after_attempt(5),
                      retry=retry_if_exception_type(BlocksetError))
                      # before_sleep=before_sleep_log(logger, logging.WARN))


@dataclass
class Link(TypedJsonMixin):
    href: str


@dataclass
class Client(TypedJsonMixin):
    account_id: str
    client_id: str
    name: str
    token: str
    created: str
    updated: str
    _links: Mapping[str, Link]


@dataclass
class Account(TypedJsonMixin):
    account_id: str
    email: str
    name: str
    _links: Mapping[str, Link]
    token: Optional[str] = None


@dataclass
class Amount(TypedJsonMixin):
    amount: str
    currency_id: str


@dataclass
class FeeEstimate(TypedJsonMixin):
    estimated_confirmation_in: int
    fee: Amount
    tier: str


@dataclass
class Blockchain(TypedJsonMixin):
    id: str
    is_mainnet: bool
    name: str
    native_currency_id: str
    network: str
    block_height: int
    confirmations_until_final: int
    fee_estimates: List[FeeEstimate]
    _links: Mapping[str, Link]


@dataclass
class Transfer(TypedJsonMixin):
    acknowledgements: int
    amount: Amount
    blockchain_id: str
    from_address: str
    to_address: str
    index: int
    meta: Mapping[str, str]
    transaction_id: str
    transfer_id: str
    _links: Mapping[str, Link]


@dataclass
class Call(TypedJsonMixin):
    pass


@dataclass
class Transaction(TypedJsonMixin):
    transaction_id: str
    identifier: str
    hash: str
    blockchain_id: str
    timestamp: str
    size: int
    fee: Amount
    confirmations: int
    index: int
    block_hash: str
    block_height: int
    calls: List[Call]
    meta: Mapping[str, str]
    acknowledgements: int
    status: str
    _embedded: Mapping[str, List[Transfer]]
    _links: Mapping[str, Link]
    raw: Optional[str] = None
    proof: Optional[str] = None


@dataclass
class TransactionsPageContent(TypedJsonMixin):
    transactions: List[Transaction]


@dataclass
class TransactionsPage(TypedJsonMixin):
    _links: Mapping[str, Link]
    _embedded: TransactionsPageContent

    @property
    def transactions(self):
        if self._embedded is None:
            return []
        return self._embedded.transactions


class Blockset:
    def __init__(self, endpoint='https://api.blockset.com', logging_enabled=False):
        self.endpoint = endpoint
        self.http = httpx.AsyncClient()
        self.token = None
        self.logging_enabled = logging_enabled

    def use_token(self, token: str):
        self.token = token

    def _headers(self, token=None, accept='application/json'):
        if token is None and self.token is None:
            raise ValueError('No token configured for Blockset client')
        return {
            'authorization': f'Bearer {token if token else self.token}',
            'accept': accept,
        }

    def _raise_error(self, response: httpx.Response):
        if response.status_code > 399:
            self._log(f"ERROR: bad status code {response.status_code} {response.text}")
            raise BlocksetError(response)

    def _log(self, s):
        if self.logging_enabled:
            print(f"[BlocksetHttpClient] {s}")

    async def create_account(self, name, email, password) -> Account:
        resp = await self.http.post(self.endpoint + '/accounts',
                                    json={'name': name, 'email': email, 'password': password})
        self._raise_error(resp)
        return Account.from_dict(resp.json())

    async def login(self, email, password) -> Account:
        resp = await self.http.post(self.endpoint + '/accounts/login',
                                    json={'email': email, 'password': password})
        self._raise_error(resp)
        account = Account.from_dict(resp.json())
        self.token = account.token
        return account

    async def create_or_login_account(self, name, email, password) -> Account:
        try:
            account = await self.create_account(name, email, password)
            self.token = account.token
        except BlocksetError:
            account = await self.login(email, password)
            self.token = account.token
        return account

    async def get_account(self, account_id, account_token=None) -> Account:
        resp = await self.http.get(self.endpoint + f'/accounts/{account_id}',
                                   headers=self._headers(account_token))
        self._raise_error(resp)
        return Account.from_dict(resp.json())

    async def get_clients(self, account_token=None) -> List[Client]:
        resp = await self.http.get(self.endpoint + '/clients',
                                   headers=self._headers(account_token))
        self._raise_error(resp)
        json = resp.json()
        if '_embedded' not in json:
            return []
        return [Client.from_dict(c) for c in json['_embedded']['clients']]

    async def create_client(self, client_name, account_token=None) -> Client:
        resp = await self.http.post(self.endpoint + '/clients', json={'name': client_name},
                                    headers=self._headers(account_token))
        self._raise_error(resp)
        return Client.from_dict(resp.json())

    async def delete_client(self, client_id, account_token=None):
        resp = await self.http.delete(self.endpoint + '/clients/' + client_id,
                                      headers=self._headers(account_token))
        self._raise_error(resp)

    @default_retry
    async def get_blockchains(self, testnet=False, token=None) -> List[Blockchain]:
        resp = await self.http.get(self.endpoint + '/blockchains', params={'testnet': testnet},
                                   headers=self._headers(token))
        self._raise_error(resp)
        json = resp.json()
        if '_embedded' not in json:
            return []
        return [Blockchain.from_dict(b) for b in json['_embedded']['blockchains']]

    @default_retry
    async def get_blockchain(self, blockchain_id, token=None) -> Blockchain:
        resp = await self.http.get(self.endpoint + f'/blockchains/{blockchain_id}',
                                   headers=self._headers(token))
        self._raise_error(resp)
        return Blockchain.from_dict(resp.json())

    @default_retry
    async def get_transactions(self, blockchain_id, addresses: List[str] = None, start_height=None, end_height=None,
                               start_timestamp=None, end_timestamp=None, max_page_size=None, include_proof=False,
                               include_raw=False, token=None) -> TransactionsPage:
        args = {
            'blockchain_id': blockchain_id,
            'address': addresses,
            'start_height': start_height,
            'end_height': end_height,
            'start_ts': start_timestamp,
            'end_ts': end_timestamp,
            'max_page_size': max_page_size,
        }
        if include_raw:
            args['include_raw'] = True
        if include_proof:
            args['include_proof'] = True
        args = {k: v for k, v in args.items() if v is not None}
        resp = await self.http.get(self.endpoint + '/transactions', params=args,
                                   headers=self._headers(token))
        self._log(f"GET {resp.url}")
        self._raise_error(resp)
        json = resp.json()
        if '_embedded' not in json:
            return TransactionsPage(_links=json['_links'], _embedded=TransactionsPageContent([]))
        return TransactionsPage.from_dict(resp.json())
