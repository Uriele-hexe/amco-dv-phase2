*============================================================================================
* Client Name: AMCO SpA
* Project    : Framework di Data Verification
*--------------------------------------------------------------------------------------------
* Program name: cmn_import_metadata_raccordo.sas
* Author      : Uriele De Piano Hexe SpA 02 October 2020
* Description : Import MPS's metadata
*============================================================================================
;
%Let wkbFolder  = %UnQuote(&projectFolder.)&slash.02_Metadati&slash.&dataProvider.&slash.Excel;
/* Spostata in config 
   %Let metaFolder = %UnQuote(&projectFolder.)&slash.02_Metadati&slash.&dataProvider.&slash.Tabledata;
    Libname racmeta	"&metaFolder.";
   %Let dsMetaRacc = racmeta.%UnQuote(&dataProvider.)_data_model_raccordo;
*/
%hx_import_cmn_metadata(wkbFolder=&wkbFolder.
                       ,wkbName=%UnQuote(&dataProvider.)_data_model_raccordo.xlsx
                       ,dsMeta=&dsMetaRacc.);
%Macro checkValidName;
	%Local hasFlag dsid
		;
	%Let dsid    = %sysfunc(open(&dsMetaRacc.));
	%Let hasFlag = %sysfunc(Varnum(&dsid.,flgValidName));
	%Let dsid    = %sysfunc(Close(&dsid.));

	Data &dsMetaRacc. (Drop=_:);	
		set &dsMetaRacc.	end=fine;
		%If &hasFlag. le 0 %Then %Do;
			Attrib flgValidName Length=$1;
		%End;
		Retain _nUnvalidName 0;
		flgValidName = ifc(nvalid(columnName,'V7'),'Y','N');
		If flgValidName='N' Then _nUnvalidName = Sum(_nUnvalidName,1);
		If fine Then Do;
			Call Symputx("unValid",put(_nUnvalidName,12.),'G');
		End;
	Run;
  Data _null_;
		_nUnvalidName = &unValid.;
		%hx_declare_ht_pr(htTable=&processTrace.);		
		sourceCode = "HX_IMPORT_%Upcase(&dataProvider.)_METADATA";
		stepCode	 = "Check valid column name on &dataProvider._data_model_raccordo.xlsx";
		rcCode		 = 10;
		msgCode 	 = ifc(_nUnvalidName>0,catx(' ',"Ci sono",put(_nUnvalidName,12.),"campi in input il cui nome non è un valid sasname")
																		,"Tutti i campi sono valid name"
																		);
		rc = ht.add();
		rc = ht.output(dataset:"&processTrace.");
	Run;
%Mend;
%checkValidName;
