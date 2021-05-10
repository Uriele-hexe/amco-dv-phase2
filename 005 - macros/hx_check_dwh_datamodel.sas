/*{
    "Program": "hx_check_dwh_datamodel"
	"Descrizione": "Check for any changes on the dwh table data model",
	"Parametri": [
		"datamapping":"standard data dictionary containg list of fields in input at dataverification engine"
		"dwhlibname":"libname on which get contents of all SAS data sets " 	 
		"listdwhtable":"list of DWH tables to be imported"
		"dsChecksList":"List of checks"
	],
	"Return": "dataset named: work.hx_check_dwh_datamodel",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
}*/

/*%Macro hx_check_dwh_datamodel (datamapping=prvmeta.dwh_data_model_raccordo
							   ,dsChecksList=&dsDWHMetaChecks.
							   ,listdwhtable=metadata.npl_sourcedata_list) 
				/ Des = "Check for any changes on the dwh table data model";
				*/
%Macro  hx_check_dwh_datamodel () /
   Store Secure Des = "Check for any changes on the dwh table data model";
	%local _dttimeStamp 
	   ;
	%Let datamapping  = %sysfunc(dequote(&dsMetaRacc.));
    %Let dsChecksList = %sysfunc(dequote(&dsDWHMetaChecks.));
	%Let listdwhtable = %sysfunc(dequote(&nplsourcelist.));

	%Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] -----------------------+;
	%Put | Check for any changes on the dwh table data model |;
	%Put | ................................................. |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] -----------------------+;

    %*-- Retrieves contents from any table regarding data verification engine ;
	Data _null_;
	  Attrib dwhTable     Length=$80 Label="DWH Table Name"
	         dwhSasTable  Length=$80 Label="SAS Table Name"
			 idVarnum     Length=8	 Label="Id DWH column"
	         dwhNomeCampo Length=$80 Label="Varname on DWH Table"
			 dwhTypeCampo Length=$80 Label="Vartype on DWH Table"
			 ntable       Length=8  
			 ;
	   Declare hash ht();
	     ht.defineKey("dwhSasTable","idVarnum");
		 ht.defineData("dwhSasTable","dwhTable","idVarnum","dwhNomeCampo","dwhTypeCampo");
		 ht.defineDone();

       Call Missing(ntable);
       dslist = Open("&listdwhtable. (Where=(dataProvider='DWH'))");
	   Do While (Fetch(dslist)=0);
	     dwhTable    = GetvarC(dslist,Varnum(dslist,"tableName"));
		 dwhSasTable = GetvarC(dslist,Varnum(dslist,"tableAlias"));
		 ntable      = Sum(ntable,1);
		 dsid        = open(catx('.',"dwh_core",dwhTable));
		 *--Put dwhSasTable= dsid=;
		 If dsid>0 Then Do;
		   Do idVarnum=1 To Attrn(dsid,"NVARS");
		     dwhNomeCampo = varname(dsid,idVarnum);
			 dwhTypeCampo = ifc(vartype(dsid,idVarnum)=:'C'
			                    ,cats("char(",put(varlen(dsid,idVarnum),12.),')')
								,"num(8)"
								);
			 rc = ht.add();
		   End;
		 End;
	   End;
	   dslist = Close(dslist);
       ht.output(dataset:"work.dwhdatamodel");
	Run;

	%*-- Check eventually changement on data model ;
	%*-- New Field and change on data type and deleted fields;
	Data _null_;
	  Attrib check_direction Length=$40 label="Direction data model check"
	         idRecord        Length=8   label="Primary key"
	         dwhTable        Length=$80 label="DWH Table Name"
	         dwhSasTable     Length=$80 label="Datiodd SAS Name"
	         dataMapping     Length=$80 label="DWH Data Mapping"
			 dwhNomeCampo    Length=$80 label="DWH Field Name"
			 dwhTypeCampo    Length=$20 label="DWH Field Type"
			 dmFieldName     Length=$80 label="Data Mapping field original name"
			 dmFieldType     Length=$80 label="Data Mapping field original type"
			 dwhFieldNew     Length=$1  label="Field is new?"
			 dmFieldSameT    Length=$1  label="Has same type?"
			 dmFieldExist    Length=$1  label="Field exists again?"
			 dmFieldInDV     Length=$1  label="Field is used in data quality engine?"
			 _dsWhere       Length=$255
        ;
	  Retain dataMapping "&datamapping." idRecord 0;

      Declare hash htout();
	    htout.defineKey("dwhSasTable","dwhNomeCampo");
		htout.defineData("check_direction","idRecord","dwhTable","dwhSasTable"
		                 ,"dwhNomeCampo","dwhTypeCampo","dwhFieldNew"
						 ,"dmFieldType","dmFieldSameT");
		htout.defineDone();

	  check_direction = "DWH -> DATA MAPPING";
	  _dsid           = open("work.dwhdatamodel");
	  Do While (fetch(_dsid)=0);
	    dwhTable     = GetvarC(_dsid,varnum(_dsid,"dwhTable"));
		dwhSasTable  = GetvarC(_dsid,varnum(_dsid,"dwhSasTable"));
		dwhNomeCampo = GetvarC(_dsid,varnum(_dsid,"dwhNomeCampo"));
		dwhTypeCampo = GetvarC(_dsid,varnum(_dsid,"dwhTypeCampo"));

        *-- Find field in data mapping;
  	    _dsWhere = cats("Upcase(tableName)='",Upcase(dwhTable),"' And Upcase(columnName)='",Upcase(dwhNomeCampo),"'))");
		_dsid2      = open(catx(' ',dataMapping,"(Where=(",_dsWhere,"))"));
		_fetch      = fetch(_dsid2);
		%*-- Check if field is new Y = new N = already defined;
		dwhFieldNew = ifc(_fetch=0,'N','Y');
		Call Missing(dmFieldType,dmFieldSameT);
		%*-- If already defined, checks eventually changement on data type;
		If dwhFieldNew='N' Then Do;
		  If Getvarc(_dsid2,varnum(_dsid2,"flgRaccordo"))='N' Then Do;
		    dmFieldType = Lowcase(Getvarc(_dsid2,Varnum(_dsid2,"columnSourceType")));
		    dmFieldType = cats(dmFieldType,'(',GetvarN(_dsid2,Varnum(_dsid2,"columnSourceLen")),')');
		  End;
		  Else Do;
		    dmFieldType = Lowcase(Getvarc(_dsid2,Varnum(_dsid2,"columnTargetType")));
			dmFieldType = cats(dmFieldType,'(',GetvarN(_dsid2,Varnum(_dsid2,"columnTargetLen")),')');
		  End;
		  dmFieldSameT = ifc(strip(dwhTypeCampo)=strip(dmFieldType),'Y','N');
		End;
		_dsid2   = Close(_dsid2);
		idRecord = sum(idRecord,1);
		_rc      = htout.add();
	  End;
	  _dsid  = Close(_dsid);

	  %*-- Starting from data mapping lookup for fields has been deleted;
	  Call Missing(dwhNomeCampo,dwhFieldType,dmFieldType,dmFieldSameT);
	  check_direction = "DATA MAPPING -> DWH";
	  _dsid = open(dataMapping);
	  Do While (fetch(_dsid)=0);
	    dwhTable    = Getvarc(_dsid,Varnum(_dsid,"tableName"));
		dmFieldName = Getvarc(_dsid,Varnum(_dsid,"columnName"));
		
        %*-- Get dwhSasTable name;
	    _dsWhere = cats("Upcase(dwhTable)='",Upcase(dwhTable),"'");
	    _dsid2   = open(catx(' ',"work.dwhdatamodel (Where=(",_dsWhere,"))"));
        If fetch(_dsid2)=0 Then dwhSasTable = GetvarC(_dsid2,Varnum(_dsid2,"dwhSasTable"));
		_dsid2 = Close(_dsid2);

		%*-- Checks if field in metadata was deleted;
	    _dsWhere = cats("Upcase(dwhTable)='",Upcase(dwhTable),"' And Upcase(dwhNomeCampo)='",Upcase(dmFieldName),"'))");
	    _dsid2      = open(catx(' ',"work.dwhdatamodel (Where=(",_dsWhere,"))"));
		dwhFieldNew = ifc(fetch(_dsid2)=0,'N','D');
    	If dwhFieldNew='D' Then do;
		  dwhNomeCampo = strip(dmFieldName);
  		  idRecord     = sum(idRecord,1);
		  _rc = htout.add();
		End;
		_dsid2 = close(_dsid2);
	  End;
	  _dsid = Close(_dsid);
	  _rcout = htout.output(dataset:"work.&sysmacroname.");
	Run;

    %*-- Check on Campi Tecnici And perimeter;
	Data work.&sysmacroname.; Set work.&sysmacroname.;
	  Attrib isInTechnical Length=$1  Label="Is an technical field?"
	         isInPerimeter Length=$1  Label="Is an perimeter field?"
			 idRule        Length=$20 Label="Id Rule"
			 fxName        Length=$40 Label="Function Name"
			;
	   Drop _:;
	   Call Missing(idRule,fxName,isInTechnical,isInPerimeter);
	   If dwhFieldNew='D' Or (dwhFieldNew='N' And dmFieldSameT='N') Then Do;
         _dsid = Open("&dsChecksList.");
	     isInTechnical = 'N';
	     isInPerimeter = 'N';
	     Do While (fetch(_dsid)=0 And (isInTechnical='N' And isInPerimeter='N'));
           _ct    = GetvarC(_dsid,Varnum(_dsid,"Campi_Tecnici"));
           _per   = GetvarC(_dsid,Varnum(_dsid,"Perimetro_di_applicabilita"));
		   isInTechnical  = ifc(prxmatch(cats("/",dwhNomeCampo,"/i"),_per)>0,'Y','N');
           isInPerimeter   = ifc(prxmatch(cats("/",dwhNomeCampo,"/i"),_ct)>0,'Y','N');	
		   If  isInTechnical='Y' Or isInPerimeter='Y' Then Do;
             fxName = GetvarC(_dsid,Varnum(_dsid,"Nome_Funzione"));
		     idRule = GetvarC(_dsid,Varnum(_dsid,"idRule"));
		   End;
	     End;
	     _dsid = Close(_dsid);
	   End;
	Run;

	%Uscita:
	  %Let _dttimeStamp  = %sysfunc(datetime());
	  %Put +----[Macro: &sysmacroname.] -----------------------+;
	  %Put | Check for any changes on the dwh table data model |;
	  %Put | ................................................. |;
	  %Put | Ended at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	  %Put +----[Macro: &sysmacroname.] -----------------------+;

%Mend;
/*%hx_check_dwh_datamodel();*/





