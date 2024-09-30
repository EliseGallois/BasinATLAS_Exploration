# An exploratory analysis of the BasinATLAS data
# Elise Gallois, elise.gallois94@gmail.com (Github: EliseGallois)

# 1. Import Libraries ----
# remotes::install_github("r-spatial/mapview") # run only once
library(tidyverse) # for data cleaning and plotting
library(readxl) # for reading in excel files
library(sf) # for spatial data
library(mapview) # for interactive mapping
library(rnaturalearth) # to subset countries
library(shiny) # to create shiny app
library(rsconnect) # to publish shiny app
library(viridis) # for colourblind friendly visualisation

# 2. Load GDB Data & inspect variables of interest ----
global_basin <- "data/gdb/BasinATLAS_Data_v10.gdb/BasinATLAS_v10.gdb/"
st_layers(global_basin) # view properties of layers

# load and inspect level 4
lvl4 <- st_read(global_basin, "BasinATLAS_v10_lev04")
str(lvl4) # view all columns 
mapview::mapview(lvl4) # view leaflet version of level 4

# load and inspect level 1
lvl1 <- st_read(global_basin, "BasinATLAS_v10_lev01")
str(lvl1) # view all columns 
mapview::mapview(lvl1) # view leaflet version of level 1

# load and inspect level 6 - and plot variables of interest
lvl6 <- st_read(global_basin, "BasinATLAS_v10_lev06")
str(lvl6) # view all columns 
mapview::mapview(lvl6, zcol = "glc_pc_s06") # interactive land use level 6
mapview::mapview(lvl6, zcol = "run_mm_syr") # interactive land surface runoff level 6

# load and inspect level 7 - and plot variables of interest
lvl7 <- st_read(global_basin, "BasinATLAS_v10_lev07")
str(lvl7) # view all columns 
mapview::mapview(lvl7, zcol = "glc_pc_s07") # interactive land use level 6
mapview::mapview(lvl7, zcol = "run_mm_syr") # interactive land surface runoff level 6

# load and inspect level 9 - and plot variables of interest
lvl9 <- st_read(global_basin, "BasinATLAS_v10_lev09")
str(lvl9) # view all columns
mapview::mapview(lvl9, zcol = "glc_pc_s09") # interactive land use level 6
mapview::mapview(lvl9, zcol = "run_mm_syr") # interactive land surface runoff level 6

# 3. Subset by Country ----
# by Canada
canada <- ne_countries(scale = "medium", country = "canada", returnclass = "sf")
plot(canada)

# crop lvl6 basin data to canada size only
lvl6 <- st_make_valid(lvl6)
canada <- st_make_valid(canada)
canada_lvl6 <- st_intersection(lvl6, canada)

# plot data in mapview  
mapview::mapview(canada_lvl6, zcol = "run_mm_syr") # land surface runoff
mapview::mapview(canada_lvl6, zcol = "glc_pc_s06") # land cover classification

# 4. Import legend data and merge df ----
# get legend names for the land cover types
legend <- read_excel("data/gdb/BasinATLAS_Data_v10.gdb/HydroATLAS_v10_Legends.xlsx", sheet = "glc_cl")

# merge the legend data with the canada data
canada_lvl6 <- canada_lvl6 %>%
  left_join(legend, by = c("glc_pc_s06" = "GLC_ID"))

canada_lvl6 <- canada_lvl6 %>%
  mutate(glc_pc_s06 = GLC_Name) %>%
  select(-GLC_Name)

# make sure it is a factor variable
canada_lvl6 <- canada_lvl6 %>%
  mutate(glc_pc_s06 = factor(glc_pc_s06))

# plot data in ggplot and save
(runoff_plot <- ggplot(data = canada_lvl6) +
    geom_sf(aes(fill = run_mm_syr)) +
    scale_fill_viridis_c(direction = -1) +  
    theme_bw() +
    labs(fill = "Land Surface Runoff (mm/yr)", 
         title = "Canada Basin Map (Level 6)", 
         subtitle = "Land Surface Runoff (run_mm_syr)") +
    guides(fill = guide_legend(title.position = "top")))

# ggsave in figures folder
ggsave("shiny/figures/canada_runoff_plot.png", plot = runoff_plot, width = 10, height = 10, units = "in")

(landuse_plot <- ggplot(data = canada_lvl6) +
    geom_sf(aes(fill = glc_pc_s06)) +  
    scale_fill_viridis_d() +  
    theme_bw() +
    theme(
      legend.position = "bottom",    
      legend.box = "vertical",      
      legend.text = element_text(size = 8)) +
    labs(fill = "Land Use Classification", 
         title = "Canada Basin Map (Level 6)", 
         subtitle = "Land Use Classification (glc_pc_s06)") +
    guides(fill = guide_legend(title.position = "top", nrow = 8)))

# adjust so a similar size to runoff plot
ggsave("shiny/figures/canada_landuse_plot.png", plot = landuse_plot, width = 16, height = 16, units = "in")

# 5. Save Canada data ----
write_csv(canada_lvl6, "data/canada_lvl6.csv")

# only keep necessary columns for the shiny aka runoff geometry and land use
canada_lvl6 <- canada_lvl6 %>%
  select(run_mm_syr, glc_pc_s06, Shape)

# save as a feature collection
st_write(canada_lvl6, "shiny/canada_lvl6.geojson")

# save as RDS
saveRDS(canada_lvl6, file = "shiny/canada_lvl6.rds")


# 6. Deploy the shiny app ----

# link account
rsconnect::setAccountInfo(name='q0yfxi-elise0g',
                          token='7F91DACEA09C2DC69A02321FEF51A735',
                          secret='5d8WKIWcHX481+uzlimrobqrGJrFJ3gz1BwrdRJ2')

# deploy app (kept in shiny folder of repo)
rsconnect::deployApp('shiny/')
rsconnect::restartApp('shiny')









