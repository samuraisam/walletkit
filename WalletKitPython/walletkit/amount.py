from babel.numbers import format_currency
from walletkit import native as n


class Amount:
    _amount: n.AmountBase
    _unit: n.UnitBase

    @property
    def native(self) -> n.AmountBase:
        return self._amount

    @native.setter
    def native(self, new_amount: n.AmountBase):
        self._amount = new_amount

    @classmethod
    def from_native(cls, amt: n.AmountBase, unit: n.UnitBase) -> 'Amount':
        c = cls()
        c._amount = amt
        c._unit = unit
        return c

    def format(self, locale='en_US'):
        return format_currency(self._amount.float(self._unit),
                               currency=self._unit.symbol,
                               locale=locale,
                               format='¤ #0.' + (self._unit.decimals * '0'),
                               decimal_quantization=False,
                               currency_digits=False)

    def __str__(self):
        return self.format()
