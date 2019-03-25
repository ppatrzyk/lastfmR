#api variables
api_root <- "http://ws.audioscrobbler.com/2.0/?method="
api_key <- "23fadd845ffb9a4ece7caeaecd74c94e"

# reformat curl reponse
parse_content <- function(response){
  raw <- rawToChar(response$content)
  Encoding(raw) <- 'UTF-8'
  content <- unlist(strsplit(raw, '\n'))
  return(content)
}

#helpers for get_entries
extract_content <- function(line){
  value <- gsub('>|</', '', regmatches(line, regexpr(">.*</", line, ignore.case = TRUE)))
  return(value)
}

extract_attr <- function(line){
  value <- gsub('[^0-9]', '', regmatches(line, regexpr("uts=.*?( |>|<)", line, ignore.case = TRUE)))
  return(value)
}

# parse char vector of xml
get_entries <- function(response, name, by_attribute = FALSE){
  datalines <- grep(name, response, value = TRUE, ignore.case = TRUE)
  entries <- sapply(
    datalines,
    ifelse(by_attribute, extract_attr, extract_content)
  )
  return(unname(entries))
}

# run batch or urls
run_batch <- function(url_list, indices, update_data){
  pool <- new_pool()
  for (i in indices) {
    curl_fetch_multi(url_list[i], pool = pool, done = update_data)
  }
  out <- multi_run(pool = pool)
}
