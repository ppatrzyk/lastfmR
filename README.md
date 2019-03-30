# lastfmR
R package wrapping useful [last.fm](https://www.last.fm/) API methods. 

## Installation

```R
remotes::install_github("ppatrzyk/lastfmR")
# OR
devtools::install_github("ppatrzyk/lastfmR")
```

The package installs as dependencies R packages [`curl`](https://cran.r-project.org/web/packages/curl/), [`data.table`](https://cran.r-project.org/web/packages/data.table/) and [`xml2`](https://cran.r-project.org/web/packages/xml2/index.html).

## Usage

### get_scrobbles

This function will download all scrobbles for a specified user. Example:

```R
scrobbles <- get_scrobbles(user = "grinder91")
> scrobbles[sample(.N, 5), ]
                  date        artist              track                             album
1: 2014-04-29 10:23:24 The Awakening Before I Leap (XV)                      Anthology XV
2: 2009-11-25 17:46:06  Judas Priest  Take on the World Killing Machine [Remastered] [UK]
3: 2016-07-16 10:02:38  FOREVER GREY     Full Of Lights                              <NA>
4: 2011-06-26 10:36:23       Bauhaus  Small Talk Stinks                 In the Flat Field
5: 2019-02-15 22:20:35          Past             Czarna                    czarno / biala
```

Scrobble dates indicate when you *started* to play given track in *GMT* timezone. You can pass an optional `timezone` parameter with a timezone name (run `OlsonNames()` if in doubt) if you need. E.g., `get_scrobbles(user = "grinder91", timezone = 'Europe/Warsaw')`.

### get_artist_info

This function will download information about specific artists. Example:

```R
artists <- c("Anthrax", "Metallica", "Megadeth", "Slayer")
artist_info <- get_artist_info(artist_vector = artists)
> artist_info
      artist global_listeners global_scrobbles                                              artist_tags
1:   Anthrax           867775         25910522 thrash metal; metal; heavy metal; speed metal; seen live
2: Metallica          2890695        280742907        thrash metal; metal; heavy metal; hard rock; rock
3:  Megadeth          1410966         97458296 thrash metal; heavy metal; metal; speed metal; seen live
4:    Slayer          1366827         82132980 thrash metal; metal; seen live; speed metal; heavy metal
```

### get_library_info

Extension of `get_artist_info`. Gets list of artists in a specified user's library and information about them. Example:

```R
artist_info <- get_library_info(user = "grinder91")
> artist_info[sample(.N, 5), ]
            artist user_scrobbles global_listeners global_scrobbles                                             artist_tags
1:    Peine Perdue             15             2645            35717   minimal synth; minimal wave; french; synthpop; france
2:        Motorama             10           171162          7331742          post-punk; new wave; indie; russian; seen live
3:     Perturbator             97           149293          6829118 synthwave; electronic; synthpop; retro electro; electro
4:   The Deep Wave              1              180              905               new wave; post-punk; retrowave; synthwave
5: Psychoformalina            621              739            13435      zimna fala; post-punk; cold wave; coldwave; polish
```
