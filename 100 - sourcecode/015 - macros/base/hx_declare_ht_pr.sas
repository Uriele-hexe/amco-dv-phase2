*==================================================================================================
* Cliente : AMCO SpA
* Office  : CRO Portfolio Managment -> Data Verification
* -------------------------------------------------------------------------------------------------
* Macro name  : hx_declare_ht_pr
* Description : Define Hash Table for process trace
* Author      : Uriele De Piano Hexe SpA, 18 October 2020
* -------------------------------------------------------------------------------------------------
* NOTE: Macro is divided in two component
*	        1) Metadata NPL SOURCE LIST to retrieve list of table will be normalized
*					2) Creation of datiwip table using sas statment inserted in temporary dataset 
*==================================================================================================
;

%Macro hx_declare_ht_pr(htTable=_NULL_) / store secure;
	%Local dsid ncampo tcampo lcampo
		;
	%*-- Write Process Trace;
	%If %sysfunc(exist(&htTable.))=0 %Then %Do;
		%Let dsid = %sysfunc(open(&processTrace.));
	%End;
	%Else %Do;
		%Let dsid = %sysfunc(open(&htTable.));
	%End;
	%Do _i=1 %To %sysfunc(attrn(&dsid,NVARS));
		%Let ncampo = %sysfunc(varname(&dsid.,&_i.));
		%Let tcampo = %sysfunc(vartype(&dsid.,&_i.));
		%Let lcampo = %sysfunc(varlen(&dsid.,&_i.));
		%Let fcampo = %sysfunc(varfmt(&dsid.,&_i.));
		%if &tcampo.=C %then %do;
			Attrib &ncampo. Length=$&lcampo.
		%end;
		%else %do;
				Attrib &ncampo. Length=8
		%end;
      		format = &fcampo.
					;
	%end;
	%Let dsid = %sysfunc(close(&dsid.));
	%If %sysfunc(exist(&htTable.))=0 %Then %Do;
		Declare hash ht(ordered:'yes');
	%End;
	%Else %Do;
		Declare hash ht(dataset:"&htTable.",ordered:'yes');
	%End;
			ht.defineKey("idTransaction","timeStamp","dataProvider");
			ht.defineData("idTransaction","dta_reference","cod_ist","timeStamp","dataProvider"
									 ,"sourceCode","stepCode","rcCode","msgCode");
			ht.defineDone();
		idTransaction = symget("idTrasaction");
		timeStamp     = dateTime();
		dataProvider  = symget("dataProvider");
		dta_reference	= "&dta_reference."d;
		Call Missing(cod_ist);
		%If %Symexist(cod_ist) %Then %Do;
			cod_ist = &cod_ist.;
		%End;
%Mend;
