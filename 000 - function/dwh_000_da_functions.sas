/*{
    "Program": "dwh_000_da_functions.sas"
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

Proc Fcmp outlib=hx_func.da_functions.package encrypt;
  function fx_check_dwh_datamodel() $;
    Attrib fx_return Length=$40;
	*-- Macro creates table named hx_retrieve_checks_applicable;
    rc = run_macro("hx_check_dwh_datamodel");
	fx_return = "ERROR IN MACRO";
	If exist("work.hx_check_dwh_datamodel") Then Do;
	  fx_return = "PASSED";
	  _dsid = open("work.hx_check_dwh_datamodel (Where=(isInTechnical='Y' Or isInPerimeter='Y'))");
	  fx_return = ifc(fetch(_dsid)=0,"ALERT",fx_return);
	  _dsid = close(_dsid);
	  If fx_return = "PASSED" Then Do;
	    _dsid = open("work.hx_check_dwh_datamodel (Where=(dwhFieldNew='D' Or (dwhFieldNew='N' And dmFieldSameT='N')))");
	    fx_return = ifc(fetch(_dsid)=0,"WARNING",fx_return);
	    _dsid = close(_dsid);
	  End;
	End;
	return (fx_return);
  endsub;

  /* Call macros used to import source data */
  function fx_da_import_sourcedata (datiodd $) $;
    Attrib fx_return Length=$40;
	*-- Macro creates table named hx_retrieve_checks_applicable;
	macroname = "hx_dv_import_sourcedata";
    rc        = run_macro(macroname,datiodd);
	fx_return = "ERROR IN MACRO";
	If exist(catx('.',"work",macroname)) Then Do;
	  fx_return = "PASSED";
	  _dsid = open(catx(' ',catx('.',"work",macroname),"(Where=(dtaCreate<timeStamp))"));
	  fx_return = ifc(fetch(_dsid)=0,"ALERT",fx_return);
	  _dsid = close(_dsid);
	  fx_return = catx(' ',fx_return,'[',macroname,']');
	End;
	return (fx_return);
  endsub;

  function fx_da_mapping_sourcedata (datiwip $, dataimported $) $;
    Attrib fx_return Length=$40;
	*-- Macro creates table named hx_retrieve_checks_applicable;
	macroname = "hx_dv_mapping_sourcedata";
    rc        = run_macro(macroname,datiwip,dataimported);
	fx_return = "ERROR IN MACRO";
	If exist(catx('.',"work",macroname)) Then Do;
	  fx_return = "PASSED";
	  _dsid = open(catx(' ',catx('.',"work",macroname),"(Where=(dtaCreate<timeStamp))"));
	  fx_return = ifc(fetch(_dsid)=0,"ALERT",fx_return);
	  _dsid = close(_dsid);
	  fx_return = catx(' ',fx_return,'[',macroname,']');
	End;
	return (fx_return);
  endsub;

Run; 