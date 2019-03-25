#' Get info about all artists from a user's library
#'
#' @param user Last.fm username
#'
#' @return \code{data.table} object with columns: artist, artist_tag, global_listners, global_scrobbles
#'
#' @examples
#' artist_info <- get_library_info(user = "enter_your_username")
#'
#' @seealso \code{\link{get_library_info}}
#'
#' @export
get_library_info <- function(user){

  #library
  first_url <- paste0(
    api_root,
    'library.getartists&user=',
    user,
    '&limit=1000&api_key=',
    api_key
  )
  first_url_conn <- curl(first_url)
  page_check <- try(readLines(first_url_conn), silent = TRUE)
  close(first_url_conn)
  if(class(page_check)[1] == "try-error"){
    # todo connection problems vs invalid username (?)
    stop("Invalid username")
  }

  pageline <- grep('<artists', page_check, value = TRUE, ignore.case = TRUE)[1]
  pages <- as.integer(gsub('[^0-9]', '', regmatches(pageline, regexpr("totalpages.*?( |>)", pageline, ignore.case = TRUE))))
  total <- as.integer(gsub('[^0-9]', '', regmatches(pageline, regexpr("total=.*?( |>|<)", pageline, ignore.case = TRUE))))

  #allocate data.table
  user_artists <- data.table(
    artist = as.character(rep(NA_character_, total)),
    user_scrobbles = as.integer(rep(NA_integer_, total))
  )

  lastfm_urls <- paste0(
    api_root,
    "library.getartists&user=",
    user,
    "&limit=1000&page=",
    seq(pages),
    "&api_key=",
    api_key
  )

  add_data <- function(response){
    page_index <- which(lastfm_urls == response$url)
    content <- parse_content(response)
    artists <- get_entries(content, '<name')
    scrobbles <- as.integer(get_entries(content, '<playcount'))
    start_index <- as.integer(((page_index - 1) * 1000) + 1)
    end_index <- start_index + length(artists) - 1
    user_artists[
      start_index:end_index,
      `:=`(artist = artists, user_scrobbles = scrobbles)
      ]
  }
  run_batch(url_list = lastfm_urls, indices = seq(pages), update_data = add_data)

  artist_info <- get_artist_info(artist_vector = user_artists$artist)
  user_artists <- merge(
    user_artists, artist_info,
    by = 'artist', all = TRUE
  )[
    order(user_scrobbles, decreasing = TRUE)
  ]

  return(user_artists)
}
