*============================================================================================
* Client Name: AMCO SpA
* Project    : Framework di Data Verification
*--------------------------------------------------------------------------------------------
* Program name: autoexec.sas
* Author      : Uriele De Piano Hexe SpA 02 October 2020
* Description : Setting global parameters. In addition to, this autoexec import metadata's project
*--------------------------------------------------------------------------------------------
* NOTE:
*   Change      : DWH-LIB
*		Author      : Uriele De Piano Hexe S.p.A
*		Date			  : 20 Novembre 2020
*   Description : Declaration of libnames inside a datastep
*   --------------------------------------------------------------------------------------------
*   Change      : DWH-IST
*		Author      : Uriele De Piano Hexe S.p.A
*		Date			  : 20 Novembre 2020
*   Description : If macro cod_ist exists, then it will be use to define libnames
*   --------------------------------------------------------------------------------------------
*   Change      : LDT_LIB
*		Author  : Uriele De Piano Hexe S.p.A
*		Date	: 05 Febbraio 2021
*   Description : Con l'integrazione dei flussi pre migrazione usando un template standard
*                 si è resa necessaria la revisione delle libname
*============================================================================================
;
options
	/*sasautos = (SASAUTOS, "d:\DataQuality\05_SourceCode\01_Macro\base", "d:\DataQuality\05_SourceCode\01_Macro\project") mautosource*/
	sasmstore=hx_macro mstored
	/*hx_func.lookup*/
	cmplib = (
		hx_func.cmn_dv_function
		hx_func.da_functions
		Hx_func.dt_functions.package
		hx_func.dataverification_dwh
		hx_func.tablesas
	)
	fmtsearch = (cmnfmt) mprint
;
Libname hx_macro "d:\DataQuality\05_SourceCode\01_Macro\project";

%* Carico configurazione di progetto;
%let idTrasaction = %sysfunc(putn(%sysfunc(datetime()),datetime.));
%let config_file = d:\DataQuality\02_Metadati\Common\Excel\config.xlsx;
%config(%bquote(&config_file.));

%*-- Split parameter ldt_fullName in two macro variables declared into config file;
Data _null_;
  Attrib LDT_wkbFolder Length=$256
         LDT_wkbName   Length=$100
	;
  _ldtFullName = symget("ldt_fullName");
  _rc          = count(_ldtFullName,strip(symget("slash")));
  do _i=1 to _rc;
    LDT_wkbFolder = catx("&slash.",LDT_wkbFolder,scan(_ldtFullName,_i,"&slash."));
  end;
  LDT_wkbName = scan(_ldtFullName,_rc+1,"&slash.");

  Call Symput("LDT_wkbFolder",LDT_wkbFolder);	
  Call Symput("LDT_wkbName",LDT_wkbName);	
Run;
%Put &=LDT_wkbFolder;
%Put &=LDT_wkbName;

*--[Change: DWH-LIB: Start] --------------------------------------;
%Macro checkLib_x_ist;
	%Local dataProviderF
			;
	%Let dataProviderF = _NULL_;
	%*-- CAUTION: regarding the declaration of the libname daticheck a distinction is made
								between DWH and LDT
		;
  %*-- [Change code: LDT_LIB] -- [Inizio modifica];
  /*
	%If "%Upcase(&dataProvider.)" ne "DWH" %Then %Do;
		Libname datichk  "&dataRootFolder.&slash.04_Dati_Check&slash.LDT";
		Libname datichk  "&dataRootFolder.&slash.04_Dati_Check&slash.LDT&slash.%UnQuote(&dataProvider.)" filelockwait=600;
		%Return;
	%End;
  Libname datichk  "&dataRootFolder.&slash.04_Dati_Check&slash.%UnQuote(&dataProvider.)";
  */
  %*-- [Change code: LDT_LIB] -- [Fine modifica];

	Data _null_;
		Attrib 	cod_ist      		Length=8
					;
    %*-- [Change code: LDT_LIB] -- [Inizio modifica];
    if Upcase(symget("dataProvider"))="LDT" then do;
      Call Symput("dataProviderF",symget("cod_portafoglio_gest"));
    end;
    else Do;
  	   Call Missing(cod_ist);
	   If symexist("cod_ist") Then Do;
         cod_ist = symget("cod_ist");
	     If not missing(cod_ist) And cod_ist>0 Then Do;
	       dataProviderF = catx('-',"ist",put(cod_ist,12.));
		   Call Symput("dataProviderF",dataProviderF);
	     End;
       End;
	End;
    %*-- [Change code: LDT_LIB] -- [Fine modifica];
	Run;
	%Put &=dataProviderF;
	%If "%Upcase(&dataProviderF.)" ne "_NULL_" %Then %Do;
		Libname datiodd  "&dataRootFolder.&slash.01_Dati_Odd&slash.%UnQuote(&dataProvider.)&slash.%UnQuote(&dataProviderF.)" filelockwait=600;
		Libname datiwip  "&dataRootFolder.&slash.02_Dati_Wip&slash.%UnQuote(&dataProvider.)&slash.%UnQuote(&dataProviderF.)" filelockwait=600;
		Libname datistg  "&dataRootFolder.&slash.03_Dati_Staging&slash.%UnQuote(&dataProvider.)&slash.%UnQuote(&dataProviderF.)" filelockwait=600;
		Libname datichk  "&dataRootFolder.&slash.04_Dati_Check&slash.%UnQuote(&dataProvider.)&slash.%UnQuote(&dataProviderF.)" filelockwait=600;
		Libname datitrc	 "&dataRootFolder.&slash.05_Dati_trace&slash.%UnQuote(&dataProvider.)&slash.%UnQuote(&dataProviderF.)" filelockwait=600;
	%End;
%Mend;
%checkLib_x_ist;
*--[Change: DWH-LIB: End] --------------------------------------;

%macro create_checks_tables;
*-- Create Table and Process Trace;
	%if %sysfunc(exist(&processTrace.))=0 %then %create_dset_struct_from_mtd(cmn_datamodel, whrClause=%bquote(memname='PROCESSTRACE'), dsOut=&processTrace.);
	%if %sysfunc(exist(&tableTrace.))=0 %then %create_dset_struct_from_mtd(cmn_datamodel, whrClause=%bquote(memname='TABLETRACE'), dsOut=&tableTrace.);
	*-- Create Table containing historical checks;
	%if %sysfunc(exist(&histchecks.))=0 %then %create_dset_struct_from_mtd(cmn_datamodel, whrClause=%bquote(memname='HIST_CHECKS'), dsOut=&histchecks.);
	%if %sysfunc(exist(&dsHistRepChecks.))=0 %then %create_dset_struct_from_mtd(cmn_datamodel, whrClause=%bquote(memname='HIST_CHECKS'), dsOut=&dsHistRepChecks.);
	%if %sysfunc(exist(&dsDWHPerimeter.))=0 %then %create_dset_struct_from_mtd(cmn_datamodel, whrClause=%bquote(memname='PERIMETERS'), dsOut=&dsDWHPerimeter.);
%mend create_checks_tables;
%create_checks_tables;

*-- Import common parameters;
%hx_import_parameters(cfgFolder=%UnQuote(&sascodeFolder.)&slash.04_Config
					  ,cfgName=cmn_dataverification_parameters.cfg
					  ,dtaReference=&dta_reference.);
%Put _global_;

*-- Change 02 Dec 2020 by UDP
				Import Common Metadata Excel tabella dei domini
	;
%hx_import_cmn_metadata(wkbName   = npl_cmn_lista_domini.xlsx
						,wbkSheet = npl_cmn_domini
						,dsMeta   = &nplDomini.);

*-- Import Common Metadata Excel;
%hx_import_cmn_metadata(wkbName = npl_sourcedata_list.xlsx
						,dsMeta = &nplSourceList.);

%Let metaTableName = &nplCommonDM.;
%hx_import_cmn_metadata(wkbName = npl_cmn_data_model.xlsx
						,dsMeta = &metaTableName.);
%Macro checkFlgVName;
	%local dsid alreadyChecked
	;

	%Let alreadyChecked = N;
	%Let dsid = %sysfunc(open(&metaTableName));
	%If %sysfunc(varnum(&dsid.,flgValidName))>0 %then %do;
		*%-- In this case metadata table has not be imported;
		%Let alreadyChecked = Y;
	%End;
	%Let dsid = %sysfunc(Close(&dsid.));
	%If &alreadyChecked.= N %Then %Do;
		*-- Check valid varname;
		Data &metaTableName.; Set &metaTableName.;
			Attrib flgValidName Length=$1 label="Flag valid column name";
			flgValidName = ifc(nvalid(columnName,"V7"),'Y','N');
		Run;
		%Let hasUnvalidName=N;
		Proc Sql NoPrint outobs=1;
			select 'Y' into :hasUnvalidName from &metaTableName. where flgValidName='N';
		Quit;
		%if &hasUnvalidName.=Y %then %do;
			Data _null_;
				Put "+---------------------------------------------------------------------+";
				Put "| Importazione di %UnQuote(&metaTableName.) ha un campo non sas valid |";
				Put "+---------------------------------------------------------------------+";
				Abort Abend 10000;
			Run;
		%End;
	%End;
%Mend;
%checkFlgVName;
/*
*======================================================*
* Formats creation from metadata table or lookup table *
*======================================================*
;
%hx_create_formats(libout			   = cmnfmt
									 ,dsSourceFmt  = &nplCommonDQ.
									 ,startV			 = id_Ambito
									 ,descriptionV = Ambito
									 ,fmtName 		 = dqambit);

%hx_create_formats(libout			   = cmnfmt
									 ,dsSourceFmt  = &nplCommonDQ.
									 ,startV			 = idRule
									 ,descriptionV = Descrizione del controllo
									 ,fmtName 		 = dqrules);
*/
