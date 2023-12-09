* This script cleans the DHS dataset and maps each respondent to a subcounty and thus their access to a facility.
* This is the 2014 DHS dataset for births


****
*** DHS Births
****

cd /*set directory */

use dhs/births.dta

*Current relevant variables
keep caseid - v007 v012 v025 v106 v130 v131 v133 v138 v140 v190 v191 v201 v440 v444a v481 v501 v701 v715 v730 bord b1 b2 b4 b5 b8 m15 hw70 - hw72 idxml


*get only relevant years
gen monthyearbirth = ym( b2, b1)
la var monthyearbirth "birthdate in stata format"
gen policy = cond(monthyear >= ym(2013, 06), 1, 0, .)
la var policy "time effect"
drop if monthyear < ym(2011, 1) 

*gen age of child in months
gen monthyearage = ym(v007, v006)
la var monthyearage "interview date in stata format"
gen age_months = monthyearage - monthyearbirth
la var age_months "age in months"

*gen mother stunting/ wasted
gen stunted = cond(v440 < -200, 1, 0, .)
la var stunted "mother stunted"
label define stuntedlbl 0 "not stunted" 1 "stunted"
label values stunted stuntedlbl
gen wasted = cond(v444a < -200, 1, 0, .)
la var wasted "mother wasted"
label define wastedlbl 0 "not wasted" 1 "wasted"
label values wasted wastedlbl
gen malnourished = cond(stunted == 1, 1, cond(wasted == 1, 1, 0,.))
label define malnourishlbl 0 "not malnourished" 1 "malnourished"
label values malnourished malnourishlbl
la var malnourished "mother malnourished"


*Delivery into dummy
*Other included in non-hospital
gen facilitydelivery = 1 if m15 == 21| m15 == 22 | m15 == 23 | m15 == 26 | m15 == 31 | m15 == 32 | m15 == 33 | m15 == 36
replace facilitydelivery = 0 if m15 == 11 | m15 == 12 | m15 == 96
la var facilitydelivery "delivery in facility"

*Type of hospital
gen hosp_type = cond(m15 == 20 | m15 == 21| m15 == 22 | m15 == 23 | m15 == 26, 1, cond(m15 == 31 | m15 == 32 | m15 == 33 | m15 == 36, 0, .))
la var hosp_type "type of hospital"

* label variables
label define policylbl 0 "before 2013" 1 "after 2013"
label values policy policylbl
label define facilitylbl 0 "home" 1 "facility"
label values facilitydelivery facilitylbl
label define typelbl 0 "public" 1 "private"
label values hosp_type typelbl

*Drop if missing height/ weight/ implausible
*drop if hw13 != 0 /*decided not to drop dead children */
foreach var of varlist hw70 - hw72 v440 v444a {
	replace `var' = . if `var' == 9996 | `var' == 9997 | `var' == 9998 
}
replace v133 = . if v133 == 97
replace v715 = . if v715 == 98

/*make height/weight/age into std deviations
foreach var of varlist hw70 - hw72 {
	replace `var' = `var'/100
}
*/
save dhs/dhs_births.dta, replace
clear


****
***GPS
****

* Shp to dta for gps location
shp2dta using gps.shp, data(gps_data) coord(gps_coord) genid(gps_id) replace

use gps_data.dta
ren _all, lower
ren dhsclust v001
ren dhsregna province

save gps_data.dta, replace
clear

****
***Identify subcounty
****

use .data/dhs_births.dta

merge m:1 v001 using .data/gps_data.dta
drop if _merge != 3 /*Noone in this regions was eligible */
drop _merge
ren _all, lower
ren adm1name county

foreach var of varlist county province source {
	replace `var'=ustrlower(`var')
}
drop if source == "mis" /*lat and long are 0,0*/
drop dhsid - adm1dhs dhsregco source alt_gps - datum

*** Put cluster in subcounty
ren gps_id clusterid
la var clusterid "cluster id"
geoinpoly latnum longnum using ./06_gis/subcounty/subcounty/sub_county_coord.dta
drop if missing(_ID)
ren _ID sub_id


*** Merge with concentration data
merge m:1 sub_id using .data/subcountymap.dta
drop if _merge != 3 /*this subcounty has no person */
drop _merge
la var sub_id "subcounty id"
encode county, gen (dcounty)
la var dcounty "factor variable"
encode subcounty, gen(dsubcounty)
la var dsubcounty "factor variable"
encode province, gen(dprovince)
la var dprovince "factor variable"
save .data/dhs.dta, replace




