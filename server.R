library(shiny)
library(tidyverse)
library(stringr)
library(maptools)
library(rgeos)
library(ggmap)
library(scales)
library(RColorBrewer)
library(lubridate)

displayinputs <- read_csv('AppInput.csv')
sfloc <- read_csv('SF_CensusTracts.csv')
sf <- readShapeSpatial('geo_export_391ea3ea-9acb-46a8-a9fc-8ff59f12fbda.shp')
sfdf <- fortify(sf, region = "geoid") %>% mutate(id = str_sub(id, 2, -1))

sfloc <- sfloc %>% mutate(geoid = as.numeric(str_sub(geoid, 2, -1)))

shinyServer(function(input, output) {
        
        output$datatable = renderDataTable({
                displayinputs %>% filter(day(time) %in% input$day) %>%
                        arrange(desc(price)) %>% head() %>% left_join(., sfloc) %>%
                        mutate(Neighborhood = nhood, Time = time, 
                               `Estimated % Increase` = round(price * 100, 1)) %>% 
                        select(Neighborhood, Time, 
                               `Estimated % Increase`)
        })
        
        mapdata <- reactive({
                displayinputs %>% filter(day(time) == input$daymap,
                                         hour(time) == input$time) %>%
                        mutate(id = as.character(geoid)) %>%
                        left_join(sfdf, .)
        })
        
        output$map = renderPlot({
                ggplot() +
                        geom_polygon(data = mapdata(), 
                                     aes(x = long, y = lat, group = group, fill = price), 
                                     color = "black", size = 0.25) + 
                        coord_map() +
                        scale_fill_gradient(name = 'Estimated  %Price Increase', 
                                            low = 'blue', high = 'red', 
                                            labels = percent) +
                        theme(legend.position = 'bottom')
        })

})
