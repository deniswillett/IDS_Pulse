

library(shiny)

shinyUI(navbarPage('Pulse!',
                   
                   tabPanel("Hotspots!",
                            sidebarLayout(
                                    
                                    sidebarPanel(
                                            checkboxGroupInput("day", "Day of Week:",
                                                               c('Wed 25th' = 25,
                                                                 'Thurs 26th' = 26),
                                                               selected = c(25, 26))
                                    ),
                                    
                                    mainPanel(
                                            dataTableOutput('datatable')
                                    )
                            )
                            
                            ),
                   tabPanel("Visualization",
                            sidebarLayout(
                                    sidebarPanel(
                                            radioButtons("daymap", "Day of Week:",
                                                               c('Wed 25th' = 25,
                                                                 'Thurs 26th' = 26),
                                                               selected = 25),
                                            sliderInput('time', 'Time of Day',
                                                        min = 0, max = 24, 
                                                        value = 7, step = 1)
                                    ),
                                    
                                    mainPanel(
                                            plotOutput('map')
                                    )
                                    
                            )
                            ),
                   tabPanel('Time Series')
                   
))
        

