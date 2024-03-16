from eth_abi import encode

fsl = 1140000
psl = 400000
supply = 190000000
floor_price = fsl/supply

floor_price *= (10 ** 18)
enc = encode(['uint256'], [int(floor_price)])
print("0x" + enc.hex())