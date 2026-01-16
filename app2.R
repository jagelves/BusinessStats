library(shiny)
library(ggplot2)
library(ggthemes)

# Generate population data
set.seed(123)
N <- 10000

# Uniform: min=40, max=120, mean=80, sd≈23.09
population_uniform <- runif(N, 40, 120)
pop_sd_uniform <- sd(population_uniform)

# Exponential: rate=1/80, mean=80, sd=80
population_exp <- rexp(N, rate = 1/80)
pop_sd_exp <- sd(population_exp)

# Gamma: shape=2, scale=40, mean=80, sd≈56.57
population_gamma <- rgamma(N, shape = 2, scale = 40)
pop_sd_gamma <- sd(population_gamma)

# Triangular: min=0, max=160, mode=80, mean=80, sd≈32.66
u <- runif(N)
Fc <- (80 - 0) / (160 - 0)
population_tri <- ifelse(u < Fc,
                         0 + sqrt(u * (160 - 0) * (80 - 0)),
                         160 - sqrt((1 - u) * (160 - 0) * (160 - 80)))
pop_sd_tri <- sd(population_tri)

# UI
ui <- fluidPage(
  titlePanel("Central Limit Theorem: Sampling Distribution of the Mean"),
  sidebarLayout(
    sidebarPanel(
      selectInput("dist", "Select Population Distribution:",
                  choices = c("Uniform", "Exponential", "Triangular", "Gamma"),
                  selected = "Uniform"),
      selectInput("n", "Select Sample Size:",
                  choices = c(5, 10, 20, 25, 30, 50, 100,200,500),
                  selected = 5),
      selectInput("num_samples", "Number of Samples:",
                  choices = c(20, 50, 100, 200,500,1000),
                  selected = 20),
      actionButton("generate_btn", "Generate Sampling Distribution")
    ),
    mainPanel(
      h4("Population Distribution"),
      plotOutput("pop_hist"),
      h4("Distribution of Sample Means"),
      plotOutput("sampling_hist")
    )
  )
)

# Server
server <- function(input, output) {
  
  # Reactive value to store sample means
  sample_means <- reactiveVal()
  
  # Generate samples on button click
  observeEvent(input$generate_btn, {
    dist_choice <- input$dist
    n <- as.numeric(input$n)
    num_samples <- input$num_samples
    
    if (dist_choice == "Uniform") {
      population <- population_uniform
      pop_sd <- pop_sd_uniform
    } else if (dist_choice == "Exponential") {
      population <- population_exp
      pop_sd <- pop_sd_exp
    } else if (dist_choice == "Triangular") {
      population <- population_tri
      pop_sd <- pop_sd_tri
    } else {
      population <- population_gamma
      pop_sd <- pop_sd_gamma
    }
    
    # Generate multiple samples and compute means
    means <- replicate(num_samples, mean(sample(population, size = n, replace = TRUE)))
    sample_means(means)
  })
  
  # Population histogram (updates with distribution selection)
  output$pop_hist <- renderPlot({
    dist_choice <- input$dist
    pop_mean <- 80
    
    if (dist_choice == "Uniform") {
      pop_data <- data.frame(value = population_uniform)
      title_text <- "Uniform Population Distribution"
    } else if (dist_choice == "Exponential") {
      pop_data <- data.frame(value = population_exp)
      title_text <- "Exponential Population Distribution"
    } else if (dist_choice == "Triangular") {
      pop_data <- data.frame(value = population_tri)
      title_text = "Triangular Population Distribution"
    } else {
      pop_data <- data.frame(value = population_gamma)
      title_text <- "Gamma Population Distribution"
    }
    
    ggplot(pop_data, aes(x = value)) +
      geom_histogram(bins = 30, fill = "#E7B800", color = "#818589", alpha = 0.7) +
      geom_vline(xintercept = pop_mean, color = "#818589", linetype = "solid", size = 1) +
      labs(title = title_text, x = "Value", y = "Frequency") +
      theme_minimal() +
      theme_clean()
  })
  
  # Histogram of sample means
  output$sampling_hist <- renderPlot({
    req(sample_means())
    dist_choice <- input$dist
    n <- as.numeric(input$n)
    obs<-as.numeric(input$num_samples)
    title_text <- paste("Sampling Distribution of Sample Means",
                        paste("(", dist_choice, ", n =", n, ")", sep = ""))
    pop_mean <- 80
    
    if (dist_choice == "Uniform") {
      pop_sd <- pop_sd_uniform
    } else if (dist_choice == "Exponential") {
      pop_sd <- pop_sd_exp
    } else if (dist_choice == "Triangular") {
      pop_sd <- pop_sd_tri
    } else {
      pop_sd <- pop_sd_gamma
    }
    
    theo_sd <- pop_sd / sqrt(n)
    samp_df <- data.frame(means = sample_means())
    
    
    ggplot(samp_df, aes(x = means)) +
      geom_histogram(bins = round(1+log(obs)), fill = "#6082B6", color = "#818589", alpha = 0.7) +
      geom_vline(xintercept = pop_mean, color = "#818589", linetype = "solid", size = 1) +
      labs(title = title_text, x = "Sample Mean", y = "Frequency") +
      theme_minimal() +
      theme_clean() +
      annotate("text", x = pop_mean + theo_sd * 1.5, y = Inf,
               label = "Population Mean", color = "#818589", vjust = 2, hjust = 0)
  })
}

# Run the app
shinyApp(ui = ui, server = server)