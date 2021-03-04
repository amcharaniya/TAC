# dataConversion.R
# Convert input files from Stata to R format
# Nick Lotito, v.2021-03

library(dplyr)
library(tidyr)
library(haven)
library(readr)

setwd("~/../GitHub/TAC")

rm(list=ls())

# Load data created with Stata

link.dta <- read_dta("Stata/data_input/Link.dta")
gtd.dta <- read_dta("Stata/data_input/GTD0814.dta")
ucdp.dta <- read_dta("Stata/data_input/UCDP2014.dta")
date.range.dta <- read_dta("Stata/data_input/DateRange.dta")

# Write to compressed RDS format

write_rds(link.dta, "R/data/Link.rds", "xz", compression = 7L)
write_rds(gtd.dta, "R/data/GTD0814.rds", "xz", compression = 7L)
write_rds(ucdp.dta, "R/data/UCDP2014.rds")
write_rds(date.range.dta, "R/data/DateRange.rds")

# Confirm files are identical

link <- readRDS("R/data/Link.rds")
identical(link.dta, link)
gtd <- readRDS("R/data/GTD0814.rds")
identical(gtd.dta, gtd)
ucdp <- readRDS("R/data/UCDP2014.rds")
identical(ucdp.dta, ucdp)
date.range <- readRDS("R/data/DateRange.rds")
identical(date.range.dta, date.range)
