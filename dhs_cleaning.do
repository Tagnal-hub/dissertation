* This script cleans the DHS dataset and maps each respondent to a subcounty and thus their access to a facility.
* This is the 2014 DHS dataset for births


****
*** DHS Births
****

cd /*set directory */

use data/births.dta

*Current relevant variables
keep caseid - v007 v012 v025 v106 v130 v131 v133 v138 v140 v190 v191 v201 v440 v444a v445 v481 v501 v701 v715 v730 bord b1 b2 b4 b5 b8 m14 m15 hw70 - hw72 idxml

** get other variables
*create mean wealth index by cluster
egen meanwindex = mean(v191), by(v001)
la var meanwindex "cluster mean wealth factor score"
* rural-urban
gen rural = cond(v025 == 2, 1, 0, .)
*male
gen male = cond(b4 == 1, 1, 0, .)
*education
ren v133 education
* parity
ren v201 parity
* wealth index
ren v191 windex
* child alive
ren b5 childalive
* no. of anc vists
ren m14 ancn


*get only relevant years
gen monthyearbirth = ym( b2, b1)
la var monthyearbirth "birthdate in stata format"
gen policy = cond(monthyeabirth >= ym(2013, 06), 1, 0, .)
la var policy "time effect"
drop if monthyearbirth < ym(2011, 1) 

*gen age of child in months
gen monthyearage = ym(v007, v006)
la var monthyearage "interview date in stata format"
gen agemonths = monthyearage - monthyearbirth
la var agemonths "age in months"

* gen age of mother
gen motherage = v012 - (agemonths/12)
la var motherage "mother's age"

*gen mother malnutrition
replace v440 = cond(v440 == 998, ., v440/100, .)
gen mstunted = cond(v440 < -2, 1, 0, .)
la var mstunted "mother stunted"
label define mstuntedlbl 0 "not stunted" 1 "stunted"
label values mstunted mstuntedlbl
replace v444a = cond(v444a == 9998, ., v444a/100, .)
gen mwasted = cond(v444a < -2, 1, 0, .)
la var mwasted "mother wasted"
label define mwastedlbl 0 "not wasted" 1 "wasted"
label values mwasted mwastedlbl
replace v445 = cond(v445 == 9998, ., v445/100, .)
gen munderweight = cond(v445 <= 18.5, 1, 0, .)
label var munderweight "mother underweight"
label define munderweightlbl 0 "not underweight" 1 "underweight"
label values munderweight munderweightlbl
gen moverweight = cond(v445 >= 25, 1, 0, .)
label var moverweight "mother overweight"
label define moverweightlbl 0 "not overweight" 1 "overweight"
label values moverweight moverweightlbl
gen mmalnourished = cond(mstunted == 1, 1, cond(mwasted == 1, 1, cond(munderweight == 1, 1, 0, .)))
label define mmalnourishlbl 0 "not malnourished" 1 "malnourished"
label values mmalnourished mmalnourishlbl
la var mmalnourished "mother malnourished"


*Delivery into dummy
*Other included in non-hospital
gen facilitydelivery = 1 if m15 == 21| m15 == 22 | m15 == 23 | m15 == 26 | m15 == 31 | m15 == 32 | m15 == 33 | m15 == 36
replace facilitydelivery = 0 if m15 == 11 | m15 == 12 | m15 == 96
la var facilitydelivery "delivery in facility"

*Type of hospital
gen hosptype = cond(m15 == 20 | m15 == 21| m15 == 22 | m15 == 23 | m15 == 26, 1, cond(m15 == 31 | m15 == 32 | m15 == 33 | m15 == 36, 0, .))
la var hosptype "type of hospital"

* label variables
label define policylbl 0 "before 2013" 1 "after 2013"
label values policy policylbl
label define facilitylbl 0 "home" 1 "facility"
label values facilitydelivery facilitylbl
label define typelbl 0 "public" 1 "private"
label values hosptype typelbl

*Drop if missing height/ weight/ implausible
*drop if hw13 != 0 /*decided not to drop dead children */
foreach var of varlist hw70 - hw72 v440 v444a {
	replace `var' = . if `var' == 9996 | `var' == 9997 | `var' == 9998 
}
replace education = . if education == 97
replace v715 = . if v715 == 98

/*make height/weight/age into std deviations
foreach var of varlist hw70 - hw72 {
	replace `var' = `var'/100
}

* generate child malnutrition
gen cstunted = cond(hw70 < -2, 1, 0, .)
la var cstunted "child stunted"
label values cstunted mstuntedlbl
gen cwasted = cond(hw72 < -2, 1, 0, .)
la var cwasted "child wasted"
label values cwasted mwastedlbl
gen cunderweight = cond(hw71 < -2, 1, 0, .)
label var cunderweight "child underweight"
label values cunderweight munderweightlbl
gen coverweight = cond(hw71 > 2, 1, 0, .)
label var coverweight "child overweight"
label values coverweight moverweightlbl
gen cmalnourished = cond(cstunted == 1, 1, cond(cwasted == 1, 1, cond(cunderweight == 1, 1, 0, .)))
label values cmalnourished malnourishlbl
la var cmalnourished "child malnourished"


*/
save dhs/dhsbirths.dta, replace
clear


****
***GPS
****

* Shp to dta for gps location
shp2dta using gps.shp, data(gpsdata) coord(gpscoord) genid(gpsid) replace

use gpsdata.dta
ren all, lower
ren dhsclust v001
ren dhsregna province

save gpsdata.dta, replace
clear

****
***Identify subcounty
****

use .data/dhsbirths.dta

merge m:1 v001 using .data/gpsdata.dta
drop if merge != 3 /*Noone in this regions was eligible */
drop merge
ren all, lower
ren adm1name county

foreach var of varlist county province source {
	replace `var'=ustrlower(`var')
}
drop if source == "mis" /*lat and long are 0,0*/
drop dhsid - adm1dhs dhsregco source altgps - datum

*** Put cluster in subcounty
ren gpsid clusterid
la var clusterid "cluster id"
geoinpoly latnum longnum using ./06gis/subcounty/subcounty/subcountycoord.dta
drop if missing(ID)
ren ID subid


*** Merge with concentration data
merge m:1 subid using .data/subcountymap.dta
drop if merge != 3 /*this subcounty has no person */
drop merge
la var subid "subcounty id"
encode county, gen (dcounty)
la var dcounty "factor variable"
encode subcounty, gen(dsubcounty)
la var dsubcounty "factor variable"
encode province, gen(dprovince)
la var dprovince "factor variable"


save .data/dhs.dta, replace
