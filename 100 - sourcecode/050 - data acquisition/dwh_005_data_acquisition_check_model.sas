/*{
    "Program": "dwh_005_data_acquisition_check_model"
	"Descrizione": "Preliminary checks on DWH Table data model",
	"Parametri": [
	],
	"Return": {"Global macro variable named hx_dwh_chk_model",
	           "Physical dataset containing checks's result on DWH datamodel"
			   },
	"Autore": "Hexe S.p.A.",
	"Sito web": "<http://www.hexeitalia.com>",
	"Email": "<info@hexeitalia.com>",
	"Manutentori": [ "Hexe S.p.A." ]
    "Note": [ "Checks will be run by functions" ]
}*/

*-- Option cmplib = (hx_func.da_functions) mprint source2;
%Macro hx_dwh_chk_model()
           / Des="Preliminary checks on data model";
	%Local _tmpStamp _dscheckOut _changeCheck _reportName
			;

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ------------------------------+;
	%Put | Verify eventually changemment on DWH data contents      |;
	%Put |.........................................................|;
	%Put | Started at: &_tmpStamp.                                 |;
	%Put +---------------------------------------------------------+;
    %Let _dscheckOut = datichk.%UnQuote(&dataProvider.)_dm_prelimnary_checks
    %*-- Run function;    
    %Let _tmpStamp = %sysfunc(datetime());
    %Let _changeCheck = %sysfunc(fx_check_dwh_datamodel());
	
	%*-- Preserve output checks on data model;
	Proc Sql;
      %If %sysfunc(exist(&_dscheckOut.)) %Then %Do;
	    Drop Table &_dscheckOut.;
	  %End;
	  Create Table &_dscheckOut. As
		  Select "&idTrasaction." as idTransaction "Id. transaction"
		         ,"&dta_reference."d as dta_riferimento "Reference date" format=ddmmyy10.
				 ,&cod_ist. as cod_istituto "Istituto"
				 ,&_tmpStamp as timeStamp "Timestamp" format=datetime22.
				 ,a.*
			From work.hx_check_dwh_datamodel as a
		;
	Quit;

	%*-- Update Process Trace;
	Data _null_;
	  %hx_declare_ht_pr(htTable=&processTrace.);
	  sourceCode = "Data Acquisition";
	  stepCode   = "Check on data model";
	  msgCode    = "&_changeCheck.";
	  rcCode     = ifn(msgCode =: "PASSED",1,-20000);
	  rc = ht.add();
	  rc = ht.output(dataset:"&processTrace.");
	Run;
	%If %symexist(hx_dwh_chk_model)=0 %Then %Do;
	  %Global hx_dwh_chk_model;
	%End;
	%Let hx_dwh_chk_model = &_changeCheck.;

	%*-- Print report check;
    %If "&hx_dwh_chk_model." ne "PASSED" %Then %Do;
      %Let _reportName = &sysmacroname..pdf;
      Ods Listing close;
      Ods results off;
      Ods pdf file="&publishfolder.&slash.&_reportName.";
      Option nodate nonumber orientation=landscape papersize=A4 topMargin=.1cm bottommargin=.1cm leftmargin=.1cm rightmargin=.1cm
       	;
      %hx_check_dwh_datamodel_report(dsDMchecked=&_dscheckOut.);
      Ods _all_ Close;
	%End;

	%Let _tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] ------------------------------+;
	%Put | Verify eventually changemment on DWH data contents      |;
	%Put | (output of the verification: &hx_dwh_chk_model.)       |;
	%Put |.........................................................|;
	%Put | Ended at: &_tmpStamp.;
	%Put +-------------------------------------------------+;
%Mend;
%hx_dwh_chk_model();
