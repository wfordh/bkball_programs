library(shiny)
# save data when year is done so it can be pulled from there instead of re-calling the 
# functions over and over
# REMEMBER TO RE-PUBLISH AFTER MAKING ANY CHANGES
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
			p(HTML("<b>DRE:</b> "), a(href="https://fansided.com/2017/04/10/updating-dre-tweaks/", "DRE"), "was developed by Kevin Ferrigan (", 
			         a(href="https://twitter.com/NBACouchside", "@NBACouchside"),
			  ") and attempts to model NBA RAPM with box score statistics. While the G League
				is similar to the NBA, it is not the same league and the resulting coefficients are not
				the best fit. All DRE numbers are therefore rough estimates."
			  ),
	    p(
				HTML("<b>Shooting:</b> "), "Relative TS and eFG% are calculated as player stat / league avg stat. The G League 
				introduced rule changes in the 2019-20 season where players shot one free throw on each trip to 
				the foul line for the corresponding number of points instead of one free throw per point.
				This impacts the coefficient used for estimating TS% and seasons with the new rules
				use 0.692 instead of the typical 0.44. This an estimate and may cause small differences 
				between the 'real' and displayed relative TS%."
			),
      p(
        HTML("<b>Minutes</b>: "), "The default minutes minimum is 200 and those under 200 minutes played are regressed to
				-2. You may adjust the minutes minimum from 0 to 1000 in steps of 50 minutes."
      ),
			p(HTML("<b>STK</b>: "), "Stk is stocks aka blocks plus steals, and is on a per 100 possession basis instead of a
				percentage basis."),
			p("Last updated: 12/12/21")
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
			),
			sliderInput("Age",
			   label = "Choose player age range",
			   min = 17, max = 40,
			   value = c(17, 40)
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
	  #get_gleague_dre_stats(as.numeric(input$Year), save_dre = T)
		read.csv(
		  paste0("./data/nbadl_dre_", as.character(input$Year), "-", substr(as.character(as.integer(input$Year)+1), 3, 4), ".csv")
		  ) %>%
	    dplyr::arrange(desc(dre)) %>% 
		  dplyr::filter(min > input$Minutes, between(age, input$Age[1], input$Age[2]))
	})
	}


# Run app
shinyApp(ui, server)
