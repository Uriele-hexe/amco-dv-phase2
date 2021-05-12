*============================================================================================
* Client Name: AMCO SpA
* Project    : Framework di Data Verification
*--------------------------------------------------------------------------------------------
* Program name: hx_import_parameters
* Author      : Uriele De Piano Hexe SpA 02 October 2020
* Description : Import parameters
*--------------------------------------------------------------------------------------------
* NOTE: Use two global macro variable
*============================================================================================
;

%Macro hx_import_parameters(cfgFolder=_NULL_,cfgName=_NULL_,dtaReference=_NULL_) / Store secure;
	%Local tmpStamp
		;
	%Let tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));
	%Put +---[Macro: &sysmacroname.] -------------+;
	%Put | Import configurazione file  				  	|;
	%Put |   Folder [&cfgFolder.]			|;
	%Put |   File   [&cfgName.]			|;
	%Put |........................................|;
	%Put | Started at: &tmpStamp.;
	%Put +----------------------------------------+;	
	Data _null_;
		Attrib paramFolder	Length=$256
					 cfgName		  Length=$100

					 paramName		Length=$40
					 paramValue		Length=$256
					 paramDescr   Length=$256
					 validFrom		Length=$10
					 validTo  		Length=$10
					 slash				Length=$1
					 stringParam	Length=$500
				;
		paramFolder = Strip(Symget("cfgFolder"));
		cfgName   = Strip(Symget("cfgName"));
		slash     = ifc(symget("SYSSCP")=:"WIN",'\','/');
		%*-- Write Process Trace;
		%hx_declare_ht_pr(htTable=&processTrace.);
		sourceCode    = symget("sysmacroname");
		stepCode      = catx(' ',"Importazione parametri:",cfgName,"su folder",paramFolder);
		%*-- Try to import parameters;
		rc  = filename("fparam",catx(slash,paramFolder,cfgName));
		fid = fopen("fparam");
		If fid<=0 Then Do;
			rcCode  = sysrc();
			msgCode = sysmsg();
		End;
		Else Do;
			rcCode = 1;
			nParam = 0;
			Do While (fread(fid)=0);
				rc = fget(fid,stringParam,500);
				If Not (stringParam=:'#') Then Do;
					paramName  = scan(stringParam,1,':');
					paramValue = scan(stringParam,2,':');
					validFrom  = scan(stringParam,3,':');	
					validTo		 = scan(stringParam,4,':');
					%If %Upcase(&dtaReference.) ne _NULL_ %Then %Do;
						flgPutParam = Ifc(input(validFrom,date9.)<="&dtaReference."d And input(validTo,date9.)>="&dtaReference."d,'Y','N'); 
					%End;
					%Else %Do;
						flgPutParam='Y';
					%End;
					If flgPutParam='Y' Then Do;
						nParam = Sum(nParam,1);
						Call Execute(catx(' ',cats('%',"Global"),paramName));
						Call Execute(catx(' ',cats('%',"Let"),paramName,'=',paramValue,';'));
						rc = prxMatch("/#/i",stringParam);
						If rc > 0 Then Do;
							Call Execute(catx(' ',cats('%',"Global"),catx('_',paramName,"descr")));
							Call Execute(catx(' ',cats('%',"Let"),catx('_',paramName,"descr"),'=',substr(stringParam,rc+1),';'));
						End;
					End;
				End;
			End; 
			fid 		= fclose(fid);
			msgCode = catx(' ',put(nParam,12.),"parameters declared");
		End;
		rc = ht.add();
		rc = ht.output(dataset:"&processTrace.");
	Run;
	%Put +---[Macro: &sysmacroname.] -------------+;
	%Put | Import configurazione file  				  	|;
	%Put |   Folder [&cfgFolder.]									|;
	%Put |   File   [&cfgName.]										|;
	%Put |........................................|;
	%Put | Ended at: &tmpStamp.;
	%Put +----------------------------------------+;	
%Mend;

