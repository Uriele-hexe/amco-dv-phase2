/*{
    "Program": "hx_dt_impact_dm_on_lkp"
	"Descrizione": "Retrieve impacts of DWH data model changement on lookup rules",
	"Parametri": [
		  "datichk.DWH_DM_PRELIMNARY_CHECKS":"Output of program named dwh_005_data_acquisition_check_model.sas",
		  "meta_dslkp_name":"Metadata describe lookup rules"
		         ]
	],
	"Return": {"Physical dataset (preserve in datichk) named same macro name, containing deleted lookup rules",
	           "Update metadata lookup"
			   },
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
}*/

%Macro hx_dt_impact_dm_on_lkp() / store secure des="Retrieve impact on lookup rules";
  %local _dttimeStamp _dsOutCheckDM _dsLookupRules _dsHistchangeRule
	   ;
  %Let _dsOutCheckDM  = datichk.%UnQuote(&dataProvider.)_DM_PRELIMNARY_CHECKS;
  %Let _dsLookupRules = %sysfunc(dequote(&meta_dslkp_name.));

  %Let _dttimeStamp  = %sysfunc(datetime());
  %Put +----[Macro: &sysmacroname.] -----------------------------------+;
  %Put | Retrieve impacts of DWH data model changement on lookup rules |;
  %Put | ............................................................. |;
  %Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
  %Put +----[Macro: &sysmacroname.] -----------------------------------+;

  %If %sysfunc(exist(&_dsOutCheckDM.))=0 %Then %Do;
    %log(level = E, msg = Dataset named &_dsOutCheckDM not exists! It should be created by dwh_005_data_acquisition_check_model.sas);
    %log(level = E, msg = Data transformation engine was stopped !!);
    %goto uscita;
  %End;

  %*-- STEP 1: Transpose DS lookup;
  Data _null_; 
    Attrib colDeleted  Length=$80  label="Name of column deleted "
	       dwhSasTable Length=$80  label="Name of dataset SAS"
	       Idlookup   Length=$255 label="Id. Lookup"
	       whereIs    Length=$80  label="Where is impact?"
		;
	Length _whereClause $255;

    Declare hash ht(ordered:"yes",multidata:"yes");
	  ht.defineKey("Idlookup","colDeleted","dwhSasTable");
	  ht.defineData("Idlookup","colDeleted","dwhSasTable","whereIs");
	  ht.defineDone();

	dslkp = Open("&_dsLookupRules.");
	_whereClause = "dwhFieldNew='D'";
	%if %symexist(dta_reference) %then %do;
      _whereClause = catx(' ',_whereClause,"And",cats('dta_riferimento="',symget("dta_reference"),'"d'));
	%end;

	%if %symexist(cod_ist) %then %do;
	  _whereClause = catx(' ',_whereClause,'and cod_istituto=',symget("cod_ist"));
	%end;
	Put _whereClause=;
	Do While(Fetch(dslkp)=0);
	  Idlookup    = GetvarC(dslkp,Varnum(dslkp,"Id_lookup")); 
	  SourceTable = GetvarC(dslkp,Varnum(dslkp,"Source_Table")); 
	  SourceKey   = GetvarC(dslkp,Varnum(dslkp,"Source_Key")); 
	  Sourcewcls  = GetvarC(dslkp,Varnum(dslkp,"Source_Where_Clause")); 
	  TargetTable = GetvarC(dslkp,Varnum(dslkp,"Target_Table")); 
	  TargetKey   = GetvarC(dslkp,Varnum(dslkp,"Target_Key")); 
	  Targetwcls  = GetvarC(dslkp,Varnum(dslkp,"Target_Where_Clause")); 
	  Targetout   = GetvarC(dslkp,Varnum(dslkp,"Target_Out_Values")); 
	  dsimp = Open(catx(' ',"&_dsOutCheckDM.","(Where=(",_whereClause,"))"));
	  Do While (Fetch(dsimp)=0);
	    colDeleted  = GetvarC(dsimp,Varnum(dsimp,"targetColumn"));
		dwhSasTable = GetvarC(dsimp,Varnum(dsimp,"dwhSasTable"));
		If prxmatch(cats('/',dwhSasTable,"/i"),SourceTable)>0 or
  	      prxmatch(cats('/',dwhSasTable,"/i"),TargetTable)>0 Then Do;
		  *-- Look deleted field inside sourceKey;
		  Call Missing(whereIs);
		  If prxmatch(cats('/',colDeleted,"/i"),SourceKey)>0 Then Do;
		    whereIs="sourcekey";
			ht.add();
		  End;
		  If prxmatch(cats('/',colDeleted,"/i"),Sourcewcls)>0 Then Do;
		    whereIs="sourcewhere";
			ht.add();
		  End;
		  If prxmatch(cats('/',colDeleted,"/i"),TargetKey)>0 Then Do;
		    whereIs="targetKey";
			ht.add();
		  End;
		  If prxmatch(cats('/',colDeleted,"/i"),Targetwcls)>0 Then Do;
		    whereIs="targetwcls";
			ht.add();
		  End;
		  If prxmatch(cats('/',colDeleted,"/i"),Targetout)>0 Then Do;
		    whereIs="targetoutfields";
			ht.add();
		  End;
		End;
	  End;
      dsimp = close(dsimp);
	end;
	dslkp = Close(dslkp);
    ht.output(dataset:"work.&sysmacroname.");
  Run;

  %*-- Update metadata lookup;
  %If %sysfunc(hx_get_nobs(work.&sysmacroname.))>0 %Then %Do;
    Data &_dsLookupRules. (Drop=_: idlookup colDeleted whereIs); 
	      Set &_dsLookupRules. 
	          work.&sysmacroname. (obs=0 keep=idlookup colDeleted whereIs)
	   ;
	  Attrib _string _stringNew Length=$1000
		;
      If _N_=1 Then Do;
	    Declare hash ht(dataset:"work.&sysmacroname.",ordered:"yes",multidata:"yes");
		  ht.defineKey("idLookup");
		  ht.defineData("colDeleted","whereIs");
		  ht.defineDone();
	  End;
	  Call Missing(colDeleted,whereIs);
	  _flgIdLkp = ifc(ht.find(key:Id_lookup)=0,'Y','N');
	  Do While (_flgIdLkp='Y');
	    If whereIs="sourcekey" Then Do;
          _posInString = prxmatch(cats('/',colDeleted,"/i"),Source_Key);
		  _string      = strip(Source_Key);
		  Link deleteField;
		  Source_Key = _string;
		End;
	    Else If whereIs="sourcewhere" Then Do;
          _posInString = prxmatch(cats('/',colDeleted,"/i"),Source_Where_Clause);
		  _string      = strip(Source_Where_Clause);
		  Link deleteField;
		  Source_Where_Clause = _string;
		End;
	    Else If whereIs="targetKey" Then Do;
          _posInString = prxmatch(cats('/',colDeleted,"/i"),Target_Key);
		  _string      = strip(Target_Key);
		  Link deleteField;
		  Target_Key = _string;
		End;
	    Else If whereIs="targetwcls" Then Do;
          _posInString = prxmatch(cats('/',colDeleted,"/i"),Target_Where_Clause);
		  _string      = strip(Target_Where_Clause);
		  Link deleteField;
		  Target_Where_Clause = _string;
		End;
	    Else If whereIs="targetoutfields" Then Do;
          _posInString = prxmatch(cats('/',colDeleted,"/i"),Target_Out_Values);
		  _string      = strip(Target_Out_Values);
		  Link deleteField;
		  Target_Out_Values = _string;
		End;
	    Call Missing(colDeleted,whereIs);
	    _flgIdLkp = ifc(ht.find_next(key:Id_lookup)=0,'Y','N');
	  End;
	  Return;

	  DELETEFIELD:
	    Call Missing(_stringNew);
        _rc  = ifn(missing(_string),0,count(_string,'-')+1);
		_sep = "   ";
		Do _i=1 To _rc;
		  if strip(lowcase(scan(_string,_i,'-'))) ^= strip(lowcase(colDeleted)) then do;
		    _stringNew = strip(_stringNew)||_sep||strip(scan(_string,_i,'-'));
			_sep       = " - ";
		   Put "STEP 0: " _i= id_Lookup= colDeleted= _string= _stringNew= _rc=;
		  end;
		End;
		Note = "Sono stati eliminati i campi";
		_string = Strip(_stringNew);
		Put "STEP 1: " id_Lookup= colDeleted= _string= _stringNew= _rc=;
	  RETURN;
	Run;

    %*-- Historicize results;
    %Let _dsHistchangeRule = datichk.%UnQuote(&dataProvider.)_%UnQuote(&sysmacroname.);
    Data &_dsHistchangeRule.;
      Attrib idTransaction Length=$25 Label="Id. transaction"
	         dta_reference    Length=8   Label="Reference date" format=ddmmyy10.
		     cod_istituto     Length=8   Label="Istitute" 
		     timeStamp        Length=8   Label="Timestamp" format=datetime.
		     idRecord         Length=8   Label="Id. record"
	    ;
		Set
      %if %sysfunc(exist(&_dsHistchangeRule.)) %then %do;
	    &_dsHistchangeRule. (in=hist)
	  %end;
	    work.&sysmacroname. (in=tmp)
	    ;
      idRecord = _N_;
   	  if tmp then do;
	    idTransaction = "&idTrasaction.";
	    dta_reference = "&dta_reference."d;
	    %if %symexist(cod_ist) %then %do;
	      cod_istituto = &cod_ist.;
	    %end;
	    timeStamp = &_dttimeStamp.;
	  end;
    Run;
  %End;	

  %*-- Update Process Trace;
  Data _null_;
    %hx_declare_ht_pr(htTable=&processTrace.);
    sourceCode = "Data Transformation";
    stepCode   = "Impact analysis following any changes in the DWH data model";
    if hx_get_nobs("work.&sysmacroname.")>0 Then Do;
      msgCode    = "Some idRule was impcated by changement on DWH data model. See &_dsHistchangeRule. for details";
      rcCode     = -20030;
    end;
    else do;
      msgCode    = "No rule was changed";
      rcCode     = 1;
    End;
    rc = ht.add();
    rc = ht.output(dataset:"&processTrace.");
  Run;

  %Uscita:
    %Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] -----------------------------------+;
	%Put | Retrieve impacts of DWH data model changement on lookup rules |;
	%Put | ............................................................. |;
	%Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] -----------------------------------+;
%Mend;
%*hx_dt_impact_dm_on_lkp();