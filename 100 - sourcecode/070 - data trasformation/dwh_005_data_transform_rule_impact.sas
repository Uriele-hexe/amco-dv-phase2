/*{
    "Program": "dwh_005_data_trasformation_rule_impact.sas"
	"Descrizione": "Impact analisys on lookup rules following changes on DWH data model",
	"Parametri": [
	],
	"Return": ["Update metadata lookup",
	           "Process trace"
			   ]
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
}*/

*-- Option cmplib = (hx_func.da_functions) mprint source2;
%Macro hx_dwh_check_lookup() / Des="Check on lookup rules";
	%Local _tmpStamp _rcCode _dsTemp 
			;

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] -------------------------+;
	%Put | Impact analisys on lookup rules following changes  |;
    %Put | on DWH data model                                  |;
	%Put |....................................................|;
	%Put | Started at: &_tmpStamp.                            |;
	%Put +----------------------------------------------------+;

    %*-- Call function that import DWH Table;
    %Let _rcCode = %sysfunc(fx_dt_impact_dm_on_lkp ());
    %Put &=_rcCode;

    %Uscita:
	  %Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	  %Put +---[Macro: &sysmacroname.] -------------------------+;
	  %Put | Impact analisys on lookup rules following changes  |;
      %Put | on DWH data model                                  |;
	  %Put |....................................................|;
	  %Put | Started at: &_tmpStamp.                            |;
	  %Put +----------------------------------------------------+;
%Mend;
%hx_dwh_check_lookup();






