# lastfm-to-R
This function will download all your scrobbles from last.fm into R.

It requires R package [XML](https://cran.r-project.org/web/packages/XML/). Run the following if you do not have it installed:

```R
install.packages("XML")
library(XML)
```
## Usage

First run the script to import the function to the environment; then run the following line:

```R
lastfm <- lastfm_export("enter_your_username")
```

`lastfm` is a `data.frame` object. Each row corresponds to one scrobble. It contains 6 columns:

- artist

- track

- album

- fulldate

- time

- weekday

The difference between *fulldate* and *time* is that *fulldate* contains both date and time (YYYY-MM-DD HH:MM:SS), while *time* contains only time (HH:MM:SS). *time* variable is useful if you want to analyze listening patterns depending on the part of a day.
