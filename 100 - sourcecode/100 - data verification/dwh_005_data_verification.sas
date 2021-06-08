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

*-- Option cmplib = (hx_func.dv_functions) mprint source2;
%Macro hx_dwh_run_check_lists(idAmbito=_ALL_,dsTarget=_NULL_)
           / Des="Apply checks rules"; 
	%Local _tmpStamp _wclsClause _phase _libcheck
			;

    %Let _libcheck=datichk;
	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ----------------------+;
	%Put | Apply checks rules regarding &idAmbito.         |;
	%Put | Target Table	      : &dsTarget.	     	       |;
	%Put | Libname of details : &_libcheck.	     		   |;
	%Put |.................................................|;
	%Put | Started at: &_tmpStamp.;
	%Put +-------------------------------------------------+;

    %*-- Run function used to retrieve list of rules can be applied;   
	%Let _phase = Extract Check can be applied; 
	%*-- Creates dataset work.HX_RETRIEVE_CHECKS_APPLICABLE containing list of rule to be executed;
    %Let fx_retrieve = %sysfunc(fx_retrieve_checks(&idAmbito., &dsTarget., &dsDwhMetaChecks.));
    %Put &=fx_retrieve;
    %*-- Historicize list of checks can be applied;
    Proc Sql;
  	  %if %sysfunc(exist(&histCtchecks.)) %then %do;
       Delete From &histCtchecks. 
	     Where dta_reference = "&dta_reference."d 
	           %if %symexist(cod_ist) %then %do;
	  		     And cod_ist = &cod_ist.
	 		   %end;
			   And idRule In (Select idRule From work.HX_RETRIEVE_CHECKS_APPLICABLE)
			   ;
	  %end;
	  %else %do;
	    Create Table &histCtchecks. Like HX_RETRIEVE_CHECKS_APPLICABLE;
	  %end;
	Quit;
	Proc Contents data=&histCtchecks. out=_dmmodel_ (Keep=NAME) noprint;
	Run;
	%Let _campiHist=;
	Proc Sql noPrint;
	  Select NAME Into :_campiHist separated by ' ' from _dmmodel_;
	  Drop Table _dmmodel_;
	Quit;
	%Let _tmpStamp = %sysfunc(datetime());
    Data &histCtchecks.(Keep=&_campiHist.) ;
	  Attrib dta_reference Length=8 Label="Data Reference" format=ddmmyy10.
           %if %symexist(cod_ist) %then %do;
			 cod_ist Length=8 Label="Codice Istituto"
		    %end;
		;
     Set &histCtchecks. 
         work.HX_RETRIEVE_CHECKS_APPLICABLE (in=tmp);
	  If tmp then do;
	    idTransaction = "&idTrasaction.";
		dataProvider  = "&dataProvider";
	    timeStamp = &_tmpStamp.;
	    dta_reference = "&dta_reference."d;
		%if %symexist(cod_ist) %then %do;
		  cod_ist = &cod_ist.;
		%end;
	  end;
	Run;

    %*-- Run Check;
	%if &fx_retrieve.=Y %then %do;
  	  %Let _phase = Run checks can be applied;
	  %Let fx_retrieve = %sysfunc(fx_run_list_of_checks(&dsTarget.,"&_libcheck.", "work.HX_RETRIEVE_CHECKS_APPLICABLE"));
	  %Put &=fx_retrieve;
	  %Let _dsToBeCheck = %NrQuote(&_libcheck..%Qscan(&dsTarget.,2,%NrQuote(.)));
	  %Let fx_retrieve = %sysfunc(fx_dv_summ_details_checks("&_dsToBeCheck.","work.HX_RETRIEVE_CHECKS_APPLICABLE"));
	%end;
    /****** AGGIUNGERE IL RICHIAMO DEI FORMAT PER COMPILARE LE INFORMAZIONI PIU DESCRITTIVE  ***/

    %*-- Update process trace;
    Data _null_;
	  %hx_declare_ht_pr(htTable=&processTrace.);
	  sourceCode = "Data Verification";
	  stepCode   = "&_phase. [&fx_retrieve.]";
	  msgCode    = "Run data verification about idAmbito [&idAmbito.] on dataset [&dsTarget.]";
      rcCode     = Ifn("&fx_retrieve." =: "PASSED" Or "&fx_retrieve." =: "Y" ,1,-30000);
	  rc = ht.add();
	  rc = ht.output(dataset:"&processTrace.");
	Run;

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ----------------------+;
	%Put | Apply checks rules regarding &idAmbito.         |;
	%Put | Target Table	: &dsTarget.	     			   |;
	%Put |.................................................|;
	%Put | Ended at: &_tmpStamp.;
	%Put +-------------------------------------------------+;
%Mend;
/*
%hx_dwh_run_check_lists(idAmbito=A,dsTarget=datistg.DWH_COUNTERPARTIES);
%hx_dwh_run_check_lists(idAmbito=F,dsTarget=datistg.DWH_FIDI);
%hx_dwh_run_check_lists(idAmbito=G,dsTarget=datistg.DWH_GARANZIE);

*-- Regola I.10.1;
%hx_dwh_run_check_lists(idAmbito=I,dsTarget=datistg.DWH_PERIZIE_LOTTI);
Proc Sort data=work.HX_DV_SUMM_DETAILS_CHECKS (Where=(idRule="I.10.1" And Not missing(nRecPerimeter) And not missing(nOccurs))) out=_checkImm2;
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;
%hx_dwh_run_check_lists(idAmbito=I,dsTarget=datistg.DWH_IMMOBILI_PERIZIE_CTP);
Proc Sort data=work.HX_DV_SUMM_DETAILS_CHECKS (Where=(Not missing(nRecPerimeter) And not missing(nOccurs))) out=_checkImm1;
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;
Proc Sort data=&dsHistRepChecks.;
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;
Data &dsHistRepChecks.; Merge &dsHistRepChecks. 
                              _checkImm1 (Drop=des_portafoglio_gest) 
                              _checkImm2 (Drop=des_portafoglio_gest);
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;

%hx_dwh_run_check_lists(idAmbito=L,dsTarget=datistg.DWH_LOTTI);
%hx_dwh_run_check_lists(idAmbito=P,dsTarget=datistg.DWH_PERIZIE);
%hx_dwh_run_check_lists(idAmbito=PE,dsTarget=datistg.DWH_PEGNI);
%hx_dwh_run_check_lists(idAmbito=R,dsTarget=datistg.DWH_RAPPORTI);
%hx_dwh_run_check_lists(idAmbito=GC,dsTarget=datistg.DWH_COLLATERAL);

*--------------------------------------------------------*
*  PER LE ASTE SONO DUE LE TABELLE SOGGETTE A CONTROLLO  *
*--------------------------------------------------------*
;
%hx_dwh_run_check_lists(idAmbito=AS,dsTarget=datistg.DWH_IMMOBILI_ASTE);
Proc Sort data=work.HX_DV_SUMM_DETAILS_CHECKS (Where=(Not missing(nRecPerimeter) And not missing(nOccurs))) out=_checksAste1;
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;
%hx_dwh_run_check_lists(idAmbito=AS,dsTarget=datistg.DWH_ASTE);
Proc Sort data=work.HX_DV_SUMM_DETAILS_CHECKS (Where=(Not missing(nRecPerimeter) And not missing(nOccurs))) out=_checksAste2;
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;
Proc Sort data=&dsHistRepChecks.;
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;
Data &dsHistRepChecks.; Merge &dsHistRepChecks. 
                              _checksAste1 (Drop=des_portafoglio_gest) 
                              _checksAste2 (Drop=des_portafoglio_gest) ;
  By dataProvider cod_ist dta_reference cod_portafoglio_gest idRule;
Run;
*--------------------------------------------------------*
*  PER LE ASTE SONO DUE LE TABELLE SOGGETTE A CONTROLLO  *
*--------------------------------------------------------*
;
                
*/

