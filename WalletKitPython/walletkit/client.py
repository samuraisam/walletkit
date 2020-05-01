# implement general blockset client using previous art (from blockchain-db repo)
# implement BlockchainClient

import httpx
from typing import Mapping, List, Optional
from dataclasses import dataclass
from typed_json_dataclass import TypedJsonMixin


class BlocksetError(BaseException):
    def __init__(self, response: httpx.Response):
        self.data = response.json()
        self.response = response

    def __str__(self):
        return f'{self.response.status_code} data={self.data}'


def raise_error(response: httpx.Response):
    if response.status_code > 399:
        raise BlocksetError(response)


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


class Blockset:
    def __init__(self, endpoint='https://api.blockset.com'):
        self.endpoint = endpoint
        self.http = httpx.AsyncClient()
        self.token = None

    def use_token(self, token: str):
        self.token = token

    def _headers(self, token=None, accept='application/json'):
        if token is None and self.token is None:
            raise ValueError('No token configured for Blockset client')
        return {
            'authorization': f'Bearer {token if token else self.token}',
            'accept': accept,
        }

    async def create_account(self, name, email, password) -> Account:
        resp = await self.http.post(self.endpoint + '/accounts',
                                    json={'name': name, 'email': email, 'password': password})
        raise_error(resp)
        return Account.from_dict(resp.json())

    async def login(self, email, password) -> Account:
        resp = await self.http.post(self.endpoint + '/accounts/login',
                                    json={'email': email, 'password': password})
        raise_error(resp)
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
        raise_error(resp)
        return Account.from_dict(resp.json())

    async def get_clients(self, account_token=None) -> List[Client]:
        resp = await self.http.get(self.endpoint + '/clients',
                                   headers=self._headers(account_token))
        raise_error(resp)
        json = resp.json()
        if '_embedded' not in json:
            return []
        return [Client.from_dict(c) for c in json['_embedded']['clients']]

    async def create_client(self, client_name, account_token=None) -> Client:
        resp = await self.http.post(self.endpoint + '/clients', json={'name': client_name},
                                    headers=self._headers(account_token))
        raise_error(resp)
        return Client.from_dict(resp.json())

    async def delete_client(self, client_id, account_token=None):
        resp = await self.http.delete(self.endpoint + '/clients/' + client_id,
                                      headers=self._headers(account_token))
        raise_error(resp)
