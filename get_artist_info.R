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
  
  if(method == "library"){
    
    #library
    first_url <- paste0(
      "http://ws.audioscrobbler.com/2.0/?method=library.getartists&user=",
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
    
    #total number of scrobbles
    pages <- as.numeric(xmlAttrs(current_node[[1]])[4])
    total <- as.numeric(xmlAttrs(current_node[[1]])[5])
    
    #allocate data.table
    artist_info <- data.table(
      artist = as.character(rep(NA, total)),
      artist_tag = as.character(rep(NA, total)),
      global_listners = as.integer(rep(NA_integer_, total)),
      global_scrobbles = as.integer(rep(NA_integer_, total)),
      user_scrobbles = as.integer(rep(NA_integer_, total))
    )
    
    #get XML files
    lastfm_urls_lib <- paste0(
      "http://ws.audioscrobbler.com/2.0/?method=library.getartists&user=",
      user,
      "&limit=1000&page=",
      seq(pages),
      "&api_key=",
      lastfm_api
    )
    lastfm_xmls_lib <- rep(NA_character_, pages)
    add_data_lib <- function(x){
      index <- which(lastfm_urls_lib == x$url)
      lastfm_xmls_lib[index] <<- rawToChar(x$content)
    }
    pool <- new_pool()
    for (i in seq(pages)) {
      curl_fetch_multi(lastfm_urls_lib[i], pool = pool, done = add_data_lib)
    }
    
    print(paste0("Fetching artists from ", user, " library ..."))
    out <- multi_run(pool = pool)
    
    #parsing data
    print(paste0("Parsing ", user, " library ..."))
    for(i in 1:pages){
      
      current_page <- lastfm_xmls_lib[i]
      parsed <- xmlTreeParse(current_page, useInternal = TRUE)
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
          artist_info, index, "artist",
          xmlValue(current_node[[1]][[j]][1]$name)
        )
        
        #set user scrobbles
        set(
          artist_info, index, "user scrobbles",
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
      global_listners = as.integer(rep(NA_integer_, total)),
      global_scrobbles = as.integer(rep(NA_integer_, total))
    )
    
  }
  
  #get artist info: scrobbles/listeners/tags
  
  artists <- artist_info[, artist]
  artists_encoded <- sapply(artists, function(x) URLencode(x, reserved = TRUE))
  
  #get XML files
  lastfm_urls_artists <- paste0(
    "http://ws.audioscrobbler.com/2.0/?method=artist.getInfo&artist=",
    artists_encoded,
    "&api_key=",
    lastfm_api
  )
  
  lastfm_urls_tags <- paste0(
    "http://ws.audioscrobbler.com/2.0/?method=artist.gettoptags&artist=",
    artists_encoded,
    "&api_key=",
    lastfm_api
  )
  
  lastfm_xmls_artists <- rep(NA_character_, length(artists))
  lastfm_xmls_tags <- rep(NA_character_, length(artists))
  
  add_data_artists <- function(x){
    index <- which(lastfm_urls_artists == x$url)
    lastfm_xmls_artists[index] <<- rawToChar(x$content)
  }
  add_data_tags <- function(x){
    index <- which(lastfm_urls_tags == x$url)
    lastfm_xmls_tags[index] <<- rawToChar(x$content)
  }
  
  #define download procedure for each batch (100 urls per call)
  
  run_batch <- function(indices){
    artist_pool <- new_pool()
    tag_pool <- new_pool()
    for (i in indices) {
      curl_fetch_multi(lastfm_urls_artists[i], pool = artist_pool, done = add_data_artists)
      curl_fetch_multi(lastfm_urls_tags[i], pool = tag_pool, done = add_data_tags)
    }
    out <- multi_run(pool = artist_pool)
    out <- multi_run(pool = tag_pool)
  }
  
  all_indices <- 1:length(artists)
  batches <- split(all_indices, ceiling(seq_along(all_indices) / 100))
  
  print("Downloading data")
  for (i in 1:length(batches)) { 
    current_batch <- batches[[i]]
    run_batch(current_batch)
    print(
      paste0(
        "Batch ", i, 
        "/", length(batches),
        " processed (",
        round(100 * i / length(batches), 2), "%)"
      )
    )
  }
  
  #parsing data
  print("Parsing data")
  for (i in 1:nrow(artist_info)) {
    
    artist_xml <- lastfm_xmls_artists[i]
    tag_xml <- lastfm_xmls_tags[i]
    
    parse <- try(xmlTreeParse(artist_xml, useInternal = TRUE), silent = TRUE)
    if(class(parse)[1] == "try-error"){
      print(paste("No artist called", artists[i]))
      next
    }
    artist_node <- xmlRoot(parse)
    
    #set global listeners
    set(
      artist_info, i, "global_listners",
      as.integer(xmlValue(artist_node[[1]][["stats"]][["listeners"]]))
    )
    
    #set global scrobbles
    set(
      artist_info, i, "global_scrobbles",
      as.integer(xmlValue(artist_node[[1]][["stats"]][["playcount"]]))
    )
    
    #set top tag
    set(
      artist_info, i, "artist_tag",
      as.character(xmlValue(artist_node[[1]][["tags"]][[1]][["name"]]))
    )
    
    #get tags
    parse <- try(xmlTreeParse(tag_xml, useInternal = TRUE), silent = TRUE)
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
    
    #print progress
    if(i %% 10 == 0 | i == nrow(artist_info)){
      print(paste(
        round(100 * i / nrow(artist_info), digits = 2),
        "% processed"
      ))
    }
  }
  return(artist_info)
}