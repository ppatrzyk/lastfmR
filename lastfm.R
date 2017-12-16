# 
# 1. Run this script to import the function to the environment
# 
# 2. The function returns a data.frame object; run the following line
#    lastfm <- lastfm_export("enter_your_username")
# 
# 3. Depending on the size of your Last.fm library, downloading might take a while
#
lastfm_export <- function(user, timezone = "") {
  if(require("XML")){
    print("XML loaded")
  } else {
    print("install XML package and run again")
    return(NULL)
  }
  rawdata <- vector()
  page_check <- xmlTreeParse(sprintf("http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=%s&limit=1000&api_key=9b5e3d77309d540e9687909aabd9d467", user), useInternal = TRUE)
  r <- xmlRoot(page_check)
  pages <- as.numeric(xmlAttrs(r[[1]])[4]) #data is stored on multiple pages with an unique url; 1000 scrobbles on each page except the last one
  total <- as.numeric(xmlAttrs(r[[1]])[5]) #total number of scrobbles
  lastp <- total - ((pages - 1) * 1000) #no of scrobbles to be fetched from the last page
  if (pages>1){ # if pages==1 no need to process previous pages
    for (j in 1:(pages-1)) { #last page requires a different treatment
      url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=%s&limit=1000&page=%s&api_key=9b5e3d77309d540e9687909aabd9d467", user, j)
      dl <- xmlTreeParse(url, useInternal = TRUE)
      r <- xmlRoot(dl)
      for (i in 1:1000) {
        if (length(as.character(xmlAttrs(r[[1]][[i]])[1])) == 0) {
          date <- as.character(xmlApply(r[[1]][[i]], xmlAttrs)$date)
          artist <- xmlValue(r[[1]][[i]][1]$artist)
          track <- xmlValue(r[[1]][[i]][2]$name)
          album <- xmlValue(r[[1]][[i]][5]$album)
          if (date != "0"){ #all scrobbles with missing date and time are discarded
            add <- c(artist, track, album, date)
            rawdata <- rbind(rawdata, add)
          }
        }
      }
      print(sprintf("Page %s out of %s downloaded", j, pages))
    }
  }
  #last page treatment
  url <- sprintf("http://ws.audioscrobbler.com/2.0/?method=user.getRecentTracks&user=%s&limit=1000&page=%s&api_key=9b5e3d77309d540e9687909aabd9d467", user, pages)
  dl <- xmlTreeParse(url, useInternal = TRUE)
  r <- xmlRoot(dl)
  for (i in 1:lastp) {
    if (length(as.character(xmlAttrs(r[[1]][[i]])[1])) == 0) {
      date <- as.character(xmlApply(r[[1]][[i]], xmlAttrs)$date)
      artist <- xmlValue(r[[1]][[i]][1]$artist)
      track <- xmlValue(r[[1]][[i]][2]$name)
      album <- xmlValue(r[[1]][[i]][5]$album)
      if (date != "0"){
        add <- c(artist, track, album, date)
        rawdata <- rbind(rawdata, add)
      }
    }
  }
  print(sprintf("Page %s out of %s downloaded", pages, pages))
  #reformat
  lastfm <- as.data.frame(rawdata)
  names(lastfm) <- c("artist", "track", "album", "fulldate")
  lastfm$fulldate <- as.character(lastfm$fulldate)
  class(lastfm$fulldate) <- c("POSIXt", "POSIXct")
  attr(lastfm$fulldate, "tzone") <- timezone
  raw_time <- substr(as.character(lastfm$fulldate), 12, 19) #extracts time information from the full date
  raw_time <- strptime(raw_time, format="%H:%M:%S")
  lastfm$time <- raw_time
  weekday <- sapply(lastfm$fulldate, weekdays)
  lastfm$weekday <- as.factor(weekday)
  row.names(lastfm) <- 1:nrow(lastfm)
  return(lastfm)
}
