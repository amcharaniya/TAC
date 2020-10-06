/*	Causes and Consequences of Terrorism */
/*	Version 09-2020	*/
/*	Page Fortna, Nicholas Lotito, Michael Rubin */

/* This is TAC.do, which links UCDP and GTD based on TAC codings 
	and generates group-year count data */
/*	Input:
	- TAC coding list (Dyads.dta)
	- UCDP Dyadic (UCDP2014.dta)
	- GTD (GTD0814.dta)
	- UCDP and GTD country code pairs (CountryCodes.dta)
	Output:
	- TAC group-year terrorism counts (TAC.dta) */

cd "~/GitHub/TAC/Stata/data_input"

set more off

/* Determine date range for each Dyad */

* Merge with UCDP
* Join Dyads with UCDP
use "Dyads.dta", clear
keep dyadid
duplicates drop
sort dyadid
merge 1:m dyadid using "UCDP2014.dta", ///
	keepusing(year startdate) ///
	assert(using match) keep(match) nogen // all dyads match except conflict types 1 (extrasystemic) and 2 (interstate)
sort dyadid year
gen int first_ucdp = year(date(startdate,"YMD",2020)) // first_ucdp is year of startdate
by dyadid (year), sort: egen int last_ucdp = max(year) 
format %ty first_ucdp last_ucdp
// drop if last_ucdp < 1970
* keep dyad-year observations because we need to know which
* years are included in UCDP (due to meeting threshold)
tempfile UCDP_range
save `UCDP_range'

/* Get first and last attributed GTD attack */

* Merge with GTD
use "GTD0814.dta", clear
keep eventid gname gname2 gname3 iyear
rename gname gname1
reshape long gname, i(eventid) j(gindex)
drop if gname == ""
drop eventid gindex
duplicates drop
// save first and last year per group
sort gname iyear
by gname (iyear): egen int first_gtd = min(iyear)
by gname (iyear): egen int last_gtd = max(iyear)
drop iyear
duplicates drop // one observation per gname
format %ty first_gtd last_gtd
tempfile GTD_range
save `GTD_range' // gname first_gtd last_gtd

use "Dyads.dta", clear
keep if gname_match == 0 | gname_match == 1 // ignore gnames that are not main group or armed wing
rename gtd_gname gname
sort dyadid gname
merge m:1 gname using `GTD_range', assert(match using) keep(match) nogen
sort dyadid

* drop unnecessary vars
keep dyadid first_gtd last_gtd

* collapse multiple DyadID obs into one
sort dyadid first_gtd last_gtd
by dyadid: egen first = min(first_gtd)
by dyadid: egen last = max(last_gtd)
replace first_gtd = first
replace last_gtd = last
drop first last
duplicates drop

// this is a list of the first and last year of a 0 or 1 gname_match per dyad
tempfile Dyad_GTD_range
save `Dyad_GTD_range', replace // dyadid first_gtd last_gtd
clear

/* Merge UCDP Ranges with GTD ranges */
use `UCDP_range', clear
sort dyadid year
merge m:1 dyadid using `Dyad_GTD_range', ///
	keep(master match) nogen
*not all of these match because some dyads do not have a 
*GTD_gname associated with gname_match == 1 or 2

*Generate dyad date ranges
gen int dyad_start = first_ucdp
gen int dyad_end = last_ucdp
format %ty dyad_start dyad_end

* limit range to 1970-2013
drop if dyad_start > 2013 | dyad_end < 1970

*Add 5 years to end of date range (up to end of full time period)
replace dyad_end = dyad_end + 5
replace dyad_end = 2013 if dyad_end > 2013 // end of GTD data

*Adjust for matching GTD attacks
replace dyad_start = first_gtd if first_gtd < dyad_start
replace dyad_end = last_gtd if dyad_end < last_gtd & last_gtd != .

*limit range to 1970-2013
replace dyad_start = 1970 if dyad_start < 1970
replace dyad_end = 2013 if dyad_end > 2013

tempfile DateRange_annual
save `DateRange_annual' // date ranges for all dyad-years
/* DateRange_annual includes per dyad :
years in UCDP, start and end of CCT date 
range, and UCDP and GTD date ranges. 
Only includes matches with main group or 
armed wing (gname_match = 0 or 1) */

/* Generate Date Ranges uniquely identified on DyadID */
drop year
duplicates drop
tempfile DateRange
save `DateRange' // date ranges per Dyad, one obs per DyadID
save "DateRange.dta"

/* Add UCDP numerical country codes to GTD */
use "CountryCodes.dta", clear
gen country = gtd_numeric
gen country_ucdp = ucdp_statenum
gen natlty1 = gtd_numeric
gen natlty1_ucdp = ucdp_statenum
tempfile ccodes
save `ccodes'
use "GTD0814.dta", clear
keep eventid iyear gname gname2 gname3 country country_txt ///
	crit1 crit2 crit3 doubtterr natlty1 natlty1_txt ///
	natlty2 natlty2_txt natlty3 natlty3_txt
rename gname gname1
reshape long gname, i(eventid) j(gindex)
drop if gname == ""
order gindex, after(gname)
merge m:1 country using `ccodes', keep(master match) assert(match) nogen keepusing(country_ucdp)
merge m:1 natlty1 using `ccodes', keep(master match) nogen keepusing(natlty1_ucdp)
tempfile GTD_STND
save `GTD_STND'

/* Generate Link with attributed and Unknown GTD attacks */

* Generate Link with attributed GTD attacks
use "Dyads.dta", clear
rename gtd_gname gname
drop if gname_match == 13 | gname_match == 5  //< 0 | gname_match > 4 // only 0-4
sort gname dyadid
joinby gname using `GTD_STND'
sort gname dyadid eventid
format %30s gname sideb
format %14.0g eventid
tempfile Link_part1
save `Link_part1'

* Add Unknown perpetrator attacks for each Dyad

* Link Unknown attacks on country
* match on gname = Unknown and Location = SideA
use "Dyads.dta", clear
rename gtd_gname gname
keep if gname_match == 13 | gname_match == 5 // only unknown and generic
sort dyadid
gen country_ucdp = gwnoa
merge m:1 dyadid using `DateRange', /// assert(match)  add date range
	keep(match) keepusing(dyad_start dyad_end) nogen
sort country_ucdp dyadid

joinby gname country_ucdp using `GTD_STND'
sort dyadid eventid

drop if (iyear < dyad_start)
drop if (iyear > dyad_end)

drop dyad_start dyad_end country_ucdp natlty1_ucdp
sort dyadid eventid

tempfile Link_part2 // unknown perp, country match
save `Link_part2', replace

* Match Unknown attacks on target nationality
*Merge on gname = Unknown and Target = SideA
use "Dyads.dta", clear
rename gtd_gname gname
keep if gname_match == 13 | gname_match == 5 // only unknown and generic
gen natlty1_ucdp = gwnoa
merge m:1 dyadid using `DateRange', /// Add date range
	keep(match) keepusing(dyad_start dyad_end) nogen
sort natlty1_ucdp dyadid

joinby gname natlty1_ucdp using `GTD_STND'
sort dyadid eventid

drop if iyear < dyad_start
drop if iyear > dyad_end

drop dyad_start dyad_end country_ucdp natlty1_ucdp
sort dyadid eventid

tempfile Link_part3 // unknown perp, target match
save `Link_part3', replace

/* Combine Link parts 1, 2, and 3 */
use `Link_part1', clear
append using `Link_part2' `Link_part3'

keep dyadid sideb eventid gname gname_match iyear

// if same event matches twice, keep the one with lowest gname_match
gen gname_match2 = .
replace gname_match2 = gname_match if gname_match >= 0
sort dyadid eventid gname_match2 gname
by dyadid eventid: keep if _n == 1
drop gname_match2

/*Format data */
rename iyear gtd_year
order dyadid sideb eventid gname gname_match gtd_year
sort dyadid gname_match gname eventid
format gname %30s
format sideb %30s

tempfile Link
save `Link'
save "Link.dta", replace
// cf _all using "C:/Users/njl26/Dropbox/Fortna RA Folder/TAC/Data Paper/CMPS Submission/data/AutoLink_20200120.dta" // assert same as submitted version

*******************************************************************
*******************************************************************
** Generate Terrorism Counts
*******************************************************************

/* Add Sidebid */
use "UCDP2014.dta", clear
keep dyadid sidebid
destring sidebid, replace force
duplicates drop
sort dyadid sidebid
tempfile ucdp_sidebid
save `ucdp_sidebid'
use `Link', clear
merge m:1 dyadid using `ucdp_sidebid', nogen keep(master match)

/* Merge Link with GTD */
merge m:1 eventid using "GTD0814.dta", ///
	keepusing(nkill nkillter crit1 crit2 crit3 attacktype1 targtype1 targsubtype1) ///
	keep(match) assert(match using) nogen
sort sidebid eventid
* Includes all Link data and GTD data matched on incidentID
* 	including full date (for use in determining period splits)

/* Generate GTD count vars  */
replace gname_match = 96 if gname_match == -96
replace gname_match = 97 if gname_match == -97

recode nkillter (. = 0), gen(nkillter0)
gen nkillvic = round(nkill - nkillter0, .01)
gen fatal = 0 if nkillvic == 0 | nkillvic == .
replace fatal = 1 if nkillvic > 0 & nkillvic != .
gen mass = 0 if nkillvic == 0
replace mass = 1 if nkillvic >= 4 & nkillvic != .

/* generate dummies	to indicate whether each attack matches the least restrictive or most restrictive criteria */
gen match_crit = 1 if crit1 == 1 & crit2 == 1 & crit3 == 1
gen match_attack_least = 1 if /// 2, 3, 4, 5, 6, 9 (unknown, added 7/12/18)
	attacktype1 == 2 | attacktype1 == 3 | attacktype1 == 4 | attacktype1 == 5 | attacktype1 == 6 | attacktype1 == 9
gen match_targ_least = 1 if /// 1, 6, 8, 9, 11, 13-16, 18-21 (added 13 on 9/2/16, 11 on 5/3/18, 20 [unknown] on 7/12/18)
	targtype1 == 1 | targtype1 == 6 | targtype1 == 8 | targtype1 == 9 | targtype1 == 11 | targtype1 == 13 | ///
	targtype1 == 14 | targtype1 == 15 | targtype1 == 16 | targtype1 == 18 | targtype1 == 19 | targtype1 == 20 | targtype1 == 21
gen least_restrictive = 1 if ///
	match_crit == 1 & match_attack_least == 1 & ///
	match_targ_least == 1
	
gen match_attack_most = 1 if /// 2,3
	attacktype1 == 2 | attacktype1 == 3
/* attacktype: 2 armed assault; 3 bombing/explosion */
gen match_targ_most = 1 if /// 2, 7-8, 11, 42, 44, 49-52, 57, 60, 65-67, 69-81, 86-87, 95-105 (Changed to include 51-52, 87 on 9/2/16, 57 & 60 on 5/3/18)
	targsubtype1 == 2 | targsubtype1 == 7 | targsubtype1 == 8 | targsubtype1 == 11 | targsubtype1 == 42 | ///
	targsubtype1 == 44 | targsubtype1 == 49 | targsubtype1 == 50 | targsubtype1 == 51 | targsubtype1 == 52 | ///
	targsubtype1 == 57 | targsubtype1 == 60 | targsubtype1 == 65 | targsubtype1 == 66 | ///
	targsubtype1 == 67 | targsubtype1 == 69 | targsubtype1 == 70 | targsubtype1 == 71 | targsubtype1 == 72 | ///
	targsubtype1 == 73 | targsubtype1 == 74 | targsubtype1 == 75 | targsubtype1 == 76 | targsubtype1 == 77 | ///
	targsubtype1 == 78 | targsubtype1 == 79 | targsubtype1 == 80 | targsubtype1 == 81 | targsubtype1 == 86 | targsubtype1 == 87 | ///
	targsubtype1 == 95 | targsubtype1 == 96 | targsubtype1 == 97 | targsubtype1 == 98 | targsubtype1 == 99 | ///
	targsubtype1 == 100 | targsubtype1 == 101 | targsubtype1 == 102 | targsubtype1 == 103 | ///
	targsubtype1 == 104 | targsubtype1 == 105
gen most_restrictive = 1 if ///
	match_crit == 1 & match_attack_most == 1 & ///
	match_targ_most == 1

keep dyadid sidebid eventid gname gname_match gtd_year fatal mass least_restrictive most_restrictive nkillvic nkill

* incident count
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating t_`i'"
	gen x = 1 if gname_match == `i' & least_restrictive == 1
	by sidebid gtd_year, sort: egen t_`i' = sum(x)
	drop x
}
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating tm_`i'"
	gen x = 1 if gname_match == `i' & most_restrictive == 1
	by sidebid gtd_year, sort: egen tm_`i' = sum(x)
	drop x
}
gen t_a = t_0 + t_1
gen t_b = t_a + t_2 + t_3
gen t_c = t_b + t_4
gen t_d = t_c + t_97 + t_96
gen t_e = t_d + t_5
gen t_f = t_e + t_13
gen tm_a = tm_0 + tm_1
gen tm_b = tm_a + tm_2 + tm_3
gen tm_c = tm_b + tm_4
gen tm_d = tm_c + tm_97 + tm_96
gen tm_e = tm_d + tm_5
gen tm_f = tm_e + tm_13
drop t_0-tm_96

gen x = 1 if gname_match == 0 | gname_match == 1
by sidebid gtd_year, sort: egen t_a_all = sum(x)
drop x

* fatal incident count
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating f_`i'"
	gen x = 1 if gname_match == `i' & ///
	least_restrictive == 1 & fatal == 1
	gen y = 1 if x == 1 & !missing(nkill)
	by sidebid gtd_year, sort: egen f_`i' = sum(x)
	by sidebid gtd_year, sort: egen f_`i'_na = sum(y)
	drop x y
}
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating fm_`i'"
	gen x = 1 if gname_match == `i' & ///
	most_restrictive == 1 & fatal == 1
	gen y = 1 if x == 1 & !missing(nkill)
	by sidebid gtd_year, sort: egen fm_`i' = sum(x)
	by sidebid gtd_year, sort: egen fm_`i'_na = sum(y)
	drop x y
}
gen f_a = f_0 + f_1
gen f_b = f_a + f_2 + f_3
gen f_c = f_b + f_4
gen f_d = f_c + f_97 + f_96
gen f_e = f_d + f_5
gen f_f = f_e + f_13
gen fm_a = fm_0 + fm_1
gen fm_b = fm_a + fm_2 + fm_3
gen fm_c = fm_b + fm_4
gen fm_d = fm_c + fm_97 + fm_96
gen fm_e = fm_d + fm_5
gen fm_f = fm_e + fm_13

gen f_a_na = f_0_na + f_1_na
gen f_b_na = f_a_na + f_2_na + f_3_na
gen f_c_na = f_b_na + f_4_na
gen f_d_na = f_c_na + f_97_na + f_96_na
gen f_e_na = f_d_na + f_5_na
gen f_f_na = f_e_na + f_13_na
gen fm_a_na = fm_0_na + fm_1_na
gen fm_b_na = fm_a_na + fm_2_na + fm_3_na
gen fm_c_na = fm_b_na + fm_4_na
gen fm_d_na = fm_c_na + fm_97_na + fm_96_na
gen fm_e_na = fm_d_na + fm_5_na
gen fm_f_na = fm_e_na + fm_13_na

drop f_0-fm_96_na

* mass killing incident count
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating m_`i'"
	gen x = 1 if gname_match == `i' & ///
	least_restrictive == 1 & mass == 1
	gen y = 1 if x == 1 & !missing(nkill)
	by sidebid gtd_year, sort: egen m_`i' = sum(x)
	by sidebid gtd_year, sort: egen m_`i'_na = sum(y)
	drop x y
}
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating mm_`i'"
	gen x = 1 if gname_match == `i' & ///
	most_restrictive == 1 & mass == 1
	gen y = 1 if x == 1 & !missing(nkill)
	by sidebid gtd_year, sort: egen mm_`i' = sum(x)
	by sidebid gtd_year, sort: egen mm_`i'_na = sum(y)
	drop x y
}
gen m_a = m_0 + m_1
gen m_b = m_a + m_2 + m_3
gen m_c = m_b + m_4
gen m_d = m_c + m_97 + m_96
gen m_e = m_d + m_5
gen m_f = m_e + m_13
gen mm_a = mm_0 + mm_1
gen mm_b = mm_a + mm_2 + mm_3
gen mm_c = mm_b + mm_4
gen mm_d = mm_c + mm_97 + mm_96
gen mm_e = mm_d + mm_5
gen mm_f = mm_e + mm_13

gen m_a_na = m_0_na + m_1_na
gen m_b_na = m_a_na + m_2_na + m_3_na
gen m_c_na = m_b_na + m_4_na
gen m_d_na = m_c_na + m_97_na + m_96_na
gen m_e_na = m_d_na + m_5_na
gen m_f_na = m_e_na + m_13_na
gen mm_a_na = mm_0_na + mm_1_na
gen mm_b_na = mm_a_na + mm_2_na + mm_3_na
gen mm_c_na = mm_b_na + mm_4_na
gen mm_d_na = mm_c_na + mm_97_na + mm_96_na
gen mm_e_na = mm_d_na + mm_5_na
gen mm_f_na = mm_e_na + mm_13_na
drop m_0-mm_96_na

* fatality count
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating k_`i'"
	gen x = nkillvic if gname_match == `i' & ///
	least_restrictive == 1
	gen y = 1 if x == 1 & !missing(nkill)
	by sidebid gtd_year, sort: egen k_`i' = sum(x)
	by sidebid gtd_year, sort: egen k_`i'_na = sum(y)
	drop x y
}
foreach i in 0 1 2 3 4 5 13 97 96 {
	display "Generating km_`i'"
	gen x = nkillvic if gname_match == `i' & ///
	most_restrictive == 1
	gen y = 1 if x == 1 & !missing(nkill)
	by sidebid gtd_year, sort: egen km_`i' = sum(x)
	by sidebid gtd_year, sort: egen km_`i'_na = sum(y)
	drop x y
}
gen k_a = k_0 + k_1
gen k_b = k_a + k_2 + k_3
gen k_c = k_b + k_4
gen k_d = k_c + k_97 + k_96
gen k_e = k_d + k_5
gen k_f = k_e + k_13
gen km_a = km_0 + km_1
gen km_b = km_a + km_2 + km_3
gen km_c = km_b + km_4
gen km_d = km_c + km_97 + km_96
gen km_e = km_d + km_5
gen km_f = km_e + km_13

gen k_a_na = k_0_na + k_1_na
gen k_b_na = k_a_na + k_2_na + k_3_na
gen k_c_na = k_b_na + k_4_na
gen k_d_na = k_c_na + k_97_na + k_96_na
gen k_e_na = k_d_na + k_5_na
gen k_f_na = k_e_na + k_13_na
gen km_a_na = km_0_na + km_1_na
gen km_b_na = km_a_na + km_2_na + km_3_na
gen km_c_na = km_b_na + km_4_na
gen km_d_na = km_c_na + km_97_na + km_96_na
gen km_e_na = km_d_na + km_5_na
gen km_f_na = km_e_na + km_13_na
drop k_0-km_96_na

drop least_restrictive

by sidebid gtd_year, sort: egen totalgtd = count(eventid)
label variable totalgtd "incidents"

rename gtd_year year

/* Collapse to one obs per group-year */
keep sidebid year totalgtd t_* f_* m_* k_* tm_* fm_* mm_* km_*
sort sidebid year
duplicates drop

tempfile GTD_annual
save `GTD_annual'

// expand out all years in dyad range
use `DateRange', clear
keep dyadid dyad_start dyad_end
merge m:1 dyadid using `ucdp_sidebid', keep(match) nogen
bysort sidebid: egen start = min(dyad_start)
bysort sidebid: egen end = max(dyad_end)
keep sidebid start end
duplicates drop
expand end - start + 1
bysort sidebid: gen year = start + _n - 1
keep sidebid year
merge 1:1 sidebid year using `GTD_annual', nogen keep(master match)

drop totalgtd

foreach myvar of varlist t_a-km_f {
	replace `myvar' = 0 if `myvar' == . & year != 1993
}

*label variables
label variable sidebid "UCDP group id"
label variable year "Year"

foreach i of var t_* {
	local j = "T incidents least " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}
foreach i of var tm_* {
	local j = "T incidents most " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}
foreach i of var f_* {
	local j = "fatal T incidents least " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}
foreach i of var fm_* {
	local j = "fatal T incidents most " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}
foreach i of var m_* {
	local j = "mass T incidents least " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}
foreach i of var mm_* {
	local j = "mass T incidents most " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}
foreach i of var k_* {
	local j = "T fatalities least " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}
foreach i of var km_* {
	local j = "T fatalities most " + strupper(substr("`i'",-1,1))
	label variable `i' "`j'"
}

*** SAVE DATA ***

save "../TAC.dta"

exit
