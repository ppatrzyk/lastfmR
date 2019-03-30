#' Get artist similarity relationships
#'
#' @param artist \code{character} one-element vector with a specified artist
#'
#' @return \code{data.table} object structured as edgelist
#'
#' @examples
#' # Get similarity two levels from given artist
#' edgelist <- get_similar('Closterkeller')
#' level2 <- rbindlist(lapply(
#'   edgelist[, To], get_similar
#' ))
#' edgelist <- rbindlist(list(edgelist, level2))
#'
#' @export
get_similar <- function(artist) {

  if (length(artist) != 1) {
    stop("Supply one artist only")
  }

  lastfm_url <- paste0(
    api_root,
    "artist.getsimilar&",
    "artist=",
    URLencode(artist),
    "&autocorrect=0",
    "&api_key=",
    api_key
  )

  first_url_conn <- curl(lastfm_url)
  page_check <- try(readLines(first_url_conn), silent = TRUE)
  close(first_url_conn)

  if(class(page_check)[1] == "try-error"){
    # todo connection problems vs invalid artist (?)
    stop("Invalid artist")
  }

  parsed_xml <- read_xml(paste(page_check, collapse = '\n'))
  statusline <- xml_find_first(parsed_xml, ".//similarartists")
  from_artist <- xml_attr(statusline, 'artist')

  to_nodes <- xml_find_all(parsed_xml, ".//artist")
  to_names <- xml_text(xml_find_all(parsed_xml, ".//name"))
  to_match <- xml_text(xml_find_all(parsed_xml, ".//match"))

  edgelist <- data.table(
    From = rep(from_artist, length(to_names)),
    To = to_names,
    match = to_match
  )

  return(edgelist)
}
