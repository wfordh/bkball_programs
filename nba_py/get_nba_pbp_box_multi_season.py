import csv
import requests
import pandas as pd
import numpy as np

from nba_functions import write_nba_data

base_pbp_url = 'http://stats.nba.com/stats/playbyplayv2' 
base_box_url = 'http://stats.nba.com/stats/boxscoretraditionalv2'

for season in np.arange(2016, 2018):
    print(season)
    scoreboard_params['GameDate'] = f'10/15/{str(season)[-2:]}'
    pbp_data = list()
    box_data = list()
    
    for i in np.arange(200):
        scoreboard_params['DayOffset'] = str(i)
        time.sleep(1)
        game_ids = get_game_ids(params=scoreboard_params, headers=nba_headers)
        
        for game in game_ids:
#             print(game)
            time.sleep(np.random.randint(1, 3))
            pbp_params['GameID'] = game
            box_params['GameID'] = game

            pbp_rows, pbp_headers = get_game_data(base_pbp_url, params=pbp_params, headers=nba_headers)
            [x.insert(0, season+1) for x in pbp_rows]
            pbp_data.extend(pbp_rows)
            
            time.sleep(np.random.randint(1, 3))
    
            box_rows, box_headers = get_game_data(base_box_url, params=box_params, headers=nba_headers)
            [x.insert(0, season+1) for x in box_rows]
            box_data.extend(box_rows)

    pbp_headers.insert(0, 'Season')
    box_headers.insert(0, 'Season')
    
    pbp_data.insert(0, [x.title() for x in pbp_headers]) # how to get headers out of here?
    box_data.insert(0, [x.title() for x in box_headers])
    
    write_nba_data(pbp_data, f'nba_pbp_data_{season+1}.csv')
    write_nba_data(box_data, f'nba_box_data_{season+1}.csv')