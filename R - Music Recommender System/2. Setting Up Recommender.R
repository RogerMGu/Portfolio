##### Setting Up the Recommender System #####
# Roger Monclus Guma
# 27/08/2022


#### For the recommender I want to use a dataframe with the data of each artist. 
#### I'll obtain the mean or median for numeric variables. I could also calculate the proportion for dichotomic variables. 


## Reading data cleaned from the Cleaning Music Data.R script
# setwd("Write Here Your Directory with tracks_cleaned.csv")
tracks <- read.csv("tracks_cleaned.csv")


## Loading tidyverse package
if(!require('tidyverse')) install.packages('tidyverse'); library('tidyverse')


## I'll use the function created on Cleaning Music Data.R to split multiple artists
sep_artists <- function(artist){
  mult_artists <- strsplit(artist, "', '")[[1]]
  # Remove 1st apostrophe from first artist
  mult_artists[1] <- sub(".", "", mult_artists[1]) 
  # Remove last apostrophe from last artist
  mult_artists[length(mult_artists)] <- substr(mult_artists[length(mult_artists)], 1, 
                                               nchar(mult_artists[length(mult_artists)])-1) 
  
  return(mult_artists)
}


## Expanding the tracks data
sum(str_detect(tracks$artist_ids,",")) # There are 281439 songs with multiple artists
tracks_dupl <- tracks[str_detect(tracks$artist_ids, ","), ] # which songs have at least 2 artists
num_times <- as.vector(str_count(tracks_dupl$artist_ids, ",")+1) # number of artists per song
tracks_dupl_full <- data.frame(lapply(tracks_dupl, rep, num_times)) # Duplicate each song (row) for the number of artists


## This loop will make the duplicated rows for a song have one artist each
k <- 1 # tracks_dupl_full row

for(i in 1:nrow(tracks_dupl)){ # This loop took over 30 minutes
  all_artists <- sep_artists(tracks_dupl[i, "artists"])
  all_ids <- sep_artists(tracks_dupl[i, "artist_ids"])
  
  tracks_dupl_full[k:(k+length(all_artists)-1), "artists"] <- all_artists
  tracks_dupl_full[k:(k+length(all_ids)-1), "artist_ids"] <- all_ids
  
  k <- k+length(all_artists)
  
}


## Merge the tracks with only 1 artist and the duplicated songs with 1 artist each
tracks2 <- rbind(tracks[!tracks$id %in% tracks_dupl$id,], tracks_dupl_full)


## Saving this data because the last loop took a while 
write.csv(tracks2, "tracks_dupl.csv", row.names=F) 
#tracks2 <- read.csv("tracks_dupl.csv")


## Getting the mean attributes per artist (into a Tibble)
dfartists <- tracks2 %>% 
  group_by(artist_ids) %>% 
  summarise(artists=unique(artists), danceability=mean(danceability), energy=mean(energy), loudness=mean(loudness), speechiness=mean(speechiness),
            acousticness=mean(acousticness), instrumentalness=mean(instrumentalness), liveness=mean(liveness), valence=mean(valence),
            tempo=mean(tempo), year=as.integer(median(year)), duration_s=mean(duration_s))

# Missing variables: Explicit, Key, Mode, Time Signature, Month


## Min max normalizing year and duration
min_max_scaling <- function(v){
  v <- (v-min(v))/(max(v)-min(v))
}
dfartists$year_n <- min_max_scaling(dfartists$year)
dfartists$duration_n <- min_max_scaling(dfartists$duration_s)


## Removing ' ' from artists and artist_ids from dfartists. There is only 1 artist per row.
dfartists$artist_ids <- gsub("'", "", dfartists$artist_ids)
dfartists$artists <- gsub("'", "", dfartists$artists)


## Convert to a dataframe because it was Tibble 
dfartists <- as.data.frame(dfartists)


## Saving the artists for the recommender
write.csv(dfartists, "dfartists.csv", row.names=F)
#dfartists <- read.csv("dfartists.csv")
