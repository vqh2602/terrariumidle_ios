# Let's search inside plant18.svg for pot elements or colors
with open('terrariumidle_ios/Resources/SVGPlants/plant18.svg') as f:
    text = f.read()

import re
# check colors or ids
paths = re.findall(r'<path[^>]+fill="([^"]+)"', text)
from collections import Counter
c = Counter(paths)
print('Top 15 colors in plant18.svg:')
for color, count in c.most_common(15):
    print(f'  {color}: {count}')
