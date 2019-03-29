#api variables
api_root <- "http://ws.audioscrobbler.com/2.0/?method="
api_key <- "23fadd845ffb9a4ece7caeaecd74c94e"

# reformat curl reponse
parse_content <- function(response){
  content <- rawToChar(response$content)
  Encoding(content) <- 'UTF-8'
  return(content)
}

# run batch or urls
run_batch <- function(url_list, indices, update_data){
  pool <- new_pool()
  for (i in indices) {
    curl_fetch_multi(url_list[i], pool = pool, done = update_data)
  }
  out <- multi_run(pool = pool)
}
