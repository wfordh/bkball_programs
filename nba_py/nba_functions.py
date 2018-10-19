import requests
from bs4 import BeautifulSoup
import json
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import time
import datetime as dt
import altair as alt

from nba_headers import *

# if in notebook, uncomment these
#pd.options.display.max_columns = 100
#%matplotlib inline


def get_gleague_draft(year):
    """
    Scrapes and returns G League Draft info from RealGM
    year - year of draft (start year of season)
    """
    url = "https://basketball.realgm.com/dleague/draft/past_annual_drafts/" + year
    html = requests.get(url)
    c = html.content
    soup = BeautifulSoup(c, 'html.parser')
    column_headers = [th.get_text() for th in soup.find_all('tr', limit = 2)[0].find_all('th')]
    column_headers[0] = 'Round_Pos'
    data_rows = soup.find_all('tr')[1:]
    player_info = [[td.get_text() for td in data_rows[i].find_all('td')] for i in np.arange(len(data_rows))]
    df = pd.DataFrame(player_info, columns = column_headers).dropna()
    df.insert(0, column = 'Draft_Pos', value = df.index + 1)
    return df


def get_all_gleague_drafts(start = 2008):
    """
    Use get_gleague_draft function to get drafts for every year since 2008
    """
    all_drafts = []
    for year in np.arange(start, dt.date.today().year):
        time.sleep(np.random.randint(1, 4))
        df = get_gleague_draft(str(year))
        # insert year and overall position?
        df.insert(0, column = 'Season', value = year)
        all_drafts.append(df)
    
    return pd.concat(all_drafts)


def get_nba_stats(stat_level, league_id = '00', measure_type = 'Base', 
    per_mode = 'Totals', seasons = np.arange(2017, 2018), season_type = 'Regular+Season', 
    headers = nba_headers):
    """
    set params this way or import them from nba_headers.py and use keyword args?
    """

    df = pd.DataFrame()

    for yr_start in seasons:
        time.sleep(np.random.randint(1, 4))
        yr_end = str(yr_start + 1)[2:]
        yr_start = str(yr_start)
        season = yr_start + "-" + yr_end
        url = "http://stats.nba.com/stats/leaguedash{}stats?Conference=&DateFrom=" + \
            "&DateTo=&GameScope=&GameSegment=&LastNGames=0&LeagueID={}&Location=" + \
            "&MeasureType={}&Month=0&OpponentTeamID=0&Outcome=&PORound=0" + \
            "&PaceAdjust=N&PerMode={}&Period=0&PlayerExperience=&PlayerPosition=" + \
            "&PlusMinus=N&Rank=N&Season={}&SeasonSegment=&SeasonType={}" + \
            "&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision="
        
        url = url.format(stat_level, league_id, measure_type, per_mode, season, season_type)
        page = requests.get(url, headers = headers)
        data = page.json()['resultSets'][0]['rowSet']
        results = pd.DataFrame(data)
        results.insert(0, column = 'season', value = season)
        df = pd.concat([df, results])
    
    cols = [x.lower() for x in page.json()['resultSets'][0]['headers']]
    cols.insert(0, 'season')
    df.columns = cols
    df.rename(columns = {'min':'minutes'}, inplace = True)

    return df

def scrape_inpredict_possessions(year_start = 2017, year_end = 2017,
                                 defense = False):
    base_url = "http://stats.inpredictable.com/nba/ssnTeamPoss.php?"
    inpredict_params = {'view':'def'} if defense else {'view':'off'}
    column_headers = ['Season',
        'Team',
        'Gms',
        'tot_poss',
        'tot_secs',
        'tot_secs_rk',
        'tot_pts',
        'tot_pts_rk',
        'after_fgM_%',
        'after_fgM_secs',
        'after_fgM_secs_rk',
        'after_fgM_pts',
        'after_fgM_pts_rk',
        'after_drb_%',
        'after_drb_secs',
        'after_drb_secs_rk',
        'after_drb_pts',
        'after_drb_pts_rk',
        'after_tov_%',
        'after_tov_secs',
        'after_tov_secs_rk',
        'after_tov_pts',
        'after_tov_pts_rk']
    
    final_data = list()
    final_data.append(column_headers)
    
    for season in np.arange(year_start, year_end + 1):
        time.sleep(np.random.randint(1, 3))
        inpredict_params['season'] = season
        r = requests.get(base_url, inpredict_params)
        soup = BeautifulSoup(r.content, 'html.parser')
        data_rows = soup.find_all('tr')[3:]
        raw_data = [[td.get_text() for td in data_rows[i]][1:] for i in np.arange(len(data_rows))][:-2]
        [row.insert(0, season+1) for row in raw_data]
        
        final_data.extend(raw_data)
        
    return final_data

def write_nba_data(data, filename):
    from pathlib import Path
    
    filepath = Path("/Users/fordhiggins/basketball/analytics/data/")
    with open(filepath/filename, 'w') as outfile:
        wr = csv.writer(outfile, quoting = csv.QUOTE_ALL)
        wr.writerows(data)
        
def get_game_data(base_url, params, headers = nba_headers):
    data = requests.get(base_url, params=params, headers=headers)
    return data.json()['resultSets'][0]['rowSet'], data.json()['resultSets'][0]['headers']

def get_game_ids(params = nba_params, headers = nba_headers):
    base_url = "http://stats.nba.com/stats/scoreboardv2/"
    data = requests.get(base_url, params=params, headers=headers)
    game_ids = [x[0] for x in data.json()['resultSets'][6]['rowSet']]
    return game_ids
