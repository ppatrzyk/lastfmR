# 
# 1. Run this script to import the function to the environment
# 
# 2. The function returns a data.frame object; run the following line
#    lastfm <- lastfm_export("enter_your_username")
# 
# 3. Depending on the size of your Last.fm library, downloading might take a while
#
lastfm_export <- function(user, timezone = "") {
  
  #load required packages
  if("XML" %in% rownames(installed.packages()) == FALSE) {
    install.packages("XML")
  }
  
  if("data.table" %in% rownames(installed.packages()) == FALSE) {
    install.packages("data.table")
  }
  
  if(require("XML")){
    print("XML loaded")
  } else {
    print("Failed to load XML package")
    return(NULL)
  }
  
  if(require("data.table")){
    print("data.table loaded")
  } else {
    print("Failed to load data.table package")
    return(NULL)
  }
  
  #get number of pages
  first_url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=%s&limit=1000&api_key=9b5e3d77309d540e9687909aabd9d467", user)
  page_check <- xmlTreeParse(first_url, useInternal = TRUE)
  current_node <- xmlRoot(page_check)
  pages <- as.numeric(xmlAttrs(current_node[[1]])[4])
  
  #total number of scrobbles
  #+20 to prevent out of range error (if the user is scrobbling right now, data grows during downloading)
  total <- as.numeric(xmlAttrs(current_node[[1]])[5]) + 20
  
  #allocate data.table
  lastfm <- data.table(
    date = as.numeric(rep(NA_integer_, total)),
    artist = as.character(rep(NA, total)),
    track = as.character(rep(NA, total)),
    album = as.character(rep(NA, total))
  )
  
  for (i in 1:pages) {
    
    current_url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=%s&limit=1000&page=%s&api_key=9b5e3d77309d540e9687909aabd9d467", user, i)
    parsed <- xmlTreeParse(current_url, useInternal = TRUE)
    current_node <- xmlRoot(parsed)
    
    for (j in 1:1000) {
      
      #check if end of page is reached (last page has < 1000 entries)
      if(is.na(xmlValue(current_node[[1]][[j]]))){
        break
      }
      
      #row index in data.table
      index <- as.integer(((i - 1) * 1000) + j)
      
      #set date
      rawdate <- as.integer(xmlApply(current_node[[1]][[j]], xmlAttrs)$date)
      if(length(rawdate) != 0){
        # = the track is not played now
        set(
          lastfm, index, 1L,
          rawdate
        )
      }
      
      #set artist
      set(
        lastfm, index, 2L,
        xmlValue(current_node[[1]][[j]][1]$artist)
      )

      #set track
      set(
        lastfm, index, 3L,
        xmlValue(current_node[[1]][[j]][2]$name)
      )

      #set album
      set(
        lastfm, index, 4L,
        xmlValue(current_node[[1]][[j]][5]$album)
      )
    }
    print(paste(round(100 * i / pages, digits = 2), "% downloaded", sep = ""))
  }
  
  #remove empty rows
  empty_rows <- apply(lastfm, 1, function(x) all(is.na(x)))
  lastfm <- lastfm[!empty_rows,]
  
  #handle missing values
  missing_date <- which(lastfm$date == 0)
  for(i in missing_date){
    set(
      lastfm, i, 1L,
      NA_integer_
    )
  }
  missing_album <- grep("^\\s*$", lastfm$album)
  for(i in missing_album){
    set(
      lastfm, i, 4L,
      NA
    )
  }
  
  #date formatting
  class(lastfm$date) <- c("POSIXt", "POSIXct")
  attr(lastfm$date, "tzone") <- timezone

  return(lastfm)
  }
 
