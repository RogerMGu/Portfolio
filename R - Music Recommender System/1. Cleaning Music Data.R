##### DATA CLEANING PROJECT #####
# Roger Monclus Guma
# 26/08/2022

#### The goal of this project is to make the data of over a million tracks functional for EDA, data modeling or a system recommendation.

# setwd("Write Here Your Directory with tracks_features.csv")
tracks <- read.csv("tracks_features.csv")


## Char variables as Factor
tracks$explicit <- as.factor(tracks$explicit)
tracks$mode <- factor(tracks$mode, levels=c(0,1), labels=c("Minor", "Major"))
tracks$key <- as.factor(tracks$key)


## Date format
tracks$release_date <- as.Date(tracks$release_date, format="%Y-%m-%d") # Some Dates are missing
# This created over 130k NA because some tracks only have the Year in the release_date column.


## Get the Month from Date Format
tracks$month <- as.numeric(format(tracks$release_date, "%m"))
# month also has 130k NA as explained above.


## Duration_ms to seconds
tracks$duration_s <- tracks$duration_ms/1000
tracks$duration_ms <- NULL


## Remove irrelevant columns
tracks[, c("track_number", "disc_number")] <- list(NULL)


## Min max normalization for numerical (continuous) data
names_numeric <- c("danceability", "energy", "loudness", "speechiness", "acousticness", "instrumentalness", "liveness", "valence", "tempo")
min_max_scaling <- function(v){
  v <- (v-min(v))/(max(v)-min(v))
}


## There is an artist with a "0" in the variable year. This affects a lot the min maxing of this column
tracks[tracks$year < 1900,]$year <- mean(tracks[tracks$year>=1900,]$year)

tracks[, colnames(tracks) %in% names_numeric] <- as.data.frame(lapply(tracks[, colnames(tracks) %in% names_numeric]
                                                                      , min_max_scaling))
tracks$year_n <- min_max_scaling(tracks$year)
tracks$duration_n <- min_max_scaling(tracks$duration_s)

summary(tracks[, colnames(tracks) %in% c(names_numeric, "year_n", "duration_n")])


## Square brackets are not needed for artist_ids nor artists 
tracks$artist_ids <- gsub("\\[", "", tracks$artist_ids)
tracks$artist_ids <- gsub("\\]", "", tracks$artist_ids)

tracks$artists <- gsub("\\[", "", tracks$artists)
tracks$artists <- gsub("\\]", "", tracks$artists)


## Some artists have " " between their names instead of ' '
tracks$artists <- gsub('"', "'", tracks$artists)


## Save Cleaned Data into a .csv file
write.csv(tracks, "tracks_cleaned.csv", row.names=F)

# Now you can load "tracks_cleaned.csv" on your next projects.


## Function useful for separating different artists
## Giving the artists of a track, this function returns the artist as a character or multiple artists in a vector

sep_artists <- function(artist){
  mult_artists <- strsplit(artist, "', '")[[1]]
  # Remove 1st apostrophe from first artist
  mult_artists[1] <- sub(".", "", mult_artists[1]) 
  # Remove last apostrophe from last artist
  mult_artists[length(mult_artists)] <- substr(mult_artists[length(mult_artists)], 1, 
                                               nchar(mult_artists[length(mult_artists)])-1) 
  
  return(mult_artists)
}

# An example with only 1 artist
sep_artists(tracks$artists[1])

# An example with multiple artists
sep_artists(tracks$artists[153279])
