import os
import pandas as pd
import sys

from pathlib import Path

filepath = Path('../../data')

stat_type = str(sys.argv[1]).lower() # pretty slow for pbp data

data = list()

for (dirpath, dirnames, filenames) in os.walk(filepath):
	for fname in filenames:
		if fname.startswith(f'nba_{stat_type}_'):
			# not the most pythonic, but it works better
			# than other things I've tried
			data.append(pd.read_csv(os.sep.join([dirpath, fname])))

df = pd.concat(data)

df.to_csv(filepath/f'nba_{stat_type}_data_all.csv', index=False)