import asyncio
from typing import List, Tuple
from walletkit import native as n
from walletkit.amount import Amount
from walletkit.currency import Units
from walletkit.model import WalletManagerListener, WalletManagerEvents, WalletEvents, TransferEvent


class Wallet(WalletManagerListener):
    _manager: n.WalletManagerBase
    wallet_manager_events: List[WalletManagerEvents]
    wallet_events: List[WalletEvents]
    transfer_events: List[TransferEvent]

    @property
    def native(self) -> n.WalletManagerBase:
        return self._manager

    @native.setter
    def native(self, new_wallet_manager: n.WalletManagerBase):
        self._manager = new_wallet_manager

    def __init__(self):
        self.wallet_manager_events = []
        self.wallet_events = []
        self.transfer_events = []

    def received_wallet_manager_event(self, event: WalletManagerEvents):
        self.wallet_manager_events.append(event)

    def received_wallet_event(self, event: WalletEvents):
        self.wallet_events.append(event)

    def received_transfer_event(self, event: TransferEvent):
        self.transfer_events.append(event)

    def _clear_events(self) -> Tuple[List[WalletManagerEvents], List[WalletEvents], List[TransferEvent]]:
        wme, we, te = (self.wallet_manager_events.copy(), self.wallet_events.copy(), self.transfer_events.copy())
        self.wallet_manager_events = []
        self.wallet_events = []
        self.transfer_events = []
        return wme, we, te

    def _was_stopped(self):
        for event in self.wallet_manager_events:
            if event.type == n.WalletManagerEventType.SYNC_STOPPED:
                return True
        return False

    def balance(self, unit: Units) -> Amount:
        wallet = self._manager.get_wallet_for_currency(unit.native.currency)
        return Amount.from_native(wallet.balance, unit.native)

    async def sync(self) -> Tuple[List[WalletManagerEvents], List[WalletEvents], List[TransferEvent]]:
        await asyncio.sleep(0.1)
        self._manager.sync()
        await asyncio.sleep(0.1)
        self._manager.connect()

        while not self._was_stopped():
            await asyncio.sleep(0.1)

        return self._clear_events()
