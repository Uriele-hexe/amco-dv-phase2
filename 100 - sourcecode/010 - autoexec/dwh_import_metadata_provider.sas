/*============================================================================================
 * Client Name: AMCO SpA
 * Project    : Framework di Data Verification
 *--------------------------------------------------------------------------------------------
 * Program name: dwh_import_metadata_provider.sas
 * Author      : Uriele De Piano Hexe SpA 02 October 2020
 * Description : Import MPS's metadata
 *============================================================================================*/

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

	%if &metadataTable.=&dsDwhMetaChecks. %then %do;
	  Data &dsDwhMetaChecks. ;
	    Attrib "Data Provider"n Length=$10 Label="Data Provider";
	    Set &dsDwhMetaChecks. (Where=(Upcase(&dataProvider)=:'S' or Upcase(&dataProvider)=:'Y'));
        "Data Provider"n = Upcase("&dataProvider.");
	  Run;
	%end;

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
Proc Delete data=&meta_dslkp_name.; Run;
%hx_import_meta_provider(metadataFile=%Unquote(&dataProvider.)_list_lookup_rules.xlsx
						,metadataTable=&meta_dslkp_name.);

%*-- Import metadata regarding rules;
*-- ATTENZIONE IL PANEL DOVRA ESSERE SPOSTATO SOTTO LA CARTELLA COMMON QUANDO FINIREMO LE MODIFICHE;
%Let _panelName = amco panel dei controlli.xlsx; 
Data _null_;
  *_folderInput = "&METACOMMONFOLDER.";
   _folderInput = "d:\dataquality\99 - rrhh\uriele\Tassonomia controlli";
   _folderOut   = "&wkbFolder.";
   _panelName   = "&_panelName.";
   _cmdCopy     = catx(' ',"copy",cats('"',_folderInput,"&slash.",_panelName,'"'),cats('"',_folderOut,"&slash.",'"'));
   rc           = system(_cmdCopy);
   Put _cmdCopy= rc=;
Run;
Proc Delete data=&dsDwhMetaChecks.; Run;
%hx_import_meta_provider(metadataFile=&_panelName.
						,metadataTable=&dsDwhMetaChecks.
                        ,wbkSheet=Dizionario controlli);

Data &dsDwhMetaChecks. (Keep=Data_Provider 
						     id_Ambito 
							 Ambito
						     IdRule 
						     Principio 
							 Controllo
						     Descrizione_Controllo_per_Report 
                             Periodicita  
						     Perimetro_di_applicabilita 
							 Campi_Tecnici 
							 Nome_Funzione 
							 Regola_Tecnica_violata 
							 Severity 
                             Soglia_inferiore 
							 Soglia_Superiore 
							 Data_Rilascio 
							 Data_ultimo_aggiornamento 
							 Data_Validita_From 
							 Data_validita_To 
                             Applicabilita_Controllo 
							 Note_Applicabilita)
	; Set &dsDwhMetaChecks. (Rename=(id_rule=idRule 
									 data_valid_to=Data_validita_To
									'Entità'n=ambito
                             ))
		;
	Attrib data_validita_from Length=8 Label="Valid from" format=ddmmyy10.
           severity           Length=8 Label="Severity"
	       Soglia_inferiore   Length=8 Label="Soglia inferiore"
		   Soglia_superiore   Length=8 Label="Soglia Superiore"
		   Data_ultimo_aggiornamento Length=8 Label="Data ultimo aggiornamento" format=ddmmyy10.

       ;
	Severity=2;
	Call Missing(Soglia_inferiore,Soglia_superiore);
	Data_ultimo_aggiornamento = Data_Rilascio;
	data_validita_from = input(data_valid_from,ddmmyy10.);
Run;

/*
*======================================================*
* Formats creation from metadata table or lookup table *
*======================================================*/
;
%hx_create_formats (libout		  = work
	 				,dsSourceFmt  = &dsDwhMetaChecks.
	 			    ,startV	      = idRule
	 				,descriptionV = controllo
	 				,fmtName 	  = fmtcontrollo);

%hx_create_formats (libout		  = work
	 				,dsSourceFmt  = &dsDwhMetaChecks.
	 			    ,startV	      = idRule
	 				,descriptionV = ambito
	 				,fmtName 	  = ambito);
/*
%hx_create_formats (libout		  = work
	 				,dsSourceFmt  = &dsDwhMetaChecks.
	 			    ,startV	      = idRule
	 				,descriptionV = severity
	 				,fmtName 	  = severity);
*/
%hx_create_formats (libout		  = work
	 				,dsSourceFmt  = &dsDwhMetaChecks.
	 			    ,startV	      = idRule
	 				,descriptionV = Principio
	 				,fmtName 	  = Principio);

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
		msgCode 	 = ifc(_nUnvalidName>0,catx(' ',"Ci sono",put(_nUnvalidName,12.),"campi in input il cui nome non Ã¨ un valid sasname")
																		,"Tutti i campi sono valid name"
																		);
		rc = ht.add();
		rc = ht.output(dataset:"&processTrace.");
	Run;
%Mend;
%checkValidNameRacc();
