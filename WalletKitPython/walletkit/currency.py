from typing import Union
import native as n


class Unit:
    _unit: n.UnitBase

    @property
    def native(self) -> n.UnitBase:
        return self._unit

    @native.setter
    def native(self, new_native: n.UnitBase):
        self._unit = new_native

    def __init__(self, currency: 'Currency', code: str, name: str, symbol: str, base: 'Unit', decimals: int):
        self._unit = n.Unit.create(currency.native, code=code, name=name, symbol=symbol, base=base.native,
                                   decimals=decimals)


class BaseUnit:
    _unit: n.UnitBase

    @property
    def native(self) -> n.UnitBase:
        return self._unit

    @native.setter
    def native(self, new_native: n.UnitBase):
        self._unit = new_native

    def __init__(self, currency: 'Currency', code: str, name: str, symbol: str):
        self._unit = n.Unit.create_base(currency.native, code=code, name=name, symbol=symbol)


Units = Union[Unit, BaseUnit]


class Currency:
    _currency: n.CurrencyBase

    @property
    def native(self) -> n.CurrencyBase:
        return self._currency

    @native.setter
    def native(self, new_native: n.CurrencyBase):
        self._currency = new_native

    def __init__(self, name: str, code: str, type: str, issuer: str):
        self._currency = n.Currency.create(name=name, code=code, type=type, issuer=issuer)

    def create_base_unit(self, code: str, name: str, symbol: str):
        return BaseUnit(self, code=code, name=name, symbol=symbol)

    def create_unit(self, code: str, name: str, symbol: str, base: Unit, decimals: int):
        return Unit(self, code=code, name=name, symbol=symbol, base=base, decimals=decimals)
