/*{"Program": "dwh_040_data_transform_rapporti.sas"
   "Descrizione": "Creates staging about checks ambito='R'",
   "Parametri": [
	],
   "Return": ["Table in staging area [DATISTG.DWH_RAPPORTI]",
	           "Process trace"
			   ]
   "Autore": "Hexe S.p.A.",
   "Sito web": "<http://www.hexeitalia.com>",
   "Email": "<info@hexeitalia.com>",
   "Manutentori": [ "Hexe S.p.A." ]
   "Note": [ ]
   "CR": ["Code":"SOFF"
          "description":"Estarre dalla rapporto il servizio 11"
         ]
}*/

%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=R.1);
*-- [Code: SOFF] ---------------------------------------;
%Let msgFunction  = ;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,R.1,msgFunction));
Data &tableOutName.; Set &tableOutName.;
  if substr(cod_rapporto,2,2)="11" and FLGLKP_R_1_4 = 'N' then do;
    FLGLKP_R_1_4='Y';
  end;
Run;
*-- [Code: SOFF] ---------------------------------------;

%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
                      ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_rapporto cod_portafoglio_gest idRecord)
                      ,flagVarName = flg_f_rapporto);
