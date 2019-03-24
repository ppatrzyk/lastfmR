#' Get info about artists
#'
#' @param artist_vector \code{character} vector with specified artists
#'
#' @return \code{data.table} object with columns: artist, artist_tag, global_listners, global_scrobbles
#'
#' @examples
#' artists <- c("Anthrax", "Metallica", "Megadeth", "Slayer")
#' artist_info <- get_artist_info(artist_vector = artists)
#'
#' @seealso \code{\link{get_library_info}}
#'
#' @export
get_artist_info <- function(artist_vector){

  total <- length(artist_vector)

  #allocate data.table
  artist_info <- data.table(
    artist = artist_vector,
    artist_tag = as.character(rep(NA, total)),
    global_listners = as.integer(rep(NA_integer_, total)),
    global_scrobbles = as.integer(rep(NA_integer_, total))
  )

  #get artist info: scrobbles/listeners/tags

  artists <- artist_info[, artist]
  artists_encoded <- sapply(artists, function(x) URLencode(x, reserved = TRUE))

  #get XML files
  lastfm_urls_artists <- paste0(
    api_root,
    "artist.getInfo&artist=",
    artists_encoded,
    "&api_key=",
    api_key
  )

  lastfm_urls_tags <- paste0(
    api_root,
    "artist.gettoptags&artist=",
    artists_encoded,
    "&api_key=",
    api_key
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
