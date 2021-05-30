/*{
    "Program": "dwh_005_dv_functions.sas"
	"Descrizione": "Define all functions regarding data verification engine",
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
}*/

Proc Fcmp outlib=hx_func.dv_functions.prelimnary_checks encrypt;
  function fx_retrieve_checks(idAmbito $, dsTarget $, dsListChecks $) $;
    Attrib fx_return Length=$1;
	*-- Macro creates table named hx_retrieve_checks_applicable;
    rc = run_macro("hx_retrieve_checks_applicable",idAmbito,dsTarget,dsListChecks);
	fx_return = 'N';
	If exist("work.hx_retrieve_checks_applicable") Then Do;
	  _dsid = open("work.hx_retrieve_checks_applicable");
	  Do While (fetch(_dsid)=0 And fx_return='N');
	    fx_return = ifc(GetvarC(_dsid,Varnum(_dsid,"isExecutable"))='Y','Y','N');
	  End;
	  _dsid = close(_dsid);
	End;
	return (fx_return);
  endsub;
Run; 

Proc Fcmp outlib=hx_func.dv_functions.apply_checks encrypt;
  function fx_run_list_of_checks (dsTarget $, checkLibOut $, dsListChecks $) $;
    Attrib fx_return Length=$50
	       dsDatiodd Length=$40
		   crdte     Length=8
	  ;
	*-- Macro creates table named hx_retrieve_checks_applicable;
	macroName = "hx_run_list_of_checks";
    rc = run_macro(macroName,dsTarget,checkLibOut,dsListChecks);
	dsDatiodd = catx('.',checkLibOut,scan(dsTarget,2,'.'));
	crdte = hx_get_crdte(dsDatiodd);
	fx_return = ifc(crdte<=datetime() and not missing(crdte)
	                     ,catx(' ',"RUN CHECK:",dsDatiodd)
						 ,"CHECK WAS NOT EXECUTED"
	               );
	return (fx_return);
  endsub;

  function fx_create_templ_checks(dsHistChecks $, dsMetaChecks $) $;
    Attrib fx_return Length=$1;
    rc = run_macro("hx_create_temp_sum_checks",dsHistChecks,dsMetaChecks);
	fx_return = 'N';
	fx_return = ifc(exist("work.hx_create_temp_sum_checks"),'Y','N');
	return (fx_return);
  endsub;

  function fx_dv_summ_details_checks(dsDataChecked $, dsListChecks $) $;
    Attrib fx_return Length=$1;
	runMacroName = "hx_dv_summ_details_checks";
    rc = run_macro(runMacroName,dsDataChecked,dsListChecks);
	fx_return = 'N';
	fx_return = ifc(datepart(hx_get_crdte("&histChecks."))=date(),"PASSED","NO RUN");
	return (fx_return);
  endsub;
  
Run; 
