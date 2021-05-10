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

%Macro hx_create_temp_sum_checks (dsListChecks=_NULL_
                                  ,dsTarget=_NULL_
                                  ,checkLibOut = work
                                  )
				/ Des = "Checks execution";
/*%Macro hx_create_temp_sum_checks ()	
     / Des = "Create a temporary table about output of checks";                */
	%local _dttimeStamp _dsid _checksData
	   ;

	%Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] --------------------------+;
	%Put | Execution of list checks                             |;
	%Put | Data table : &dsTarget.                           |;
	%Put | .................................................... |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] --------------------------+;

/*
    %Let dsHistChecks = %sysfunc(dequote(&dsHistChecks.));
    %Let dsMetaChecks =  %sysfunc(dequote(&dsMetaChecks.));
    %Let dsListPortf  = datistg.ALL_RECONNECTION_TABLE;
    */
    %Let _checksData = %UnQuote(&checkLibOut.).&dsTarget.;
    %If %sysfunc(count(&dsTarget.,.))>0 %Then %Do;
      %Let _checksData = %UnQuote(&checkLibOut.).%Qscan(&dsTarget.,2,%NrQuote(.));
    %End;

    %*-- Write temporary code [Start];
    Data _null_;
      Attrib _stmtRunChecks Length=$255
             flagName       Length=$40
             perimName      Length=$40
                 ;
      rc   = filename("tmpcode","work.dv_verification.apply_list_checks.source","catalog");
      _fid = fopen("tmpcode",'o');
      _dsrule = Open("&dsListChecks. (Where=(isExecutable='Y'))");
      Do While (Fetch(_dsrule)=0);
        idRule        = Getvarc(_dsrule,varnum(_dsrule,"idRule"));
        fx_name       = Getvarc(_dsRule,Varnum(_dsRule,"Nome_Funzione"));
        campi_tecnici = translate(Getvarc(_dsRule,Varnum(_dsRule,"Campi_Tecnici")),',','-');
        perimetro     = translate(Getvarc(_dsRule,Varnum(_dsRule,"Perimetro_di_applicabilita")),' ','#');
        flagName      = catx('_',"flgidRule",translate(idRule,'_','.'));
        perimName     = catx('_',"inperim",translate(idRule,'_','.'));
     
        *-- Produce Attrib Statment;
        rc = fput(_fid,"Attrib");
        rc = fput(_fid,catx(' ',flagName,"Length=$1","Label='Flag for idRule",idRule,"passed Y/N"));
        rc = fwrite(_fid);
        rc = fput(_fid,catx(' ',perimName,"Length=8","Label='Perimeter for",idRule,"is applicable 1/0"));
        rc = fput(_fid,';');
        rc = fwrite(_fid);
        rc = fput(_fid,catx(' ',perimName,"=0;"));
        If not missing(perimetro) Then rc = fput(_fid,catx(' ',"If",compbl(perimetro),"Then Do;"));
        rc = fput(_fid,catx(' ',perimName,"=1;"));
        rc = fwrite(_fid);
        rc = fput(_fid,cats(flagName,'=',fx_name,'(',campi_tecnici,");"));
        rc = fwrite(_fid);
        If not missing(perimetro) Then Do;
          rc = fput(_fid,'Do;');
          rc = fwrite(_fid);
        End;
      End;
      _dsrule = Close(_dsrule);
      _fid    = fclose(_fid);
    Run;
    %*-- Write temporary code [End];
  



    %Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] --------------------------+;
	%Put | Execution of list checks                             |;
	%Put | Data table : &dsTarget.                           |;
	%Put | .................................................... |;
	%Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] --------------------------+;
%Mend;
