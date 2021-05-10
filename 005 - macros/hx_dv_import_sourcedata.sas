/*{
    "Program": "hx_dv_import_sourcedata"
	"Descrizione": "Import in datiodd source data listed in metadata npl_list",
	"Parametri": [
		"dataProvider":"Data provider"
        "LDT_wkbFolder":"Macro variable defined as project's parameter. Containing folder of LDT workbook"
        "LDT_wkbName":"Macro variable defined as project's parameter. Containing name of LDT workbook"
	],
	"Return": "dataset on datiodd libname",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note":"Macro needs to be call by an function. In addition to LDT.. paramters must be defined just for LDT provider"
}*/

%Macro  hx_dv_import_sourcedata () 
    / store secure Des = "Check for any changes on the dwh table data model" ;
	%local _dttimeStamp _dataProvider _ldtWorkbookFolder _ldtWorkBookName _nplSourceList
           _wclsClause _dsid _ldtFullName _hashDataList
	   ;
	%Let _dataProvider      = %upcase(%sysfunc(dequote(&dataProvider.)));
    %Let _ldtWorkbookFolder = ;
    %LEt _ldtWorkBookName   = ; 
    %Let _nplSourceList     = %sysfunc(dequote(&nplsourcelist.));
    %Let datiodd            = %sysfunc(dequote(&datiodd.));

    %Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] ------------------------------+;
	%Put | Import data from %UnQuote(&_dataProvider.) data provider |;
	%Put | .........................................................|;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.))    |;
	%Put +----[Macro: &sysmacroname.] ------------------------------+;

    %*-- Checks existence of two parameters in case of data provider is equal LDT;
    %If (%symexist(LDT_wkbFolder)= Or %symexist(LDT_wkbName)=0) And &_dataProvider=LDT %Then %Do;
      %log(level = E, msg = One of the two parameters - LDT_wkbName or LDT_wkbFolder - associated with the LDT provider is missing);
 	  %log(level = E, msg = Data acquisition engine will be stopped !!);

      %*-- Update Process Trace;
	  Data _null_;
	    %hx_declare_ht_pr(htTable=&processTrace.);
	    sourceCode = "Data Acquisition";
	    stepCode   = "Import data source regarding [&_dataProvider.]";
	    msgCode    = "One of the two parameters - LDT_wkbName or LDT_wkbFolder - associated with the LDT provider is missing";
	    rcCode     = -20010;
	    rc = ht.add();
	    rc = ht.output(dataset:"&processTrace.");
	  Run;
      %goto uscita;
    %End;

    %Let _wclsClause = %NrQuote(Upcase%(DataProvider%)="&_dataprovider.");  
    %If %symexist(dta_reference) %Then %Do;
      %Let _wclsClause = %NrQuote(&_wclsClause And %(DtaValid_from <= "&dta_reference."d And DtaValid_to >= "&dta_reference."d%));
    %End;
    %*-- If data provider is equal LDT then import workbook and workbook name;
    %If &_dataProvider.=LDT %Then %Do;
      %Let _ldtFullName = %UnQuote(&LDT_wkbFolder.)&slash.%UnQuote(&LDT_wkbName.);
      %If %sysfunc(fileExist(&_ldtFullName.))=0 %Then %Do;
        %log(level = E, msg = LDT Workbook [&_ldtFullName.] not exists);
        
        %*-- Update Process Trace;
	    Data _null_;
	      %hx_declare_ht_pr(htTable=&processTrace.);
	      sourceCode = "Data Acquisition";
	      stepCode   = "Import data source regarding [&_dataProvider.]";
	      msgCode    = "LDT Workbook [&_ldtFullName.] not exists";
	      rcCode     = -20015;
	      rc = ht.add();
	      rc = ht.output(dataset:"&processTrace.");
	    Run;
        %Goto uscita;
      %End;
	  %import_xlsx_sheets(%bquote(&_ldtFullName.), work, whr_clause=1);
	%End;

    %*************************************
    %*   Extract list of datasource      *  
    %*************************************
     ;
    Data _nplListDataSource; 
       Set &_nplSourceList.  (Where=(&_wclsClause.)
         %If &_dataProvider=LDT %Then %Do;
             Rename=(wkbFolder=_wkbFolder Dbcontainer=_Dbcontainer)
          %End; 
          );
      %If &_dataProvider=LDT %Then %Do;
        wkbFolder  = resolve(_wkbFolder);
        *-- Force dbcontainser at work;
        wkbName     = resolve(_Dbcontainer); 
        dbContainer = "work";
      %End; 
    Run;

    %*************************************************
    %*   Import data. Keep trace on table trace      *  
    %*************************************************
     ;
    Proc Sql noprint;
      Create Table &sysmacroname. Like &TABLETRACE.;
      Select cats("'",NAME,"'") Into :_hashDataList separated by ','
         from sashelp.vcolumn
         where libname="WORK" and memname="&sysmacroname."
         ;
    Quit;

    %Let _dsid = %sysfunc(Open(_nplListDataSource));
    %Do %While (%sysfunc(fetch(&_dsid.))=0);
      %Let _dbcontainer  = %Sysfunc(GetvarC(&_dsid.,%Sysfunc(Varnum(&_dsid.,Dbcontainer))));
      %Let _TableName    = %Sysfunc(GetvarC(&_dsid.,%Sysfunc(Varnum(&_dsid.,tableName))));
      %Let _wclsTable    = %Sysfunc(GetvarC(&_dsid.,%Sysfunc(Varnum(&_dsid.,whereClause))));
      %Let _sasTableName = %Sysfunc(GetvarC(&_dsid.,%Sysfunc(Varnum(&_dsid.,tableAlias))));
      %If &_dataProvider.=LDT %Then %Do;
        %Let _wkbName = %Sysfunc(GetvarC(&_dsid.,%Sysfunc(Varnum(&_dsid.,wkbName))));
      %End;
      %If "&_wclsTable." = "" %Then %Do;
        %Let _wclsTable = 1;
      %End;     

      %*-- Write data on datiodd;
      Data %UnQuote(&datiodd.).&_sasTableName.;
		%if %symexist(idTrasaction) %then %do;
			Attrib idTransaction Length=$30 label="Id. transanction";
			Retain idTransaction "&idTrasaction.";
		%end;
			Attrib dbContainer Length=$256
                   tableName   Length=$100
					 ;
          %If &_dataProvider.=DWH %Then %Do;
			Retain dbContainer "&_Dbcontainer." tableName "&_TableName.";
          %End;
          %Else %Do;
            Retain dbContainer "&_wkbName." tableName "&_TableName.";
          %End;
		Attrib idRecord Length=8 label="Id. record";
        %If &_dataProvider.=DWH %Then %Do;
		  Set %UnQuote(&_dbcontainer.).%UnQuote(&_TableName.) (Where=(&_wclsTable.))
        %End;
        %Else %Do;
		  Set %UnQuote(&_dbcontainer.)."%sysfunc(strip(&_TableName.))"n (Where=(&_wclsTable.))
        %End;
		;
		idRecord = _N_;
      Run;
      %*-- Trace results;
      Data _null_;
        %hx_cmn_attrib_from_ds(dsname=&TABLETRACE.);
        Declare hash ht(dataset:"&sysmacroname.");
          ht.defineKey("libname","tableName");
          ht.defineData(&_hashDataList.);
          ht.defineDone();
        libname       = "&datiodd.";
        tableName     = lowcase("&_sasTableName.");
        timeStamp     = &_dttimeStamp.;
        idTransaction = "&idTrasaction.";
        %if %symexist(cod_ist) %then %do;
          cod_ist       = &cod_ist.;
        %end;
        dataProvider  = "&_dataprovider.";
        phase         = "Extraction";
        if exist(catx('.',libname,tablename)) Then Do;
          _dsid     = open(catx('.',libname,tablename));
          dtaCreate = attrn(_dsid,"CRDTE");
          recNo     = attrn(_dsid,"NOBS");
          varsNo    = attrn(_dsid,"NVARS");
        end;
        ht.add();
        ht.output(dataset:"&sysmacroname.");
      Run;
    %End;
    %Let _dsid = %sysfunc(close(&_dsid.));
    Proc Append data=&sysmacroname. base=&tableTrace.;
    Run;

    %Uscita:
      %Let _dttimeStamp  = %sysfunc(datetime());
	  %Put +----[Macro: &sysmacroname.] ------------------------------+;
	  %Put | Import data from %UnQuote(&_dataProvider.) data provider |;
	  %Put | .........................................................|;
	  %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.))    |;
	  %Put +----[Macro: &sysmacroname.] ------------------------------+;
%Mend;
/*
option mprint;
%Let datiodd = work;
%Let dataProvider = LDT;
%Let LDT_wkbFolder = %UnQuote(&projectFolder.)&slash.01_sourcedata\Django;
%Let LDT_wkbName   = %NrQuote(2.2_Prj. Django - LDT_v.200710- Mapping_FROZEN.xlsx);
%hx_dv_import_sourcedata();
*/
    

