library(shiny)
library(ggplot2)
library(ggthemes)

# Define UI for the Shiny App
ui <- fluidPage(
  titlePanel("Correlation Coefficient (r), Scatterplot, and Regression Line"),
  sidebarLayout(
    sidebarPanel(
      sliderInput(
        inputId = "correlation",
        label = "Select Correlation Coefficient (r):",
        min = -1,
        max = 1,
        value = 0,
        step = 0.1
      ),
      helpText("Adjust the slider to change the correlation coefficient.")
    ),
    mainPanel(
      plotOutput(outputId = "scatterPlot"),
      textOutput(outputId = "correlationText")
    )
  )
)

# Define server logic for the Shiny App
server <- function(input, output) {
  
  # Generate data based on correlation coefficient
  generate_data <- reactive({
    set.seed(123) # For reproducibility
    n <- 100
    r <- input$correlation
    x <- rnorm(n)
    y <- r * x + sqrt(1 - r^2) * rnorm(n)
    data.frame(x = x, y = y)
  })
  
  # Create scatterplot with regression line
  output$scatterPlot <- renderPlot({
    data <- generate_data()
    
    ggplot(data, aes(x = x, y = y)) +
      geom_point(color = "blue", alpha = 0.6, cex=2) +
      geom_smooth(method = "lm", color = "black", se = FALSE) +
      labs(
        title = "",
        x = "",
        y = ""
      ) +
      theme_clean()
  })
  
}

# Run the Shiny App
shinyApp(ui = ui, server = server)
