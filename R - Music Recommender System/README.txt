Data obtained from Kaggle: https://www.kaggle.com/datasets/rodolfofigueroa/spotify-12m-songs

The data can also be obtained from a Google Drive folder: https://drive.google.com/drive/folders/1kAPSInkKW76yNmzLFGFMGF2twK7Qyjx5?usp=sharing

Access to the Music Recommender System: https://rogermgu.shinyapps.io/MusicRecommenderSystem/


Do you want to execute the code by yourself?

1. Download the data and scripts
  - tracks_features.csv contains the original data from kaggle.
  - tracks_full.csv contains the data with some transformations.
  - MusicDataPreparation.R cleans and preprocesses the data.
  - MusicRecommender.R contains the code with the recommender function and the shiny app.

Note: make sure to save all the files in the same folder.

2. Execute MusicDataPreparation.R
  This R script will:
  - Load the tidyverse package.
  - Load tracks_features.csv.
  - Load tracks_full.csv if you choose to. This will skip a part of the code that takes around 30 minutes.
  - Select only the relevant columns.
  - Set the correct typing of each column.
  - Fix errors.
  - Normalize numeric data.
  - Change some texting format.
  - Create another dataframe for artists' average feature.
  The output of the script are the file df_tracks_prepared.csv and df_artists.csv, which will be used in the next script.

3. Execute MusicRecommender.R
  This R script will:
  - Load tidyverse, shiny, shinythemes, stringi, shinysky and markdown packages.
  - Load df_tracks_prepared.csv
  - Load df_artists.csv
  - Create the function that calculates the k most similar songs or artists to the ones given.
  - Create the interactive app with the shiny package
