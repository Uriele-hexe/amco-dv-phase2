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
%*-- Retrieve table created by lookup rules;
%Let tableOutName = %sysfunc(fx_get_dsname_outjoin(&meta_dslkp_name.,IA.1,msgFunction));
%Put &=tableOutName;

*-- Restituisce per ogni codice collateral il max tra importo base asta e importo vendita asta per AS.5.4 e AS.5.5
  ;
Proc Sql;
  Create Table _maxValue As  
    Select cod_collateral
	       ,cod_sub_collateral
	       ,max(flglkp_IA_1_2) as flglkp_IA_1_2
		   ,max(imp_base_ultimaasta) as imp_base_ultimaasta
		   ,max(imp_vendita_asta) as imp_vendita_asta
		   ,count(*) as ncoll
	  From &tableOutName.
	  Group By 1,2
	  ;
Quit;
Proc Sort data= &tableOutName. (Where=(cod_tipo="CTU"))
           out=_ctuCollateral (Keep=cod_collateral cod_sub_collateral cod_tipo imp_valore_ctu);
  by cod_collateral cod_sub_collateral;
Run;
Data _ctuCollateral; Set  _ctuCollateral;
  Attrib flgMoreLotti Length=$1 Label="Collateral has more records Y/N?"
         flgMoreCtu   Length=$1 Label="Collateral has more CTU values Y/N?"
		 imp_valore_ctu_min Length=8
		 ;
  by cod_collateral cod_sub_collateral;
  Retain imp_valore_ctu_min 9999999999999999;
  If _N_=1 Then Do;
    declare hash ht(dataset:"_maxValue (Where=(ncoll>1))",ordered:"yes");
	 ht.defineKey("cod_collateral","cod_sub_collateral");
     ht.defineDone();
  End;
  flgMoreLotti = ifc(ht.check(key:cod_collateral,key:cod_sub_collateral)=0,'Y','N');
  if first.cod_sub_collateral then imp_valore_ctu_min = 9999999999999999;
  imp_valore_ctu_min = min(imp_valore_ctu_min,imp_valore_ctu); 
  if last.cod_sub_collateral then output;
Run;

Data &tableOutName.; Set &tableOutName. 
                         _ctuCollateral (obs=0 keep=cod_collateral imp_valore_ctu_min);
  Drop _: imp_valore_ctu_min
    ;
  If _N_=1 then Do;
    declare hash ht(dataset:"_maxValue (Where=(ncoll>1))",ordered:"yes");
	 ht.defineKey("cod_collateral","cod_sub_collateral");
	 ht.defineData("flglkp_IA_1_2","imp_base_ultimaasta","imp_vendita_asta");
	 ht.defineDone();
    declare hash htCtu(dataset:"_ctuCollateral (Where=(flgMoreCtu='Y'))",ordered:"yes");
	 htCtu.defineKey("cod_collateral","cod_sub_collateral");
	 htCtu.defineData("imp_valore_ctu_min");
	 htCtu.defineDone();
  End;
  _Rc = ht.find(key:cod_collateral,key:cod_sub_collateral);
  if htCtu.find(key:cod_collateral,key:cod_sub_collateral)=0 then do;
    _imp_valore_ctu_originale = imp_valore_ctu;
    imp_valore_ctu            = imp_valore_ctu_min;
  end;
  *-- Forza il valore di cod_tipo a CTU nel caso in cui non ci sono perizie CTU;
  if flgLkp_IA_1_3='N' then cod_tipo="CTU";
Run;
%Let msgFunction  = ;
%hx_set_portfolio (dsName=&tableOutName.);
%hx_set_flag_distinct(tableOut    = &tableOutName.
					  ,Keys        = %NrQuote(dta_riferimento cod_istituto cod_collateral cod_sub_collateral cod_portafoglio_gest idRecord)
					  ,flagVarName = flg_f_subcoll);
