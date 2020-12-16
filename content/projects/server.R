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
library(ggcorrplot)
library(RColorBrewer)
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

#########################################################################     ##############################################     #######################

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
  gridExtra::grid.arrange(p, logo, heights = c(1-size, size))
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

###################################################--------###########################
###################################################       ############################
shinyServer(function(input, output) {
  #####################             ##########################     ####### # # #
  ###########################################################################
  get_data <- reactive({
    all_data <- all_data %>%
      mutate(days = as.numeric((date - data_start))) %>%
      filter(value > input$cases_limit || type == "deceased")

    start_dataset <- all_data %>%
      group_by(`Country/Region`) %>%
      summarise(minvalue = min(value),
                onset = min(days))

    all_data %>% dplyr::left_join(start_dataset) %>%
      mutate(matched_days = days - onset) %>%
      mutate(lvalue = log(value + 1))
  })

  get_max_day_value <- reactive({
    get_data() %>% pull(matched_days) %>% max()
  })


  output$distPlot <- renderPlot({
    req(input$country_selector)
    sdate <- input$start_date[1]
    edate <- input$start_date[2]
    scaleparam <- "fixed"
    if(input$scalesfree) scaleparam <- "free_y"
    p <- get_data() %>%
      filter(value > 0) %>%
      filter(`Country/Region` %in% input$country_selector) %>%
      filter(matched_days %in% sdate:edate) %>%
      ggplot()+
      aes(x = matched_days, y = value,
          group = interaction(`Country/Region`, type),
          color = `Country/Region`,
          shape = `Country/Region`,
          label = value) +
      geom_line(size = 1) +
      geom_point(size = 3)+
      facet_wrap(~type, scales = scaleparam, ncol = 1) +
      labs(x = paste("Days after", input$cases_limit, "confirmed cases were reached.")) +
      labs(y = "Count") +
      NULL
    if(input$logscale) {
      p <- p + scale_y_log10() + labs(y = "Count (log-scale)")
    }
    if (input$labelshow){
      p <- p + geom_label()
    }
    p +
      hrbrthemes::theme_ipsum_rc(base_size = 18) +
      ggtitle("Comparison of case trajectories by country") +
      theme(legend.position="bottom") +
      theme(plot.caption = element_text(family = "Roboto Condensed")) +
      theme(plot.title = element_text(size = 24),
            axis.title.x = element_text(size = 16),
            axis.title.y = element_text(size = 16),
            strip.text.x = element_text(size = 18)
      ) +
      scale_x_continuous(expand=c(0, 2)) +
      coord_cartesian(clip = 'off') +
      geom_dl(aes(label = `Country/Region`), method = list(dl.trans(x = x - 0.3, y = y + 0.4), dl.combine("last.points"), cex = 0.8)) -> p

    add_logoplot(p)



  })

  output$modeltable <- renderDT({
    get_data() %>%
      filter(type == "confirmed") %>%
      ungroup() %>%
      select(`Country/Region`, days, lvalue) %>%
      nest(data = c(days,lvalue)) %>%
      mutate(
        fit = map(data, ~lm(lvalue ~ days, data=.x)),
        tidied = map(fit, broom::tidy)
      ) %>%
      unnest(tidied) %>%
      filter(term == "days") %>%
      mutate(estimate = exp(estimate)) %>%
      select(`Country/Region`, estimate, std.error, statistic, p.value) %>%
      mutate(`Growth Rate` = paste0(round((estimate-1) * 100, 2), "%")) %>%
      mutate(`p Value` = scales::pvalue(p.value,
                                        accuracy = 0.001, # Number to round to
                                        decimal.mark = ".", # The character to be used to indicate the numeric decimal point
                                        add_p = TRUE)) %>%
      select(`Country/Region`, `Growth Rate`, `p Value`)


  })





  ###########################################################
  ###########################################################
  output$ibox <- renderInfoBox({
    valueBox(
      "Confirmed Cases",
      value = 39,
      color= "yellow" ,
      icon = icon("diagnoses")


    )
  })
  output$vbox <- renderValueBox({
    valueBox(
      "Deaths",
      value = 0 ,
      color = "red",
      icon = icon("exclamation-triangle")

    )
  })
  output$cbox <- renderInfoBox({
    valueBox(
      "Recovered",
      value = 0 ,
      color = "blue",
      icon = icon("walking")

    )
  })

  output$table = DT::renderDataTable({

    DT::datatable(Tun,options = list(scrollX = TRUE))

  })
  output$sum <-renderPrint({

    summary(Tun)
  })
  output$plot4=renderImage({
    outfile <- tempfile(fileext='.gif')

    plo2=ggplot(Tun, aes(Date, y=Tun$Tunidex20_Clot , colour = isConfirmed ))+
      geom_line(size = 2.5, alpha = 0.6)+
      geom_point(shape=21,size = 2)+

      scale_y_continuous(trans="log10")+
      labs(x = "", y = "Tunidex20 Value", title =  "Tunidex20 Values", subtitle = "by Confirmed Cases")+
      geom_text(aes(label = Tunidex_Clot), nudge_y = 0.006, color = "blue", size = 1.1)+
      scale_colour_brewer(palette = "Set2")+
      theme_fivethirtyeight()+
      theme(legend.position="bottom", legend.direction="horizontal", legend.title = element_blank(), axis.text = element_text(size = 14),
            legend.text = element_text(size = 13), axis.title = element_text(size = 14), axis.line = element_line(size = 0.4, colour = "grey10"),
            plot.background = element_rect(fill = "#EFEFEF"), legend.background = element_rect(fill = "#DCDCDC"))


    ploo=plo2 + geom_point() + transition_reveal(Date)
    anim_save("outfile1.gif", animate(ploo))
    # Return a list containing the filename
    list(src = "outfile.gif",
         contentType = 'image/gif',
         width = 1000,
         height = 1000
         # alt = "This is alternate text"
    )


  })

  output$tb<- renderUI({
    tabsetPanel(


      tabPanel("Dataset",br(), DT::dataTableOutput("table")),
      tabPanel("Summary",br(),verbatimTextOutput("sum")),
      tabPanel("Plot",br(),imageOutput('plot4'))



    )})


  output$plot=renderPlotly({

    Date=as.Date(Tun$Date)
    indice=Tun[,8:9]
    Tun$isConfirmed <- ifelse(Tun$Confirmed != 0,"Confirmed","Not Confirmed")

    plo = ggplot(Tun, aes(Date, y=Tun$Tunidex_Clot , colour = isConfirmed ))+
      geom_line(size = 2.5, alpha = 0.6)+
      geom_point(shape=21,size = 2)+
      scale_y_continuous(trans="log10")+
      labs(x = "", y = "Tunidex Value", title =  "Tunidex Values", subtitle = "by Confirmed Cases")+
      geom_text(aes(label = Tunidex_Clot), nudge_y = 0.004, color = "blue", size = 1.1)+
      scale_colour_brewer(palette = "Set2")+
      theme_fivethirtyeight()+
      theme(legend.position="bottom", legend.direction="horizontal", legend.title = element_blank(), axis.text = element_text(size = 14),
            legend.text = element_text(size = 13), axis.title = element_text(size = 14), axis.line = element_line(size = 0.4, colour = "grey10"),
            plot.background = element_rect(fill = "#EFEFEF"), legend.background = element_rect(fill = "#DCDCDC"))
    ggplotly(plo)

  })

  output$plot2=renderPlotly({

    plo2=ggplot(Tun, aes(Date, y=Tun$Tunidex20_Clot , colour = isConfirmed ))+
      geom_line(size = 2.5, alpha = 0.6)+
      geom_point(shape=21,size = 2)+

      scale_y_continuous(trans="log10")+
      labs(x = "", y = "Tunidex20", title =  "Tunidex20 Values", subtitle = "by Confirmed Cases")+
      geom_text(aes(label = Tunidex_Clot), nudge_y = 0.006, color = "blue", size = 1.1)+
      scale_colour_brewer(palette = "Set2")+
      theme_fivethirtyeight()+
      theme(legend.position="bottom", legend.direction="horizontal", legend.title = element_blank(), axis.text = element_text(size = 14),
            legend.text = element_text(size = 13), axis.title = element_text(size = 14), axis.line = element_line(size = 0.4, colour = "grey10"),
            plot.background = element_rect(fill = "#EFEFEF"), legend.background = element_rect(fill = "#DCDCDC"))
    ggplotly(plo2)

  })

  output$plot3<- renderImage({
    outfile <- tempfile(fileext='.gif')

    plo2=ggplot(Tun, aes(Date, y=Tun$Tunidex20_Clot , colour = isConfirmed ))+
      geom_line(size = 2.5, alpha = 0.6)+
      geom_point(shape=21,size = 2)+

      scale_y_continuous(trans="log10")+
      labs(x = "", y = "Tunidex20", title =  "Tunidex20 Values", subtitle = "by Confirmed Cases")+
      geom_text(aes(label = Tunidex_Clot), nudge_y = 0.006, color = "blue", size = 1.1)+
      scale_colour_brewer(palette = "Set2")+
      theme_fivethirtyeight()+
      theme(legend.position="bottom", legend.direction="horizontal", legend.title = element_blank(), axis.text = element_text(size = 14),
            legend.text = element_text(size = 13), axis.title = element_text(size = 14), axis.line = element_line(size = 0.4, colour = "grey10"),
            plot.background = element_rect(fill = "#EFEFEF"), legend.background = element_rect(fill = "#DCDCDC"))
    plo3 = plo2 + geom_point() + transition_reveal(Date)
    anim_save("outfile.gif", animate(plo3))
    # Return a list containing the filename
    list(src = "outfile.gif",
         contentType = 'image/gif'
         #width = "100%",
         #height = "100%",

         # alt = "This is alternate text"
    )

  }
    )  # turn the device off



  output$sum6 <-renderPrint({
    Tunidex_min=min(Tun[[8]])
    Tunidex_max=max(Tun[[8]])



  })
  output$sum7 <-renderPrint({
    Tunidex20_min=min(Tun[[9]])
    Tunidex20_max=max(Tun[[9]])

  })
  output$sum8 <-renderPrint({
    Tunidex_moy=mean(Tun[[8]])
    Tunidex20_moy=mean(Tun[[9]])

  })








  output$ttt= renderPlot({

    plo = ggplot(Tun, aes(Date, y=Tun$Tunidex_Clot , colour = isConfirmed ))+
      geom_line(size = 2.5, alpha = 0.6)+
      geom_point(shape=21,size = 2)+
      scale_y_continuous(trans="log10")+
      labs(x = "", y = "Tunidex Value", title =  "Tunidex Values", subtitle = "by Confirmed Cases")+
      geom_text(aes(label = Tunidex_Clot), nudge_y = 0.004, color = "blue", size = 1.1)+
      scale_colour_brewer(palette = "Set2")+
      theme_fivethirtyeight()+
      theme(legend.position="bottom", legend.direction="horizontal", legend.title = element_blank(), axis.text = element_text(size = 14),
            legend.text = element_text(size = 13), axis.title = element_text(size = 14), axis.line = element_line(size = 0.4, colour = "grey10"),
            plot.background = element_rect(fill = "#EFEFEF"), legend.background = element_rect(fill = "#DCDCDC"))

    #########
    plo2=ggplot(Tun, aes(Date, y=Tun$Tunidex20_Clot , colour = isConfirmed ))+
      geom_line(size = 2.5, alpha = 0.6)+
      geom_point(shape=21,size = 2)+

      scale_y_continuous(trans="log10")+
      labs(x = "", y = "Tunidex Value", title =  "Tunidex20 Values", subtitle = "by Confirmed Cases")+
      geom_text(aes(label = Tunidex_Clot), nudge_y = 0.006, color = "blue", size = 1.1)+
      scale_colour_brewer(palette = "Set2")+
      theme_fivethirtyeight()+
      theme(legend.position="bottom", legend.direction="horizontal", legend.title = element_blank(), axis.text = element_text(size = 14),
            legend.text = element_text(size = 13), axis.title = element_text(size = 14), axis.line = element_line(size = 0.4, colour = "grey10"),
            plot.background = element_rect(fill = "#EFEFEF"), legend.background = element_rect(fill = "#DCDCDC"))

    pol1=grid.arrange(plo,plo2,ncol=2)
    pol1
  })




  output$text=renderPrint({



    summary(df_all[,5:7])
  })





})



