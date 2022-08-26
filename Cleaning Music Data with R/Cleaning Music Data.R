##### DATA CLEANING PROJECT #####
# Roger Monclus Guma
# 26/08/2022

# The goal of this project is to make the data of over a million tracks functional for EDA, data modeling or a system recommendation.
#Make sure to set the directory to the folder with the "tracks_features.csv" file.


tracks <- read.csv("tracks_features.csv")


### Char variables as Factor
tracks$explicit <- as.factor(tracks$explicit)
tracks$mode <- factor(tracks$mode, levels=c(0,1), labels=c("Minor", "Major"))
tracks$key <- as.factor(tracks$key)


### Date format
tracks$release_date <- as.Date(tracks$release_date, format="%Y-%m-%d") # Some Dates are missing
# This created over 130k NA because some tracks only have the Year in the release_date column.

### Get the Month from Date Format
tracks$month <- as.numeric(format(tracks$release_date, "%m"))
# month also has 130k NA as explained above.


### Duration_ms to seconds
tracks$duration_s <- tracks$duration_ms/1000
tracks$duration_ms <- NULL


### Remove irrelevant columns
tracks[, c("track_number", "disc_number")] <- list(NULL)


### Min max normalization for numerical (continuous) data
names_numeric <- c("danceability", "energy", "loudness", "speechiness", "acousticness", "instrumentalness", "liveness", "valence", "tempo")
vars_num <- tracks[, colnames(tracks) %in% names_numeric]
summary(vars_num)

min_max_scaling <- function(v){
  v <- (v-min(v))/(max(v)-min(v))
}

tracks[, colnames(tracks) %in% names_numeric] <- as.data.frame(lapply(vars_num, min_max_scaling))

summary(tracks[, colnames(tracks) %in% names_numeric])


### Square brackets are not needed for artist_ids nor artists
tracks$artist_ids <- gsub("\\[", "", tracks$artist_ids)
tracks$artist_ids <- gsub("\\]", "", tracks$artist_ids)

tracks$artists <- gsub("\\[", "", tracks$artists)
tracks$artists <- gsub("\\]", "", tracks$artists)

### Save Cleaned Data into a .csv file
write.csv(tracks, "tracks_cleaned.csv", row.names=F)

# Now you can load "tracks_cleaned.csv" on your next projects.

### Function useful for separating different artists
# Giving the artists of a track, this function returns the artist as a character or multiple artists in a vector

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
