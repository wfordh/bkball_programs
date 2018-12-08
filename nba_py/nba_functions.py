import csv
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


def get_all_gleague_drafts(start = 2007, stop = dt.date.today().year):
	"""
	Use get_gleague_draft function to get drafts for every year since 2008
	"""
	all_drafts = []
	for year in np.arange(start, stop):
		time.sleep(np.random.randint(1, 4))
		df = get_gleague_draft(str(year))
		# insert year and overall position?
		df.insert(0, column = 'Season', value = year+1)
		all_drafts.append(df)
	
	return pd.concat(all_drafts).reset_index(drop=True)


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

		
def get_game_data(base_url, params, headers = nba_headers):
	data = requests.get(base_url, params=params, headers=headers)
	return data.json()['resultSets'][0]['rowSet'], data.json()['resultSets'][0]['headers']

def get_game_ids(params = scoreboard_params, headers = nba_headers):
	base_url = "http://stats.nba.com/stats/scoreboardv2/"
	data = requests.get(base_url, params=params, headers=headers)
	if params['LeagueID'] == '00':
		game_ids = [x[0] for x in data.json()['resultSets'][6]['rowSet']]
	else: 
		game_ids = [x[2] for x in data.json()['resultSets'][0]['rowSet']]
	return game_ids


def scrape_nba_stats(base_url, headers, params, year_start=2017, year_end = 2017):
	"""
	Use this or get_nba_stats?
	"""
	data = list()
	
	for season in np.arange(year_start, year_end+1):
		params['Season'] = f'{season}-{str(season+1)[-2:]}'
		time.sleep(np.random.randint(1, 4))
		r = requests.get(base_url, headers=headers, params=params)
		data_rows = r.json()['resultSets'][0]['rowSet']
		[row.insert(0, season+1) for row in data_rows]
		data.extend(data_rows)
	
	columns = [s.title() for s in r.json()['resultSets'][0]['headers']] # or lowercase or uppercase?
	columns.insert(0, 'Season')
	data.insert(0, columns)
	
	return data


def get_period_starters(game_id, period_in_subs, periods):
	"""
	h/t Ryan Davis (@rd11490) 
	"""
	from nba_helpers import period_time_ranges
	frames = []
	box_params['GameID'] = game_id
	box_adv_url = "https://stats.nba.com/stats/boxscoreadvancedv2"

	for period in periods:

		time.sleep(np.random.randint(1, 4))
		low, high = period_time_ranges[period]
		box_params['StartRange'] = low
		box_params['EndRange'] = high
		box_adv_rows, box_adv_headers = get_game_data(box_adv_url, box_params)
		box_adv_headers = [x.title() for x in box_adv_headers]
		box_df = pd.DataFrame(box_adv_rows, columns=box_adv_headers)
	#     boxscore = advanced_boxscore_url(game_id, low, high)
		boxscore_players = box_df[['Player_Name', 'Player_Id',
			'Team_Abbreviation']].copy()
		boxscore_players['Period'] = period
		
		current_per_subs_in = period_in_subs.loc[period_in_subs.Period==period]

		joined_players = pd.merge(boxscore_players, current_per_subs_in,
			on=['Player_Id', 'Period'], how='left')
		joined_players = joined_players[pd.isnull(joined_players['Sub'])][['Player_Name',
			'Player_Id', 'Team_Abbreviation', 'Period']]
		frames.append(joined_players)

	out = pd.concat(frames)

	# need this so I can pull it back out later for plus minus parsing
	out['game_id'] = box_params['GameID']
	return out


def split_subs(arr, tag, n_subs):
	tag_arr = np.ones(n_subs) if tag == 'OUT' else -np.ones(n_subs)
	idx = [0, 1, 2, 4] if tag == 'OUT' else [0, 1, 3, 4]
	return np.vstack((arr, tag_arr))[idx]


def get_period_subs(pbp_df):
	"""
	"""
	# pbp_arr = pbp_df.loc[pbp_df.Game_Id == game].values.T
	pbp_arr = pbp_df.values.T
	pbp_headers = pbp_df.columns.tolist()
	# print(pbp_headers)
	# pbp_arr = game_pbp.

	event_msg_type = pbp_headers.index('Eventmsgtype')
	sub_events = np.where(pbp_arr[event_msg_type] == 8)
	n_subs = sub_events[0].shape[0]

	sub_cols = [
		pbp_headers.index('Period'),
		pbp_headers.index('Eventnum'),
		pbp_headers.index('Player1_Id'),
		pbp_headers.index('Player2_Id')
	]

	subs_arr = np.squeeze(np.take(pbp_arr,
		sub_events, axis=1))[sub_cols].astype(np.int64)

	in_sub = split_subs(subs_arr, 'IN', n_subs)
	out_sub = split_subs(subs_arr, 'OUT', n_subs)

	all_subs = np.hstack((in_sub, out_sub))

	periods = np.unique(all_subs[0])

	first_subs_df = pd.DataFrame(all_subs.T,
		columns=['Period', 'Eventnum',
		'Player_Id', 'Sub']).groupby(['Period', 'Player_Id']).Eventnum.idxmin()

	first_subs = np.take(all_subs, first_subs_df.values, axis=1)

	per_in_subs = np.delete(np.squeeze(np.take(first_subs,
		np.where(first_subs[3] == -1), axis = 1)), 1, axis=0)

	subs_df = pd.DataFrame(per_in_subs.T, columns=['Period', 'Player_Id', 'Sub'])

	return subs_df, periods


