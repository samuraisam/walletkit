from abc import ABC, abstractmethod
from typing import List


class RawTransaction(ABC):
    @property
    @abstractmethod
    def status(self) -> str:
        pass

    @property
    @abstractmethod
    def timestamp(self) -> str:
        pass

    @property
    @abstractmethod
    def block_height(self) -> int:
        pass

    @property
    @abstractmethod
    def data(self) -> bytes:
        pass


class BlockchainClient(ABC):
    @abstractmethod
    async def get_block_height(self, blockchain_id: str) -> int:
        pass

    @abstractmethod
    async def get_raw_transactions(self, blockchain_id: str, addresses: List[str], currency: str,
                                   start_block_height: int, end_block_height: int) -> List[RawTransaction]:
        pass
