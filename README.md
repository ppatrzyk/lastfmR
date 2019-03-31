# lastfmR
R package wrapping useful [last.fm](https://www.last.fm/) API methods. The package leverages [concurrent requests](https://www.rdocumentation.org/packages/curl/versions/3.3/topics/multi) to enable *fast* data export.

## Installation

```R
remotes::install_github("ppatrzyk/lastfmR")
# OR
devtools::install_github("ppatrzyk/lastfmR")
```

The package requires as dependencies [`curl`](https://cran.r-project.org/web/packages/curl/), [`data.table`](https://cran.r-project.org/web/packages/data.table/) and [`xml2`](https://cran.r-project.org/web/packages/xml2/index.html).

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

If you only need user_scrobbles, set `user_scrobbles_only = TRUE` in function call, the function will return faster.

### get_tags

Get all tags and their frequencies for specified artists (you can pass multiple names). Example:

```R
tags <- get_tags(artist_vector = 'Manowar')
> head(tags, 5)
    artist         tag tag_freq
1: Manowar heavy metal      100
2: Manowar Power metal       49
3: Manowar       metal       35
4: Manowar  true metal       28
5: Manowar  epic metal       21
```

Note that last.fm returns tag frequencies on a normalized scale (1-100). These are not absolute counts.

### get_tracks

Get tracks and their listeners and scrobbles for a specified artist. Example:

```R
tracks <- get_tracks(artist = 'Siekiera')
> head(tracks, 5)
               track listeners scrobbles
1:  Nowa Aleksandria     19617    121351
2:    Ludzie wschodu     17710    105302
3: Idziemy przez las     15468     82805
4:  Idziemy na skraj     12944     67068
5:  Jest bezpiecznie     10237     49799
```

Note that last.fm limits this method to only first 10000 tracks.

### get_similar

Get similar artists for a given artist. Example:

```R
edgelist <- get_similar('Closterkeller')
# Get also similarity for artist similar to your input (2nd level)
level2 <- rbindlist(lapply(
  edgelist[, To], get_similar
))
edgelist <- rbindlist(list(edgelist, level2))
> head(edgelist)
            From             To    match
1: Closterkeller       Artrosis        1
2: Closterkeller      Moonlight 0.998498
3: Closterkeller         O.N.A. 0.630667
4: Closterkeller Renata Przemyk 0.485797
5: Closterkeller      Chylińska 0.469014
6: Closterkeller  XIII. Století 0.402615
```

The function returns a `data.table` formatted as edgelist, which is handy if you want to analyze it as a graph (either in *R* or other software such as *Gephi*). `match` is a number on 0-1 scale indicating artist's similarity (returned directly by last.fm).
