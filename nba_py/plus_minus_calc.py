import numpy as np
import pandas as pd
import sys


def period_plus_minus_prep(game_pbp, game_lineups, period, team_1, team_2):
	"""
	Function preparing a single game's dataframe for plus/minus analysis
	Adds necessary columns tracking score and who is on the court
	Returns the cleaned dataframe
	"""
	period_pbp = game_pbp.loc[game_pbp.Period == period].copy().reset_index(drop = True)
	team_1_starters = game_lineups.loc[(game_lineups.Period == period) &
									   (game_lineups.Team_id == team_1)].\
									   Person_id.values
	team_2_starters = game_lineups.loc[(game_lineups.Period == period) &
									   (game_lineups.Team_id == team_2)].\
									   Person_id.values
	
	t1_players = team_1_starters
	t2_players = team_2_starters
	
	player_cols = ['t' + str(i) + str(j) for i in range(1, 3) for j in range(1, 6)]
	
	period_pbp['team_1_score'] = 0
	period_pbp['team_2_score'] = 0
	period_pbp['team_1_score_diff'] = 0
	period_pbp['team_2_score_diff'] = 0
	
	period_pbp.team_1_score_diff = period_pbp.apply(lambda x: x.Option1 if 
		(x.Team_id == team_1) & ((x.Event_Msg_Type == 1) | 
			(x.Event_Msg_Type == 3)) else 0, axis=1)
	period_pbp.team_2_score_diff = period_pbp.apply(lambda x: x.Option1 if 
		(x.Team_id == team_2) & ((x.Event_Msg_Type == 1) | 
			(x.Event_Msg_Type == 3)) else 0, axis=1)

	period_pbp.team_1_score = period_pbp.team_1_score_diff.cumsum()
	period_pbp.team_2_score = period_pbp.team_2_score_diff.cumsum()

	period_pbp['score_diff'] = period_pbp.team_1_score - period_pbp.team_2_score
	
	stint_list, oncourt = track_stint_subs(period_pbp, t1_players, t2_players)
	
	period_pbp['stint'] = stint_list
	oncourt_players = pd.DataFrame(oncourt, columns=player_cols).reset_index(drop=True)
	
	period_pbp = period_pbp.merge(oncourt_players, left_index = True, 
		right_index = True)
	period_pbp = swap_rows(period_pbp)
	
	return period_pbp


def swap_rows(period_pbp):
	"""
	Swaps any occurrences of a substitution happening in between free throws 
	so the substitution effectively happens at the end of the free throws, 
	but before any other events, resolving the issue of a player being 
	miscredited for plus/minus
	"""
	period_pbpc = period_pbp.copy()
	
	for idx, row in period_pbpc.iterrows():
		# just to get around last index/index out of bounds issues
		try:
			if (row.Event_Msg_Type == 8) & (period_pbpc.loc[idx+1].Event_Msg_Type == 3):
				temp1 = row.copy().values
				temp2 = period_pbpc.loc[idx+1].copy().values
				period_pbpc.loc[idx] = temp2
				period_pbpc.loc[idx+1] = temp1
		except:
			pass
			
	return period_pbpc


def track_stint_subs(period_pbp, t1_players, t2_players):
	"""
	Tracks when substitutions occur, which number stint, and 
	who is on the court after the substitution occurs
	"""
	oncourt = list()
	stint = 0
	stint_list = list()
	period_pbpc = period_pbp.copy()
	
	for idx, row in period_pbpc.iterrows():
		if row.Event_Msg_Type == 8:				
			try:
				t1_players[np.where(t1_players == row.Person1)[0][0]] = row.Person2
			except:
				t2_players[np.where(t2_players == row.Person1)[0][0]] = row.Person2
			oncourt.append(np.append(t1_players, t2_players))
			
			if period_pbpc.loc[idx-1].Event_Msg_Type == 8:
				stint_list.append(stint)
			else:
				stint += 1
				stint_list.append(stint)
		else:
			# keep the same players
			oncourt.append(np.append(t1_players, t2_players))
			stint_list.append(stint)
			
	return stint_list, oncourt


def compute_period_plus_minus(period_pbp, player_plus_minus_dict):
	"""
	Finds plus/minus for a single period of a single game
	"""
	period_grp = period_pbp.groupby('stint')
	
	t1_cols = [x for x in period_pbp if x.startswith('t1')]
	t2_cols = [x for x in period_pbp if x.startswith('t2')]
	
	for stint in period_grp:
		stint_num = stint[0]
		stint_df = stint[1]
		first_idx = stint_df.index[0]
		last_idx = stint_df.index[-1]
		
		plus_minus = stint_df.score_diff[last_idx] - stint_df.score_diff[first_idx]
		
		for p_id in stint_df.loc[first_idx, t1_cols]:
			player_plus_minus_dict[p_id] += plus_minus
		for p_id in stint_df.loc[first_idx, t2_cols]:
			player_plus_minus_dict[p_id] -= plus_minus
			
	return player_plus_minus_dict


def get_game_plus_minus(game_pbp, game_lineups):
	"""
	Finds game plus/minus across all periods and players
	Returns it as a dictionary
	"""
	nperiods = game_lineups.Period.max()
	gpmd = dict.fromkeys(np.union1d(game_pbp.Person1.unique(),
								   game_pbp.Person2.unique()), 0)
	
	team_1 = game_pbp.Team_id.value_counts().index[0]
	team_2 = game_pbp.Team_id.value_counts().index[1]
	
	for i in np.arange(1, nperiods + 1):
		period_pbp = period_plus_minus_prep(game_pbp, game_lineups, i, team_1, team_2)
		gpmd = compute_period_plus_minus(period_pbp, gpmd)
		
	return gpmd


def all_games_plus_minus(pbp, lineups):
	"""
	Aggregates across all games and puts results in a dataframe with
	columns 'Game_ID', 'Player_ID', and 'Player_Plus/Minus'
	"""
	unique_games = lineups.Game_id.unique()
	gpmd_df = pd.DataFrame()

	for game in unique_games:
		game_pbp = pbp.loc[pbp.Game_id == game].copy().reset_index(drop = True)
		game_pbp.sort_values(by = ['Period', 'PC_Time', 'WC_Time', 'Event_Num'],
							 ascending=[True, False, True, True], inplace = True)

		game_lineups = lineups.loc[lineups.Game_id == game].copy().reset_index(drop = True)

		gpmd = get_game_plus_minus(game_pbp, game_lineups=game_lineups)
		temp_game = pd.DataFrame.from_dict(gpmd, orient = 'index',
										  columns = ['Player_Plus/Minus']).reset_index().\
										rename(columns = {'index':'Player_ID'})
		temp_game.insert(0, column='Game_ID', value = pd.Series([game]*len(temp_game)))
		gpmd_df = pd.concat([gpmd_df, temp_game])

	return gpmd_df.reset_index(drop = True)

def main():
	pbp = sys.argv[0]
	lineups = sys.argv[1]
	if pbp.endswith('.txt'):
		pbp = pd.read_csv(pbp, sep = '\t')
	else:
		pbp = pd.read_csv(pbp, sep = ',')
	if lineups.endswith('.txt'):
		lineups = pd.read_csv(lineups, sep = '\t')
	else:
		lineups = pd.read_csv(lineups)

	# keep events as simply reading in from file for now instead of 
	# coming from the command line
	events = pd.read_csv('~/basketball/analytics/hackathon_2018/Basketball_Analytics/NBA Hackathon - Event Codes.txt', 
		sep='\t')
	gpmd_df = all_games_plus_minus(pbp, lineups)

	# wrap this in if statement? pass arg for it?
	gpmd_df.to_csv('games_plus_minus.csv')


if __name__ == '__main__':
	main()