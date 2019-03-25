#' Get all scroblles for a given user
#'
#' @param user Last.fm username
#'
#' @return \code{data.table} object with columns: date, track, artist, album
#'
#' @examples
#' scrobbles <- get_scrobbles(user = "enter_your_username")
#'
#' @export
get_scrobbles <- function(user) {

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
  pageline <- grep('recenttracks', page_check, value = TRUE, ignore.case = TRUE)[1]
  pages <- as.integer(gsub('[^0-9]', '', regmatches(pageline, regexpr("totalpages.*?( |>|<)", pageline, ignore.case = TRUE))))

  #total number of scrobbles
  #+20 to prevent out of range error (if the user is scrobbling right now, data grows during downloading)
  total <- as.integer(gsub('[^0-9]', '', regmatches(pageline, regexpr("total=.*?( |>|<)", pageline, ignore.case = TRUE)))) + 20

  #allocate data.table
  scrobbles <- data.table(
    date = as.integer(rep(NA_integer_, total)),
    artist = as.character(rep(NA_character_, total)),
    track = as.character(rep(NA_character_, total)),
    album = as.character(rep(NA_character_, total))
  )

  #get XML files
  lastfm_urls <- paste0(
    "http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=",
    user,
    "&limit=1000&page=",
    seq(pages),
    "&api_key=",
    api_key
  )

  pb <- txtProgressBar(min = 0, max = pages, style = 3)
  add_data <- function(response){
    page_index <- which(lastfm_urls == response$url)
    content <- parse_content(response)
    dates <- as.integer(get_entries(content, '<date', by_attribute = TRUE))
    artists <- get_entries(content, '<artist')
    tracks <- get_entries(content, '<name')
    albums <- get_entries(content, '<album')
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
  scrobbles[date == 0, date := NA_integer_]
  scrobbles[grepl("^\\s*$", album), album := NA_character_]

  #date formatting
  class(scrobbles$date) <- c("POSIXt", "POSIXct")
  attr(scrobbles$date, "tzone") <- "GMT"

  close(pb)
  return(scrobbles)
}
