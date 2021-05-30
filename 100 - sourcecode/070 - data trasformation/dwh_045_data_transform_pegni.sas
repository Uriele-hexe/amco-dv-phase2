/*{"Program": "dwh_040_data_transform_perizie.sas"
   "Descrizione": "Creates staging about checks ambito='PE'",
   "Parametri": [
	],
   "Return": ["Table in staging area [DATISTG.PEGNI]",
	           "Process trace"
			   ]
   "Autore": "Hexe S.p.A.",
   "Sito web": "<http://www.hexeitalia.com>",
   "Email": "<info@hexeitalia.com>",
   "Manutentori": [ "Hexe S.p.A." ]
   "Note": [ ]
   "CR": [ ]
}*/

%*-- Update Process Trace and Table Trace;
%Let idLkp = PE.1;
%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=&idLkp.);
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,&idLkp.,msgFunction));
%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
                     ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_collateral cod_portafoglio_gest idRecord)
                     ,flagVarName = flg_f_pegni);