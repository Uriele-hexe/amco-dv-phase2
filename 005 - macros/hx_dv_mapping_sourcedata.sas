/*{
    "Program": "hx_dv_mapping_sourcedata"
	"Descrizione": "Mapping the fields of the imported DWH table against a standard name. Macro use dataset about prelimnary checks on datamodel",
	"Parametri": [
		"dataMapping":"Mapping table. Metadata containing rename fields",
        "_dsOutCheckDM":"Dataset in output at program dwh_005_data_acquisition_check_model.sas"
        "_dataImport":"List of table imported by DWH"
	],
	"Return": ["dataset on datiodd libname",
               "dataset on datichk named dwh_deleted_field_mapping containing list of deleted fields
               ],
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note":"Macro needs to be call by an function."
}*/

%Macro  hx_dv_mapping_sourcedata () / 
  store secure Des = "Check for any changes on the dwh table data model";
	%local _dttimeStamp _dataProvider _dataMapping _dmMapping _dataImport _dsimp
	   ;
	%Let _dataProvider = %upcase(%sysfunc(dequote(&dataProvider.)));
    %Let _dataMapping  = %sysfunc(dequote(&DSMETARACC.));
    %Let _dsOutCheckDM = datichk.%UnQuote(&_dataProvider.)_DM_PRELIMNARY_CHECKS;
    %Let _dataImport   = %sysfunc(dequote(&dataImported.));
    %Let _datiwip      = %sysfunc(dequote(&datiwip.));

    %Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] ------------------------------+;
	%Put | Mapping data regarding %UnQuote(&_dataProvider.)         |;
	%Put | Data Mapping  : &_dataMapping.                           |;
	%Put | Data Imported : &_dataImport.                            |;
	%Put | .........................................................|;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.))    |;
	%Put +----[Macro: &sysmacroname.] ------------------------------+;

    *-- STEP 1: Marks deleted fields on table mapping (raccordo);
    %Let _dmMapping=;
    Proc Contents data=&_dataMapping. noprint out=dmMapping (Keep=NAME);
    Run;
    Proc Sql NoPrint;
      Select NAME Into :_dmMapping separated by ' ' from dmMapping;
    Quit;
    Data work._raccordo_table (Where=(flgDelete='N')
                           Keep=&_dmMapping. dwhSasTable idVarname flgDelete )
         work.%UnQuote(&_dataProvider)_deleted_field_mapping
           (Where=(flgDelete='Y')
             Keep=&_dmMapping. dwhSasTable flgDelete)
         ; 
         Set &_dataMapping. &_dsOutCheckDM. (obs=0);
      Attrib flgDelete Length=$1
             idVarname Length=$32;
      If _N_=1 Then Do;
        Declare hash htchk(dataset:"&_dsOutCheckDM.",ordered:"yes");
          htchk.defineKey("dwhTable","dwhNomeCampo");
          htchk.defineData("dwhSasTable","dwhFieldNew");
          htchk.defineDone();
      End;
      Call Missing(flgDelete,dwhSasTable,dwhFieldNew);
      if htchk.find(key:tableName,key:lowcase(columnName))=0 then Do;
        *-- If source column not exists or final column name is not valid then field will be deleted;
        flgDelete = ifc(dwhFieldNew^='D' and nvalid(columnTarget,"V7") ,'N','Y');
        if flgDelete='Y' then do;
          put "+---------------------------------------------------";
          put "| Delete: " columnName "On " tableName;
          put "+---------------------------------------------------";
        end;
        if flgRaccordo='N' then do;
          columnTargetType = columnSourceType;
          columnTargetLen  = columnSourceLen;
          columnTargetFmt  = columnSourceFmt; 
        end;
        idVarname = cats('_V',put(idColumn,Z30.));
        colRuleTransform = ifc(missing(colRuleTransform),idVarname
                                                        ,prxchange(cats("s/<columnSource>/",idVarname,'/'),-1,colRuleTransform)
                            );
        columnTargetFmt = ifc(missing(columnTargetFmt),"_ND_",columnTargetFmt);
      end;
      %if %symExist(dta_reference) %Then %Do;
        if dtaValid_from<="&dta_reference."d And dtaValid_to>="&dta_reference."d then output;
      %end;
    Run;
    %*-- One input field can be used to create two new variables. For this reason next step creates a distinct;
    Proc Sort data=_raccordo_table (Where=(flgDelete='N'))
               out=_list_of_input_field (Keep=dwhSasTable columnName idVarname)
               nodupkey;
      by dwhSasTable columnName;
    Run;

    %*-- Preserve mapping;
    Data datitrc.%UnQuote(&_dataProvider.)_MAPPING_HISTORY;
      Attrib idTransaction Length=$25
             idRecord      Length=8
            ;
      Set work._raccordo_table work.%UnQuote(&_dataProvider)_deleted_field_mapping;
      Retain idTransaction "&idTrasaction";
      idRecord = _N_;
    Run;

    %*************************************************
    %*   Mapping data. Keep trace on table trace      *  
    %*************************************************
     ;
    Proc Sql noprint;
      Create Table &sysmacroname. Like &TABLETRACE.;
      Select cats("'",NAME,"'") Into :_hashDataList separated by ','
         from sashelp.vcolumn
         where libname="WORK" and memname="&sysmacroname."
         ;
    Quit;

    *-- STEP2: Creates temporary code to normalize input fields;
	%Let _dsimp = %sysfunc(open(&_dataImport.));
    %Do %While (%sysfunc(fetch(&_dsimp.))=0);     
	  %Let _dwhSasTable = %Sysfunc(GetvarC(&_dsimp.,%Sysfunc(Varnum(&_dsimp.,tableName))));
	  %Let _libSasTable = %Sysfunc(GetvarC(&_dsimp.,%Sysfunc(Varnum(&_dsimp.,libname))));

	  Data %UnQuote(&_datiwip.).%UnQuote(&_dwhSasTable.) (Drop=_V:);
	    Set %UnQuote(&_libSasTable.).%UnQuote(&_dwhSasTable.)
		  (Rename=(
	    %Let _dsKeep = %Sysfunc(Open(_list_of_input_field (Where=(Upcase(dwhSasTable)="%Upcase(&_dwhSasTable.)"))));
	    %Do %While (%sysfunc(fetch(&_dsKeep.))=0);
	      %Let _dwhColName = %Sysfunc(GetvarC(&_dsKeep.,%Sysfunc(Varnum(&_dsKeep.,columnName))));
	  	  %Let _idColumn   = %Sysfunc(GetvarC(&_dsKeep.,%Sysfunc(Varnum(&_dsKeep.,idVarname))));
		  %UnQuote(&_dwhColName.)=%UnQuote(&_idColumn.)
	    %End;
	    ));
	    %Let _dsKeep = %Sysfunc(Close(&_dsKeep.));

        %*-- Statment Attrib;
        %Let _dsMapp = %Sysfunc(Open(_raccordo_table (Where=(flgDelete='N' And Upcase(dwhSasTable)="%Upcase(&_dwhSasTable.)"))));
	    %Do %While (%sysfunc(fetch(&_dsMapp.))=0);
          %Let _columnTarget  = %Sysfunc(GetvarC(&_dsMapp.,%Sysfunc(Varnum(&_dsMapp.,columnTarget))));
          %Let _dwhColName    = %Sysfunc(GetvarC(&_dsMapp.,%Sysfunc(Varnum(&_dsMapp.,columnName))));
          %Let _colTargetType = %Sysfunc(GetvarC(&_dsMapp.,%Sysfunc(Varnum(&_dsMapp.,columnTargetType))));
          %Let _colTargetLen  = %Sysfunc(GetvarN(&_dsMapp.,%Sysfunc(Varnum(&_dsMapp.,columnTargetLen))));
          %Let _colTargetFmt  = %Sysfunc(GetvarC(&_dsMapp.,%Sysfunc(Varnum(&_dsMapp.,columnTargetFmt))));
          %If %lowcase(&_colTargetType.)=num %then %Let _colTargetType=;
          %Else %Let _colTargetType=$;
          Attrib %UnQuote(&_columnTarget.) Length=%UnQuote(&_colTargetType.)%UnQuote(&_colTargetLen.)
                                           Label ="Derived from: &_dwhColName" 
                                %if "&_colTargetFmt." ne "_ND_" %then %do;
                                  format=&_colTargetFmt.
                                %End;
                             ; 
        %End;

        %*-- Creates new variables;
        %Let rc = %Sysfunc(rewind(&_dsMapp.));
	    %Do %While (%sysfunc(fetch(&_dsMapp.))=0);
          %Let _columnTarget = %Sysfunc(GetvarC(&_dsMapp.,%Sysfunc(Varnum(&_dsMapp.,columnTarget))));
          %Let _columnRule   = %Sysfunc(GetvarC(&_dsMapp.,%Sysfunc(Varnum(&_dsMapp.,colRuleTransform))));
          %UnQuote(&_columnTarget.) = %UnQuote(&_columnRule.);
        %End;
        %Let _dsMapp = %Sysfunc(Close(&_dsMapp.));
	  Run;
      %*************************************************
      %*   Mapping data. Update trace
      %*************************************************
       ;

      Data _null_;
        %hx_cmn_attrib_from_ds(dsname=&TABLETRACE.);
        Declare hash ht(dataset:"&sysmacroname.");
          ht.defineKey("libname","tableName");
          ht.defineData(&_hashDataList.);
          ht.defineDone();

        libname       = "&_datiwip.";
        tableName     = lowcase("&_dwhSasTable.");
        timeStamp     = &_dttimeStamp.;
        idTransaction = "&idTrasaction.";
        %if %symexist(cod_ist) %then %do;
          cod_ist       = &cod_ist.;
        %end;
        dataProvider  = "&_dataprovider.";
        phase         = "Mapping";
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
	%Let _dsimp = %sysfunc(close(&_dsimp.));

    Proc Append data=&sysmacroname. base=&tableTrace.;
    Run;

    %Uscita:
      %Let _dttimeStamp  = %sysfunc(datetime());
	  %Put +----[Macro: &sysmacroname.] ------------------------------+;
	  %Put | Mapping data regarding %UnQuote(&_dataProvider.)         |;
	  %Put | Data Mapping : &_dataMapping.                             |;
	  %Put | .........................................................|;
	  %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.))    |;
	  %Put +----[Macro: &sysmacroname.] ------------------------------+;
%Mend;
/*
Option mprint source2;
%Let dataImported = hx_dv_import_sourcedata;
Libname datiwip "d:\DataQuality\99 - rrhh\Uriele\DWH";
%Let datiwip = datiwip;
%hx_dv_mapping_sourcedata();
*/








