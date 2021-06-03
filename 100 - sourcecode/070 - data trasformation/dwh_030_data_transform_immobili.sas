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

*-- Estrazione degli Immobili con associati una o pi� controparti debitori;
Proc Sort data=&tableOutName. (Where=(flgLkp_I_1_5='Y'))
           out=immobiliConProcedure (keep=idRecord cod_collateral cod_procedura cod_garanzia cod_fido cod_rapporto ndg_debitore flgLkp_I_1_11 dta_apertura_procedura dta_chiusura_procedura dta_ins_fase dta_ult_var_fase dta_riferimento);
  by cod_collateral;
Run;
*-- Considera le procedure aperte come dta_chiusura_procedura missing oppure dta_chiusura_procedura>data riferimento;
Data datistg.DWH_IMMOBILI_IN_PROCEDURA; Set immobiliConProcedure (Where=(flgLkp_I_1_11='Y'));
  Attrib flgProcClose    Length=$1 Label="Flag procedura chiusa Y/N"
         nGiorniApertura Length=8  Label="Nr. di giorni di apertura in procedura" format=commax12.
         nMesiApertura   Length=8  Label="Nr. di mesi di apertura in procedura" format=commax12.
         nAnniApertura   Length=8  Label="Nr. di anni di apertura in procedura" format=commax12.
      ;
  flgProcClose =ifc(not missing(dta_chiusura_procedura) and dta_chiusura_procedura<=dta_riferimento,'Y','N');
  format ndg_debitore 12.;
  by cod_collateral;
  nGiorniApertura = intck("day",dta_apertura_procedura,dta_riferimento);
  nMesiApertura   = intck("month",dta_apertura_procedura,dta_riferimento);
  nAnniApertura   = intck("year",dta_apertura_procedura,dta_riferimento);
Run;

Data &tableOutName.; Set &tableOutName.;
  Attrib anni_in_procedura_lim Length=8 Label="Anni in procedura oltre il quale scatta l'anomalia"
         ndg_in_procedura_aa   Length=8 Label="No. di anni del debitore in procedura"
           ;
  Retain anni_in_procedura_lim &anni_in_procedura.
     ;
  *---[Change Code: GET_ANNI_IN_PROC] -----------------------------;
  *-- Default value if dta_apertura_procedura is missing;
  ndg_in_procedura_aa = 99999; 
  if missing(dta_chiusura_procedura) then ndg_in_procedura_aa = intck("year",dta_apertura_procedura,dta_riferimento);
  else if dta_chiusura_procedura<=dta_riferimento then ndg_in_procedura_aa=0;
  else ndg_in_procedura_aa = intck("year",dta_apertura_procedura,dta_riferimento);
Run;

%hx_set_portfolio (dsName=&tableOutName.,_businessKey=cod_collateral);
%hx_set_flag_distinct(tableOut    = &tableOutName.
  				     ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_collateral cod_sub_collateral cod_portafoglio_gest idRecord)
					 ,flagVarName = flg_f_immobili);
