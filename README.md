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

- artist_country

- global_listners

- global_scrobbles

- user_scrobbles (only if `method = "library"` is used)

One note about *artist_country* column: in order to get this value, the function looks at the list of *tags* of given artist and checks if any of these matches an existing country name (data is taken from [Wikipedia](https://en.wikipedia.org/wiki/List_of_adjectival_and_demonymic_forms_for_countries_and_nations)). As country-related information is not always available there, expect some of the values to be `NA`. Additionally, this value might be wrong in case an artist is incorrectly tagged by the users. The latter happens especially in cases when there are multiple artists with the same name.
