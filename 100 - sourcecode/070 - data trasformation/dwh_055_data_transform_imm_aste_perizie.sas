/*{
    "Program": "dwh_050_data_transform_collateral.sas"
	"Descrizione": "Creates data regarding checks on collateral",
	"Parametri": [
	],
	"Return": ["Table in staging area [DATISTG.DWH_IMMOBILI_ASTE]",
	           "Process trace"
			   ]
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ ]
    "CR": [ 
          ]
}*/

%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=IA.1);
%Let msgFunction  = ;
%*-- Retrieve table created by lookup rules;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,IA.1,msgFunction));
%Put &=tableOutName;
%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
					  ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_collateral cod_sub_collateral cod_portafoglio_gest idRecord)
					  ,flagVarName = flg_f_subcoll);
