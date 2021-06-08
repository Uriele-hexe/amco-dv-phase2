/*{
    "Program": "hx_dv_summ_details_checks"
	"Descrizione": "Summarize violation",
	"Parametri": [
		    "dsDataChecked":"Dataset checked",
            "dsListChecks":"List of checks to be applied"
	],
	"Return": "Dataset containing result of checks. Its name is declared in global macro variable named histchecks",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Function needs to be execute by function. In addition to macro creates a temporary source in work" ]
}*/

%Macro hx_dv_summ_details_checks () / store secure Des = "Checks execution";
	%local _dttimeStamp _dsSummarizeCheck _checksVariable _dsHistPer _dschk
	   ;
  %Let dsDataChecked     = %sysfunc(dequote(&dsDataChecked.));
  %Let dsListChecks      = %sysfunc(dequote(&dsListChecks.));
  %Let _dsSummarizeCheck = work.&sysmacroname.;

  %Let _dttimeStamp  = %sysfunc(datetime());
  %Put +----[Macro: &sysmacroname.] --------------------------+;
  %Put | Execution of list checks                             |;
  %Put | Data table      : &dsDataChecked.                    |;
  %Put | Total violation : &histchecks.                       |;
  %Put | .................................................... |;
  %Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
  %Put +----[Macro: &sysmacroname.] --------------------------+;

  %*-- Create List of portfolio. Used to create matrix idrule -> portfolios;
  %*+-----------------------------------------------------+;
  %*| Extract _all_ portfolios necessary to create matrix  |;            
  %*+-----------------------------------------------------+;
  Proc Sql;
    Create Table _listOfPortfolios as  
      Select cod_portafoglio_gest 
             ,count(distinct idRecord) as nRecords
        From &dsDataChecked.
        Group by 1
		Outer Union Corresponding
		  Select cod_portafoglio_gest
		         ,. as nRecords
		  From datistg._ALL_RECONNECTION_TABLE
		  Group by 1
        ;

	 Create Table _listOfPortfolios as  
	  Select cod_portafoglio_gest 
             ,max(nrecords) as nRecords
		From _listOfPortfolios
		Group by 1
		;
  Quit;

  %*-- Create temporary data model based on histChecks;
  Proc Sql;
    Create Table &_dsSummarizeCheck. Like &histChecks.;
  Quit;
  %Let _checksVariable=;
  Proc Contents data=&_dsSummarizeCheck. noprint out=_dtmodel_ (Keep=NAME VARNUM);
  Run;
  Proc Sql NoPrint;
    Select cats('"',NAME,'"') into :_checksVariable separated by ',' from  _dtmodel_ order by varnum;
    Drop Table _dtmodel_;
  Quit;

  %*+---------------------------------------------+;
  %*| Create Matrix cod_portafoglio -> idRule     |;            
  %*+---------------------------------------------+;
  Data _null_;
    *-- Matrix will be produced in memory by through hash table object;
    %hx_cmn_attrib_from_ds (dsname=&_dsSummarizeCheck.);
    Declare hash htchecks(ordered:"yes");
      htchecks.defineKey("idTransaction","dataProvider","cod_ist","dta_reference","cod_portafoglio_gest"
                        ,"idAmbito","tableName","idRule","flagName");
      htchecks.defineData(&_checksVariable.);
      htchecks.defineDone();

/*
    *-- Declaration of a hash table from which to retrieve the total number of distinct keys ;
    %hx_cmn_attrib_from_ds(dsname=&_dsHistPer.);
    Declare hash htper (dataset:"&_dsHistPer.",ordered:"yes");
      htper.defineKey("cod_ist","dta_reference","stagingtable","cod_portafoglio_gest");
      htper.defineData("nrecord");
      htper.defineDone();
*/

    Retain idTransaction "&idTrasaction."  
           dta_reference "&dta_reference."d tableName "&dsDataChecked" timeStamp &_dttimeStamp.
           %if %symexist(cod_ist) %then %do;
             cod_ist &cod_ist.
           %end;
          ;
    stagingtable = Lowcase(Scan(tableName,2,'.'));
    nvarsTotal = hx_get_nvars(tableName);
    _dsport = Open("_listOfPortfolios");
    _dsrule = Open("&dsListChecks");
    Do While (Fetch(_dsport)=0);
      cod_portafoglio_gest = GetvarC(_dsport,Varnum(_dsport,"cod_portafoglio_gest"));
      nrecTotal            = GetvarN(_dsport,Varnum(_dsport,"nRecords"));
      *-- Ciclo on rule table;
      rc = rewind(_dsrule);
      Do While (Fetch(_dsrule)=0);
        dataProvider              = GetvarC(_dsrule,Varnum(_dsrule,"data_Provider"));
        idAmbito                   = GetvarC(_dsrule,Varnum(_dsrule,"id_Ambito"));
        idRule                     = GetvarC(_dsrule,Varnum(_dsrule,"idrule"));
        descr_rule                 = GetvarC(_dsrule,Varnum(_dsrule,"Descrizione_Controllo_per_Report"));
        flagName                   = GetvarC(_dsrule,Varnum(_dsrule,"flgName"));
        fx_name                    = GetvarC(_dsrule,Varnum(_dsrule,"Nome_Funzione"));
        Campi_Tecnici              = GetvarC(_dsrule,Varnum(_dsrule,"Campi_Tecnici"));
        Perimetro_di_applicabilita = GetvarC(_dsrule,Varnum(_dsrule,"PerimetroApplicabilita"));
        eseguito                   = GetvarC(_dsrule,Varnum(_dsrule,"isExecutable"));
        nota                       = GetvarC(_dsrule,Varnum(_dsrule,"noteExecutable"));
        nOccurs                    = ifn(eseguito='Y',0,.);
        rc = htchecks.add();
      End;
    End;

    _dsport = Close(_dsport);
    _dsrule = Close(_dsrule);
    rc      = htchecks.output(dataset:"&_dsSummarizeCheck.");
  Run;

  %*-- Count violation. These will be preserve inside matrix;
  Data _null_;
    Set &dsDataChecked. (Keep=idTransaction cod_istituto dta_riferimento cod_portafoglio_gest inPerim_:
                              flgIdRule_:
                         Rename=(cod_istituto=cod_ist dta_riferimento=dta_reference)) 
         end=fine;
	  If _N_=1 Then Do;
      %hx_cmn_attrib_from_ds (dsname=&_dsSummarizeCheck.);
      Declare hash htchecks(dataset:"&_dsSummarizeCheck.",ordered:"yes");
        htchecks.defineKey("cod_ist","dta_reference","cod_portafoglio_gest","idRule");
        htchecks.defineData(&_checksVariable.);
        htchecks.defineDone();
	  End;
    %*-- Calculate total violation;
    %Let _dschk = %Sysfunc(open(&dsListChecks. (Where=(isExecutable='Y'))));
    %Do %While (%Sysfunc(Fetch(&_dschk.))=0);
      %Let _idRule   = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,idRule))));
      %Let _flagName = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,flgName))));
      %Let _inPerim  = inPerim_%Sysfunc(prxchange(%bquote(s/[\.]/_/),-1,&_idRule.));

      controllo    = put(_idRule,$fmtcontrollo.);
      descr_ambito = put(_idRule,$ambito.);
      severity     = put(_idRule,severity.);
      Principio    = put(_idRule,$Principio.);
	  des_portafoglio_gest = put(cod_portafoglio_gest,$portafoglio.);

      idRule         = "&_idRule.";
      _nrecPerimeter = &_inPerim.;
      _nOccurs       = ifn(&_flagName.='Y',1,0);
      if htchecks.find(key:cod_ist,key:dta_reference,key:cod_portafoglio_gest,key:idRule)=0 then do;
        nrecPerimeter = sum(nrecPerimeter,_nrecPerimeter);
        nOccurs       = nOccurs+_nOccurs;
        rc            = htchecks.replace();
      end;
    %End;
    %Let _dschk = %Sysfunc(Close(&_dschk.));
	  If fine Then rc = htchecks.output(dataset:"&_dsSummarizeCheck.");
  Run;

  %*-- Historicize results ;
  Proc Sql;
    %*-- Dataset used to preserve run about single cod_ist;
    Delete From &histChecks.
      Where 1
      %if %symexist(cod_ist) %then %do;
        And cod_ist = &cod_ist.
      %end;
      And dta_reference = "&dta_reference."d
      And catx('-',idTransaction,dataProvider,cod_portafoglio_gest,idRule) In  
        (select catx('-',idTransaction,dataProvider,cod_portafoglio_gest,idRule) 
           from &_dsSummarizeCheck.
        )
      ;

    %*-- Dataset used in dashboard. Contains all cod_ist;
    Delete From &dsHistRepChecks.
      Where 1
      %if %symexist(cod_ist) %then %do;
        And cod_ist = &cod_ist.
      %end;
      And dta_reference = "&dta_reference."d
      And catx('-',dataProvider,cod_portafoglio_gest,idRule) In  
        (select catx('-',dataProvider,cod_portafoglio_gest,idRule) 
           from &_dsSummarizeCheck.
        )
      ;     
  Quit;
  Data &histChecks.;
    Set &histChecks. &_dsSummarizeCheck.;
  Run;
  Data &dsHistRepChecks. (Drop=_:);
    Set &dsHistRepChecks. &_dsSummarizeCheck.
	    ;
	If _N_=1 Then Do;
	  declare hash htp(dataset:"datistg.all_reconnection_table",ordered:"yes");
	    htp.defineKey("cod_portafoglio_gest");
		htp.defineData("des_portafoglio_gest");
		htp.defineDone();
	End;
	if cod_portafoglio_gest="_ALL_" Then des_portafoglio_gest = "PORTAFOGLIO TOTALE";
    else _rc = htp.find(key:cod_portafoglio_gest);
	ruleFlag = ifn(eseguito='Y',1,0);
  Run;

  %Uscita:
    %Let _dttimeStamp  = %sysfunc(datetime());
    %Put +----[Macro: &sysmacroname.] --------------------------+;
    %Put | Execution of list checks                             |;
    %Put | Data table      : &dsDataChecked.                    |;
    %Put | Total violation : &histchecks.                       |;
    %Put | .................................................... |;
    %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
    %Put +----[Macro: &sysmacroname.] --------------------------+;
%Mend;
/*
Option mprint;
%Let dsDataChecked     = work.DWH_COUNTERPARTIES;
%Let dsListChecks      = work.HX_RETRIEVE_CHECKS_APPLICABLE;
%hx_dv_summ_details_checks();
  */
