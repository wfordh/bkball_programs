library(jsonlite)
library(stringr)
library(purrr)
# only pick out necessary tidyverse packages
library(dplyr)
library(magrittr)
library(progress)

nba_dre <- function(df, minutes_regression=200) {
  # Check if minutes over 200 for mean regression
  # new eqn: -8.424 + .792*pts - .719*2pa - .552*3pa - .159*fta + .135*orb + .400*drb 
  # + .544*ast + 1.68*stl + .764*blk - 1.36*tov - .108*pf
  # No adjustment for post-2019 free throw rule change
  
  df %<>% mutate(fg2a = fga - fg3a,
                 dre = if_else(min > minutes_regression, 
                               -8.424 + .792*pts - .719*fg2a - .552*fg3a - .159*fta - 1.36*tov 
                               + .135*oreb + .4*dreb + 1.68*stl + .764*blk + .544*ast -.108*pf, 
                               -2.0*(400 - min)/400 + (min/400)*(-8.424 + .792*pts - .719*fg2a - .552*fg3a 
                                                                 - .159*fta - 1.36*tov + .135*oreb + .4*dreb 
                                                                 + 1.68*stl + .764*blk + .544*ast -.108*pf)
                               )
                 )
  
  # pts = 30. reb = 22. stl = 25. blk = 26. ast = 23. fga = 12. fta = 18. tov = 24. pf = 28.
  #colnames(dre) <- "dre"
  #df <- cbind(df, dre)
}

get_lg_efg <- function(player_stats) {
  return(player_stats %>% 
    select(c("fga", "fgm", "fg3m")) %>% 
    summarise_all(sum) %>% 
    transmute(lg_efg = 100.0*(fgm + 0.5*fg3m) / fga)
  )
}

get_lg_ts <- function(player_stats, year){
  if (year >= 2019) {
    ts_coef <- 0.692
  } else {
    ts_coef <- 0.44
  }
  return(player_stats %>% 
           select(c("fga", "pts", "fta")) %>% 
           summarise_all(sum) %>% 
           transmute(lg_ts = if_else(
             year >= 2019,
             100.0*pts / (2*(fga + 0.692*fta)),
             100.0*pts / (2*(fga + 0.44*fta))
             )
             )
         )
}

# SPR formula (All per-100 except GS%)

# PTS-1.2*TOV+0.7*BLK+1.5*STL+0.5*AST+0.2*DRB+0.3*ORB-0.3*FTA- 2PA - 0.8*3PA + GamesStarted% x 2.2 - 7.9
# GamesStarted would need to be scraped from basketball-reference

# do I need the below stuff? can now just read in most of it
# stats go back to 07-08


# Other things to add to table: rel eFG%, PER? plus minus? 
# remove all the per 100 numbers?
# try to get games started from the box scores?

get_gleague_dre_stats <- function(year, save_dre=TRUE, minutes_limit=0) {
  pb <- progress::progress_bar$new(total = 6)
  season <- paste0(as.character(year), "-", substr(as.character(year+1), 3, 4))
  # placeholder for now. 
  # 2021-22 RS starts on Dec 27
  # will need to pull the "Advanced" numbers as well to get pace
  # can do pace * min to get total possessions and then do weighted average to get to per 100 poss?
  if (year > 2020) {
    season_type <- "Showcase"
  } else {
    season_type <- "Regular+Season"
  }
  url_totals <- paste0("http://stats.nbadleague.com/stats/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=",
          "&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=20&Location=&MeasureType=Base&Month=",
          "0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=",
          "N&Rank=N&Season=", season, "&SeasonSegment=&SeasonType=", season_type, "&ShotClockRange=&StarterBench=&TeamID=0&VsConference=",
          "&VsDivision=&Weight=")
  url_totals <- fromJSON(url_totals)
  head_totals <- tolower(url_totals$resultSets$headers[1][[1]])
  stats_totals <- as.data.frame(url_totals$resultSets$rowSet)
  names(stats_totals) <- head_totals
  pb$tick()
  
  url_per100 <- paste0("http://stats.nbadleague.com/stats/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=",
          "&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=20&Location=&MeasureType=Base",
          "&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Per100Possessions&Period=0&PlayerExperience=",
          "&PlayerPosition=&PlusMinus=N&Rank=N&Season=", season, "&SeasonSegment=&SeasonType=", season_type, "&ShotClockRange=",
          "&StarterBench=&TeamID=0&VsConference=&VsDivision=&Weight=")
  url_per100 <- fromJSON(url_per100)
  head_per100 <- tolower(url_per100$resultSets$headers[1][[1]])
  stats_per100 <- as.data.frame(url_per100$resultSets$rowSet)
  names(stats_per100) <- head_per100
  stats_per100 <- stats_per100[1:33]
  pb$tick()
  
  # Overwrite per 100 minutes with total minutes
  stats_per100[10] <- stats_totals[10]
  
  cols <- c(5:33)
  stats_per100[, cols] <- map(stats_per100[, cols], function(x) as.numeric(as.character(x)))
  ## OR stats[, cols] <- as.numeric(as.character(unlist(stats[, cols])))
  stats_per100[10] <- round(stats_per100[10], 2)
  stats_per100 %<>% filter(min >= minutes_limit)
  
  dre_stats <- nba_dre(stats_per100)
  pb$tick()
  lg_ts <- get_lg_ts(dre_stats, year = year)$lg_ts
  lg_efg <- get_lg_efg(dre_stats)$lg_efg
  pb$tick()
  
  dre_stats %<>% 
    mutate(efg = 100.0*(fgm + 0.5*fg3m) / fga,
           rel_efg = 100.0*(efg / lg_efg), # / lg_efg,
           stk = blk + stl
           )
  if (year >= 2019) {
    dre_stats %<>% 
      mutate(ts = 100.0*(pts / (2*(fga + 0.692*fta))),
             rel_ts = 100.0*(ts / lg_ts ) #/ lg_ts
             )
  } else {
    dre_stats %<>% 
      mutate(ts = 100.0*(pts / (2*(fga + 44*fta))),
             rel_ts = 100.0*(ts / lg_ts) #/ lg_ts
             )
  }
  pb$tick()
  dre_stats %<>% select(
    c("player_name", "team_abbreviation", "age", "gp", "min", "dre", "efg", "rel_efg", "ts", "rel_ts", "stk", "plus_minus")
    )
  
  dre_stats$min <- round(dre_stats$min)
  dre_stats$dre <- round(dre_stats$dre, 2)
  dre_stats$efg <- round(dre_stats$efg, 2)
  dre_stats$rel_efg <- round(dre_stats$rel_efg, 2)
  dre_stats$ts <- round(dre_stats$ts, 2)
  dre_stats$rel_ts <- round(dre_stats$rel_ts, 2)
  
  if (save_dre) {
    write.csv(dre_stats, file = paste0("~/basketball/analytics/bkball_programs/nba_R/dre_app/data/nbadl_dre_", season, ".csv"), row.names=F)
    print(paste0("DRE for ", season, " saved!"))
  }
  pb$tick()
  return(dre_stats)
}

args <- commandArgs()

if (length(args) > 1) {
  print(args)
  year <- as.integer(format(Sys.Date(), "%Y"))
  print(year)
  dre_stats <- get_gleague_dre_stats(year, save_dre=T)
}
