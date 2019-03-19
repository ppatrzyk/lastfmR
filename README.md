# lastfm-to-R
R functions to download [last.fm](https://www.last.fm/) data. 

## Requirements

- R package [curl](https://cran.r-project.org/web/packages/curl/),

- R package [XML](https://cran.r-project.org/web/packages/XML/),

- R package [data.table](https://cran.r-project.org/web/packages/data.table/).

## Usage

### get_scrobbles

This function will download all your scrobbles from [last.fm](https://www.last.fm/).

First run the script to import the function to the environment; then run the following line:

```R
scrobbles <- get_scrobbles("enter_your_username")
```

`scrobbles` is a `data.table` object. Each row corresponds to one scrobble. It contains 4 columns:

- date

- artist

- track

- album

### get_artist_info

This function will download information about specific artists from [last.fm](https://www.last.fm/). There are two ways to use it:

- `method = "library"` (default): enter your username as a parameter and data about all artists from your library will be downloaded. 

- `method = "artist_vector"`: pass a vector of artist names and data about them will be downloaded.

Here is a sample code:

```R
# Option 1
artist_info <- get_artist_info(user = "enter_your_username")

# Option 2
artists <- c("Anthrax", "Metallica", "Megadeth", "Slayer")
artist_info <- get_artist_info(method = "artist_vector", artist_vector = artists)
```

The function returns a `data.table` object with the following columns:

- artist

- artist_tag (the most popular tag)

- global_listners

- global_scrobbles

- user_scrobbles (only if `method = "library"` is used)
