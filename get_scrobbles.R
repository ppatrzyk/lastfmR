# 
# 1. Run this script to import the function to the environment
# 
# 2. The function returns a data.table object; run the following line
#    scrobbles <- get_scrobbles("enter_your_username")
# 
get_scrobbles <- function(user, timezone = "") {
  
  #install/load required packages
  packages <- c("curl", "XML", "data.table")
  for(i in 1:length(packages)){
    
    package <- packages[i]
    
    if(package %in% rownames(installed.packages()) == FALSE) {
      install.packages(package)
    }
    
    if(require(package, character.only = TRUE)){
      print(paste0(package, " loaded"))
    } else {
      print(paste0("Failed to load ",  package, " package"))
      return(NULL)
    }
  }
  
  #api key
  lastfm_api <- "9b5e3d77309d540e9687909aabd9d467"
  
  #get number of pages
  first_url <- paste0(
    "http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=",
    user,
    "&limit=1000&api_key=",
    lastfm_api
  )
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
  
  #get XML files
  lastfm_urls <- paste0(
    "http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=",
    user,
    "&limit=1000&page=",
    seq(pages),
    "&api_key=",
    lastfm_api
  )
  
  lastfm_xmls <- rep(NA_character_, pages)
  add_data <- function(x){
    index <- which(lastfm_urls == x$url)
    lastfm_xmls[index] <<- rawToChar(x$content)
  }
  pool <- new_pool()
  for (i in seq(pages)) {
    curl_fetch_multi(lastfm_urls[i], pool = pool, done = add_data)
  }
  
  print("Downloading data from last.fm ...")
  out <- multi_run(pool = pool)
  
  #process XML files
  print("Parsing data ...")
  for (i in seq(pages)) {
    
    current_page <- lastfm_xmls[i]
    parsed <- xmlTreeParse(current_page, useInternal = TRUE)
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
          scrobbles, index, "date",
          rawdate
        )
      }
      
      #set artist
      set(
        scrobbles, index, "artist",
        xmlValue(current_node[[1]][[j]][1]$artist)
      )
      
      #set track
      set(
        scrobbles, index, "track",
        xmlValue(current_node[[1]][[j]][2]$name)
      )
      
      #set album
      set(
        scrobbles, index, "album",
        xmlValue(current_node[[1]][[j]][5]$album)
      )
    }
    #print progress
    if(i %% 10 == 0 | i == pages){
      print(paste(
        round(100 * i / pages, digits = 2),
        "% processed"
      ))
    }
  }
  
  #remove empty rows
  empty_rows <- apply(scrobbles, 1, function(x) all(is.na(x)))
  scrobbles <- scrobbles[!empty_rows,]
  
  #handle missing values
  missing_date <- which(scrobbles$date == 0)
  for(i in missing_date){
    set(
      scrobbles, i, "date",
      NA_integer_
    )
  }
  missing_album <- grep("^\\s*$", scrobbles$album)
  for(i in missing_album){
    set(
      scrobbles, i, "album",
      NA
    )
  }
  
  #date formatting
  class(scrobbles$date) <- c("POSIXt", "POSIXct")
  attr(scrobbles$date, "tzone") <- timezone
  
  return(scrobbles)
}
