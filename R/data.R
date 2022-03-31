# TAC Data Setup
# Nick Lotito, v.2021-03
library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(plyr)

setwd("~/../GitHub/TAC/R")

rm(list=ls())

# SET UP SOURCE DATA

link.raw <- read_rds("Documents//WashU/Year Two/R Class/TAC/R/data/Link.rds")
gtd.raw <- read_rds("Documents//WashU/Year Two/R Class/TAC/R/data/GTD0814.rds")
ucdp.raw <- read_rds("Documents//WashU/Year Two/R Class/TAC/R/data/UCDP2014.rds")
date.range.raw <- read_rds("Documents//WashU/Year Two/R Class/TAC/R/data/DateRange.rds")
gtd.raw <- read_excel("Documents/Research/Data/Global Terrorism Database/globalterrorismdb_0221dist.xlsx")

link <- link.raw %>%
  as_tibble() %>%
  dplyr::select(dyadid, eventid, gname_match) %>%
  mutate(gname_match = as.factor(abs(gname_match))) %>%
  distinct()

gtd <- gtd.raw %>%
  as_tibble() %>%
  dplyr::select(eventid, year = iyear, crit1, crit2, crit3, attacktype1, attacktype2, attacktype3,
         targtype1, targsubtype1, natlty1, gname, nkill, nkillter, latitude, longitude) %>%
  mutate_at(vars(starts_with("crit")), as.logical) %>%
  mutate(nkillter = ifelse(is.na(nkillter),0,nkillter),
         nkillvic = as.integer(round(nkill - nkillter)),
         fatal = (nkillvic > 0),
         mass = (nkillvic >= 4))	%>%
  dplyr::select(-starts_with("nkill")) %>%
  semi_join(link) # keep only GTD events that appear in link data

ucdp <- ucdp.raw %>%
  as_tibble() %>%
  separate(sidebid, "sidebid", sep = ",", extra = "drop", convert = TRUE) %>%
  dplyr::select(dyadid, sidebid, year, conflictid, location, starts_with("gwno")) %>%
  distinct()

date.range.dyad <- date.range.raw %>% 
  dplyr::select(uid = dyadid, dyad_start, dyad_end) %>%
  group_by(uid) %>% 
  expand(uid, year = seq(first(dyad_start),first(dyad_end))) %>% 
  ungroup()

date.range.group <- date.range.raw %>% 
  left_join(distinct(select(ucdp, dyadid, sidebid))) %>% 
  select(uid = sidebid, dyad_start, dyad_end) %>%
  group_by(uid) %>% 
  expand(uid, year = seq(min(dyad_start),max(dyad_end))) %>% 
  arrange(uid, year) %>% 
  ungroup()

df.source <- left_join(link, distinct(dplyr::select(ucdp, dyadid, sidebid))) %>% 
    dplyr::arrange(sidebid, eventid, gname_match) %>% 
    dplyr::group_by(sidebid, eventid) %>% 
    dplyr::select(sidebid, dyadid, everything()) %>% 
    dplyr::mutate(grouplevel = (row_number()==1)) %>% 
    dplyr::ungroup()
length(unique(df.source$eventid))

df <- NULL
nrow(unique(df))
df <- left_join(df.source, gtd)
variable.names(df)

forge <- Foundation_and_Origins_of_Rebel_Group_Emergence_FORGE_
forge <- forge %>%
  dplyr::rename(sidebid = actorid)

df.1 <- left_join(df, forge, by = 'sidebid')
length(unique(df.1$sidebid))

df.1_group <- NULL
df.1_group <- df.1 %>%
  group_by(sidebid)
civilian <- c(1,8,9,11,12,14,15,16,18,19,21)
government <- c(2,3,4,7,22)
other <- c(5,6,10,13,17,20)

df.1_group <- df.1_group[-which(df.1_group$targtype1 %in% other),]

df.1_group_sub <- df.1_group[1:1000,]  
  
df.1_group$civ <- NA
length(variable.names(df.1_group_sub))

l_ply(df.1_group_sub, function(x) x[which(x$targtype1 %in% civilian),]$civ <- 1)

df.1_group$civ <- NA
df.1_group$gov <- NA


df.1_group[which(df.1_group$targtype1 %in% civilian),]$civ <- 1
df.1_group[which(df.1_group$targtype1 %in% government),]$gov <- 1
variable.names(df.1_group)
df.1_group_sum <- NULL
df.1_group$gov
df.1_group$civ

df.1_group_civ <- df.1_group %>%
  tally(civ) %>%
  group_by(sidebid)
df.1_group_civ <- df.1_group_civ %>%
  dplyr::rename(civkilled = n)
  
df.1_group_gov <- df.1_group %>%
  tally(gov) %>%
  group_by(sidebid)
df.1_group_gov <- df.1_group_gov %>%
  dplyr::rename(govkill = count)

sum(df.1_group_gov$count)
sum(df.1_group_civ$n)

data <- left_join(df.1_group_gov,df.1_group_civ)

count_data <- left_join(data, forge, by = "sidebid")
count_data$civkilled + count_data$govkill
count_data$pctciv <- count_data$civkilled/(count_data$civkilled + count_data$govkill)
hist(count_data$pctciv)
mean(count_data$pctciv)
max(count_data$pctciv)

df.1_group[which(df.1_group$targtype1 %in% government),]$civ <- 0
table(df.1_group$civ)


(df.1_group[,c(61:64,66,68,70)])
