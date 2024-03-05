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
  (buy, 1000000),
  (floor_raise, None),
  (sell, 2000000),
  (buy, 13000000),
  (floor_raise, None),
  (sell, 17100000),
  (buy, 19808759),
  (floor_raise, None),
  (redeem, 5000000),
  (floor_raise, None),
  (sell, 1700000)
]


for transaction, amount in transactions:
  if transaction == floor_raise:
    target, fsl, psl, supply, floor_price, market_price = transaction(target, fsl, psl, supply, floor_price, market_price)
  else:
    fsl, psl, supply, floor_price, market_price = transaction(amount, fsl, psl, supply, floor_price, market_price)
    print("Price:", market_price, "Floor price:", floor_price)

market_price *= (10 ** 18)
enc = encode(['uint256'], [int(market_price)])
print("0x" + enc.hex())