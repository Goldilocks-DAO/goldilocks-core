import sys
sys.path.append('price_tests')
from market_functions import sell
from eth_abi import encode

fsl = 1050000
psl = 320000
supply = 100000000
floor_price = fsl/supply
market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
target = 0.36

sold = 0
while(sold < 100):
  fsl, psl, supply, floor_price, market_price = sell(2.5, fsl, psl, supply, floor_price, market_price)
  sold += 2.5

market_price *= (10 ** 18)
enc = encode(['uint256'], [int(market_price)])
print("0x" + enc.hex())