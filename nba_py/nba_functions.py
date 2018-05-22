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