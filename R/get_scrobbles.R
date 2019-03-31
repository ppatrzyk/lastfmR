#' Get all scroblles for a given user
#'
#' @param user Last.fm username
#' @param timezone (optional) defaults to GMT.
#' Pass any timezone name as in \code{OlsonNames()} if you need to convert
#'
#' @return \code{data.table} object with columns: date, track, artist, album
#'
#' @examples
#' scrobbles <- get_scrobbles(user = "enter_your_username")
#'
#' @export
get_scrobbles <- function(user, timezone = 'GMT') {

  #get number of pages
  first_url <- paste0(
    api_root,
    "user.getRecentTracks&user=",
    user,
    "&limit=1000&api_key=",
    api_key
  )
  first_url_conn <- curl(first_url)
  page_check <- try(readLines(first_url_conn), silent = TRUE)
  close(first_url_conn)
  if(class(page_check)[1] == "try-error"){
    # todo connection problems vs invalid username (?)
    stop("Invalid username")
  }
  parsed_xml <- read_xml(paste(page_check, collapse = '\n'))
  pageline <- xml_find_first(parsed_xml, ".//recenttracks")
  pages <- as.integer(xml_attr(pageline, 'totalPages'))
  # total number of scrobbles
  # +20 to prevent out of range error
  # (if the user is scrobbling right now, data grows during downloading)
  total <- as.integer(xml_attr(pageline, 'total')) + 20

  #allocate data.table
  scrobbles <- data.table(
    date = as.integer(rep(NA_integer_, total)),
    artist = as.character(rep(NA_character_, total)),
    track = as.character(rep(NA_character_, total)),
    album = as.character(rep(NA_character_, total))
  )

  #get XML files
  lastfm_urls <- paste0(
    api_root,
    "user.getRecentTracks&user=",
    user,
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
    if (!is.na(xml_attr(entries[1], 'nowplaying'))) {
      entries <- entries[2:length(entries)]
    }
    dates <- as.integer(xml_attr(xml_find_all(entries, './/date'), 'uts'))
    artists <- xml_text(xml_find_all(entries, './/artist'))
    tracks <- xml_text(xml_find_all(entries, './/name'))
    albums <- xml_text(xml_find_all(entries, './/album'))
    start_index <- as.integer(((page_index - 1) * 1000) + 1)
    end_index <- start_index + length(artists) - 1
    scrobbles[
      start_index:end_index,
      `:=`(date = dates, artist = artists, track = tracks, album = albums)
    ]
    setTxtProgressBar(pb, getTxtProgressBar(pb) + 1L)
  }

  run_batch(url_list = lastfm_urls, indices = seq(pages), update_data = add_data)

  #remove empty rows
  empty_rows <- apply(scrobbles, 1, function(x) all(is.na(x)))
  scrobbles <- scrobbles[!empty_rows,]

  #handle missing values
  #assumes anything before 2000-01-01 to be error
  scrobbles[date < 946684800, date := NA_integer_]
  scrobbles[grepl("^\\s*$", album), album := NA_character_]

  #date formatting
  #last.fm returns GMT, this need to be set first, then optionally convertred
  class(scrobbles$date) <- c("POSIXt", "POSIXct")
  attr(scrobbles$date, "tzone") <- "GMT"
  if (timezone != 'GMT') {
    attr(scrobbles$date, "tzone") <- timezone
  }

  close(pb)
  return(scrobbles)
}
