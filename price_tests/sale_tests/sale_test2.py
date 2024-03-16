import sys
sys.path.append('price_tests')
from market_functions import sell, get_initital_target_ratio
from eth_abi import encode

fsl = 1140000
psl = 400000
supply = 190000000
floor_price = fsl/supply
market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
target = get_initital_target_ratio()

sold = 0
while(sold < 100):
  fsl, psl, supply, floor_price, market_price = sell(2.5, fsl, psl, supply, floor_price, market_price)
  sold += 2.5

market_price *= (10 ** 18)
enc = encode(['uint256'], [int(market_price)])
print("0x" + enc.hex())