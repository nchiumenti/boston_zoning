library(tidyverse)

data<-sf::read_sf("C:\\01_current_projects\\_Boston Zoning Paper\\zoning_atlas_latlong.shp")

data2 <- as.data.frame(data)

data2 %>%
  
  filter(zo_usety==1) %>%
  
  select(-geometry) %>%
  
  mutate(sf_only = if_else(mulfam2==0&mulfam3_4==0&mulfam5_19==0&mulfam20_==0,1,0)) %>%
  
  group_by(sf_only) %>%
  
  summarize(area = sum(land_area)) %>%
  
  ungroup() %>%
  
  mutate(share = area/sum(area))
