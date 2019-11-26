
I was trying to get the period of record for data in the St. Johns River
Water Management District’s Hydstra database, which houses hydrologic
data. I found the report type HYREP PERIOD, which produces an output
that contains the period of record information I needed. However, it was
not in a convenient format to allow for easy joining to other tables in
Oracle-based tables. This project steps through the data cleaning
process I went through to get the data into a usable format in R.

## HYREP PERIOD data output

The HYREP PERIOD report produces an output that would be very good on a
small scale (i.e., looking at only a few stations at a time):

![](images/HYREP_PERIOD_output.png)

## 

``` r
# Load text file exported from HYREP PERIOD
hy <- data.frame(V1 = readLines("HY_POR_WATERCAT.txt", skipNul = T))
head(hy, 10)
```

    ##                                                                                                          V1
    ## 1                                                                       HYREP.PERIOD V77  Output 02/07/2019
    ## 2                                                                                                          
    ## 3                                                                             File 20014731.A - State Rd 16
    ## 4                                                                                                          
    ## 5   Var     Description                         Start             End               Period          Missing
    ## 6  -------  ----------------------------------  ----------------  ----------------  --------------  -------
    ## 7   227.10  Elev. (feet NAVD88)  Continuous     11:00_06/30/2006  11:00_07/10/2018   12.03 Years         0%
    ## 8   227.14  Elev. (feet NAVD88)  Random Manual  12:01_09/22/1970  11:35_07/10/2018   47.80 Years         0%
    ## 9   232.10  Elev. (feet NGVD29)  Continuous     11:00_06/30/2006  11:00_03/01/2010    3.67 Years         0%
    ## 10  232.14  Elev. (feet NGVD29)  Random Manual  12:01_09/22/1970  11:14_03/01/2010   39.44 Years         0%

## Remove unnecessary lines and whitespace

``` r
hy <- hy %>% 
    filter(!grepl("--|HYREP.PERIOD|Var|dup/|Index", V1), V1 != "") %>% 
    mutate(V1 = str_trim(V1))
head(hy, 10)
```

    ##                                                                                                         V1
    ## 1                                                                            File 20014731.A - State Rd 16
    ## 2  227.10  Elev. (feet NAVD88)  Continuous     11:00_06/30/2006  11:00_07/10/2018   12.03 Years         0%
    ## 3  227.14  Elev. (feet NAVD88)  Random Manual  12:01_09/22/1970  11:35_07/10/2018   47.80 Years         0%
    ## 4  232.10  Elev. (feet NGVD29)  Continuous     11:00_06/30/2006  11:00_03/01/2010    3.67 Years         0%
    ## 5  232.14  Elev. (feet NGVD29)  Random Manual  12:01_09/22/1970  11:14_03/01/2010   39.44 Years         0%
    ## 6                                                                            File 20014731.X - State Rd 16
    ## 7     227.10  Elev. (feet NAVD88)  Continuous  00:00_01/01/2010  06:00_02/07/2019    9.10 Years         0%
    ## 8                                                                            File 20014731.H - State Rd 16
    ## 9     227.10  Elev. (feet NAVD88)  Continuous  11:00_06/30/2006  02:00_09/13/2016   10.21 Years         0%
    ## 10                                                                           File 20014731.W - State Rd 16

## New Site variable, filling down

``` r
hy <- hy %>% 
    mutate(Site = str_extract(V1, "\\d{8}"))
hy <- fill(hy, Site)
```

Extract the variable, start date, and end date from the Hydstra output
Omit all subvariables except 0.10 and 0.14 Omit variables 104 (Static
Head), 252 (X-Section Area), 551 (Barometric pressure)

``` r
hy <- hy %>% 
    mutate(Variable = str_extract(V1, "^\\d+\\.\\d+"),
           StartDate = as.POSIXct(str_extract(V1, "\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4}"),
                               format = "%H:%M_%m/%d/%Y", tz = "EST"),
           EndDate = as.POSIXct(str_sub(str_extract(V1, "\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4}.*?(\\d{2}\\:\\d{2}\\_\\d{2}/\\d{2}/\\d{4})"), -16),
                                format = "%H:%M_%m/%d/%Y", tz = "EST"),
           Var = as.numeric(str_extract(Variable, ".*(?=\\.)")),
           SubVar = as.numeric(str_extract(Variable, "(\\.[^\\.]+)$")
           )) %>% 
    filter(SubVar %in% c(0.1, 0.14), !(Var %in% c(104, 252, 551)))
```

Summarize by Site and variable

``` r
hy_sum <- hy %>% 
    group_by(Site, Var) %>% 
    summarize(Start = min(StartDate), End = max(EndDate))
```

Read in Event Type Hydstra Variable Crosswalk table

``` r
var_xwalk <- read.csv("Event_Var_Xwalk.csv")
```

``` r
hy_sum <- hy_sum %>% 
    mutate(Event = paste(as.character(var_xwalk$Event.Type[var_xwalk$Var == Var]),
                         collapse = ";", sep = " "))
```

    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length
    
    ## Warning in var_xwalk$Var == Var: longer object length is not a multiple of
    ## shorter object length

hy\_sum\(Event <- NA for(i in 1:nrow(hy_sum)) {  hy_sum\)Event\[i\] \<-
paste(as.character(var\_xwalk\(Event.Type[var_xwalk\)Var ==
hy\_sum$Var\[i\]\]), collapse = “;”, sep = " ") }

hy\_sum \<- hy\_sum %\>% group\_by(Site, Event) %\>% summarize(Start =
min(Start), End = max(End))

hy\_sum \<- hy\_sum %\>% mutate(Event = strsplit(as.character(Event),
“;”)) %\>% unnest(Event)

hy\_sum \<- hy\_sum %\>% group\_by(Site, Event) %\>% summarize(Start =
min(Start), End = max(End))
