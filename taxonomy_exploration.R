library(dplyr)
library(tidyr)
library(stringr)

taxo_clean <-
taxo %>%
  mutate(Taxonomy = str_replace_all(pattern = "\\([0-9]+\\)", replacement = "", string = Taxonomy))%>% 
  separate(col = Taxonomy, sep = ";", into = paste0("lvl", 1:6))


lapply(X = names(taxo_clean)[3:8], function(x){
taxo_clean %>%
  group_by_(.dots = x) %>%
  summarise(read_count = sum(Size)) %>%
  arrange(desc(read_count))})
