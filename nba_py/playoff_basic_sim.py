import numpy as np

gl_1 = ['h', 'h', 'a', 'a', 'a', 'h', 'h']
gl_2 = ['h', 'h', 'a', 'a', 'h', 'a', 'h']

gl_3 = ['h', 'h', 'a', 'a', 'a']
gl_4 = ['h', 'h', 'a', 'a', 'h']

series_wins_1 = 0
series_wins_2 = 0

p_h = 0.7
p_a = 0.4

# currently summing up to 1000, but I want each setup's

def playoff_sim(game_list, p_h = 0.5, p_a = 0.5, n_iters = 1000):
    """
    Simple playoff simulation system. 
    game_list: list of strings for set up of home/away games in the series
    p_h: probability of win at home
    p_a: probability of win away
    n_iters: number of simulations to use
    """
    series_wins = 0

    for i in np.arange(n_iters):
        wins = 0
        #w2 = 0 # need this?

        for g in game_list:
            rn = np.random.uniform(0, 1, 1)
            if (g == 'h') & (rn < p_h):
                wins += 1
            
            if (g == 'a') & (rn < p_a):
                wins += 1
            
            if wins == 4:
                series_wins += 1
                break 
    
    return series_wins/float(n_iters)

print(playoff_sim(['h', 'h', 'a', 'a'], p_h = 0.7, p_a = 0.7, n_iters=10000))
print(playoff_sim(gl_3, p_h = 0.7, p_a = 0.4, n_iters = 10000))
print(playoff_sim(gl_4, p_h = 0.7, p_a = 0.4, n_iters = 10000))

# for i in np.arange(10000):
#     w1 = 0
#     w2 = 0
#     # can these for loops be switched to while loops?
#     # functionalize them?
#     # how to approach five games or less --> win problem

#     for g in gl_1:
#         rn = np.random.uniform(0, 1, 1)
#         if (g == 'h') & (rn < p_h):
#             w1 += 1

#         if (g == 'a') & (rn < p_a):
#             w1 += 1

#         if w1 == 4:
#             series_wins_1 += 1
#             break

#     for g in gl_2:
#         rn = np.random.uniform(0, 1, 1)
#         if (g == 'h') & (rn < p_h):
#             w2 += 1

#         if (g == 'a') & (rn < p_a):
#             w2 += 1

#         if w2 == 4:
#             series_wins_2 += 1
#             break

#     #print(w1, w2)

# print(series_wins_1)
# print(series_wins_2)
