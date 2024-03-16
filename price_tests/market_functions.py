def redeem(amount, fsl, psl, supply, floor_price, market_price):  
  supply -=amount
  fsl -= floor_price*amount
  floor_price = fsl/supply
  market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
  return fsl, psl, supply, floor_price, market_price

def sell(amount, fsl, psl, supply, floor_price, market_price):
  sale_price = 0
  increment = supply / 100000
  while amount >= increment:
    amount -= increment
    supply -= increment
    sale_price += market_price*increment
    fsl -= floor_price*increment
    psl -= (market_price - floor_price)*increment
    floor_price = fsl/supply
    market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
  supply -= amount
  sale_price += market_price*amount
  fsl -= floor_price*amount
  psl -= (market_price - floor_price)*amount
  tax = sale_price*0.05
  fsl += (tax * fsl / (fsl + psl))
  psl += (tax * psl / (fsl + psl))
  floor_price = fsl/max(supply, 1)
  market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
  return fsl, psl, supply, floor_price, market_price

def buy(amount, fsl, psl, supply, floor_price, market_price):
  purchase_price = 0
  increment = supply / 100000
  while amount >= increment:
    amount -= increment
    supply += increment
    purchase_price += market_price*increment
    if psl/fsl >= 0.5:
      fsl += market_price*increment
      floor_price = fsl/supply
    else:
      fsl += floor_price*increment
      psl += (market_price - floor_price)*increment
    floor_price = fsl/supply
    market_price = floor_price + ((psl/supply)*((psl+fsl)/fsl)**6)
  supply += amount
  purchase_price += market_price * amount
  if psl/fsl >= 0.5:
    fsl += market_price * amount
    floor_price = fsl/supply
  else:
    fsl += floor_price * amount
    psl += (market_price - floor_price) * amount
  floor_price = fsl/supply
  market_price = floor_price + ((psl/max(supply, 1))*((psl+fsl)/max(fsl, 1))**6)
  return fsl, psl, supply, floor_price, market_price

def floor_raise(target, fsl, psl, supply, floor_price, market_price):  
  ratio = psl/fsl
  if ratio > target:
    raise_amount = ratio * (psl / 32)
    psl -= raise_amount
    fsl += raise_amount
    if(ratio < 0.45):
      target += target / 50
    floor_price = fsl/supply
    market_price = floor_price + ((psl/max(supply, 1))*((psl+fsl)/max(fsl, 1))**6)  
  return target, fsl, psl, supply, floor_price, market_price

def get_initital_target_ratio():
  return 0.38