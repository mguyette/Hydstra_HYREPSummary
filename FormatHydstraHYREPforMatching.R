## Required packages
library(dplyr)
library(tidyr)
library(stringr)

## Load csv file exported from HYREP PERIOD
hy <- data.frame(readLines("./DataFiles/HY_POR_WATERCAT.txt", skipNul = T))

names(hy) <- "V1"
## Remove unnecessary lines
hy <- hy %>% 
    filter(!grepl("--", V1) & !grepl("HYREP.PERIOD", V1) &
               !grepl("Var", V1) & V1 != "")

## Create new, empty, variables
hy$Site <- hy$Variable <- hy$StartDate <- hy$EndDate <- NA

## Populate the Site variable with the Hydron ID from the File row
for(i in 1:nrow(hy)) {
    if(grepl("\\d{8}", hy$V1[i])) {
        hy$Site[i] <- regmatches(hy$V1[i],
                                   regexpr("\\d{8}", hy$V1[i]))
    }
}

## Fill down the Hydron ID to associate the variables
## with the appropriate Hydron ID
hy <- fill(hy, Site)

## Remove unnecessary lines
hy <- hy %>% 
    filter(!grepl("File", V1), !grepl("Index", V1),
           !grepl("Differences", V1), !grepl("Read", V1), 
           !grepl("dup/", V1))

## Remove whitespace
## (there is a tab or space at the beginning of every line)
hy$V1 <- trimws(hy$V1)

## Extract the variable, start date, and end date from the Hydstra output
for(i in 1:nrow(hy)) {
    hy$Variable[i] <- regmatches(hy$V1[i], 
                                   regexpr("^\\d+\\.\\d+", hy$V1[i]))
    hy$StartDate[i] <- str_extract(hy$V1[i], "\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4}")
    hy$EndDate[i] <- as.character(data.frame(str_extract_all(hy$V1[i], "\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4}"))[2,])
}

## Reformat the dates as dates recognizable by R
hy$EndDate <- as.Date(hy$EndDate,format = "%H:%M_%m/%d/%Y")
hy$StartDate <- as.Date(hy$StartDate,format = "%H:%M_%m/%d/%Y")

## 
hy$Var <- as.numeric(str_extract(hy$Variable, ".*(?=\\.)"))
hy$SubVar <- as.numeric(str_extract(hy$Variable, "(\\.[^\\.]+)$"))

## Omit all subvariables except 0.10 and 0.14
## Omit variables 104 (Static Head), 252 (X-Section Area), 551 (Barometric pressure)
hy <- hy %>% 
    filter(SubVar %in% c(0.1, 0.14), !(Var %in% c(104, 252, 551)))



## Summarize by Site and variable
hy_sum <- hy %>% 
    group_by(Site, Var) %>% 
    summarize(Start = min(StartDate), End = max(EndDate))

## Read in Event Type Hydstra Variable Crosswalk table
var_xwalk <- read.csv("./DataFiles/Event_Var_Xwalk.csv")

hy_sum$Event <- NA
for(i in 1:nrow(hy_sum)) {
    hy_sum$Event[i] <- paste(as.character(var_xwalk$Event.Type[var_xwalk$Var == hy_sum$Var[i]]), collapse = ";", sep = " ")
}

hy_sum <- hy_sum %>% 
    group_by(Site, Event) %>% 
    summarize(Start = min(Start), End = max(End))


hy_sum <- hy_sum %>% 
    mutate(Event = strsplit(as.character(Event), ";")) %>%
    unnest(Event)

hy_sum <- hy_sum %>% 
    group_by(Site, Event) %>% 
    summarize(Start = min(Start), End = max(End))



