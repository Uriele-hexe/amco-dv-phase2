/*{
    "Program": "hx_check_dwh_datamodel_report"
   	"Descrizione": "Produce a summary reports. It will be send by mail-address",
	  "Parametri": [
		   "dsDMchecked":"Output macro hx_check_dwh_datamodel"
	  ],
	  "Return": "Output in pdf format and mail",
	  "Autore": "Hexe S.p.A.",
	  "Sito web": "<http://www.hexeitalia.com>",
	  "Email": "<info@hexeitalia.com>",
	  "Manutentori": [ "Hexe S.p.A." ]
}*/

%Macro hx_check_dwh_datamodel_report (dsDMchecked=work.hx_check_dwh_datamodel) 
           / Store secure Des="Print results about checks on DWH Data Model";

  %local _dttimeStamp _tableStyle
	   ;

  %Let _dttimeStamp  = %sysfunc(datetime());
	%Put +----[Macro: &sysmacroname.] ------------------------------------------------+;
	%Put | Prints the results of the impacts related to changes in the DWH data model |;
	%Put | .......................................................................... |;
	%Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	%Put +----[Macro: &sysmacroname.] ------------------------------------------------+;

  %*-- Prepare data for report;
  Proc Sql;
    Create Table _checksForPrint As
      Select dwhTable
	           ,dwhNomeCampo 
             ,idRule
             ,fxName
			       ,isInPerimeter
			       ,isInTechnical
             ,dmFieldType
             ,dwhTypeCampo
		         ,case 
		            when (dwhFieldNew='D') then "Field was deleted from DWH"
			          when (dwhFieldNew='N' And dmFieldSameT='N') then "Field has an different type"
			        end as reason length=80
              ,dwhFieldNew
	   From &dsDMchecked.
     Where dwhFieldNew='D' Or (dwhFieldNew='N' And dmFieldSameT='N')
	   Order by 1,2
	    ;
     Create Table _listTables As
        Select dwhFieldNew 
               ,dwhTable
               ,count(dwhNomeCampo) as nrec
         From _checksForPrint
         Group By 1,2
         ;
  Quit;

  %*-- Produce Report;
  %Let _tableStyle       = %NrQuote(width=100% frame=box bordercolor=#330000 background=#000066 BorderWidth=0 cellspacing=2 cellPadding=2 just=left);
  %Let _tableTitleStyle  = %NrQuote(font_face=arial font_style=roman font_size=10pt color=#ffffff font_weight=bold background=#000066 vjust=center cellwidth=12% cellspacing=2 cellPadding=2);
  %Let _tableBodyStyle   = %NrQuote(font_face=arial font_style=roman font_size=8pt color=#ffffff font_weight=bold background=#330000 vjust=center cellspacing=2 cellPadding=2);
  %Let _reportTitleStyle = %NrQuote(font_face=arial font_style=roman font_size=12pt color=#000066 font_weight=bold background=#ffffff vjust=center cellspacing=2 cellPadding=2);
  Data _null_;
    Length _wclsChange _wclsDetail $255;
    Declare odsout objOds();
    %*-- Define Table titles;

    objOds.table_start();
      %*-- Print report regarding change on data type;
      _wclsChange = "dwhFieldNew ^= 'D'";
      _dsT = open(cats("_listTables (where=(",_wclsChange,"))"));
      Put _wclsChange=;
	    Link HeaderTable;
      Link faiReport;
      _dsT = Close(_dsT);
    objOds.table_end();
	  objOds.table_start();
      %*-- Print report regarding change on data type;
      _wclsChange = "dwhFieldNew = 'D'";
      _dsT = open(catx(' ',"_listTables (where=(",_wclsChange,"))"));
	    Link HeaderTable_1;
      Link faiReport;
      _dsT = Close(_dsT);
    objOds.table_end();
    Return;

    HEADERTABLE:
      objOds.head_start();
      objOds.row_start();
        objOds.format_cell(data:"Report di dettaglio relativo per i campi con data type diverso"
                          ,overrides:"&_reportTitleStyle."
                          ,column_span:8);
      objOds.row_end();

      objOds.row_start();
   		  objOds.format_cell(data:"DWH Table"
                          ,overrides:"&_tableTitleStyle.");
        objOds.format_cell(data:"Varname"
                          ,overrides:"&_tableTitleStyle.");
	      objOds.format_cell(data:"Id. Rule"
                           ,overrides:"&_tableTitleStyle.");
		    objOds.format_cell(data:"Function Name"
                          ,overrides:"&_tableTitleStyle.");
		    objOds.format_cell(data:"DWH^Column^Type"
                          ,overrides:"&_tableTitleStyle.",split:'^');
		    objOds.format_cell(data:"SAS^Column^ Type"
                          ,overrides:"&_tableTitleStyle.",split:'^');                         
		    objOds.format_cell(data:"In^perimeter^ Y/N"
                          ,overrides:"&_tableTitleStyle.",split:'^');
		    objOds.format_cell(data:"Technical^field^Y/N"
                          ,overrides:"&_tableTitleStyle.",split:'^');
      objods.row_end();
      objOds.head_end();
    RETURN;

    HEADERTABLE_1:
      objOds.head_start();
      objOds.row_start();
        objOds.format_cell(data:"Report di dettaglio relativo alla lista dei nuovi campi"
                          ,overrides:"&_reportTitleStyle."
                          ,column_span:3);
      objOds.row_end();

      objOds.row_start();
   		  objOds.format_cell(data:"DWH Table"
                          ,overrides:"&_tableTitleStyle.");
        objOds.format_cell(data:"Varname"
                          ,overrides:"&_tableTitleStyle.");
		    objOds.format_cell(data:"DWH^Column^Type"
                          ,overrides:"&_tableTitleStyle.",split:'^');
      objods.row_end();
      objOds.head_end();
    RETURN;
      
    FAIREPORT:
      Do While (fetch(_dsT)=0);
        dwhFieldNew = GetvarC(_dsT,Varnum(_dsT,"dwhFieldNew"));
        dwhTable    = GetvarC(_dsT,Varnum(_dsT,"dwhTable"));
        nrec        = GetvarN(_dsT,Varnum(_dsT,"nrec"));
        objOds.row_start();
          objOds.format_cell(data:dwhTable
                            ,overrides:"&_tableBodyStyle."
                            ,row_span:nrec);
        _dsid = Open(cats(' ',"_checksForPrint (Where=(",_wclsChange,"And dwhTable= Strip('",dwhTable,"')))"));
        Do While (fetch(_dsid)=0);
            Link details; 
          objOds.row_end();
          objOds.row_start();
        End;
        _dsid = Close(_dsid);
      End;
    RETURN;
    
    DETAILS:
      idRule       = Getvarc(_dsid,Varnum(_dsid,"idRule"));
      fxName       = Getvarc(_dsid,Varnum(_dsid,"fxName"));
      reason       = Getvarc(_dsid,Varnum(_dsid,"reason"));
      flgInPer     = Getvarc(_dsid,Varnum(_dsid,"isInPerimeter"));
      flgInTec     = Getvarc(_dsid,Varnum(_dsid,"isInTechnical"));
      dmFieldType  = Getvarc(_dsid,Varnum(_dsid,"dmFieldType"));
      dwhTypeCampo = Getvarc(_dsid,Varnum(_dsid,"dwhTypeCampo"));
      dwhField     = GetvarC(_dsid,Varnum(_dsid,"dwhNomeCampo"));

      If dwhFieldNew ^= 'D' Then Do;
        objOds.format_cell(data:dwhField
                           ,overrides:"&_tableBodyStyle.");
        objOds.format_cell(data:idRule
                           ,overrides:"&_tableBodyStyle.");
        objOds.format_cell(data:fxName
                           ,overrides:"&_tableBodyStyle.");
        If input(scan(scan(dwhTypeCampo,2,'('),1,')'),8.) > input(scan(scan(dmFieldType,2,'('),1,')'),8.) Then Do;
          objOds.format_cell(data:dwhTypeCampo
                            ,overrides:"&_tableBodyStyle.",style_attr:"color=red");
          objOds.format_cell(data:dmFieldType
                             ,overrides:"&_tableBodyStyle.",style_attr:"color=red");
        End;
        Else Do;
          objOds.format_cell(data:dwhTypeCampo
                            ,overrides:"&_tableBodyStyle.");
          objOds.format_cell(data:dmFieldType
                            ,overrides:"&_tableBodyStyle.");
        End;
        objOds.format_cell(data:flgInPer
                           ,overrides:"&_tableBodyStyle.");
        objOds.format_cell(data:flgInTec
                           ,overrides:"&_tableBodyStyle.");
      End;
      Else Do;
        objOds.format_cell(data:dwhField
                           ,overrides:"&_tableBodyStyle.");
        objOds.format_cell(data:dwhTypeCampo
                          ,overrides:"&_tableBodyStyle.");
      End;
    RETURN;
  Run;

  %*-- Add send mail;

  %Uscita:
    %Put +----[Macro: &sysmacroname.] ------------------------------------------------+;
    %Put | Prints the results of the impacts related to changes in the DWH data model |;
	  %Put | .......................................................................... |;
	  %Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	  %Put +----[Macro: &sysmacroname.] ------------------------------------------------+;
%Mend;
