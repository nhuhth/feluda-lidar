library(shiny)
library(shinydashboard)
library(curl)
library(jsonlite)


ui <- dashboardPage(
  dashboardHeader(title = "Feluda Analytica", disable = FALSE),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("EDA", tabName = "eda", icon = icon("file"), selected = TRUE)
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "dashboard",
        fluidRow(
          box(
            title = "Project Title: Enhancing Data Exploration Efficiency: Developing an Automated EDA Tool with ShinyApp in R.", 
            width = 12, 
            solidHeader = TRUE, 
            tags$hr(),
            h4("Contributors:"),
            tableOutput("contributors_table"),
            p("Note: Every contributor makes an equal contribution.")
          )
        ),
        fluidRow(
          box(
            title = "Introduction",
            tags$hr(),
            width = 6, 
            solidHeader = TRUE, 
            "Exploratory Data Analysis (EDA) is one of the crucial parts of Data Science and Machine Learning projects for understanding the datasets better to detect anomalies, and guiding feature engineering in data science projects.",
            tags$br(),
            tags$br(),
            "Developing an automated EDA tool using ShinyApp in R offers efficiency, interactivity, reproducibility, scalability, and customization benefits. Automating the EDA will speed up the analysis, enhance the developer experience, and ensure EDA consistency across projects. Interactive interfaces facilitate deeper exploration of complex datasets and promote transparency in analyses. Using automated EDA tools can be tailored to meet specific project requirements and developer preferences.",
            tags$br(),
            "By focusing on EDA and automation, data scientists can derive insights more efficiently and make better-informed decisions for business."
          ),
          box(
            title = "Motivation",
            tags$hr(),
            width = 6, 
            solidHeader = TRUE, 
            "EDA is the foundation of effective data analysis and communication based on data. However, creating compelling and informative visualizations can be a time-consuming and skill-intensive process.",
            tags$br(),
            tags$br(),
            "Our project aims to streamline the visualization creation process by leveraging the power of large language models (LLMs). Drawing inspiration from the research presented in 'LIDA: A Tool for Automatic Generation of Grammar-Agnostic Visualizations and Infographics using Large Language Models' (Dibia, 2023), we aim to develop a project that will transform natural language descriptions into tailored R EDA.",
            tags$br(),
            tags$br(),
            "In summary, prioritizing EDA and developing automated tools using ShinyApp in R leads to more effective data analysis and facilitates better decision-making in various domains."
          )
        ),
        fluidRow(
          box(
            title = "References", 
            width = 12, 
            solidHeader = TRUE, 
            "Dibia, V. (2023). Lida: A tool for automatic generation of grammar-agnostic visualizations and infographics using large language models. arXiv preprint arXiv:2303.02927."
          )
        )
      ),
      tabItem(
        tabName = "eda",
        tabsetPanel(
          tabPanel(
            id = "data_uploader",
            title = "Data Uploader",
            fluidRow(
              box(
                title = "Uplaod a CSV file!",
                #tags$hr(),
                width = 4, 
                solidHeader = TRUE, 
                fileInput(
                  "file",
                  "Please upload a CSV file to perform analysis",
                  accept = ".csv",
                  multiple = FALSE
                )
              ),
              box(
                id = "dataframe",
                title = "Uploaded dataset as tabular format",
                width = 8,
                fluidRow(
                  box(
                    width = 12, 
                    solidHeader = TRUE,
                    DT::dataTableOutput("dataframe")
                  )
                )
              ),
            ),
          ),
          tabPanel(
            id = "eda_summary",
            title = "EDA Summary",
            fluidRow(
              box(
                title = "Summary of Exploratory Data Analysis",
                width = 12, 
                solidHeader = TRUE, 
                verbatimTextOutput("analysis_summary"),
                fluidRow(
                  box(
                    title = "Data Types",
                    width = 6, 
                    solidHeader = TRUE,
                    verbatimTextOutput("data_types_output")
                  ),
                  box(
                    title = "Null Values",
                    width = 6, 
                    solidHeader = TRUE,
                    verbatimTextOutput("null_values_output")
                  ),
                ),
                fluidRow(
                  id = "correlation",
                  title = "Correlation",
                  box(
                    title = "Correlation Matrix",
                    width = 6, 
                    solidHeader = TRUE,
                    verbatimTextOutput("correlation_matrix")
                  ),
                  box(
                    title = "Correlation Plot",
                    width = 6, 
                    solidHeader = TRUE,
                    verbatimTextOutput("correlation_plot")
                  ),
                )
                
              )
            )
          ),
          
          
          tabPanel(
            id = "data_visualization_plots",
            title = "Data Visualization",
            fluidRow(
              box(
                title = "Visualization Data for Better Insights",
                width = 12, 
                solidHeader = TRUE, 
                fluidRow(
                  id = "categorical_and_numerical_data_plot",
                  title = "Categorical and Numerical Data Plot",
                  box(
                    title = "Categorical Data Plot",
                    width = 6, 
                    solidHeader = TRUE,
                    verbatimTextOutput("categorical_data_plot")
                  ),
                  box(
                    title = "Numerical Data Plot",
                    width = 6, 
                    solidHeader = TRUE,
                    verbatimTextOutput("numerical_data_plot")
                  ),
                )
                
              )
            )
          ),
          
          tabPanel(
            id = "chat",
            title = "Chat with Llama2",
            fluidRow(
              box(
                id = "dataframe_header",
                title = "Top 5 rows of the dataset.",
                width = 12,
                fluidRow(
                  box(
                    width = 12, 
                    solidHeader = TRUE,
                    DT::dataTableOutput("dataframe_header")
                  )
                )
              )
            ),
            fluidRow(
              box(
                title = "Chat with your dataset using Llama2",
                width = 12, 
                solidHeader = TRUE, 
                verbatimTextOutput("chat_questions"),
                fluidRow(
                  box(
                    # title = "ChatGPT Answers",
                    width = 12,
                    solidHeader = TRUE,
                    uiOutput("chat_response_output")
                  )
                ),
                fluidRow(
                  box(
                    title = "Questions",
                    width = 12,
                    solidHeader = TRUE,
                    textAreaInput(
                      "question_input",
                      label = NULL,
                      placeholder = "Enter your question(s) here",
                      rows = 6
                    ),
                    actionButton(
                      "chat_question_btn",
                      "Ask",
                      class = "btn btn-success btn-block",
                      style="padding: 4px 8px; font-size: 12px; max-width: 100px; align:right;"
                    )
                  )
                )
                
              )
            )
          )
        )
      )
    )
  )
)
