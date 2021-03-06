cap ssc install spmap
/* 
This do-file is for mapping data at the state-level.

It is separated into 3 parts

1. locals for path and file names
2. data to be mapped
3. mapping the data

Technically, if you put the locals in right, 
you should only have to edit one line.

*/
**************************************************
******************** PART 1 ***********************
**************************************************
/*
The following locals need to be assigned for this to run

DIRECTORIES
logdir - where you want the logfile to be saved
datadir - where your data is
mapdir - where you put state_map.dta and statecoor.dta (in zip file)
finishedmap - where you want the map saved to

DATASETS
dataname

VARIABLES
mapvar - which variable we want to map
statevar - what the variable is named in your data the identifies state fips code

MAPNAME
mapname - what the name of the map should be

MAP OPTIONS
clmethod - how you want the cutoffs for shading of 
	the maps to be determined; if left blank, default for spmap is assumed.
	if "custom", then must also fill out clcuts; 
	This is done just before the spmap command, otherwise STATA can't handle it
clcuts - If clmethod == custom, which cutoffs do you want to use? 
	Default is to assign them in the 
	following bins: 
	min - 25th pctile, 25th-50th pctile, 50th-75th pctile, 75th-max
mapcolor - what color you want the map to be shaded in. The default is Blues
	(help spmap##color for full list)
ndfcolor - what color you want for states w/ no data; default is white
	(help colorstyle for full list)
*/

*DIRECTORIES
local logdir ""
local datadir ""
local mapdir ""
local finishedmap ""

*DATASETS
local dataname "" 

*VARIABLES
local mapvar
local statevar

*MAP OPTIONS
local mapname ""
local clmethod "custom"
local clcuts "25 50 75"
local mapcolor Blues
local ndfcolor white

set more off

cap log close
log using "`logdir'\state_maps_creation.log", replace

**************************************************
******************** PART 2 ***********************
**************************************************

use  "`datadir'/`dataname'.dta", clear

destring `statevar', replace force 

**************************************************
*******EDIT THIS SECTION TO CREATE VARIABLE*********
**************************************************


****************************
*COLLAPSING SO ONLY ONE OBSERVATION PER STATE
****************************
collapse (first) `mapvar', by(`statevar')

keep `mapvar' `statevar'
sort `statevar'
tempfile mergefile
save `mergefile', replace

**************************************************
******************** PART 3 ***********************
**************************************************

use "`mapdir'/state_map.dta", clear

destring STATE_FIPS, gen(`statevar') force

sort `statevar'
merge `statevar' using `mergefile'

tab _merge /*should be all 3s*/


drop if `statevar' == 2 | `statevar' == 15 /*eliminating for HI, AK */

if "`clmethod'" == "custom" { 
	sum `mapvar', d
	local pmin = r(min)
	local pmax = r(max)
	foreach perc in `clcuts' {
		local p`perc' = round(r(p`perc'),0.01)
		di "`p`perc''" 
		local breaks "`breaks' `p`perc''"
	}
	local cloption "clmethod(custom) clbreaks(`pmin' `breaks' `pmax')"
} 

spmap `mapvar' using "`mapdir'/statecoor.dta", id(id) fcolor(`mapcolor') `clmethod' saving("`finishedmap'/`mapname'.gph", replace)

log close 
