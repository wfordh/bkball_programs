# NBA Scrapers: (which are actually necessary)
library(jsonlite)
library(tidyverse)
library(stringr)
library(curl)
library(rvest)
library(magrittr)

# Table of Contents:

# need one for each so I can run them all at once?
# NBA from 96-97, NBADL from 07-08

# NBA Player Basic Totals [nba_pbt]:
scrape <- "http://stats.nba.com/stats/leaguedashplayerstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=2015-16&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=" %>% 
  read_html() %>% 
  html_text() %>% 
  fromJSON()
head_nba <- scrape$resultSets$headers[1][[1]]
stats_nba <- as.data.frame(scrape$resultSets$rowSet)
names(stats_nba) <- head_nba
stats_nba <- as_data_frame(stats_nba)


nba_pbt <- list()

for (yr_start in 1996:2017) {
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)
  
  scrape <- paste0("http://stats.nba.com/stats/leaguedashplayerstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end, "&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=") %>%
    read_html() %>%
    html_text() %>%
    fromJSON()
  head_nba <- tolower(scrape$resultSets$headers[1][[1]])
  stats_nba <- as.data.frame(scrape$resultSets$rowSet)
  names(stats_nba) <- head_nba
  stats_nba <- as_data_frame(stats_nba)
  
  # add year to data each time through
  # if per 100, switch minutes to total
  # switching to numeric from factor? how to know which columns?
  
  cols1 <- c(1, 3:55)
  stats_nba[, cols1] <- map(stats_nba[, cols1], function(x) as.numeric(as.character(x)))
  cols2 <- c(2, 56)
  stats_nba[, cols2] <- map(stats_nba[, cols2], function(x) as.character(x))
  stats_nba <- add_column(stats_nba, YEAR = yr_start + 1, .before = "team_abbreviation")
  nba_pbt[[yr_end]] <- stats_nba
} 

nba_pbt <- bind_rows(nba_pbt)

write_csv(nba_pbt, path = "/Users/fordhiggins/basketball/Analytics/data/nba_pbt.csv")

# NBA Player Basic P100 [nba_pbp100]:

# NBA Player Basic Advanced [nba_pba]: 
scrape <- "http://stats.nba.com/stats/leaguedashplayerstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Advanced&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=2017-18&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=" %>% 
  read_html() %>% 
  html_text() %>% 
  fromJSON()
head_nba <- scrape$resultSets$headers[1][[1]]
stats_nba <- as.data.frame(scrape$resultSets$rowSet)
names(stats_nba) <- head_nba
nba_padv <- as_data_frame(stats_nba)

# NBA Team Basic Totals [nba_tbt]:
nba_tbt <- list()

for (yr_start in 1996:2017) {
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)
  
  scrape <- paste0("http://stats.nba.com/stats/leaguedashteamstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end, "&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=") %>%
    read_html() %>%
    html_text() %>%
    fromJSON()
  head_nba <- scrape$resultSets$headers[1][[1]]
  stats_nba <- as.data.frame(scrape$resultSets$rowSet)
  names(stats_nba) <- head_nba
  stats_nba <- as_data_frame(stats_nba)
  
  # add year to data each time through
  # if per 100, switch minutes to total
  # switching to numeric from factor? how to know which columns?
  
  cols1 <- c(1, 3:55)
  stats_nba[, cols1] <- map(stats_nba[, cols1], function(x) as.numeric(as.character(x)))
  cols2 <- c(2, 56)
  stats_nba[, cols2] <- map(stats_nba[, cols2], function(x) as.character(x))
  stats_nba <- add_column(stats_nba, YEAR = yr_start + 1, .before = "TEAM_NAME")
  nba_tbt[[yr_end]] <- stats_nba
} 

nba_tbt <- bind_rows(nba_tbt)

write_csv(nba_tbt, path = "/Users/fordhiggins/basketball/Analytics/data/nba_tbt.csv")

# NBA Team Basic P100:

# NBA Team Advanced Totals

nba_tadv <- list()

# Single season:
scrape <- "http://stats.nba.com/stats/leaguedashteamstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Advanced&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=2016-17&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=" %>% 
  read_html() %>% 
  html_text() %>% 
  fromJSON()

head_nba_tadv <- scrape$resultSets$headers[1][[1]]
stats_nba_tadv <- as.data.frame(scrape$resultSets$rowSet)
names(stats_nba_tadv) <- head_nba_tadv
stats_nba_tadv <- as_data_frame(stats_nba_tadv)

# Multi season:
for (yr_start in 1996:2016) {
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)
  
  scrape <- paste0("http://stats.nba.com/stats/leaguedashteamstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Advanced&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end, "&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=") %>%
    read_html() %>%
    html_text() %>%
    fromJSON()
  head_nba_tadv <- scrape$resultSets$headers[1][[1]]
  stats_nba_tadv <- as.data.frame(scrape$resultSets$rowSet)
  names(stats_nba_tadv) <- head_nba_tadv
  stats_nba_tadv <- as_data_frame(stats_nba_tadv)
  
  # add year to data each time through
  # if per 100, switch minutes to total
  # switching to numeric from factor? how to know which columns?
  
  cols1 <- c(1, 3:41)
  stats_nba_tadv[, cols1] <- map(stats_nba_tadv[, cols1], function(x) as.numeric(as.character(x)))
  cols2 <- c(2, 42)
  stats_nba_tadv[, cols2] <- map(stats_nba_tadv[, cols2], function(x) as.character(x))
  stats_nba_tadv <- add_column(stats_nba_tadv, YEAR = yr_start + 1, .before = "TEAM_NAME")
  nba_tadv[[yr_end]] <- stats_nba_tadv
} 

nba_tadv <- bind_rows(nba_tadv)

write_csv(nba_tbt, path = "/Users/fordhiggins/basketball/Analytics/data/nba_tadv.csv")


# NBADL Team Basic Totals:

#nbdl_tbt <- as_data_frame(matrix(ncol = 57, nrow = 0))
nbadl_tbt <- list()

for (yr_start in 2007:2017) {
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)
  
  scrape <- paste0("http://stats.nbadleague.com/stats/leaguedashteamstats?Conference=&DateFrom=&DateTo=&GameScope=&GameSegment=&LastNGames=0&LeagueID=20&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end, "&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=") %>%
    read_html() %>%
    html_text() %>%
    fromJSON()
  head_nbadl <- scrape$resultSets$headers[1][[1]]
  stats_nbadl <- as.data.frame(scrape$resultSets$rowSet)
  names(stats_nbadl) <- head_nbadl
  stats_nbadl <- as_data_frame(stats_nbadl)
  
  # add year to data each time through
  # if per 100, switch minutes to total
  # switching to numeric from factor? how to know which columns?
  
  cols1 <- c(1, 3:55)
  stats_nbadl[, cols1] <- map(stats_nbadl[, cols1], function(x) as.numeric(as.character(x)))
  cols2 <- c(2, 56)
  stats_nbadl[, cols2] <- map(stats_nbadl[, cols2], function(x) as.character(x))
  stats_nbadl <- add_column(stats_nbadl, YEAR = yr_start + 1, .before = "TEAM_NAME")
  nbadl_tbt[[yr_end]] <- stats_nbadl
  # nbdl_tbt <- bind_rows(nbdl_tbt, stats_nba)
} 

nbadl_tbt <- bind_rows(nbadl_tbt)

write_csv(nbadl_tbt, path = "/Users/fordhiggins/basketball/Analytics/data/nbadl_tbt.csv")

# NBADL Player Basic Totals:

nbadl_pbt <- tibble()

for (yr_start in 2007:2017) {
  Sys.sleep(3)
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)

  url_totals <- paste0("http://stats.nbadleague.com/stats/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=",
                       "&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=20&Location=&MeasureType=Base&Month=",
                       "0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=",
                       "N&Rank=N&Season=", as.character(yr_start), "-", yr_end,"&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=",
                       "&VsDivision=&Weight=")
  url_totals <- fromJSON(url_totals)
  head_totals <- tolower(url_totals$resultSets$headers[1][[1]])
  stats_totals <- as.data.frame(url_totals$resultSets$rowSet)
  names(stats_totals) <- head_totals
  stats_totals %<>% select(1:34)
  
  cols1 <- c(1, 3, 5:34)
  stats_totals[, cols1] <- map(stats_totals[, cols1], function(x) as.numeric(as.character(x)))
  cols2 <- c(2, 4)
  stats_totals[, cols2] <- map(stats_totals[, cols2], function(x) as.character(x))
  stats_totals <- add_column(stats_totals, year = yr_start + 1, .before = "team_abbreviation")
  nbadl_pbt <- bind_rows(nbadl_pbt, stats_totals)
}

write_csv(nbadl_pbt, path = "/Users/fordhiggins/basketball/Analytics/data/nbadl_pbt.csv")

# NBADL Player Per100:
nbadl_pp100 <- tibble()

for (yr_start in 2007:2017) {
  Sys.sleep(3)
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)
  
  url_per100 <- paste0("http://stats.nbadleague.com/stats/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=",
                       "&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=20&Location=&MeasureType=Base",
                       "&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Per100Possessions&Period=0&PlayerExperience=",
                       "&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end,"&SeasonSegment=",
                       "&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=&Weight=")
  url_per100 <- fromJSON(url_per100)
  head_per100 <- tolower(url_per100$resultSets$headers[1][[1]])
  stats_per100 <- as.data.frame(url_per100$resultSets$rowSet)
  names(stats_per100) <- head_per100
  stats_per100 %<>%  select(1:34)

  cols1 <- c(1, 3, 5:34)
  stats_per100[, cols1] <- map(stats_per100[, cols1], function(x) as.numeric(as.character(x)))
  cols2 <- c(2, 4)
  stats_per100[, cols2] <- map(stats_per100[, cols2], function(x) as.character(x))
  stats_per100 <- add_column(stats_per100, year = yr_start + 1, .before = "team_abbreviation")
  nbadl_pp100 <- bind_rows(nbadl_pp100, stats_per100)
}

write_csv(nbadl_pp100, path = "/Users/fordhiggins/basketball/Analytics/data/nbadl_pp100.csv")


# NBADL Player Advanced:
nbadl_padv <- tibble()

for (yr_start in 2007:2017) {
  Sys.sleep(3)
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)
  
  url_adv <- paste0("http://stats.nbadleague.com/stats/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=",
                       "&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=20&Location=&MeasureType=Advanced",
                       "&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Totals&Period=0&PlayerExperience=",
                       "&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end,"&SeasonSegment=",
                       "&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=&Weight=")
  url_adv <- fromJSON(url_adv)
  head_adv <- tolower(url_adv$resultSets$headers[1][[1]])
  stats_adv <- as.data.frame(url_adv$resultSets$rowSet)
  names(stats_adv) <- head_adv
  stats_adv %<>%  select(1:34)
  
  cols1 <- c(1, 3, 5:34)
  stats_adv[, cols1] <- map(stats_adv[, cols1], function(x) as.numeric(as.character(x)))
  cols2 <- c(2, 4)
  stats_adv[, cols2] <- map(stats_adv[, cols2], function(x) as.character(x))
  stats_adv <- add_column(stats_adv, year = yr_start + 1, .before = "team_abbreviation")
  nbadl_padv <- bind_rows(nbadl_padv, stats_adv)
}

# for Daniel Alexander
nbadl_padv <- replace_na(nbadl_padv, list(player_id = 1627000))

write_csv(nbadl_padv, path = "/Users/fordhiggins/basketball/Analytics/data/nbadl_padv.csv")
