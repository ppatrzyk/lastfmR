# 
# 1. Run this script to import the function to the environment
# 
# 2. The function returns a data.table object; run the following line
#    scrobbles <- get_scrobbles("enter_your_username")
# 
# 3. Depending on the size of your Last.fm library, downloading might take a while
#
get_scrobbles <- function(user, timezone = "") {
  
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
  page_check <- try(xmlTreeParse(first_url, useInternal = TRUE), silent = TRUE)
  if(class(page_check)[1] == "try-error"){
    print("Invalid username")
    return(NULL)
  }
  current_node <- xmlRoot(page_check)
  pages <- as.numeric(xmlAttrs(current_node[[1]])[4])
  
  #total number of scrobbles
  #+20 to prevent out of range error (if the user is scrobbling right now, data grows during downloading)
  total <- as.numeric(xmlAttrs(current_node[[1]])[5]) + 20
  
  #allocate data.table
  scrobbles <- data.table(
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
          scrobbles, index, 1L,
          rawdate
        )
      }
      
      #set artist
      set(
        scrobbles, index, 2L,
        xmlValue(current_node[[1]][[j]][1]$artist)
      )
      
      #set track
      set(
        scrobbles, index, 3L,
        xmlValue(current_node[[1]][[j]][2]$name)
      )
      
      #set album
      set(
        scrobbles, index, 4L,
        xmlValue(current_node[[1]][[j]][5]$album)
      )
    }
    print(paste(round(100 * i / pages, digits = 2), "% downloaded", sep = ""))
  }
  
  #remove empty rows
  empty_rows <- apply(scrobbles, 1, function(x) all(is.na(x)))
  scrobbles <- scrobbles[!empty_rows,]
  
  #handle missing values
  missing_date <- which(scrobbles$date == 0)
  for(i in missing_date){
    set(
      scrobbles, i, 1L,
      NA_integer_
    )
  }
  missing_album <- grep("^\\s*$", scrobbles$album)
  for(i in missing_album){
    set(
      scrobbles, i, 4L,
      NA
    )
  }
  
  #date formatting
  class(scrobbles$date) <- c("POSIXt", "POSIXct")
  attr(scrobbles$date, "tzone") <- timezone
  
  return(scrobbles)
}
