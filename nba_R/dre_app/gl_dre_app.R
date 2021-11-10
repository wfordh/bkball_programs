library(shiny)
# save data when year is done so it can be pulled from there instead of re-calling the 
# functions over and over
source("dre_calc.R")

# will need to update logic for beginning of next season
dt <- Sys.Date()
if (as.integer(format(dt, "%m")) > 10) {
    current_year <- as.integer(format(dt, "%Y"))
} else {
    current_year <- as.integer(format(dt, "%Y")) - 1
}

# User Interface
ui <- fluidPage(
	titlePanel("G League DRE"),

	sidebarLayout(
		sidebarPanel(
			helpText(
			p("
				G League DRE and other statistics by year. ", a(href="https://fansided.com/2017/04/10/updating-dre-tweaks/", "DRE"), "was developed by Kevin Ferrigan (", 
			         a(href="https://twitter.com/NBACouchside", "@NBACouchside"),
			  ") and attempts to model NBA RAPM with box score statistics. Therefore, while the G League
				is similar to the NBA, it is not the same league and so the coefficients used are not
				necessarily the best fitting and the end numbers should be seen as rough estimates."
			  ),
	    p(
				"Relative TS and eFG% are provided and calculated as player stat / league avg stat. The G League 
				introduced a new rule for the 2019-20 season where players shot one free throw on each trip to 
				the foul line for the corresponding number of points instead of one free throw per point. For 
				example, a player fouled on a layup attempt who misses the field goal attempt will attempt one 
				free throw for 2 points. This rule change impacts the coefficient used for estimating TS%, and so
				seasons before the rule change use the old 0.44 coefficient and those with the rule change
				use 0.692. The coefficient is an estimate and not derived from the play by play data,
				and so it may result in small differences between the 'real' and displayed relative TS%."
			),
      p(
        "The default minutes minimum is 200 and those under 200 minutes played are regressed to
				-2. You may adjust the minutes minimum from 0 to 1000 in steps of 50 minutes."
      ),
			p("Stk is stocks aka blocks plus steals, and is on a per 100 possession basis instead of a
				percentage basis."),
			), 
			selectInput("Year",
				label = "Choose season, where year corresponds to year the season started, eg 2019 means the 2019-20 season.",
				choices = c(2007:current_year),
				selected = current_year
			),
			sliderInput("Minutes",
				label = "Choose minutes minimum.",
				min = 0, max = 1000,
				value = 200, step = 50
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
		  ) %>%
		dplyr::filter(min > input$Minutes)
	})
	}


# Run app
shinyApp(ui, server)
