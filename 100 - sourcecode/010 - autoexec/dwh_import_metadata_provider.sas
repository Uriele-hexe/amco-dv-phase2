*============================================================================================
* Client Name: AMCO SpA
* Project    : Framework di Data Verification
*--------------------------------------------------------------------------------------------
* Program name: dwh_import_metadata_provider.sas
* Author      : Uriele De Piano Hexe SpA 02 October 2020
* Description : Import MPS's metadata
*============================================================================================
;
%Let wkbFolder  = %UnQuote(&projectFolder.)&slash.02_Metadati&slash.&dataProvider.&slash.Excel;
/*-- Dichiarata in config 
  %Let metaFolder = %UnQuote(&projectFolder.)&slash.02_Metadati&slash.&dataProvider.&slash.Tabledata;
  Libname prvmeta	"&metaFolder.";
--*/

%Macro hx_import_meta_provider(metadataFile=_NULL_,metadataTable=hx_import_meta_provider,wbkSheet=_null_);
	%Local tmpStamp flgLoad _dsid _name _rename
			;
	%Let tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +--[Macro: &sysmacroname.] ----------------------------------------------------------------;
	%Put | Import metadata about [&dataProvider.]																										;
	%Put | Metadata file  : &metadataFile.																													;
	%Put | Metadata Table : &metadataTable.																													;
	%Put | .........................................................................................;
	%Put | Started at : &tmpStamp.;
	%Put +------------------------------------------------------------------------------------------;

	%Let flgLoad=N;
	Data _null_;
		Attrib slash Length=$1
			;
		slash = ifc(symget("sysscp")=:"WIN",'\','/');
		rc    = filename("fname",catx(slash,"&wkbFolder.","&metadataFile."));
		If fexist("fname") And libref("prvmeta")=0 Then 
			Call Symput("flgLoad",'Y');
	Run;
	%Put &=flgLoad;
	%If &flgLoad.=N %Then %Do;
		%Let _fileExtrnal = %sysfunc(pathName(fname));
		%log(level = E, msg = [%UnQuote(&_fileExtrnal.)] not exists);
		%Goto uscita;
	%End;
	%hx_import_cmn_metadata(wkbFolder=&wkbFolder.,wkbName=&metadataFile.,dsMeta=&metadataTable.
	%If %Upcase(&wbkSheet.) ne _NULL_ %Then %Do;
		,wbkSheet=&wbkSheet.
	%End;
			);

    %if &metadataTable.=&dsMetaRacc. %then %goto uscita;

	Proc Contents data=&metadataTable. out=_metaDataContents (Keep=NAME) noprint;
	Run;
	%Let _dsid = %sysfunc(Open(_metaDataContents));
	Data &metadataTable.(Where=(not missing(data_Provider))); 
		Set &metadataTable. (Rename=(
		%Do %While (%Sysfunc(fetch(&_dsid.))=0);
			%Let _name   = %sysfunc(getvarc(&_dsid.,%sysfunc(varnum(&_dsid.,NAME))));
			%Let _rename = %replace_spec_chars(&_name.,char=_);
			"&_name."n = &_rename.
		%End;
		));
	Run;
	%Let _dsid = %sysfunc(close(&_dsid.));

	%uscita:
		%Put +--[Macro: &sysmacroname.] ----------------------------------------------------------------;
		%Put | Import metadata about [&dataProvider.]																										;
		%Put | Metadata file  : &metadataFile.																													;
		%Put | Metadata Table : &metadataTable.																													;
		%Put | .........................................................................................;
		%Put | Ended at : &tmpStamp.;
		%Put +------------------------------------------------------------------------------------------;
%Mend;
Options mprint;
*-- Import Data Mapping raccordo;
%hx_import_meta_provider(metadataFile=%Unquote(&dataProvider.)_data_model_raccordo.xlsx
												,metadataTable=&dsMetaRacc.);

*-- Import Lookup Rules;
%hx_import_meta_provider(metadataFile=%Unquote(&dataProvider.)_list_lookup_rules.xlsx
												,metadataTable=&meta_dslkp_name.);

%*-- Import metadata regarding rules;
%hx_import_meta_provider(metadataFile=%Unquote(&dataProvider.)_tassonomia_controlli.xlsx
												,metadataTable=&dsDwhMetaChecks.,wbkSheet=Elenco controlli di business);

/*
+--[Post Procesing importing metadata] ---------------------------+
| Check if Target Column Name is a valid sasname                  |;
+-----------------------------------------------------------------+
*/

%Macro checkValidNameRacc();
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
%checkValidNameRacc();
