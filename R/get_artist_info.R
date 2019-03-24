#' Get info about artists
#'
#' @param artist_vector \code{character} vector with specified artists
#'
#' @return \code{data.table} object with columns: artist, artist_tag, global_listeners, global_scrobbles
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
    global_listeners = as.integer(rep(NA_integer_, total)),
    global_scrobbles = as.integer(rep(NA_integer_, total)),
    artist_tags = as.character(rep(NA_character_, total))
  )

  artists_encoded <- sapply(artist_vector, function(x) URLencode(x, reserved = TRUE))

  lastfm_urls <- paste0(
    api_root,
    "artist.getInfo&artist=",
    artists_encoded,
    "&api_key=",
    api_key
  )

  pb <- txtProgressBar(min = 0, max = total, style = 3)
  add_data <- function(response){
    page_index <- which(lastfm_urls == response$url)
    content <- unlist(strsplit(rawToChar(response$content), '\n'))
    tags <- paste(gsub('<name|<tag[s]*', '', get_entries(content, '<tag><name')), collapse = "; ")
    listeners <- as.integer(gsub('[^0-9]', '', get_entries(content, '<stats><listeners')))
    scrobbles <- as.integer(get_entries(content, '<playcount'))
    artist_info[
      page_index,
      `:=`(artist_tags = tags, global_listeners = listeners, global_scrobbles = scrobbles)
      ]
    setTxtProgressBar(pb, getTxtProgressBar(pb) + 1L)
  }

  # process data in 100-url batches
  all_indices <- 1:total
  batches <- split(all_indices, ceiling(seq_along(all_indices) / 100))
  for (i in 1:length(batches)) {
    current_batch <- batches[[i]]
    run_batch(url_list = lastfm_urls, indices = current_batch, update_data = add_data)
  }

  close(pb)
  return(artist_info)
}
