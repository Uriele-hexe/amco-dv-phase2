/*{
    "Program": "dwh_015_data_transform_fidi.sas"
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

%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=F.1);
%Let msgFunction  = ;
%*-- Retrieve table created by lookup rules;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,F.1,msgFunction));
%Put &=tableOutName;
%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
					  ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_fido cod_portafoglio_gest idRecord)
					 ,flagVarName = flg_f_fido);

*---- NOTA APPENA CONCLUSA LA PRIMA FASE QUESTO PEZZO DI CODICE E DA VEDERE SE SI RIESCE A PORTARE NEL METADATO DI MAPPING;
Data &tableOutName.; Set &tableOutName.;
  Attrib flg_fido_attivo Length=$1 Label="Flag fido attivo" format=$1.;
  flg_fido_attivo = ifc(missing(dta_revoca) Or dta_revoca>dta_riferimento,'Y','N');
Run;
