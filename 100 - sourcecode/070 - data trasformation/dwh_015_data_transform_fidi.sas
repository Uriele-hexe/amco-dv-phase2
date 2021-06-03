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

*-- Estrazione se esiste un fido che ha almeno un rapporto non censito e di conseguenza un ndg;
Proc Sort data=&tableOutName.
           out=_fidiRapporti;
  by cod_fido;
Run;
Data _fidiRapportiSint (Keep=cod_fido flg_fido_attivo flgLkp_F_1_1 flgLkp_F_1_2 flgLkp_F_1_3 nRapporti flgRapp_Nc flgDeb_Nc cod_rapporto_nc cod_ndg_debitore_nc)
; Set _fidiRapporti;
  Attrib cod_rapporto_nc     Length=$255 Label="Codice rapporto non censito"
         cod_ndg_debitore_nc Length=$255 Label="Codice ndg debitore non censito"
		 flgRapp_Nc          Length=$1   LAbel="Ha un rapporto non censito Y/N"
		 flgDeb_Nc           Length=$1   Label="Ha un ndg non censito Y/N"
		 nRapporti           Length=8    Label="N. rapporti"
         flg_fido_attivo Length=$1 Label="Flag fido attivo" format=$1.
  ;
	;
  Retain cod_rapporto_nc cod_ndg_debitore_nc flgRapp_Nc	flgDeb_Nc ' ';
  By cod_fido;

  If first.cod_fido then Call missing(cod_rapporto_nc,cod_ndg_debitore_nc,flgRapp_Nc,flgDeb_Nc,nRapporti);
  flg_fido_attivo = ifc(missing(dta_revoca) Or dta_revoca>dta_riferimento,'Y','N');
  nRapporti       = sum(nRapporti,1);
  *-- Flag aggancio rapporti solo se è stato agganciato il fido;
  if flgLkp_F_1_1='Y' And flgLkp_F_1_2='N' then do;
    cod_rapporto_nc = cod_rapporto;
	flgRapp_Nc      = 'Y';
  end;
  *-- Flag aggancio ndg solo se è stato agganciato il rapporto;
  if flgLkp_F_1_2='Y' And flglkp_F_1_3='N' then do;
    cod_ndg_debitore_nc = ndg_debitore;
	flgDeb_Nc           = 'Y';
  end;
  if last.cod_fido Then output;
Run;
*---- Riscrive i flag nella tabella finale;
Data &tableOutName. (Drop=flgRapp_Nc flgDeb_Nc); 
             Set &tableOutName. 
                 _fidiRapportiSint(obs=0 keep=cod_fido flg_fido_attivo flgRapp_Nc flgDeb_Nc cod_rapporto_nc cod_ndg_debitore_nc)
      ;
  If _N_=1 Then Do;
    declare hash ht(dataset:"_fidiRapportiSint");
	ht.defineKey("cod_fido");
	ht.defineData("flg_fido_attivo","flgRapp_Nc","flgDeb_Nc","cod_rapporto_nc","cod_ndg_debitore_nc");
    ht.defineDone();
  End;
  Call Missing(flg_fido_attivo,cod_rapporto_nc,cod_ndg_debitore_nc);
  if ht.find(key:cod_fido)=0 then do;
    flgLkp_F_1_2 = ifc(flgRapp_Nc='Y','N',flgLkp_F_1_2);
	flglkp_F_1_3 = ifc(flgDeb_Nc='Y','N',flglkp_F_1_3);
  end;
Run;

%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
					  ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_fido cod_portafoglio_gest idRecord)
					 ,flagVarName = flg_f_fido);

