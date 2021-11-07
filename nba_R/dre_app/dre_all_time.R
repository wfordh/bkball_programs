library(jsonlite)
library(stringr)
library(purrr)
# only pick out necessary tidyverse packages
library(dplyr)
library(tidyr)
library(magrittr)

## All Years

all_years_nba_dre <- tibble()

for (yr_start in 2007:2016) {
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
  
  url_per100 <- paste0("http://stats.nbadleague.com/stats/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=",
                       "&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=20&Location=&MeasureType=Base",
                       "&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Per100Possessions&Period=0&PlayerExperience=",
                       "&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end,"&SeasonSegment=",
                       "&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=&Weight=")
  url_per100 <- fromJSON(url_per100)
  head_per100 <- tolower(url_per100$resultSets$headers[1][[1]])
  stats_per100 <- as.data.frame(url_per100$resultSets$rowSet)
  names(stats_per100) <- head_per100
  stats_per100 <- stats_per100[1:33]
  stats_per100[10] <- stats_totals[10]
  
  cols <- c(5:33)
  stats_per100[, cols] <- map(stats_per100[, cols], function(x) as.numeric(as.character(x)))
  stats_per100[10] <- round(stats_per100[10], 2)
  
  stats_w_dre <- nba_dre(stats_per100)
  stats_w_dre <- bind_cols(year = replicate(nrow(stats_w_dre), yr_start+1), 
                           stats_w_dre)
  #names(stats_w_dre)[names(stats_w_dre) == 'yr_start + 1'] <- 'YEAR'
  all_years_nba_dre <- bind_rows(all_years_nba_dre, stats_w_dre)
}

write_csv(all_years_nba_dre, path = "/Users/fordhiggins/basketball/Analytics/data/nbadl_dre_all.csv")

# Career D League DRE:
nbadl_pbt <- read_csv("/Users/fordhiggins/basketball/Analytics/data/nbadl_pbt.csv")
nbadl_padv <- read_csv("/Users/fordhiggins/basketball/Analytics/data/nbadl_padv.csv")

# five no name players from 2009. should I figure them out? for now just exclude
nbadl_pbt %<>% filter(is.na(player_name)==F)
nbadl_padv %<>% filter(is.na(player_name)==F)
nbadl_pbt <- replace_na(nbadl_pbt, list(player_id = 1627000))
nbadl_padv <- replace_na(nbadl_padv, list(player_id = 1627000))
nbadl_pbt[nbadl_pbt$player_name == 'Gutierrez Jorge', "player_name"] <- 'Jorge Gutierrez'
nbadl_padv[nbadl_padv$player_name == 'Gutierrez Jorge', "player_name"] <- 'Jorge Gutierrez'
nbadl_pbt[nbadl_pbt$player_id == 163525718, "player_id"] <- 203268
nbadl_padv[nbadl_padv$player_id == 163525718, "player_id"] <- 203268
nbadl_pbt[nbadl_pbt$player_id == 1700000021, "player_id"] <- 1628686
nbadl_padv[nbadl_padv$player_id == 1700000021, "player_id"] <- 1628686
nbadl_pbt[nbadl_pbt$player_id == 1962936959, "player_id"] <- 1627592
nbadl_padv[nbadl_padv$player_id == 1962936959, "player_id"] <- 1627592
nbadl_pbt[nbadl_pbt$player_id == 269009, "player_id"] <- 203473
nbadl_padv[nbadl_padv$player_id == 269009, "player_id"] <- 203473
nbadl_pbt[nbadl_pbt$player_id == 1962937364, "player_id"] <- 202962
nbadl_padv[nbadl_padv$player_id == 1962937364, "player_id"] <- 202962
nbadl_pbt[nbadl_pbt$player_id == 1962937369, "player_id"] <- 1627232
nbadl_padv[nbadl_padv$player_id == 1962937369, "player_id"] <- 1627232
nbadl_pbt[nbadl_pbt$player_id == 1962937360, "player_id"] <- 203512
nbadl_padv[nbadl_padv$player_id == 1962937360, "player_id"] <- 203512
nbadl_pbt[nbadl_pbt$player_id == 204259, "player_id"] <- 203940
nbadl_padv[nbadl_padv$player_id == 204259, "player_id"] <- 203940
nbadl_pbt[nbadl_pbt$player_id == 1962936933, "player_id"] <- 202805
nbadl_padv[nbadl_padv$player_id == 1962936933, "player_id"] <- 202805
nbadl_pbt[nbadl_pbt$player_id == 1962936946, "player_id"] <- 204215
nbadl_padv[nbadl_padv$player_id == 1962936946, "player_id"] <- 204215
nbadl_pbt[nbadl_pbt$player_id == 832964432, "player_id"] <- 203360
nbadl_padv[nbadl_padv$player_id == 832964432, "player_id"] <- 203360
nbadl_pbt[nbadl_pbt$player_id == 39320, "player_id"] <- 204081
nbadl_padv[nbadl_padv$player_id == 39320, "player_id"] <- 204081
nbadl_pbt[nbadl_pbt$player_id == 1962936937, "player_id"] <- 204289
nbadl_padv[nbadl_padv$player_id == 1962936937, "player_id"] <- 204289
nbadl_pbt[nbadl_pbt$player_id == 1962936920, "player_id"] <- 204262
nbadl_padv[nbadl_padv$player_id == 1962936920, "player_id"] <- 204262
nbadl_pbt[nbadl_pbt$player_id == 3259651, "player_id"] <- 203523
nbadl_padv[nbadl_padv$player_id == 3259651, "player_id"] <- 203523
nbadl_pbt[nbadl_pbt$player_name == "BJ Young" & nbadl_pbt$age == 21, "player_name"] <- "B.J. Young"
nbadl_padv[nbadl_padv$player_name == "BJ Young" & nbadl_padv$age == 21, "player_name"] <- "B.J. Young"
nbadl_pbt[nbadl_pbt$player_id == 203523 & nbadl_pbt$age == 114, "age"] <- 21
nbadl_padv[nbadl_padv$player_id == 203523 & nbadl_padv$age == 114, "age"] <- 21
nbadl_pbt[nbadl_pbt$player_id == 1962936816, "player_id"] <- 203609
nbadl_padv[nbadl_padv$player_id == 1962936816, "player_id"] <- 203609
nbadl_pbt[nbadl_pbt$player_id == 664328, "player_id"] <- 202077
nbadl_padv[nbadl_padv$player_id == 664328, "player_id"] <- 202077
nbadl_pbt[nbadl_pbt$player_id == 1962936822, "player_id"] <- 203818
nbadl_padv[nbadl_padv$player_id == 1962936822, "player_id"] <- 203818
nbadl_pbt[nbadl_pbt$player_id == 1962936824, "player_id"] <- 203819
nbadl_padv[nbadl_padv$player_id == 1962936824, "player_id"] <- 203819
nbadl_pbt[nbadl_pbt$player_id == 2445, "player_id"] <- 200963
nbadl_padv[nbadl_padv$player_id == 2445, "player_id"] <- 200963
nbadl_pbt[nbadl_pbt$age == 109 & nbadl_pbt$player_id == 200963, "age"] <- 27
nbadl_padv[nbadl_padv$age == 109 & nbadl_padv$player_id == 200963, "age"] <- 27

# necessary changes:
# CTN 2015 gutierrez jorge 163525718 --> jorge gutierrez 203268
# SCW 2018 winston shepard: 1700000021 --> 1628686
# DEL 2016 davon usher: 1962936959 --> 1627592
# ERI 2016 dewayne dedmon: 269009 --> 203473
# RAP 2016 greg smith: 1962937364 --> 202962
# RAP 2016 john jordan: 1962937369 --> 1627232
# RAP 2016 lucas nogueira: 1962937360 --> 203512
# AUS 2015 adreian payne: 204259 --> 203940
# SCW 2015 anthony vereen: 1962936933 --> 202805
# SXF 2015 bubu palo: 1962936946 --> 204215
# SCW 2015 dominique sutton: 832964432 --> 203360
# WCK 2015 jordan vandenberg: 39320 --> 204081
# IDA 2015 nick wiggins: 1962936937 --> 204289
# IDA 2015 ta'quan zimmerman: 1962936920 --> 204262
# CTN 2015 travis mckie: 1962936945 --> 204287
# DEL 2014 b.j. young 3259651 --> bj young 203523
# AUS 2014 greg gantt: 1962936816 --> 203609
# BAK 2014 jerel mcneal: 664328 --> 202077
# MNE 2014 julian mavunga: 1962936822 --> 203818
# SCW 2014 karron johnson: 1962936824 --> 203819
# ANA 2009 marcus taylor: id 2445 --> 200963 age 27 <-- 109


# gp, w, l, min, fgm, fga, fg3m, fg3a, ftm, fta, oreb, dreb, reb, ast, tov, stl, blk, blka
# pf, pfd, pts, plus_minus
# Create myself:
# fg_pct, fg3_pct, ft_pct, fg2m, fg2a, fg2_pct

pace <- nbadl_padv %>% select(player_id, year, pace)

# pbt = player basic totals

nbadl_pbt_car <- tibble()
nbadl_pbt_car <- nbadl_pbt %>% 
  group_by(player_id) %>%
  left_join(pace, by = c("player_id", "year")) %>% 
  transmute(player_name = player_name,
            gp = sum(gp), w = sum(w), l = sum(l), poss = sum(min*pace/48), min = sum(min),
            fgm = sum(fgm), fga = sum(fga), fg3m = sum(fg3m), fg3a = sum(fg3a),
            ftm = sum(ftm), fta = sum(fta), oreb = sum(oreb), dreb = sum(dreb),
            reb = sum(reb), ast = sum(ast), tov = sum(tov), stl = sum(stl), 
            blk = sum(blk), blka = sum(blka), pf = sum(pf), pfd = sum(pfd), 
            pts = sum(pts), plus_minus = sum(plus_minus), 
            fg_pct = if_else(fga == 0, 0, fgm/as.numeric(fga)),
            fg3_pct = if_else(fg3a == 0, 0, fg3m/as.numeric(fg3a)),
            ft_pct = if_else(ftm == 0, 0, ftm/as.numeric(fta)),
            fg2m = fgm - fg3m, fg2a = fga - fg3a,
            fg2_pct = if_else(fg2a == 0, 0, fg2m/as.numeric(fg2a))
  ) %>% 
  distinct(player_id, .keep_all = T)


nbadl_pp100_car <- nbadl_pbt_car
# player per 100 possessions columns
pp100_cols <- c(8:25, 29:30)

# need to find total possession for each year first
nbadl_pp100_car[pp100_cols] <- map(nbadl_pbt_car[pp100_cols],
                                   function(x) 100*x/nbadl_pbt_car$poss)
# need to generalize dre function? add some error handling?
nbadl_dre_car <- nba_dre(nbadl_pp100_car)
write_csv(nbadl_dre_car, path = "/Users/fordhiggins/basketball/Analytics/data/nbadl_dre_car.csv")

# figure out how to handle players whose ages are over 100 - their player IDs don't match 
# with themselves (check Anthony Vereen)

# to get seasons played, use group_by/summarise on nbadl_pbt and then left join by player id
# onto nbadl_pbt_car

