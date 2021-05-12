*==================================================================================================
* Cliente : AMCO SpA
* Office  : CRO Portfolio Managment -> Data Verification
* -------------------------------------------------------------------------------------------------
* Macro name  : dwh_005_T_counterparty
* Description : Create counterparties in staging area
* Author      : Uriele De Piano Hexe SpA, 15 January 2020
* -------------------------------------------------------------------------------------------------
* Parameter:
*
* -------------------------------------------------------------------------------------------------
* Output
*  - Dataset defined into metadata that describe lookup
* -------------------------------------------------------------------------------------------------
* NOTE: Statment about hash table will be write in dataset sas
* -------------------------------------------------------------------------------------------------
* History change:
*   version     : 1.1
*   Description : Lookup on counterparties status descrizione_del_controllo
*   Author      : Uriele De Piano
*   Datetime    : 22 January 2021
* -------------------------------------------------------------------------------------------------
*   version     : 1.2
*   Description : 'Descrizione Status': Substitute missing value with 'Status' values
*   Author      : Uriele De Piano
*   Datetime    : 22 January 2021
*==================================================================================================
;

*-- [version: 1.1] -- [Start] ---------;
*-- import excel;
%Let wkbFolder = &dataRootFolder.&slash.06_Lookup_Table&slash.&dataProvider.;
%Let wkbName   = AMCO_Classificazione_Contabile.xlsx;
%Let wbkSheet  = mapping_stato_b3;
%Let dsDomains = work.counterparties_stato_raccordo;
Proc Delete data=&dsDomains.; Run;
%hx_import_sheet (wkbFolder = &wkbFolder.
                 ,wkbName  = &wkbName.
                 ,wkbSheet = &wbkSheet.
                 ,dsImport = &dsDomains.);
*-- [version: 1.1] -- [End] ---------;

*-- [change version: 1.2] -- [Start] ---------;
Proc Sql;
  Update &dsDomains.  Set 'Descrizione Status'n = 'status'n 
                    where 'Descrizione Status'n Is Null
    ;
Quit;
*-- [change version: 1.2] -- [End] ---------;

%Let _dtRiferimento = %sysfunc(inputn(&dta_reference.,date9.));
%Let _whereClause = %NrQuote(%'Data Valid From%'n <= &_dtRiferimento. And %'Data Valid To%'n >= &_dtRiferimento.);
%Put &=_whereClause;

Data datiStg.DWH_COUNTERPARTIES;
		Set datiwip.DWH_ANAG_CTP (Rename=(stato_debitore=stato_debitore_dwh)) 
        &dsDomains. (obs=0 Keep='Descrizione Status'n code);
    Attrib stato_debitore Length=$255
      ;
		Drop _:
      ;
    *-- [version: 1.1] -- [Start] ---------;
    *-- Create Hash Table to retrieve status code;
    If _N_=1 Then Do;
      declare hash htCS(dataset:"&dsDomains. (Where=(&_whereClause))");
      _rc = htCS.definekey("Descrizione Status");
      _rc = htCS.definedata("code");
      htCS.definedone();
    End;
    Call Missing(stato_debitore);
    if not missing(stato_debitore_dwh) then
      stato_debitore = ifc(htCS.find(key:stato_debitore_dwh)=0,code,"_NC_");
    
    *-- [version: 1.1] -- [End] ---------;
Run;

Proc Sql;
  Create Table _DWH_COUNTERPARTIES_SD As
    Select stato_debitore 
	       ,stato_debitore_dwh
	       ,Count(*) as nrecord
	  From datiStg.DWH_COUNTERPARTIES
	  Group by 1,2
	  ;
Quit;

%hx_set_portfolio (dsName=datiStg.DWH_COUNTERPARTIES);
Options mprint;
%hx_set_flag_distinct(tableOut    = datiStg.DWH_COUNTERPARTIES
                     ,Keys        = %NrQuote(dta_riferimento cod_istituto ndg_debitore cod_portafoglio_gest idRecord)
                     ,flagVarName = flg_f_cpy);
