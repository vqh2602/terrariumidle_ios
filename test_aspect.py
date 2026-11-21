# Check aspects:
# containerSize on shelf: baseW = 120, baseH = 260 (typical shelf slot)
# In TerrariumSlotScene:
# if isHanging:
#    potH = baseH * 0.70 = 260 * 0.70 = 182
#    potContainerSize = (120, 182)

# Pot15:
# baseCanvas: 363 x 724 -> aspect = 724 / 363 = 1.994
# targetH = 182 * 0.98 = 178.36
# naturalW = 178.36 / 1.994 = 89.4pt (fits inside 120 easily!)

# Pot16:
# baseCanvas: 155 x 494 -> aspect = 494 / 155 = 3.187
# targetH = 178.36
# naturalW = 178.36 / 3.187 = 55.9pt

# Pot17:
# baseCanvas: 357 x 883 -> aspect = 883 / 357 = 2.473
# targetH = 178.36
# naturalW = 178.36 / 2.473 = 72.1pt

# Pot18:
# image: 497 x 821 -> aspect = 821 / 497 = 1.6519
# targetH = 178.36
# naturalW = 178.36 / 1.6519 = 107.97pt !
# In PotView Preview:
# Pot18View preview: width = 140, height = 180 (or 120, 180)
# But what if containerSize is wider or what if widthFill or what is Pot18 actual content?
