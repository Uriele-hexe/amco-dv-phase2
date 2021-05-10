/*{
    "Program": "hx_retrieve_checks_applicable"
	"Descrizione": "Retrieve how many of data quality's checks are applicable",
	"Parametri": [
		"idAmbito":"Can be null"
		"dsTarget":"Data which needs to be checked"
		"dsListChecks":"Dataset containg list of checks"
	],
	"Return": "dataset named: work.hx_retrieve_checks_applicable containing list of checks executable",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Function needs to be exexute by function" ]
}*/

/*%Macro hx_run_checks_list(idAmbito=_ALL_,dsTarget=_NULL_,dsListChecks=_NULL_)
           / Des="Retrieve list of controls can be applied";*/

%Macro hx_retrieve_checks_applicable() / Des="Retrieve list of controls can be applied";
	%Local _tmpStamp _wclsClause
			;
    %Let idAmbito     = %sysfunc(dequote(&idAmbito.));
    %Let dsTarget     = %sysfunc(dequote(&dsTarget.));
    %Let dsListChecks = %sysfunc(dequote(&dsListChecks.));

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ----------------------+;
	%Put | Retrieve list of controls can be applied        |;
	%Put | idAmbito	: &idAmbito.	     			       |;
	%Put | Metadata	: &dsListChecks.				       |;
	%Put |.................................................|;
	%Put | Started at: &_tmpStamp.;
	%Put +-------------------------------------------------+;

	%If %sysfunc(exist(&dsListChecks.))=0 %Then %Do;
 	  %log(level = E, msg = &dsListChecks. not exists);
 	  %log(level = E, msg = Data verification engine was stopped !!);
    %return;
	%End;

	%*-- Compone  where clause used to filter metadata;
    %Let _wclsClause = %NrQuote(Not missing%(Data_Rilascio%) And Year%(Data_Rilascio%) < 2999);
	%If %symexist(dta_reference) %Then %Do;
		%Let _wclsClause=%NrQuote(Not missing%(Data_Rilascio%) And Data_Rilascio <= "&dta_reference."d And %(Data_Validita_From <= "&dta_reference."d And Data_validita_To >= "&dta_reference."d%));
	%End;
    %If "%Upcase(&idAmbito.)" ne "_ALL_" %Then %Do;
	  %Let _wclsClause=%NrQuote(&_wclsClause. And id_Ambito="&idAmbito.");
    %End;

    %If %symexist(dataProvider) %Then %Do;
	  %Let _wclsClause=%NrQuote(&_wclsClause. And Upcase%(data_provider%)=Upcase%("&dataProvider."%));
    %End;
    
    %*-- Add reference date;
	%Put &=_wclsClause;
    %*-- If the same rule exists for both CMN and Provider, the next datastep only keeps the one of the provider;
	Proc Sql;
		Create Table _metaCheckRueles As
			Select monotonic() as _idRecordRule
                   ,*
			  From &dsListChecks.
			Where &_wclsClause.
		Order By data_provider,id_Ambito,idRule
			;
	Quit;
	%If &sqlObs.<=0 %Then %Do;
	  %log(level = E, msg = &dsListChecks. no records for &_wclsClause.);
      %log(level = E, msg = Data verification engine was stopped !!);
      %Return;
	%End;

    Data _null_;
      Attrib targetTable Length = $80 Label = "Target Table"
             idCampo     Length = 8   Label = "Id varname"
             nomeCampo   Length = $80 Label = "Varname"
        ;
      Declare hash ht();
        ht.defineKey("targetTable","idCampo"); 
        ht.defineData("targetTable","idCampo","nomeCampo"); 
        ht.defineDone();

      *-- STEP 1 : Extract data model;
      targetTable = "&dsTarget.";
      If exist(targetTable) Then Do;
        _dsid = Open(targetTable);
        Do idCampo=1 To Attrn(_dsid,"NVARS");
          nomeCampo = varname(_dsid,idCampo);
          ht.add();
        End;
        _dsid = close(_dsid);
      End;
      ht.output(dataset:"work.targetDataModel");
      *-- STEP 2 : Retrieve how many checks are applicable;
      Attrib _idRecordRule   Length=8     Label="Primary key of checks"
             listOfPerimeter Length=$5000 Label="List of fields shared with function's perimeter"
             listOfCT        Length=$5000 Label="List of field shared with function's technical fields"
             isExecutable    Length=$1    Label="Flag executable funcion Y/N"
             noteExecutable  Length=$5000 Label="Applicability notes"
        ;
      Declare hash htc();
        htc.defineKey("_idRecordRule");
        htc.defineData("_idRecordRule","listOfPerimeter","listOfCT","isExecutable","noteExecutable");
        htc.defineDone();

      _dsf      = Open("work.targetDataModel");
      _dschecks = Open("_metaCheckRueles");
      Do While(fetch(_dschecks)=0);
        _idRecordRule = GetvarN(_dschecks,Varnum(_dschecks,"_idRecordRule"));
        _perimeter    = GetvarC(_dschecks,Varnum(_dschecks,"Perimetro_di_applicabilita"));
        _tecfields    = GetvarC(_dschecks,Varnum(_dschecks,"Campi_Tecnici"));
        _manApplicab  = GetvarC(_dschecks,Varnum(_dschecks,"Applicabilita_Controllo"));

        Call missing(listOfPerimeter,listOfCT,isExecutable,noteExecutable);
        rc = rewind(_dsf);
        *-- Check applicablity;
        Do While(Fetch(_dsf)=0);
          nomeCampo = GetvarC(_dsf,varnum(_dsf,"nomeCampo"));
          if prxmatch(cats('/',nomeCampo,"/i"),_perimeter)>0 then
            listOfPerimeter = catx('-',listOfPerimeter,nomeCampo);

          if prxmatch(cats('/',nomeCampo,"/i"),_tecfields)>0 then 
            listOfCT = catx('-',listOfCT,nomeCampo);
        End;
        %*-- Update flag executable;
        isExecutable = 'Y';

        *-- Check how many fields are included in perimeter;
        If not missing(_perimeter) Then Do;
          *--  Count how many fields are repoterd into _perimeter. 
               Each field needs to be closed among the hashtag symbol
                 ;
          _numFinPerim = count(_perimeter,'#')/2;
          If _numFinPerim ^= count(listOfPerimeter,'-')+1 Then Do;
            isExecutable   = 'N';
            noteExecutable = catx(',',noteExecutable,"Not all fields included in perimeter are into data contents");
          End;
        End;
        
        *-- Check how many fields are included in technical fields;
        If missing(_tecfields) Then Do;
          isExecutable   = 'N';
          noteExecutable = catx(',',noteExecutable,"Technical fields needs to be compiled. It can't be empty");
        End;
        Else Do;
          If (count(_tecfields,'-') ^= count(listOfCT,'-')) or missing(listOfCT) Then Do;
            isExecutable   = 'N';
            noteExecutable = catx(',',noteExecutable,"Not all fields included in tecnical fields are into data contents");
          End;
        End;

        *-- Check if flag of Applicability (update manually into excel by business user) forced
                      at N it win on isExecutable flag
                       ;
        If _manApplicab='N' Then Do;
          isExecutable   = 'N';
          noteExecutable = catx(',',noteExecutable,"Manual forced. See manual note for details");
        End;

        _rc = htc.add();
      End
      ;
      _dschecks = close(_dschecks);
      _dsF      = close(_dsf);
      htc.output(dataset:"work._functionStatus");   
    Run;

    %*-- Raise _metaCheckRueles with Applicability;
    Proc Sql;
      Create Table work.&sysmacroname. As
        Select a.*
               ,b.isExecutable
               ,b.noteExecutable
               ,b.listOfPerimeter as includeInPerim "Fields included in perimeter"
               ,b.listOfCT as includeInTech "Fields included in technical fields"
          From _metaCheckRueles as a Left Join
               _functionStatus as b 
            On a._idRecordRule = b._idRecordRule
            ;
      Drop Table _functionStatus;
      Drop Table targetDataModel;
    Quit;

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ----------------------+;
	%Put | Retrieve list of controls can be applied        |;
	%Put | idAmbito	: &idAmbito.	     			       |;
	%Put | Metadata	: &dsListChecks.				       |;
	%Put |.................................................|;
	%Put | Ended at: &_tmpStamp.;
	%Put +-------------------------------------------------+;
%Mend;

