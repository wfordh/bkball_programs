library(jsonlite)
library(stringr)
library(purrr)
library(readr)
# only pick out necessary tidyverse packages
library(dplyr)
library(magrittr)
library(progress)
library(httr)

get_nba_stats_json <- function(url) {
  headers <- c(
    `Host` = 'stats.nba.com',
    `User-Agent` = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36',
    `Accept` = 'application/json, text/plain, */*',
    `Accept-Language` = 'en-US,en;q=0.5',
    `Accept-Encoding` = 'gzip, deflate, br',
    `x-nba-stats-origin` = 'stats',
    `x-nba-stats-token` = 'true',
    `Connection` = 'keep-alive',
    `Origin` = "http://stats.nba.com",
    `Referer` = 'https://www.nba.com/',
    `Pragma` = 'no-cache',
    `Cache-Control` = 'no-cache'
  )
  
  res <- httr::RETRY("GET", url,
                     httr::add_headers(.headers = headers))
  
  stats_json <- res$content %>%
    rawToChar() %>%
    jsonlite::fromJSON(simplifyVector = T)
  
  return(stats_json)
}

nba_json2df <- function(stats_json) {
  head_nba <- stats_json$resultSets$headers[1][[1]]
  stats_nba <- as.data.frame(stats_json$resultSets$rowSet)
  names(stats_nba) <- tolower(head_nba)
  stats_nba <- as_tibble(stats_nba)
  
  return(stats_nba)
}

nba_dre <- function(df, minutes_regression = 200) {
  # Check if minutes over 200 for mean regression
  # new eqn: -8.424 + .792*pts - .719*2pa - .552*3pa - .159*fta + .135*orb + .400*drb
  # + .544*ast + 1.68*stl + .764*blk - 1.36*tov - .108*pf
  # No adjustment for post-2019 free throw rule change
  
  df %<>% mutate(
    fg2a = fga - fg3a,
    dre = if_else(
      min > minutes_regression,-8.424 + .792 * pts - .719 * fg2a - .552 * fg3a - .159 *
        fta - 1.36 * tov
      + .135 * oreb + .4 * dreb + 1.68 * stl + .764 *
        blk + .544 * ast - .108 * pf,-2.0 * (400 - min) / 400 + (min / 400) * (
          -8.424 + .792 * pts - .719 * fg2a - .552 * fg3a
          - .159 *
            fta - 1.36 * tov + .135 * oreb + .4 * dreb
          + 1.68 *
            stl + .764 * blk + .544 * ast - .108 * pf
        )
    )
  )
  
  # pts = 30. reb = 22. stl = 25. blk = 26. ast = 23. fga = 12. fta = 18. tov = 24. pf = 28.
  #colnames(dre) <- "dre"
  #df <- cbind(df, dre)
}

get_lg_efg <- function(player_stats) {
  return(
    player_stats %>%
      select(c("fga", "fgm", "fg3m")) %>%
      summarise_all(sum) %>%
      transmute(lg_efg = 100.0 * (fgm + 0.5 * fg3m) / fga)
  )
}

get_lg_ts <- function(player_stats, year) {
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
             100.0 * pts / (2 * (fga + 0.692 * fta)),
             100.0 * pts / (2 * (fga + 0.44 * fta))
           )))
}

# SPR formula (All per-100 except GS%)

# PTS-1.2*TOV+0.7*BLK+1.5*STL+0.5*AST+0.2*DRB+0.3*ORB-0.3*FTA- 2PA - 0.8*3PA + GamesStarted% x 2.2 - 7.9
# GamesStarted would need to be scraped from basketball-reference

# do I need the below stuff? can now just read in most of it
# stats go back to 07-08


# Other things to add to table: rel eFG%, PER? plus minus?
# remove all the per 100 numbers?
# try to get games started from the box scores?

get_gleague_dre_stats <-
  function(year,
           save_dre = TRUE,
           minutes_limit = 0) {
    season <-
      paste0(as.character(year), "-", substr(as.character(year + 1), 3, 4))
    # placeholder for now.
    # 2021-22 RS starts on Dec 27
    # will need to pull the "Advanced" numbers as well to get pace
    # can do pace * min to get total possessions and then do weighted average to get to per 100 poss?
    if (year > 2020) {
      season_type <- "Showcase"
    } else {
      season_type <- "Regular+Season"
    }
    url_totals <-
      paste0(
        "http://stats.nba.com/stats/leaguedashplayerstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=",
        "&LastNGames=0&LeagueID=20&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N",
        "&PerMode=Totals&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=",season,"&SeasonSegment=",
        "&SeasonType=", season_type, "&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision="
      )
    totals_json <- get_nba_stats_json(url_totals)
    stats_totals <- nba_json2df(totals_json)
    
    url_per100 <-
      paste0(
        "http://stats.nba.com/stats/leaguedashplayerstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=",
        "&LastNGames=0&LeagueID=20&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N",
        "&PerMode=Per100Possessions&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=",season,"&SeasonSegment=",
        "&SeasonType=", season_type, "&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision="
        #"http://stats.nbadleague.com/stats/leaguedashplayerstats?College=&Conference=&Country=&DateFrom=&DateTo=",
        #"&DraftPick=&DraftYear=&GameScope=&GameSegment=&Height=&LastNGames=0&LeagueID=20&Location=&MeasureType=Base",
        #"&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=Per100Possessions&Period=0&PlayerExperience=",
        #"&PlayerPosition=&PlusMinus=N&Rank=N&Season=",
        #season,
        #"&SeasonSegment=&SeasonType=",
        #season_type,
        #"&ShotClockRange=",
        #"&StarterBench=&TeamID=0&VsConference=&VsDivision=&Weight="
      )
    per100_json <- get_nba_stats_json(url_per100)
    stats_per100 <- nba_json2df(per100_json)
    
    # Overwrite per 100 minutes with total minutes
    stats_per100[10] <- stats_totals[10]
    
    cols <- c(5:33)
    stats_per100[, cols] <-
      map(stats_per100[, cols], function(x)
        as.numeric(as.character(x)))
    ## OR stats[, cols] <- as.numeric(as.character(unlist(stats[, cols])))
    stats_per100[10] <- round(stats_per100[10], 2)
    stats_per100 %<>% dplyr::filter(min >= minutes_limit)
    
    dre_stats <- nba_dre(stats_per100)
    
    lg_ts <- get_lg_ts(dre_stats, year = year)$lg_ts
    lg_efg <- get_lg_efg(dre_stats)$lg_efg
    
    dre_stats %<>%
      mutate(
        efg = 100.0 * (fgm + 0.5 * fg3m) / fga,
        rel_efg = 100.0 * (efg / lg_efg),
        # / lg_efg,
        stk = blk + stl
      )
    if (year >= 2019) {
      dre_stats %<>%
        mutate(ts = 100.0 * (pts / (2 * (fga + 0.692 * fta))),
               rel_ts = 100.0 * (ts / lg_ts)) #/ lg_ts)
    } else {
      dre_stats %<>%
        mutate(ts = 100.0 * (pts / (2 * (fga + 44 * fta))),
               rel_ts = 100.0 * (ts / lg_ts)) #/ lg_ts)
    }
    
    dre_stats %<>% select(
      c(
        "player_name",
        "team_abbreviation",
        "age",
        "gp",
        "min",
        "dre",
        "efg",
        "rel_efg",
        "ts",
        "rel_ts",
        "stk",
        "plus_minus"
      )
    )
    
    dre_stats$min <- round(dre_stats$min)
    dre_stats$dre <- round(dre_stats$dre, 2)
    dre_stats$efg <- round(dre_stats$efg, 2)
    dre_stats$rel_efg <- round(dre_stats$rel_efg, 2)
    dre_stats$ts <- round(dre_stats$ts, 2)
    dre_stats$rel_ts <- round(dre_stats$rel_ts, 2)
    
    if (save_dre) {
      write.csv(
        dre_stats,
        file = paste0(
          "~/basketball/analytics/bkball_programs/nba_R/dre_app/data/nbadl_dre_",
          season,
          ".csv"
        ),
        row.names = F
      )
      print(paste0("DRE for ", season, " saved!"))
    }
    
    return(dre_stats)
  }

args <- commandArgs(trailingOnly = T)

if (length(args) > 1) {
  print(args)
  year <- as.integer(format(Sys.Date(), "%Y"))
  print(year)
  dre_stats <- get_gleague_dre_stats(year, save_dre = T)
}
