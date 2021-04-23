/*{
    "Program": "dwh_005_data_verification"
	"Descrizione": "Run checks for all entity",
	"Parametri": [
	],
	"Return": "dataset named: work.hx_retrieve_checks_applicable containing list of checks executable",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
}*/

Option cmplib = (hx_func.dv_functions) mprint source2;
%Macro hx_dwh_run_check_lists(idAmbito=_ALL_,dsTarget=_NULL_)
           / Des="Apply checks rules";
	%Local _tmpStamp _wclsClause
			;

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ----------------------+;
	%Put | Apply checks rules regarding &idAmbito.         |;
	%Put | Target Table	: &dsTarget.	     			   |;
	%Put |.................................................|;
	%Put | Started at: &_tmpStamp.;
	%Put +-------------------------------------------------+;

    %*-- Declare function used to retrieve list of rules can be applied;    
    %Let fx_retrieve = %sysfunc(fx_retrieve_checks(&idAmbito., &dsTarget., &dsDwhMetaChecks.));
    
	%*-- Create temporary table used to preserve results of checks;
	%Let fx_tempdata =  %sysfunc(fx_create_templ_checks(&histchecks.,hx_retrieve_checks_applicable));

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ----------------------+;
	%Put | Apply checks rules regarding &idAmbito.         |;
	%Put | Target Table	: &dsTarget.	     			   |;
	%Put |.................................................|;
	%Put | Ended at: &_tmpStamp.;
	%Put +-------------------------------------------------+;
%Mend;
%hx_dwh_run_check_lists(idAmbito=_ALL_,dsTarget=datistg.DWH_COUNTERPARTIES);