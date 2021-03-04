# TAC Data Setup
# Nick Lotito, v.2021-03
library(dplyr)
library(tidyr)
library(readr)

setwd("~/../GitHub/TAC/R")

rm(list=ls())

# SET UP SOURCE DATA

link.raw <- read_rds("data/Link.rds")
gtd.raw <- read_rds("data/GTD0814.rds")
ucdp.raw <- read_rds("data/UCDP2014.rds")
date.range.raw <- read_rds("data/DateRange.rds")

link <- link.raw %>%
  as_tibble() %>%
  select(dyadid, eventid, gname_match) %>%
  mutate(gname_match = as.factor(abs(gname_match))) %>%
  distinct()

gtd <- gtd.raw %>%
  as_tibble() %>%
  select(eventid, year = iyear, crit1, crit2, crit3, attacktype1, attacktype2, attacktype3,
         targtype1, targsubtype1, natlty1, gname, nkill, nkillter) %>%
  mutate_at(vars(starts_with("crit")), as.logical) %>%
  mutate(nkillter = ifelse(is.na(nkillter),0,nkillter),
         nkillvic = as.integer(round(nkill - nkillter)),
         fatal = (nkillvic > 0),
         mass = (nkillvic >= 4))	%>%
  select(-starts_with("nkill")) %>%
  semi_join(link) # keep only GTD events that appear in link data

ucdp <- ucdp.raw %>%
  as_tibble() %>%
  separate(sidebid, "sidebid", sep = ",", extra = "drop", convert = TRUE) %>%
  select(dyadid, sidebid, year, conflictid, location, starts_with("gwno")) %>%
  distinct()

date.range.dyad <- date.range.raw %>% 
  select(uid = dyadid, dyad_start, dyad_end) %>% 
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

df.source <- left_join(link, distinct(select(ucdp, dyadid, sidebid))) %>% 
    arrange(sidebid, eventid, gname_match) %>% 
    group_by(sidebid, eventid) %>% 
    select(sidebid, dyadid, everything()) %>% 
    mutate(grouplevel = (row_number()==1)) %>% 
    ungroup()

df <- left_join(df.source, gtd)

save(df.source, gtd, date.range.dyad, date.range.group, file = "source.Rdata")