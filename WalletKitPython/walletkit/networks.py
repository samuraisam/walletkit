from native import Network, Unit, Currency

was_imported = False
if not was_imported:
    Network.install_builtins()


# TODO: figure out how to update the block height here

class Bitcoin:
    mainnet = Network.find_builtin('bitcoin-mainnet')
    testnet = Network.find_builtin('bitcoin-testnet')

    currency = Currency.create('bitcoin', code='btc', type='native')

    SAT = Unit.create_base(currency, code='sat', name='satoshi', symbol='SAT')
    BTC = Unit.create(currency, code='bitcoin', name='bitcoin', symbol='B', base=SAT, decimals=8)
