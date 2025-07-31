#'calulates the land area share by zoning use type

library(tidyverse)

data<-sf::read_sf("C:/current_projects/boston_zoning/data/Base Districts/zoning_atlas.shp")

data2 <- as.data.frame(data)

data2 %>%
  
  filter(zo_usety==1) %>%
  
  select(-geometry) %>%
  
  mutate(sf_only = if_else(mulfam2==0&mulfam3_4==0&mulfam5_19==0&mulfam20_==0,1,0)) %>%
  
  group_by(sf_only) %>%
  
  summarize(area = sum(land_area)) %>%
  
  ungroup() %>%
  
  mutate(share = area/sum(area))
