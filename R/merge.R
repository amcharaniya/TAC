######################################################
# Terrorism in Armed Conflict (TAC)
# Code to Generate Count Data
# Nick Lotito, v.2021-03
######################################################

library(dplyr)
library(tidyr)

setwd("~/../GitHub/TAC/R")

rm(list=ls())
load("source.Rdata")

######################################################
# Define UCDP-GTD match levels
######################################################

matches <- tribble(
    ~gname_match, ~match,
    0, "a",
    1, "a",
    2, "b",
    3, "b",
    4, "c",
    97,"d",
    96,"d",
    5, "e",
    13,"f"
)

######################################################
# Specify less and more restrictive attack and 
#   target criteria (CUSTOMIZE HERE)
######################################################

# Less restrictive (t_a, t_b, ..., m_a, etc.)
attack.list <- c(2:6,9)
target.list <- c(1,6,8,9,11,13:16,18:21)

# More restrictive (tm_a, tm_b, ..., mm_a, etc.)
attack.more.list <- c(2,3)
subtarg.more.list <- c(2, 7, 8, 11, 42, 44, 49:52, 57,
                     60, 65:67, 69:81, 86, 87, 95:105)

######################################################
# Define TAC generation function
######################################################

tac.generate <- function(unit = "group"){
    
    as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}

    if (unit == "group") {
        df <- left_join(df.source, gtd, by = "eventid") %>% 
            rename(uid = sidebid)
    } else if (unit == "dyad") {
        df <- left_join(df.source, gtd, by = "eventid") %>%
            rename(uid = dyadid)
    } else {
        stop("'unit' must be 'group' or 'dyad'")
    }

    # generate counts
    df <- df %>%
        mutate(crit = ifelse(crit1 == TRUE & crit2 == TRUE & crit3 == TRUE, T, F),
            attack = ifelse(attacktype1 %in% attack.list | attacktype2 %in% attack.list | attacktype3 %in% attack.list, T, F),
            target = ifelse(targtype1 %in% target.list, T, F),
            attack.more = ifelse(attacktype1 %in% attack.more.list | attacktype2 %in% attack.more.list | attacktype3 %in% attack.more.list, T, F),
            target.more = ifelse(targsubtype1 %in% subtarg.more.list, T, F)) %>%
        select(uid, year, gname_match, fatal:target.more) %>%
        mutate(t = ifelse(crit == T & attack == T & target == T, T, F),
               f = ifelse(t == T & fatal == T, T, F),
               m = ifelse(t == T & mass == T, T, F),
               tm = ifelse(crit == T & attack.more == T & target.more == T, T, F),
               fm = ifelse(tm == T & fatal == T, T, F),
               mm = ifelse(tm == T & mass == T, T, F),
               gname_match = as.numeric.factor(gname_match)) %>%
        left_join(matches, by = "gname_match") %>%
        filter(!is.na(match)) %>%
        arrange(uid, year, match, t) %>%
        group_by(uid, year, match) %>%
        summarize_at(vars(t:mm), sum) %>%
        ungroup() %>% 
        complete(nesting(uid,year),match,fill = list(t = 0, f = 0, m = 0, tm = 0, fm = 0, mm = 0)) %>%
        group_by(uid, year) %>% 
        mutate_at(vars(t:mm), cumsum) %>% 
        gather(key, value, -uid, -year, -match) %>% 
        mutate(variable = paste0(key, "_", match)) %>% 
        select(-match, -key) %>% 
        spread(variable, value) %>% 
        ungroup() %>% 
        mutate_all(as.integer)

    # expand to group/dyad date range
    if (unit == "group") {
        df <- left_join(date.range.group, df, by = c("uid", "year"))
        df <- bind_rows(filter(df, year == 1993),
                 mutate_all(filter(df, year != 1993), ~replace_na(., 0))) %>% 
              arrange(uid, year) %>% 
              rename(sidebid = uid)
    } else if (unit == "dyad") {
        df <- left_join(date.range.dyad, df, by = c("uid", "year"))
        df <- bind_rows(filter(df, year == 1993),
                 mutate_all(filter(df, year != 1993), ~replace_na(., 0))) %>% 
              arrange(uid, year) %>% 
              rename(dyadid = uid)
    }
}

######################################################
## Output data
######################################################

# Group-year data
df.out.group<- tac.generate("group")

saveRDS(df.out.group, "TAC_group_202010.rds")
haven::write_dta(df.out.group, "TAC_group_202010.dta")
write.csv(df.out.group, "TAC_group_202010.csv")

# Dyad-year data
df.out.dyad <- tac.generate("dyad")

saveRDS(df.out.dyad, "TAC_dyad_202010.rds")
haven::write_dta(df.out.dyad, "TAC_dyad_202010.dta")
write.csv(df.out.dyad, "TAC_dyad_202010.csv")
