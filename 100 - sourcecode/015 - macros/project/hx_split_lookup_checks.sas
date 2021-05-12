*==================================================================================================                                                                                                                                                             
* Cliente : AMCO SpA                                                                                                                                                                                                                                            
* Office  : CRO Portfolio Managment -> Data Verification                                                                                                                                                                                                        
* -------------------------------------------------------------------------------------------------                                                                                                                                                             
* Macro name  : hx_split_lookup_checks                                                                                                                                                                                                                          
* Description : Split lookup rules from other rules                                                                                                                                                                                                             
* Author      : Uriele De Piano Hexe SpA, 22 October 2020                                                                                                                                                                                                       
* -------------------------------------------------------------------------------------------------                                                                                                                                                             
* NOTE: Update a standard check tables.                                                                                                                                                                                                                         
*       History check table has been created in autoexec workflow                                                                                                                                                                                               
*==================================================================================================                                                                                                                                                             
;                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                
%Macro hx_split_lookup_checks(dqListChecks=_NULL_,dqListLookup=hx_split_lookup_checks ) / store secure ;                                                                                                                                                        
	%Local idAmbito tmpStamp                                                                                                                                                                                                                                       
			;                                                                                                                                                                                                                                                            
	%Let tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));                                                                                                                                                                                                
	%Put +---[Macro: &sysmacroname.] -------------+;                                                                                                                                                                                                               
	%Put | Split lookup rules from others rules  	|;                                                                                                                                                                                                               
	%Put |   1) Check list [&dqListChecks.]				|;                                                                                                                                                                                                                  
	%Put |   2) Lookup list [&dqListLookup.]			|;                                                                                                                                                                                                                  
	%Put |........................................|;                                                                                                                                                                                                               
	%Put | Starting at: &tmpStamp.;                                                                                                                                                                                                                                
	%Put +----------------------------------------+;                                                                                                                                                                                                               
	%If %sysfunc(exist(&dqListChecks.))=0 %Then %Do;                                                                                                                                                                                                               
		%Put +-------------------------------------------+;                                                                                                                                                                                                           
		%Put | MSGERROR: dqListChecks. table not exist   |;                                                                                                                                                                                                           
		%Put +-------------------------------------------+;                                                                                                                                                                                                           
		%Goto uscita;                                                                                                                                                                                                                                                 
	%End;                                                                                                                                                                                                                                                          
	%If %Sysfunc(exist(&dqListLookup.)) %Then %Do;                                                                                                                                                                                                                 
		Proc Sql;                                                                                                                                                                                                                                                     
			Drop Table &dqListLookup.;                                                                                                                                                                                                                                   
		Quit;                                                                                                                                                                                                                                                         
	%End;                                                                                                                                                                                                                                                          
	Data &dqListChecks. &dqListLookup.;                                                                                                                                                                                                                            
		Set &dqListChecks.;                                                                                                                                                                                                                                           
		If lowcase(tipoCheck)=:"hx_check_lookup_value" Then Output &dqListLookup.;                                                                                                                                                                                    
		Else Output &dqListChecks.;                                                                                                                                                                                                                                   
	Run;                                                                                                                                                                                                                                                           
	Proc Sort data=&dqListLookup. nodupkey;                                                                                                                                                                                                                        
		By dataProvider idAmbito idRule;                                                                                                                                                                                                                              
	Run;                                                                                                                                                                                                                                                           
	%Let idAmbito=;                                                                                                                                                                                                                                                
	Proc Sql Outobs=1 noprint;                                                                                                                                                                                                                                     
		Select Strip(idAmbito) Into :idAmbito From &dqListChecks.;                                                                                                                                                                                                    
	Quit;                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                
	Data _null_;                                                                                                                                                                                                                                                   
		%*-- Write Process Trace;                                                                                                                                                                                                                                     
		%hx_declare_ht_pr(htTable=&processTrace.);                                                                                                                                                                                                                    
		sourceCode    = symget("sysmacroname");                                                                                                                                                                                                                       
		stepCode      = "Split lookup rules and others rules";                                                                                                                                                                                                        
		If exist(symget("dqListChecks")) Then Do;                                                                                                                                                                                                                     
			lkpRules = hx_get_nobs(symget("dqListLookup"));                                                                                                                                                                                                              
			totRules = hx_get_nobs(symget("dqListChecks"))+lkpRules;                                                                                                                                                                                                     
			rcCode   = 1;                                                                                                                                                                                                                                                
			msgCode  = catx(' ',"[&dataProvider.] [%UnQuote(&idAmbito.)] There are",put(lkpRules,commax12.),"on",Put(totRules,commax12.),"rules");                                                                                                                       
		End;                                                                                                                                                                                                                                                          
		Else Do;                                                                                                                                                                                                                                                      
			rcCode   = 0;                                                                                                                                                                                                                                                
			msgCode  = "[&dataProvider.] [%UnQuote(&idAmbito.)] no rules about lookup";                                                                                                                                                                                  
		End;                                                                                                                                                                                                                                                          
		rc = ht.add();                                                                                                                                                                                                                                                
		rc = ht.output(dataset:"&processTrace.");                                                                                                                                                                                                                     
	Run;                                                                                                                                                                                                                                                           
                                                                                                                                                                                                                                                                
	%Uscita:                                                                                                                                                                                                                                                       
		%Let tmpStamp = %sysfunc(putn(%sysfunc(datetime()),datetime.));                                                                                                                                                                                               
		%Put +---[Macro: &sysmacroname.] -------------+;                                                                                                                                                                                                              
		%Put | Split lookup rules from others rules  	|;                                                                                                                                                                                                              
		%Put |   1) Check list [&dqListChecks.]				|;                                                                                                                                                                                                                 
		%Put |   2) Lookup list [&dqListLookup.]			|;                                                                                                                                                                                                                 
		%Put |........................................|;                                                                                                                                                                                                              
		%Put | Starting at: &tmpStamp.;                                                                                                                                                                                                                               
		%Put +----------------------------------------+;                                                                                                                                                                                                              
%Mend;                                                                                                                                                                                                                                                          
