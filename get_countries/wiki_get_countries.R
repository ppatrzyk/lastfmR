# libraries
library(httr)
library(XML)

# get data from wikipedia
# accessed 2018-05-12
url_wiki <- "https://en.wikipedia.org/wiki/List_of_adjectival_and_demonymic_forms_for_countries_and_nations"
get_wiki <- GET(url_wiki)
countries <- readHTMLTable(doc = content(get_wiki, "text"))[[1]]

# clean
countries <- countries[2:nrow(countries), 1:2]
countries <- as.data.frame(apply(countries, 2, function(x) as.character(gsub("\\[.*\\]", "", x))))
countries[,1] <- gsub("\\,.*", "", countries[,1])
countries[,2] <- gsub("\\.", "", countries[,2])
countries <- stack(setNames(strsplit(as.character(countries[,2]), "\\, | or "), countries[,1]))
countries[,1] <- as.character(countries[,1])
countries[,2] <- as.character(countries[,2])
colnames(countries) <- c("adjectival", "country")
countries <- countries[order(countries$adjectival),]
#duplicates
to_delete <- which(countries$country %in% c("Northern Ireland", "Scotland", "Myanmar", "Guernsey", "Macau", "Dominica", "Côte d'Ivoire", "Timor-Leste")) 
to_delete <- to_delete[c(1:7, 11)]
countries <- countries[-to_delete,]

# write
write.csv(countries, "countries.csv", row.names = FALSE)