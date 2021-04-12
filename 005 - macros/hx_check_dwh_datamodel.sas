/*{
    "Program": "hx_check_dwh_datamodel"
	"Descrizione": "Check for any changes on the dwh table data model",
	"Parametri": [
		"datamapping":"standard data dictionary containg list of fields in input at dataverification engine"
		"dwhlibname":"libname on which get contents of all SAS data sets " 	 
		"listdwhtable":"list of DWH tables to be imported"
	],
	"Return": "dataset named: work.hx_check_dwh_datamodel",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
}*/

%Macro hx_check_dwh_datamodel (datamapping=prvmeta.dwh_data_model_raccordo
                               ,_dwhLibname=DATIODD
							   ,listdwhtable=metadata.npl_sourcedata_list) 
				/ Des = "Check for any changes on the dwh table data model";
	%local _dttimeStamp _dsOutCheckDM
	   ;
	%Let _dsOutCheckDM = work.%UnQuote(&_dwhLibname.)_datamodel;

	%Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] -----------------------+;
	%Put | Check for any changes on the dwh table data model |;
	%Put | ................................................. |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] -----------------------+;

	Ods results off;
	Proc Datasets lib=&_dwhLibname. mt=data nolist;
	  contents data=_all_ out=&_dsOutCheckDM.;
	Run;

    Data &_dsOutCheckDM. (Drop=_:); 
	  Attrib dsDwhTable   Length=$80 label="DWH Table Name";
	  Set &_dsOutCheckDM. (Where=(Lowcase(name) not in ("idtransaction","idrecord","tablename","dbcontainer")
	                       ));
	  _count = count(memname,'_');
	  %*--- Delete numeric component on table name;
	  Call Missing(dsDwhTable);  
	  Do _i=1 To _count;
	    dsDwhTable = catx('_',dsDwhTable,scan(memname,_i,'_'));
	  End;
    Run;

	Data _null_;
	  Attrib check_direction Length=$40 label="Direction data model check"
	         idRecord        Length=8   label="Primary key"
	         tableName       Length=$80 label="DWH Table Name"
	         dsDwhTable      Length=$80 label="Datiodd SAS Name"
	         dataMapping     Length=$80 label="DWH Data Mapping"
			 dwhFieldName    Length=$80 label="DWH Field Name"
			 dwhFieldType    Length=$20 label="DWH Field Type"
			 dmFieldName     Length=$80 label="Data Mapping field original name"
			 dmFieldType     Length=$80 label="Data Mapping field original type"
			 dwhFieldNew     Length=$1  label="Field is new?"
			 dmFieldSameT    Length=$1  label="Has same type?"
			 dmFieldExist    Length=$1  label="Field exists again?"
			 dmFieldInDV     Length=$1  label="Field is used in data quality engine?"
			 _dsWhere       Length=$255
        ;
	  Retain dataMapping "&datamapping." idRecord 0;
	  Length tableAlias tableName $80
	      ;
	  Declare hash ht(dataset:"&listdwhtable. (Where=(dataProvider='DWH'))",ordered:'yes');
	    ht.defineKey("tableAlias");
		ht.defineData("tableName");
		ht.defineDone();

      Declare hash htout();
	    htout.defineKey("dsDwhTable","dwhFieldName");
		htout.defineData("check_direction","idRecord","tableName","dsDwhTable","dwhFieldName","dwhFieldType","dwhFieldNew","dmFieldType","dmFieldSameT");
		htout.defineDone();

	  check_direction = "DWH -> DATA MAPPING";
	  _dsid = open("&_dsOutCheckDM.");
	  Do While (fetch(_dsid)=0);
	    dsDwhTable   = GetvarC(_dsid,varnum(_dsid,"dsDwhTable"));
		Call Missing(tableName);
		If ht.find(key:dsDwhTable)=0 Then Do;
     	  dwhFieldName = GetvarC(_dsid,varnum(_dsid,"NAME"));
		  dwhFieldType = ifc(GetvarN(_dsid,varnum(_dsid,"TYPE"))=1
		                     ,"num(8)"
			   			     ,cats("char(",put(GetvarN(_dsid,varnum(_dsid,"LENGTH")),12.),')')
		                    );
		  _dsWhere = cats("Upcase(tableName)='",Upcase(tableName),"' And Upcase(columnName)='",Upcase(dwhFieldName),"'))");
		  _dsid2      = open(catx(' ',dataMapping,"(Where=(",_dsWhere,"))"));
		  _fetch      = fetch(_dsid2);
		  dwhFieldNew = ifc(_fetch=0,'N','Y');
		  Call Missing(dmFieldType,dmFieldSameT);
		  If dwhFieldNew='N' Then Do;
		    If Getvarc(_dsid2,varnum(_dsid2,"flgRaccordo"))='N' Then Do;
		      dmFieldType = Lowcase(Getvarc(_dsid2,Varnum(_dsid2,"columnSourceType")));
			  dmFieldType = cats(dmFieldType,'(',GetvarN(_dsid2,Varnum(_dsid2,"columnSourceLen")),')');
			End;
			Else Do;
		      dmFieldType = Lowcase(Getvarc(_dsid2,Varnum(_dsid2,"columnTargetType")));
			  dmFieldType = cats(dmFieldType,'(',GetvarN(_dsid2,Varnum(_dsid2,"columnTargetLen")),')');
			End;
			dmFieldSameT = ifc(dwhFieldType=dmFieldType,'Y','N');
		  End;
		  _dsid2      = Close(_dsid2);
		  idRecord    = sum(idRecord,1);
		  _rc         = htout.add();
		End;
	  End;
	  _dsid  = Close(_dsid);

	  %*-- Starting from data mapping lookup for fields has been deleted;
	  Call Missing(dwhFieldName,dwhFieldType,dmFieldType,dmFieldSameT);
	  check_direction = "DATA MAPPING -> DWH";
	  Declare hash ht2(dataset:"&listdwhtable. (Rename=(tableAlias=dsDwhTable) Where=(dataProvider='DWH'))",ordered:'yes');
	    ht2.defineKey("tableName");
		ht2.defineData("dsDwhTable");
		ht2.defineDone();

	  _dsid = open(dataMapping);
	  Do While (fetch(_dsid)=0);
	    tableName   = Getvarc(_dsid,Varnum(_dsid,"tableName"));
		dmFieldName = Getvarc(_dsid,Varnum(_dsid,"columnName"));
		Call Missing(dsDwhTable);
		_rcFind = ht2.find(key:tableName);
		%*-- Check if field in data mappin has been deleted;
	    _dsWhere = cats("Upcase(dsDwhTable)='",Upcase(dsDwhTable),"' And Upcase(name)='",Upcase(dmFieldName),"'))");
	    _dsid2      = open(catx(' ',dataMapping,"(Where=(",_dsWhere,"))"));
		dwhFieldNew = ifc(fetch(_dsid2)=0,'N','D');
		If dwhFieldNew='D' Then do;
		  dwhFieldName = strip(dmFieldName);
  		  idRecord     = sum(idRecord,1);
		  _rc = htout.add();
		End;
	  End;
	  _dsid = Close(_dsid);
	  _rcout = htout.output(dataset:"work.&sysmacroname.");
	Run;
	%Uscita:
	  %Let _dttimeStamp  = %sysfunc(datetime());
	  %Put +----[Macro: &sysmacroname.] -----------------------+;
	  %Put | Check for any changes on the dwh table data model |;
	  %Put | ................................................. |;
	  %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	  %Put +----[Macro: &sysmacroname.] -----------------------+;

%Mend;
%hx_check_dwh_datamodel();





