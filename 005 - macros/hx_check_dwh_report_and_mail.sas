/*{
    "Program": "hx_check_dwh_report_and_mail"
	"Descrizione": "Produce a summary reports. It will be send by mail-address",
	"Parametri": [
		"dsDMchecked":"Output macro hx_check_dwh_datamodel"
		"dsRuleChecked":"List of dataverification's checks has been impacted" 
	],
	"Return": "Mail",
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
}*/

%Macro hx_check_dwh_report_and_mail (dsDMchecked=work.hx_check_dwh_datamodel
        ,dsRuleChecked=work.hx_check_in_dataverification) / Des="Print results about checks on DWH Data Model";

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
      Select dwhFieldName 
	         ,dsDwhTable
             ,idRule
		     ,case
		        when (dwhFieldNew='D') then "Field deleted by DWH"
			    when (dmFieldSameT='N') then "Field has an different type"
			  end as reason length=80
			  ,flgInPerimeter
			  ,flgInTecnical
			  ,count(*) as nrec 
	   From &dsRuleChecked.
	   Group by 1,2
	   Order by 1,2,3
	    ;
      Create Table _listTables As
         Select Distinct dwhFieldName
                ,dsDwhTable
                ,nrec
          From _checksForPrint
          ;
    Quit;

    %*-- Produce Report;
    %Let _tableStyle      = %NrQuote(width=100%% frame=box bordercolor=white background=#000066 BorderWidth=0 cellspacing=1 cellPadding=1 just=left);
    %Let _tableTitleStyle = %NrQuote(font_face=arial font_style=roman font_size=10pt color=#ffffff font_weight=bold background=#000066 vjust=center cellwidth=15% cellspacing=2 cellPadding=2);
    %Let _tableBodyStyle  = %NrQuote(font_face=arial font_style=roman font_size=8pt color=#ffffff font_weight=bold background=#999999 vjust=center cellspacing=2 cellPadding=2);
    %Let _reportTitle     = %NrQuote(font_face=arial font_style=roman font_size=14pt color=#000066 font_weight=bold background=#ffffff vjust=center cellspacing=2 cellPadding=2);

    Data _null_;
      Declare odsout objOds();
      %*-- Define Table titles;

      %*-- Define Style of Table and print Header;
	  objOds.table_start();
	    Link HeaderTable;

        _dsT = open("_listTables");
        Do While (fetch(_dsT)=0);
          dwhFieldName = GetvarC(_dsT,Varnum(_dsT,"dwhFieldName"));
          dsDwhTable   = GetvarC(_dsT,Varnum(_dsT,"dsDwhTable"));
          nrec         = GetvarN(_dsT,Varnum(_dsT,"nrec"));
          objOds.row_start();
            objOds.format_cell(data:dwhFieldName
                              ,overrides:"&_tableBodyStyle."
                              ,row_span:nrec);
            objOds.format_cell(data:dsDwhTable
                              ,overrides:"&_tableBodyStyle."
                              ,row_span:nrec);
          _dsid = Open(cats("_checksForPrint (Where=(dwhFieldName='",dwhFieldName,"' And dsDwhTable='",dsDwhTable,"'))"));
          If fetch(_dsid)=0 Then Do;
            Link read; 
            objOds.row_end();
            Do While (fetch(_dsid)=0);
              objOds.row_start();
                Link read; 
              objOds.row_end();
            End;
          End;
          _dsid = Close(_dsid);
        End;
        _dsT = Close(_dsT);

	  objOds.table_end();
      
      Return;
      HEADERTABLE:
        objOds.head_start();
        objOds.row_start();
          objOds.format_cell(data:"Elenco delle regole coinvolte dalle modifiche del modello dati DWH"
                             ,overrides:"&_reportTitle."
                             ,column_span:6);
        objOds.row_end();

        objOds.row_start();
		 * objOds.format_cell(data:' ',overrides:"preimage='&logoAmco.' just=left cellwidth=15%",column_span:1);
		  objOds.format_cell(data:"Field Name"
                            ,overrides:"&_tableTitleStyle."
							,column_span:1);
		  objOds.format_cell(data:"Datiodd Table"
                            ,overrides:"&_tableTitleStyle."
							,column_span:1);
		  objOds.format_cell(data:"Id. Rule"
                            ,overrides:"&_tableTitleStyle."
							,column_span:1);
		  objOds.format_cell(data:"Reason"
                            ,overrides:"&_tableTitleStyle."
							,column_span:1);
		  objOds.format_cell(data:"In perimeter Y/N"
                            ,overrides:"&_tableTitleStyle."
							,column_span:1);
		  objOds.format_cell(data:"Technical field"
                            ,overrides:"&_tableTitleStyle."
							,column_span:1);
        objods.row_end();
        objOds.head_end();
      RETURN;
      READ:
        idRule   = Getvarc(_dsid,Varnum(_dsid,"idRule"));
        reason   = Getvarc(_dsid,Varnum(_dsid,"reason"));
        flgInPer = Getvarc(_dsid,Varnum(_dsid,"flgInperimeter"));
        flgInTec = Getvarc(_dsid,Varnum(_dsid,"flgInTecnical"));
        objOds.format_cell(data:idRule
                           ,overrides:"&_tableBodyStyle.");
        objOds.format_cell(data:reason
                           ,overrides:"&_tableBodyStyle.");
        objOds.format_cell(data:flgInPer
                           ,overrides:"&_tableBodyStyle.");
        objOds.format_cell(data:flgInTec
                           ,overrides:"&_tableBodyStyle.");
      RETURN;
    Run;

    %Uscita:
      %Put +----[Macro: &sysmacroname.] ------------------------------------------------+;
	  %Put | Prints the results of the impacts related to changes in the DWH data model |;
	  %Put | .......................................................................... |;
	  %Put | Started at : %Sysfunc(PutN(&_dttimeStamp.,datetime.));
	  %Put +----[Macro: &sysmacroname.] ------------------------------------------------+;
%Mend;


Option nodate nonumber orientation=landscape papersize=A4 topMargin=.1cm bottommargin=.1cm leftmargin=.1cm rightmargin=.1cm
       	;
title ' ';

%Let _reportName = dwh_check_datamodel_output.pdf;
filename rwiOut "&PUBLISHFOLDER.";
Ods Listing close;
Ods results off;
Ods pdf file="&PUBLISHFOLDER.&slash.&_reportName.";
%hx_check_dwh_report_and_mail();
Ods _all_ Close;

