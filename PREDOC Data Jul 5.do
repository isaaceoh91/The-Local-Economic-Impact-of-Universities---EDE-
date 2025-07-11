/*
Author: Isaac Oh
Date: July 5, 2025
Purpose: Read-in and clean data for PREDOC project
*/

* Preamble
clear all
set more off

* Change wd to get to raw data
cd "/Users/isaacoh/Documents/EDE+/raw_data"

* Import data
* use usa_00002, clear
* This one didn't have the right code

* Bringing in Excel spreadsheet
import excel using US_FIPS_Codes.xlsx, sheet("3,142 U.S. Counties") firstrow clear
save "US_FIPS_Codes.dta"
use US_FIPS_Codes, clear

* This one does
use usa_00004, clear

* Make a compatible string variable to merge by county and state codes
tostring countyfip, replace
generate FIPSCounty = string(real(countyfip),"%03.0f")
* Old code; using new thing by changing variables in Excel to bytes and ints
* Needed to use it again
tostring statefip, generate(FIPSState_inter)
generate FIPSState = string(real(FIPSState_inter), "%02.0f")

* Modify FIPSState and FIPSCounty to numeric to merge with usa_00004
* New names are statefip and countyfip
* destring FIPSState, generate(statefip)
* destring FIPSCounty, generate(countyfip)

* Merge sheet with dependent variable dataset
* use usa_00004, clear
* keep if countyfip >= 0 
* keep if year >= 2000
preserve
merge m:1 FIPSCounty FIPSState using US_FIPS_Codes
sort year
keep if _merge == 3
drop _merge

* Clean out missing values
drop if incwage == 999999
save "US_County_Inc_Wage_Merged.dta"

* Bring in list of universities
import excel using University_List.xlsx, sheet("1-8") firstrow clear
* Eliminate counties with more than one university
save "University_List.dta"
use University_List, clear
duplicates drop CountyName, force
save "University_List_Final.dta"

* Merge data with university list
use University_List_Final, clear
merge 1:m CountyName using US_County_Inc_Wage_Merged
gen treat = 0
replace treat = 1 if _merge == 3
drop if _merge == 1
drop _merge
save "Uni_Income.dta"

* Make index variable for years since university founding
use Uni_Income, clear
gen index = 0
drop if YearFounded < 1950
replace index = year - YearFounded if treat == 1
replace index = year - 1994 if treat == 0

* Check for parallel pre-trends
* Make a line graph of income/wages of treatment group
preserve
drop if treat == 1
collapse (mean) incwage, by(index)
twoway line incwage index
restore



