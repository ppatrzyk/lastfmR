# lastfmR
R package wrapping useful [last.fm](https://www.last.fm/) API methods. 

## Installation

```R
devtools::install_github("ppatrzyk/lastfmR")
```

The package installs as dependencies R packages [curl](https://cran.r-project.org/web/packages/curl/) and [data.table](https://cran.r-project.org/web/packages/data.table/).

## Usage

### get_scrobbles

This function will download all scrobbles for a specified user. Example:

```R
scrobbles <- get_scrobbles(user = "grinder91")
> scrobbles[sample(.N, 5), ]
                  date           artist                    track                   album
1: 2015-12-22 13:26:11     Echo Syndrom    Zagłada (bonus track)              BEZSENNOŚĆ
2: 2014-07-14 15:49:29          Manowar             Call to Arms   Warriors of the World
3: 2008-08-23 10:03:21          Bauhaus The Three Shadows Part 1 The Sky&apos;s Gone Out
4: 2008-05-28 18:12:46              KSU                Moje Oczy                Ustrzyki
5: 2016-09-19 11:15:21 In Death It Ends           Power Of Seven          Sanctus Mortem
```

### get_artist_info

This function will download information about specific artists. Example:

```R
artists <- c("Anthrax", "Metallica", "Megadeth", "Slayer")
artist_info <- get_artist_info(artist_vector = artists)
> artist_info
      artist                                              artist_tags global_listeners global_scrobbles
1:   Anthrax thrash metal; metal; heavy metal; speed metal; seen live           867775         25910522
2: Metallica        thrash metal; metal; heavy metal; hard rock; rock          2890695        280742907
3:  Megadeth thrash metal; heavy metal; metal; speed metal; seen live          1410966         97458296
4:    Slayer thrash metal; metal; seen live; speed metal; heavy metal          1366827         82132980
```

### get_library_info

Extension of `get_artist_info`. Gets list of artists in a specified user's library and information about them. Example:

```R
artist_info <- get_library_info(user = "grinder91")
> artist_info[sample(.N, 5), ]
           artist user_scrobbles                                                artist_tags global_listeners global_scrobbles
1: Marilyn Manson            186     industrial; industrial metal; metal; rock; alternative          2233411        122137950
2:          PLOHO             15 post-punk; coldwave; russian; Russian Post-Punk; seen live            18604           565067
3:     Switchface             12 ebm; dark electro; electro-industrial; industrial; electro             2670            25780
4:  The Exploited              2      punk; hardcore punk; punk rock; street punk; hardcore           243440          6265333
5:    Pornografia             30       cold wave; polish; zimna fala; coldwave; Gothic Rock             1360            35898
```
