# 
# 1. Run this script to import the function to the environment
# 
# 2. The function returns a data.table object; there are two methods to use:
#    
# 2.1 Get all artists from a user's library
#    artist_info <- get_artist_info(user = "enter_your_username")
# 
# 2.1 Specify vector of artists
#    artists <- c("Anthrax", "Metallica", "Megadeth", "Slayer")
#    artist_info <- get_artist_info(method = "artist_vector", artist_vector = artists)
#
# 3. Depending on the size of your Last.fm library, downloading might take a while
#
get_artist_info <- function(user = "", method = "library", artist_vector = character(), timezone = ""){
  
  #check method
  if(method %in% c("library", "artist_vector") == FALSE){
    print("Incorrect method, pass either 'library' or 'artist_vector'")
    return(NULL)
  }
  
  if(method == "artist_vector" & length(artist_vector) == 0){
    print("'artist_vector' method chosen but no data supplied")
    return(NULL)
  }
  
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
  
  #load country data
  countries <- read.csv(url("https://raw.githubusercontent.com/ppatrzyk/lastfm-to-R/master/get_countries/countries.csv"), stringsAsFactors=FALSE)
  
  if(method == "library"){
    
    #library
    first_url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=library.getartists&user=%s&limit=1000&api_key=9b5e3d77309d540e9687909aabd9d467", user)
    page_check <- try(xmlTreeParse(first_url, useInternal = TRUE), silent = TRUE)
    if(class(page_check)[1] == "try-error"){
      print("Invalid username")
      return(NULL)
    }
    current_node <- xmlRoot(page_check)
    
    #total number of scrobbles
    pages <- as.numeric(xmlAttrs(current_node[[1]])[4])
    total <- as.numeric(xmlAttrs(current_node[[1]])[5])
    
    #allocate data.table
    artist_info <- data.table(
      artist = as.character(rep(NA, total)),
      artist_tag = as.character(rep(NA, total)),
      artist_country = as.character(rep(NA, total)),
      global_listners = as.integer(rep(NA_integer_, total)),
      global_scrobbles = as.integer(rep(NA_integer_, total)),
      user_scrobbles = as.integer(rep(NA_integer_, total))
    )
    
    #get artists / user scrobble counts from library
    for(i in 1:pages){
      
      current_url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=library.getartists&user=%s&limit=1000&page=%s&api_key=9b5e3d77309d540e9687909aabd9d467", user, i)
      parsed <- xmlTreeParse(current_url, useInternal = TRUE)
      current_node <- xmlRoot(parsed)
      
      for(j in 1:1000){
        
        #check if end of page is reached (last page has < 1000 entries)
        if(is.na(xmlValue(current_node[[1]][[j]]))){
          break
        }
        
        #row index in data.table
        index <- as.integer(((i - 1) * 1000) + j)
        
        #set artist
        set(
          artist_info, index, 1L,
          xmlValue(current_node[[1]][[j]][1]$name)
        )
        
        #set user scrobbles
        set(
          artist_info, index, 6L,
          as.integer(xmlValue(current_node[[1]][[j]][2]$playcount))
        )
        
      }
      
    }
    
  }else{
    
    total <- length(artist_vector)
    
    #allocate data.table
    artist_info <- data.table(
      artist = artist_vector,
      artist_tag = as.character(rep(NA, total)),
      artist_country = as.character(rep(NA, total)),
      global_listners = as.integer(rep(NA_integer_, total)),
      global_scrobbles = as.integer(rep(NA_integer_, total))
    )
    
  }
  
  #get artist info
  for (i in 1:nrow(artist_info)) {
    
    artist <- artist_info[i, artist]
    artist_encoded <- URLencode(artist, reserved = TRUE)
    artist_url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=artist.getInfo&artist=%s&api_key=9b5e3d77309d540e9687909aabd9d467", artist_encoded)
    parse <- try(xmlTreeParse(artist_url, useInternal = TRUE), silent = TRUE)
    if(class(parse)[1] == "try-error"){
      print(paste("No artist called", artist))
      return(NULL)
    }
    artist_node <- xmlRoot(parse)
    
    #set global listeners
    set(
      artist_info, i, 4L,
      as.integer(xmlValue(artist_node[[1]][["stats"]][["listeners"]]))
    )
    
    #set global scrobbles
    set(
      artist_info, i, 5L,
      as.integer(xmlValue(artist_node[[1]][["stats"]][["playcount"]]))
    )
    
    #set top tag
    set(
      artist_info, i, 2L,
      as.character(xmlValue(artist_node[[1]][["tags"]][[1]][["name"]]))
    )
    
    #get tags
    tag_url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=artist.gettoptags&artist=%s&api_key=9b5e3d77309d540e9687909aabd9d467", artist_encoded)
    parse <- try(xmlTreeParse(tag_url, useInternal = TRUE), silent = TRUE)
    if(class(parse)[1] == "try-error"){
      print(paste("No tags for", artist))
    }else{
      tag_node <- xmlRoot(parse)
      tags <- character()
      j <- 1
      while(TRUE){
        current_tag <- as.character(xmlValue(tag_node[[1]][[j]][["name"]]))
        if(is.na(current_tag)) break
        tags <- c(tags, current_tag)
        j <- j + 1
      }
    }
    
    #chceck country, more popular tags prevail in case of conflict
    found <- FALSE
    for(k in 1:length(tags)){
      current_tag <- paste0("^", tags[k], "$")
      match <- grep(current_tag, countries$adjectival, ignore.case = TRUE)
      if(length(match) > 0) {
        found <- TRUE
        break
      }
      match <- grep(current_tag, countries$country, ignore.case = TRUE)
      if(length(match) > 0) {
        found <- TRUE
        break
      }
    }
    
    if(found){
      set(
        artist_info, i, 3L,
        countries$country[match[1]]
      )
    }
    
    #print progress
    print(paste(
      round(100 * i / nrow(artist_info), digits = 2),
      "% processed"
    ))
    
  }
  return(artist_info)
}