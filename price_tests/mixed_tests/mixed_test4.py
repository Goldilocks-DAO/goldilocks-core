import sys
sys.path.append('price_tests')
from market_functions import buy, sell, redeem, floor_raise, get_initital_target_ratio
from eth_abi import encode

fsl = 600000
psl = 180000
supply = 100000000
floor_price = fsl/supply
market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
target = get_initital_target_ratio()

transactions = [
  (buy, 6000000),
  (floor_raise, None),
  (sell, 8000000),
  (buy, 14000000),
  (floor_raise, None),
  (sell, 12900000),
  (buy, 23500000),
  (floor_raise, None),
  (redeem, 2500000),
  (floor_raise, None),
  (sell, 1500000)
]


for transaction, amount in transactions:
  if transaction == floor_raise:
    target, fsl, psl, supply, floor_price, market_price = transaction(target, fsl, psl, supply, floor_price, market_price)
  else:
    fsl, psl, supply, floor_price, market_price = transaction(amount, fsl, psl, supply, floor_price, market_price)

market_price *= (10 ** 18)
enc = encode(['uint256'], [int(market_price)])
print("0x" + enc.hex())