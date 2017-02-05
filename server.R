library(shiny)
library(tidyverse)
library(stringr)
library(maptools)
library(rgeos)
library(ggmap)
library(scales)
library(RColorBrewer)
library(lubridate)
library(plotly)
library(sp)
library(rgdal)

censusOverlay <- function(data, census_shp) {
        coordinates(data) <- ~ Lon + Lat
        proj4string(data) <- CRS("+proj=longlat")
        data <- spTransform(data, proj4string(census_shp))
        proj4string(data) <- proj4string(census_shp)
        
        overlay <- cbind(as.data.frame(data), over(data, census_shp)) %>% na.omit()
        
        return(overlay)
}


displayinputs <- read_csv('AppInput.csv')
sfloc <- read_csv('SF_CensusTracts.csv')
sf <- readShapeSpatial('geo_export_391ea3ea-9acb-46a8-a9fc-8ff59f12fbda.shp')
sf_format<-readOGR(".","geo_export_391ea3ea-9acb-46a8-a9fc-8ff59f12fbda")
sfdf <- fortify(sf, region = "geoid") %>% mutate(id = str_sub(id, 2, -1))

sfloc <- sfloc %>% mutate(geoid = as.numeric(str_sub(geoid, 2, -1)))

eventbrite <- read_csv('EventBrite.csv')

eventful <- read_csv('Eventful.csv') %>%
        mutate(Lon = lon, Lat = lat) %>% select(-lon, -lat)

eventfuloverlay <- censusOverlay(eventful, sf_format) %>%
        mutate(geoid = as.numeric(str_sub(geoid, 2, -1)))

shinyServer(function(input, output) {
        
        output$datatable = renderDataTable({
                displayinputs %>% filter(service %in% input$service) %>%
                        arrange(desc(price)) %>% head(8) %>% left_join(., sfloc) %>%
                        mutate(Neighborhood = nhood, Time = time, 
                               Service = service,
                               `Estimated % Increase` = round(price * 100, 1)) %>% 
                        select(Neighborhood, Time, 
                               `Estimated % Increase`, Service)
        })
        
        mapdata <- reactive({
                displayinputs %>% filter(service == input$mapserv,
                                         hour(time) == input$time) %>%
                        mutate(id = as.character(geoid)) %>%
                        left_join(sfdf, .) %>% left_join(., select(sfloc, geoid, nhood))
        })
        
        # ebrite <- reactive({
        #         eventbrite %>% filter(day(end) == input$daymap & 
        #                                       hour(end) == input$time |
        #                                       day(start) == input$daymap &
        #                                       day(start) == input$time)
        # })
        
        eful <- reactive({
                eventfuloverlay %>% filter(hour(end) == input$time | hour(start) == input$time)
        })
        
        map <- reactive({
                ggplot() +
                        geom_polygon(data = mapdata(),
                                     aes(x = long, y = lat, group = group, 
                                         fill = round(price*100,0),
                                         text = paste("Neighborhood:", nhood)),
                                     color = "black", size = 0.25) +
                        # geom_point(data = ebrite(), aes(x = lon, y = lat)) + 
                        geom_point(data = eful(), aes(x = Lon, y = Lat, 
                                                      text = paste('Event:', title))) + 
                        coord_map() +
                        scale_fill_gradient(name = 'Estimated  %Price Increase',
                                            low = 'blue', high = 'red') +
                        theme_nothing() +
                        theme(legend.position = 'bottom') 
        })
        
        
        output$map = renderPlotly({
                ggplotly(map())
                
                
        })

})
