
# 20/02/2021
# TAYOSO

# educational ------------------------------------------------------------
# Use renv::init() to initialize a project. renv will discover the R packages used in your project, and install those packages into a private project library.
#   Work in your project as usual, installing and upgrading R packages as required as your project evolves.
# Use renv::snapshot() to save the state of your project library. The project state will be serialized into a file called renv.lock.
# Use renv::restore() to restore your project library from the state of your previously-created lockfile renv.lock.
# Use renv::history() to view past versions of renv.lock that have been committed to your repository, and find the commit hash associated with that particular revision of renv.lock.
# Use renv::revert() to pull out an old version of renv.lock based on the previously-discovered commit, and then use renv::restore() to restore your library from that state


# set up project env in the current directory
## setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# renv::init()  
# renv::snapshot()

# load packages -----------------------------------------------------------
library(sf)
library(lwgeom)
library(dplyr)
library(data.table)
library(config)
library(yaml)
library(renv)


# read yaml file --------------------------------------------------------
config <- config::get(file = "./config.yml")

# load data --------------------------------------------------------------
data <- read.csv(paste0(config$link,config$train_sample))
stadiums <- read.csv(paste0(config$link,config$stadiums))
stations <- read.csv(paste0(config$link,config$stations))
national_parks <- st_read(paste0(config$link,config$national_parks))


# load functions ---------------------------------------------------------
get_nearest_feature_column_and_geom <- function(x, y, col = "column", geom = "geometry") {
  # x is the object you want to append a column to
  # y is the object you want to get the column from
  # col is the unique id column to add from y to x
  # geom is the name of the active geometry column
  res <- y[st_nearest_feature(x, y), c(col, geom)]
  x[, c(col, "geometry.y")] <- res[, c(col, geom)]
  return(x)
}
create_lists <- function(x, splits = 29,each = 1){
  my_split <- base::rep(1:splits,each = each, length = nrow(x))
  my_split2 <- dplyr::mutate(x, my_split = my_split)
  list_lists <- base::split(my_split2,my_split2$my_split)
  #list_lists <- purrr::map(my_split3$data, ~ split(., func_arg))
  return(list_lists)
}
get_the_distance <- function(x, y) {
  # x is the data with the x geometry as the active geom
  # y is the data with the y geometry as the active geom
  for (i in 1:length(x)) {
    # message for progress
    message(paste0((i/length(x))*100,"% at ",Sys.time()))

    x_1 <- x[[i]]
    y_1 <- y[[i]]
    for (j in 1:nrow(x[[i]])) {
      # calculate the distance
      x_1$length_to_centroid[[j]] <- as.numeric(lwgeom::st_geod_distance(x_1[j, "geometry"], y_1[j, "geometry.y"]))
    }
    if (i == 1) {
      output.final <- x_1
    } else {
      output.final <- plyr::rbind.fill(output.final, x_1)
    }
  }

  return(as.data.frame(output.final))
}

# Stadiums --------------------------------------------------------------
# convert data to shpfile
data_shp <- st_as_sf(data,coords = c("longitude","latitude"), crs = 4326)
stadiums_shp <- st_as_sf(stadiums, coords = c("Longitude","Latitude"), crs = 4326)
# data_shp <- st_transform(data_shp,crs = 27700)
# stadiums_shp <- st_transform(stadiums_shp,crs = 27700)

# get the nearest stadiums to each ppt - add name (maybe add capacity) and also rename the app. columns
data_stadiums_shp <- get_nearest_feature_column_and_geom(data_shp,stadiums_shp,"Name","geometry")
colnames(data_stadiums_shp)[colnames(data_stadiums_shp) == "Name"] <- "stadium_name"

# duplicate the object and set the geometry for x id of get_the_distance()
data_stadiums_shp_dup <- data_stadiums_shp

# duplicate so the active geometry is that of y
data_stadiums_shp_dup_y <- data_stadiums_shp_dup
st_geometry(data_stadiums_shp_dup_y) <- "geometry.y"

# split x into lists of 3
data_stadiums_shp_lists <- create_lists(data_stadiums_shp_dup, 50)
data_stadiums_shp_y_lists <- create_lists(data_stadiums_shp_dup_y, 50)

# use the function above to get your output
# tic()
data_stadiums_shp_distance <- get_the_distance(data_stadiums_shp_lists, data_stadiums_shp_y_lists)
# toc()

# add capacity as 'stad_capacity', rename length_to_centroid as 'stad_distance' and deselect 'my_split' column
data_stadiums_shp_distance <- data_stadiums_shp_distance %>%
  left_join(stadiums[,c("Name","Capacity")], by = c("stadium_name"="Name")) %>%
  select(-my_split)
colnames(data_stadiums_shp_distance)[colnames(data_stadiums_shp_distance) == "Capacity"] <- "stad_capacity"
colnames(data_stadiums_shp_distance)[colnames(data_stadiums_shp_distance) == "length_to_centroid"] <- "stad_distance"

# test and delete
data_stadiums_shp_distance %>% mutate(stad_distance=as.integer(stad_distance)) %>% arrange(stad_distance) ## DELETE!!!!

# Stations ------------------------------------------------------------
# convert data to shpfile
data_stadiums_shp_distance <- st_as_sf(data_stadiums_shp_distance, crs = 4326) %>%
  select(-geometry.y)
stations_shp <- st_as_sf(stations, coords = c("Longitude","Latitude"), crs = 4326)

# get the nearest stations to each ppt
data_stations_shp <- get_nearest_feature_column_and_geom(
  data_stadiums_shp_distance,
  stations_shp,
  c("Station", "Entries.and.exits.2020"),
  "geometry")

# duplicate the object and set the geometry for x id of get_the_distance()
data_stations_shp_dup <- data_stations_shp

# duplicate so the active geometry is that of y
data_stations_shp_dup_y <- data_stations_shp_dup
st_geometry(data_stations_shp_dup_y) <- "geometry.y"

# split x into lists of 3
data_stations_shp_lists <- create_lists(data_stations_shp_dup, 50)
data_stations_shp_y_lists <- create_lists(data_stations_shp_dup_y, 50)

# use the function above to get your output
# tic()
data_stations_shp_distance <- get_the_distance(data_stations_shp_lists, data_stations_shp_y_lists)
# toc()

# rename Entries.and.exits.2020, rename length_to_centroid as 'stat_distance' and deselect 'my_split' column
data_stations_shp_distance <- data_stations_shp_distance %>%
  select(-my_split)
colnames(data_stations_shp_distance)[colnames(data_stations_shp_distance) == "Entries.and.exits.2020"] <- "stat_Entries.and.exits.2020"
colnames(data_stations_shp_distance)[colnames(data_stations_shp_distance) == "length_to_centroid"] <- "stat_distance"

# save image data
# save.image(paste0(config$link,config$image))
# load(paste0(config$link,config$image))

# national_parks ------------------------------------------------------
# free up the env
rm(data_stations_shp_lists)
rm(data_stations_shp_y_lists)
rm(data_stadiums_shp_lists)
rm(data_stadiums_shp_y_lists)

# convert data to shpfile and subset the data to aid faster processing
data_stations_shp_distance_2 <- st_as_sf(data_stations_shp_distance, crs = 4326) %>%
  select(id,geometry)
national_parks_shp <- st_transform(national_parks, crs = 4326) %>%
  select(name)

# convert polygon to point feature
national_parks_shp <- st_centroid(national_parks_shp)

# get the nearest national_parks to each ppt. We should not need "desig_date"?
data_national_parks_shp <- get_nearest_feature_column_and_geom(
  data_stations_shp_distance_2,
  national_parks_shp,
  "name",
  "geometry")

# duplicate the object and set the geometry for x id of get_the_distance()
data_national_parks_shp_dup <- data_national_parks_shp

# duplicate so the active geometry is that of y
data_national_parks_shp_dup_y <- data_national_parks_shp_dup
st_geometry(data_national_parks_shp_dup_y) <- "geometry.y"

# split x into lists of 3
data_national_parks_shp_lists <- create_lists(data_national_parks_shp_dup, 50)
data_national_parks_shp_y_lists <- create_lists(data_national_parks_shp_dup_y, 50)

# use the function above to get your output
# tic()
data_national_parks_shp_distance <- get_the_distance(data_national_parks_shp_lists, data_national_parks_shp_y_lists)
# toc()

# rename Entries.and.exits.2020, rename length_to_centroid as 'stat_distance' and deselect 'my_split' column
data_output <- data_national_parks_shp_distance %>%
  select(-my_split,-geometry.y, -geometry) %>%
  left_join(data_stations_shp_distance, by = "id") %>%
  select(-geometry.y)
colnames(data_output)[colnames(data_output) == "name"] <- "national_park_name"
colnames(data_output)[colnames(data_output) == "length_to_centroid"] <- "national_park_distance"

# free up the env
rm(data_national_parks_shp_lists)
rm(data_national_parks_shp_y_lists)

# save result
data_output %>%
  as.data.frame() %>%
  select(-c(geometry)) %>%
  write.csv(config$output)
