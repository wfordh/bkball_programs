library(jsonlite)
library(stringr)
#nba.com only goes back to 96-97. use bref instead? 

url <- "http://stats.nba.com/stats/leaguedashteamstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=PerGame&Period=0&PlayerExperience=&PlayerPosition=&PlusMinus=N&Rank=N&Season=2014-15&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision="
url <- fromJSON(url)
head <- url$resultSets$headers[1][[1]]
stats <- as.data.frame(url$resultSets$rowSet)
names(stats) <- head

stats$W_PCT <- as.numeric(levels(stats$W_PCT))[stats$W_PCT]
var(stats$W_PCT)

# code below should run through each year and create a table
# for each, but will overwrite the previous one each time, so
# need to save relevant info somewhere else where it won't be
# overwritten

winvar_table <- data.frame(x<-as.character(), y<-as.numeric(), z<-as.numeric())
winvar_names <- c("Year", "WPct_Var", "Wins_Var")

for (yr_start in 1996:2015){
  yr_end <- str_sub(as.character(yr_start + 1), 3, 4)
  
  url <- paste("http://stats.nba.com/stats/leaguedashteamstats?Conference=&DateFrom=&DateTo=&Division=&GameScope=&GameSegment=&LastNGames=0&LeagueID=00&Location=",
    "&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PORound=0&PaceAdjust=N&PerMode=PerGame&Period=0&PlayerExperience=",
    "&PlayerPosition=&PlusMinus=N&Rank=N&Season=", as.character(yr_start), "-", yr_end,
    "&SeasonSegment=&SeasonType=Regular+Season&ShotClockRange=&StarterBench=&TeamID=0&VsConference=&VsDivision=", sep = "")

  url <- fromJSON(url)
  head <- url$resultSets$headers[1][[1]]
  stats <- as.data.frame(url$resultSets$rowSet)
  names(stats) <- head
  
  stats$W_PCT <- as.numeric(levels(stats$W_PCT))[stats$W_PCT]
  wp_var <- var(stats$W_PCT)
  stats$W <- as.numeric(levels(stats$W))[stats$W]
  win_var <- var(stats$W)
  newdata <- c(yr_start + 1, wp_var, win_var)
  winvar_table <- rbind(winvar_table, newdata)
}

names(winvar_table) <- winvar_names
head(winvar_table)

qplot(winvar_table$Year, winvar_table$WPct_Var, data = winvar_table, geom = "line", main = "Variance of Win Pct in NBA (Last 20 Years)", xlab = "Year", ylab = "Variance of Win Pct")
qplot(winvar_table$Year, winvar_table$Wins_Var, data = winvar_table, geom = "line", main = "Variance of Wins in NBA (Last 20 Years)", xlab = "Year", ylab = "Variance of Wins")

# same idea, but bin by wins/win% and make bar graph?