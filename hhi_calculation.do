* This script uses the number of facilities to calculate competition in subcounties.
* The subcounty shape file was obtained from: doi.org/10.6084/M9.FIGSHARE.12501455.V1
* The hospitals in 2015 was obtained from: https://open.africa/dataset/health-facilities-in-kenya
* The number of hospitals in 2020 was obtained from: https://open.africa/dataset/kenya-master-health-facility-list-2020


****
***Shp file to dta
****

cd //directory where the shape file is saved

shp2dta using Sub_County_Kenya.shp, data(subcounty) coord(sub_county_coord) genid(sub_id) replace
clear


****
***Cleaning subcounty map data
****

use data/subcounty.dta

*** Making names lower case
ren Sub_County subcounty
ren _all, lower
foreach var of varlist subcounty county {
	replace `var'=ustrlower(`var')
}


***Sort naming

*Baringo county
replace subcounty = "marigat" if subcounty == "baringo south" 
replace subcounty = "east pokot" if subcounty == "tiaty" 

*Garissa
replace subcounty = "garissa township" if subcounty == "dujis"

*Homa Bay
replace subcounty = "kabondo" if subcounty == "kabondo kasipul"
replace subcounty = "homa bay town" if subcounty == "homa bay"

*Kajiado
replace subcounty = "loitokitok" if subcounty == "kajiado south"

*Kericho
replace subcounty = "ainamoi" if subcounty == "kericho east" 
replace subcounty = "belgut" if subcounty == "kericho west" 
replace subcounty = "sigowet/soin" if subcounty == "sigowet" 
replace subcounty = "bureti" if subcounty == "buret"

*Kiambu
replace subcounty = "kiambu town" if subcounty == "kiambu" 

*Kitui
replace subcounty = "mwingi central" if subcounty == "mwingi east"

*Meru
replace subcounty = "imenti central" if subcounty == "central imenti" 
replace subcounty = "imenti north" if subcounty == "north imenti" 
replace subcounty = "imenti south" if subcounty == "south imenti" 

replace subcounty = "pokot north" if subcounty == "north pokot"
replace subcounty = "koibatek" if subcounty == "eldama ravine" 


save data/sub_county.dta, replace
clear


****
***Cleaning facility data
****

***2015 dataset
import excel data/ehealth-kenya-facilities-download-21102015.xls, firstrow


keep FacilityCode FacilityName Beds Cots County Division Constituency Location SubLocation
gen beds_cots_2015 = Beds + Cots
la var beds_cots "Total facility beds and cots in 2015"
drop Beds Cots
duplicates drop //none actually exist
ren FacilityCode code
ren _all, lower
ren constituency constituency_2015
foreach var of varlist county facilityname division constituency_2015 location sublocation {
	replace `var'=ustrlower(`var')
	replace `var' = rtrim(`var')
}

save data/facilities_beds_2015.dta, replace
clear

***2020 dataset
import delimited ./01_Raw/2020_hospital_beds.csv
keep code subcounty county constituency ward bedsandcots
duplicates drop
destring code,  force replace
ren _all, lower
ren constituency constituency_2020
ren bedsandcots beds_cots_2020
foreach var of varlist subcounty county constituency_2020 ward {
	replace `var'=ustrlower(`var')
	replace `var' = rtrim(`var')
}
replace county = "murang'a" if county == "muranga"


save data/facilities_beds_2020.dta, replace
clear


***Merge
merge m:1 code county using data/facilities_beds_2015.dta
drop if beds_cots_2020 == .| beds_cots_2020 == 0 & beds_cots_2015 == . | beds_cots_2015 == 0


***sort subcounties
*Baringo
replace subcounty = "east pokot" if subcounty == "tiaty east" /*east pokot */
replace subcounty = "marigat" if division == "marigat" /*marigat*/

*Bomet
drop if facilityname == "njerian dispensary" /*too high*/
replace subcounty = "konoin" if constituency_2015 == "konoin" /*konoin*/

*Bungoma
replace subcounty = "bumula" if constituency_2015 == "bumula" /*bumula*/
replace subcounty = "kanduyi" if constituency_2015 == "kanduyi" /*kanduyi*/
replace subcounty = "mt elgon" if subcounty == "cheptais"

*Busia
replace subcounty = "budalangi" if subcounty == "bunyala" /*bunyala*/
replace subcounty = "funyula" if subcounty == "samia" /*samia*/
replace subcounty = "butula" if constituency_2015 == "butula" /*butula*/
replace subcounty = "matayos" if division == "matayos" /*matayos*/
replace subcounty = "nambale" if division == "nambale" /*nambale */

*Embu
replace subcounty = "mbeere north" if constituency_2015 == "siakago"

*Garissa
replace subcounty = "garissa township" if constituency_2020 == "garissa township" /*garissa */
replace subcounty = "ijara" if subcounty == "hulugho" /*hulugho */
replace subcounty = "dadaab" if division == "dadaab"

*Homabay
replace subcounty = "kabondo" if subcounty == "kabondo kasipul"
replace subcounty = "kasipul" if subcounty == "rachuonyo south"
replace subcounty = "suba" if subcounty == "suba south"
replace subcounty = "kasipul" if division == "kasipul"
replace subcounty = "mbita" if constituency_2015 == "mbita"
replace subcounty = "rangwe" if division == "rangwe"

*Isiolo
replace subcounty = "isiolo" if division == "central" && county == "isiolo"

*Kajiado
replace division = "mashuru" if division == "mashuuru"
replace subcounty = "kajiado east" if division == "mashuru"
replace subcounty = "kajiado central" if location == "township" && county == "kajiado"
replace subcounty = "loitokitok" if constituency_2015 == "kajiado south"
replace subcounty = "kajiado east" if sublocation == "ongata rongai"
replace subcounty = "kajiado east" if division == "isinya"
replace subcounty = "kajiado north" if division == "ongata rongai"

*Kakamega
replace subcounty = "butere" if constituency_2015 == "butere"
replace subcounty = "ikolomani" if constituency_2015 == "ikolomani"
replace subcounty = "lugari" if division == "lugari"
replace subcounty = "navakholo" if division == "navakholo"
replace subcounty = "lurambi" if location == "butsotso central"
replace subcounty = "matungu" if constituency_2015 == "matungu"
replace subcounty = "mumias east" if division == "east wanga"
replace subcounty = "mumias west" if division == "south wanga"
replace subcounty = "shinyalu" if constituency_2015 == "shinyalu"

*Kericho
replace subcounty = "kipkelion east" if location == "chepkongony" | sublocation == "chesinende" 

*Kiambu
replace subcounty = "gatundu north" if constituency_2015 == "gatundu north"
replace subcounty = "gatundu south" if constituency_2015 == "gatundu south"
replace subcounty = "juja" if location == "toll"| location == "kibichiku"
replace subcounty = "ruiru" if location == "githurai" && county == "kiambu"
replace subcounty = "kikuyu" if location == "kikuyu"
replace subcounty = "kiambu town" if code == 19655/*st marks hospital */
replace subcounty = "limuru" if constituency_2015 == "limuru"

*Kilifi
replace subcounty = "kilifi" if constituency_2015 == "bahari"
replace subcounty = "kilifi" if subcounty == "kilifi north" | subcounty == "kilifi south"
replace subcounty = "magarini" if division == "magarini"
replace subcounty = "malindi" if sublocation == "shella"

*Kirinyaga 
replace subcounty = "kirinyaga central" if constituency_2015 == "kerugoya/kutus"
replace subcounty = "gichugu" if subcounty == "kirinyaga east" /*gichugu*/
replace subcounty = "mwea" if subcounty == "kirinyaga north/mwea west" | subcounty == "kirinyaga south" /*mwea*/
replace subcounty = "ndia" if subcounty == "kirinyaga west" /*ndia*/

*Kisii
replace subcounty = "bobasi" if constituency_2015 == "bobasi"
replace subcounty = "kitutu chache south" if constituency_2015 == "kitutu chache"

*Kisumu
replace subcounty = "kisumu central" if location == "manyatta b"

*Kwale
replace subcounty = "msambweni" if division == "diani"

*Laikipia
replace subcounty = "laikipia east" if division == "central" && county == "laikipia"
replace subcounty = "laikipia west" if division == "sipili" | location == "mutara"

*Lamu
replace subcounty = "matungulu" if division == "kyanzavi"

*Machakos
replace subcounty = "machakos town" if subcounty == "machakos" | subcounty == "kalama" /*machakos */
replace subcounty = "maara" if subcounty == "muthambi" | subcounty == "mwimbi"
replace subcounty = "kathiani" if division == "kathiani"
replace subcounty = "mavoko" if subcounty == "athi river" | division == "mlolongo" | division == "athi river" | division == "mavoko" | location == "katani" 
replace subcounty = "machakos town" if constituency_2015 == "machakos town"
replace subcounty = "masinga" if constituency_2015 == "masinga"
replace subcounty = "mwala" if constituency_2015 == "mwala"

*Makueni
replace subcounty = "kaiti" if constituency_2015 == "kaiti"
replace subcounty = "kibwezi west" if division == "mulala" | division == "makindu"
replace subcounty = "kibwezi east" if division == "mtito andei"
replace subcounty = "makueni" if division == "kathonzweni"
replace subcounty = "mbooni" if constituency_2015 == "mbooni"

*Mandera
replace subcounty = "lafey" if location == "bulla mpya"
replace subcounty = "mandera east" if division == "central" && county == "mandera"
replace subcounty = "laisamis" if constituency_2015 == "laisamis"

*Meru
replace subcounty = "meru south" if subcounty == "chuka" | subcounty == "igambangombe"
replace subcounty = "igembe north" if division == "mutuati"
replace subcounty = "buuri" if division == "buuri"

*Migori
replace subcounty = "kuria east" if division == "kegonga"
replace subcounty = "kuria east" if division == "ntimaru"
replace subcounty = "suna west" if location == "suna ragana" | location == "suna south" | location == "suna wasimbete"
replace subcounty = "suna east" if location == "suna central" | location == "suna rabuor"
replace subcounty = "nyatike" if constituency_2015 == "nyatike"
replace subcounty = "awendo" if division == "awendo"
replace subcounty = "uriri" if division == "uriri"

*Mombasa
replace subcounty = "jomvu" if location == "jomvu"
replace subcounty = "kisauni" if location == "bamburi"
replace subcounty = "kisauni" if code == 11434/*jocham */
replace subcounty = "mvita" if constituency_2015 == "mvita"

*Murang'a
replace county = "murang'a" if constituency_2015 == "gatanga"
replace subcounty = "gatanga" if constituency_2015 == "gatanga"
replace subcounty  = "murang'a south" if subcounty == "muranga south"/*murang'a south */
replace subcounty = "kandara" if constituency_2015 == "kandara"
replace subcounty = "kiharu" if constituency_2015 == "kiharu"
replace subcounty = "kahuro" if division == "kahuro" /*kahuro */
replace subcounty = "kahuro" if ward == "wangu" /*wangu*/

*Nairobi
replace subcounty = "dagoretti north" if sublocation == "gatina"
replace subcounty = "dagoretti south" if sublocation == "kawangware" | code == 13212 | location == "riruta" /*st judes health centre" */
replace subcounty = "embakasi central" if constituency_2015 == "embakasi central"
replace subcounty = "embakasi east" if division == "embakasi east" | location == "utawala" | sublocation == "embakasi village" | code == 19455 /*communal oriented services intl*/
replace subcounty = "embakasi east" if location == "embakasi" && sublocation == "embakasi"
replace subcounty = "embakasi south" if location == "mukuru"
replace sublocation = "mukuru kwa njenga" if sublocation == "mukuru kwa njega"
replace location = "mukuru kwa njenga" if location == "mukuru kwanjega"
replace subcounty = "embakasi south" if sublocation == "mukuru kwa njenga"
replace subcounty = "embakasi east" if location == "savannah" | sublocation == "savannah" | sublocation == "tassia"
replace subcounty = "embakasi west" if division == "umoja" && location == "umoja" && constituency_2015 == "embakasi west"
replace subcounty = "langata" if constituency_2020 == "langata"
replace subcounty = "kamukunji" if constituency_2015 == "kamukunji"
replace subcounty = "kasarani" if sublocation == "dandora  41"
replace subcounty = "kibra" if code == 21083 /*kibera ubuntu afya medical centre */
replace subcounty = "makadara" if location == "viwandani"
replace subcounty = "mathare" if constituency_2015 == "mathare"
replace subcounty = "roysambu" if location == "githurai" && county == "nairobi"
replace subcounty = "ruaraka" if division == "ruaraka"
replace subcounty = "starehe" if division == "ngara"
replace subcounty = "westlands" if constituency_2015 == "westlands"

*Nakuru
replace subcounty = "bahati" if subcounty == "nakuru north"
replace subcounty = "nakuru town east" if subcounty == "nakuru east" /*nakuru east */
replace subcounty = "nakuru town west" if subcounty == "nakuru west" /*nakuru west */
replace division = "elementaita" if division == "elementeita"
replace subcounty = "gilgil" if division == "elementaita"
replace subcounty = "naivasha" if sublocation == "olkaria"
replace subcounty = "naivasha" if location == "naivasha east"
replace subcounty = "nakuru town east" if location == "lanet"
replace subcounty = "nakuru town west" if location == "kaptembwo"
replace subcounty = "bahati" if division == "kiamaina"
replace subcounty = "subukia" if division == "subukia"

*Narok
replace subcounty = "emurua dikirr" if subcounty == "transmara east" /*transmara east */
replace subcounty = "kilgoris" if subcounty == "transmara west" /*transmara west*/
replace subcounty = "kilgoris" if division == "kilgoris" | division == "angata"
replace subcounty = "narok east" if location == "suswa" | location == "enoosupukia"


*Nyamira
replace subcounty = "masaba north" if division == "rigoma" && constituency_2015 == "kitutu masaba"
replace subcounty = "masaba north" if division == "gesima"
replace location = "magombo" if location == "mogombo"
replace subcounty = "manga" if location == "magombo" | division == "kemera"
replace subcounty = "borabu" if division == "nyansiongo"
replace subcounty = "nyamira north" if code == 20290 | code == 20293 /*nyabonge, kemuchungu */
replace subcounty = "nyamira" if constituency_2015 == "west mugirango"
replace subcounty = "manga" if constituency_2015 == "west mugirango" && constituency_2020 == "kitutu masaba"

*Nyandarua
replace subcounty = "ol kalou" if subcounty == "olkalou" /*ol kalou */
replace subcounty = "ol jorok" if subcounty == "oljoroorok"/*ol jorok */
replace subcounty = "kinangop" if constituency_2015 == "kinangop"

*Nyeri
replace subcounty = "nyeri town" if subcounty == "nyeri central"
replace subcounty = "othaya" if subcounty == "nyeri south"

*Samburu
replace subcounty = "samburu east" if constituency_2015 == "samburu east"

*Siaya
replace subcounty = "bondo" if division == "nyang'oma" | division == "usigu"
replace sublocation = "bar kowino" if sublocation == "barkowino" 
replace subcounty = "bondo" if sublocation == "bar kowino"
replace subcounty = "ugunja" if code == 18093 /*our lady of perpetual sisters vct */

*Taita Taveta
replace subcounty = "mwatate" if constituency_2015 == "mwatate"

*Trans Nzoia
replace subcounty = "kiminini" if constituency_2015 == "saboti" && sublocation == "milimani"

*Turkana
replace subcounty = "turkana north" if subcounty == "kibish"
replace subcounty = "turkana central" if constituency_2015 == "turkana central"

*Uasin Gishu
replace subcounty = "moiben" if division == "moiben"
replace subcounty = "turbo" if location == "kibulgeng"
replace subcounty = "kesses" if sublocation == "pioneer"

*Vihiga
replace subcounty = "emuhaya" if division == "elukongo" | location == "central bunyore"
replace subcounty = "luanda" if code == 16451 /*makutano medical clinic */
replace subcounty = "hamisi" if constituency_2015 == "hamisi"

*Wajir
replace subcounty = "wajir east" if division == "central" && county == "wajir"


drop constituency* ward division location sublocation _merge

save data/merged_facilities.dta, replace
clear

****
***Calculating Herfindahl-Hirchsmann Index
****

use .data/merged_facilities.dta

//drop if missing(beds_cots_2015)
sort subcounty
by subcounty: egen sum_beds_2015 = total(beds_cots_2015)
la var sum_beds_2015 "sum of beds in subcounty in 2015"
gen facility_hhi_2015 = ((beds_cots_2015/sum_beds_2015)^ 2) 
la var facility_hhi_2015 "market share of facility in 2015"
by subcounty: egen sum_hhi_2015 = total(facility_hhi_2015)
la var sum_hhi_2015 "hhi of subcounty in 2015"
//replace concentration_2015 = . if subcounty == "mathioya" /*mathioya has no beds or cots */

by subcounty: egen sum_beds_2020 = total(beds_cots_2020)
la var sum_beds_2020 "sum of beds in subcounty in 2020"
gen facility_hhi_2020 = ((beds_cots_2020/sum_beds_2020)^ 2) 
la var facility_hhi_2020 "market share of facility in 2020"
by subcounty: egen sum_hhi_2020 = total(facility_hhi_2020)


save data/hhi.dta, replace
clear


****
*** Calculating subcounty HHI
****

use .data/hhi.dta

by subcounty, sort: keep if _n == 1
drop code facilityname beds_cots* facility_hhi*
foreach var of varlist subcounty_hhi*{
	replace `var' = . if `var' == 0
}

*HHI of county
sort county
by county: egen county_beds_2015 = total(sum_beds_2015)
la var county_beds_2015 "sum of beds in county in 2015"
gen subcounty_ms_2015 = ((sum_beds_2015/county_beds_2015)^ 2) 
la var subcounty_ms_2015 "market share of subcounty in county in 2015 squared"
by county: egen county_hhi_2015 = total(subcounty_ms_2015)
la var county_hhi_2015 "hhi of county in 2015"
by county: egen county_beds_2020 = total(sum_beds_2020)
la var county_beds_2020 "sum of beds in county in 2020"
gen subcounty_ms_2020 = ((sum_beds_2020/county_beds_2020)^ 2) 
la var subcounty_ms_2020 "market share of subcounty in county in 2020 squared"
by county: egen county_hhi_2020 = total(subcounty_ms_2020)
la var county_hhi_2020 "hhi of county in 2020"


*Location quotient
gen lq_2015 = subcounty_hhi_2015/county_hhi_2015
la var lq_2015 "location quotient in 2015"
gen lq_2020 = subcounty_hhi_2020/county_hhi_2020
la var lq_2020 "location quotient in 2020"


*Concentration
gen concentration_2015 = cond(lq_2015 < 1, 1, 0, .)
la var concentration_2015 "treatment effect"
label define conclbl 1 "competitive" 0 "concentrated"
label values concentration_2015 conclbl
gen concentration_2020 = cond(lq_2020 < 1, 1, 0, .)
la var concentration_2020 "concentration in 2020"
label values concentration_2020 conclbl

save ./03_temp/subcountylq.dta, replace



****
***Subcounty mapped to hhi
****


use .data/sub_county.dta
 

*Merge with  database
merge 1:m subcounty using .data/subcountyhhi.dta
drop _merge
la var sub_id "subcounty id"
replace sum_hhi_2015 = 0 if subcounty == "mathioya"
replace sum_hhi_2020 = 0 if subcounty == "mathioya"
replace concentration_2015 = 0 if subcounty == "mathioya"
replace concentration_2020 = 0 if subcounty == "mathioya"

save .data/subcountymap.dta, replace

*Drawing kdensity plot
//twoway kdensity sum_hhi_2015 || kdensity sum_hhi_2020, xline(0.25)

*Plotting Maps
spmap sum_hhi_2015 using data/sub_county_coord, id(sub_id) clmethod(custom) clbreaks(0 0.25 1) fcolor(Reds) title ("HHI Index of subcounty") //map using 0.25 as cutoff
spmap lq_2015 using .data/sub_county_coord, id(sub_id) clnumber(10) fcolor(Blues2) legenda(off) title("location quotient of subcounties")
