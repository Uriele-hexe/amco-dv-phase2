/*{
    "Program": "cmn_dv_functions.sas"
	"Descrizione": "Define all functions regarding data acquisition engine",
	"Parametri": [
		"hx_func":"Libname containing functions"
	],
	"Return": [
	   "dataset named : ",
	   ],
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
	"Note":"All parameters used in macro was declared in global macro variable"
}*/

Proc Fcmp outlib=Hx_func.dt_functions.package encrypt;
  function fx_dt_impact_dm_on_lkp() $;
    Length rc_function $40
        ;
    _macroName = "hx_dt_impact_dm_on_lkp";
    Call Missing(rc_function);   
    rc = run_macro(_macroName);
    rc_function = ifc(hx_get_nobs(catx('.',"work",_macroName))>0,"CAUTION","PASSED");
    rc_function =cats(,rc_function,': [',_macroName,']');
  return (rc_function);
  endsub;
Run;