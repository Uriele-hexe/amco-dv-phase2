/*{
    "Program": "dwh_010_data_acquisition_import_data.sas"
	"Descrizione": "Preliminary checks on DWH Table data model",
	"Parametri": [
	],
	"Return": ["datiwip.%UnQuote(&_dataProvider.)_LIST_SASTABLE_NORMALIZED",
	           "datiwip":"Libname datiwip"
			   ]
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
}*/

*-- Option cmplib = (hx_func.da_functions) mprint source2;
%Macro hx_dwh_import_data(forced=Y) / Des="Import data";
	%Local _tmpStamp _rcImportData _dsTempTrace _datiodd
			;
    %If %symexist(hx_dwh_chk_model) %Then %Do;
      %Put &=hx_dwh_chk_model;
      %If &hx_dwh_chk_model. ne PASSED And &forced.=N %Then %Goto uscita;
    %End;

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ------------------------------+;
	%Put | Import data from DWH                                    |;
	%Put |.........................................................|;
	%Put | Started at: &_tmpStamp.                                 |;
	%Put +---------------------------------------------------------+;
 
    %*-- Call function that import DWH Table;
	%Let _datiodd = work;
    %Let _rcImportData = %sysfunc(fx_da_import_sourcedata("&_datiodd."));

    %*-- Split return code and name of temporary table trace;
    %Let _dsTempTrace = %Qscan(%Qscan(&_rcImportData,2,[),1,]);
    %Let _rcImportData = %Qscan(&_rcImportData,1,[);

    %*-- Update process trace;
    Data _null_;
      _dsid = Open("&_dsTempTrace.");     
	  %hx_declare_ht_pr(htTable=&processTrace.);
	  sourceCode = "Data Acquisition";
	  stepCode   = "Import source table in datiodd area";
      If "&_rcImportData." = "PASSED" Then Do;
	    msgCode = catx(' ',"Imported",Put(AttrN(_dsid,"NOBS"),12.),"&dataProvider. tables");
	    rcCode  = 1;
      End;
      Else Do;
	    msgCode = "Some tables was not imported. See &tableTrace. for details";
	    rcCode  = -20020;
      End;
	  rc = ht.add();
	  rc = ht.output(dataset:"&processTrace.");
      _dsid = close(_dsid);
	Run;

    %*-- Call function that normalize data model of DWH Tables;
	Proc Datasets lib=datiwip nolist kill;
	Quit;
    %Let _rcImportData = %sysfunc(fx_da_mapping_sourcedata("datiwip","&_dsTempTrace."));

    %*-- Split return code and name of temporary table trace;
    %Let _dsTempTrace = %Qscan(%Qscan(&_rcImportData,2,[),1,]);
    %Let _rcImportData = %Qscan(&_rcImportData,1,[);

    %Put &=_dsTempTrace;
	%Put &=_rcImportData;
    %*-- Update process trace;
    Data _null_;
      _dsid = Open("&_dsTempTrace.");     
	  %hx_declare_ht_pr(htTable=&processTrace.);
	  sourceCode = "Data Acquisition";
	  stepCode   = "Mapping source table versus an standard naming convention";
      If "&_rcImportData." = "PASSED" Then Do;
	    msgCode = catx(' ',"Imported",Put(AttrN(_dsid,"NOBS"),12.),"&dataProvider. tables");
	    rcCode  = 1;
      End;
      Else Do;
	    msgCode = "Some tables was not imported. See &tableTrace. for details";
	    rcCode  = -20030;
      End;
	  rc = ht.add();
	  rc = ht.output(dataset:"&processTrace.");
      _dsid = close(_dsid);
	Run;

	%*-- Preserve on datiwip list of SAS Table was normalized;
	Data datiwip.%UnQuote(&dataProvider.)_LIST_SASTABLE_NORMALIZED;
	  Set &_dsTempTrace.;
	Run;

    %Uscita:
      %Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	  %Put +---[Macro: &sysmacroname.] ------------------------------+;
	  %Put | Import data from DWH     |;
	  %Put |.........................................................|;
	  %Put | Started at: &_tmpStamp.                                 |;
	  %Put +---------------------------------------------------------+;
%Mend;
%hx_dwh_import_data();