*==================================================================================================
* Cliente : AMCO SpA
* Office  : CRO Portfolio Managment -> Data Verification
* -------------------------------------------------------------------------------------------------
* Macro name  : hx_create_formats
* Description : Creates a format from metadata table or lookup table
* Author      : Uriele De Piano Hexe SpA, 29 October 2020
* -------------------------------------------------------------------------------------------------
* NOTE: Macro is divided in two component
*==================================================================================================
;

%Macro hx_create_formats (libout			  = cmnfmt
		 				  ,dsSourceFmt  = _NULL_
		 			      ,startV			  = _NULL_
		 				  ,descriptionV = _NULL_
		 				  ,fmtName 		  = fmtName)
						  / store secure des="creazione formati";
    %Local timeStamp wlcsDate dsid dsidDP typeFmt
		;
	%Let timeStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));

	%Put +----[macro=&sysmacroname.] --------------------------------+;
	%Put | Creation format [&fmtName.]															 |;
	%Put | Parameters:                                         			 |;
	%Put |    Source Table   : &dsSourceFmt.												 |;
	%Put |    Start Variable : &startV.													 		 |;
	%Put |    Label Variable : &descriptionV.												 |;
	%Put +-----------------------------------------------------------+;
	%Put | Started at: &timeStamp.																	 |;
	%Put +-----------------------------------------------------------+;

	%*-- Check Metadata Table. Update Process trace;
	Data _null_;
		Length dsVariable $100
			;
		dsSourceFmt = symget("dsSourceFmt");
		timeStamp     = datetime();
		%hx_declare_ht_pr(htTable=&processTrace.);
		sourceCode    = symget("sysmacroname");

		rcCode = 0;
		If Not exist(dsSourceFmt) Then Do;
			stepCode = catx(' ',"Verifica Format Table",dsSourceFmt);
			rcCode   = -30010;
			msgCode  = "Dataset not exists";
		End;
		*-- Check start variable and label variable;
		dsid       = open(dsSourceFmt);

		%*-- Check start variable;
		dsVariable = symget("startV");
		flgStartV  = ifc(varnum(dsid,dsVariable)<=0,'N','Y');
		If flgStartV='Y' Then Call Symput("typeFmt",vartype(dsid,varnum(dsid,dsVariable)));
		%*-- Check label variable;
		dsVariable = symget("descriptionV");
		flgLabelV  = ifc(varnum(dsid,dsVariable)<=0,'N','Y');
		dsid = close(dsid);
		select;
			when (flgStartV = 'N' And flgLabelV = 'N') Do;
				rcCode  = -30011;
				msgCode = catx(' ',"Both variables [",symget("startV"),"] and [",symget("descriptionV"),"] not exist");
			end;
			when (flgStartV = 'N' And flgLabelV = 'Y') Do;
				rcCode  = -30012;
				msgCode = catx(' ',"Start variable [",symget("startV"),"] not exists");
			end;
			when (flgStartV = 'Y' And flgLabelV = 'N') Do;
				rcCode  = -30013;
				msgCode = catx(' ',"Description variable [",symget("descriptionV"),"] not exists");
			end;
			otherwise rcCode=1;
		end;
		If rcCode ^= 1 Then Do;
			rc = ht.add();
			rc = ht.output(dataset:"&processTrace.");
			Abort Abend 0;
		End;
	Run;
	Data _fmtTable_;
		Attrib start Length=$300
					 type  Length=$1
					 label Length=$500
					 fmtName Length=$20
					 hlo Length=$1;
		Retain type "&typeFmt." fmtName "&fmtName."
			;
		Set &dsSourceFmt. (Rename=("&startV."n = START "&descriptionV."n = LABEL)) end=fine;
		Output;
		if fine Then Do;
			hlo = 'O';
			output;
		End;
	Run;
	Proc Sort data=_fmtTable_ nodupkey;
		by start;
	Run;
	Proc format lib=&libout. cntlin=_fmtTable_;
	Run;
	%*-- Check Metadata Table. Update Process trace;
	Data _null_;
		Length dsVariable $100
			;
		dsSourceFmt = symget("dsSourceFmt");
		timeStamp     = datetime();
		%hx_declare_ht_pr(htTable=&processTrace.);
		sourceCode    = symget("sysmacroname");

		rcCode   = -30100;
	  stepCode = catx(' ',"Creation format [",Symget("fmtName"),']');
		msgCode  = "Format was not created";
		If symget("syserr")<=4 Then Do;
			rcCode   = 0;
			msgCode  = "Format has been created";
		End;
		rc = ht.add();
		rc = ht.output(dataset:"&processTrace.");
	Run;

	%Uscita:
		%Put +----[macro=&sysmacroname.] --------------------------------+;
		%Put | Creation format [&fmtName.]															 |;
		%Put | Parameters:                                         			 |;
		%Put |    Source Table   : &dsSourceFmt.												 |;
		%Put |    Start Variable : &startV.													 		 |;
		%Put |    Label Variable : &descriptionV.												 |;
		%Put +-----------------------------------------------------------+;
		%Put | Ended at: &timeStamp.																	 |;
		%Put +-----------------------------------------------------------+;

%Mend;


/*
%hx_create_formats (libout		  = work
	 				,dsSourceFmt  = PRVMETA.DWH_TASSONOMIA_CONTROLLI
	 			    ,startV	      = IDRULE
	 				,descriptionV = CONTROLLO
	 				,fmtName 	  = fmtcontrollo);
*/






