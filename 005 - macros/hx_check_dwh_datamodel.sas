/*{
    "Program": "hx_check_dwh_datamodel"
	"Descrizione": "Check for any changes on the dwh table data model",
	"Parametri": [
		"datamapping: standard data dictionary containg list of fields in input at dataverification engine"
	],
	"Return": "List of changes",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
}*/

Macro hx_check_dwh_datamodel (datamapping=prvmeta.dwh_data_model_raccordo,_dwhLibname=DATIODD) / Des = "Check for any changes on the dwh table data model";
	%local _dttimeStamp _dsOutCheckDM
	   ;
	%Let _dttimeStamp  = %sysfunc(datetime());
	%Let _dsOutCheckDM = work.%UnQuote(&_dwhLibname.)_datamodel;

	%Put +----[Macro: &sysmacroname.] -----------------------+;
	%Put | Check for any changes on the dwh table data model |;
	%Put | ................................................. |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] -----------------------+;

	Ods results off;
	Proc Datasets lib=&_dwhLibname. mt=data nolist;
	  contents data=_all_ out=&_dsOutCheckDM.;
	Run;
    Data &_dsOutCheckDM.; 
	  Attrib dsDwhTable   Length=$80 label="DWH Table Name";
	  Set &_dsOutCheckDM.;
	  Drop _:;
	  _count = count(memname,'_');
	  %*- Delete numeric component on table name;
	  Call Missing(dsDwhTable);  
	  Do _i= To _count;
	    dsDwhTable = catx('_',dsDwhTable,scan(memname,_i,'_'));
	  run;
    Run;

	Data _null_;
	  Attrib dsDwhTable   Length=$80 label="DWH Data Model"
	         dataMapping  Length=$80 label="DWH Data Mapping"
			 dwhFieldName Length=$80 label="DWH Field Name"
			 dwhFieldType Length=$20 label="DWH Field Type"
			 dmFieldName  Length=$80 label="Data Mapping field original name"
			 dmFieldType  Length=$80 label="Data Mapping field original type"
			 dmFieldNew   Length=$1  label="Field is new?"
			 dmFieldSameT Length=$1  label="Has same type?"
			 dmFieldExist Length=$1  label="Field exists again?"
			 dmFieldInDV  Length=$1  label="Field is used in data quality engine?"
        ;
	  Retain dataMapping "&datamapping.";
	  _dsid = open("&_dsOutCheckDM.");
	  Do While (fetch(_dsid)=0);
	    dsDwhTable   = GetvarC(_dsid,varnum(_dsid,""));
		dwhFieldName = GetvarC(_dsid,varnum(_dsid,""));
		dwhFieldType = ifc(GetvarN(_dsid,varnum(_dsid,"TYPE"))=1
		                   ,"Num(8)"
						   ,cats("Char("put(GetvarN(_dsid,varnum(_dsid,"LENGTH")),"12)"))
		                  );
		Put dsDwhTable= dwhFieldName= dwhFieldType=;
	  End;
	  _dsid = Close(_dsid);
	Run;
%Mend;
%hx_check_dwh_datamodel();





