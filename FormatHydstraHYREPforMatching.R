#=======================================================================#
## This script cleans the text output from the Hydstra report type     ##
## HYREP PERIOD to generate a data frame that contains the period of   ##
## record for each site and event type combination as needed for a     ##
## metadata summary of active stations in the St. Johns River Water    ##
## Management District's monitoring network                            ##
## Author: Margaret Guyette             Created: January, 2019         ##
#=======================================================================#

## Required packages
library(tidyverse)

## Load text file exported from HYREP PERIOD
hy <- data.frame(V1 = read_lines("HY_POR_WATERCAT.txt", skip_empty_rows = T))

## Remove unnecessary lines and trim whitespace from the beginning and end
## of each row
hy <- hy %>% 
    filter(!grepl("--|HYREP.PERIOD|Var|dup/|Index", V1)) %>% 
    mutate(V1 = str_trim(V1))

## Create a Site column
## The data frame contains a line with information about the site 
## followed by one or more lines of data.  The site designator is 
## an eight digit number included in each line above the data blocks.  
## This extracts this site designator, fills the site designator down
## so that each data row is associated with the correct Site.
## Once the Site variable is extracted, the rows containing the string
## "File" can be omitted.
hy <- hy %>% 
    mutate(Site = str_extract(V1, "\\d{8}")) %>% 
    select(Site, V1) %>% 
    fill(Site) %>% 
    filter(!grepl("File", V1))


## Create additional columns by extracting pieces of the V1 column
## Only some of the variables and subvariables needed to be retained: 
##   Omit all subvariables except 0.10 and 0.14
##   Omit variables 104 (Static Head), 229 (Level), 252 (X-Section Area), 
##   300 (Voltage), 551 (Barometric pressure), and 2327 (YSINitrate-fld)
hy <- hy %>% 
    mutate(Variable = str_extract(V1, "^\\d+\\.\\d+"),
           StartDate = as.POSIXct(str_extract(V1, "\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4}"),
                                  format = "%H:%M_%m/%d/%Y", tz = "EST"),
           EndDate = as.POSIXct(str_sub(str_extract(V1, "\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4}.*?(\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4})"), -16),
                                format = "%H:%M_%m/%d/%Y", tz = "EST"),
           Var = as.numeric(str_extract(Variable, ".*(?=\\.)")),
           SubVar = as.numeric(str_extract(Variable, "(\\.[^\\.]+)$"))) %>% 
    filter(SubVar %in% c(0.1, 0.14), !(Var %in% c(104, 229, 252, 300, 551, 2327)))

## Summarize by Site and variable
hy_sum <- hy %>% 
    group_by(Site, Var) %>% 
    summarize(Start = min(StartDate), End = max(EndDate))

## Read in Event Type Hydstra Variable Crosswalk table so that Event Type can
## be used instead of variable
var_xwalk <- read_csv("Event_Var_Xwalk.csv", col_types = "cd")

## Create the Event column using the crosswalk table
hy_sum <- hy_sum %>% 
    mutate(Event = paste(as.character(unique(var_xwalk$`Event Type`[var_xwalk$Var == Var])),
                         collapse = ";", sep = " ")) %>% 
    mutate(Event = strsplit(as.character(Event), ";")) %>%
    unnest(Event) %>% 
    group_by(Site, Event) %>% 
    summarize(Start = min(Start), End = max(End))

## Remove objects no longer needed
rm(hy, var_xwalk)
