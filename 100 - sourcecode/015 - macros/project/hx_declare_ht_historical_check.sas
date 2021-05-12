*==================================================================================================                                                                                                                                                             
* Cliente : AMCO SpA                                                                                                                                                                                                                                            
* Office  : CRO Portfolio Managment -> Data Verification                                                                                                                                                                                                        
* -------------------------------------------------------------------------------------------------                                                                                                                                                             
* Macro name  : hx_declare_ht_historical_check                                                                                                                                                                                                                  
* Description : New macro developed to historicize dwh checks                                                                                                                                                                                                   
* Author      : Uriele De Piano Hexe SpA, 30 November 2020                                                                                                                                                                                                      
* -------------------------------------------------------------------------------------------------                                                                                                                                                             
* NOTE: Macro can declare hash by historical checks                                                                                                                                                                                                             
* -------------------------------------------------------------------------------------------------                                                                                                                                                             
* CHANGE HISTORY:                                                                                                                                                                                                                                               
*	  Code				: portf                                                                                                                                                                                                                                             
*		Description : Add variables about portfolio                                                                                                                                                                                                                  
*		Author      : Uriele De Piano Hexe S.p.A 14 January 2021                                                                                                                                                                                                     
*==================================================================================================                                                                                                                                                             
;                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                
%Macro hx_declare_ht_historical_check(htTable=_NULL_ ) / store secure ;                                                                                                                                                                                         
	%Local dsid ncampo tcampo lcampo fcampo                                                                                                                                                                                                                        
		;                                                                                                                                                                                                                                                             
	%*-- Write Process Trace;                                                                                                                                                                                                                                      
	%Let dsid = %sysfunc(open(&histchecks.));                                                                                                                                                                                                                      
	%Do _i=1 %To %sysfunc(attrn(&dsid,NVARS));                                                                                                                                                                                                                     
		%Let ncampo = %sysfunc(varname(&dsid.,&_i.));                                                                                                                                                                                                                 
		%Let tcampo = %sysfunc(vartype(&dsid.,&_i.));                                                                                                                                                                                                                 
		%Let lcampo = %sysfunc(varlen(&dsid.,&_i.));                                                                                                                                                                                                                  
		%Let fcampo = %sysfunc(varfmt(&dsid.,&_i.));                                                                                                                                                                                                                  
		%if &tcampo.=C %then %do;                                                                                                                                                                                                                                     
			Attrib &ncampo. Length=$&lcampo.;                                                                                                                                                                                                                            
		%end;                                                                                                                                                                                                                                                         
		%else %do;                                                                                                                                                                                                                                                    
				Attrib &ncampo. Length=8                                                                                                                                                                                                                                    
				%If %Lowcase(&nCampo.)=timestamp %Then %Do;                                                                                                                                                                                                                 
					format = datetime.                                                                                                                                                                                                                                         
				%End;                                                                                                                                                                                                                                                       
				format=&fcampo.                                                                                                                                                                                                                                             
					;                                                                                                                                                                                                                                                          
			%end;                                                                                                                                                                                                                                                        
		%end;                                                                                                                                                                                                                                                         
		%Let dsid = %sysfunc(close(&dsid.));                                                                                                                                                                                                                          
		%If %sysfunc(exist(&htTable.))=0 %Then %Do;                                                                                                                                                                                                                   
			Declare hash ht(ordered:'yes');                                                                                                                                                                                                                              
		%End;                                                                                                                                                                                                                                                         
		%Else %Do;                                                                                                                                                                                                                                                    
			Declare hash ht(dataset:"&htTable.",ordered:'yes');                                                                                                                                                                                                          
		%End;                                                                                                                                                                                                                                                         
			%*--[Change code: portf] -- [Start modify] ----;                                                                                                                                                                                                             
			ht.defineKey("idTransaction","dataProvider","cod_ist","dta_reference","cod_portafoglio_gest","idAmbito","idRule");                                                                                                                                           
			ht.defineData("idTransaction","dataProvider","cod_ist","dta_reference","cod_portafoglio_gest","des_portafoglio_gest"                                                                                                                                         
										,"idAmbito","descr_ambito","timeStamp","tableName","nrecTotal","nvarsTotal","nrecPerimeter","tableAlias"                                                                                                                                              
										,"idRule","descr_rule","flagName","nOccurs","principio","fx_name","Campi_Tecnici"                                                                                                                                                                     
										,"Perimetro_di_applicabilita","eseguito","nota"                                                                                                                                                                                                       
										);                                                                                                                                                                                                                                                    
			%*--[Change code: portf] -- [End modify] ----;                                                                                                                                                                                                               
		ht.defineDone();                                                                                                                                                                                                                                              
		Retain timeStamp dta_reference . idTransaction dataProvider tableName ' ';                                                                                                                                                                                    
		timeStamp     = dateTime();                                                                                                                                                                                                                                   
		idTransaction = symget("idTrasaction");                                                                                                                                                                                                                       
		dataProvider  = symget("dataProvider");                                                                                                                                                                                                                       
		dta_reference = "&dta_reference."d;                                                                                                                                                                                                                           
		%If %symexist(cod_ist) %Then %Do;                                                                                                                                                                                                                             
			Retain cod_ist .;                                                                                                                                                                                                                                            
			cod_ist = &cod_ist.;                                                                                                                                                                                                                                         
		%End;                                                                                                                                                                                                                                                         
%Mend;                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                
		                                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                
