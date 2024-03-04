import sys
sys.path.append('price_tests')
from market_functions import redeem, floor_raise, get_initital_target_ratio
from eth_abi import encode

fsl = 1050000
psl = 320000
supply = 100000000
floor_price = fsl/supply
market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
target = get_initital_target_ratio()

redeemed = 0
while(redeemed < 400):
  fsl, psl, supply, floor_price, market_price = redeem(10, fsl, psl, supply, floor_price, market_price)
  target, fsl, psl, supply, floor_price, market_price = floor_raise(target, fsl, psl, supply, floor_price, market_price)
  redeemed += 10

market_price *= (10 ** 18)
enc = encode(['uint256'], [int(market_price)])
print("0x" + enc.hex())