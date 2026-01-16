library(shiny)
library(ggplot2)
library(ggthemes)

# Generate fictional population data for male weights (in kg)
set.seed(123)
# Normal distribution
population_weights_normal <- rnorm(10000, mean = 80, sd = 10)
# Right-skewed (gamma) distribution, parameters for more pronounced skew
population_weights_skewed <- rgamma(10000, shape = 10, scale = 5) # mean ≈ 80, sd ≈ 20, skewness ≈ 0.5

# UI
ui <- fluidPage(
  titlePanel("Sampling Male Weights From a Population of 10,000"),
  sidebarLayout(
    sidebarPanel(
      selectInput("sample_size", "Select Sample Size:", 
                  choices = c(10, 100, 200, 500, 1000, 5000, 10000), 
                  selected = 10),
      actionButton("sample_btn", "Take Sample")
    ),
    mainPanel(
      h4("Normal Distribution"),
      tableOutput("stats_table_normal"),
      plotOutput("sample_hist_normal"),
      h4("Right-Skewed (Gamma) Distribution"),
      tableOutput("stats_table_skewed"),
      plotOutput("sample_hist_skewed")
    )
  )
)

# Server
server <- function(input, output) {
  
  # Reactive values to store samples
  sample_data_normal <- reactiveVal()
  sample_data_skewed <- reactiveVal()
  
  # Update samples when button is clicked
  observeEvent(input$sample_btn, {
    sample_size <- as.numeric(input$sample_size)
    sample_data_normal(sample(population_weights_normal, size = sample_size))
    sample_data_skewed(sample(population_weights_skewed, size = sample_size))
  })
  
  # Normal distribution: Calculate and display statistics
  output$stats_table_normal <- renderTable({
    req(sample_data_normal())
    sample_mean <- mean(sample_data_normal())
    sample_sd <- sd(sample_data_normal())
    pop_mean <- mean(population_weights_normal)
    pop_sd <- sd(population_weights_normal)
    
    data.frame(
      Statistic = c("Mean", "Standard Deviation"),
      Sample = c(round(sample_mean, 2), round(sample_sd, 2)),
      Population = c(round(pop_mean, 2), round(pop_sd, 2)),
      Error = c(round(sample_mean - pop_mean, 2), round(sample_sd - pop_sd, 2))
    )
  })
  
  # Normal distribution: Plot sample histogram
  output$sample_hist_normal <- renderPlot({
    req(sample_data_normal())
    ggplot(data.frame(weights = sample_data_normal()), aes(x = weights)) +
      geom_histogram(binwidth = (max(sample_data_normal()) - min(sample_data_normal())) / (1 + 3.322 * log10(length(sample_data_normal()))),
                     fill = "#088F8F", color = "#818589", alpha = 0.3) +
      geom_vline(aes(xintercept = mean(sample_data_normal())), color = "#088F8F", linetype = "dashed", size = 1) +
      geom_vline(aes(xintercept = mean(population_weights_normal)), color = "#818589", linetype = "solid", size = 1) +
      labs(title = "Histogram of Sample Weights (Normal Distribution)",
           x = "Weight (kg)", y = "Frequency") +
      theme_minimal() +
      annotate("text", x = mean(sample_data_normal()) + 5, y = Inf, 
               label = "Sample Mean", color = "#088F8F", vjust = 1) +
      annotate("text", x = mean(population_weights_normal) + 5, y = Inf, 
               label = "Population Mean", color = "#818589", vjust = 2) +
      theme_clean()
  })
  
  # Skewed distribution: Calculate and display statistics
  output$stats_table_skewed <- renderTable({
    req(sample_data_skewed())
    sample_mean <- mean(sample_data_skewed())
    sample_sd <- sd(sample_data_skewed())
    pop_mean <- mean(population_weights_skewed)
    pop_sd <- sd(population_weights_skewed)
    
    data.frame(
      Statistic = c("Mean", "Standard Deviation"),
      Sample = c(round(sample_mean, 2), round(sample_sd, 2)),
      Population = c(round(pop_mean, 2), round(pop_sd, 2)),
      Error = c(round(sample_mean - pop_mean, 2), round(sample_sd - pop_sd, 2))
    )
  })
  
  # Skewed distribution: Plot sample histogram
  output$sample_hist_skewed <- renderPlot({
    req(sample_data_skewed())
    ggplot(data.frame(weights = sample_data_skewed()), aes(x = weights)) +
      geom_histogram(binwidth = (max(sample_data_skewed()) - min(sample_data_skewed())) / (1 + 3.322 * log10(length(sample_data_skewed()))),
                     fill = "#6082B6", color = "#818589", alpha = 0.3) +
      geom_vline(aes(xintercept = mean(sample_data_skewed())), color = "#6082B6", linetype = "dashed", size = 1) +
      geom_vline(aes(xintercept = mean(population_weights_skewed)), color = "#818589", linetype = "solid", size = 1) +
      labs(title = "Histogram of Sample Weights (Right-Skewed Gamma Distribution)",
           x = "Weight (kg)", y = "Frequency") +
      theme_minimal() +
      annotate("text", x = mean(sample_data_skewed()) + 5, y = Inf, 
               label = "Sample Mean", color = "#6082B6", vjust = 1) +
      annotate("text", x = mean(population_weights_skewed) + 5, y = Inf, 
               label = "Population Mean", color = "#818589", vjust = 2) +
      theme_clean()
  })
}

# Run the app
shinyApp(ui = ui, server = server)