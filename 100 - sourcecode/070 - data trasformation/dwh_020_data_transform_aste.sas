/*{
    "Program": "dwh_020_data_transform_aste.sas"
	"Descrizione": "Arrich fidi information",
	"Parametri": [
	],
	"Return": ["Update metadata lookup",
	           "Process trace"
			   ]
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
    "CR": [ ["Code":"FLG_ATT",
             "Description":"Add flg_fido_attivo based on dat_revoca=10JAN2020"
            ]
          ]

}*/

%Let idLkp = AS.1;
%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=&idLkp.);
%Let msgFunction  = ;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,&idLkp.,msgFunction));
%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
                     ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_asta cod_portafoglio_gest idRecord)
                     ,flagVarName = flg_f_asta);
