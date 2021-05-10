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

Proc Fcmp outlib=hx_func.cmn_dv_function.package encrypt;
  function fx_retrieve_first_array_value(a_values $) $;
    Length a_string $255
           n_elemn  8
        ;
    Call Missing(a_string);   
    _a_values = prxchange('s/\[|\]|\"//',-1,a_values);
    n_elemn   = count(_a_values,',')+1;
    Do _e=1 To n_elemn;
      if not missing(scan(_a_values,_e,',')) then 
        a_string = catx(',',a_string,scan(_a_values,_e,','));
    End;
  return (a_string);
  endsub;
Run;