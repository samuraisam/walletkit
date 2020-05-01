from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List


@dataclass
class RawTransaction:
    status: str
    timestamp: int
    block_height: int
    data: bytes


class BlockchainClient(ABC):
    @abstractmethod
    async def get_block_height(self, blockchain_id: str) -> int:
        pass

    @abstractmethod
    async def get_raw_transactions(self, blockchain_id: str, addresses: List[str], currency: str,
                                   start_block_height: int, end_block_height: int) -> List[RawTransaction]:
        pass
