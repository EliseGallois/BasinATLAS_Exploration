# Packages required for app ----
library(tidyverse) # for data cleaning and plotting
library(sf) # for spatial data
library(shiny) # to create shiny app
library(viridis) # for colourblind friendly visualisation
library(leaflet) # for interactive mapping

# Loading Data ----
canada_lvl6 <- readRDS("canada_lvl6.rds")

# prepare data for barplot
summary_data <- canada_lvl6 %>%
  st_drop_geometry() %>%
  group_by(glc_pc_s06) %>%
  summarise(mean_runoff = mean(run_mm_syr, na.rm = TRUE)) %>%
  arrange(desc(mean_runoff))

# ui ----
ui <- fluidPage(
  titlePanel("Land surface run-off and land cover types in Canada (Basin map level 6)"),
  
  tags$style(type = "text/css", "
    #mapPlot {height: 500px; width: 100%; margin-bottom: 200px;}
    #landUsePlot {height: 400px; width: 100%;}
  "),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("layer", "Select Layer:", 
                  choices = c("runoff" = "runoff", "land use" = "land_use"))
    ),
    mainPanel(
      imageOutput("mapPlot"),   
      plotOutput("landUsePlot", height = "600px")  
    )
  )
)

# server ----
server <- function(input, output) {
  
  output$mapPlot <- renderImage({
    if (input$layer == "runoff") {
      list(src = "figures/canada_runoff_plot.png", 
           contentType = 'image/png',
           width = 600, height = 600,  
           alt = "Canada Runoff Map")
    } else {
      list(src = "figures/canada_landuse_plot.png", 
           contentType = 'image/png',
           width = 600, height = 600, 
           alt = "Canada Land Use Map")
    }
  }, deleteFile = FALSE)  
  
  output$landUsePlot <- renderPlot({
    ggplot(summary_data, aes(x = reorder(glc_pc_s06, mean_runoff), y = mean_runoff)) +
      geom_bar(stat = "identity", aes(fill = mean_runoff), show.legend = FALSE) +
      scale_fill_viridis(direction = -1) +  
      coord_flip() +
      theme_minimal() +
      labs(x = "Land Use Classification", 
           y = "Mean Land Surface Runoff (mm/yr)", 
           title = "Average Land Surface Runoff by Land Use Type")
  })
}

# initialise application ----
shinyApp(ui = ui, server = server)
