/*{
    "Program": "dwh_025_data_transform_garanzie.sas"
	"Descrizione": "Creates data regarding checks on garanzie",
	"Parametri": [
	],
	"Return": ["Table in staging area [DATISTG.DWH_GARANZIE]",
	           "Process trace"
			   ]
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
    "CR": [ ["Code":"STATUS",
             "Description":"Create Status of garanzia"
            ],
            ["Code":"GR_IPO",
             "Description":"Get max grado ipoteca, inside cod_garanzia"
            ]
          ]
}*/

%hx_get_lookup_group(dsMtd=&meta_dslkp_name.,idLookupGroup=G.1);
%Let msgFunction  = ;
%*-- Retrieve table created by lookup rules;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,G.1,msgFunction));

Proc Sort data=&tableOutName.;
  By dta_riferimento cod_istituto cod_garanzia;
Run;

*---- NOTA DEL 18 MAY: PROVARE AD INSERIRE LA CREAZIONE DEL CAMPO status_gara_derived NEL RACCORDO RICHIAMANDO UNA FUNZIONE ;
*---- APPENA E CONCLUSA QUESTA FASE e ci danno la fase due;

Data _singleGara_ (Keep=dta_riferimento cod_istituto cod_garanzia max_grado_ipot max_grado_sost
                        grado_ammesso has_gravami_miss status_gara_derived); Set &tableOutName.;
  Attrib  max_grado_ipot      Length=8   Label="Grado Ipoteca MAX"
          max_grado_sost      Length=8   Label="Grado Sostanziale MAX"
          status_gara_derived Length=$80 Label="Stato Garanzia derivato" 
          grado_ammesso       Length=8	 Label="Grado ammesso derivato dalla macro GRADO_IPO_AMMISSIBILE"
		  has_gravami_miss    Length=$1  Label="Esiste almeno un gravame non valorizzato Y/N"
          ;

    ;
  By dta_riferimento cod_istituto cod_garanzia;
  Retain max_grado_ipot max_grado_sost . status_gara_derived ' ' grado_ammesso &GRADO_IPO_AMMISSIBILE. has_gravami_miss ' '
    ;
  *-- Retrieve Stato Garanzia;
  if first.cod_garanzia then do;
    if flg_escusso eq 1 then status_gara_derived='ESCUSSA';
    else if missing(dta_estinzione) ne 1 and dta_estinzione le "&dta_reference."D then status_gara_derived='ESTINTA';
    else if dta_scadenza ge "&dta_reference."D or (missing(dta_rinnovo) ne 1 and dta_rinnovo ge "&dta_reference."D) then status_gara_derived='VALIDA';
    else if missing(dta_scadenza) ne 1 and dta_scadenza lt "&dta_reference"D then status_gara_derived='SCADUTA' ;
    else do;
      status_gara_derived='NON VALIDA';
    end;
    Call Missing(max_grado_ipot,max_grado_sost);
	has_gravami_miss = 'N';
  end;
  max_grado_ipot = max(num_grado_ipoteca,max_grado_ipot);
  max_grado_sost = max(num_grado_sost,max_grado_sost);
  if missing(des_gravami) Then has_gravami_miss='Y';
  if last.cod_garanzia then output;
Run;
*-- Rewrite table in staging;
Data &tableOutName.; Set &tableOutName. _singleGara_ (Obs=0);
  If _N_=1 Then Do;
    Declare hash ht(dataset:"_singleGara_");
      ht.defineKey("dta_riferimento","cod_istituto","cod_garanzia");
      ht.defineData("max_grado_ipot","max_grado_sost","grado_ammesso","status_gara_derived","has_gravami_miss");
      ht.defineDone();
  End;
  if ht.find(key:dta_riferimento,key:cod_istituto,key:cod_garanzia)=0 then do;
    num_grado_ipoteca = max_grado_ipot;
    num_grado_sost    = max_grado_sost;
	if has_gravami_miss='Y' Then Call Missing(des_gravami);
  end;
Run;
%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
					  ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_garanzia cod_portafoglio_gest idRecord)
					  ,flagVarName = flg_f_garanzia);
