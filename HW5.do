* I will not comment on commands that have already been used and explained in another command.
* So mostly each command will only be commented once.

**************
* Question 1 *
**************
clear all
cd "/Users/changjay/Desktop/貿易理論/HW5"
use "main_for_trade_theory_class"
gen d_import_usch_1991_2007 = 100 / 16 * (real_imports_usch_2007 - real_imports_usch_1991) / real_market1991 // creat delta_IPJ
gsort - d_import_usch_1991_2007 // gsort - means sort in descending value
* Waterproff outerwear, Printing trades machinery, Women's footwear, except athletic, Games, toys, and children's vehicles, and Luggage are the 5 most exposed industries to China shock.
graph twoway (scatter dl_cbp_emp_1991_2007 d_import_usch_1991_2007) (lfit dl_cbp_emp_1991_2007 d_import_usch_1991_2007)
* lfit means to draw the fitted value line
graph twoway (scatter dl_cbp_emp_1991_2007 d_import_usch_1991_2007 [aw = cbp_emp1991]) (lfit dl_cbp_emp_1991_2007 d_import_usch_1991_2007)
* [aw = cbp_emp1991] means to weight the scatterplot on employment in 1991.

**************
* Question 2 *
**************
clear all
cd "/Users/changjay/Desktop/貿易理論/HW5"
use "main_for_trade_theory_class"
* First we need to make industry-level shock in the using data. (smae as in Question 1)
gen d_import_usch_1991_2007 = 100 / 16 * (real_imports_usch_2007 - real_imports_usch_1991) / real_market1991 // creat delta_IPJ
reg dl_cbp_emp_1991_2007 d_import_usch_1991_2007 sector* ind_ci_1990 ind_htsh1_1990 ind_lnavgw_1991 d_ind_lnavgw_7691 ind_prodwemp_1991 ind_capvadd_1991 d_ind_shemp_7691, robust
* sector* creates 9 dummies for sectors (one of them will be automatically omitted)
reg dl_cbp_emp_1991_2007 d_import_usch_1991_2007 sector* ind_ci_1990 ind_htsh1_1990 ind_lnavgw_1991 d_ind_lnavgw_7691 ind_prodwemp_1991 ind_capvadd_1991 d_ind_shemp_7691 nber_real_wage2007, robust
* nber_real_wage2007 is not a good control since it makes the variable of interest(delta_IPJ) statistically insignificant.
* Though R^2 does increase, it does not mean the regression with nber_real_wage2007 controlled a better model.

****************
* Question 3-1 *
****************
* STEP 1
cd "/Users/changjay/Desktop/貿易理論/HW5/czone_analysis_dta/emp_counts"
clear all
use "cbp_czone_merged.dta"
keep if year == 1991 | year == 1999 | year == 2007
* keep data in 1991, 1999, and 2007. The code in the beamer only kept data in year 1991 and 2007. However, we need data in 1999 to run regressions in Question3-2 so I also keep 1991 data.
gen mfgemp = emp if sic87dd >= 2000 & sic87dd <= 3999 // create variable of emp in manufacturing industries
collapse (sum) mfgemp (sum) totemp = emp, by(year czone) // sum emp and mfgemp that uniquely defined by year and zone
reshape wide mfgemp totemp, i(czone) j(year) // reshape data to wide with j = year, which makes year define column names
order czone totemp1991 mfgemp1991 totemp1999 mfgemp1999 totemp2007 mfgemp2007 // order data with assigned order
save "/Users/changjay/Desktop/貿易理論/HW5/temp/empcounts.dta", replace

* STEP 2
clear all
cd "/Users/changjay/Desktop/貿易理論/HW5/czone_analysis_dta/pop"
use "czone_pop_1990_2012.dta"
keep if year == 1991 | year == 1999 | year == 2007 // keep data in 1991, 1999, or 2007
rename totpop pop
reshape wide pop workagepop, i(czone) j(year) // reshape data to wide with j = year, which makes year define column names
order czone pop* workagepop* // order data with assigned order, * after variable names is equivalent to adding every year after the variable name
save "/Users/changjay/Desktop/貿易理論/HW5/temp/popest.dta", replace

* STEP 3
clear all
cd "/Users/changjay/Desktop/貿易理論/HW5/temp"
use "empcounts.dta"
merge 1:1 czone using "popest.dta", assert(3) nogenerate
* assert(3) means to check whether all observations are matched in both master and using. nogenerate means not to create the _merge variable.
merge 1:1 czone using "shock_czone.dta", assert(3) nogenerate keepusing(*1991_1999 *1999_2007 *1991_2007)
* keepusing() means to keep only some specific variables from using. In fact, in this command all variables are kept.
merge 1:1 czone using "cw_czone_region.dta", assert(2 3) keep(3) keepusing(region)
save "/Users/changjay/Desktop/貿易理論/HW5/temp/final_3.dta", replace // Save this for convenience in Question 3-2
* assert(2 3) means to check whether all observations are matched in both master and using or at least matched from master.
* keep(3) means only to keep observations that are matched both in master and using.

* STEP 4
gen mfgsh1991 = mfgemp1991 / totemp1991 // create manufacturing employment share in 1991, this is a control in the following regressions
foreach y in 1991 2007 {
gen emppop_`y' = 100 * (totemp`y' / workagepop`y')
} // creat employment rate in 1991 and 2007. We use foreach command to run simple loop in STATA.

foreach t in "1991_2007" {
local start = substr("`t'", 1, 4) // creat a substring start from 1 with length of 4
local end = substr("`t'", 6, 4) // creat a substring start from 6 with length of 4
gen d_emppop_`t' = (emppop_`end' - emppop_`start') / (`end' - `start')
} // create difference in employment rate between 1991 and 2007

* This is another way to create difference in employment rate between 1991 and 2007. In fact, if we want only few data of difference, this is more intuituive.
gen d_emppop_1991_2007_another = (emppop_2007 - emppop_1991) / (2007 - 1991)
assert d_emppop_1991_2007 == d_emppop_1991_2007_another // I use assert x == y to check my way to create difference is correct.

* STEP 5
foreach t in "1991_2007" {
reg d_emppop_`t' shock_us_`t' mfgsh1991 i.region [aw = pop1991], robust
}

****************
* Question 3-2 *
****************
cd "/Users/changjay/Desktop/貿易理論/HW5/temp"
clear all
use "final_3.dta" // Since we save the file above, now I can simply start from STEP 4.

* STEP 4
gen mfgsh1991 = mfgemp1991 / totemp1991
foreach y in 1991 1999 2007 {
gen emppop_`y' = 100 * (totemp`y' / workagepop`y')
} // creat employment rate in 1991, 1999, and 2007. We use foreach command to run simple loop in STATA.

foreach t in "1991_2007" "1991_1999" "1999_2007" {
local start = substr("`t'", 1, 4) // creat a substring start from 1 with length of 4
local end = substr("`t'", 6, 4) // creat a substring start from 6 with length of 4
gen d_emppop_`t' = (emppop_`end' - emppop_`start') / (`end' - `start')
} // create difference in employment rate with respect to three different time intervals

* STEP 5
foreach t in "1991_2007" "1991_1999" "1999_2007"{
reg d_emppop_`t' shock_us_`t' mfgsh1991 i.region [aw = pop1991], robust
}

* I made another version of the regression in 1999_2007 by using mfgsh1999 as control and pop1999 as weight
gen mfgsh1999 = mfgemp1999 / totemp1999 // create manufacturing employment share in 1999, this is an alternative control the following regression
reg d_emppop_1999_2007 shock_us_1999_2007 mfgsh1999 i.region [aw = pop1999], robust

* Main Results
* 1991_2007: -0.2342063 
* 1991_1999: 0.0808246 
* 1999_2007: -0.1586397 / another version: -0.5521582

**************
* Question 4 *
**************
cd "/Users/changjay/Desktop/貿易理論/HW5"
clear all
use "main_for_trade_theory_class.dta"

* First we need to make industry-level shock in the using data. (smae as in Question 1)
gen d_import_usch_1991_2007 = 100 / 16 * (real_imports_usch_2007 - real_imports_usch_1991) / real_market1991 // creat delta_IPJ
* upstrem shock included
reg dl_cbp_emp_1991_2007 d_up_usch_1991_2007 sector* ind_ci_1990 ind_htsh1_1990 ind_lnavgw_1991 d_ind_lnavgw_7691 ind_prodwemp_1991 ind_capvadd_1991 d_ind_shemp_7691 [aw = cbp_emp1991], robust
* downstream shock included
reg dl_cbp_emp_1991_2007 d_down_usch_1991_2007 sector* ind_ci_1990 ind_htsh1_1990 ind_lnavgw_1991 d_ind_lnavgw_7691 ind_prodwemp_1991 ind_capvadd_1991 d_ind_shemp_7691 [aw = cbp_emp1991], robust
* both upstream and downstream shock included
reg dl_cbp_emp_1991_2007 d_up_usch_1991_2007 d_down_usch_1991_2007 d_import_usch_1991_2007 sector* ind_ci_1990 ind_htsh1_1990 ind_lnavgw_1991 d_ind_lnavgw_7691 ind_prodwemp_1991 ind_capvadd_1991 d_ind_shemp_7691 [aw = cbp_emp1991], robust

**************
* Question 5 *
**************
* First we need to make industry-level shock(delta_IPJ) in the using data. (smae as in Question 1)
cd "/Users/changjay/Desktop/貿易理論/HW5"
clear all
use "main_for_trade_theory_class.dta"
gen d_import_usch_1991_2007 = 100 / 16 * (real_imports_usch_2007 - real_imports_usch_1991) / real_market1991 // creat delta_IPJ
save "/Users/changjay/Desktop/貿易理論/HW5/main_for_trade_theory_class_IPJ.dta", replace // save the delta_IPJ variable for using in the following merge

* Then we use the worker data and merge it with shock data.
clear all
use "worker_data.dta"
rename sic87dd_employer_1991 sic87dd // rename for the following merge (to make it consistent with the using data)
merge m:1 sic87dd using "main_for_trade_theory_class_IPJ.dta", assert(2 3) keep(3) nogenerate keepusing(d_import_usch_1991_2007)
* merge m:1 since there are multiple workers with the same sic87dd in master datafile. We only keep the delta_IPJ variable from using.
gen d_wage_1991_2007 = wage2007 - wage1991 // create dependent variable
reg d_wage_1991_2007 d_import_usch_1991_2007 age gender, robust
* China shock negatively affected wage since it made the wage difference between 1991 and 2007 smaller.

**************
* Question 6 *
**************
* This part can easily continue from Question 5, so we don't clear the data out.
reg d_wage_1991_2007 d_import_usch_1991_2007 age c.d_import_usch_1991_2007#c.age, robust // c.x#c.y means to make the interaction term of x and y, which are both continuous variables.
reg d_wage_1991_2007 d_import_usch_1991_2007 gender c.d_import_usch_1991_2007#i.gender, robust // c.x#i.y means to make the interaction term of x and y. Y is a disvrete indicator.

* The following is another way to make regressions with interaction terms, which is to simply create interaction variables on our own.
gen d_import_usch_1991_2007_age = d_import_usch_1991_2007 * age
gen d_import_usch_1991_2007_gender = d_import_usch_1991_2007 * gender
reg d_wage_1991_2007 d_import_usch_1991_2007 age d_import_usch_1991_2007_age, robust
reg d_wage_1991_2007 d_import_usch_1991_2007 gender d_import_usch_1991_2007_gender, robust








