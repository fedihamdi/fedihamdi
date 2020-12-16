library(shiny)
library(plotly)
library(shinydashboard)
library(DT)
library(plotly)
library(caret)
library(dygraphs)
library(xts)
library(tidyverse)
library(lubridate)
library(forecast)
library(ggplot2)
library(plotly)
library(readr)
library(shinythemes)
library(dplyr)
library(ggplot2)
library(forecast)
library(zoo)
require(xts)
library(ggplot2)
library(tidyverse)
library(scales)
library(RColorBrewer)
library(ggthemes)
require(gridExtra)
library(plotly)
library(gganimate)
library(coronavirus)
library(gapminder)
library(av)
library(readxl)
#########################################################################     ##############################################     #######################
setwd(getwd())
library(tidyverse)
library(lubridate)
library(shiny)
library(shinydashboard)
library(flexdashboard)
library(shinyWidgets)
library(plotly)
library(DT)
library(metathis)
library(directlabels)
library(ggthemes)
library(hrbrthemes)
library(png)
library(magick)
library(gridExtra)
library(grid)

options(scipen = 9999)



get_png <- function(filename) {
  grid::rasterGrob(png::readPNG(filename), interpolate = TRUE)
}

get_txt <- function(txt) {
  grid::textGrob(txt)
}

add_logoplot <- function(p, size = 0.05){
  txt = get_txt("CC-BY Fedi HAMDI/Association Tunisienne des Ingénieurs Statisticiens")
  xpos = 0.01
  #size = 0.05
  logo <-
    ggplot() +
    aes(x = 0:1, y = 1) +
    theme_void() +
    annotation_custom(txt, xmin = 0, xmax = 0.5, ymin = 0) +
    NULL
  gridExtra::grid.arrange(p, logo)
}


#p <- qplot(mtcars$mpg)
#add_logoplot(p, 0.05)

write_ts <- function(key) {
  file_timestamp <- paste0(key,"_updated.rds")
  timestamp <- lubridate::now()
  write_rds(timestamp, file_timestamp)
}

read_ts <- function(key) {
  file_timestamp <- paste0(key,"_updated.rds")
  if(file.exists(file_timestamp)) {
    timestamp <- read_rds(file_timestamp)
  }
  else timestamp <- Sys.Date() - 1
  timestamp
}

read_cached_file <- function(url, file){
  timestamp <- read_ts(str_sub(file, end = -5))
  now <- lubridate::now()
  data_age <- lubridate::interval(timestamp, now)

  if (time_length(data_age, "hours") > 12) {
    data <- read_csv(url)
    write_rds(data, file)
    write_ts(str_sub(file, end = -5))
  } else {
    cat(paste("Data age:", as.duration(data_age), "- Using cached version."))
    data <- read_rds(file)
  }
  data
}

read_confirmed_cases <- function() {
  read_cached_file("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv",
                   "confirmed.rds")
}

read_death_cases <- function() {
  read_cached_file("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv",
                   "deaths.rds")
}

confirmed <- read_confirmed_cases() %>%
  gather(date, value, -`Province/State`, -`Country/Region`, -Lat, -Long) %>%
  mutate(date = paste0(date,"20")) %>%
  mutate(date = mdy(date)) %>%
  mutate(type = "confirmed")

deaths <- read_death_cases() %>%
  gather(date, value, -`Province/State`, -`Country/Region`, -Lat, -Long) %>%
  mutate(date = paste0(date,"20")) %>%
  mutate(date = mdy(date)) %>%
  mutate(type = "deceased")


all_data <- bind_rows(confirmed, deaths) %>%
  group_by(`Country/Region`, date, type) %>%
  summarise(value = sum(value))

countries <- all_data %>% arrange(desc(value)) %>%
  pull(`Country/Region`) %>% unique()

data_start <- all_data %>% pull(date) %>% min()
data_end <- all_data %>% pull(date) %>% max()

all_cases <- all_data %>% group_by(`Country/Region`) %>%  summarise(cases = max(value)) %>% tally(cases) %>% pull(n)

########################################################################     ####################################### 3#########################      #################   3############
Tun <- read_excel("Tun.xlsx",sheet = "Feuil1", col_types = c("date","text", "numeric", "numeric", "numeric","numeric", "numeric", "numeric","numeric"))
df_all <- read_delim("covid_19_clean_complete.csv",
                     ";", escape_double = FALSE, col_types = cols(`Province/State` = col_skip()
                     ), trim_ws = TRUE)
Date=as.Date(Tun$Date)
indice=Tun[,8:9]
Tun$isConfirmed <- ifelse(Tun$Confirmed != 0,"Confirmed","Not Confirmed")
confirmed_color <- "purple"
active_color <- "#1f77b4"
recovered_color <- "forestgreen"
death_color <- "red"
setwd(getwd())
title1 <- tags$a(img(src="Atis1.jpg",align = 'left' ,height = '50px'),
                'COVID-19')

# Define UI
shinyUI(dashboardPage(



  dashboardHeader(title =title1 ,titleWidth = "20%",
                  tags$li(class="dropdown",
                         img(src="tunisie.png",align = 'left' ,height = '50px')),
                  dropdownMenuOutput('messageMenu'),
                  dropdownMenu(type = 'notifications',
                               notificationItem(text = '5 new users today', icon('users')),
                               notificationItem(text = 'Server load at 86%',
                                                icon = icon('exclamation-triangle'),
                                                status = 'warning')),
                  dropdownMenu(type = 'tasks',
                               badgeStatus = 'success',
                               taskItem(value = 90, color = 'green', 'Documentation'),
                               taskItem(value = 75, color = 'yellow', 'Server deployment'),
                               taskItem(value = 50, color = 'red', 'Overall project'))
                  ),
  ########## sider panel ####
  dashboardSidebar( width = 150,
                    sidebarMenu(


                      menuItem("Analysis", tabName = "DA", icon = icon("connectdevelop"),
                               startExpanded = T,
                               menuSubItem(" 1 ", tabName = "UA", icon = icon("boxes")),
                               menuSubItem(" 2 ", tabName = "BA", icon = icon("megaport"))
                      ),
                      menuItem("Data", tabName = "VD", icon = icon("table")),
                      menuItem("Prediction", tabName = "ML", icon = icon("slideshare"))



                    )

                    ),

  dashboardBody(






    tabItems(

      #####Vizualise Data #########
      tabItem(
        tabName = 'VD', uiOutput('tb')
        ###################### nzidou 7aja hna



        ,

        tags$div(id="cite",
                 '\U00A9 ATIS'
        )

        #tabPanel("Summary",br(), verbatimTextOutput("sum"))

      ),



      ########## Univariate analysis ######
      tabItem(  tabName = "UA",

                box( status = "primary",height=1000,  width = 40,
                     tabsetPanel(
                       selected = "Tunidex20",






                       tabPanel("Tunidex20",br(),imageOutput("plot3")),
                       tabPanel("Tunidex",plotlyOutput('plot'),br(),
                                downloadButton(outputId = "down2", label = "Download the plot"))
                     )),
                tags$head(tags$style(" #cite {
                                     color: #009790;
                                     position: absolute;
                                     bottom: 10px;
                                     right: 10px;
                                     font-size: 15px;
                                     }
                                     ")),

                tags$div(id="cite",
                         '\U00A9 ATIS'
                )),
      ########## Bivariate analysis ########
      tabItem(
        tabName = "BA",

        fluidRow(
          box( status = "primary",  width = 8 ,
               tabsetPanel(

                 selected = "Correlation Scatterplot",


                 tabPanel("Correlation Scatterplot",
                          br(),

                          selectInput("Var3", "Choose a variable :",width = '200px',
                                      colnames(df_all[,1,4]),selected = "Date"),


                          br(),
                          imageOutput('plot2')),
                 tabPanel("Correlogram",br(),
                          br(),

                          plotOutput('ttt')),
                 tabPanel("t-test for Tunidex",br(),
                          br(),verbatimTextOutput("sum6"),verbatimTextOutput("sum7")
                          ,verbatimTextOutput("sum8"),

                          " .
                          ")
                 )


                 ),
          tags$div(id="cite",
                   '\U00A9 ATIS'
          )


               )),
      tabItem(
        tabName = "ML",
        fluidRow(

         sidebarPanel(

           withMathJax(),
           h4("Total cases:", scales::number(all_cases)),
           pickerInput("country_selector", "Select Countries", countries, multiple = TRUE,
                      options = list(`actions-box` = TRUE),
                      #selectize = TRUE,
                      selected = c("US", "Germany", "Italy", "France", "Iran", "Spain", "Korea, South")),
          sliderInput("cases_limit", "Pick #cases for alignment", min = 1, max = 500, value = 100),
          sliderInput("start_date", "Limit Duration", min = 0, max = 100, value=c(0,100)),
          checkboxInput("scalesfree", "Free Y-Scale", value = TRUE),
          checkboxInput("logscale", "Logarithmic Y-Scale", value = TRUE),
          checkboxInput("labelshow", "Show case counts", value = FALSE),
          shiny::div("This web-app uses data from the Github repository provided by",
                     a("Johns Hopkins CSSE.", href="https://github.com/CSSEGISandData/COVID-19"),
                     "The data is typically 1 day behind current data."),
          br(),
          div("Last data update:", format(data_end, "%d-%B-%Y") ," - No warranties."),

          div("Created by Fedi HAMDI."),
          DT::DTOutput("models")
        ),
        mainPanel(
          plotOutput("distPlot", width = "100%", height = "640"),br(),br(),
          shiny::wellPanel(
            h4("Log-Linear model fit"),
            withMathJax(
              div("This table shows the exponential of the log-linear model fit as a percentage value and the corresponding p-value. ",
                  "A growth rate of 30% indicates that that the following exponential function best approximates the curve:",
                  "$$\\text{cases} = cases_{0} \\times 1.3^{days} + c$$",
                  "The constant cases0 refers the the alignment specified above. The constant c adjusts for small differences and is not reported here.",
                  br(),
                  "A growth rate of 30% would mean approx. 30% increase of cases per day.")),br(),
            DT::DTOutput("modeltable")
          ))


      ))
      ########## Machine learning#####################















                )

    )))



