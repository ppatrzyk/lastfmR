#' Get all tracks and their popularity for given artists
#'
#' @param artist one-element \code{character} vector with a specified artist
#'
#' @return \code{data.table} object with columns: track, listeners, scrobbles
#'
#' @examples
#' tracks <- get_tracks(artist = 'Siekiera')
#'
#' @export
get_tracks <- function(artist) {

  first_url <- paste0(
    api_root,
    "artist.gettoptracks&artist=",
    URLencode(artist),
    "&autocorrect=0",
    "&limit=1000&api_key=",
    api_key
  )

  first_url_conn <- curl(first_url)
  page_check <- try(readLines(first_url_conn), silent = TRUE)
  close(first_url_conn)
  if(class(page_check)[1] == "try-error"){
    # todo connection problems vs invalid name (?)
    stop("Artist not found")
  }

  parsed_xml <- read_xml(paste(page_check, collapse = '\n'))
  pageline <- xml_find_first(parsed_xml, ".//toptracks")
  pages <- as.integer(xml_attr(pageline, 'totalPages'))
  total <- as.integer(xml_attr(pageline, 'total'))
  if(pages > 10){
    pages <- 10
    total <- 10000
    warning("Unable to fetch all tracks, only first 10,000 returned")
  }

  #allocate data.table
  tracks <- data.table(
    track = as.character(rep(NA_character_, total)),
    listeners = as.integer(rep(NA_integer_, total)),
    scrobbles = as.integer(rep(NA_integer_, total))
  )

  lastfm_urls <- paste0(
    api_root,
    "artist.gettoptracks&artist=",
    URLencode(artist),
    "&autocorrect=0",
    "&limit=1000&page=",
    seq(pages),
    "&api_key=",
    api_key
  )

  pb <- txtProgressBar(min = 0, max = pages, style = 3)
  add_data <- function(response){
    page_index <- which(lastfm_urls == response$url)
    parsed_xml <- read_xml(parse_content(response))
    entries <- xml_find_all(parsed_xml, ".//track")
    current_tracks <- xml_text(xml_find_first(entries, './/name'))
    current_listeners <- as.integer(xml_text(xml_find_all(entries, './/listeners')))
    current_scrobbles <- as.integer(xml_text(xml_find_all(entries, './/playcount')))
    start_index <- as.integer(((page_index - 1) * 1000) + 1)
    end_index <- start_index + length(current_tracks) - 1
    tracks[
      start_index:end_index,
      `:=`(track = current_tracks, listeners = current_listeners, scrobbles = current_scrobbles)
    ]
    setTxtProgressBar(pb, getTxtProgressBar(pb) + 1L)
  }

  run_batch(url_list = lastfm_urls, indices = seq(pages), update_data = add_data)

  close(pb)
  return(tracks)
}
