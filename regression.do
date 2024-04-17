* This is the script for the regressions and producing tables (balance and results).


cd /* Set directory */

use ./05_final/dhs.dta


* Generate quartile
xtile quartile = lq_2015, nq(4)
gen concentration = cond(quartile == 1, 1, .)
replace concentration = 0 if quartile == 4
la var concentration "treatment effect"
la define concentrationlbl 0 "concentrated" 1 "competitive"
la values concentration concentrationlbl

*Generate deprivation
xtile half = mean_windex, nq(2)
gen deprived = cond(half == 1, 1, 0)
la var deprived "subcounty has low mean wealth factor score"


\\drop if anc_visits == 0 & facilitydelivery == 0

****
***Balance tables
****

*Cutoff is bottom quartile
iebaltab rural education windex parity motherage male childalive policy ancn agemonths mstunted mwasted mmalnourished, groupvar(concentration) rowvar savetex(./tables/baltab_quartile_og.tex) texnotefile(./table/baltab_quartile_og_note.tex) replace

iebaltab rural v133 v191 v201  male b5 policy m14 age_months mstunted mwasted mmalnourished, groupvar(concentration) rowvar savetex(.table/baltab_quartile_ancdel.tex) texnotefile(./table/baltab_quartile_ancdel_note.tex) replace


****
*** Intermediate outcomes
****

reg ancn concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
estimates store anc1, title (anc visits)
reg facilitydelivery concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
estimates store del1, title(delivery)

reg ancn concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
estimates store anc2, title(anc visits)
reg facilitydelivery concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
estimates store del2, title(delivery)

reg anc_visits concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
estimates store anc3, title(anc visits)
reg facilitydelivery concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
estimates store del3, title(delivery)

*Create table
esttab anc1 del1 anc2 del2 anc3 del3 using tables/public.tex, replace se ar2 mtitles label title("Intermediate Results") star(* 0.1 ** 0.05 *** 0.01) noomitted

*private
reg private_visits concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
estimates store privanc1, title (anc visits)
reg privatedelivery concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
estimates store privdel1, title(delivery)

reg private_visits concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
estimates store privanc2, title(anc visits)
reg privatedelivery concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
estimates store privdel2, title(delivery)

reg private_visits concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
estimates store privanc3, title(anc visits)
reg privatedelivery concentration##policy rural v201 i.age_groups i.v106 i.v190 male i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
estimates store privdel3, title(delivery)

*create table
esttab privanc1 privdel1 privanc2 privdel2 privanc3 privdel3 using ./tables/private.tex, replace se ar2 mtitles label title("Intermediate Results") star(* 0.1 ** 0.05 *** 0.01) noomitted
drop if anc_visits == 0 & facilitydelivery == 0

****
***Scores
****
 
eststo haz : reg hw70 concentration##policy rural i.age_groups i.v106 i.v190 v440 male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
eststo waz : reg hw71 concentration##policy rural i.age_groups i.v106 i.v190 v445 male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
eststo whz : reg hw72 concentration##policy rural i.age_groups i.v106 i.v190 v444a male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
esttab haz waz whz using ./tables/score.tex, replace se ar2 mtitles label title("Nutrition scores") star(* 0.1 ** 0.05 *** 0.01) noomitted

eststo haz1 : reg hw70 concentration##policy rural i.age_groups i.v106 i.v190 v440 male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, 
cluster(dsubcounty) 
eststo waz1 : reg hw71 concentration##policy rural i.age_groups i.v106 i.v190 v445 male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
eststo whz1 : reg hw72 concentration##policy rural i.age_groups i.v106 i.v190 v444a male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
esttab haz1 waz1 whz1 using ./tables/depscore.tex, replace se ar2 mtitles label title("Nutrition scores for deprived") star(* 0.1 ** 0.05 *** 0.01) noomitted

eststo haz2 : reg hw70 concentration##policy rural i.age_groups i.v106 i.v190 v440 male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
eststo waz2 : reg hw71 concentration##policy rural i.age_groups i.v106 i.v190 v445 male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
eststo whz2 : reg hw72 concentration##policy rural i.age_groups i.v106 i.v190 v444a male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
esttab haz2 waz2 whz2 using ./tables/9monthscore.tex, replace se ar2 mtitles label title("Nutrition scores for 9 months") star(* 0.1 ** 0.05 *** 0.01) noomitted

****
***Malnutrition
****

eststo stunted : reg cstunted concentration##policy rural i.age_groups i.v106 i.v190 mstunted male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
eststo underweight : reg cunderweight concentration##policy rural i.age_groups i.v106 i.v190 munderweight male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
eststo overweight : reg coverweight concentration##policy rural i.age_groups i.v106 i.v190 moverweight male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
eststo wasted : reg cwasted concentration##policy rural i.age_groups i.v106 i.v190 mwasted male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty, cluster(dsubcounty)
esttab stunted underweight overweight wasted using ./tables/malnutrition.tex, replace se ar2 mtitles label title("Malnutrition") star(* 0.1 ** 0.05 *** 0.01) noomitted

eststo stunted1 : reg cstunted concentration##policy rural i.age_groups i.v106 i.v190 mstunted male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
eststo underweight1 : reg cunderweight concentration##policy rural i.age_groups i.v106 i.v190 munderweight male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
eststo overweight1 : reg coverweight concentration##policy rural i.age_groups i.v106 i.v190 moverweight male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1, cluster(dsubcounty)
eststo wasted1 : reg cwasted concentration##policy rural i.age_groups i.v106 i.v190 mwasted male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if deprived == 1 , cluster(dsubcounty)
esttab stunted1 underweight1 overweight1 wasted1 using ./tables/deprived_malnutrition.tex, replace se ar2 mtitles label title("Malnutrition") star(* 0.1 ** 0.05 *** 0.01) noomitted

eststo stunted2 : reg cstunted concentration##policy rural i.age_groups i.v106 i.v190 mstunted male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
eststo underweight2 : reg cunderweight concentration##policy rural i.age_groups i.v106 i.v190 munderweight male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
eststo overweight2 : reg coverweight concentration##policy rural i.age_groups i.v106 i.v190 moverweight male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
eststo wasted2 : reg cwasted concentration##policy rural i.age_groups i.v106 i.v190 mwasted male age_months bord i.b1 i.b2 i.dcounty i.dsubcounty if nine_months == 1, cluster(dsubcounty)
esttab stunted2 underweight2 overweight2 wasted2 using ./table/9month_malnutrition.tex, replace se ar2 mtitles label title("Malnutrition") star(* 0.1 ** 0.05 *** 0.01) noomitted



*Using diff in diff tables

ieddtab hw70 - hw72, time( policy ) treat( concentration ) covar (rural i.v106 i.v190 b4 v201 v012 v481 bord b4 b5 idxml age_months mstunted mwasted mmalnourished)replace savetex("./table/nutrition_did1.tex") rowlabtype("varlab") onerow 

ieddtab cstunted - cmalnourished, time(policy) treat (concentration) covar(rural i.v106 i.v190 b4 v201 v012 v481 bord b4 b5 idxml age_months mstunted mwasted mmalnourished) replace savetex("table/nutritiond_dummydid1.tex") rowlabtype ("varlab") onerow

ieddtab facilitydelivery anc_visits, time( policy ) treat( concentration ) covar(rural i.v106 i.v190 b4 v012 v201 bord) replace savetex("./table/delivery_did1.tex") rowlabtype("varlab") onerow





