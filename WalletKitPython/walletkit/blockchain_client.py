import asyncio
import traceback
from base64 import b64decode
from functools import wraps
from typing import List
from .client import Blockset
from .model import BlockchainClient, RawTransaction


def error_reporter(async_func):
    @wraps(async_func)
    async def error_reporting(*args, **kwargs):
        try:
            return await async_func(*args, **kwargs)
        except Exception as e:
            print(f"[BlocksetBlockchainClient] ERROR IN ASYNC FUNCTION {e}")
            traceback.print_exc()
            raise e

    return error_reporting


class BlocksetBlockchainClient(BlockchainClient):
    def __init__(self, blockset_client: Blockset, enable_logging=True):
        self.blockset = blockset_client
        self.enable_logging = enable_logging

    @error_reporter
    async def get_block_height(self, blockchain_id: str) -> int:
        self.log(f"get_block_height blockchain_id={blockchain_id}")
        blockchain = await self.blockset.get_blockchain(blockchain_id)
        self.log(f"get_block_height completed blockchain_id={blockchain_id} block_height={blockchain.block_height}")
        return blockchain.block_height

    @error_reporter
    async def get_raw_transactions(self, blockchain_id: str, addresses: List[str], currency: str,
                                   start_block_height: int, end_block_height: int) -> List[RawTransaction]:
        self.log(f"get_raw_transactions blockchain_id={blockchain_id} addresses={len(addresses)} "
                 f"start={start_block_height} end={end_block_height}")
        # split into one kb buckets of addresses
        cur_bucket_size = 0
        buckets = [[]]
        for addr in addresses:
            self.log(f"cur_bucket_size {cur_bucket_size}")
            cur_bucket_size += len(addr)
            if cur_bucket_size > 1500:
                buckets.append([])
                cur_bucket_size = 0
            buckets[-1].append(addr)
        # fetch each bucket
        bucket_lens = [len(b) for b in buckets]
        self.log(f"get_raw_transactions making {bucket_lens} requests")
        transactions = []
        for bucket in buckets:
            transactions_page = await self.blockset.get_transactions(blockchain_id, addresses=bucket,
                                                                     start_height=start_block_height,
                                                                     end_height=end_block_height, include_raw=True)
            transactions.extend([RawTransaction(status=t.status, timestamp=t.timestamp,
                                                block_height=t.block_height, data=b64decode(t.raw))
                                 for t in transactions_page.transactions])
        self.log(f"get_raw_transactions finished blockchain_id={blockchain_id} "
                 f"tx_count={len(transactions)}")
        return transactions

    def log(self, s):
        if self.enable_logging:
            print(f"[BlocksetBlockchainClient] {s}")
