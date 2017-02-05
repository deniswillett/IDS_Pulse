

library(shiny)
library(plotly)

shinyUI(navbarPage('Pulse',
                   
                   tabPanel("Hotspots",
                            titlePanel('San Francisco on Feb 4th'),
                            sidebarLayout(
                                    
                                    sidebarPanel(
                                            checkboxGroupInput("service", "Service:",
                                                               c('Uber' = 'Uber',
                                                                 'Lyft' = 'Lyft'),
                                                               selected = c('Uber', 'Lyft'))
                                    ),
                                    
                                    mainPanel(
                                            dataTableOutput('datatable')
                                    )
                            )
                            
                            ),
                   tabPanel("Map",
                            titlePanel('San Francisco on Feb 4th'),
                            sidebarLayout(
                                    sidebarPanel(
                                            radioButtons("mapserv", "Service:",
                                                         c('Uber' = 'Uber',
                                                           'Lyft' = 'Lyft'),
                                                         selected = 'Uber'),
                                            sliderInput('time', 'Time of Day',
                                                        min = 0, max = 24,
                                                        value = 7, step = 1)
                                    ),
                                    
                                    mainPanel(
                                            plotlyOutput('map')
                                    )
                                    
                            )
                            )
                   
))
        

