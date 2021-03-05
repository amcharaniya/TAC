# dataConversion.R
# Convert input files from Stata to R format
# Nick Lotito, v.2021-03

library(dplyr)
library(tidyr)
library(haven)
library(readr)

setwd("~/GitHub/TACDataProject/TAC")

rm(list=ls())

# Load data created with Stata

dyads.dta <- read_dta("Stata/data_input/Dyads.dta")
link.dta <- read_dta("Stata/data_input/Link.dta")
gtd.dta <- read_dta("Stata/data_input/GTD0814.dta")
ucdp.dta <- read_dta("Stata/data_input/UCDP2014.dta")
date.range.dta <- read_dta("Stata/data_input/DateRange.dta")

# Write to compressed RDS format

write_rds(dyads.dta, "R/data/Dyads.rds", "xz", compression = 7L)
write_rds(link.dta, "R/data/Link.rds", "xz", compression = 7L)
write_rds(gtd.dta, "R/data/GTD0814.rds", "xz", compression = 7L)
write_rds(ucdp.dta, "R/data/UCDP2014.rds")
write_rds(date.range.dta, "R/data/DateRange.rds")

# Confirm files are identical

dyads <- readRDS("R/data/Dyads.rds")
identical(dyads.dta, dyads)
link <- readRDS("R/data/Link.rds")
identical(link.dta, link)
gtd <- readRDS("R/data/GTD0814.rds")
identical(gtd.dta, gtd)
ucdp <- readRDS("R/data/UCDP2014.rds")
identical(ucdp.dta, ucdp)
date.range <- readRDS("R/data/DateRange.rds")
identical(date.range.dta, date.range)

# Write files to Download folder

write_csv(dyads.dta, file = "Download/Dyads.csv")
write_csv(link.dta, file = "Download/Link.csv")
write_rds(dyads.dta, "Download/Dyads.rds", "xz", compression = 7L)
write_rds(link.dta, "Download/Link.rds", "xz", compression = 7L)
