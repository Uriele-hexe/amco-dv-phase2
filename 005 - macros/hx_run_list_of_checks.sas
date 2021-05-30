/*{
    "Program": "hx_run_list_of_checks"
	"Descrizione": "Run list of checks can be exdcuted",
	"Parametri": [
		    "dsListChecks":"Contains name dataset in output at macro hx_retrieve_checks_applicable",
        "dsTarget":"Data on which apply checks"
        "checkLibOut":"Name of libname will preserve checks's results"
	],
	"Return": "dataset named: <checkLibOut>.<name of target>",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Function needs to be execute by function. In addition to macro creates a temporary source in work" ]
}*/

%Macro hx_run_list_of_checks () / store secure Des = "Checks execution";
	%local _dttimeStamp _dschk _checksData
	   ;
  /*%Let dsHistChecks = %sysfunc(dequote(&dsHistChecks.));
  %Let dsMetaChecks = %sysfunc(dequote(&dsMetaChecks.));
  %Let dsListPortf  = datistg.ALL_RECONNECTION_TABLE;*/
  %Let dsTarget     = %sysfunc(dequote(&dsTarget.));
  %Let checkLibOut  = %sysfunc(dequote(&checkLibOut.));
  %Let dsListChecks = %sysfunc(dequote(&dsListChecks.));

	%Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] --------------------------+;
	%Put | Execution of list checks                             |;
	%Put | Data table     : &dsTarget.                          |;
	%Put | Output library : &checkLibOut.                       |;
	%Put | .................................................... |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] --------------------------+;

  %Let _checksData = %UnQuote(&checkLibOut.).&dsTarget.;
  %If %sysfunc(count(&dsTarget.,.))>0 %Then %Do;
    %Let _checksData = %UnQuote(&checkLibOut.).%Qscan(&dsTarget.,2,%NrQuote(.));
  %End;
  
  %If %Sysfunc(exist(&dsTarget.))=0 %Then %Do;
   %log(level=E, msg=&dsTarget. not exist !!);
   %Goto uscita;
  %End;

  Proc Sort data=&dsTarget. out=&_checksData.;
    By idRecord;
  Run;
  %Let _dschk = %Sysfunc(Open(&dsListChecks. (Where=(isExecutable='Y'))));
  Data &_checksData.; Set &_checksData.;
    By idRecord;
    %*-- Write statment attrib;
    %Do %While (%Sysfunc(Fetch(&_dschk.))=0);
      %Let _idRule      = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,idRule))));
      %Let _flgName     = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,flgName))));
      %Let _inPerimName = inPerim_%UnQuote(%replace_spec_chars(&_idRule.));
      Attrib &_flgName. Length=$1 Label="Flag rule: &_idRule";
      Attrib &_inPerimName. Length=8 Label="In perimeter 0/1";
    %End;
    %*-- Write statment to call function;
    %Let rc = %Sysfunc(Rewind(&_dschk.));    
    %Do %While (%Sysfunc(Fetch(&_dschk.))=0);
      %Let _idRule      = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,idRule))));
      %Let _flgName     = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,flgName))));
      %Let _perimetro   = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,PerimetroApplicabilita))));
      %Let _inPerimName = inPerim_%UnQuote(%replace_spec_chars(&_idRule.));
      %Let _fxName      = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,Nome_Funzione))));
      %Let _tc          = %Sysfunc(GetvarC(&_dschk.,%Sysfunc(Varnum(&_dschk.,Campi_Tecnici))));
      %Let _tc          = %sysfunc(prxchange(%bquote(s/[\-]/,/), -1, %bquote(&_tc.)));
      &_inPerimName.=0;
      %If "&_perimetro." ne "_null_" %Then %Do;
        %UnQuote(&_perimetro.) Then Do;
          &_inPerimName.= 1;
          &_flgName.    = %UnQuote(&_fxName.)(&_tc.);
        End;
      %End;
	    %Else %Do;
	      if first.idRecord Then &_inPerimName.=1;
      %End;
	  %End;
  Run;
  %Let _dschk = %Sysfunc(Close(&_dschk.));

  %Uscita:
    %Let _dttimeStamp  = %sysfunc(datetime());
    %Put +----[Macro: &sysmacroname.] --------------------------+;
    %Put | Execution of list checks                             |;
    %Put | Data table     : &dsTarget.                          |;
    %Put | Output library : &checkLibOut.                       |;
    %Put | .................................................... |;
    %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
    %Put +----[Macro: &sysmacroname.] --------------------------+;
%Mend;

/*
Option mprint;
 %Let dsTarget     = datistg.DWH_COUNTERPARTIES;
 %Let checkLibOut  = work;
 %Let dsListChecks = work.HX_RETRIEVE_CHECKS_APPLICABLE ;
 %hx_run_list_of_checks();
*/