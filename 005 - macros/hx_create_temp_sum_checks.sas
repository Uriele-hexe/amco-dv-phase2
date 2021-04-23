/*{
    "Program": "hx_create_temp_sum_checks"
	"Descrizione": "Create a temporary table containing the results of the data verification engine",
	"Parametri": [
		"dsHistChecks":"Contains name of historical data checks",
        "dsMetaChecks":"Panel of checks"
        "dsListPortf":"List of portfolios"
	],
	"Return": "dataset named: work.hx_create_temp_sum_checks",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Function needs to be execute by function" ]
}*/

/*%Macro hx_create_temp_sum_checks (dsHistChecks=_NULL_
                                  ,dsMetaChecks=_NULL_
                                  ,dsListPortf=datistg.ALL_RECONNECTION_TABLE )
				/ Des = "Create a temporary table about output of checks";*/
%Macro hx_create_temp_sum_checks ()	
     / Des = "Create a temporary table about output of checks";                
	%local _dttimeStamp _dsid _hashData
	   ;

	%Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] --------------------------+;
	%Put | Create a temporary table about output of checks      |;
	%Put | Data model: &dsHistChecks.                           |;
	%Put | .................................................... |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] --------------------------+;

    %Let dsHistChecks = %sysfunc(dequote(&dsHistChecks.));
    %Let dsMetaChecks =  %sysfunc(dequote(&dsMetaChecks.));
    %Let dsListPortf  = datistg.ALL_RECONNECTION_TABLE;

    %If %sysfunc(exist(work.&sysmacroname.)) %Then %Do;
      Proc Sql;
        Drop Table work.&sysmacroname.;
      Quit;
    %End;
    %If %sysfunc(exist(&dsMetaChecks.))=0 %Then %Do;
      %log(level = E, msg = Metadata table %UnQuote(&dsMetaChecks.) containing checks not exist!!);
 	  %log(level = E, msg = Data verification engine was stopped !!);
      %return;
    %End;

    Proc Contents data=&dsHistChecks. noprint 
                   out=_dmChecks (Keep=VARNUM NAME TYPE LENGTH LABEL FORMAT FORMATL FORMATD);
    Run;
    Proc Sql Noprint;
        Select cats('"',NAME,'"') into :_hashData separated by ','
        From _dmChecks
        Order by varnum
         ;
        %If %sysfunc(exist(&dsListPortf.)) %Then %Do;         
          Create Table _listPortf As
            Select Distinct cod_portafoglio_gest
                            ,des_portafoglio_gest
              from &dsListPortf.
            ;
        %End;
    Quit;

    %Let _dsid = %sysfunc(open(_dmChecks));
    Data _null_;
       %*-- Compone Attrib statement [Start];
       %Do %While(%sysfunc(fetch(&_dsid.))=0);
         %Let _nomeV = %Sysfunc(Getvarc(&_dsid.,%Sysfunc(Varnum(&_dsid.,NAME))));
         %Let _typeV = %Sysfunc(GetvarN(&_dsid.,%Sysfunc(Varnum(&_dsid.,TYPE))));
         %Let _lenV  = %Sysfunc(GetvarN(&_dsid.,%Sysfunc(Varnum(&_dsid.,LENGTH))));
         %Let _labV  = %Sysfunc(Getvarc(&_dsid.,%Sysfunc(Varnum(&_dsid.,LABEL))));
         %Let _fmtV  = %Sysfunc(Getvarc(&_dsid.,%Sysfunc(Varnum(&_dsid.,FORMAT))));
         %Let _fmtlV = %Sysfunc(GetvarN(&_dsid.,%Sysfunc(Varnum(&_dsid.,FORMATL))));
         %Let _fmtdV = %Sysfunc(GetvarN(&_dsid.,%Sysfunc(Varnum(&_dsid.,FORMATD))));
   
         %Let _sastype = 8;
         %If &_typeV.=2 %Then %Do;
           %Let _sastype = $%UnQuote(&_lenV.);
         %End;

         %Let _label=;
         %If "&_labV." ne "" %Then %Do;
           %Let _label = %NrQuote(Label="&_labV.");
        %End;

         %Let _format = ;
         %If "&_fmtV." ne "" %Then %Do;
           %Let _format = %NrQuote(format=&_fmtV.);
           %If %Eval(&_fmtlV.)>0 %Then %Let _format = %UnQuote(&_format.)%UnQuote(&_fmtlV.).;
           %Else %Let _format = %UnQuote(&_format.).;

           %If %Eval(&_fmtdV.)>0 %Then %Do;
             %Let _format = %UnQuote(&_format.)%UnQuote(&_fmtdV.);
           %End;
         %End;
         Attrib &_nomeV. Length=&_sastype. &_label. &_format.;
       %End;
       %*-- Compone Attrib statement [End];

       Declare hash ht(multidata:"yes");
         ht.defineKey("dataProvider","cod_ist","dta_reference","cod_portafoglio_gest","idRule");
         ht.defineData(&_hashData.);
         ht.defineDone();

        dataProvider  = "&dataProvider.";
        cod_ist       = "&cod_ist.";
        dta_reference = "&dta_reference."d;
        timeStamp     = &_dttimeStamp.;
        idTransaction = "&idTrasaction";

       *-- Creates an empty matrix associating at any idrule all portafolio;
       _dsport = 0;
       %If %sysfunc(exist(_listPortf)) %Then %Do;
         _dsport = open("_listPortf");
       %End;
       _dsRule = open("&dsMetaChecks.");
       Do While (Fetch(_dsRule)=0);
         idAmbito                    = Getvarc(_dsRule,Varnum(_dsRule,"id_Ambito"));
         descr_ambito                = Getvarc(_dsRule,Varnum(_dsRule,"ambito"));
         idRule                      = Getvarc(_dsRule,Varnum(_dsRule,"idRule"));
         descr_rule                  = Getvarc(_dsRule,Varnum(_dsRule,"Descrizione_del_controllo"));
         principio                   = Getvarc(_dsRule,Varnum(_dsRule,"principio"));
         fx_name                     = Getvarc(_dsRule,Varnum(_dsRule,"Nome_Funzione"));
         Campi_Tecnici               = Getvarc(_dsRule,Varnum(_dsRule,"Campi_Tecnici"));
         Perimetro_di_applicabilita  = Getvarc(_dsRule,Varnum(_dsRule,"Perimetro_di_applicabilita"));
         eseguito                    = Getvarc(_dsRule,Varnum(_dsRule,"isExecutable"));
         nota                        = Getvarc(_dsRule,Varnum(_dsRule,"noteExecutable"));
         flagName     = catx('_',"flgidRule",translate(idRule,'_','.'));
         nOccurs      = 0;
         *-- Attach portfolios;         
         cod_portafoglio_gest = "_ND_";
         des_portafoglio_gest = "PORTAFOGLIO NON TROVATO";
         ht.add();
         Call Missing(cod_portafoglio_gest,des_portafoglio_gest);
         If _dsport>0 Then Do;
           rc = rewind(_dsport);
           Do While(Fetch(_dsport)=0);
             cod_portafoglio_gest = GetvarC(_dsport,varnum(_dsport,"cod_portafoglio_gest"));
             des_portafoglio_gest = GetvarC(_dsport,varnum(_dsport,"des_portafoglio_gest"));
             ht.add();
           End;
         End;
       End;
       _dsRule = close(_dsRule);
       If _dsport>0 Then _dsport = close(_dsport);
       ht.output(dataset:"work.&sysmacroname.");
    Run;
    %Let _dsid = %Sysfunc(Close(&_dsid.));

    %Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] --------------------------+;
	%Put | Create a temporary table about output of checks      |;
	%Put | Data model: &dsHistChecks.                           |;
	%Put | .................................................... |;
	%Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] --------------------------+;
%Mend;
/*
Option mprint source2;
%hx_create_temp_sum_checks (dsHistChecks=&histchecks.,dsMetaChecks=work.HX_RETRIEVE_CHECKS_APPLICABLE)
*/