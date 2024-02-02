from eth_abi import encode

fsl = 1050000
psl = 320000
supply = 100000000
floor_price = fsl/supply

floor_price *= (10 ** 18)
enc = encode(['uint256'], [int(floor_price)])
print("0x" + enc.hex())