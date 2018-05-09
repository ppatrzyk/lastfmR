# lastfm-to-R
This function will download all your scrobbles from [last.fm](https://www.last.fm/) into R. It requires R packages [XML](https://cran.r-project.org/web/packages/XML/) and [data.table](https://cran.r-project.org/web/packages/data.table/).

## Usage

First run the script to import the function to the environment; then run the following line:

```R
scrobbles <- get_scrobbles("enter_your_username")
```

`scrobbles` is a `data.table` object. Each row corresponds to one scrobble. It contains 4 columns:

- date

- artist

- track

- album
