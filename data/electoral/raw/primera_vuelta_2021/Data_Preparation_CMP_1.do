
********************************************
* Preparation for merge with All_Elections *
********************************************

* Input is the prepared CMP file, prepared in R, with the various measures
* Data_Preparation_CMP is using the 2023 dataset

cap cd "C:\Users\charlott\Dropbox (Personal)\MA Masterarbeit\0Data\CMP"

use cmp_with_scores_2023.dta, clear

count //20

*==========================================*
* Create partyyear variable to merge with election data *
*==========================================*

_strip_labels party 

tostring party, replace

tostring year, replace

gen partyyear=party+"_"+year

distinct partyyear

gen green_dummy = green

*========*
* Save file *
*========*

cap cd "C:\Users\charlott\Dropbox (Personal)\MA Masterarbeit\0Data\CMP"

save CMP_Prepared.dta, replace

*--> now go to data_preparation_merge_CMP.do, line 103


*=============*
* Some checks *
*=============*

sum median_environment //between 0 and and 2.7, mean is 1.45, sd 0.58
//7 out of 1286 are missing! 

count if right==1 | green==1
count if right==0 | green==1

list partyname countryname year if globalist==1 & green==1
list partyname countryname year if globalist==0 & green==1

*==============================================*
* Simple Averages of Environmentalism over time*
*==============================================*


* Calculating the Average, i.e. one single line

* Mean
bysort year: egen mean_Environmentalism = mean(lowe_environment)

gen obs=_n
collapse obs, by (year mean_Environmentalism)
drop obs

* 3-years averages
gen year_3 = round(year/3, 1) * 3

bysort year_3 country: egen mean_Environmentalism = mean(lowe_environment)

gen obs=_n
collapse obs, by (year_3 country mean_Environmentalism)
drop obs

* 4-years averages
gen year_4 = round(year/4, 1) * 4

bysort year_4: egen mean_Environmentalism = mean(lowe_environment)

gen obs=_n
collapse obs, by (year_4 mean_Environmentalism)
drop obs

* 5-years averages
gen year_5 = round(year/5, 1) * 5

bysort year_5: egen mean_Environmentalism = mean(lowe_environment)

gen obs=_n
collapse obs, by (year_5 mean_Environmentalism)
drop obs


* Median 
bysort year: egen median_Environmentalism = median(lowe_environment)

gen obs=_n
collapse obs, by (year median_Environmentalism)
drop obs

* 3-years averages
gen year_3 = round(year/3, 1) * 3

bysort year_3: egen median_Environmentalism = median(lowe_environment)

gen obs=_n
collapse obs, by (year_3 median_Environmentalism)
drop obs


* 4-years averages
gen year_4 = round(year/4, 1) * 4

bysort year_4: egen median_Environmentalism = median(lowe_environment)

gen obs=_n
collapse obs, by (year_4 median_Environmentalism)
drop obs


* 5-years averages
gen year_5 = round(year/5, 1) * 5

bysort year_5: egen median_Environmentalism = median(lowe_environment)

gen obs=_n
collapse obs, by (year_5 median_Environmentalism)
drop obs


* Calculating average for every single country 

gen year_3 = round(year/3, 1) * 3

bysort year_3: egen Germany = mean(lowe_environment) if country == 41

gen obs=_n
collapse obs, by (year_3 country countryname mean_Environmentalism)
drop obs
