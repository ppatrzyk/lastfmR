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

  # TODO this won't work now, add user lib and call call get artist info

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
}
