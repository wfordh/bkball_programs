
# save data when year is done so it can be pulled from there instead of re-calling the 
# functions over and over
source("dre_calc.R")

# will need to update logic for beginning of next season
current_year <- as.integer(format(Sys.Date(), "%Y")) - 1

# User Interface
ui <- fluidPage(
	titlePanel("G League DRE"),

	sidebarLayout(
		sidebarPanel(
			helpText("
				G League DRE and other statistics by year. DRE was developed by Kevin Ferrigan (@nbacouchside)
				and attempts to model NBA RAPM with box score statistics. Therefore, while the G League
				is similar to the NBA, it is not the same league and so the coefficients used are not
				necessarily the best fitting and the end numbers should be seen as rough estimates.

				Relative TS and eFG% are also provided. The G League introduced a new rule for the 2019-20
				season where players shot one free throw on each trip to the foul line for the
				corresponding number of points instead of one free throw per point. For example, a player
				fouled on a layup attempt who misses the field goal attempt will attempt one free throw
				for 2 points. This rule change impacts the coefficient used for estimating TS%, and so
				seasons before the rule change use the old 0.44 coefficient and those with the rule change
				use 0.692. Again, that coefficient is an estimate and not derived from the play by play data,
				and so it may result in small differences between the 'real' and displayed relative TS%.

				All players are displayed by default and those under 200 minutes played are regressed to
				-2. I hope to provide functionality for adjusting minutes minimums and regression minute
				minimums in the future.

				Stk is stocks aka blocks plus steals, and is on a per 100 possession basis instead of a
				percentage basis.
				"),
			selectInput("Year",
				label = "Choose season, where year corresponds to year the season started, eg 2019 means the 2019-20 season.",
				choices = c(2007:current_year),
				selected = current_year
			)
		),

	mainPanel(
		dataTableOutput("view")
		)
	)
)

# Server logic
server <- function(input, output) {
	output$view <- renderDataTable({
	  #get_gleague_dre_stats(input$Year, save_dre = F)
		read.csv(
		  paste0("./data/nbadl_dre_", as.character(input$Year), "-", substr(as.character(as.integer(input$Year)+1), 3, 4), ".csv")
		  )
	})
	}


# Run app
shinyApp(ui, server)