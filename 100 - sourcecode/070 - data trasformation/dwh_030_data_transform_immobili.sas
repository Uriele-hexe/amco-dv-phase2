/*{
    "Program": "dwh_030_data_transform_immobili.sas"
	"Descrizione": "Creates staging about checks ambito='A'",
	"Parametri": [
	],
	"Return": ["Table in staging area [DATISTG.DWH_IMMOBILI_CTP]",
	           "Process trace"
			   ]
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
    "CR": [ ["Code":"GET_ANNI_IN_PROC",
             "Description":"Creates a new variable containing parameters anni_in_procedura"
            ],
            [
            ]
          ]
}*/
%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=I.1);
%*-- Retrieve table created by lookup rules;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,I.1,msgFunction));

*-- Lookup tra immobili e procedure per applicare la regola che verifica quanti anni una ctp è in procedura;
%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=IP.1);
%*-- Retrieve table created by lookup rules;
%Let tableOutProc = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,IP.1,msgFunction));
Proc Sort data=&tableOutProc.;
  By dta_riferimento cod_istituto cod_collateral cod_sub_collateral;
Run;

*-- Calculate no of years;
Data &tableOutProc. (Drop=maxAnniInProc dta_apertura_procedura_max dta_chiusura_procedura_max cod_procedure_max cod_pratica_max)
    _sintCollateral (Keep=flgLkp_ip_1_3 dta_riferimento cod_istituto cod_collateral cod_sub_collateral maxAnniInProc dta_apertura_procedura_max dta_chiusura_procedura_max cod_procedure_max cod_pratica_max);  
    Set &tableOutProc.;
  By dta_riferimento cod_istituto cod_collateral cod_sub_collateral;
  Attrib flgProcClose               Length=$1   Label="Procedure was closed Y/N"
         nAnniInProc                Length=8    Label="Year opening procedure" format=commax12.
		 maxAnniInProc              Length=8    Label="Max opening procedura inside sub collateral" format=commax12.
		 dta_apertura_procedura_max Length=8    Label="Open date corresponding max year" format=ddmmyy10.
		 dta_chiusura_procedura_max Length=8    Label="Close date corresponding max year" format=ddmmyy10.
		 cod_procedure_max          Length=$255 Label="Procedure corresponding max year"
		 cod_pratica_max            Length=$255 Label="Code pratica corresponding max year"
     ;
  Length _flgProcOpen $1;
  Retain maxAnniInProc dta_apertura_procedura_max dta_chiusura_procedura_max . cod_procedure_max cod_pratica_max ' '
         flgProcClose _flgProcOpen ' '
    ;
  if first.cod_sub_collateral then 
    call missing(maxAnniInProc,dta_apertura_procedura_max,dta_chiusura_procedura_max,cod_procedure_max,cod_pratica_max,_flgProcOpen);

  flgProcClose = ifc(flgLkp_ip_1_3='Y' and (missing(dta_chiusura_procedura) or dta_chiusura_procedura>dta_riferimento),'N','Y');
  Call Missing(nAnniInProc);
  if flgProcClose='N' then do; 
    _flgProcOpen = 'Y';
    nAnniInProc = intck("year",sum(dta_apertura_procedura,0),dta_riferimento);
	if nAnniInProc>maxAnniInProc then do;
	  maxAnniInProc = nAnniInProc;
	  dta_apertura_procedura_max = dta_apertura_procedura;
	  dta_chiusura_procedura_max = dta_chiusura_procedura;
	  cod_procedure_max          = cod_procedure;
	  cod_pratica_max            = cod_pratica;
	end;
  end;
  Output &tableOutProc. ;
  if last.cod_sub_collateral and _flgProcOpen='Y' and flgLkp_ip_1_3='Y' then output _sintCollateral;
Run;
*-- Agganci gli immobili in procedura estratti direttamente dalla Lotti / Aste;
Data &tableOutName. (Drop=_:); Set &tableOutName. _sintCollateral(obs=0);
  Attrib anni_in_procedura_lim Length=8 Label="Anni in procedura oltre il quale scatta l'anomalia"
           ;
  Retain anni_in_procedura_lim &anni_in_procedura.
     ;
  If _N_=1 Then Do;
    Declare hash ht(dataset:"_sintCollateral",ordered:'y');
	  ht.defineKey("dta_riferimento","cod_istituto","cod_collateral","cod_sub_collateral");
	  ht.defineData("flgLkp_ip_1_3","dta_apertura_procedura_max","dta_chiusura_procedura_max","cod_procedure_max","cod_pratica_max","maxAnniInProc");
	  ht.defineDone();
  End;
  *---[Change Code: GET_ANNI_IN_PROC] -----------------------------;
  Call Missing(flgLkp_ip_1_3,dta_apertura_procedura_max,dta_chiusura_procedura_max,cod_procedure_max,cod_pratica_max,maxAnniInProc);
  _rc = ht.find(key:dta_riferimento,key:cod_istituto,key:cod_collateral,key:cod_sub_collateral);
Run;

%hx_set_portfolio (dsName=&tableOutName.,_businessKey=cod_collateral);
%hx_set_flag_distinct(tableOut    = &tableOutName.
  				     ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_collateral cod_sub_collateral cod_portafoglio_gest idRecord)
					 ,flagVarName = flg_f_immobili);
