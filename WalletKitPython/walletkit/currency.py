from typing import Union
from babel.numbers import format_currency
from walletkit import native as n

Numeric = Union[int, float]


class Unit:
    _unit: n.UnitBase

    @property
    def native(self) -> n.UnitBase:
        return self._unit

    @native.setter
    def native(self, new_native: n.UnitBase):
        self._unit = new_native

    @classmethod
    def from_native(cls, native: n.UnitBase) -> 'Unit':
        u = cls.__new__(cls)
        u._unit = native
        return u

    def __init__(self, currency: 'Currency', code: str, name: str, symbol: str, base: 'Unit', decimals: int):
        self._unit = n.Unit.create(currency.native, code=code, name=name, symbol=symbol, base=base.native,
                                   decimals=decimals)

    def __call__(self, amount: Numeric) -> 'Amount':
        return Amount.from_native(self._unit(amount), self._unit)

    def __str__(self):
        return str(self._unit)


class BaseUnit:
    _unit: n.UnitBase

    @property
    def native(self) -> n.UnitBase:
        return self._unit

    @native.setter
    def native(self, new_native: n.UnitBase):
        self._unit = new_native

    @classmethod
    def from_native(cls, native: n.UnitBase) -> 'BaseUnit':
        u = cls.__new__(cls)
        u._unit = native
        return u

    def __init__(self, currency: 'Currency', code: str, name: str, symbol: str):
        self._unit = n.Unit.create_base(currency.native, code=code, name=name, symbol=symbol)

    def __call__(self, amount: Numeric) -> 'Amount':
        return Amount.from_native(self._unit(amount), self._unit)

    def __str__(self):
        return str(self._unit)


Units = Union[Unit, BaseUnit]


class Currency:
    _currency: n.CurrencyBase

    @property
    def native(self) -> n.CurrencyBase:
        return self._currency

    @native.setter
    def native(self, new_native: n.CurrencyBase):
        self._currency = new_native

    @classmethod
    def from_native(cls, currency: n.CurrencyBase):
        c = cls.__new__(cls)
        c._currency = currency
        return c

    def __init__(self, name: str, code: str, type: str, issuer: str):
        self._currency = n.Currency.create(name=name, code=code, type=type, issuer=issuer)

    def create_base_unit(self, code: str, name: str, symbol: str):
        return BaseUnit(self, code=code, name=name, symbol=symbol)

    def create_unit(self, code: str, name: str, symbol: str, base: Unit, decimals: int):
        return Unit(self, code=code, name=name, symbol=symbol, base=base, decimals=decimals)


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
                               decimal_quantization=True,
                               currency_digits=False)

    def __str__(self):
        return self.format()


class FeeBasis:
    _fee_basis: n.FeeBasisBase

    @property
    def native(self) -> n.FeeBasisBase:
        return self._fee_basis

    @native.setter
    def native(self, new_native: n.FeeBasisBase):
        self._fee_basis = new_native

    @classmethod
    def from_native(cls, fee: n.FeeBasisBase) -> 'FeeBasis':
        f = FeeBasis()
        f._fee_basis = fee
        return f

    def __str__(self):
        return Amount.from_native(self._fee_basis.fee, self._fee_basis.fee.unit).format()
