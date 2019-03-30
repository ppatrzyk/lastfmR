#' Get all tags and their frequency for given artists
#'
#' @param artist_vector \code{character} vector with specified artists
#'
#' @return \code{data.table} object with columns: artist, tag, tag_freq
#'
#' @examples
#' tags <- get_tags(artist_vector = c('Saxon', 'Iron Maiden'))
#'
#' @export
get_tags <- function(artist_vector) {

  total <- length(artist_vector)

  #length of tags not known need to store list of data.tables and rbind later
  dt_list <- replicate(total, NA, simplify = FALSE)

  #get XML files
  artists_encoded <- sapply(artist_vector, function(x) URLencode(x, reserved = TRUE))
  lastfm_urls <- paste0(
    api_root,
    "artist.gettoptags&",
    "artist=",
    artists_encoded,
    "&autocorrect=0",
    "&api_key=",
    api_key
  )

  pb <- txtProgressBar(min = 0, max = total, style = 3)
  add_data <- function(response){
    dt_index <- which(lastfm_urls == response$url)
    parsed_xml <- read_xml(parse_content(response))
    entries <- xml_find_all(parsed_xml, ".//tag")
    tags <- xml_text(xml_find_all(entries, './/name'))
    counts <- as.integer(xml_text(xml_find_all(entries, './/count')))
    tags_dt <- data.table(
      artist = rep(artist_vector[dt_index], length(tags)),
      tag = tags,
      tag_freq = counts
    )
    dt_list[[dt_index]] <<- tags_dt
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
  return(rbindlist(dt_list))
}
