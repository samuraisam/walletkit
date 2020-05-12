from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List, Optional, Union
from enum import Enum


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


class WalletManagerEventType(Enum):
    CREATED = 0
    CHANGED = 1
    DELETED = 2
    WALLET_ADDED = 3
    WALLET_CHANGED = 4
    WALLET_DELETED = 5
    SYNC_STARTED = 6
    SYNC_CONTINUES = 7
    SYNC_STOPPED = 8
    SYNC_RECOMMENDED = 9
    BLOCK_HEIGHT_UPDATED = 10


@dataclass
class WalletManagerEvent:
    type: WalletManagerEventType


@dataclass
class WalletManagerStateEvent(WalletManagerEvent):
    pass  # TODO: state ...


@dataclass
class WalletManagerWalletEvent(WalletManagerEvent):
    pass  # TODO: wallet ...


class WalletManagerSyncStoppedReason(Enum):
    COMPLETE = 0
    REQUESTED = 1
    UNKNOWN = 2
    POSIX = 4


@dataclass
class WalletManagerSyncEvent(WalletManagerEvent):
    timestamp: Optional[int] = None
    percent_complete: Optional[float] = None
    reason: Optional[WalletManagerSyncStoppedReason] = None
    depth: Optional[int] = None


@dataclass
class WalletManagerBlockHeightEvent(WalletManagerEvent):
    height: int


WalletManagerEvents = Union[WalletManagerStateEvent, WalletManagerWalletEvent,
                            WalletManagerSyncEvent, WalletManagerBlockHeightEvent]


class WalletEventType(Enum):
    CREATED = 0
    CHANGED = 1
    DELETED = 3
    TRANSFER_ADDED = 4
    TRANSFER_CHANGED = 5
    TRANSFER_SUBMITTED = 6
    TRANSFER_DELETED = 7
    BALANCE_UPDATED = 8
    FEE_BASIS_UPDATED = 9
    FEE_BASIS_ESTIMATED = 10


@dataclass
class WalletEvent:
    type: WalletManagerEventType


@dataclass
class WalletStateEvent(WalletEvent):
    pass  # TODO: new/old state...


@dataclass
class WalletTransferEvent(WalletEvent):
    pass  # TODO: value...


@dataclass
class WalletBalanceEvent(WalletEvent):
    pass  # TODO: amount...


@dataclass
class WalletFeeBasisUpdatedEvent(WalletEvent):
    pass  # TODO: basis...


@dataclass
class WalletFeeBasisEstimated(WalletEvent):
    pass  # TODO: status/cookie/basis...


WalletEvents = Union[WalletStateEvent, WalletTransferEvent, WalletBalanceEvent,
                     WalletFeeBasisUpdatedEvent, WalletFeeBasisEstimated]


class TransferEventType(Enum):
    CREATED = 0
    CHANGED = 1
    DELETED = 2


@dataclass
class TransferEvent:
    type: TransferEventType
    # TODO: state.old/state.new...


class WalletManagerListener(ABC):
    @abstractmethod
    def received_wallet_manager_event(self, event: WalletManagerEvents):
        pass

    @abstractmethod
    def received_wallet_event(self, event: WalletEvents):
        pass

    @abstractmethod
    def received_transfer_event(self, event: TransferEvent):
        pass
