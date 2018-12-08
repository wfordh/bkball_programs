from nba_functions import get_period_starters, split_subs, get_game_data, get_period_subs
from nba_headers import box_params
from nba_helpers import period_time_ranges

import time
import pandas as pd
import numpy as np

pbp_df = pd.read_csv('../../data/nba_pbp_data_2017.csv')

game_ids = pbp_df.Game_Id.unique()[:3]
bad_games = list()
frames = list()

for game in game_ids:
	print(game)
	game_pbp = pbp_df.loc[pbp_df.Game_Id == game]
	period_in_subs, periods = get_period_subs(game_pbp)

	# temp workaround
	game = str(game).zfill(10)
	period_starters = get_period_starters(game, period_in_subs, periods)
	frames.append(period_starters)

pd.concat(frames).to_csv('../../data/pbp_starters_test.csv', index=False)


# Game IDs with '00' start are NBA. If next digit is '1', then preseason.
# If '2', then regular season. If '3' or '4'???
# Need to pad all the game_ids in the data...