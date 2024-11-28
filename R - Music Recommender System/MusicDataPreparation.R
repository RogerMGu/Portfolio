##### MUSIC DATA PREPARATION SCRIPT #####
# Roger Monclus Guma
# 21/11/2024

#### The purpose of this script is to clean and transform the data in order to be prepared for EDA, data modeling or a recommendation system.

# This script receives data from 1.2 M songs and outputs a DF with the features of each track (df_tracks_prepared) 
# and another DF with the average features of each artist (df_artists). Both DF's will be used in the recommendation system (next script).


#### LOAD PACKAGES ####

if(!require('tidyverse')) install.packages('tidyverse'); library('tidyverse')

#### 0. IMPORT THE DATA ####

# The tracks_features.csv file contains over 1.2 million tracks from Spotify obtained through Kaggle: 
# https://www.kaggle.com/datasets/rodolfofigueroa/spotify-12m-songs

#setwd("Write here your directory where tracks_features.csv is")
tracks <- read.csv("tracks_features.csv")


#### 1. PREPARING TRACKS DATAFRAME ####

# This DF will contain the features for each track in the data.

### 1.1. REMOVE IRRELEVANT COLUMNS ###

tracks[, c("track_number", "disc_number", "release_date")] <- list(NULL)


### 1.2. DROP DUPLICATES ###

tracks_no_id <- tracks
tracks_no_id$id <- NULL
sum(duplicated(tracks_no_id)) # There are 72 duplicated songs

tracks <- tracks[!duplicated(tracks_no_id),]
tracks_no_id <- NULL


### 1.3. CHANGE TYPING ###

# explicit as a binary variable
tracks$explicit <- as.integer(ifelse(tracks$explicit == "True", 1, 0))
# key as a factor (nominal) variable
tracks$key <- as.factor(tracks$key)

# release_date in Date format
#tracks$release_date <- as.Date(tracks$release_date, format="%Y-%m-%d") # There are NA
# This created over 130k NA because some tracks only have the Year in the release_date column.

# Duration from milliseconds to seconds
tracks$duration_s <- tracks$duration_ms/1000
tracks$duration_ms <- NULL


### 1.4. MISSINGS AND ERRORS ###

colSums(is.na(tracks)) # 0 NA

summary(tracks)

## YEAR

# There is an artist with a zero in the year variable. This has a significant impact on the min maxing of this column. 
# I will input the median year in its place.
tracks[tracks$year == 0, ]$year <- median(tracks[tracks$year > 0, "year"])

## DURATION_S
# Minimum duration

# There are songs that last 1 second that are used as a bridge inside a music album. There are also poetry, intros and outros.
head(tracks[order(tracks$duration_s),c("duration_s", "name")], 200)
head(tracks[tracks$duration_s >= 10 & tracks$duration_s <= 30 , c("duration_s", "name", 'artists')])

# I think it's fair to consider it is a song if its duration is at least 1 minute. So I will drop all tracks that last less than 60 seconds.
tracks <- tracks[tracks$duration_s >= 60,]

# Another approach would be to do a ML model to classify audios into songs and not songs.


# Maximum duration

# The tracks that last longer are mixes or recompilation of different songs. These should be eliminated. Where to draw the line?
# There are tracks that are classical music that last over 20 minutes. Do I want to include classical music in this project?
# Songs usually don't last over 5 or 6 minutes.
head(tracks[order(tracks$duration_s, decreasing = T),c("duration_s", "name")], 30)
head(tracks[tracks$duration_s >= 480 & tracks$duration_s <= 540 , c("duration_s", "name", 'artists')])

# Since classical music is not the main target of this recommender system, I will draw the line at 10 minutes.
tracks <- tracks[tracks$duration_s <= 600,]


## TIME_SIGNATURE
# Time signature of 0 or 1 are most likely errors.
# - Input with the mode = 4.
# - Input with another method using the other variables (multinomial model).
# - Create another category for the errors (NA or other) and keep it as another one.
table(tracks$time_signature)
nrow(tracks[tracks$time_signature == 0 | tracks$time_signature == 1,]) # 17483

tracks[tracks$time_signature == 0 | tracks$time_signature == 1, ]$time_signature <- which.max(table(tracks$time_signature))[[1]]
tracks$time_signature <- as.factor(tracks$time_signature)


## TEMPO
#tempo == 0 ? Data error, experimental or ambient music.
summary(tracks[tracks$tempo != 0,]$tempo)
tail(tracks[tracks$tempo == 0 , c("tempo", "name", 'artists')]) 

nrow(tracks[tracks$tempo == 0,]) # 410

# - Input missings with mean or median.
# - Input missings with a more robust method.

tracks[tracks$tempo == 0, ]$tempo <- mean(tracks[tracks$tempo != 0, ]$tempo)

summary(tracks)


## ARTISTS
# 'Various Artists' is treated as if he was an artist
# Since I can't know the artists of these songs, they can't be part of the recommender system.
nrow(tracks[tracks$artists == "['Various Artists']" , ]) #1569

tracks <- tracks[tracks$artists != "['Various Artists']" , ]

summary(tracks)


### 1.5. NORMALIZATION ###

# Min max normalization for numerical (continuous) data
names_numeric <- c("danceability", "energy", "loudness", "speechiness", "acousticness", "instrumentalness", "liveness", "valence", "tempo",
                   "duration_s")
min_max_scaling <- function(v){ # min maxing function
  v <- (v-min(v))/(max(v)-min(v))
}
tracks$year_n <- min_max_scaling(tracks$year)

tracks[, colnames(tracks) %in% names_numeric] <- as.data.frame(lapply(tracks[, colnames(tracks) %in% names_numeric]
                                                                      , min_max_scaling))


### 1.6. CHANGE TEXT FORMAT ###

# Remove square brackets for artist_ids and artists 
tracks$artist_ids <- gsub("\\[", "", tracks$artist_ids)
tracks$artist_ids <- gsub("\\]", "", tracks$artist_ids)

tracks$artists <- gsub("\\[", "", tracks$artists)
tracks$artists <- gsub("\\]", "", tracks$artists)


tracks[str_which(tracks$artists, "Wiener Philharmoniker"),]

# Substitute " for ' in artist's names.
tracks$artists <- gsub('"', "'", tracks$artists)

tracks[str_which(tracks$artists, "Wiener Philharmoniker"),]
tracks_full[str_which(tracks_full$artists, "'") , ]


### 1.7. SAVE PREPARED DATA ###

# Save tracks prepared dataframe into a .csv file
write.csv(tracks, "df_tracks_prepared.csv", row.names=F)
#tracks <- read.csv("df_tracks_prepared.csv")



#### 2. PREPARING ARTISTS DATAFRAME ####

# This DF will contain the mean or median value for numeric variables and the proportion of 1's for dichotomic or binary variables. 


### 2.1. HANDLING TRACKS WITH MULTIPLE ARTISTS ###

# A function to obtain the different artists in a track.
# This function returns an artist as a character (if only 1) or multiple artists in a vector.
sep_artists <- function(artist){
  # Splits the artist text by ', ' which results in a vector with all the artists in it.
  mult_artists <- strsplit(artist, "', '")[[1]]
  # Removes the first apostrophe from the first artist.
  mult_artists[1] <- sub(".", "", mult_artists[1]) 
  # Removes the last apostrophe from the last artist.
  mult_artists[length(mult_artists)] <- substr(mult_artists[length(mult_artists)], 1, 
                                               nchar(mult_artists[length(mult_artists)])-1)
  # Returns the vector with the artists.
  return(mult_artists)
}

# An example with only 1 artist.
sep_artists(tracks$artists[1])

# An example with multiple artists.
sep_artists(tracks$artists[153279])

# To calculate the average values of the songs for each artist, I need to have only one artist per song. This means that songs with 
# multiple artists must be duplicated times the number of artists.

# Expanding the tracks data.
sum(str_detect(tracks$artist_ids, ",")) # There are 281439 songs with multiple artists
tracks_dupl <- tracks[str_detect(tracks$artist_ids, ","), ] # which songs have at least 2 artists
num_times <- as.vector(str_count(tracks_dupl$artist_ids, ",")+1) # number of artists per song
tracks_dupl_full <- data.frame(lapply(tracks_dupl, rep, num_times)) # Duplicate each song (row) for the number of artists

# Removes the first and last apostrophe from the 1 artist DF.
tracks_1artist <- tracks[!tracks$id %in% tracks_dupl$id,]
tracks_1artist <- tracks_1artist %>% 
  mutate(artists = substr(artists, 2, nchar(artists) - 1),
         artist_ids = substr(artist_ids, 2, nchar(artist_ids) - 1))


# The following script section takes over 30 minutes to run. If you would like to skip it and load the resulting data, please indicate "no".
# If, on the contrary, you desire to run it, say "yes".

execute_section <- readline("Do you wish to run the slow function? (yes/no): ")

if (tolower(execute_section) == "yes"){
  
  areyousure <- readline("Are you sure? It can take over 30 minutes. (yes/no): ")
  
  if (tolower(areyousure) == "yes"){
    print("Be patient, please.")
    # This loop will make the duplicate rows for a song have a different artist each.
    k <- 1 # tracks_dupl_full row index
    
    for(i in 1:nrow(tracks_dupl)){ # This loop took over 30 minutes
      all_artists <- sep_artists(tracks_dupl[i, "artists"])
      all_ids <- sep_artists(tracks_dupl[i, "artist_ids"])
      
      tracks_dupl_full[k:(k+length(all_artists)-1), "artists"] <- all_artists
      tracks_dupl_full[k:(k+length(all_ids)-1), "artist_ids"] <- all_ids
      
      k <- k + length(all_artists)
      
    }
    
    # Merge the tracks with 1 artist and the duplicated tracks with an artist each.
    tracks_full <- rbind(tracks_1artist, tracks_dupl_full)
    
    # Saving the data because the last loop took a long time (around 30 minutes).
    write.csv(tracks_full, "tracks_full.csv", row.names=F) 
    
  }
  
}

if (tolower(execute_section) == "no" || (tolower(areyousure) == "no")){
  fileready <- readline("Do you have the tracks_full.csv file ready in the same folder as this script? (yes/no): ")
  if (fileready == "yes"){
    # Reading the data.
    tracks_full <- read.csv("tracks_full.csv")
    # Changing typing after reading the data.
    tracks_full$key <- as.factor(tracks_full$key)
    #tracks_full$release_date <- as.Date(tracks_full$release_date, format="%Y-%m-%d")
  } else {
    print("Please find the tracks_full.csv file and download it into the folder that contains this script.")
  }
  
}


### 2.2. ATTRIBUTES PER ARTIST ###

# Function to calculate the mode for categorical features.
getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

# Getting the mean attributes per artist (into a Tibble)
dfartists <- tracks_full %>%
  group_by(artist_ids) %>% 
  reframe(artists = first(unique(artists)), explicit = mean(explicit), danceability = mean(danceability), energy = mean(energy), 
          loudness = mean(loudness), mode = mean(mode), speechiness = mean(speechiness), acousticness=mean(acousticness), 
          instrumentalness = mean(instrumentalness), liveness = mean(liveness), valence = mean(valence), tempo = mean(tempo), 
          year = median(year), duration_s = mean(duration_s), key = getmode(key), time_signature = getmode(time_signature))

summary(dfartists)


### 2.3. NORMALIZING ATTRIBUTES ###

# Min max normalizing year and duration
names_numeric <- c("danceability", "energy", "loudness", "speechiness", "acousticness", "instrumentalness", "liveness", "valence", "tempo",
                   "duration_s")
min_max_scaling <- function(v){ # min maxing function
  v <- (v-min(v))/(max(v)-min(v))
}
dfartists$year_n <- min_max_scaling(dfartists$year)

dfartists[, colnames(dfartists) %in% names_numeric] <- as.data.frame(lapply(dfartists[, colnames(dfartists) %in% names_numeric]
                                                                      , min_max_scaling))
summary(dfartists)


### 2.4. TEXT FORMATTING ###

# Removing ' ' from artists and artist_ids from dfartists. There is only 1 artist per row.
#dfartists$artist_ids <- gsub("'", "", dfartists$artist_ids)
#dfartists$artists <- gsub("'", "", dfartists$artists)


### DUPLICATED ARTIST IDS ###
sum(duplicated(dfartists$artist_ids)) # 0
sum(duplicated(dfartists$artists)) # 2933
sum(duplicated(dfartists$artists) & duplicated(dfartists$artist_ids)) # 0
dfartists[duplicated(dfartists$artists) & order(dfartists$artists),c('artists', 'artist_ids')]


### 2.5. SAVING THE ARTISTS DF ###

# Convert to a dataframe because it was Tibble 
dfartists <- as.data.frame(dfartists)

# Saving the artists for the recommender
write.csv(dfartists, "df_artists.csv", row.names=F)
#dfartists <- read.csv("df_artists.csv")


dfartists[str_which(dfartists$artists, 'Bring Me The Horizon'),]
dfartists[str_which(dfartists$artists, 'The 1975'),]

tracks_full[str_which(tracks_full$artists, 'Bring Me The Horizon'),]%>% 
  group_by(artist_ids, artists) %>% 
  summarise(dance = danceability)

tracks_full[str_which(tracks_full$artists, 'The 1975'),]
