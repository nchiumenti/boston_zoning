
drop if cousub_name=="COUNTY SUBDIVISIONS NOT DEFINED"

// replace cousub_name = subinstr(cousub_name," TOWN","",.)

* Remove 'TOWN' and 'CITY' from end of string
replace cousub_name = regexr(cousub_name,"( TOWN| CITY)+","")

* Replace all 'BOROUGH' with 'BORO' suffix
replace cousub_name = regexr(cousub_name, "(BOROUGH)$","BORO")

* Rename 'MT WASHINGTON'->'MOUNT WASHINGTON'; 'MANCHESTER-BY-THE-SEA'->'MANCHESTER'
replace cousub_name = "MOUNT WASHINGTON" if cousub_name=="MT WASHINGTON"

replace cousub_name = "MANCHESTER" if cousub_name=="MANCHESTER-BY-THE-SEA"

isid cousub_name
