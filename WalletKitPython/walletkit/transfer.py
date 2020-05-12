from typing import Optional
from walletkit import native as n
from walletkit.currency import Amount, FeeBasis


class Transfer:
    _transfer: n.TransferBase

    @property
    def native(self) -> n.TransferBase:
        return self._transfer

    @native.setter
    def native(self, new_native: n.TransferBase):
        self._transfer = new_native

    @classmethod
    def from_native(cls, native_transfer: n.TransferBase) -> 'Transfer':
        c = cls()
        c._transfer = native_transfer
        return c

    @property
    def to_address(self) -> str:
        return str(self._transfer.target_address)

    @property
    def amount(self) -> Amount:
        return Amount.from_native(self._transfer.amount, self._transfer.amount.unit)

    @property
    def fee(self) -> Optional[FeeBasis]:
        fee = self._transfer.estimated_fee
        if fee is None:
            fee = self._transfer.confirmed_fee
        if fee is None:
            return None
        return FeeBasis.from_native(fee)

    def __str__(self):
        return f'{self.amount} -> {self.to_address}'
