##### Music Recommender System #####
# Roger Monclus Guma
# 21/11/2024


## This script calculates music recommendations and shows them on a website.
## It takes a couple minutes to deploy.

# Link to the recommender on the website: https://rogermgu.shinyapps.io/MusicRecommenderSystem/
# If it doesn't work for you, write me at: monclusr@gmail.com


## Loading required packages
library(shiny)
library(shinythemes)
library(stringi)
library(tidyverse)
library(shinysky)
library(markdown)


## Loading tracks and artists. You must have this .csv files in the same folder as this MusicRecommender.R script
tracks <- read.csv("df_tracks_prepared.csv")
dfartists <- read.csv("df_artists.csv")

## Indicating which columns will be used to calculate the similarity
selection <- c("danceability", "energy", "loudness", "speechiness", "acousticness", "instrumentalness", "liveness", 
              "valence", "tempo", "duration_s", "year_n") # explicit, mode, key, time_signature
#tracks$key <- as.factor(tracks$key) ; tracks$time_signature <- as.factor(tracks$time_signature)
#dfartists$key <- as.factor(dfartists$key) ; dfartists$time_signature <- as.factor(dfartists$time_signature)

## Ordering artists by year for the select input
autocompletelist <- dfartists[order(dfartists$year, decreasing=T), "artists"]


## This function calculates "k" recommendations for a given artist or artist+song
MusicRecommenderFunction <- function(myartist, mysong = "None", k, weight, tracks, dfartists){
  
  
  idartist <- dfartists[which(dfartists$artists == myartist), "artist_ids"]        # ID of the artist
  
  
  ##### Artist recommender #####
    
  ref1 <- which(dfartists$artist_ids %in% idartist)[1] # If I remove the [1], this will check 
                                                     # if there are multiple artists with the same name
  reference1 <- dfartists[ref1, selection]           # The attributes of the artist given 
                                                     # which will be compared to the rest of the artists
    
  dfartists <- dfartists[-ref1, ]  # Data without the artist given 
    
    
  ## Sample of artists. It takes too long to calculate a 158009 * 12 table with all the artists.
  ## It would be ideal to have the genres of each artist and select a sample within the artists 
  ##  that have at least a genre in common with the artist given.
  ## I'm not using a seed so that the recommendations are different each time.
  dfartists_sample <- dfartists[sample(1:nrow(dfartists), 5000), ]

  ## Calculating similarity. Since all the attributes are in the same [0, 1] scale, I will calculate the absolute difference.
  dfart_similarities <- unlist(apply(dfartists_sample[,selection], 1, function(x) abs(x - reference1)))
  dfart_similarities <- matrix(dfart_similarities, nrow=nrow(dfartists_sample), byrow=T)
  rownames(dfart_similarities) <- rownames(dfartists_sample)
  colnames(dfart_similarities) <- selection
  dfartists_sample$similarity <- 1 - drop(dfart_similarities %*% weight)/length(selection) # Add similarity as a column to the artists data
    
  dfart_similarities_ordered <- dfartists_sample[order(dfartists_sample$similarity, decreasing=T),] # Order the artists data by similarity
    
  if(mysong=="None"){ ##### OUTPUT ONLY ARTISTS #####
    
    ## If no song is given, the outcome will be a list of the most similar artists.
    returnvars <- c("artists", "danceability", "acousticness", "valence", "year" # Which variables will be shown
                     #, "similarity"
    )
    
    print(dfart_similarities_ordered[1:k, returnvars]) 
    
  } else { ##### Song recommender #####
    
    ## Otherwise, if a song is given, the outcome will be a list of songs.
    possible_songs <- which(tracks$name == mysong) # Position of songs with the song name given
    right_song <- str_which(tracks[possible_songs,]$artist_ids, idartist)[1] # Takes the first song with the artist given
    ind_song <- possible_songs[right_song]
    reference2 <- tracks[ind_song, selection] # The attributes of the song given 
                                              # which will be compared to the rest of the songs

    ## Since there are over a million songs, I'll use the fact that I know the most similar artists to the one from the song given.
    artists0 <- dfart_similarities_ordered[1:150,'artist_ids']

    # Then, from the most similar artists, I get all their songs
    dfsongs <- tracks[str_which(tracks$artist_ids, paste(artists0, collapse="|")) # This takes about half a minute
                        , c("id", "name", "artists", "artist_ids", selection, "year")]
    
    
    ## Calculating similarity. Pretty much the same calculations from before
    dfsongs1 <- unlist(apply(dfsongs[, selection], 1, function(x) abs(x - reference2)))
    
    dfsongs1 <- matrix(dfsongs1, nrow=nrow(dfsongs), byrow=T)
    rownames(dfsongs1) <- rownames(dfsongs)
    colnames(dfsongs1) <- selection
    
    dfsongs$similarity <- 1 - drop(dfsongs1 %*% weight)/length(selection)
    
    # Order songs by similarity
    dfsongs <- dfsongs[order(dfsongs$similarity, decreasing=T),]
    
    
    ## Table with the k most similar songs. I do this step to make sure every song recommended has a different artist.
    list_art <- c() # This list will contain the ids of the artists
    dfsongs_ord <- dfsongs[FALSE,] # Getting a blank copy of the songs data frame to fill now with k songs.
    j <- 1 # Initiate this for keeping track of the row of the new data frame

    while(length(list_art) < k){ # Iterate until I reach a list of k songs (and artists)
      
      list_art <- c(list_art, dfsongs$artist_ids[1]) # add the new artist to the list
      dfsongs_ord[j,] <- dfsongs[1,] # save his most similar song to the table
      
      remove_these <- grepl(list_art[j], dfsongs$artist_ids)  # find the songs from the artist added to the list
      dfsongs <- dfsongs[!remove_these,] # removing those songs
      j <- j + 1 # Move to the next row
    }
    
    dfsongs_ord$artists <- gsub("'", "", dfsongs_ord$artists) # For better visualization
    names(dfsongs_ord)[which(names(dfsongs_ord)=="name")] <- "song"
    returnvars <- c("song","artists", "danceability", "acousticness", "valence", "year" # Attributes that will be shown
                    #, "similarity"
    )
    
    #### OUTPUT SONGS WITH ARTIST #####
    print(dfsongs_ord[, returnvars])
    
    
  } 
  
}

### TO TEST THE FUNCTION
# result <- MusicRecommenderFunction(myartist="Rage Against The Machine", k=7, weight=rep(1,length(selection)), tracks=tracks, dfartists=dfartists)
# result2 <- MusicRecommenderFunction(myartist="Rage Against The Machine", mysong="Testify", k=10, 
    #                       weight = rep(1,length(selection)), tracks=tracks, dfartists=dfartists)
# myartist="Rage Against The Machine"; mysong="Testify"; k=10;
# weight = rep(1,length(selection)); tracks=tracks; dfartists=dfartists

# Giving a song with multiple artists:
# myartist="Jamie 3:26"; mysong="Testify"; k=10;
# weight = rep(1,length(selection)); tracks=tracks; dfartists=dfartists


## From here on, the code is to create the interactive app on the web with Shiny package.

####################################
# User interface                   #
####################################

ui <- fluidPage(theme = shinytheme("united"),
                navbarPage("",
                           tabPanel("Recommender",
                                    tags$head(
                                      tags$style(HTML(" .shiny-output-error-validation { color: red;}"))
                                    ),
                                    
                                    headerPanel('Music Recommender System'),
                                    
                                    sidebarPanel(
                                      
                                      tags$label(h2('Input parameters')),
                                      
                                      br(),br(),
                                  
                            
                                      ### Select an artist
                                      selectizeInput(
                                        inputId = 'artist',
                                        label = 'Enter your favourite artist:',
                                        choices = NULL,
                                        selected = "The Beatles",
                                        multiple = FALSE, # allow for multiple inputs
                                        options = list('create' = F, 'persist'=T
                                                       , 'placeholder'='select an artist', 'maxOptions'=7500  # Needs this for Shiny to work
                                        ) # if create=T, allows inputs not in choices
                                      ),
                                      
                                      
                                      ### Select a song (optional)
                                      selectizeInput(
                                        inputId = 'song',
                                        label = 'Enter your favourite song (optional):',
                                        choices = c(),
                                        selected = "None",
                                        
                                        multiple = FALSE,
                                        options = list('create' = F, 'persist'=F
                                                       , 'placeholder'='select a song'
                                                       #, 'maxOptions'=300
                                        ) 
                                      ),
                                      
                                      
                                      ### Choose variables to give them more weight (optional)
                                      selectInput("moreweight", 
                                                  label="Select the most important aspect for you regarding music (optional):",
                                                  choices = list("Danceability" = "danceability", "Acousticness" = "acousticness", 
                                                                 "Tempo" = "tempo", "Loudness" = "loudness",
                                                                 "Valence" = "valence", "Year" = "year"), 
                                                  multiple=TRUE),
                                      
                                      
    
                                      ### Indicate the number of recommendations with a slider
                                      sliderInput("numrecom", 
                                                  label = "Number of recommendations:", 
                                                  value = 10, min=1, max=25),
                                      
                                      br(),
                                      
                                     ### Sumbit button
                                      actionButton("submitbutton", "Submit", 
                                                   class = "btn btn-primary")
                                      
                                    ),
                                    
                                    
                                    mainPanel(
                                      tags$label(h3('Status/Output')), # Status/Output Text Box
                                      verbatimTextOutput('contents'),
                                      br(),
                                      textOutput('infoart'),
                                      br(),
                                      textOutput('youmayalso'),
                                      br(),
                                      tableOutput('tabledata') # Prediction results table
                                      
                                      
                                    )
                                    
                           )
                           
                )            
)

####################################
# Server                           #
####################################

server<- function(input, output, session) {
  
  # This shows the artists in the database
  updateSelectizeInput(session, 'artist', choices=autocompletelist, server=T#, selected="The Beatles"
                       #, options = list(maxOptions=32000)
  )
  
  
  # Once the artist is selected, this calculates and shows the songs of the artist selected.
  selectedData <- reactiveValues()
  
  observeEvent(input$artist,{
    
    posi <- which(dfartists$artists == input$artist)
    idartist <- dfartists$artist_ids[posi]
    
    dades_ord <- tracks[str_which(tracks$artist_ids, idartist), ]
    selectedData$songs <- dades_ord[order(dades_ord$year, decreasing = T),]$name
    
    updateSelectizeInput(session, 'song', choices=c("None", selectedData$songs), server=T)
  })
  
  
  
  
  # Status/Output Text Box
  output$contents <- renderPrint({
    if (input$submitbutton>0) { 
      isolate("Calculation complete") 
      
    }else {
      return("Waiting for inputs")
    }
  
  })
  
  
  
  
  songcharac <- reactive({
    
    song <- input$song
    info <- input$moreweight
    
    validate(need(input$artist %in% dfartists$artists, ""))
    validate(need(song %in% tracks$name, ""))
    validate(need(info %in% selection, ""))
    
    a <- round(tracks[tracks$name==song, ][1, info], 2) 
    b <- paste(a, info, collapse=" & ")
    paste("Your favourite song has:", b, " (range from 0 to 1).")
    
  })
  
  
  
  artistcharac <- reactive({
    
    artist <- input$artist
    info <- input$moreweight
    
    validate(need(artist %in% dfartists$artists, ""))
    validate(need(info %in% selection, ""))
    
    c <- round(dfartists[dfartists$artists==artist,][1, info], 2)
    d <- paste(c, info, collapse=" & ")
    paste("Your favourite artist has", d, " (range from 0 to 1).") ## SHOW GENRE
    
  })
  
  

  output$infoart <- renderText({
    
    if(input$submitbutton>0 & input$song=="None"){
      isolate(artistcharac())
    }else if(input$submitbutton>0 & input$song!="None"){
      isolate(songcharac())
    }
    
    
  })
  
  
  # Validate artist name and song name
  youmay <- renderText({
    validate(need(input$artist %in% dfartists$artists, ""))
    validate(need(input$song %in% tracks$name | input$song=="None", ""))
    "Then, you may also like:"
  })
  
  
  
  # To show the previous message
  output$youmayalso <- renderText({
    if(input$submitbutton>0){
      
      isolate(youmay())
    }
    
  })
  
  
  
  # Input Data
  datasetInput <- reactive({  
    
    artist <- input$artist
    numrecom <- input$numrecom
    song <- input$song
    moreweight <- input$moreweight

    
    weights0 <- rep(1, length(selection))
    position0 <- which(selection %in% moreweight)
    if(length(position0) < length(selection)){
      weights0[position0] <- 1.5
      minorweight <- ( length(selection) - 1.5*length(position0) ) / length(weights0[-position0])
      weights0[-position0] <- minorweight
    }
    
    
    
    validate(need(artist %in% dfartists$artists, ""))
    validate(need(song %in% tracks$name | song=="None", ""))
    
    Output <- MusicRecommenderFunction(myartist = artist, mysong=song, k = numrecom, weight = weights0, dfartists=dfartists, tracks = tracks)
    print(Output)
    
    
  })
  
  
  
  # Recommendation results table
  output$tabledata <- renderTable({
    if (input$submitbutton>0) {
      
      isolate(datasetInput())
      
    } 
  })
  
  
  
}

####################################
# Create the shiny app             #
####################################

shinyApp(ui = ui, server = server)
